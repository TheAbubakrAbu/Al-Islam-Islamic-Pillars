import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var quranView: Bool
    @Binding private var scrollDown: Int
    @Binding private var searchText: String
    
    init(
        quranView: Bool,
        scrollDown: Binding<Int> = .constant(-1),
        searchText: Binding<String> = .constant("")
    ) {
        self.quranView = quranView
        self._scrollDown = scrollDown
        self._searchText = searchText
    }
    
    var body: some View {
        guard
            let surahNum = quranPlayer.currentSurahNumber,
            let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNum }),
            (quranPlayer.isPlaying || quranPlayer.isPaused)
        else { return AnyView(EmptyView()) }
        
        let ayahNum = quranPlayer.currentAyahNumber ?? 1
        let isPlaying = quranPlayer.isPlaying
        
        #if !os(watchOS)
        return AnyView(
            VStack(spacing: 8) {
                if quranView {
                    NavigationLink {
                        if quranPlayer.isPlayingSurah {
                            AyahsView(surah: surah)
                        } else {
                            AyahsView(surah: surah, ayah: ayahNum)
                        }
                    } label: {
                        playerRow(isPlaying: isPlaying)
                    }
                } else {
                    playerRow(isPlaying: isPlaying)
                }
            }
            .contextMenu { contextMenu(for: surah, ayah: ayahNum) }
            .padding(.horizontal, 8)
            .transition(.opacity)
        )
        #else
        return AnyView(
            Section(header: Text("NOW PLAYING")) {
                VStack(spacing: 8) {
                    playerRow(isPlaying: isPlaying)
                }
                .transition(.opacity)
            }
        )
        #endif
    }
    
    @ViewBuilder
    private func transportButtons(isPlaying: Bool) -> some View {
        Image(systemName: "backward.fill")
            .foregroundColor(settings.accentColor.color)
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipBackward()
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

        Image(systemName: "forward.fill")
            .foregroundColor(settings.accentColor.color)
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipForward()
            }
    }

    @ViewBuilder
    private func playerRow(isPlaying: Bool) -> some View {
        #if os(watchOS)
        VStack(alignment: .center, spacing: 6) {
            if let title = quranPlayer.nowPlayingTitle {
                Text(title)
                    .foregroundColor(.primary)
                    .font(.caption)
                    .lineLimit(2)
            }
            if let reciter = quranPlayer.nowPlayingReciter {
                Text(reciter)
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                transportButtons(isPlaying: isPlaying)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
        .padding(4)
        .overlay(alignment: .bottomTrailing) {
            Button {
                settings.hapticFeedback()
                withAnimation { quranPlayer.stop() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
            }
            .tint(.secondary)
            .padding(.vertical, 4)
            .padding(.trailing, -2)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)

        #else
        let spacing: CGFloat = 16
        HStack {
            VStack(alignment: .leading) {
                if let title = quranPlayer.nowPlayingTitle {
                    Text(title)
                        .foregroundColor(.primary)
                        .font(.headline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                if let reciter = quranPlayer.nowPlayingReciter {
                    Text(reciter)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            Spacer()

            HStack(spacing: spacing) {
                transportButtons(isPlaying: isPlaying)
            }
            .font(.body)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        .confirmationDialog("Remove bookmark and delete note?", isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                let surah = quranPlayer.currentSurahNumber ?? 1
                let ayah = quranPlayer.currentAyahNumber ?? 1
                
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah, ayah: ayah)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This ayah has a note. Unbookmarking will delete the note.")
        }
        #endif
    }
    
    private var bookmarkIndex: Int? {
        let surah = quranPlayer.currentSurahNumber ?? 1
        let ayah = quranPlayer.currentAyahNumber ?? 1
        
        return settings.bookmarkedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }
    
    private var bookmark: BookmarkedAyah? {
        bookmarkIndex.flatMap { settings.bookmarkedAyahs[$0] }
    }
    
    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    
    private var currentNote: String {
        (bookmark?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @State private var confirmRemoveNote = false

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
    private func contextMenu(for surah: Surah, ayah: Int) -> some View {
        let isFav = settings.isSurahFavorite(surah: surah.id)
        let isBm = settings.isBookmarked(surah: surah.id, ayah: ayah)
        
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
            quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
        } label: {
            Label("Play from Beginning", systemImage: "memories")
        }
        
        Divider()
        
        Button {
            settings.hapticFeedback()
            settings.toggleSurahFavorite(surah: surah.id)
        } label: {
            Label(
                isFav ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFav ? "star.fill" : "star"
            )
        }
        
        Button {
            settings.hapticFeedback()
            toggleBookmarkWithNoteGuard()
        } label: {
            Label(
                isBm ? "Unbookmark Ayah" : "Bookmark Ayah",
                systemImage: isBm ? "bookmark.fill" : "bookmark"
            )
        }
        
        Divider()
        
        if quranView {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    searchText = ""
                    scrollDown = surah.id
                    self.endEditing()
                }
            } label: {
                Label("Scroll To Surah", systemImage: "arrow.down.circle")
            }
        }
    }

}
