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
    
    private var continueRecitationFromAyah = false
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        setupRemoteTransportControls()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deactivateAudioSession()
    }
}

extension QuranPlayer {
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed:", error)
        }
    }
    
    private func deactivateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deactivation failed:", error)
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        
        if type == .began {
            pause()
        } else if type == .ended,
                  let opts = info[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume) {
            player?.play()
            isPlaying = true
            isPaused = false
        }
        updateNowPlayingInfo()
    }
    
    private func setupRemoteTransportControls() {
        let cc = MPRemoteCommandCenter.shared()
        
        cc.playCommand.addTarget { [unowned self] _ in
            if !self.isPlaying {
                self.player?.play()
                self.isPlaying = true
                self.isPaused = false
                self.updateNowPlayingInfo()
                return .success
            }
            return .commandFailed
        }
        cc.pauseCommand.addTarget { [unowned self] _ in
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        cc.stopCommand.addTarget { [unowned self] _ in
            if self.isPlaying {
                self.pause()
                self.isPlaying = false
                self.isPaused = false
                return .success
            }
            return .commandFailed
        }
        cc.previousTrackCommand.addTarget { [unowned self] _ in
            self.skipBackward()
            return .success
        }
        cc.nextTrackCommand.addTarget { [unowned self] _ in
            self.skipForward()
            return .success
        }
        cc.skipBackwardCommand.isEnabled = false
        cc.skipForwardCommand.isEnabled = false
        cc.changePlaybackPositionCommand.addTarget { [unowned self] evt in
            guard let evt = evt as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let time = CMTime(seconds: evt.positionTime, preferredTimescale: 1)
            self.player?.seek(to: time) { _ in
                self.updateNowPlayingInfo()
            }
            return .success
        }
    }
}

extension QuranPlayer {
    func skipBackward() {
        guard player != nil else { return }
        if isPlayingSurah {
            surahSkipBackward()
        } else {
            ayahSkipBackward()
        }
    }
    
    func skipForward() {
        guard player != nil else { return }
        if isPlayingSurah {
            surahSkipForward()
        } else {
            ayahSkipForward(continueRecitation: continueRecitationFromAyah)
        }
    }
    
