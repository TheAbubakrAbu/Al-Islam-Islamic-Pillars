import SwiftUI
import AVFoundation

struct NowPlayingView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer

    @State private var quranView: Bool
    @Binding private var scrollDown: Int
    @Binding private var searchText: String
    private let onOpenPlayback: ((PlaybackContext) -> Void)?

    @State private var confirmRemoveNote = false

    init(
        quranView: Bool = false,
        scrollDown: Binding<Int> = .constant(-1),
        searchText: Binding<String> = .constant(""),
        onOpenPlayback: ((PlaybackContext) -> Void)? = nil
    ) {
        self.quranView = quranView
        _scrollDown = scrollDown
        _searchText = searchText
        self.onOpenPlayback = onOpenPlayback
    }

    var body: some View {
        guard let playbackContext else {
            return AnyView(EmptyView())
        }

        #if os(iOS)
        return
            AnyView(
                VStack(spacing: 8) {
                    if quranView {
                        if let onOpenPlayback {
                            Button {
                                settings.hapticFeedback()
                                onOpenPlayback(playbackContext)
                            } label: {
                                playerRow(isPlaying: quranPlayer.isPlaying)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                destinationView(for: playbackContext)
                            } label: {
                                playerRow(isPlaying: quranPlayer.isPlaying)
                            }
                        }
                    } else {
                        playerRow(isPlaying: quranPlayer.isPlaying)
                    }
                }
                .contextMenu {
                    contextMenu(for: playbackContext)
                }
                .cornerRadius(24)
                .padding(.horizontal, 8)
                .transition(.opacity)
                // Always use the rounded-rectangle glass shape. Keying it on `isPlayingCustomRange` made the
                // glass morph between a capsule and a rectangle when state changed, which flashed as a dark
                // rectangle during the transition.
                .conditionalGlassEffect(rectangle: true)
            )
        #else
        return
            AnyView(
                Section(header: Text("NOW PLAYING")) {
                    VStack(spacing: 8) {
                        playerRow(isPlaying: quranPlayer.isPlaying)
                    }
                    .transition(.opacity)
                }
            )
        #endif
    }

    private var playbackContext: PlaybackContext? {
        guard
            let surahNumber = quranPlayer.currentSurahNumber,
            let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber }),
            quranPlayer.isPlaying || quranPlayer.isPaused
        else {
            return nil
        }

        return PlaybackContext(
            surah: surah,
            ayahNumber: quranPlayer.currentAyahNumber ?? 1,
            isPlaying: quranPlayer.isPlaying
        )
    }

    private var bookmarkIndex: Int? {
        let surah = quranPlayer.currentSurahNumber ?? 1
        let ayah = quranPlayer.currentAyahNumber ?? 1
        return settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: quranPlayer.currentSurahNumber ?? 1, ayah: quranPlayer.currentAyahNumber ?? 1)
    }

    private var isBookmarkedHere: Bool {
        bookmarkIndex != nil
    }

    private var currentNote: String {
        settings.bookmarkNoteText(surah: quranPlayer.currentSurahNumber ?? 1, ayah: quranPlayer.currentAyahNumber ?? 1)
    }

    @ViewBuilder
    private func destinationView(for context: PlaybackContext) -> some View {
        if quranPlayer.isPlayingSurah {
            SurahView(surah: context.surah)
        } else {
            SurahView(surah: context.surah, ayah: context.ayahNumber)
        }
    }

    @ViewBuilder
    private func transportButtons(isPlaying: Bool) -> some View {
        Image(systemName: "backward.fill")
            .font(.title2)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipBackward()
            }

        // Fine seek (±10s) only for full-surah playback, where a continuous timeline is meaningful.
        if quranPlayer.isPlayingSurah {
            Image(systemName: "gobackward.10")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.seek(by: -10)
                }
        }

        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.title2)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation {
                    isPlaying ? quranPlayer.pause() : quranPlayer.resume()
                }
            }

        if quranPlayer.isPlayingSurah {
            Image(systemName: "goforward.10")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.seek(by: 10)
                }
        }

        Image(systemName: "forward.fill")
            .font(.title2)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipForward()
            }
    }

    /// Live elapsed/duration progress bar for full-surah playback. Polls the player on a timeline so it
    /// updates without adding another player observer.
    @ViewBuilder
    private var surahProgressView: some View {
        if quranPlayer.isPlayingSurah {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                let elapsed = CMTimeGetSeconds(quranPlayer.player?.currentTime() ?? .zero)
                let rawTotal = CMTimeGetSeconds(quranPlayer.player?.currentItem?.duration ?? .zero)
                let total = (rawTotal.isFinite && rawTotal > 0) ? rawTotal : 0
                let safeElapsed = elapsed.isFinite ? max(0, elapsed) : 0

                VStack(spacing: 2) {
                    TinyProgressBar(
                        fraction: total > 0 ? safeElapsed / total : 0,
                        color: settings.accentColor.color
                    )

                    HStack {
                        Text(Self.formatMMSS(safeElapsed))
                        Spacer()
                        Text(Self.formatMMSS(total))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 3)
            }
        }
    }

    private static func formatMMSS(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func customRangeLineOne(start: Int, end: Int) -> String {
        let current = quranPlayer.customRangeCurrentIndex ?? 1
        let total = quranPlayer.customRangeTotalItems
            ?? max(1, (end - start + 1) * quranPlayer.customRangeRepeatPerAyah * quranPlayer.customRangeRepeatSection)
        return "Ayahs \(start)-\(end) (\(current)/\(total))"
    }

    private func customRangeLineTwo() -> String {
        let ayahProgress = quranPlayer.customRangeCurrentRepeatWithinAyah ?? 1
        let ayahTotal = max(1, quranPlayer.customRangeRepeatPerAyah)
        let sectionProgress = quranPlayer.customRangeRepeatSectionIndex ?? 1
        let sectionTotal = max(1, quranPlayer.customRangeRepeatSection)
        return "Ayah \(ayahProgress)/\(ayahTotal) · Section \(sectionProgress)/\(sectionTotal)"
    }

    /// For a custom range, keep the top title short (just "Name S:A") since the per-ayah/section detail
    /// shows on its own lines below. Other playback uses the full now-playing title.
    private var displayTitle: String? {
        if quranPlayer.isPlayingCustomRange,
           let surahNumber = quranPlayer.currentSurahNumber,
           let ayahNumber = quranPlayer.currentAyahNumber,
           let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber }) {
            return "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
        }
        return quranPlayer.nowPlayingTitle
    }

    @ViewBuilder
    private func playerRow(isPlaying: Bool) -> some View {
        #if os(iOS)
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    titleBlock
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    transportButtons(isPlaying: isPlaying)
                }
            }

            surahProgressView
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                let surah = quranPlayer.currentSurahNumber ?? 1
                let ayah = quranPlayer.currentAyahNumber ?? 1

                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah, ayah: ayah)
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
        #else
        VStack(alignment: .center, spacing: 6) {
            titleBlock

            HStack(spacing: 12) {
                transportButtons(isPlaying: isPlaying)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
        .padding(4)
        .overlay(alignment: .bottomTrailing) {
            stopButton
                .padding(.vertical, 4)
                .padding(.trailing, -2)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        #endif
    }

    @ViewBuilder
    private var titleBlock: some View {
        if let title = displayTitle {
            Text(title)
                .foregroundColor(.primary)
                #if os(iOS)
                .font(.headline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                #else
                .font(.caption)
                .lineLimit(2)
                #endif
        }

        if let reciter = quranPlayer.nowPlayingReciter {
            Text(reciter)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                #if os(iOS)
                .minimumScaleFactor(0.5)
                #endif
        }

        if quranPlayer.isPlayingCustomRange,
           let start = quranPlayer.customRangeStartAyah,
           let end = quranPlayer.customRangeEndAyah {
            VStack(alignment: .leading, spacing: 1) {
                Text(customRangeLineOne(start: start, end: end))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(customRangeLineTwo())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var stopButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                quranPlayer.stop()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .imageScale(.large)
        }
        .tint(.secondary)
    }

    private func toggleBookmarkWithNoteGuard() {
        let surah = quranPlayer.currentSurahNumber ?? 1
        let ayah = quranPlayer.currentAyahNumber ?? 1

        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    @ViewBuilder
    private func contextMenu(for context: PlaybackContext) -> some View {
        let isFavorite = settings.isSurahFavorite(surah: context.surah.id)
        let isBookmarked = settings.isBookmarked(surah: context.surah.id, ayah: context.ayahNumber)

        Button(role: .destructive) {
            settings.hapticFeedback()
            withAnimation {
                quranPlayer.stop()
            }
        } label: {
            Label("Stop Playing", systemImage: "xmark.circle.fill")
        }

        Divider()

        Button {
            settings.hapticFeedback()
            quranPlayer.playSurah(surahNumber: context.surah.id, surahName: context.surah.nameTransliteration)
        } label: {
            Label("Play from Beginning", systemImage: "memories")
        }

        Button {
            settings.hapticFeedback()
            quranPlayer.addSurahToQueue(surahNumber: context.surah.id, surahName: context.surah.nameTransliteration)
        } label: {
            Label("Add Current Surah to Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
        }

        if !quranPlayer.surahQueue.isEmpty {
            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    quranPlayer.clearSurahQueue()
                }
            } label: {
                Label("Clear Queue (\(quranPlayer.surahQueue.count))", systemImage: "text.badge.xmark")
            }
        }

        Divider()

        Button(role: isFavorite ? .destructive : nil) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleSurahFavorite(surah: context.surah.id)
            }
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button(role: isBookmarked ? .destructive : nil) {
            settings.hapticFeedback()
            toggleBookmarkWithNoteGuard()
        } label: {
            Label(
                isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
            )
        }

        Divider()

        if quranView {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    searchText = ""
                    scrollDown = context.surah.id
                    self.endEditing()
                }
            } label: {
                Label("Scroll To Surah", systemImage: "arrow.down.circle")
            }
        }
    }
}

struct PlaybackContext {
    let surah: Surah
    let ayahNumber: Int
    let isPlaying: Bool
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        NowPlayingView()
    }
}
