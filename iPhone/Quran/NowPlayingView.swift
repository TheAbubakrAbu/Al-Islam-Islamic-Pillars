import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer

    @State private var quranView: Bool
    @Binding private var scrollDown: Int
    @Binding private var searchText: String

    @State private var confirmRemoveNote = false

    init(
        quranView: Bool = false,
        scrollDown: Binding<Int> = .constant(-1),
        searchText: Binding<String> = .constant("")
    ) {
        self.quranView = quranView
        _scrollDown = scrollDown
        _searchText = searchText
    }

    var body: some View {
        guard let playbackContext else {
            return AnyView(EmptyView())
        }

        #if os(iOS)
        return AnyView(
            VStack(spacing: 8) {
                if quranView {
                    NavigationLink {
                        destinationView(for: playbackContext)
                    } label: {
                        playerRow(isPlaying: quranPlayer.isPlaying)
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
            .conditionalGlassEffect(rectangle: quranPlayer.isPlayingCustomRange)
        )
        #else
        return AnyView(
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
        return settings.bookmarkedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }

    private var bookmark: BookmarkedAyah? {
        bookmarkIndex.map { settings.bookmarkedAyahs[$0] }
    }

    private var isBookmarkedHere: Bool {
        bookmarkIndex != nil
    }

    private var currentNote: String {
        (bookmark?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func destinationView(for context: PlaybackContext) -> some View {
        if quranPlayer.isPlayingSurah {
            AyahsView(surah: context.surah)
        } else {
            AyahsView(surah: context.surah, ayah: context.ayahNumber)
        }
    }

    @ViewBuilder
    private func transportButtons(isPlaying: Bool) -> some View {
        if quranPlayer.isPlayingCustomRange {
            Image(systemName: "gobackward.10")
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.seek(by: -10)
                }
        } else {
            Image(systemName: "backward.fill")
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.skipBackward()
                }
        }

        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.title2)
            .foregroundColor(settings.accentColor.color)
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation {
                    isPlaying ? quranPlayer.pause() : quranPlayer.resume()
                }
            }

        if quranPlayer.isPlayingCustomRange {
            Image(systemName: "goforward.10")
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.seek(by: 10)
                }
        } else {
            Image(systemName: "forward.fill")
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.skipForward()
                }
        }
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

    @ViewBuilder
    private func playerRow(isPlaying: Bool) -> some View {
        #if os(iOS)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                titleBlock
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                transportButtons(isPlaying: isPlaying)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        .confirmationDialog("Remove bookmark and delete note?", isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                let surah = quranPlayer.currentSurahNumber ?? 1
                let ayah = quranPlayer.currentAyahNumber ?? 1

                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah, ayah: ayah)
            }
            Button("Cancel") {}
        } message: {
            Text("This ayah has a note. Unbookmarking will delete the note.")
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
        if let title = quranPlayer.nowPlayingTitle {
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

        if isBookmarkedHere, !currentNote.isEmpty {
            confirmRemoveNote = true
        } else {
            settings.hapticFeedback()
            settings.toggleBookmark(surah: surah, ayah: ayah)
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

        Divider()

        Button(role: isFavorite ? .destructive : nil) {
            settings.hapticFeedback()
            settings.toggleSurahFavorite(surah: context.surah.id)
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

private struct PlaybackContext {
    let surah: Surah
    let ayahNumber: Int
    let isPlaying: Bool
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        NowPlayingView()
    }
}
