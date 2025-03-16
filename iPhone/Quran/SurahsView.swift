import SwiftUI

struct SurahsHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    
    @State private var randomSurah: Surah?
        
    var body: some View {
        HStack {
            Text("SURAHS")
            
            #if !os(watchOS)
            Spacer()
            
            NavigationLink {
                Group {
                    if let randomS = randomSurah {
                        AyahsView(surah: randomS)
                    } else {
                        Text("No surah found!")
                    }
                }
                .onDisappear {
                    withAnimation {
                        randomSurah = quranData.quran.randomElement()
                    }
                }
            } label: {
                Image(systemName: "shuffle")
            }
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                withAnimation {
                    randomSurah = quranData.quran.randomElement()
                }
            }
        }
    }
}

struct JuzHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    let juz: Juz
    
    @State private var randomSurah: Surah?

    private func getRandomSurah() -> Surah? {
        let surahsInRange = quranData.quran.filter {
            $0.id >= juz.startSurah && $0.id <= juz.endSurah
        }
        return surahsInRange.randomElement()
    }
    
    var body: some View {
        HStack {
            Text("JUZ \(juz.id) - \(juz.nameTransliteration.uppercased())")
            
            #if !os(watchOS)
            Spacer()
            
            NavigationLink {
                Group {
                    if let randomS = randomSurah {
                        AyahsView(surah: randomS)
                    } else {
                        Text("No surah found in Juz \(juz.id).")
                    }
                }
                .onDisappear {
                    withAnimation {
                        if let randomS = getRandomSurah() {
                            randomSurah = randomS
                        }
                    }
                }
            } label: {
                Image(systemName: "shuffle")
            }
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                withAnimation {
                    if let randomS = getRandomSurah() {
                        randomSurah = randomS
                    }
                }
            }
        }
    }
}

struct SurahRow: View {
    @EnvironmentObject var settings: Settings
    
    var surah: Surah
    var ayah: Int?
    var end: Bool?

