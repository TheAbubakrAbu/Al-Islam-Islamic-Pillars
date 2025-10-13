import SwiftUI

struct QuranView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var searchText = ""
    @State private var scrollToSurahID: Int = -1
    @State private var showingSettingsSheet = false
    
    @State private var verseHits: [VerseIndexEntry] = []
    @State private var hasMoreHits = true
    @State private var showAyahSearch = false
    @State private var blockAyahSearchAfterZero = false
    @State private var zeroResultQueryLength = 0
    private let hitPageSize = 5
        
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
    
    enum QuranRoute: Hashable {
        case ayahs(surahID: Int, ayah: Int?)
    }
    
    @State private var path: [QuranRoute] = []

    var useStackOnThisDevice: Bool {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .phone
        }
        #endif
        return false
    }

    func push(surahID: Int, ayahID: Int? = nil) {
        #if os(iOS)
        if #available(iOS 16.0, *), useStackOnThisDevice {
            path.append(QuranRoute.ayahs(surahID: surahID, ayah: ayahID))
        }
        #endif
    }
    
    private func fetchHits(query: String, limit: Int, offset: Int) -> ([VerseIndexEntry], Bool) {
        let page = quranData.searchVerses(term: query, limit: limit + 1, offset: offset)
        let more = page.count > limit
        return (Array(page.prefix(limit)), more)
    }
     
    var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if useStackOnThisDevice {
                    NavigationStack(path: $path) {
                        content
                            .navigationDestination(for: QuranRoute.self) { route in
                                switch route {
                                case let .ayahs(surahID, ayah):
                                    if let s = quranData.quran.first(where: { $0.id == surahID }) {
                                        AyahsView(surah: s, ayah: ayah)
                                    } else {
                                        AyahsView(surah: quranData.quran[0])
                                    }
                                }
                            }
                    }
                } else {
                    NavigationView {
                        content
                        detailFallback
                    }
                    .navigationViewStyle(.columns)
                }
            } else {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NavigationView {
                        content
                        detailFallback
                    }
                    .navigationViewStyle(.columns)
                } else {
                    NavigationView { content }
                }
            }
            #else
            NavigationView { content }
            #endif
        }
        .confirmationDialog(
            "Internet Connection Error",
            isPresented: $quranPlayer.showInternetAlert,
            titleVisibility: .visible
        ) { Button("OK", role: .cancel) { } } message: {
            Text("Unable to load the recitation due to an internet connection issue. Please check your connection and try again.")
        }
    }
    
    var content: some View {
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
                    #else
                    NowPlayingView(quranView: true)
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
                                    if let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah }),
                                       let ayah = surah.ayahs.first(where: { $0.id == bookmarkedAyah.ayah }) {
                                        
                                        let noteText = bookmarkedAyah.note?.trimmingCharacters(in: .whitespacesAndNewlines)
                                        let noteToShow = (noteText?.isEmpty == false) ? noteText : nil
                                        
                                        Group {
                                            #if !os(watchOS)
                                            Button {
                                                push(surahID: bookmarkedAyah.surah, ayahID: bookmarkedAyah.ayah)
                                            } label: {
                                                NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                                                    SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                                                }
                                            }
                                            #else
                                            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                                                SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                                            }
                                            #endif
                                        }
                                        .rightSwipeActions(
                                            surahID: surah.id,
                                            surahName: surah.nameTransliteration,
                                            ayahID: ayah.id,
                                            searchText: $searchText,
                                            scrollToSurahID: $scrollToSurahID
                                        )
                                        .leftSwipeActions(
                                            surah: surah.id,
                                            favoriteSurahs: favoriteSurahs,
                                            bookmarkedAyahs: bookmarkedAyahs,
                                            bookmarkedSurah: bookmarkedAyah.surah,
                                            bookmarkedAyah: bookmarkedAyah.ayah
                                        )
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
                                    if let surah = quranData.quran.first(where: { $0.id == surahID }) {
                                        Group {
                                            #if !os(watchOS)
                                            Button {
                                                push(surahID: surahID)
                                            } label: {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah)
                                                }
                                            }
                                            #else
                                            NavigationLink(destination: AyahsView(surah: surah)) {
                                                SurahRow(surah: surah)
                                            }
                                            #endif
                                        }
                                        .rightSwipeActions(
                                            surahID: surahID,
                                            surahName: surah.nameTransliteration,
                                            searchText: $searchText,
                                            scrollToSurahID: $scrollToSurahID
                                        )
                                        .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
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
                                    }
                                }
                            }
                        }
                    }
                    
                    if settings.groupBySurah || (!searchText.isEmpty && settings.searchForSurahs) {
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

                        let filteredSurahs: [Surah] = quranData.quran.filter { surah in
                            if let n = numericQuery, n == surah.id { return true }
                            if searchText.isEmpty { return true }
                            return upperQuery.contains(surah.nameEnglish.uppercased())                     ||
                                   upperQuery.contains(surah.nameTransliteration.uppercased())             ||
                                   settings.cleanSearch(surah.nameArabic).contains(cleanedSearch)          ||
                                   settings.cleanSearch(surah.nameTransliteration).contains(cleanedSearch) ||
                                   settings.cleanSearch(surah.nameEnglish).contains(cleanedSearch)         ||
                                   settings.cleanSearch(String(surah.id)).contains(cleanedSearch)          ||
                                   settings.cleanSearch(arabicNumberString(from: surah.id)).contains(cleanedSearch)
                        }

                        Section(header:
                            Group {
                                if searchText.isEmpty {
                                    SurahsHeader()
                                } else {
                                    Text("SURAH SEARCH RESULTS (\(filteredSurahs.count))")
                                }
                            }
                        ) {
                            ForEach(filteredSurahs, id: \.id) { surah in
                                NavigationLink(destination: AyahsView(surah: surah)) {
                                    SurahRow(surah: surah)
                                }
                                .id("surah_\(surah.id)")
                                .onAppear { if surah.id == scrollToSurahID { scrollToSurahID = -1 } }
                                .rightSwipeActions(
                                    surahID: surah.id,
                                    surahName: surah.nameTransliteration,
                                    searchText: $searchText,
                                    scrollToSurahID: $scrollToSurahID
                                )
                                .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
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
                                                    SurahRow(surah: surah, ayah: startAyah)
                                                }
                                            } else {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah, ayah: startAyah)
                                                }
                                            }
                                            if endAyah < surah.numberOfAyahs {
                                                NavigationLink(destination: AyahsView(surah: surah, ayah: endAyah)) {
                                                    SurahRow(surah: surah, ayah: endAyah, end: true)
                                                }
                                            } else {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah)
                                                }
                                            }
                                        } else if surah.id == juz.startSurah {
                                            if startAyah > 1 {
                                                NavigationLink(destination: AyahsView(surah: surah, ayah: startAyah)) {
                                                    SurahRow(surah: surah, ayah: startAyah)
                                                }
                                            } else {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah, ayah: startAyah)
                                                }
                                            }
                                        } else if surah.id == juz.endSurah {
                                            if surah.id == 114 {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah)
                                                }
                                            } else if endAyah < surah.numberOfAyahs {
                                                NavigationLink(destination: AyahsView(surah: surah, ayah: endAyah)) {
                                                    SurahRow(surah: surah, ayah: endAyah, end: true)
                                                }
                                            } else {
                                                NavigationLink(destination: AyahsView(surah: surah)) {
                                                    SurahRow(surah: surah)
                                                }
                                            }
                                        } else {
                                            NavigationLink(destination: AyahsView(surah: surah)) {
                                                SurahRow(surah: surah)
                                            }
                                        }
                                    }
                                    .id("surah_\(surah.id)")
                                    #if !os(watchOS)
                                    .rightSwipeActions(
                                        surahID: surah.id,
                                        surahName: surah.nameTransliteration,
                                        searchText: $searchText,
                                        scrollToSurahID: $scrollToSurahID
                                    )
                                    .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
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
                    
                    if !searchText.isEmpty {
                        let searchResult = getSurahAndAyah(from: searchText)
                        let surah = searchResult.surah
                        let ayah = searchResult.ayah
                        
                        let exactMatchBump = (surah != nil && ayah != nil) ? 1 : 0
                        let canShowNext = hasMoreHits && !verseHits.isEmpty
                        let header = "AYAH SEARCH RESULTS (\(verseHits.count + exactMatchBump)\(canShowNext ? "+" : ""))"
                        
                        Section(header: Text(header)) {
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
                            
                            ForEach(verseHits) { hit in
                                if let surah = quranData.surah(hit.surah), let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
                                    NavigationLink {
                                        AyahsView(surah: surah, ayah: ayah.id)
                                    } label: {
                                        AyahSearchRow(
                                            surahName: surah.nameTransliteration,
                                            surah: hit.surah,
                                            ayah: hit.ayah,
                                            query: searchText,
                                            arabic: ayah.textArabic,
                                            transliteration: ayah.textTransliteration,
                                            englishSaheeh: ayah.textEnglishSaheeh,
                                            englishMustafa: ayah.textEnglishMustafa,
                                            favoriteSurahs: favoriteSurahs,
                                            bookmarkedAyahs: bookmarkedAyahs,
                                            searchText: $searchText,
                                            scrollToSurahID: $scrollToSurahID
                                        )
                                    }
                                }
                            }

                            if canShowNext {
                                #if !os(watchOS)
                                Menu("Load more ayah matches") {
                                    ForEach([5, 10, 20], id: \.self) { amount in
                                        Button("Load \(amount)") {
                                            settings.hapticFeedback()
                                            let (moreHits, moreAvail) = fetchHits(
                                                query: searchText,
                                                limit: amount,
                                                offset: verseHits.count
                                            )
                                            withAnimation {
                                                verseHits.append(contentsOf: moreHits)
                                                hasMoreHits = moreAvail
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                #else
                                if hasMoreHits && !verseHits.isEmpty {
                                    Button("Load \(hitPageSize) ayah matches") {
                                        let (moreHits, moreAvail) = fetchHits(query: searchText, limit: hitPageSize, offset: verseHits.count)
                                        withAnimation {
                                            verseHits.append(contentsOf: moreHits)
                                            hasMoreHits = moreAvail
                                        }
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .multilineTextAlignment(.center)
                                }
                                #endif

                                Button {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        verseHits = quranData.searchVersesAll(term: searchText)
                                        hasMoreHits = false
                                    }
                                } label: {
                                    Text("Load all ayah matches")
                                        .foregroundColor(settings.accentColor.color)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                            }
                        }
                        .onAppear {
                            showAyahSearch = true
                            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard verseHits.isEmpty, !q.isEmpty else { return }

                            if blockAyahSearchAfterZero && q.count > zeroResultQueryLength { return }

                            let (first, more) = fetchHits(query: q, limit: hitPageSize, offset: 0)
                            withAnimation {
                                verseHits = first
                                hasMoreHits = more
                                if first.isEmpty {
                                    blockAyahSearchAfterZero = true
                                    zeroResultQueryLength = q.count
                                } else {
                                    blockAyahSearchAfterZero = false
                                }
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                showAyahSearch = false
                                blockAyahSearchAfterZero = false
                            }
                        }
                        .onChange(of: searchText) { txt in
                            guard showAyahSearch else {
                                withAnimation {
                                    verseHits = []
                                    hasMoreHits = false
                                    blockAyahSearchAfterZero = false
                                }
                                return
                            }

                            let q = txt.trimmingCharacters(in: .whitespacesAndNewlines)

                            guard !q.isEmpty else {
                                withAnimation {
                                    verseHits = []
                                    hasMoreHits = false
                                    blockAyahSearchAfterZero = false
                                }
                                return
                            }

                            if blockAyahSearchAfterZero {
                                if q.count < zeroResultQueryLength {
                                    blockAyahSearchAfterZero = false
                                } else if q.count > zeroResultQueryLength {
                                    return
                                }
                            }

                            let (first, more) = fetchHits(query: q, limit: hitPageSize, offset: 0)
                            withAnimation {
                                verseHits = first
                                hasMoreHits = more
                                if first.isEmpty {
                                    blockAyahSearchAfterZero = true
                                    zeroResultQueryLength = q.count
                                } else {
                                    blockAyahSearchAfterZero = false
                                }
                            }
                        }
                    }
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
                            if let last = settings.lastListenedSurah, let surah = quranData.quran.first(where: { $0.id == last.surahNumber }) {
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
                            
                            Button {
                                settings.hapticFeedback()
                                
                                if let randomSurah = quranData.quran.randomElement() {
                                    if let randomAyah = randomSurah.ayahs.randomElement() {
                                        quranPlayer.playAyah(
                                            surahNumber: randomSurah.id,
                                            ayahNumber: randomAyah.id,
                                            continueRecitation: true
                                        )
                                    }
                                }
                            } label: {
                                Label("Play Random Ayah", systemImage: "shuffle.circle.fill")
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
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView { SettingsQuranView(showEdits: false) }
        }
        #endif
    }
    
    @ViewBuilder
    var detailFallback: some View {
        if let lastSurah = lastReadSurah, let lastAyah = lastReadAyah {
            AyahsView(surah: lastSurah, ayah: lastAyah.id)
        } else if !settings.bookmarkedAyahs.isEmpty {
            let first = settings.bookmarkedAyahs.sorted {
                $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
            }.first
            let surah = quranData.quran.first(where: { $0.id == first?.surah })
            let ayah = surah?.ayahs.first(where: { $0.id == first?.ayah })
            if let s = surah, let a = ayah { AyahsView(surah: s, ayah: a.id) }
        } else if let firstFav = settings.favoriteSurahs.sorted().first, let surah = quranData.quran.first(where: { $0.id == firstFav }) {
            AyahsView(surah: surah)
        } else {
            AyahsView(surah: quranData.quran[0])
        }
    }
}
