import SwiftUI

struct AyahRow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var ayahBeginnerMode = false
    
    #if !os(watchOS)
    @State private var shareSettings = ShareSettings()
    @State private var showingAyahSheet = false
    #endif
    
    let surah: Surah
    let ayah: Ayah
    
    @Binding var scrollDown: Int?
    @Binding var searchText: String
    
    private func spacedArabic(_ text: String) -> String {
        (settings.beginnerMode || ayahBeginnerMode) ? text.map { "\($0) " }.joined() : text
    }
    
    var body: some View {
        let isBookmarked = settings.isBookmarked(surah: surah.id, ayah: ayah.id)
        let showArabic = settings.showArabicText
        let showTranslit = settings.showTransliteration
        let showEnglish = settings.showEnglishTranslation
        let fontSizeEN = settings.englishFontSize
        
        ZStack {
            if let currentSurah = quranPlayer.currentSurahNumber, let currentAyah = quranPlayer.currentAyahNumber, currentSurah == surah.id {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        currentAyah == ayah.id
                        ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                        : .white.opacity(0.0001)
                    )
                    .padding(.horizontal, -12)
                    .transition(.opacity)
                    .animation(.easeInOut, value: currentAyah == ayah.id)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(arabicNumberString(from: ayah.id))
                        .foregroundColor(settings.accentColor.color)
                        #if !os(watchOS)
                        .font(.custom("KFGQPCHafsEx1UthmanicScript-Reg", size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize))
                        #else
                        .font(.custom("KFGQPCHafsEx1UthmanicScript-Reg", size: UIFont.preferredFont(forTextStyle: .title2).pointSize))
                        #endif
                    
                    Spacer()
                    
                    #if os(watchOS)
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(settings.accentColor.color)
                        .font(.system(size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                        .onTapGesture {
                            settings.hapticFeedback()
                            settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                        }
                    #else
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(settings.accentColor.color)
                            .font(.system(size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                            .transition(.opacity)
                    }
                    
                    Menu {
                        menuBlock(isBookmarked: isBookmarked)
                    } label: {
                        ZStack(alignment: .trailing) {
                            Rectangle().fill(.clear).frame(width: 32, height: 32)
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .title2).pointSize))
                                .foregroundColor(settings.accentColor.color)
                                .padding(.trailing, -2)
                        }
                    }
                    .sheet(isPresented: $showingAyahSheet) {
                        ShareAyahSheet(
                            shareSettings: $shareSettings,
                            surahNumber: surah.id,
                            ayahNumber: ayah.id
                        )
                    }
                    #endif
                }
                .padding(.top, -8)
                .padding(.bottom, settings.showArabicText ? -7 : 0)
                
                Group {
                    #if !os(watchOS)
                    Button {
                        if !searchText.isEmpty {
                            settings.hapticFeedback()
                            scrollDown = ayah.id
                        }
                    } label: {
                        ayahTextBlock(
                            showArabic: showArabic,
                            showTranslit: showTranslit,
                            showEnglish: showEnglish,
                            fontSizeEN: fontSizeEN
                        )
                    }
                    .disabled(searchText.isEmpty)
                    #else
                    ayahTextBlock(
                        showArabic: showArabic,
                        showTranslit: showTranslit,
                        showEnglish: showEnglish,
                        fontSizeEN: fontSizeEN
                    )
                    #endif
                }
                .padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .lineLimit(nil)
        #if !os(watchOS)
        .contextMenu {
            menuBlock(isBookmarked: isBookmarked)
        }
        #endif
        .animation(.easeInOut, value: quranPlayer.currentAyahNumber)
    }
    
    @ViewBuilder
    private func ayahTextBlock(showArabic: Bool, showTranslit: Bool, showEnglish: Bool, fontSizeEN: CGFloat) -> some View {
        VStack(alignment: .leading) {
            if showArabic {
                HighlightedSnippet(
                    source: spacedArabic(settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic),
                    term: searchText,
                    font: .custom(settings.fontArabic, size: settings.fontArabicSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    beginnerMode: (settings.beginnerMode || ayahBeginnerMode)
                )
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 4)
            }
            
            if showTranslit {
                HighlightedSnippet(
                    source: "\(ayah.id). \(ayah.textTransliteration)",
                    term: searchText,
                    font: .system(size: fontSizeEN),
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
                .padding(.vertical, 4)
            }
            
            if showEnglish {
                HighlightedSnippet(
                    source: showTranslit ? (ayah.textEnglish) : "\(ayah.id). \(ayah.textEnglish)",
                    term: searchText,
                    font: .system(size: fontSizeEN),
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
                .padding(.vertical, 4)
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    @ViewBuilder
    private func menuBlock(isBookmarked: Bool) -> some View {
        #if !os(watchOS)
        let repeatOptions = [2, 3, 5, 10]

        VStack(alignment: .leading) {
            Button(role: isBookmarked ? .destructive : nil) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            } label: {
                Label(
                    isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                    systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                )
            }
            
            if settings.showArabicText && !settings.beginnerMode {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                } label: {
                    Label("Beginner Mode",
                          systemImage: ayahBeginnerMode
                          ? "textformat.size.larger.ar"
                          : "textformat.size.ar")
                }
            }
            
            Divider()
            
            Menu {
                ForEach(repeatOptions, id: \.self) { count in
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                    } label: {
                        Label("Repeat \(count)×", systemImage: "repeat")
                    }
                }
            } label: {
                Label("Repeat Ayah", systemImage: "repeat")
            }
            
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            } label: {
                Label("Play Ayah", systemImage: "play.circle")
            }
            
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            } label: {
                Label("Play from Ayah", systemImage: "play.circle.fill")
            }
            
            Divider()
            
            Button {
                settings.hapticFeedback()
                shareSettings = ShareSettings(
                    arabic: settings.showArabicText,
                    transliteration: settings.showTransliteration,
                    translation: settings.showEnglishTranslation
                )
                showingAyahSheet = true
            } label: {
                Label("Share Ayah", systemImage: "square.and.arrow.up")
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
        #endif
    }
}
