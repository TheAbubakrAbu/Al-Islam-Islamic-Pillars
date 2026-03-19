import SwiftUI
import AVFoundation
import MediaPlayer

final class QuranPlayer: ObservableObject {
    static let shared = QuranPlayer()
    private static let listeningHistoryKey = "quranListeningHistoryData"
    private static let readingHistoryKey = "quranReadingHistoryData"
    
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    
    @Published var isLoading = false
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false
    
    @Published var currentSurahNumber: Int?
    @Published var currentAyahNumber: Int?
    @Published var isPlayingSurah = false
    @Published var isPlayingCustomRange = false
    @Published var showInternetAlert = false
    @Published var playbackAlertTitle = "Playback Error"
    @Published var playbackAlertMessage = "Unable to load this recitation right now. Please try again."

    @Published private(set) var customRangeStartAyah: Int?
    @Published private(set) var customRangeEndAyah: Int?
    @Published private(set) var customRangeRepeatPerAyah: Int = 1
    @Published private(set) var customRangeRepeatSection: Int = 1
    @Published private(set) var customRangeCurrentIndex: Int?
    @Published private(set) var customRangeTotalItems: Int?
    @Published private(set) var customRangeCurrentRepeatWithinAyah: Int?

    @Published var listeningHistory: [ListeningHistoryItem] = [] {
        didSet { persistListeningHistory() }
    }
    @Published var readingHistory: [ReadingHistoryItem] = [] {
        didSet { persistReadingHistory() }
    }
    
    private var lastSavedListeningSurahNumber: Int?
    private var lastSavedReadingPosition: (surahNumber: Int, ayahNumber: Int)?

    private var backButtonClickCount = 0
    private var backButtonClickTimestamp: Date?
    /// Ayah skip-back: delay-based so one tap = restart, two taps = previous. Avoids double-tap from one press.
    private var ayahBackPendingRestart: DispatchWorkItem?
    private var ayahBackPendingRestartScheduledAt: Date?
    private let ayahBackDoubleTapMinInterval: TimeInterval = 0.25
    private let ayahBackRestartDelay: TimeInterval = 0.4
    private var continueRecitationFromAyah = false
    private var didHandleSingleAyahEnd = false
    
    var player: AVPlayer?
    private var queuePlayer: AVQueuePlayer?
    
    private var statusObserver: NSKeyValueObservation?
    private var queuePlayerItemObserver: NSKeyValueObservation?
    private var notificationObservers = [NSObjectProtocol]()
    
