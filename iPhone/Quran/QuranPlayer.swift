import SwiftUI
import AVFoundation
import MediaPlayer

class QuranPlayer: ObservableObject {
    static let shared = QuranPlayer()

    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared

    @Published var isLoading = false
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false

    @Published var currentSurahNumber: Int?
    @Published var currentAyahNumber: Int?
    @Published var isPlayingSurah = false
    
    @Published var showInternetAlert = false

    private var backButtonClickCount = 0
    private var backButtonClickTimestamp: Date?

    var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?

    var nowPlayingTitle: String?
    var nowPlayingReciter: String?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        setupRemoteTransportControls()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        deactivateAudioSession()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            self.pause()
        } else if type == .ended,
                  let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
            player?.play()
            isPlaying = true
            isPaused = false
        }
        updateNowPlayingInfo()
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.player?.play()
                self.isPlaying = true
                self.isPaused = false
                self.updateNowPlayingInfo()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.stopCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.pause()
                self.isPlaying = false
                self.isPaused = false
                return .success
            }
            return .commandFailed
        }

        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            if self.isPlayingSurah {
                self.skipBackward()
            } else {
                self.skipBackwardAyah()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            if self.isPlayingSurah {
                self.skipForward()
            } else {
                self.skipForwardAyah()
            }
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false

        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                let time = CMTime(seconds: event.positionTime, preferredTimescale: 1)
                self.player?.seek(to: time) { _ in
                    self.updateNowPlayingInfo()
                }
                return .success
            }
            return .commandFailed
        }
    }

    func skipBackward() {
        if isPlayingSurah {
            guard currentSurahNumber != nil else {
                return
            }

            let now = Date()
            if let lastClickTime = backButtonClickTimestamp, now.timeIntervalSince(lastClickTime) < 0.75 {
                self.backButtonClickCount += 1
            } else {
                self.backButtonClickCount = 1
            }
            self.backButtonClickTimestamp = now

            if self.backButtonClickCount == 2 {
                playPreviousSurah()
                self.backButtonClickCount = 0
            } else {
                self.pause()
                player?.seek(to: .zero) { [weak self] _ in
                    self?.resume()
                }
                updateNowPlayingInfo()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.saveLastListenedSurah()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                    self.backButtonClickCount = 0
                }
            }
        } else {
            skipBackwardAyah()
        }
    }

    func skipForward() {
        if isPlayingSurah {
            guard let currentSurahNumber = self.currentSurahNumber else {
                return
            }

            if currentSurahNumber < 114 {
                let nextSurahNumber = currentSurahNumber + 1
                if let nextSurah = self.quranData.quran.first(where: { $0.id == nextSurahNumber }) {
                    self.playSurah(surahNumber: nextSurahNumber, surahName: nextSurah.nameTransliteration)
                }
            }
        } else {
            skipForwardAyah()
        }
    }

    func skipBackwardAyah() {
        guard let currentSurahNumber = self.currentSurahNumber,
              let currentAyahNumber = self.currentAyahNumber else {
            return
        }

        let now = Date()
        if let lastClickTime = backButtonClickTimestamp, now.timeIntervalSince(lastClickTime) < 0.75 {
            self.backButtonClickCount += 1
        } else {
            self.backButtonClickCount = 1
        }
        self.backButtonClickTimestamp = now

        if self.backButtonClickCount == 2 {
            if currentAyahNumber > 1 {
                playAyah(surahNumber: currentSurahNumber, ayahNumber: currentAyahNumber - 1)
            } else if currentSurahNumber > 1 {
                let previousSurahNumber = currentSurahNumber - 1
                if let previousSurah = self.quranData.quran.first(where: { $0.id == previousSurahNumber }) {
                    playAyah(surahNumber: previousSurahNumber, ayahNumber: previousSurah.numberOfAyahs)
                }
            }
            self.backButtonClickCount = 0
        } else {
            self.pause()
            player?.seek(to: .zero)
            updateNowPlayingInfo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                self.backButtonClickCount = 0
            }
        }
    }

    func skipForwardAyah(continueRecitation: Bool = false) {
        guard let currentSurahNumber = self.currentSurahNumber,
              let currentAyahNumber = self.currentAyahNumber,
              let surah = self.quranData.quran.first(where: { $0.id == currentSurahNumber }) else {
            return
        }

        if currentAyahNumber < surah.numberOfAyahs {
            playAyah(surahNumber: currentSurahNumber, ayahNumber: currentAyahNumber + 1, continueRecitation: continueRecitation)
        } else {
            stop()
        }
    }

    private func updateNowPlayingInfo(clear: Bool = false) {
        var nowPlayingInfo = [String: Any]()

        if clear {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlayingTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlayingReciter

        if let duration = player?.currentItem?.duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(duration)
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player?.currentTime() ?? .zero)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate

        if let image = UIImage(named: "Al-Islam") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func playSurah(surahNumber: Int, surahName: String, certainReciter: Bool = false, skipSurah: Bool = false) {
        guard (1...114).contains(surahNumber) else {
            print("Invalid Surah number. It must be between 1 and 114.")
            return
        }

        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber = nil
        }
        isPlayingSurah = true
        backButtonClickCount = 0

        let reciterToUse: Reciter

        if certainReciter, let lastReadReciter = settings.lastListenedSurah?.reciter {
            reciterToUse = lastReadReciter
        } else if let selectedReciter = reciters.first(where: { $0.ayahIdentifier == settings.reciter }) {
            reciterToUse = selectedReciter
        } else {
            print("Selected reciter is not in the reciters list")
            return
        }

        let surahNumberString = String(format: "%03d", surahNumber)
        let urlStr = "\(reciterToUse.surahLink)\(surahNumberString).mp3"

        let currentDuration: Double = (certainReciter && surahNumber == settings.lastListenedSurah?.surahNumber) ? settings.lastListenedSurah?.currentDuration ?? 0.0 : 0.0
        let fullDuration = settings.lastListenedSurah?.fullDuration ?? 0.0

        if let url = URL(string: urlStr) {
            DispatchQueue.main.async {
                self.setupAudioSession()
                self.isLoading = true
                self.player?.pause()

                let playerItem = AVPlayerItem(url: url)
                self.statusObserver = playerItem.observe(\.status) { [weak self] playerItem, _ in
                    switch playerItem.status {
                    case .readyToPlay:
                        self?.isLoading = false
                        self?.player?.play()
                        self?.isPlaying = true
                        self?.isPaused = false
                        self?.nowPlayingTitle = certainReciter ? surahName : "Surah \(surahNumber): \(surahName)"
                        self?.nowPlayingReciter = reciterToUse.name
                        self?.updateNowPlayingInfo()
                        
                        if !certainReciter || skipSurah {
                            self?.saveLastListenedSurah()
                        }

                        if certainReciter && currentDuration < fullDuration {
                            let seekTime = CMTime(seconds: currentDuration, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                            self?.player?.seek(to: seekTime) { success in
                                if success {
                                    self?.updateNowPlayingInfo()
                                } else {
                                    print("Seek failed")
                                }
                            }
                        }

                    case .failed, .unknown:
                        self?.isLoading = false
                        self?.isPlaying = false
                        self?.isPaused = false
                        self?.showInternetAlert = true
                    @unknown default:
                        self?.isLoading = false
                        self?.isPlaying = false
                        self?.isPaused = false
                        self?.showInternetAlert = true
                    }
                }

                self.player = AVPlayer(playerItem: playerItem)

                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: self.player?.currentItem,
                    queue: .main
                ) { [weak self] _ in
                    guard let self = self else { return }
                    switch self.settings.reciteType {
                    case "Continue to Previous":
                        self.playPreviousSurah(certainReciter: certainReciter)
                    case "End Recitation":
                        self.stop()
                    default:
                        self.playNextSurah(certainReciter: certainReciter)
                    }
                }
            }
        } else {
            self.showInternetAlert = true
            print("Invalid URL for the Surah audio.")
        }
    }

    func playNextSurah(certainReciter: Bool = false) {
        guard let currentSurahNumber = self.currentSurahNumber else {
            return
        }

        if currentSurahNumber < 114 {
            let nextSurahNumber = currentSurahNumber + 1
            if let nextSurah = self.quranData.quran.first(where: { $0.id == nextSurahNumber }) {
                if certainReciter {
                    playSurah(surahNumber: nextSurahNumber, surahName: "Surah \(nextSurah.id): \(nextSurah.nameTransliteration)", certainReciter: certainReciter, skipSurah: true)
                } else {
                    playSurah(surahNumber: nextSurahNumber, surahName: nextSurah.nameTransliteration)
                }
            }
        } else {
            self.stop()
        }
    }

    func playPreviousSurah(certainReciter: Bool = false) {
        guard let currentSurahNumber = self.currentSurahNumber else {
            return
        }

        if currentSurahNumber > 1 {
            let previousSurahNumber = currentSurahNumber - 1
            if let previousSurah = self.quranData.quran.first(where: { $0.id == previousSurahNumber }) {
                if certainReciter {
                    playSurah(surahNumber: previousSurahNumber, surahName: "Surah \(previousSurah.id): \(previousSurah.nameTransliteration)", certainReciter: certainReciter, skipSurah: true)
                } else {
                    playSurah(surahNumber: previousSurahNumber, surahName: previousSurah.nameTransliteration)
                }
            }
        } else {
            self.stop()
        }
    }

    func playAyah(surahNumber: Int, ayahNumber: Int, isBismillah: Bool = false, continueRecitation: Bool = false) {
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }),
              (1...surah.numberOfAyahs).contains(ayahNumber) else {
            print("Invalid Ayah number.")
            return
        }

        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber = ayahNumber
        }
        isPlayingSurah = false

        let cumulativeAyahCount = quranData.quran.prefix(surah.id - 1).reduce(0) { $0 + $1.numberOfAyahs }
        let ayahId = cumulativeAyahCount + ayahNumber
        
        let reciterToUse: Reciter

        if let selectedReciter = reciters.first(where: { $0.ayahIdentifier == settings.reciter }) {
            reciterToUse = selectedReciter
        } else {
            print("Selected reciter is not in the reciters list")
            return
        }
        
        let urlStr = "https://cdn.islamic.network/quran/audio/\(reciterToUse.ayahBitrate)/\(reciterToUse.ayahIdentifier)/\(ayahId).mp3"

        if let url = URL(string: urlStr) {
            DispatchQueue.main.async {
                self.setupAudioSession()
                self.isLoading = true
                self.player?.pause()

                let playerItem = AVPlayerItem(url: url)
                self.statusObserver = playerItem.observe(\.status) { [weak self] playerItem, _ in
                    switch playerItem.status {
                    case .readyToPlay:
                        self?.isLoading = false
                        self?.player?.play()
                        self?.isPlaying = true
                        self?.isPaused = false
                        self?.nowPlayingTitle = isBismillah ? "Bismillah" : "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
                        self?.nowPlayingReciter = reciterToUse.name
                        self?.updateNowPlayingInfo()
                    case .failed, .unknown:
                        self?.isLoading = false
                        self?.isPlaying = false
                        self?.isPaused = false
                        self?.showInternetAlert = true
                    @unknown default:
                        self?.isLoading = false
                        self?.isPlaying = false
                        self?.isPaused = false
                        self?.showInternetAlert = true
                    }
                }

                self.player = AVPlayer(playerItem: playerItem)

                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: self.player?.currentItem,
                    queue: .main
                ) { [weak self] _ in
                    if continueRecitation && ayahNumber < surah.numberOfAyahs {
                        self?.skipForwardAyah(continueRecitation: true)
                    } else {
                        self?.stop()
                    }
                }
            }
        } else {
            self.showInternetAlert = true
        }
    }

    
    func playBismillah() {
        playAyah(surahNumber: 1, ayahNumber: 1, isBismillah: true)
    }

    func pause(saveInfo: Bool = true) {
        if saveInfo {
            saveLastListenedSurah()
        }
        
        player?.pause()
        
        withAnimation {
            isPlaying = false
            isPaused = true
        }
        
        updateNowPlayingInfo()
    }

    func resume() {
        player?.play()
        
        withAnimation {
            isPlaying = true
            isPaused = false
        }
        
        updateNowPlayingInfo()
    }

    func seek(by seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1)) { _ in
            self.updateNowPlayingInfo()
            self.saveLastListenedSurah()
        }
    }

    func stop() {
        saveLastListenedSurah()

        player?.pause()
        
        withAnimation {
            player = nil
            currentSurahNumber = nil
            currentAyahNumber = nil
            isPlayingSurah = false
            isPlaying = false
            isPaused = false
        }
        
        updateNowPlayingInfo(clear: true)
        deactivateAudioSession()
    }
    
    func saveLastListenedSurah() {
        if let surahName = nowPlayingTitle, let currentSurahNumber = currentSurahNumber {
            if let reciter = reciters.first(where: { $0.name == nowPlayingReciter }) {
                if let player = player {
                    let currentDuration = CMTimeGetSeconds(player.currentTime())
                    let fullDuration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime())

                    if isPlayingSurah {
                        if currentDuration == fullDuration {
                            let nextSurahNumber: Int?
                            
                            switch settings.reciteType {
                            case "Continue to Previous":
                                nextSurahNumber = currentSurahNumber > 1 ? currentSurahNumber - 1 : nil
                            case "End Recitation":
                                nextSurahNumber = nil
                            default:
                                nextSurahNumber = currentSurahNumber < 114 ? currentSurahNumber + 1 : nil
                            }

                            if let nextSurahNumber = nextSurahNumber, let nextSurah = quranData.quran.first(where: { $0.id == nextSurahNumber }) {
                                let nextFullDuration = getSurahDuration(surahNumber: nextSurahNumber)
                                withAnimation {
                                    settings.lastListenedSurah = LastListenedSurah(
                                        surahNumber: nextSurahNumber,
                                        surahName: "Surah \(nextSurah.id): \(nextSurah.nameTransliteration)",
                                        reciter: reciter,
                                        currentDuration: 0,
                                        fullDuration: nextFullDuration
                                    )
                                }
                            } else {
                                withAnimation {
                                    settings.lastListenedSurah = LastListenedSurah(
                                        surahNumber: currentSurahNumber,
                                        surahName: surahName,
                                        reciter: reciter,
                                        currentDuration: 0,
                                        fullDuration: fullDuration
                                    )
                                }
                            }
                        } else {
                            withAnimation {
                                settings.lastListenedSurah = LastListenedSurah(
                                    surahNumber: currentSurahNumber,
                                    surahName: surahName,
                                    reciter: reciter,
                                    currentDuration: currentDuration,
                                    fullDuration: fullDuration
                                )
                            }
                        }
                    }
                }
            } else {
                print("Reciter not found")
            }
        }
    }

    func getSurahDuration(surahNumber: Int) -> Double {
        var duration: Double = 0.0
        let surahNumberString = String(format: "%03d", surahNumber)
        
        if let selectedReciter = reciters.first(where: { $0.ayahIdentifier == settings.reciter }) {
            let urlStr = "\(selectedReciter.surahLink)\(surahNumberString).mp3"
            
            if let url = URL(string: urlStr) {
                let asset = AVURLAsset(url: url)
                let assetDuration = asset.duration
                duration = CMTimeGetSeconds(assetDuration)
            }
        }
        return duration
    }
}

