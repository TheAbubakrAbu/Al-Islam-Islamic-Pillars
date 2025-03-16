import SwiftUI

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