    var nowPlayingTitle: String?
    var nowPlayingReciter: String?
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        loadHistoryFromDefaults()
        setupRemoteTransportControls()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deactivateAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let s = AVAudioSession.sharedInstance()
            try s.setCategory(.playback)
            try s.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { logger.debug("Audio session setup failed: \(error)") }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: .notifyOthersOnDeactivation)
        } catch { logger.debug("Audio session deactivate failed: \(error)") }
    }

    private func presentPlaybackFailure(_ message: String, title: String = "Playback Error") {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = false
                self.isPlaying = false
                self.isPaused = false
                self.playbackAlertTitle = title
                self.playbackAlertMessage = message
                self.showInternetAlert = true
            }
            self.idleTimerSet(false)
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard
            let user = notification.userInfo,
            let tVal = user[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: tVal)
        else { return }
        
        switch type {
        case .began:
            pause()
            idleTimerSet(false)
            
        case .ended:
            if let opts = user[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume) {
                player?.play()
                isPlaying = true
                isPaused = false
                idleTimerSet(true)
            }
            
        @unknown default:
            break
        }
        updateNowPlayingInfo()
    }
    
    private func setupRemoteTransportControls() {
        let cmd = MPRemoteCommandCenter.shared()
        
        cmd.playCommand.addTarget { [unowned self] _ in
            guard !isPlaying else { return .commandFailed }
            player?.play()
            isPlaying = true
            isPaused = false
            idleTimerSet(true)
            updateNowPlayingInfo()
            return .success
        }
        
        cmd.pauseCommand.addTarget { [unowned self] _ in
            guard isPlaying else { return .commandFailed }
            pause()
            return .success
        }
        
        cmd.stopCommand.addTarget { [unowned self] _ in
            guard isPlaying else { return .commandFailed }
            pause()
            isPlaying = false
            isPaused = false
            return .success
        }
        
        cmd.previousTrackCommand.addTarget { [unowned self] _ in
            skipBackwardFromRemote()
            return .success
        }
        cmd.nextTrackCommand.addTarget { [unowned self] _ in
            skipForwardFromRemote()
            return .success
        }
        
        cmd.skipBackwardCommand.addTarget { [unowned self] _ in
            guard player != nil else { return .commandFailed }
            skipBackwardFromRemote()
            return .success
        }
        cmd.skipForwardCommand.addTarget { [unowned self] _ in
            guard player != nil else { return .commandFailed }
            skipForwardFromRemote()
            return .success
        }
        
        cmd.changePlaybackPositionCommand.addTarget { [unowned self] evt in
            guard
                let e = evt as? MPChangePlaybackPositionCommandEvent,
                let p = player
            else { return .commandFailed }
            p.seek(to: CMTime(seconds: e.positionTime, preferredTimescale: 1)) { _ in
                self.updateNowPlayingInfo()
                self.saveLastListenedSurah()
            }
            return .success
        }
    }
    
    /// In-app: double-tap = previous, single-tap = restart current.
    func skipBackward()  {
        if isPlayingCustomRange { seek(by: -10); return }
        player == nil ? () : isPlayingSurah ? surahSkipBackward() : ayahSkipBackward()
    }
    func skipForward()   {
        if isPlayingCustomRange { seek(by: 10); return }
        player == nil ? () : isPlayingSurah ? surahSkipForward() : ayahSkipForward(continueRecitation: continueRecitationFromAyah)
    }

    /// Control Center / Lock Screen: one tap = previous/next and play (no double-tap).
    private func skipBackwardFromRemote() {
        if isPlayingCustomRange { seek(by: -10); return }
        guard player != nil else { return }
        if isPlayingSurah {
            surahSkipBackward()
            return
        }
        ayahGoToPreviousAndPlay()
    }
    private func skipForwardFromRemote() {
        if isPlayingCustomRange { seek(by: 10); return }
        guard player != nil else { return }
        if isPlayingSurah {
            surahSkipForward()
            return
        }
        ayahSkipForward(continueRecitation: continueRecitationFromAyah)
    }

    /// Previous ayah and start playing (used from Control Center where double-tap isn’t possible).
    private func ayahGoToPreviousAndPlay() {
        guard let s = currentSurahNumber, let a = currentAyahNumber else { return }
        if a > 1 {
            playAyah(surahNumber: s, ayahNumber: a - 1, continueRecitation: continueRecitationFromAyah)
        } else if s > 1, let prev = quranData.quran.first(where: { $0.id == s - 1 }) {
            playAyah(
                surahNumber: s - 1,
                ayahNumber: prev.numberOfAyahs,
                continueRecitation: continueRecitationFromAyah
            )
        }
    }
    
    func pause(saveInfo: Bool = true) {
        if saveInfo { saveLastListenedSurah() }
        player?.pause()
        withAnimation { isPlaying = false; isPaused = true }
        updateNowPlayingInfo()
        idleTimerSet(false)
    }
    func resume() {
        player?.play()
        withAnimation { isPlaying = true; isPaused = false }
        updateNowPlayingInfo()
        idleTimerSet(true)
    }
    
    func seek(by seconds: Double) {
        guard let p = player else { return }
        let newTime = CMTimeGetSeconds(p.currentTime()) + seconds
        p.seek(to: CMTime(seconds: newTime, preferredTimescale: 1)) { _ in
            self.updateNowPlayingInfo(); self.saveLastListenedSurah()
        }
    }
    
    func stop() {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        didHandleSingleAyahEnd = false
        repeatCount = 1
        repeatRemaining = 1
        ayahRepeatCount = 1
        ayahRepeatRemaining = 1

        withAnimation {
            isLoading = false
            
            saveLastListenedSurah()
            
            player?.currentItem?.cancelPendingSeeks()
            player?.currentItem?.asset.cancelLoading()

            player?.pause()
            removeAllObservers()

            player = nil
            queuePlayer = nil
            currentSurahNumber = nil
            currentAyahNumber = nil
            isPlayingSurah = false
            isPlayingCustomRange = false
            isPlaying = false
            isPaused = false
        }
        customRangeSequence = []
        customRangeSurahNumber = 0
        customRangeSurahName = ""
        customRangeStartAyah = nil
        customRangeEndAyah = nil
        customRangeRepeatPerAyah = 1
        customRangeRepeatSection = 1
        customRangeCurrentIndex = nil
        customRangeTotalItems = nil
        customRangeCurrentRepeatWithinAyah = nil

        updateNowPlayingInfo(clear: true)

        DispatchQueue.global(qos: .userInitiated).async {
            self.deactivateAudioSession()
        }

        self.idleTimerSet(false)
    }
    
    private func removeAllObservers() {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
        queuePlayerItemObserver = nil
        statusObserver = nil
    }
    
    private var repeatCount: Int = 1
    private var repeatRemaining: Int = 1

    private func repeatSuffix(total: Int, remaining: Int) -> String {
        guard total > 1 else { return "" }
        let index = max(1, total - remaining + 1)
        return " (x\(index)/\(total))"
    }

    func playSurah(
        surahNumber: Int,
        surahName: String,
        certainReciter: Bool = false,
        skipSurah: Bool = false,
        repeatCount: Int = 1
    ) {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        guard (1...114).contains(surahNumber) else {
            presentPlaybackFailure("This surah could not be found. Please select a valid surah and try again.")
            return
        }

        self.repeatCount = max(1, repeatCount)
        self.repeatRemaining = self.repeatCount

        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber = nil
            isPlayingSurah = true
        }
        continueRecitationFromAyah = false
        backButtonClickCount = 0

        guard let reciterPref = reciters.first(where: { $0.name == settings.reciter }) else {
            presentPlaybackFailure("The selected reciter could not be found. Please choose another reciter in settings.")
            return
        }
        let reciter: Reciter = (certainReciter && settings.lastListenedSurah?.reciter != nil)
            ? settings.lastListenedSurah!.reciter
            : reciterPref

        let urlStr = "\(reciter.surahLink)\(String(format: "%03d", surahNumber)).mp3"
        guard let url = URL(string: urlStr) else {
            presentPlaybackFailure("The recitation link appears invalid. Please try another reciter.")
            return
        }

        setupAudioSession()
        isLoading = true
        player?.pause(); removeAllObservers()

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        statusObserver = item.observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch itm.status {
                case .readyToPlay:
                    self.isLoading = false
                    self.player?.play()
                    withAnimation {
                        self.isPlaying = true
                        self.isPaused = false
                        self.nowPlayingTitle  = "Surah \(surahNumber): \(surahName)" +
                            self.repeatSuffix(total: self.repeatCount, remaining: self.repeatRemaining)
                        self.nowPlayingReciter = reciter.name
                        self.updateNowPlayingInfo()
                        self.recordListeningHistory(surahNumber: surahNumber, surahName: surahName, reciter: reciter.name)
                    }

                    self.idleTimerSet(true)

                    var didResume = false
                    if certainReciter,
                       let last = self.settings.lastListenedSurah,
                       last.surahNumber == surahNumber,
                       last.currentDuration > 1 {
                        let seekT = CMTime(seconds: last.currentDuration, preferredTimescale: 1)
                        self.player?.seek(to: seekT) { _ in
                            self.updateNowPlayingInfo()
                        }
                        didResume = true
                    }

                    if !didResume && (!certainReciter || !skipSurah) {
                        self.saveLastListenedSurah()
                    }
                default:
                    self.presentPlaybackFailure("Unable to load this recitation. Check your internet connection and try again.", title: "Playback Unavailable")
                }
            }
        }

        let obs = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem, queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            if self.repeatRemaining > 1 {
                self.repeatRemaining -= 1

                if let n = self.currentSurahNumber, n == surahNumber {
                    withAnimation {
                        self.nowPlayingTitle = "Surah \(surahNumber): \(surahName)" +
                            self.repeatSuffix(total: self.repeatCount, remaining: self.repeatRemaining)
                        self.updateNowPlayingInfo()
                    }
                }

                self.player?.seek(to: .zero) { _ in
                    withAnimation {
                        self.player?.play()
                        self.isPlaying = true
                        self.isPaused = false
                        self.updateNowPlayingInfo()
                    }
                }
                return
            }

            switch self.settings.reciteType {
            case "Continue to Previous": self.playPreviousSurah(certainReciter: certainReciter)
            case "End Recitation": self.stop()
            default: self.playNextSurah(certainReciter: certainReciter)
            }
        }
        notificationObservers.append(obs)
    }
    
    private func playNextSurah(certainReciter: Bool = false) {
        repeatCount = 1
        repeatRemaining = 1
        
        guard let n = currentSurahNumber, n < 114, let next = quranData.quran.first(where: { $0.id == n + 1 })
        else { stop(); return }
        playSurah(surahNumber: next.id,
                  surahName: next.nameTransliteration,
                  certainReciter: certainReciter,
                  skipSurah: true)
    }
    
    private func playPreviousSurah(certainReciter: Bool = false) {
        repeatCount = 1
        repeatRemaining = 1
        
        guard let n = currentSurahNumber, n > 1, let prev = quranData.quran.first(where: { $0.id == n - 1 })
        else { stop(); return }
        playSurah(surahNumber: prev.id,
                  surahName: prev.nameTransliteration,
                  certainReciter: certainReciter,
                  skipSurah: true)
    }
    
    private func surahSkipBackward() {
        guard currentSurahNumber != nil else { return }
        let now = Date()
        if let last = backButtonClickTimestamp, now.timeIntervalSince(last) < 0.75 {
            backButtonClickCount += 1
        } else {
            backButtonClickCount = 1
        }
        backButtonClickTimestamp = now
        
        if backButtonClickCount == 2 {
            playPreviousSurah(); backButtonClickCount = 0
        } else {
            pause()
            player?.seek(to: .zero) { [weak self] _ in self?.resume() }
            updateNowPlayingInfo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { self.backButtonClickCount = 0 }
        }
    }
    private func surahSkipForward() { playNextSurah() }
    
    private var ayahRepeatCount: Int = 1
    private var ayahRepeatRemaining: Int = 1
    private var lastAyahParams: (surahNumber: Int, ayahNumber: Int, isBismillah: Bool, continueRecitation: Bool)?

    private var customRangeSequence: [(ayahNumber: Int, isBismillah: Bool)] = []
    private var customRangeSurahNumber: Int = 0
    private var customRangeSurahName: String = ""

    func playAyah(
        surahNumber: Int,
        ayahNumber: Int,
        isBismillah: Bool = false,
        continueRecitation: Bool = false,
        repeatCount: Int = 1
    ) {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }) else {
            presentPlaybackFailure("This surah could not be found. Please try again.")
            return
        }
        guard (1...surah.numberOfAyahs).contains(ayahNumber) else {
            presentPlaybackFailure("This ayah is outside the valid range for the selected surah.")
            return
        }
        guard reciters.first(where: { $0.name == settings.reciter }) != nil else {
            presentPlaybackFailure("The selected reciter could not be found. Please choose another reciter in settings.")
            return
        }

        self.ayahRepeatCount      = max(1, repeatCount)
        self.ayahRepeatRemaining  = self.ayahRepeatCount
        self.lastAyahParams       = (surahNumber, ayahNumber, isBismillah, continueRecitation)

        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber  = ayahNumber
            isPlayingSurah     = false
        }

        continueRecitationFromAyah = continueRecitation
        didHandleSingleAyahEnd = false
        startAyahPlayback(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            isBismillah: isBismillah,
            continueRecitation: continueRecitation
        )
    }

    func playCustomRange(
        surahNumber: Int,
        surahName: String,
        startAyah: Int,
        endAyah: Int,
        repeatPerAyah: Int,
        repeatSection: Int
    ) {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }) else {
            presentPlaybackFailure("This surah could not be found. Please try again.")
            return
        }
        guard (1...surah.numberOfAyahs).contains(startAyah),
              (1...surah.numberOfAyahs).contains(endAyah) else {
            presentPlaybackFailure("The selected ayah range is not valid for this surah.")
            return
        }
        guard startAyah <= endAyah else {
            presentPlaybackFailure("The range start cannot be after the range end.")
            return
        }
        guard let reciter = reciters.first(where: { $0.name == settings.reciter }) else {
            presentPlaybackFailure("The selected reciter could not be found. Please choose another reciter in settings.")
            return
        }

        let perAyah = max(1, repeatPerAyah)
        let section = max(1, repeatSection)

        var sequence: [(ayahNumber: Int, isBismillah: Bool)] = []
        for _ in 1...section {
            for ayah in startAyah...endAyah {
                for _ in 1...perAyah {
                    sequence.append((ayah, false))
                }
            }
        }

        guard !sequence.isEmpty,
              let first = sequence.first
        else { return }

        removeAllObservers()
        customRangeSequence = sequence
        customRangeSurahNumber = surahNumber
        customRangeSurahName = surahName
        customRangeStartAyah = startAyah
        customRangeEndAyah = endAyah
        customRangeRepeatPerAyah = perAyah
        customRangeRepeatSection = section
        customRangeCurrentIndex = 1
        customRangeTotalItems = sequence.count
        customRangeCurrentRepeatWithinAyah = 1

        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber = first.ayahNumber
            isPlayingSurah = false
            isPlayingCustomRange = true
        }
        continueRecitationFromAyah = false

        setupAudioSession()
        isLoading = true

        var items: [AVPlayerItem] = []
        for (ayahNum, isBismillah) in sequence {
            guard let item = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNum, isBismillah: isBismillah) else {
                isLoading = false
                presentPlaybackFailure("One or more ayah audio files could not be prepared. Please try again.", title: "Range Playback Failed")
                customRangeSequence = []
                customRangeStartAyah = nil
                customRangeEndAyah = nil
                return
            }
            item.preferredForwardBufferDuration = 8
            items.append(item)
        }

        let q = AVQueuePlayer(items: items)
        q.actionAtItemEnd = .advance
        q.automaticallyWaitsToMinimizeStalling = true
        queuePlayer = q
        player = q

        statusObserver = items[0].observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                withAnimation {
                    self.isLoading = false
                    self.idleTimerSet(true)
                    if itm.status == .readyToPlay {
                        self.queuePlayer?.play()
                        self.isPlaying = true
                        self.isPaused = false
                        let (ayahNum, isBismillah) = self.customRangeSequence[0]
                        self.customRangeCurrentRepeatWithinAyah = 1
                        let base = self.customRangeTitle(ayahNum: ayahNum, isBismillah: isBismillah, repeatWithinAyah: 1)
                        self.nowPlayingTitle = base
                        self.nowPlayingReciter = reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi")
                            ? "Muhammad Al-Minshawi (Murattal)" : reciter.name
                        self.updateNowPlayingInfo()
                    } else {
                        self.presentPlaybackFailure("Unable to start this custom range. Check your internet connection and try again.", title: "Range Playback Failed")
                    }
                }
            }
        }

        queuePlayerItemObserver = q.observe(\.currentItem, options: [.old, .new]) { [weak self] qPlayer, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if qPlayer.currentItem == nil || qPlayer.items().isEmpty {
                    self.stop()
                    return
                }
                let remaining = qPlayer.items().count
                let playedCount = self.customRangeSequence.count - remaining
                guard playedCount >= 0, playedCount < self.customRangeSequence.count else { return }
                let (ayahNum, isBismillah) = self.customRangeSequence[playedCount]
                let repeatWithinAyah = (0...playedCount).filter { self.customRangeSequence[$0].ayahNumber == ayahNum }.count
                let base = self.customRangeTitle(ayahNum: ayahNum, isBismillah: isBismillah, repeatWithinAyah: repeatWithinAyah)
                withAnimation {
                    self.currentAyahNumber = ayahNum
                    self.customRangeCurrentIndex = playedCount + 1
                    self.customRangeCurrentRepeatWithinAyah = repeatWithinAyah
                    self.nowPlayingTitle = base
                    self.nowPlayingReciter = reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi")
                        ? "Muhammad Al-Minshawi (Murattal)" : reciter.name
                    self.updateNowPlayingInfo()
                }
            }
        }

        // When the last item in the custom range finishes, stop and clear Control Center (backup for currentItem observer).
        if let lastItem = items.last {
            let endObs = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: lastItem,
                queue: .main
            ) { [weak self] _ in
                guard let self = self, self.isPlayingCustomRange else { return }
                self.stop()
            }
            notificationObservers.append(endObs)
        }
    }

    private func customRangeTitle(ayahNum: Int, isBismillah: Bool, repeatWithinAyah: Int) -> String {
        let base = "\(customRangeSurahName) \(customRangeSurahNumber):\(ayahNum)"
        guard customRangeRepeatPerAyah > 1 else { return base }
        // Only show the ayah repeat count for this specific ayah, not cumulative repeats across sections
        let repeatInThisAyah = ((repeatWithinAyah - 1) % customRangeRepeatPerAyah) + 1
        return "\(base) (x\(repeatInThisAyah)/\(customRangeRepeatPerAyah))"
    }

    private func startAyahPlayback(
        surahNumber: Int,
        ayahNumber: Int,
        isBismillah: Bool,
        continueRecitation: Bool
    ) {
        removeAllObservers()

        guard
            let surah  = quranData.quran.first(where: { $0.id == surahNumber }),
            (1...surah.numberOfAyahs).contains(ayahNumber),
            let reciter = reciters.first(where: { $0.name == settings.reciter })
        else {
            presentPlaybackFailure("Could not prepare this ayah for playback. Please verify surah, ayah, and reciter settings.")
            return
        }

        setupAudioSession()
        isLoading = true

        if ayahRepeatCount > 1 || !continueRecitation {
            queuePlayer = nil

            guard let firstItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNumber, isBismillah: isBismillah) else {
                isLoading = false
                presentPlaybackFailure("Unable to load this ayah audio. Check your internet connection and try again.")
                return
            }
            firstItem.preferredForwardBufferDuration = 8

            let single = AVPlayer(playerItem: firstItem)
            single.actionAtItemEnd = .none
            player = single

            statusObserver = firstItem.observe(\.status) { [weak self] itm, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.idleTimerSet(true)
                    if itm.status == .readyToPlay {
                        self.player?.play()
                        withAnimation {
                            self.isPlaying = true
                            self.isPaused  = false
                            let base = "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
                            self.nowPlayingTitle = base + self.repeatSuffix(total: self.ayahRepeatCount, remaining: self.ayahRepeatRemaining)
                            self.nowPlayingReciter = reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi")
                                ? "Muhammad Al-Minshawi (Murattal)" : reciter.name
                            self.updateNowPlayingInfo()
                        }
                    } else {
                        self.presentPlaybackFailure("Unable to start ayah playback. Check your internet connection and try again.")
                    }
                }
            }

            let endObs = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let self = self else { return }
                
                guard let finishedItem = note.object as? AVPlayerItem,
                      finishedItem == self.player?.currentItem else { return }

                guard !self.didHandleSingleAyahEnd else { return }
                self.didHandleSingleAyahEnd = true

                if self.ayahRepeatRemaining > 1 {
                    self.ayahRepeatRemaining -= 1
                    self.player?.seek(to: .zero) { _ in
                        self.didHandleSingleAyahEnd = false
                        withAnimation {
                            self.nowPlayingTitle =
                                "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)" +
                                self.repeatSuffix(total: self.ayahRepeatCount,
                                                  remaining: self.ayahRepeatRemaining)
                            self.updateNowPlayingInfo()
                        }
                        self.player?.play()
                        self.isPlaying = true
                        self.isPaused  = false
                    }
                } else {
                    self.stop()
                }
            }

            notificationObservers.append(endObs)
            return
        }

        guard let firstItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNumber, isBismillah: isBismillah) else {
            isLoading = false
            presentPlaybackFailure("Unable to load this ayah audio. Check your internet connection and try again.")
            return
        }
        firstItem.preferredForwardBufferDuration = 8

        var nextItem: AVPlayerItem?
        if ayahNumber < surah.numberOfAyahs {
            nextItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNumber + 1)
            nextItem?.preferredForwardBufferDuration = 8
        }

        let q = AVQueuePlayer()
        q.actionAtItemEnd = .advance
        q.automaticallyWaitsToMinimizeStalling = true

        q.insert(firstItem, after: nil)

        if let ni = nextItem {
            q.insert(ni, after: firstItem)
        }

        queuePlayer = q
        player = q

        statusObserver = firstItem.observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                self.idleTimerSet(true)
                if itm.status == .readyToPlay {
                    self.queuePlayer?.play()
                    self.isPlaying = true
                    self.isPaused  = false

                    let base = "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
                    withAnimation {
                        self.nowPlayingTitle = base
                        self.nowPlayingReciter = reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi")
                            ? "Muhammad Al-Minshawi (Murattal)" : reciter.name
                        self.updateNowPlayingInfo()
                    }
                } else {
                    self.presentPlaybackFailure("Unable to continue ayah playback. Check your internet connection and try again.")
                }
            }
        }

        queuePlayerItemObserver = q.observe(\.currentItem, options: [.old, .new]) { [weak self] qPlayer, change in
            guard let self = self else { return }
            
            if qPlayer.currentItem == nil || qPlayer.items().isEmpty {
                DispatchQueue.main.async {
                    self.stop()
                }
                return
            }
            
            guard let newItem = change.newValue as? AVPlayerItem else { return }

            if let s = self.currentSurahNumber,
               let a = self.currentAyahNumber,
               let sur = self.quranData.quran.first(where: { $0.id == s }) {

                if a < sur.numberOfAyahs {
                    withAnimation {
                        self.currentAyahNumber = a + 1
                        if let recNow = reciters.first(where: { $0.name == self.settings.reciter }) {
                            self.nowPlayingTitle = "\(sur.nameTransliteration) \(s):\(self.currentAyahNumber!)"
                            self.nowPlayingReciter = recNow.ayahIdentifier.contains("minshawi") && !recNow.name.contains("Minshawi")
                                ? "Muhammad Al-Minshawi (Murattal)" : recNow.name
                            self.updateNowPlayingInfo()
                        }
                    }
                } else {
                    self.stop()
                    return
                }

                if self.continueRecitationFromAyah,
                   qPlayer.items().count < 2,
                   let rec = reciters.first(where: { $0.name == self.settings.reciter }) {

                    let nextAyah = self.currentAyahNumber! + 1
                    if nextAyah <= sur.numberOfAyahs,
                       let upcoming = self.makeItem(forSurah: sur, reciter: rec, ayahNumber: nextAyah) {
                        upcoming.preferredForwardBufferDuration = 8
                        qPlayer.insert(upcoming, after: newItem)
                    } else {}
                }
            }
        }
    }
    
    private func makeItem(
        forSurah surah: Surah,
        reciter: Reciter,
        ayahNumber: Int,
        isBismillah: Bool = false
    ) -> AVPlayerItem? {
        let globalId = quranData.quran.prefix(surah.id - 1).reduce(0) { $0 + $1.numberOfAyahs } + ayahNumber
        let urlStr = "https://cdn.islamic.network/quran/audio/\(reciter.ayahBitrate)/\(reciter.ayahIdentifier)/\(globalId).mp3"
        guard let url = URL(string: urlStr) else {
            presentPlaybackFailure("A valid audio link could not be created for this ayah.")
            return nil
        }
        return AVPlayerItem(url: url)
    }
    
    private func incrementAyahIfNeeded() {
        guard
            let s = currentSurahNumber,
            let a = currentAyahNumber,
            let sur = quranData.quran.first(where: { $0.id == s }),
            a < sur.numberOfAyahs
        else { return }
        currentAyahNumber = a + 1
    }
    
    func playBismillah() { playAyah(surahNumber: 1, ayahNumber: 1, isBismillah: true) }
    
    private func ayahSkipBackward() {
        ayahRepeatCount = 1
        ayahRepeatRemaining = 1

        guard let s = currentSurahNumber, let a = currentAyahNumber else { return }
        let now = Date()

        if let scheduledAt = ayahBackPendingRestartScheduledAt,
           now.timeIntervalSince(scheduledAt) >= ayahBackDoubleTapMinInterval {
            ayahBackPendingRestart?.cancel()
            ayahBackPendingRestart = nil
            ayahBackPendingRestartScheduledAt = nil
            if a > 1 {
                playAyah(surahNumber: s, ayahNumber: a - 1, continueRecitation: continueRecitationFromAyah)
            } else if s > 1, let prev = quranData.quran.first(where: { $0.id == s - 1 }) {
                playAyah(
                    surahNumber: s - 1,
                    ayahNumber: prev.numberOfAyahs,
                    continueRecitation: continueRecitationFromAyah
                )
            }
            return
        }
        if ayahBackPendingRestart != nil {
            return
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.ayahBackPendingRestart = nil
            self.ayahBackPendingRestartScheduledAt = nil
            self.pause()
            self.player?.seek(to: .zero) { [weak self] _ in self?.resume() }
            self.updateNowPlayingInfo()
        }
        ayahBackPendingRestart = work
        ayahBackPendingRestartScheduledAt = now
        DispatchQueue.main.asyncAfter(deadline: .now() + ayahBackRestartDelay, execute: work)
    }
    
    private func ayahSkipForward(continueRecitation: Bool) {
        ayahRepeatCount = 1
        ayahRepeatRemaining = 1
        
        guard
            let s = currentSurahNumber,
            let a = currentAyahNumber,
            let sur = quranData.quran.first(where: { $0.id == s })
        else { return }
        (a + 1) <= sur.numberOfAyahs
            ? playAyah(surahNumber: s, ayahNumber: a + 1, continueRecitation: continueRecitation)
            : stop()
    }
    
    private func updateNowPlayingInfo(clear: Bool = false) {
        let cmd = MPRemoteCommandCenter.shared()
        if clear {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            cmd.skipBackwardCommand.preferredIntervals = []
            cmd.skipForwardCommand.preferredIntervals = []
            return
        }
        // Control Center / Lock Screen: show backward/forward (no seconds) for surah/ayah; show 10 sec only for custom range
        cmd.skipBackwardCommand.preferredIntervals = isPlayingCustomRange ? [10] : []
        cmd.skipForwardCommand.preferredIntervals = isPlayingCustomRange ? [10] : []

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = nowPlayingTitle
        info[MPMediaItemPropertyArtist] = nowPlayingReciter
        if let dur = player?.currentItem?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(dur)
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player?.currentTime() ?? .zero)
        info[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        if let img = UIImage(named: "Al-Islam") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func saveLastListenedSurah() {
        guard
            nowPlayingTitle != nil,
            let num = currentSurahNumber,
            let rec = reciters.first(where: { $0.name == nowPlayingReciter }),
            let p = player
        else { return }

        let currDur = CMTimeGetSeconds(p.currentTime())
        let fullDur = CMTimeGetSeconds(p.currentItem?.duration ?? .zero)

        if isPlayingSurah, let sur = quranData.quran.first(where: { $0.id == num }) {
            let endReached = currDur == fullDur
            let nextSurahNumber: Int? = endReached
                ? (settings.reciteType == "Continue to Previous" ? (num > 1 ? num - 1 : nil)
                   : settings.reciteType == "End Recitation"     ? nil
                   : (num < 114 ? num + 1 : nil))
                : nil

            if let nxt = nextSurahNumber, let nSur = quranData.quran.first(where: { $0.id == nxt }) {
                withAnimation {
                    settings.lastListenedSurah = LastListenedSurah(
                        surahNumber: nxt,
                        surahName: nSur.nameTransliteration,
                        reciter: rec,
                        currentDuration: 0,
                        fullDuration: getSurahDuration(surahNumber: nxt)
                    )
                }
            } else {
                withAnimation {
                    settings.lastListenedSurah = LastListenedSurah(
                        surahNumber: num,
                        surahName: sur.nameTransliteration,
                        reciter: rec,
                        currentDuration: currDur,
                        fullDuration: fullDur
                    )
                }
            }
        }
    }

    /// Records listening history with surah-based deduplication.
    /// Saves only if the surah is not already present in history.
    func recordListeningHistory(surahNumber: Int, surahName: String, reciter: String) {
        // Don't save if this surah already exists anywhere in history.
        if listeningHistory.contains(where: { $0.surahNumber == surahNumber }) {
            return
        }

        if let lastSavedListeningSurahNumber, lastSavedListeningSurahNumber == surahNumber {
            return
        }

        let item = ListeningHistoryItem(
            surahNumber: surahNumber,
            surahName: surahName,
            reciter: Reciter(
                name: reciter,
                ayahIdentifier: "",
                ayahBitrate: "",
                surahLink: ""
            )
        )

        withAnimation {
            listeningHistory.insert(item, at: 0)
            listeningHistory = normalizeListeningHistory(listeningHistory)
        }

        lastSavedListeningSurahNumber = surahNumber
    }
    
    /// Records reading history with hybrid deduplication.
    /// Only saves if switching to different Surah OR moving 5+ ayahs away within same Surah.
    func recordReadingHistory(surahNumber: Int, surahName: String, ayahNumber: Int) {
        let normalizedAyah = max(1, ayahNumber)

        // Don't save duplicates already in history.
        if readingHistory.contains(where: { $0.surahNumber == surahNumber && $0.ayahNumber == normalizedAyah }) {
            return
        }
        
        let shouldSave: Bool
        
        if let last = lastSavedReadingPosition {
            if last.surahNumber != surahNumber {
                // Different surah - always save
                shouldSave = true
            } else if abs(last.ayahNumber - normalizedAyah) >= 5 {
                // Same surah but 5+ ayahs away - save
                shouldSave = true
            } else {
                // Same surah and within 4 ayahs - don't save
                shouldSave = false
            }
        } else {
            // First time - always save
            shouldSave = true
        }
        
        if shouldSave {
            let item = ReadingHistoryItem(
                surahNumber: surahNumber,
                surahName: surahName,
                ayahNumber: normalizedAyah
            )
            
            withAnimation {
                readingHistory.insert(item, at: 0)
                readingHistory = normalizeReadingHistory(readingHistory)
            }
            
            lastSavedReadingPosition = (surahNumber, normalizedAyah)
        }
    }

    private func normalizeListeningHistory(_ items: [ListeningHistoryItem]) -> [ListeningHistoryItem] {
        var seenSurahNumbers = Set<Int>()
        var normalized: [ListeningHistoryItem] = []

        for item in items {
            if seenSurahNumbers.insert(item.surahNumber).inserted {
                normalized.append(item)
            }
        }

        return Array(normalized.prefix(5))
    }

    private func normalizeReadingHistory(_ items: [ReadingHistoryItem]) -> [ReadingHistoryItem] {
        var seenKeys = Set<String>()
        var normalized: [ReadingHistoryItem] = []

        for item in items {
            let key = "\(item.surahNumber)-\(item.ayahNumber)"
            if seenKeys.insert(key).inserted {
                normalized.append(item)
            }
        }

        return Array(normalized.prefix(5))
    }

    private func persistListeningHistory() {
        let normalized = normalizeListeningHistory(listeningHistory)
        let hasChanged = normalized.count != listeningHistory.count ||
            normalized.map(\.surahNumber) != listeningHistory.map(\.surahNumber)
        if hasChanged {
            listeningHistory = normalized
            return
        }

        if let data = try? Settings.encoder.encode(normalized) {
            UserDefaults.standard.set(data, forKey: Self.listeningHistoryKey)
        }
    }

    private func persistReadingHistory() {
        let normalized = normalizeReadingHistory(readingHistory)
        let hasChanged = normalized.count != readingHistory.count ||
            normalized.map { "\($0.surahNumber)-\($0.ayahNumber)" } !=
            readingHistory.map { "\($0.surahNumber)-\($0.ayahNumber)" }
        if hasChanged {
            readingHistory = normalized
            return
        }

        if let data = try? Settings.encoder.encode(normalized) {
            UserDefaults.standard.set(data, forKey: Self.readingHistoryKey)
        }
    }

    private func loadHistoryFromDefaults() {
        if let listeningData = UserDefaults.standard.data(forKey: Self.listeningHistoryKey),
           let decodedListening = try? Settings.decoder.decode([ListeningHistoryItem].self, from: listeningData) {
            listeningHistory = normalizeListeningHistory(decodedListening)
            if let firstListening = listeningHistory.first {
                lastSavedListeningSurahNumber = firstListening.surahNumber
            }
        }

        if let readingData = UserDefaults.standard.data(forKey: Self.readingHistoryKey),
           let decodedReading = try? Settings.decoder.decode([ReadingHistoryItem].self, from: readingData) {
            let normalizedReading = decodedReading.map {
                ReadingHistoryItem(
                    surahNumber: $0.surahNumber,
                    surahName: $0.surahName,
                    ayahNumber: max(1, $0.ayahNumber)
                )
            }
            readingHistory = normalizeReadingHistory(normalizedReading)
            if let firstReading = readingHistory.first {
                lastSavedReadingPosition = (firstReading.surahNumber, firstReading.ayahNumber)
            }
        }
    }

    
    func getSurahDuration(surahNumber: Int) -> Double {
        #if os(watchOS)
        // The watch doesn't rely on this value, so just return 0
        return 0
        #else
        guard
            let rec = reciters.first(where: { $0.name == settings.reciter }),
            let url = URL(string: "\(rec.surahLink)\(String(format: "%03d", surahNumber)).mp3")
        else { return 0 }

        return CMTimeGetSeconds(AVURLAsset(url: url).duration)
        #endif
    }
    
    func idleTimerSet(_ disabled: Bool) {
        #if !os(watchOS)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }
}