#if !os(watchOS)
struct NowPlayingView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State var surahsView: Bool
    
    @Binding var scrollDown: Int
    @Binding var searchText: String
    
    init(surahsView: Bool, scrollDown: Binding<Int> = .constant(-1), searchText: Binding<String> = .constant("")) {
        _surahsView = State(initialValue: surahsView)
        _scrollDown = scrollDown
        _searchText = searchText
    }

    var body: some View {
        if let currentSurahNumber = quranPlayer.currentSurahNumber, let currentSurah = quranPlayer.quranData.quran.first(where: { $0.id == currentSurahNumber }) {
            VStack(spacing: 8) {
                if surahsView {
                    NavigationLink(destination: quranPlayer.isPlayingSurah ? AyahsView(surah: currentSurah).transition(.opacity)
                        .animation(.easeInOut, value: quranPlayer.currentSurahNumber) : AyahsView(surah: currentSurah, ayah: quranPlayer.currentAyahNumber ?? nil).transition(.opacity)
                        .animation(.easeInOut, value: quranPlayer.currentSurahNumber)) {
                        content
                    }
                } else {
                    content
                }
            }
            .contextMenu {
                Button(action: {
                    settings.hapticFeedback()
                    
                    quranPlayer.playSurah(surahNumber: currentSurahNumber, surahName: currentSurah.nameTransliteration)
                }) {
                    Label("Play from Beginning", systemImage: "memories")
                }
                
                Divider()
                
                Button(action: {
                    settings.hapticFeedback()
                    
                    settings.toggleSurahFavorite(surah: currentSurah)
                }) {
                    Label(settings.isSurahFavorite(surah: currentSurah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: currentSurah) ? "star.fill" : "star")
                }
                
                if let ayah = quranPlayer.currentAyahNumber {
                    Button(action: {
                        settings.hapticFeedback()
                        
                        settings.toggleBookmark(surah: currentSurah.id, ayah: ayah)
                    }) {
                        Label(settings.isBookmarked(surah: currentSurah.id, ayah: ayah) ? "Unbookmark Ayah" : "Bookmark Ayah", systemImage: settings.isBookmarked(surah: currentSurah.id, ayah: ayah) ? "bookmark.fill" : "bookmark")
                    }
                }
                
                Divider()
                
                if surahsView, let surahNumber = quranPlayer.currentSurahNumber {
                    Button(action: {
                        settings.hapticFeedback()
                        
                        withAnimation {
                            searchText = ""
                            settings.groupBySurah = true
                            scrollDown = surahNumber
                            self.endEditing()
                        }
                    }) {
                        Text("Scroll To Surah")
                        Image(systemName: "arrow.down.circle")
                    }
                }
            }
        }
    }

    var content: some View {
        HStack {
            VStack(alignment: .leading) {
                if let title = quranPlayer.nowPlayingTitle {
                    Text(title)
                        .foregroundColor(.primary)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                if let reciter = quranPlayer.nowPlayingReciter {
                    Text(reciter)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            
            Spacer()
            
            VStack {
                HStack(spacing: 16) {
                    Image(systemName: "backward.fill")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()
                            quranPlayer.skipBackward()
                        }

                    if quranPlayer.isPlaying {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .foregroundColor(settings.accentColor.color)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation {
                                    quranPlayer.pause()
                                }
                            }
                    } else {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(settings.accentColor.color)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation {
                                    quranPlayer.resume()
                                }
                            }
                    }

                    Image(systemName: "forward.fill")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()
                            quranPlayer.skipForward()
                        }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 8)
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
    }
}
#endif
