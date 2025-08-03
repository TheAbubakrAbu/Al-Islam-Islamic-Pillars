import SwiftUI

struct SurahRow: View {
    @EnvironmentObject var settings: Settings
    
    let surah: Surah
    var ayah: Int?
    var end: Bool?
    var favoriteSurahs: Set<Int>?
    
    var body: some View {
        ZStack {
            if let favoriteSurahs = favoriteSurahs {
                RoundedRectangle(cornerRadius: 8)
                    .fill(favoriteSurahs.contains(surah.id)
                          ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                          : .white.opacity(0.0001))
                    #if !os(watchOS)
                    .padding(.leading, 19)
                    .padding(.horizontal, settings.defaultView ? -31 : -26)
                    #else
                    .padding(.horizontal, -8)
                    .padding(.vertical, -3)
                    #endif
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25))
                    #if !os(watchOS)
                    .padding(.leading, 19)
                    .padding(.horizontal, settings.defaultView ? -31 : -26)
                    #else
                    .padding(.horizontal, -8)
                    .padding(.vertical, -3)
                    #endif
            }
                
            #if !os(watchOS)
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if let ayah = ayah {
                                if end != nil {
                                    Text("Ends at \(surah.id):\(ayah)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Starts at \(surah.id):\(ayah)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("\(surah.numberOfAyahs) Ayahs")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.secondary)
                                
                                Text(surah.type == "meccan" ? "🕋" : "🕌")
                                    .font(.caption2)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                        
                        Text(surah.nameEnglish)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(surah.nameArabic) - \(arabicNumberString(from: surah.id))")
                            .font(.headline)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(settings.accentColor.color)
                        
                        Text("\(surah.nameTransliteration) - \(surah.id)")
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 8)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #else
            VStack {
                HStack {
                    Spacer()
                    
                    Text("\(surah.nameArabic) - \(arabicNumberString(from: surah.id))")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)
                }
                
                HStack {
                    Text("\(surah.id) - \(surah.nameTransliteration)")
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #endif
        }
    }
}

struct SurahAyahRow: View {
    @EnvironmentObject var settings: Settings
    
    var surah: Surah
    var ayah: Ayah
    
    var favoriteSurahs: Set<Int>?
    
    var body: some View {
        ZStack {
            if let favoriteSurahs = favoriteSurahs {
                RoundedRectangle(cornerRadius: 8)
                    .fill(favoriteSurahs.contains(surah.id)
                          ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                          : .white.opacity(0.0001))
                    #if !os(watchOS)
                    .padding(.leading, 19)
                    .padding(.horizontal, settings.defaultView ? -31 : -26)
                    #else
                    .padding(.horizontal, -8)
                    .padding(.vertical, 3)
                    #endif
            }
            
            HStack {
                VStack {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.headline)
                    
                    Text(surah.nameTransliteration)
                        .font(.caption)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                #if !os(watchOS)
                .frame(width: 65, alignment: .center)
                #else
                .frame(width: 40, alignment: .center)
                #endif
                .foregroundColor(settings.accentColor.color)
                .padding(.trailing, 8)
                
                VStack {
                    if(settings.showArabicText) {
                        let text = settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic
                        
                        Text(settings.beginnerMode ? text.map { "\($0) " }.joined() : text)
                            .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if(settings.showTransliteration) {
                        Text(ayah.textTransliteration)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if(settings.showEnglishTranslation) {
                        Text(ayah.textEnglish)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
    }
}

private enum _FmtCache {
    static let mmss: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()
}

@inline(__always)
func formatMMSS(_ seconds: Double) -> String {
    _FmtCache.mmss.string(from: seconds) ?? "00:00"
}

struct LeftSwipeActions: View {
    @EnvironmentObject private var settings: Settings

    let surah: Int
    let favoriteSurahs: Set<Int>
    
    var bookmarkedAyahs: Set<String>?
    var bookmarkedSurah: Int?
    var bookmarkedAyah: Int?
    
    private var isFavorite: Bool {
        favoriteSurahs.contains(surah)
    }
    
    private var isBookmarked: Bool {
        if let bookmarkedAyahs = bookmarkedAyahs, let surah = bookmarkedSurah, let ayah = bookmarkedAyah {
            return bookmarkedAyahs.contains("\(surah)-\(ayah)")
        }
        
        return false
    }

    var body: some View {
        #if !os(watchOS)
        Button {
            settings.hapticFeedback()
            settings.toggleSurahFavorite(surah: surah)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
        .tint(settings.accentColor.color)
        
        if let surah = bookmarkedSurah, let ayah = bookmarkedAyah {
            Button {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah, ayah: ayah)
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
            }
            .tint(settings.accentColor.color)
        }
        #endif
    }
}

struct RightSwipeActions: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let surahID: Int
    let surahName: String
    
    let ayahID: Int?
    let certainReciter: Bool
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    
    init(
        surahID: Int,
        surahName: String,
        ayahID: Int? = nil,
        certainReciter: Bool = false,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>
    ) {
        self.surahID = surahID
        self.surahName = surahName
        self.ayahID = ayahID
        self.certainReciter = certainReciter
        self._searchText = searchText
        self._scrollToSurahID = scrollToSurahID
    }

    var body: some View {
        #if !os(watchOS)
        Button {
            settings.hapticFeedback()
            quranPlayer.playSurah(
                surahNumber: surahID,
                surahName: surahName,
                certainReciter: certainReciter
            )
        } label: {
            Image(systemName: "play.fill")
        }
        .tint(settings.accentColor.color)

        if let ayah = ayahID {
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surahID, ayahNumber: ayah)
            } label: {
                Image(systemName: "play.circle")
            }
        }

        Button {
            settings.hapticFeedback()
            withAnimation {
                searchText = ""
                scrollToSurahID = surahID
                self.endEditing()
            }
        } label: {
            Image(systemName: "arrow.down.circle")
        }
        .tint(.secondary)
        #endif
    }
}

struct SurahContextMenu: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    let surahID: Int
    let surahName: String
    
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    
    var lastListened: Bool?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surahID)
    }

