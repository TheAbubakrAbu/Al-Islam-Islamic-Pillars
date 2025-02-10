import SwiftUI

struct SurahSectionHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    var surah: Surah
    
    var body: some View {
        HStack {
            #if os(watchOS)
            Text("\(surah.numberOfAyahs) Ayahs - \(surah.type == "meccan" ? "🕋" : "🕌")")
                .textCase(.uppercase)
                .font(.subheadline)
            #else
            Text("\(surah.numberOfAyahs) Ayahs - \(surah.type) \(surah.type == "meccan" ? "🕋" : "🕌")")
                .textCase(.uppercase)
                .font(.subheadline)
            #endif
            
            Spacer()
            
            #if os(watchOS)
            Group {
                if quranPlayer.isLoading {
                    RotatingGearWatchView()
                        .transition(.opacity)
                } else if quranPlayer.isPlaying {
                    Image(systemName: "pause.fill")
                        .foregroundColor(settings.accentColor.color)
                        .font(.subheadline)
                        .transition(.opacity)
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(settings.accentColor.color)
                        .font(.subheadline)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut)
            .onTapGesture {
                settings.hapticFeedback()
                
                if quranPlayer.isLoading {
                    quranPlayer.isLoading = false
                    quranPlayer.player?.pause()
                } else {
                    if quranPlayer.isPlaying {
                        quranPlayer.pause(saveInfo: false)
                    } else {
                        quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                    }
                }
            }
            #endif
            
            Image(systemName: settings.isSurahFavorite(surah: surah) ? "star.fill" : "star")
                .foregroundColor(settings.accentColor.color)
                .font(.subheadline)
                .onTapGesture {
                    settings.hapticFeedback()

                    settings.toggleSurahFavorite(surah: surah)
                }
        }
    }
}

