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
        
        #if !os(watchOS)
        let ayahNum = quranPlayer.currentAyahNumber ?? 1
        let isPlaying = quranPlayer.isPlaying
        
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
        return AnyView(EmptyView())
        #endif
    }
    
    @ViewBuilder
    private func playerRow(isPlaying: Bool) -> some View {
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
            
            Spacer(minLength: 12)
            
            HStack(spacing: 16) {
                Image(systemName: "backward.fill")
                    .font(.body)
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
        #if !os(watchOS)
        .background(Color(UIColor.secondarySystemBackground))
        #endif
        .cornerRadius(10)
        .padding(.horizontal, 8)
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
    }
    
    @ViewBuilder
    private func contextMenu(for surah: Surah, ayah: Int) -> some View {
        let isFav = settings.isSurahFavorite(surah: surah.id)
        let isBm = settings.isBookmarked(surah: surah.id, ayah: ayah)
        
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
            settings.toggleBookmark(surah: surah.id, ayah: ayah)
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