    var body: some View {
        Button(role: isFavorite ? .destructive : .cancel) {
            settings.hapticFeedback()
            settings.toggleSurahFavorite(surah: surahID)
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }
        
        if lastListened == nil {
            Button {
                settings.hapticFeedback()
                quranPlayer.playSurah(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Play Surah", systemImage: "play.fill")
            }
        }

        Button {
            settings.hapticFeedback()
            
            withAnimation {
                searchText = ""
                scrollToSurahID = surahID
                self.endEditing()
            }
        } label: {
            Text("Scroll To Surah")
            Image(systemName: "arrow.down.circle")
        }
    }
}

struct AyahContextMenuModifier: ViewModifier {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    let surah: Int
    let ayah: Int
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    
    let lastRead: Bool
    
    @State var shareSettings = ShareSettings()
    @State var showAyahSheet = false

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(watchOS)
        content
        #else
        content
            .contextMenu {
                if lastRead {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                        }
                    } label: { Label("Remove", systemImage: "trash") }
                    
                    Divider()
                }
                
                Button(role: isBookmarked ? .destructive : .cancel) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: surah, ayah: ayah)
                } label: {
                    Label(
                        isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah, ayahNumber: ayah)
                } label: {
                    Label("Play Ayah", systemImage: "play.circle")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(
                        surahNumber: surah,
                        ayahNumber: ayah,
                        continueRecitation: true
                    )
                } label: {
                    Label("Play from Ayah", systemImage: "play.circle.fill")
                }

                Button {
                    settings.hapticFeedback()
                    shareSettings = ShareSettings(
                        arabic: settings.showArabicText,
                        transliteration: settings.showTransliteration,
                        translation: settings.showEnglishTranslation
                    )
                    showAyahSheet = true
                } label: {
                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                }

                Divider()

                if let surahObj = quranData.quran.first(where: { $0.id == surah }) {
                    SurahContextMenu(
                        surahID: surahObj.id,
                        surahName: surahObj.nameTransliteration,
                        favoriteSurahs: favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
            }
            .sheet(isPresented: $showAyahSheet) {
                ShareAyahSheet(
                    shareSettings: $shareSettings,
                    surahNumber: surah,
                    ayahNumber: ayah
                )
            }
        #endif
    }
}

extension View {
    func ayahContextMenuModifier(
        surah: Int,
        ayah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>,
        lastRead: Bool = false
    ) -> some View {
        self.modifier(AyahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID,
            lastRead: lastRead
        ))
    }
}