struct HeaderRow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    let arabicText: String
    let englishTransliteration: String
    let englishTranslation: String
    
    @State private var ayahBeginnerMode: Bool = false
    
    func arabicTextWithSpacesIfNeeded(_ text: String) -> String {
        if settings.beginnerMode || ayahBeginnerMode {
            return text.map { "\($0) " }.joined()
        }
        return text
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text(arabicTextWithSpacesIfNeeded(settings.cleanArabicText ? arabicText.removingArabicDiacriticsAndSigns : arabicText))
                .foregroundColor(settings.accentColor.color)
                .font(.custom(settings.fontArabic, size: settings.fontArabicSize))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)

            if settings.showTransliteration {
                Text(englishTransliteration)
                    .foregroundColor(settings.accentColor.color)
                    .font(.system(size: settings.englishFontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }

            if settings.showEnglishTranslation {
                Text(englishTranslation)
                    .foregroundColor(settings.accentColor.color)
                    .font(.system(size: settings.englishFontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        #if !os(watchOS)
        .contextMenu {
            if !settings.beginnerMode {
                Button(action: {
                    settings.hapticFeedback()
                    
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                }) {
                    Label("Beginner Mode", systemImage: ayahBeginnerMode ? "textformat.size.larger.ar" : "textformat.size.ar")
                }
            }
            
            if englishTranslation.contains("name") {
                Button(action: {
                    settings.hapticFeedback()
                    
                    quranPlayer.playBismillah()
                }) {
                    Label("Play Ayah", systemImage: "play.circle")
                }
            }
        }
        #endif
    }
}

struct AyahRow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var ayahBeginnerMode = false
    
    #if !os(watchOS)
    @State private var copySettings = CopySettings()
    @State private var showingAyahSheet = false
    #endif
    
    var surah: Surah
    var ayah: Ayah
        
    @Binding var scrollDown: Int?
    @Binding var searchText: String
        
    func arabicTextWithSpacesIfNeeded(_ text: String) -> String {
        if settings.beginnerMode || ayahBeginnerMode {
            return text.map { "\($0) " }.joined()
        }
        return text
    }
    
    var body: some View {
        ZStack {
            if let currentSurahNumber = quranPlayer.currentSurahNumber, let currentAyahNumber = quranPlayer.currentAyahNumber, currentSurahNumber == surah.id {
                RoundedRectangle(cornerRadius: 15)
                    .fill(ayah.id == currentAyahNumber ? settings.accentColor.color.opacity(settings.defaultView ? 0.1 : 0.25) : .clear)
                    .padding(.horizontal, -12)
                    .transition(.opacity)
                    .animation(.easeInOut, value: ayah.id == currentAyahNumber)
            }
            
            VStack {
                HStack {
                    Text("\(arabicNumberString(from: ayah.id))")
                        .foregroundColor(settings.accentColor.color)
                        #if !os(watchOS)
                        .font(.custom("KFGQPCHafsEx1UthmanicScript-Reg", size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize))
                        #else
                        .font(.custom("KFGQPCHafsEx1UthmanicScript-Reg", size: UIFont.preferredFont(forTextStyle: .title2).pointSize))
                        #endif
                    
                    Spacer()
                    
                    #if os(watchOS)
                    Image(systemName: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(settings.accentColor.color)
                        .font(.system(size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                        .onTapGesture {
                            settings.hapticFeedback()
                            
                            settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                        }
                    #else
                    if(settings.isBookmarked(surah: surah.id, ayah: ayah.id)) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(settings.accentColor.color)
                            .font(.system(size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                            .transition(.opacity)
                    }
                    
                    Menu {
                        Button(role: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? .destructive : nil, action: {
                            settings.hapticFeedback()
                            
                            settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                        }) {
                            Label(settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "Unbookmark Ayah" : "Bookmark Ayah", systemImage: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "bookmark.fill" : "bookmark")
                        }
                        
                        if settings.showArabicText && !settings.beginnerMode {
                            Button(action: {
                                settings.hapticFeedback()
                                
                                withAnimation {
                                    ayahBeginnerMode.toggle()
                                }
                            }) {
                                Label( "Beginner Mode", systemImage: ayahBeginnerMode ? "textformat.size.larger.ar" : "textformat.size.ar")
                            }
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
                        
                        Divider()
                        
                        Button(action: {
                            settings.hapticFeedback()
                            
                            copySettings = CopySettings(arabic: settings.showArabicText, transliteration: settings.showTransliteration, translation: settings.showEnglishTranslation)
                            showingAyahSheet = true
                        }) {
                            Label("Share Ayah", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        ZStack(alignment: .trailing) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .title2).pointSize))
                                .foregroundColor(settings.accentColor.color)
                                .padding(.trailing, -2)
                        }
                    }
                    .sheet(isPresented: $showingAyahSheet) {
                        CopyAyahSheet(copySettings: $copySettings, surahNumber: surah.id, ayahNumber: ayah.id)
                    }
                    #endif
                }
                .padding(.vertical, -10)
                
                #if !os(watchOS)
                Button(action: {
                    if !searchText.isEmpty {
                        settings.hapticFeedback()
                        scrollDown = ayah.id
                    }
                }) {
                    VStack {
                        if settings.showArabicText {
                            Text(arabicTextWithSpacesIfNeeded(settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic))
                                .foregroundColor(.primary)
                                .font(.custom(settings.fontArabic, size: settings.fontArabicSize))
                                .lineLimit(nil)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.vertical, 4)
                        }
                        
                        if settings.showTransliteration {
                            Text("\(ayah.id). \(ayah.textTransliteration ?? "")")
                                .font(.system(size: settings.englishFontSize))
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                        
                        if settings.showEnglishTranslation {
                            let englishText = settings.showTransliteration ? ayah.textEnglish : "\(ayah.id). \(ayah.textEnglish ?? "")"
                            Text(englishText ?? "")
                                .font(.system(size: settings.englishFontSize))
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .disabled(searchText.isEmpty)
                #else
                VStack {
                    if settings.showArabicText {
                        Text(arabicTextWithSpacesIfNeeded(settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic))
                            .foregroundColor(.primary)
                            .font(.custom(settings.fontArabic, size: settings.fontArabicSize))
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.vertical, 4)
                    }
                    
                    if settings.showTransliteration {
                        Text("\(ayah.id). \(ayah.textTransliteration ?? "")")
                            .font(.system(size: settings.englishFontSize))
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                    
                    if settings.showEnglishTranslation {
                        let englishText = settings.showTransliteration ? ayah.textEnglish : "\(ayah.id). \(ayah.textEnglish ?? "")"
                        Text(englishText ?? "")
                            .font(.system(size: settings.englishFontSize))
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                #endif

            }
            .lineLimit(nil)
            #if !os(watchOS)
            .contextMenu {
                Button(role: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? .destructive : nil, action: {
                    settings.hapticFeedback()
                    
                    settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                }) {
                    Label(settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "Unbookmark Ayah" : "Bookmark Ayah", systemImage: settings.isBookmarked(surah: surah.id, ayah: ayah.id) ? "bookmark.fill" : "bookmark")
                }
                
                if settings.showArabicText && !settings.beginnerMode {
                    Button(action: {
                        settings.hapticFeedback()
                        
                        withAnimation {
                            ayahBeginnerMode.toggle()
                        }
                    }) {
                        Label( "Beginner Mode", systemImage: ayahBeginnerMode ? "textformat.size.larger.ar" : "textformat.size.ar")
                    }
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
                
                Divider()
                
                Button(action: {
                    settings.hapticFeedback()
                    
                    copySettings = CopySettings(arabic: settings.showArabicText, transliteration: settings.showTransliteration, translation: settings.showEnglishTranslation)
                    showingAyahSheet = true
                }) {
                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                }
            }
            #endif
        }
        .animation(.easeInOut, value: quranPlayer.currentAyahNumber)
    }
}

struct AyahsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    @State private var searchText = ""
    @State private var lastAyahViewed: Int? = 1
    @State private var scrollDown: Int? = nil
    @State private var filteredAyahs: [Ayah] = []
    @State private var showingSettingsSheet = false
    @State private var showAlert = false
    
    let surah: Surah
    var ayah: Int? = 0
    
    func cleanSearch(_ text: String) -> String {
        let unwantedChars: [Character] = ["[", "]", "(", ")", "-", "'", "\""]
        let cleaned = text.filter { !unwantedChars.contains($0) }
        return cleaned.lowercased()
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                List {
                    Section(header: SurahSectionHeader(surah: surah)) {
                        if searchText.isEmpty {
                            VStack {
                                VStack {
                                    if surah.id == 1 || surah.id == 9 {
                                        HeaderRow(arabicText: "أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيْطَانِ ٱلرَّجِيمِ", englishTransliteration: "Audhu billahi minashaitanir rajeem", englishTranslation: "I seek refuge in Allah from the accursed Satan.")
                                            .padding(.vertical)
                                            .environmentObject(quranPlayer)
                                    } else {
                                        HeaderRow(arabicText: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", englishTransliteration: "Bismi Allahi alrrahmani alrraheemi", englishTranslation: "In the name of Allah, the Compassionate, the Merciful.")
                                            .padding(.vertical)
                                            .environmentObject(quranPlayer)
                                    }
                                }
                                #if !os(watchOS)
                                .listRowSeparator(.hidden, edges: .bottom)
                                #endif
                                
                                #if !os(watchOS)
                                Divider()
                                    .background(settings.accentColor.color)
                                    .padding(.trailing, -100)
                                    .padding(.bottom, -100)
                                #endif
                            }
                        }
                        
                        let filteredAyahs = surah.ayahs.filter { ayah in
                            let cleanSearchText = cleanSearch(searchText)
                            return searchText.isEmpty || cleanSearch(ayah.textClearArabic).contains(cleanSearchText) || cleanSearch(ayah.textTransliteration ?? "").contains(cleanSearchText) || cleanSearch(ayah.textEnglish ?? "").contains(cleanSearchText) || cleanSearch(String(ayah.id)).contains(cleanSearchText) || cleanSearch(arabicNumberString(from: ayah.id)).contains(cleanSearchText) || Int(cleanSearchText) == ayah.id
                        }
                        
                        ForEach(filteredAyahs, id: \.id) { ayah in
                            VStack {
                                AyahRow(surah: surah, ayah: ayah, scrollDown: $scrollDown, searchText: $searchText)
                                    .environmentObject(quranPlayer)
                                    .id(ayah.id)
                                    #if !os(watchOS)
                                    .onChange(of: scrollDown) { value in
                                        if let ayahID = value {
                                            if !searchText.isEmpty {
                                                settings.hapticFeedback()
                                                
                                                withAnimation {
                                                    searchText = ""
                                                    self.endEditing()
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                    withAnimation {
                                                        proxy.scrollTo(ayahID, anchor: .top)
                                                    }
                                                }
                                            }
                                            scrollDown = nil
                                        }
                                    }
                                    #endif
                                    .onDisappear {
                                        self.lastAyahViewed = ayah.id
                                    }
                            }
                            #if !os(watchOS)
                            .listRowSeparator(ayah.id == filteredAyahs.first?.id && searchText.isEmpty ? .hidden : .visible, edges: .top)
                            .listRowSeparator(ayah.id == filteredAyahs.last?.id ? .hidden : .visible, edges: .bottom)
                            #else
                            .padding(.vertical)
                            #endif
                        }
                    }
                }
                #if !os(watchOS)
                .applyConditionalListStyle(defaultView: settings.defaultView)
                .dismissKeyboardOnScroll()
                #endif
                .onAppear {
                    if let selectedAyah = ayah {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation {
                                proxy.scrollTo(selectedAyah, anchor: .top)
                            }
                        }
                    }
                }
                .onChange(of: quranPlayer.currentAyahNumber) { newValue in
                    if let ayahID = newValue, surah.id == quranPlayer.currentSurahNumber {
                        withAnimation {
                            proxy.scrollTo(ayahID, anchor: .top)
                        }
                    }
                }
                
                #if !os(watchOS)
                VStack {
                    if quranPlayer.isPlaying || quranPlayer.isPaused {
                        NowPlayingView(surahsView: false)
                            .environmentObject(quranPlayer)
                            .environmentObject(settings)
                            .padding(.horizontal, 8)
                            .transition(.opacity)
                    }

                    HStack {
                        SearchBar(text: $searchText.animation(.easeInOut))
                            .padding(.horizontal, 8)
                        
                        if let lastListenedSurah = settings.lastListenedSurah, lastListenedSurah.surahNumber == surah.id && !quranPlayer.isPlaying && !quranPlayer.isPaused {
                            Menu {
                                Button(action: {
                                    settings.hapticFeedback()
                                    
                                    quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: lastListenedSurah.surahName, certainReciter: true)
                                }) {
                                    Label("Play from Last Listened", systemImage: "play.fill")
                                }
                                
                                Button(action: {
                                    settings.hapticFeedback()
                                    
                                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                }) {
                                    Label("Play from Beginning", systemImage: "memories")
                                }
                            } label: {
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
                                } else {
                                    Image(systemName: "play.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(settings.accentColor.color)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.trailing, 28)
                        } else {
                            Button(action: {
                                settings.hapticFeedback()
                                
                                if quranPlayer.isLoading {
                                    quranPlayer.isLoading = false
                                    quranPlayer.pause(saveInfo: false)
                                } else {
                                    if quranPlayer.isPlaying || quranPlayer.isPaused {
                                        quranPlayer.stop()
                                    } else {
                                        quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                                    }
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
                                } else {
                                    Image(systemName: "play.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(settings.accentColor.color)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.trailing, 28)
                        }
                    }
                }
                .animation(.easeInOut, value: quranPlayer.isPlaying)
                #endif
            }
        }
        .onDisappear {
            withAnimation {
                settings.lastReadSurah = surah.id
                if let lastAyah = lastAyahViewed {
                    settings.lastReadAyah = lastAyah
                }
            }
        }
        #if !os(watchOS)
        .navigationTitle(surah.nameEnglish)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button(action: {
                settings.hapticFeedback()
                showingSettingsSheet = true
            }) {
                VStack(alignment: .trailing) {
                    Text("\(surah.nameArabic) - \(arabicNumberString(from: surah.id))")
                        .font(.footnote)
                        .foregroundColor(settings.accentColor.color)
                
                    Text("\(surah.nameTransliteration) - \(surah.id)")
                        .font(.footnote)
                        .foregroundColor(settings.accentColor.color)
                }
            }
        )
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView {
                List {
                    SettingsQuranView(showEdits: false)
                        .environmentObject(quranData)
                }
                .accentColor(settings.accentColor.color)
                .preferredColorScheme(settings.colorScheme)
                .navigationTitle("Al-Quran Settings")
                .navigationBarTitleDisplayMode(.inline)
                #if !os(watchOS)
                .applyConditionalListStyle(defaultView: true)
                #endif
            }
        }
        .onChange(of: quranPlayer.showInternetAlert) { newValue in
            if newValue {
                showAlert = true
                quranPlayer.showInternetAlert = false
            }
        }
        .confirmationDialog("Internet Connection Error", isPresented: $showAlert, titleVisibility: .visible) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to load the recitation due to an internet connection issue. Please check your connection and try again.")
        }
        #else
        .navigationTitle("\(surah.id) - \(surah.nameTransliteration)")
        #endif
    }
}

struct RotatingGearView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "gear")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    self.rotation = 360
                }
            }
    }
}

struct RotatingGearWatchView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "gear")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    self.rotation = 360
                }
            }
    }
}
