import SwiftUI

struct QuranView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var searchText = ""
    @State private var scrollToSurahID: Int = -1
    @State private var showingSettingsSheet = false
    
    @State private var verseHits: [VerseIndexEntry] = []
    @State private var hitOffset = 0
    @State private var hasMoreHits = true
    @State private var showAyahSearch = false
    private let hitPageSize = 10
    
    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()
    
    var lastReadSurah: Surah? {
        quranData.quran.first(where: { $0.id == settings.lastReadSurah })
    }

    var lastReadAyah: Ayah? {
        lastReadSurah?.ayahs.first(where: { $0.id == settings.lastReadAyah })
    }
    
    func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        QuranView.arFormatter.number(from: arabicNumber)?.intValue
    }

    func arabicNumberString(from number: Int) -> String {
        QuranView.arFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    func getSurahAndAyah(from searchText: String) -> (surah: Surah?, ayah: Ayah?) {
        let surahAyahPair = searchText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":").map(String.init)
        var surahNumber: Int? = nil
        var ayahNumber: Int? = nil

        if surahAyahPair.count == 2 {
            if let s = Int(surahAyahPair[0]), (1...114).contains(s) {
                surahNumber = s
                ayahNumber = Int(surahAyahPair[1])
            } else if let s = arabicToEnglishNumber(surahAyahPair[0]), (1...114).contains(s) {
                surahNumber = s
                ayahNumber = arabicToEnglishNumber(surahAyahPair[1])
            }
        }

        if let sNum = surahNumber,
           let aNum = ayahNumber,
           let surah = quranData.quran.first(where: { $0.id == sNum }),
           let ayah = surah.ayahs.first(where: { $0.id == aNum }) {
            return (surah, ayah)
        }
        return (nil, nil)
    }
        
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { scrollProxy in
                    List {
                        let favoriteSurahs = Set(settings.favoriteSurahs)
                        let bookmarkedAyahs = Set(settings.bookmarkedAyahs.map(\.id))
                        
                        #if !os(watchOS)
                        if searchText.isEmpty, let surah = settings.lastListenedSurah {
                            LastListenedSurahRow(
                                lastListenedSurah: surah,
                                favoriteSurahs: favoriteSurahs,
                                searchText: $searchText,
                                scrollToSurahID: $scrollToSurahID
                            )
                        }
                        #endif

                        if searchText.isEmpty, let lastReadSurah = lastReadSurah, let lastReadAyah = lastReadAyah {
                            LastReadAyahRow(
                                surah: lastReadSurah,
                                ayah: lastReadAyah,
                                favoriteSurahs: favoriteSurahs,
                                bookmarkedAyahs: bookmarkedAyahs,
                                searchText: $searchText,
                                scrollToSurahID: $scrollToSurahID
                            )
                        }
                        
                        if !settings.bookmarkedAyahs.isEmpty && searchText.isEmpty {
                            Section(header:
                                HStack {
                                    Text("BOOKMARKED AYAHS")
                                    Spacer()
                                    Image(systemName: settings.showBookmarks ? "chevron.down" : "chevron.up")
                                        .foregroundColor(settings.accentColor.color)
                                        .onTapGesture {
                                            settings.hapticFeedback()
                                            withAnimation { settings.showBookmarks.toggle() }
                                        }
                                }
                            ) {
                                if settings.showBookmarks {
                                    ForEach(settings.bookmarkedAyahs.sorted {
                                        $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                                    }, id: \.id) { bookmarkedAyah in
                                        BookmarkAyahRow(
                                            bookmarkedAyah: bookmarkedAyah,
                                            favoriteSurahs: favoriteSurahs,
                                            bookmarkedAyahs: bookmarkedAyahs,
                                            searchText: $searchText,
                                            scrollToSurahID: $scrollToSurahID
                                        )
                                    }
                                }
                            }
                        }
                        
                        if !settings.favoriteSurahs.isEmpty && searchText.isEmpty {
                            Section(header:
                                HStack {
                                    Text("FAVORITE SURAHS")
                                    Spacer()
                                    Image(systemName: settings.showFavorites ? "chevron.down" : "chevron.up")
                                        .foregroundColor(settings.accentColor.color)
                                        .onTapGesture {
                                            settings.hapticFeedback()
                                            withAnimation { settings.showFavorites.toggle() }
                                        }
                                }
                            ) {
                                if settings.showFavorites {
                                    ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahID in
                                        FavoriteSurahRow(
                                            favoriteSurah: surahID,
                                            favoriteSurahs: favoriteSurahs,
                                            searchText: $searchText,
                                            scrollToSurahID: $scrollToSurahID
                                        )
                                    }
                                }
                            }
                        }
                        
                        if settings.groupBySurah || (!searchText.isEmpty && settings.searchForSurahs) {
                            let searchResult = getSurahAndAyah(from: searchText)
                            let surah = searchResult.surah
                            let ayah = searchResult.ayah

                            if let surah = surah, let ayah = ayah {
                                AyahSearchResultRow(
                                    surah: surah,
                                    ayah: ayah,
                                    favoriteSurahs: favoriteSurahs,
                                    bookmarkedAyahs: bookmarkedAyahs,
                                    searchText: $searchText,
                                    scrollToSurahID: $scrollToSurahID
                                )
                            }
                            
                            Section(header: searchText.isEmpty ? AnyView(SurahsHeader()) : AnyView(Text("SURAH SEARCH RESULTS"))) {
                                let cleanedSearch = settings.cleanSearch(searchText.replacingOccurrences(of: ":", with: ""))
                                let surahAyahPair = searchText.split(separator: ":").map(String.init)
                                let upperQuery = searchText.uppercased()
                                let numericQuery: Int? = {
                                    if surahAyahPair.count == 2 {
                                        return Int(surahAyahPair[0]) ?? arabicToEnglishNumber(surahAyahPair[0])
                                    } else {
                                        return Int(cleanedSearch) ?? arabicToEnglishNumber(cleanedSearch)
                                    }
                                }()
                                
                                ForEach(quranData.quran.filter { surah in
                                    if let n = numericQuery, n == surah.id { return true }
                                    if searchText.isEmpty { return true }
                                    return upperQuery.contains(surah.nameEnglish.uppercased())            ||
                                           upperQuery.contains(surah.nameTransliteration.uppercased())    ||
                                           settings.cleanSearch(surah.nameArabic).contains(cleanedSearch)          ||
                                           settings.cleanSearch(surah.nameTransliteration).contains(cleanedSearch) ||
                                           settings.cleanSearch(surah.nameEnglish).contains(cleanedSearch)         ||
                                           settings.cleanSearch(String(surah.id)).contains(cleanedSearch)          ||
                                           settings.cleanSearch(arabicNumberString(from: surah.id)).contains(cleanedSearch)
                                }) { surah in
                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                        SurahRow(surah: surah, favoriteSurahs: favoriteSurahs)
                                    }
                                    .id("surah_\(surah.id)")
                                    .onAppear { if surah.id == scrollToSurahID { scrollToSurahID = -1 } }
                                    .swipeActions(edge: .trailing) {
                                        RightSwipeActions(
                                            surahID: surah.id,
                                            surahName: surah.nameTransliteration,
                                            searchText: $searchText,
                                            scrollToSurahID: $scrollToSurahID
                                        )
                                    }
                                    .swipeActions(edge: .leading) {
                                        LeftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
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
                                    .animation(.easeInOut, value: searchText)
                                }
                            }
                        } else {
                            ForEach(quranData.juzList, id: \.id) { juz in
                                Section(header: JuzHeader(juz: juz)) {
                                    let surahsInRange = quranData.quran.filter {
                                        $0.id >= juz.startSurah && $0.id <= juz.endSurah
                                    }
                                    ForEach(surahsInRange, id: \.id) { surah in
                                        let startAyah = (surah.id == juz.startSurah) ? juz.startAyah : 1
                                        let endAyah = (surah.id == juz.endSurah) ? juz.endAyah : surah.numberOfAyahs
                                        let singleSurah = (juz.startSurah == surah.id && juz.endSurah == surah.id)
                                        
                                        Group {
                                            if singleSurah {
                                                if startAyah > 1 {
                                                    NavigationLink(destination: AyahsView(surah: surah, ayah: startAyah)) {
                                                        SurahRow(surah: surah, ayah: startAyah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                } else {
                                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                                        SurahRow(surah: surah, ayah: startAyah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                }
                                                if endAyah < surah.numberOfAyahs {
                                                    NavigationLink(destination: AyahsView(surah: surah, ayah: endAyah)) {
                                                        SurahRow(surah: surah, ayah: endAyah, end: true, favoriteSurahs: favoriteSurahs)
                                                    }
                                                } else {
                                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                                        SurahRow(surah: surah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                }
                                            } else if surah.id == juz.startSurah {
                                                if startAyah > 1 {
                                                    NavigationLink(destination: AyahsView(surah: surah, ayah: startAyah)) {
                                                        SurahRow(surah: surah, ayah: startAyah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                } else {
                                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                                        SurahRow(surah: surah, ayah: startAyah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                }
                                            } else if surah.id == juz.endSurah {
                                                if surah.id == 114 {
                                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                                        SurahRow(surah: surah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                } else if endAyah < surah.numberOfAyahs {
                                                    NavigationLink(destination: AyahsView(surah: surah, ayah: endAyah)) {
                                                        SurahRow(surah: surah, ayah: endAyah, end: true, favoriteSurahs: favoriteSurahs)
                                                    }
                                                } else {
                                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                                        SurahRow(surah: surah, favoriteSurahs: favoriteSurahs)
                                                    }
                                                }
                                            } else {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah, favoriteSurahs: favoriteSurahs)
                                                }
                                            }
                                        }
                                        .id("surah_\(surah.id)")
                                        #if !os(watchOS)
                                        .swipeActions(edge: .trailing) {
                                            RightSwipeActions(
                                                surahID: surah.id,
                                                surahName: surah.nameTransliteration,
                                                searchText: $searchText,
                                                scrollToSurahID: $scrollToSurahID
                                            )
                                        }
                                        .swipeActions(edge: .leading) {
                                            LeftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
                                        }
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
                                    }
                                }
                            }
                        }
                        
                        #if !os(watchOS)
                        if !searchText.isEmpty {
                            Section(header: Text("AYAH SEARCH RESULTS (\(verseHits.count)\(hasMoreHits && verseHits.count >= hitPageSize ? "+" : ""))")) {
                                ForEach(verseHits) { hit in
                                    if let surah = quranData.surah(hit.surah),
                                       let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {

                                        NavigationLink {
                                            AyahsView(surah: surah, ayah: ayah.id)
                                        } label: {
                                            AyahSearchRow(
                                                surahName: surah.nameTransliteration,
                                                surah: hit.surah,
                                                ayah: hit.ayah,
                                                query: searchText,
                                                arabic: ayah.textArabic,
                                                english: ayah.textEnglish,
                                                translit: ayah.textTransliteration,
                                                favoriteSurahs: favoriteSurahs,
                                                bookmarkedAyahs: bookmarkedAyahs,
                                                searchText: $searchText,
                                                scrollToSurahID: $scrollToSurahID
                                            )
                                        }
                                    }
                                }

                                if verseHits.count >= hitPageSize && hasMoreHits {
                                    HStack {
                                        Spacer()
                                        
                                        Button {
                                            settings.hapticFeedback()
                                            hitOffset += hitPageSize
                                            let currentCount = verseHits.count
                                            let more = quranData.searchVerses(term: searchText, limit: hitPageSize, offset: hitOffset)
                                            withAnimation {
                                                verseHits.append(contentsOf: more)
                                                
                                                if verseHits.count == currentCount {
                                                    hasMoreHits = false
                                                }
                                            }
                                        } label: {
                                            Text("Load more ayahs…")
                                                .foregroundColor(settings.accentColor.color)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .onAppear {
                                withAnimation {
                                    showAyahSearch = true
                                }
                            }
                            .onDisappear {
                                withAnimation {
                                    showAyahSearch = false
                                }
                            }
                            .onChange(of: searchText) { txt in
                                if showAyahSearch {
                                    withAnimation {
                                        hitOffset = 0
                                        hasMoreHits = true
                                        verseHits = quranData.searchVerses(term: txt, limit: hitPageSize, offset: 0)
                                    }
                                }
                            }
                            .onChange(of: showAyahSearch) { newValue in
                                if newValue {
                                    withAnimation {
                                        hitOffset = 0
                                        hasMoreHits = true
                                        verseHits = quranData.searchVerses(term: searchText, limit: hitPageSize, offset: 0)
                                    }
                                }
                            }
                        }
                        #endif
                    }
                    .applyConditionalListStyle(defaultView: settings.defaultView)
                    .dismissKeyboardOnScroll()
                    #if os(watchOS)
                    .searchable(text: $searchText)
                    #endif
                    .onChange(of: scrollToSurahID) { id in
                        if id > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation { scrollProxy.scrollTo("surah_\(id)", anchor: .top) }
                            }
                        }
                    }
                }
                
                #if !os(watchOS)
                VStack {
                    if quranPlayer.isPlaying || quranPlayer.isPaused {
                        NowPlayingView(quranView: true, scrollDown: $scrollToSurahID, searchText: $searchText)
                            .padding(.horizontal, 8)
                            .transition(.opacity)
                            .animation(.easeInOut, value: quranPlayer.isPlaying)
                    }
                    
                    Picker("Sort Type", selection: $settings.groupBySurah.animation(.easeInOut)) {
                        Text("Sort by Surah").tag(true)
                        Text("Sort by Juz").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    HStack {
                        SearchBar(text: $searchText.animation(.easeInOut))
                            .padding(.horizontal, 8)
                        
                        if quranPlayer.isLoading || quranPlayer.isPlaying || quranPlayer.isPaused {
                            Button {
                                settings.hapticFeedback()
                                if quranPlayer.isLoading {
                                    quranPlayer.isLoading = false
                                    quranPlayer.pause(saveInfo: false)
                                } else {
                                    quranPlayer.stop()
                                }
                            } label: {
                                if quranPlayer.isLoading {
                                    RotatingGearView().transition(.opacity)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(settings.accentColor.color)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.trailing, 28)
                        } else {
                            Menu {
                                if let last = settings.lastListenedSurah,
                                   let surah = quranData.quran.first(where: { $0.id == last.surahNumber }) {
                                    Button {
                                        settings.hapticFeedback()
                                        quranPlayer.playSurah(
                                            surahNumber: last.surahNumber,
                                            surahName: last.surahName,
                                            certainReciter: true
                                        )
                                    } label: {
                                        Label("Play Last Listened Surah (\(surah.nameTransliteration))", systemImage: "play.fill")
                                    }
                                }
                                
                                Button {
                                    settings.hapticFeedback()
                                    if let randomSurah = quranData.quran.randomElement() {
                                        quranPlayer.playSurah(surahNumber: randomSurah.id, surahName: randomSurah.nameTransliteration)
                                    } else {
                                        let n = Int.random(in: 1...114)
                                        let name = quranData.quran.first(where: { $0.id == n })?.nameTransliteration ?? "Random Surah"
                                        quranPlayer.playSurah(surahNumber: n, surahName: name)
                                    }
                                } label: {
                                    Label("Play Random Surah", systemImage: "shuffle")
                                }
                            } label: {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(settings.accentColor.color)
                                    .transition(.opacity)
                            }
                            .padding(.trailing, 28)
                        }
                    }
                }
                .animation(.easeInOut, value: quranPlayer.isPlaying)
                #endif
            }
            .navigationTitle("Al-Quran")
            #if !os(watchOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        showingSettingsSheet = true
                    } label: { Image(systemName: "gear") }
                    .padding(.trailing, settings.defaultView ? 6 : 0)
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                NavigationView {
                    List {
                        SettingsQuranView(showEdits: false)
                    }
                    .applyConditionalListStyle(defaultView: true)
                    .navigationTitle("Al-Quran Settings")
                }
            }
            #endif
            
            if let lastSurah = lastReadSurah, let lastAyah = lastReadAyah {
                AyahsView(surah: lastSurah, ayah: lastAyah.id)
            } else if !settings.bookmarkedAyahs.isEmpty {
                let first = settings.bookmarkedAyahs.sorted {
                    $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                }.first
                let surah = quranData.quran.first(where: { $0.id == first?.surah })
                let ayah = surah?.ayahs.first(where: { $0.id == first?.ayah })
                if let s = surah, let a = ayah { AyahsView(surah: s, ayah: a.id) }
            } else if let firstFav = settings.favoriteSurahs.sorted().first,
                      let surah = quranData.quran.first(where: { $0.id == firstFav }) {
                AyahsView(surah: surah)
            } else {
                AyahsView(surah: quranData.quran[0])
            }
        }
        .confirmationDialog("Internet Connection Error",
            isPresented: $quranPlayer.showInternetAlert,
            titleVisibility: .visible) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Unable to load the recitation due to an internet connection issue. Please check your connection and try again.")
            }
    }
}