#if !os(watchOS)
struct LastListenedSurahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let lastListenedSurah: LastListenedSurah
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var body: some View {
        guard let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber })
        else { return AnyView(EmptyView()) }

        return AnyView(
            Section(header: Text("LAST LISTENED TO SURAH")) {
                VStack {
                    NavigationLink(destination:
                        AyahsView(surah: surah)
                            .transition(.opacity)
                            .animation(.easeInOut, value: lastListenedSurah.surahName)
                    ) {
                        HStack {
                            Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
                                .font(.headline)
                                .foregroundColor(settings.accentColor.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            Spacer()

                            if !quranPlayer.isPlaying && !quranPlayer.isPaused {
                                Menu {
                                    Button {
                                        settings.hapticFeedback()
                                        quranPlayer.playSurah(
                                            surahNumber: lastListenedSurah.surahNumber,
                                            surahName: lastListenedSurah.surahName,
                                            certainReciter: true)
                                    } label: {
                                        Label("Play from Last Listened", systemImage: "play.fill")
                                    }

                                    Button {
                                        settings.hapticFeedback()
                                        quranPlayer.playSurah(
                                            surahNumber: lastListenedSurah.surahNumber,
                                            surahName: surah.nameTransliteration)
                                    } label: {
                                        Label("Play from Beginning", systemImage: "memories")
                                    }
                                } label: {
                                    Image(systemName: "play.fill")
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(settings.accentColor.color)
                                        .minimumScaleFactor(0.75)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 1)

                    HStack {
                        Text(lastListenedSurah.reciter.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer()

                        Text("\(formatMMSS(lastListenedSurah.currentDuration)) / \(formatMMSS(lastListenedSurah.fullDuration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(.vertical, 8)
            }
            .swipeActions(edge: .trailing) {
                RightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    certainReciter: true,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            .swipeActions(edge: .leading) {
                LeftSwipeActions(
                    surah: surah.id,
                    favoriteSurahs: favoriteSurahs
                )
            }
            #if !os(watchOS)
            .contextMenu {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedSurah = nil
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                }

                Divider()

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: lastListenedSurah.surahName,
                        certainReciter: true
                    )
                } label: {
                    Label("Play from Last Listened", systemImage: "play.fill")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }

                Divider()

                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    lastListened: true
                )
            }
            #endif
            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        )
    }
}
#endif

struct LastReadAyahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }

    var body: some View {
        Section(header: Text("LAST READ AYAH")) {
            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                SurahAyahRow(surah: surah, ayah: ayah, favoriteSurahs: favoriteSurahs)
            }
            .swipeActions(edge: .trailing) {
                RightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    ayahID: ayah.id,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            .swipeActions(edge: .leading) {
                LeftSwipeActions(
                    surah: surah.id,
                    favoriteSurahs: favoriteSurahs,
                    bookmarkedAyahs: bookmarkedAyahs,
                    bookmarkedSurah: surah.id,
                    bookmarkedAyah: ayah.id
                )
            }
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                lastRead: true
            )
        }
    }
}

struct BookmarkAyahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let bookmarkedAyah: BookmarkedAyah
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(bookmarkedAyah.surah)-\(bookmarkedAyah.ayah)")
    }

    var body: some View {
        guard
            let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah }),
            let ayah = surah.ayahs.first(where: { $0.id == bookmarkedAyah.ayah })
        else { return AnyView(EmptyView()) }

        return AnyView(
            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                SurahAyahRow(surah: surah, ayah: ayah, favoriteSurahs: favoriteSurahs)
            }
            .swipeActions(edge: .trailing) {
                RightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    ayahID: ayah.id,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            .swipeActions(edge: .leading) {
                LeftSwipeActions(
                    surah: surah.id,
                    favoriteSurahs: favoriteSurahs,
                    bookmarkedAyahs: bookmarkedAyahs,
                    bookmarkedSurah: bookmarkedAyah.surah,
                    bookmarkedAyah: bookmarkedAyah.ayah
                )
            }
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        )
    }
}

struct FavoriteSurahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let favoriteSurah: Int
    
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var body: some View {
        guard let surah = quranData.quran.first(where: { $0.id == favoriteSurah })
        else { return AnyView(EmptyView()) }

        return AnyView(
            NavigationLink(destination: AyahsView(surah: surah)) {
                SurahRow(surah: surah)
            }
            .swipeActions(edge: .trailing) {
                RightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            .swipeActions(edge: .leading) {
                LeftSwipeActions(
                    surah: surah.id,
                    favoriteSurahs: favoriteSurahs
                )
            }
            #if !os(watchOS)
            .contextMenu {
                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            #endif
        )
    }
}

struct AyahSearchResultRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }

    var body: some View {
        Section(header: Text("AYAH SEARCH RESULT")) {
            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                SurahAyahRow(surah: surah, ayah: ayah, favoriteSurahs: favoriteSurahs)
            }
            .swipeActions(edge: .trailing) {
                RightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            .swipeActions(edge: .leading) {
                LeftSwipeActions(
                    surah: surah.id,
                    favoriteSurahs: favoriteSurahs,
                    bookmarkedAyahs: bookmarkedAyahs,
                    bookmarkedSurah: surah.id,
                    bookmarkedAyah: ayah.id,
                )
            }
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
    }
}

struct AyahSearchRow: View {
    @EnvironmentObject private var settings: Settings
    
    let surahName: String
    let surah: Int
    let ayah:  Int
    let query: String
    let arabic: String
    let english: String?
    let translit: String?
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(surahName) \(surah):\(ayah)")
                .font(.caption)
                .foregroundColor(settings.accentColor.color)
            
            if settings.showArabicText {
                HighlightedSnippet(
                    source: arabic,
                    term: query,
                    font: .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    selectable: false
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
            }
            
            if settings.showTransliteration,
               let tr = translit {
                HighlightedSnippet(
                    source: tr,
                    term: query,
                    font: .subheadline,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    selectable: false
                )
            }
            
            if settings.showEnglishTranslation,
               let en = english {
                HighlightedSnippet(
                    source: en,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    selectable: false
                )
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            RightSwipeActions(
                surahID: surah,
                surahName: surahName,
                ayahID: ayah,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        .swipeActions(edge: .leading) {
            LeftSwipeActions(
                surah: surah,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                bookmarkedSurah: surah,
                bookmarkedAyah: ayah
            )
        }
        .ayahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }
}