    func pause(saveInfo: Bool = true) {
        if saveInfo { saveLastListenedSurah() }
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
        guard let p = player else { return }
        let current = CMTimeGetSeconds(p.currentTime())
        let newTime = current + seconds
        p.seek(to: CMTime(seconds: newTime, preferredTimescale: 1)) { _ in
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
}

extension QuranPlayer {
    func playSurah(surahNumber: Int, surahName: String, certainReciter: Bool = false, skipSurah: Bool = false) {
        guard (1...114).contains(surahNumber) else { return }
        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber = nil
            isPlayingSurah = true
        }
        continueRecitationFromAyah = false
        backButtonClickCount = 0
        
        guard let reciterToUse = reciters.first(where: { $0.ayahIdentifier == settings.reciter }) else { return }
        let finalReciter: Reciter
        if certainReciter, let lastRead = settings.lastListenedSurah?.reciter {
            finalReciter = lastRead
        } else {
            finalReciter = reciterToUse
        }
        
        let sn = String(format: "%03d", surahNumber)
        let urlStr = "\(finalReciter.surahLink)\(sn).mp3"
        
        let currentDur: Double = (certainReciter && surahNumber == settings.lastListenedSurah?.surahNumber)
            ? (settings.lastListenedSurah?.currentDuration ?? 0.0)
            : 0.0
        let fullDur = settings.lastListenedSurah?.fullDuration ?? 0.0
        
        guard let url = URL(string: urlStr) else {
            showInternetAlert = true
            return
        }
        
        DispatchQueue.main.async {
            self.setupAudioSession()
            self.isLoading = true
            self.player?.pause()
            
            let item = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: item)
            
            self.statusObserver = item.observe(\.status) { [weak self] itm, _ in
                guard let self = self else { return }
                switch itm.status {
                case .readyToPlay:
                    self.isLoading = false
                    self.player?.play()
                    self.isPlaying = true
                    self.isPaused = false
                    self.nowPlayingTitle = "Surah \(surahNumber): \(surahName)"
                    self.nowPlayingReciter = finalReciter.name
                    self.updateNowPlayingInfo()
                    
                    if !certainReciter || skipSurah == false {
                        self.saveLastListenedSurah()
                    }
                    if certainReciter && currentDur < fullDur {
                        let seekTime = CMTime(seconds: currentDur, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        self.player?.seek(to: seekTime) { ok in
                            if ok { self.updateNowPlayingInfo() }
                        }
                    }
                case .failed, .unknown:
                    self.isLoading = false
                    self.isPlaying = false
                    self.isPaused = false
                    self.showInternetAlert = true
                @unknown default:
                    self.isLoading = false
                    self.isPlaying = false
                    self.isPaused = false
                    self.showInternetAlert = true
                }
            }
            
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
    }
    
    func playNextSurah(certainReciter: Bool = false) {
        guard let n = currentSurahNumber else { return }
        if n < 114 {
            let next = n + 1
            guard let nextSurah = quranData.quran.first(where: { $0.id == next }) else { return }
            playSurah(surahNumber: next, surahName: nextSurah.nameTransliteration, certainReciter: certainReciter, skipSurah: true)
        } else {
            stop()
        }
    }
    
    func playPreviousSurah(certainReciter: Bool = false) {
        guard let n = currentSurahNumber else { return }
        if n > 1 {
            let prev = n - 1
            guard let surah = quranData.quran.first(where: { $0.id == prev }) else { return }
            playSurah(surahNumber: prev, surahName: surah.nameTransliteration, certainReciter: certainReciter, skipSurah: true)
        } else {
            stop()
        }
    }
    
    private func surahSkipBackward() {
        guard currentSurahNumber != nil else { return }
        let now = Date()
        if let t = backButtonClickTimestamp, now.timeIntervalSince(t) < 0.75 {
            backButtonClickCount += 1
        } else {
            backButtonClickCount = 1
        }
        backButtonClickTimestamp = now
        
        if backButtonClickCount == 2 {
            playPreviousSurah()
            backButtonClickCount = 0
        } else {
            pause()
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
    }
    
    private func surahSkipForward() {
        playNextSurah()
    }
}

extension QuranPlayer {
    func playAyah(surahNumber: Int, ayahNumber: Int, isBismillah: Bool = false, continueRecitation: Bool = false) {
        guard
            let surah = quranData.quran.first(where: { $0.id == surahNumber }),
            (1...surah.numberOfAyahs).contains(ayahNumber)
        else { return }
        
        withAnimation {
            currentSurahNumber = surahNumber
            currentAyahNumber = ayahNumber
            isPlayingSurah = false
        }
        continueRecitationFromAyah = continueRecitation
        
        let countBefore = quranData.quran.prefix(surah.id - 1).reduce(0) { $0 + $1.numberOfAyahs }
        let ayahId = countBefore + ayahNumber
        
        guard let reciter = reciters.first(where: { $0.ayahIdentifier == settings.reciter }) else { return }
        let urlStr = "https://cdn.islamic.network/quran/audio/\(reciter.ayahBitrate)/\(reciter.ayahIdentifier)/\(ayahId).mp3"
        guard let url = URL(string: urlStr) else {
            showInternetAlert = true
            return
        }
        
        DispatchQueue.main.async {
            self.setupAudioSession()
            self.isLoading = true
            self.player?.pause()
            
            let item = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: item)
            
            self.statusObserver = item.observe(\.status) { [weak self] itm, _ in
                guard let self = self else { return }
                switch itm.status {
                case .readyToPlay:
                    self.isLoading = false
                    self.player?.play()
                    self.isPlaying = true
                    self.isPaused = false
                    self.nowPlayingTitle = isBismillah ? "Bismillah" : "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
                    self.nowPlayingReciter = reciter.name
                    self.updateNowPlayingInfo()
                case .failed, .unknown:
                    self.isLoading = false
                    self.isPlaying = false
                    self.isPaused = false
                    self.showInternetAlert = true
                @unknown default:
                    self.isLoading = false
                    self.isPlaying = false
                    self.isPaused = false
                    self.showInternetAlert = true
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: self.player?.currentItem,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                if self.continueRecitationFromAyah, ayahNumber < surah.numberOfAyahs {
                    self.ayahSkipForward(continueRecitation: true)
                } else {
                    self.stop()
                }
            }
        }
    }
    
    func playBismillah() {
        playAyah(surahNumber: 1, ayahNumber: 1, isBismillah: true)
    }
    
    private func ayahSkipBackward() {
        guard let s = currentSurahNumber, let a = currentAyahNumber else { return }
        let now = Date()
        if let t = backButtonClickTimestamp, now.timeIntervalSince(t) < 0.75 {
            backButtonClickCount += 1
        } else {
            backButtonClickCount = 1
        }
        backButtonClickTimestamp = now
        
        if backButtonClickCount == 2 {
            if a > 1 {
                playAyah(surahNumber: s, ayahNumber: a - 1, continueRecitation: continueRecitationFromAyah)
            } else if s > 1 {
                let prevSurahNumber = s - 1
                if let prevSurah = quranData.quran.first(where: { $0.id == prevSurahNumber }) {
                    playAyah(surahNumber: prevSurahNumber, ayahNumber: prevSurah.numberOfAyahs, continueRecitation: continueRecitationFromAyah)
                }
            }
            backButtonClickCount = 0
        } else {
            pause()
            player?.seek(to: .zero)
            updateNowPlayingInfo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                self.backButtonClickCount = 0
            }
        }
    }
    
    private func ayahSkipForward(continueRecitation: Bool) {
        guard let s = currentSurahNumber,
              let a = currentAyahNumber,
              let surah = quranData.quran.first(where: { $0.id == s }) else { return }
        let nextAyah = a + 1
        if nextAyah <= surah.numberOfAyahs {
            playAyah(surahNumber: s, ayahNumber: nextAyah, continueRecitation: continueRecitation)
        } else {
            stop()
        }
    }
}

extension QuranPlayer {
    private func updateNowPlayingInfo(clear: Bool = false) {
        var info = [String: Any]()
        if clear {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        info[MPMediaItemPropertyTitle] = nowPlayingTitle
        info[MPMediaItemPropertyArtist] = nowPlayingReciter
        if let d = player?.currentItem?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(d)
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player?.currentTime() ?? .zero)
        info[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        if let img = UIImage(named: "Al-Islam") {
            let art = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
            info[MPMediaItemPropertyArtwork] = art
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    func saveLastListenedSurah() {
        guard nowPlayingTitle != nil, let sNumber = currentSurahNumber, let reciter = reciters.first(where: { $0.name == nowPlayingReciter}),
            let p = player
        else { return }
        
        let currentDuration = CMTimeGetSeconds(p.currentTime())
        let fullDuration = CMTimeGetSeconds(p.currentItem?.duration ?? .zero)
        
        if isPlayingSurah, let currentSurah = quranData.quran.first(where: { $0.id == sNumber }) {
            if currentDuration == fullDuration {
                let nextSurahNumber: Int?
                switch settings.reciteType {
                case "Continue to Previous":
                    nextSurahNumber = sNumber > 1 ? sNumber - 1 : nil
                case "End Recitation":
                    nextSurahNumber = nil
                default:
                    nextSurahNumber = sNumber < 114 ? sNumber + 1 : nil
                }
                if let n = nextSurahNumber, let nxtSurah = quranData.quran.first(where: { $0.id == n }) {
                    let nxtFull = getSurahDuration(surahNumber: n)
                    withAnimation {
                        settings.lastListenedSurah = LastListenedSurah(
                            surahNumber: n,
                            surahName: nxtSurah.nameTransliteration,
                            reciter: reciter,
                            currentDuration: 0,
                            fullDuration: nxtFull
                        )
                    }
                } else {
                    withAnimation {
                        settings.lastListenedSurah = LastListenedSurah(
                            surahNumber: sNumber,
                            surahName: currentSurah.nameTransliteration,
                            reciter: reciter,
                            currentDuration: 0,
                            fullDuration: fullDuration
                        )
                    }
                }
            } else {
                withAnimation {
                    settings.lastListenedSurah = LastListenedSurah(
                        surahNumber: sNumber,
                        surahName: currentSurah.nameTransliteration,
                        reciter: reciter,
                        currentDuration: currentDuration,
                        fullDuration: fullDuration
                    )
                }
            }
        }
    }
    
    func getSurahDuration(surahNumber: Int) -> Double {
        var duration: Double = 0
        let sn = String(format: "%03d", surahNumber)
        guard let selReciter = reciters.first(where: { $0.ayahIdentifier == settings.reciter }) else {
            return duration
        }
        let urlStr = "\(selReciter.surahLink)\(sn).mp3"
        if let url = URL(string: urlStr) {
            let asset = AVURLAsset(url: url)
            duration = CMTimeGetSeconds(asset.duration)
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
        if let currentSurahNumber = quranPlayer.currentSurahNumber,
           let currentSurah = quranPlayer.quranData.quran.first(where: { $0.id == currentSurahNumber }) {
            VStack(spacing: 8) {
                if surahsView {
                    NavigationLink(
                        destination: quranPlayer.isPlayingSurah
                            ? AyahsView(surah: currentSurah)
                                .transition(.opacity)
                                .animation(.easeInOut, value: quranPlayer.currentSurahNumber)
                            : AyahsView(surah: currentSurah, ayah: quranPlayer.currentAyahNumber ?? 1)
                                .transition(.opacity)
                                .animation(.easeInOut, value: quranPlayer.currentSurahNumber)
                    ) {
                        content
                    }
                } else {
                    content
                }
            }
            .contextMenu {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: currentSurahNumber,
                        surahName: currentSurah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }
                
                Divider()
                
                Button {
                    settings.hapticFeedback()
                    settings.toggleSurahFavorite(surah: currentSurah)
                } label: {
                    Label(
                        settings.isSurahFavorite(surah: currentSurah) ? "Unfavorite Surah" : "Favorite Surah",
                        systemImage: settings.isSurahFavorite(surah: currentSurah) ? "star.fill" : "star"
                    )
                }
                
                if let ayah = quranPlayer.currentAyahNumber {
                    Button {
                        settings.hapticFeedback()
                        settings.toggleBookmark(surah: currentSurah.id, ayah: ayah)
                    } label: {
                        Label(
                            settings.isBookmarked(surah: currentSurah.id, ayah: ayah) ? "Unbookmark Ayah" : "Bookmark Ayah",
                            systemImage: settings.isBookmarked(surah: currentSurah.id, ayah: ayah) ? "bookmark.fill" : "bookmark"
                        )
                    }
                }
                
                Divider()
                
                if surahsView {
                    Button {
                        settings.hapticFeedback()
                        withAnimation {
                            searchText = ""
                            settings.groupBySurah = true
                            scrollDown = currentSurahNumber
                            endEditing()
                        }
                    } label: {
                        Label("Scroll To Surah", systemImage: "arrow.down.circle")
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
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 8)
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
    }
    
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