    var body: some View {
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

struct SurahsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    @EnvironmentObject var namesData: NamesViewModel
    
    @State private var searchText = ""
    @State private var scrollToSurahID: Int = -1
    #if !os(watchOS)
    @State private var copySettings = CopySettings()
    
    @State private var showingAyahSheet1 = false
    @State private var showingAyahSheet2 = false
    @State private var showingAyahSheet3 = false
    #endif
    
    @State private var showingArabicSheet = false
    @State private var showingAdhkarSheet = false
    @State private var showingDuaSheet = false
    @State private var showingTasbihSheet = false
    @State private var showingNamesSheet = false
    @State private var showingDateSheet = false
    @State private var showingSettingsSheet = false
    
    var lastReadSurah: Surah? {
        quranData.quran.first(where: { $0.id == settings.lastReadSurah })
    }

    var lastReadAyah: Ayah? {
        lastReadSurah?.ayahs.first(where: { $0.id == settings.lastReadAyah })
    }
    
    func cleanSearch(_ text: String) -> String {
        let unwantedChars: [Character] = ["[", "]", "(", ")", "-", "'", "\""]
        let cleaned = text.filter { !unwantedChars.contains($0) }
        return (cleaned.applyingTransform(.stripDiacritics, reverse: false) ?? cleaned).lowercased()
    }
    
    func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "ar")
        return numberFormatter.number(from: arabicNumber)?.intValue
    }

    func arabicNumberString(from number: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "ar")
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    func getSurahAndAyah(from searchText: String) -> (surah: Surah?, ayah: Ayah?) {
        let surahAyahPair = searchText.split(separator: ":").map(String.init)
        var surahNumber: Int? = nil
        var ayahNumber: Int? = nil

        if surahAyahPair.count == 2 {
            if let surahNum = Int(surahAyahPair[0]), surahNum >= 1, surahNum <= 114 {
                surahNumber = surahNum
                ayahNumber = Int(surahAyahPair[1])
            } else if let surahNum = arabicToEnglishNumber(surahAyahPair[0]), surahNum >= 1, surahNum <= 114 {
                surahNumber = surahNum
                ayahNumber = arabicToEnglishNumber(surahAyahPair[1])
            }
        }

        if let surahNumber = surahNumber, let ayahNumber = ayahNumber {
            if let surah = quranData.quran.first(where: { $0.id == surahNumber }),
               let ayah = surah.ayahs.first(where: { $0.id == ayahNumber }) {
                return (surah, ayah)
            }
        }
        return (nil, nil)
    }
    
    func formatTime(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
        
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { scrollProxy in
                    List {
                        #if !os(watchOS)
                        if searchText.isEmpty, let lastListenedSurah = settings.lastListenedSurah {
                            if let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber }) {
                                Section(header: Text("LAST LISTENED TO SURAH")) {
                                    VStack {
                                        NavigationLink(destination: AyahsView(surah: surah).transition(.opacity)
                                            .animation(.easeInOut, value: lastListenedSurah.surahName)) {
                                            HStack {
                                                Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
                                                    .font(.headline)
                                                    .foregroundColor(settings.accentColor.color)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.5)
                                            
                                                Spacer()
                                                
                                                if !quranPlayer.isPlaying && !quranPlayer.isPaused {
                                                    Menu {
                                                        Button(action: {
                                                            settings.hapticFeedback()
                                                            
                                                            quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: lastListenedSurah.surahName, certainReciter: true)
                                                        }) {
                                                            Label("Play from Last Listened", systemImage: "play.fill")
                                                        }
                                                        
                                                        Button(action: {
                                                            settings.hapticFeedback()
                                                            
                                                            quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: surah.nameTransliteration)
                                                        }) {
                                                            Label("Play from Beginning", systemImage: "memories")
                                                        }
                                                    } label: {
                                                        Image(systemName: "play.fill")
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 22, height: 22)
                                                            .foregroundColor(settings.accentColor.color)
                                                            .lineLimit(1)
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
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                            
                                            Spacer()
                                            
                                            Text("\(formatTime(lastListenedSurah.currentDuration)) / \(formatTime(lastListenedSurah.fullDuration))")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                                .padding(.leading, 4)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: lastListenedSurah.surahName, certainReciter: true)
                                    }) {
                                        Image(systemName: "play.fill")
                                    }
                                    .tint(settings.accentColor.color)
                                }
                                .swipeActions(edge: .leading) {
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        settings.toggleSurahFavorite(surah: surah)
                                    }) {
                                        Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                    }
                                    .tint(settings.accentColor.color)
                                }
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        settings.hapticFeedback()
                                        withAnimation {
                                            settings.lastListenedSurah = nil
                                        }
                                    }) {
                                        Label("Remove", systemImage: "trash")
                                    }
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: lastListenedSurah.surahName, certainReciter: true)
                                    }) {
                                        Label("Play from Last Listened", systemImage: "play.fill")
                                    }
                                    
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: surah.nameTransliteration)
                                    }) {
                                        Label("Play from Beginning", systemImage: "memories")
                                    }
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        settings.toggleSurahFavorite(surah: surah)
                                    }) {
                                        Label(settings.isSurahFavorite(surah: surah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                    }
                                    
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        withAnimation {
                                            searchText = ""
                                            settings.groupBySurah = true
                                            scrollToSurahID = surah.id
                                            self.endEditing()
                                        }
                                    }) {
                                        Text("Scroll To Surah")
                                        Image(systemName: "arrow.down.circle")
                                    }
                                }
                                .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
                            }
                        }
                        #endif

                        if searchText.isEmpty, let lastReadSurah = lastReadSurah, let lastReadAyah = lastReadAyah {
                            Section(header: Text("LAST READ AYAH")) {
                                NavigationLink(destination: AyahsView(surah: lastReadSurah, ayah: lastReadAyah.id)) {
                                    HStack {
                                        VStack {
                                            Text("\(lastReadSurah.id):\(lastReadAyah.id)")
                                                .font(.headline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                            
                                            Text(lastReadSurah.nameTransliteration)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .foregroundColor(settings.accentColor.color)
                                        .padding(.trailing, 8)
                                        
                                        VStack {
                                            if(settings.showArabicText) {
                                                Text(lastReadAyah.textArabic)
                                                    .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1))
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .lineLimit(1)
                                            }
                                            
                                            if(settings.showTransliteration) {
                                                Text(lastReadAyah.textTransliteration ?? "")
                                                    .font(.subheadline)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .lineLimit(1)
                                            }
                                            
                                            if(settings.showEnglishTranslation) {
                                                Text(lastReadAyah.textEnglish ?? "")
                                                    .font(.subheadline)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)
                                    #if !os(watchOS)
                                    .swipeActions(edge: .trailing) {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playSurah(surahNumber: lastReadSurah.id, surahName: lastReadSurah.nameTransliteration)
                                        }) {
                                            Image(systemName: "play.fill")
                                        }
                                        .tint(settings.accentColor.color)
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playAyah(surahNumber: lastReadSurah.id, ayahNumber: lastReadAyah.id)
                                        }) {
                                            Image(systemName: "play.circle")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleSurahFavorite(surah: lastReadSurah)
                                        }) {
                                            Image(systemName: settings.isSurahFavorite(surah: lastReadSurah) ? "star.fill" : "star")
                                        }
                                        .tint(settings.accentColor.color)
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleBookmark(surah: lastReadSurah.id, ayah: lastReadAyah.id)
                                        }) {
                                            Image(systemName: settings.isBookmarked(surah: lastReadSurah.id, ayah: lastReadAyah.id) ? "bookmark.fill" : "bookmark")
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive, action: {
                                            settings.hapticFeedback()
                                            
                                            withAnimation {
                                                settings.lastReadSurah = 0
                                                settings.lastReadAyah = 0
                                            }
                                        }) {
                                            Label("Remove", systemImage: "trash")
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleBookmark(surah: lastReadSurah.id, ayah: lastReadAyah.id)
                                        }) {
                                            Label(settings.isBookmarked(surah: lastReadSurah.id, ayah: lastReadAyah.id) ? "Unbookmark Ayah" : "Bookmark Ayah", systemImage: settings.isBookmarked(surah: lastReadSurah.id, ayah: lastReadAyah.id) ? "bookmark.fill" : "bookmark")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playAyah(surahNumber: lastReadSurah.id, ayahNumber: lastReadAyah.id)
                                        }) {
                                            Label("Play Ayah", systemImage: "play.circle")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playAyah(surahNumber: lastReadSurah.id, ayahNumber: lastReadAyah.id, continueRecitation: true)
                                        }) {
                                            Label("Play from Ayah", systemImage: "play.circle.fill")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            copySettings = CopySettings(arabic: settings.showArabicText, transliteration: settings.showTransliteration, translation: settings.showEnglishTranslation)
                                            showingAyahSheet1 = true
                                        }) {
                                            Label("Share Ayah", systemImage: "square.and.arrow.up")
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleSurahFavorite(surah: lastReadSurah)
                                        }) {
                                            Label(settings.isSurahFavorite(surah: lastReadSurah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: lastReadSurah) ? "star.fill" : "star")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playSurah(surahNumber: lastReadSurah.id, surahName: lastReadSurah.nameTransliteration)
                                        }) {
                                            Label("Play Surah", systemImage: "play.fill")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            withAnimation {
                                                searchText = ""
                                                settings.groupBySurah = true
                                                scrollToSurahID = lastReadSurah.id
                                                self.endEditing()
                                            }
                                        }) {
                                            Text("Scroll To Surah")
                                            Image(systemName: "arrow.down.circle")
                                        }
                                    }
                                    .sheet(isPresented: $showingAyahSheet1) {
                                        CopyAyahSheet(copySettings: $copySettings, surahNumber: lastReadSurah.id, ayahNumber: lastReadAyah.id)
                                    }
                                    #endif
                                }
                            }
                        }
                        
                        if !settings.bookmarkedAyahs.isEmpty && searchText.isEmpty {
                            Section(header:
                                HStack {
                                    Text("BOOKMARKED AYAHS")
                                
                                    Spacer()
                                
                                    Button(action: {
                                        withAnimation {
                                            settings.showBookmarks.toggle()
                                        }
                                    }) {
                                        Image(systemName: settings.showBookmarks ? "chevron.down" : "chevron.up")
                                    }
                                }
                            ) {
                                if settings.showBookmarks {
                                    ForEach(settings.bookmarkedAyahs.sorted {
                                        if $0.surah == $1.surah {
                                            return $0.ayah < $1.ayah
                                        } else {
                                            return $0.surah < $1.surah
                                        }
                                    }, id: \.id) { bookmarkedAyah in
                                        let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah })
                                        let ayah = surah?.ayahs.first(where: { $0.id == bookmarkedAyah.ayah })
                                        
                                        if let surah = surah, let ayah = ayah {
                                            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                                                HStack {
                                                    VStack {
                                                        Text("\(bookmarkedAyah.surah):\(bookmarkedAyah.ayah)")
                                                            .font(.headline)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.5)
                                                        
                                                        Text(surah.nameTransliteration)
                                                            .font(.caption)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.5)
                                                    }
                                                    .foregroundColor(settings.accentColor.color)
                                                    .padding(.trailing, 8)
                                                    
                                                    VStack {
                                                        if(settings.showArabicText) {
                                                            Text(ayah.textArabic)
                                                                .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1))
                                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                                                .lineLimit(1)
                                                        }
                                                        
                                                        if(settings.showTransliteration) {
                                                            Text(ayah.textTransliteration ?? "")
                                                                .font(.subheadline)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .lineLimit(1)
                                                        }
                                                        
                                                        if(settings.showEnglishTranslation) {
                                                            Text(ayah.textEnglish ?? "")
                                                                .font(.subheadline)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .lineLimit(1)
                                                        }
                                                    }
                                                }
                                                .padding(.vertical, 2)
                                            }
                                            #if !os(watchOS)
                                            .swipeActions(edge: .trailing) {
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                                }) {
                                                    Image(systemName: "play.fill")
                                                }
                                                .tint(settings.accentColor.color)
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                                                }) {
                                                    Image(systemName: "play.circle")
                                                }
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    settings.toggleSurahFavorite(surah: surah)
                                                }) {
                                                    Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                                }
                                                .tint(settings.accentColor.color)
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                                                }) {
                                                    Image(systemName: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "bookmark.fill" : "bookmark")
                                                }
                                            }
                                            .contextMenu {
                                                Button(role: .destructive, action: {
                                                    settings.hapticFeedback()
                                                    
                                                    settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                                                }) {
                                                    Label(settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "Unbookmark Ayah" : "Bookmark Ayah", systemImage: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "bookmark.fill" : "bookmark")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                                                }) {
                                                    Label("Play Ayah", systemImage: "play.circle")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                                                }) {
                                                    Label("Play from Ayah", systemImage: "play.circle.fill")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    copySettings = CopySettings(arabic: settings.showArabicText, transliteration: settings.showTransliteration, translation: settings.showEnglishTranslation)
                                                    showingAyahSheet2 = true
                                                }) {
                                                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                                                }
                                                
                                                Divider()
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    settings.toggleSurahFavorite(surah: surah)
                                                }) {
                                                    Label(settings.isSurahFavorite(surah: surah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                                }) {
                                                    Label("Play Surah", systemImage: "play.fill")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    withAnimation {
                                                        searchText = ""
                                                        settings.groupBySurah = true
                                                        scrollToSurahID = surah.id
                                                        self.endEditing()
                                                    }
                                                }) {
                                                    Text("Scroll To Surah")
                                                    Image(systemName: "arrow.down.circle")
                                                }
                                            }
                                            .sheet(isPresented: $showingAyahSheet2) {
                                                CopyAyahSheet(copySettings: $copySettings, surahNumber: surah.id, ayahNumber: ayah.id)
                                            }
                                            #endif
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
                                
                                    Button(action: {
                                        withAnimation {
                                            settings.showFavorites.toggle()
                                        }
                                    }) {
                                        Image(systemName: settings.showFavorites ? "chevron.down" : "chevron.up")
                                    }
                                }
                            ) {
                                if settings.showFavorites {
                                    ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahId in
                                        if let surah = quranData.quran.first(where: { $0.id == surahId }) {
                                            NavigationLink(destination: AyahsView(surah: surah)) {
                                                SurahRow(surah: surah)
                                            }
                                            #if !os(watchOS)
                                            .swipeActions(edge: .trailing) {
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                                }) {
                                                    Image(systemName: "play.fill")
                                                }
                                                .tint(settings.accentColor.color)
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    settings.toggleSurahFavorite(surah: surah)
                                                }) {
                                                    Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                                }
                                                .tint(settings.accentColor.color)
                                            }
                                            .contextMenu {
                                                Button(role: .destructive, action: {
                                                    settings.hapticFeedback()
                                                    
                                                    settings.toggleSurahFavorite(surah: surah)
                                                }) {
                                                    Label(settings.isSurahFavorite(surah: surah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                                }) {
                                                    Label("Play Surah", systemImage: "play.fill")
                                                }
                                                
                                                Button(action: {
                                                    settings.hapticFeedback()
                                                    
                                                    withAnimation {
                                                        searchText = ""
                                                        settings.groupBySurah = true
                                                        scrollToSurahID = surah.id
                                                        self.endEditing()
                                                    }
                                                }) {
                                                    Text("Scroll To Surah")
                                                    Image(systemName: "arrow.down.circle")
                                                }
                                            }
                                            #endif
                                        }
                                    }
                                }
                            }
                        }
                        
                        if settings.groupBySurah || (!searchText.isEmpty && settings.searchForSurahs) {
                            let searchResult = getSurahAndAyah(from: searchText)
                            let surah = searchResult.surah
                            let ayah = searchResult.ayah

                            if let surah = surah, let ayah = ayah {
                                Section(header: Text("AYAH SEARCH RESULT")) {
                                    NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                                        HStack {
                                            VStack {
                                                Text("\(surah.id):\(ayah.id)")
                                                    .font(.headline)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.5)
                                                
                                                Text(surah.nameTransliteration)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.5)
                                            }
                                            .foregroundColor(settings.accentColor.color)
                                            .padding(.trailing, 8)
                                            
                                            VStack {
                                                if settings.showArabicText {
                                                    Text(ayah.textArabic)
                                                        .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1))
                                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                                        .lineLimit(1)
                                                }
                                                
                                                if settings.showTransliteration {
                                                    Text(ayah.textTransliteration ?? "")
                                                        .font(.subheadline)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .lineLimit(1)
                                                }
                                                
                                                if settings.showEnglishTranslation {
                                                    Text(ayah.textEnglish ?? "")
                                                        .font(.subheadline)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    #if !os(watchOS)
                                    .swipeActions(edge: .trailing) {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                        }) {
                                            Image(systemName: "play.fill")
                                        }
                                        .tint(settings.accentColor.color)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleSurahFavorite(surah: surah)
                                        }) {
                                            Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                        }
                                        .tint(settings.accentColor.color)
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                                        }) {
                                            Label(settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "Unbookmark Ayah" : "Bookmark Ayah", systemImage: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "bookmark.fill" : "bookmark")
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                                        }) {
                                            Label("Play Ayah", systemImage: "play.circle")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                                        }) {
                                            Label("Play from Ayah", systemImage: "play.circle.fill")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            copySettings = CopySettings(arabic: settings.showArabicText, transliteration: settings.showTransliteration, translation: settings.showEnglishTranslation)
                                            showingAyahSheet3 = true
                                        }) {
                                            Label("Share Ayah", systemImage: "square.and.arrow.up")
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleSurahFavorite(surah: surah)
                                        }) {
                                            Label(settings.isSurahFavorite(surah: surah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                        }) {
                                            Label("Play Surah", systemImage: "play.fill")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            withAnimation {
                                                searchText = ""
                                                settings.groupBySurah = true
                                                scrollToSurahID = surah.id
                                                self.endEditing()
                                            }
                                        }) {
                                            Text("Scroll To Surah")
                                            Image(systemName: "arrow.down.circle")
                                        }
                                    }
                                    .sheet(isPresented: $showingAyahSheet3) {
                                        CopyAyahSheet(copySettings: $copySettings, surahNumber: surah.id, ayahNumber: ayah.id)
                                    }
                                    #endif
                                }
                            }

                            Section(header: searchText.isEmpty ? AnyView(SurahsHeader()) : AnyView(Text("SURAH SEARCH RESULTS"))) {
                                ForEach(quranData.quran.filter { surah in
                                    let cleanSearchText = cleanSearch(searchText.replacingOccurrences(of: ":", with: ""))
                                    let surahAyahPair = searchText.split(separator: ":").map(String.init)

                                    if surahAyahPair.count == 2 {
                                        let surahPart = surahAyahPair[0]
                                        
                                        if let surahNum = Int(surahPart) ?? arabicToEnglishNumber(surahPart), surahNum == surah.id {
                                            return true
                                        }
                                    } else if let surahNum = Int(cleanSearchText) ?? arabicToEnglishNumber(cleanSearchText), surahNum == surah.id {
                                        return true
                                    }

                                    return searchText.isEmpty ||
                                        searchText.uppercased().contains(surah.nameEnglish.uppercased()) ||
                                        searchText.uppercased().contains(surah.nameTransliteration.uppercased()) ||
                                        cleanSearch(surah.nameArabic).contains(cleanSearchText) ||
                                        cleanSearch(surah.nameTransliteration).contains(cleanSearchText) ||
                                        cleanSearch(surah.nameEnglish).contains(cleanSearchText) ||
                                        cleanSearch(String(surah.id)).contains(cleanSearchText) ||
                                        cleanSearch(arabicNumberString(from: surah.id)).contains(cleanSearchText) ||
                                        Int(cleanSearchText) == surah.id
                                }) { surah in
                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                        SurahRow(surah: surah)
                                    }
                                    .id("surah_\(surah.id)")
                                    .onAppear {
                                        if surah.id == scrollToSurahID {
                                            scrollToSurahID = -1
                                        }
                                    }
                                    .animation(.easeInOut, value: searchText)
                                    #if !os(watchOS)
                                    .swipeActions(edge: .trailing) {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                        }) {
                                            Image(systemName: "play.fill")
                                        }
                                        .tint(settings.accentColor.color)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleSurahFavorite(surah: surah)
                                        }) {
                                            Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                        }
                                        .tint(settings.accentColor.color)
                                    }
                                    .contextMenu {
                                        Button(role: settings.isSurahFavorite(surah: surah) ? .destructive : nil, action: {
                                            settings.hapticFeedback()
                                            
                                            settings.toggleSurahFavorite(surah: surah)
                                        }) {
                                            Label(settings.isSurahFavorite(surah: surah) ? "Unfavorite Surah" : "Favorite Surah", systemImage: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                        }
                                        
                                        Button(action: {
                                            settings.hapticFeedback()
                                            
                                            quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                        }) {
                                            Label("Play Surah", systemImage: "play.fill")
                                        }
                                        
                                        if !searchText.isEmpty {
                                            Button(action: {
                                                settings.hapticFeedback()
                                                
                                                withAnimation {
                                                    searchText = ""
                                                    settings.groupBySurah = true
                                                    scrollToSurahID = surah.id
                                                    self.endEditing()
                                                }
                                            }) {
                                                Text("Scroll To Surah")
                                                Image(systemName: "arrow.down.circle")
                                            }
                                        }
                                    }
                                    #endif
                                }
                                .animation(.easeInOut, value: searchText)
                            }
                        } else {
                           ForEach(quranData.juzList, id: \.id) { juz in
                               Section(header: JuzHeader(juz: juz)) {
                                   let surahsInRange = quranData.quran.filter {
                                       $0.id >= juz.startSurah && $0.id <= juz.endSurah
                                   }
                                   
                                   ForEach(surahsInRange, id: \.id) { surah in
                                       let startAyah = (surah.id == juz.startSurah) ? juz.startAyah : 1
                                       let endAyah   = (surah.id == juz.endSurah)   ? juz.endAyah   : surah.numberOfAyahs
                                       
                                       let isSingleSurahJuz = (juz.startSurah == surah.id && juz.endSurah == surah.id)
                                       
                                       Group {
                                           if isSingleSurahJuz {
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
                                       #if !os(watchOS)
                                       .swipeActions(edge: .trailing) {
                                           Button(action: {
                                               settings.hapticFeedback()
                                               quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                           }) {
                                               Image(systemName: "play.fill")
                                           }
                                           .tint(settings.accentColor.color)
                                       }
                                       .swipeActions(edge: .leading) {
                                           Button(action: {
                                               settings.hapticFeedback()
                                               settings.toggleSurahFavorite(surah: surah)
                                           }) {
                                               Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                                           }
                                           .tint(settings.accentColor.color)
                                       }
                                       .contextMenu {
                                           Button(action: {
                                               settings.hapticFeedback()
                                               settings.toggleSurahFavorite(surah: surah)
                                           }) {
                                               Label(
                                                   settings.isSurahFavorite(surah: surah) ? "Unfavorite Surah" : "Favorite Surah",
                                                   systemImage: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star"
                                               )
                                           }
                                           
                                           Button(action: {
                                               settings.hapticFeedback()
                                               quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration
                                               )
                                           }) {
                                               Label("Play Surah", systemImage: "play.fill")
                                           }
                                           
                                           if !searchText.isEmpty {
                                               Button(action: {
                                                   settings.hapticFeedback()
                                                   withAnimation {
                                                       searchText = ""
                                                       settings.groupBySurah = true
                                                       scrollToSurahID = surah.id
                                                       self.endEditing()
                                                   }
                                               }) {
                                                   Text("Scroll To Surah")
                                                   Image(systemName: "arrow.down.circle")
                                               }
                                           }
                                       }
                                       #endif
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
                                withAnimation {
                                    scrollProxy.scrollTo("surah_\(id)", anchor: .top)
                                }
                            }
                        }
                    }
                }
                
                #if !os(watchOS)
                VStack {
                    if quranPlayer.isPlaying || quranPlayer.isPaused {
                        NowPlayingView(surahsView: true, scrollDown: $scrollToSurahID, searchText: $searchText)
                            .environmentObject(quranPlayer)
                            .environmentObject(settings)
                            .padding(.horizontal, 8)
                            .transition(.opacity)
                            .animation(.easeInOut, value: quranPlayer.isPlaying)
                    }
                    
                    if searchText.isEmpty {
                        Picker("Sort Type", selection: $settings.groupBySurah.animation(.easeInOut)) {
                            Text("Sort by Surah").tag(true)
                            Text("Sort by Juz").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        SearchBar(text: $searchText.animation(.easeInOut))
                            .padding(.horizontal, 8)
                        
                        if quranPlayer.isLoading || quranPlayer.isPlaying || quranPlayer.isPaused {
                            Button(action: {
                                settings.hapticFeedback()
                                
                                if quranPlayer.isLoading {
                                    quranPlayer.isLoading = false
                                    quranPlayer.pause(saveInfo: false)
                                } else {
                                    quranPlayer.stop()
                                }
                            }) {
                                if quranPlayer.isLoading {
                                    RotatingGearView()
                                        .transition(.opacity)
                                } else if quranPlayer.isPlaying || quranPlayer.isPaused {
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
                                if let lastListenedSurah = settings.lastListenedSurah,
                                   let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber }) {
                                    
                                    Button(action: {
                                        settings.hapticFeedback()
                                        quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: lastListenedSurah.surahName, certainReciter: true)
                                    }) {
                                        Label("Play Last Listened Surah (\(surah.nameTransliteration))", systemImage: "play.fill")
                                    }
                                }
                                
                                Button(action: {
                                    settings.hapticFeedback()
                                    
                                    if let randomSurah = quranData.quran.randomElement() {
                                        quranPlayer.playSurah(surahNumber: randomSurah.id, surahName: randomSurah.nameTransliteration)
                                    } else {
                                        let randomSurahNumber = Int.random(in: 1...114)
                                        
                                        if let randomSurah = quranData.quran.first(where: { $0.id == randomSurahNumber }) {
                                            quranPlayer.playSurah(surahNumber: randomSurah.id, surahName: randomSurah.nameTransliteration)
                                        } else {
                                            quranPlayer.playSurah(surahNumber: randomSurahNumber, surahName: "Random Surah")
                                        }
                                    }
                                }) {
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
            #if os(watchOS)
            .navigationTitle("Al-Quran")
            #else
            .navigationTitle("Al-Quran | Beginner Quran")
            .toolbar {
                /*ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            showingArabicSheet = true
                        }) {
                            Image(systemName: "textformat.size.ar")
                            Text("Arabic Alphabet")
                        }
                        
                        Button(action: {
                            showingAdhkarSheet = true
                        }) {
                            Image(systemName: "book.closed")
                            Text("Common Adhkar")
                        }
                        
                        Button(action: {
                            showingDuaSheet = true
                        }) {
                            Image(systemName: "text.book.closed")
                            Text("Common Duas")
                        }
                        
                        Button(action: {
                            showingTasbihSheet = true
                        }) {
                            Image(systemName: "circles.hexagonpath.fill")
                            Text("Tasbih Counter")
                        }
                        
                        Button(action: {
                            showingNamesSheet = true
                        }) {
                            Image(systemName: "signature")
                            Text("99 Names of Allah")
                        }
                        
                        Button(action: {
                            showingDateSheet = true
                        }) {
                            Image(systemName: "calendar")
                            Text("Hijri Calendar Converter")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .padding(.leading, settings.defaultView ? 6 : 0)
                }*/

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .padding(.trailing, settings.defaultView ? 6 : 0)
                }
            }
            .sheet(isPresented: $showingArabicSheet) {
                NavigationView {
                    ArabicView()
                }
            }
            .sheet(isPresented: $showingAdhkarSheet) {
                NavigationView {
                    AdhkarView()
                }
            }
            .sheet(isPresented: $showingDuaSheet) {
                NavigationView {
                    DuaView()
                }
            }
            .sheet(isPresented: $showingTasbihSheet) {
                NavigationView {
                    TasbihView()
                }
            }
            .sheet(isPresented: $showingNamesSheet) {
                NavigationView {
                    NamesView().environmentObject(namesData)
                }
            }
            .sheet(isPresented: $showingDateSheet) {
                NavigationView {
                    DateView()
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
                
                /*SettingsView()
                    .environmentObject(quranData)
                    .accentColor(settings.accentColor.color)
                    .preferredColorScheme(settings.colorScheme)*/
            }
            #endif
            
            if let lastReadSurah = lastReadSurah, let lastReadAyah = lastReadAyah {
                AyahsView(surah: lastReadSurah, ayah: lastReadAyah.id)
            } else if !settings.bookmarkedAyahs.isEmpty {
                let sortedBookmarks = settings.bookmarkedAyahs.sorted {
                    if $0.surah == $1.surah {
                        return $0.ayah < $1.ayah
                    } else {
                        return $0.surah < $1.surah
                    }
                }

                let firstBookmark = sortedBookmarks.first
                let surah = quranData.quran.first(where: { $0.id == firstBookmark?.surah })
                let ayah = surah?.ayahs.first(where: { $0.id == firstBookmark?.ayah })

                if let surah = surah, let ayah = ayah {
                    AyahsView(surah: surah, ayah: ayah.id)
                }
            } else if !settings.favoriteSurahs.isEmpty {
                let sortedFavorites = settings.favoriteSurahs.sorted()
                let firstFavorite = quranData.quran.first(where: { $0.id == sortedFavorites.first })
                
                if let surah = firstFavorite {
                    AyahsView(surah: surah)
                }
            } else {
                AyahsView(surah: quranData.quran[0])
            }
        }
        .confirmationDialog("Internet Connection Error", isPresented: $quranPlayer.showInternetAlert, titleVisibility: .visible) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to load the recitation due to an internet connection issue. Please check your connection and try again.")
        }
    }
}
