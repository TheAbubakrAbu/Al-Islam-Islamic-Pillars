import SwiftUI

struct AyahsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var searchText = ""
    @State private var visibleAyahs: [Int] = []
    @State private var scrollDown: Int? = nil
    @State private var didScrollDown = false
    @State private var showingSettingsSheet = false
    @State private var showAlert = false
    
    let surah: Surah
    var ayah: Int? = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                let cleanQuery = settings.cleanSearch(searchText, whitespace: true)
                
                let filteredAyahs = surah.ayahs.filter { a in
                    guard !cleanQuery.isEmpty else { return true }

                    let rawArabic   = settings.cleanSearch(a.textArabic)
                    let clearArabic = settings.cleanSearch(a.textClearArabic)

                    return rawArabic.contains(cleanQuery)
                        || clearArabic.contains(cleanQuery)
                        || settings.cleanSearch(a.textTransliteration).contains(cleanQuery)
                        || settings.cleanSearch(a.textEnglish).contains(cleanQuery)
                        || settings.cleanSearch(String(a.id)).contains(cleanQuery)
                        || settings.cleanSearch(arabicNumberString(from: a.id)).contains(cleanQuery)
                        || Int(cleanQuery) == a.id
                }
                
                List {
                    Section(header: SurahSectionHeader(surah: surah)) {
                        if searchText.isEmpty {
                            VStack {
                                if surah.id == 1 || surah.id == 9 {
                                    HeaderRow(
                                        arabicText: "أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيْطَانِ ٱلرَّجِيمِ",
                                        englishTransliteration: "Audhu billahi minashaitanir rajeem",
                                        englishTranslation: "I seek refuge in Allah from the accursed Satan."
                                    )
                                    .padding(.vertical)
                                } else {
                                    HeaderRow(
                                        arabicText: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                                        englishTransliteration: "Bismi Allahi alrrahmani alrraheemi",
                                        englishTranslation: "In the name of Allah, the Compassionate, the Merciful."
                                    )
                                    .padding(.vertical)
                                }
                                
                                #if !os(watchOS)
                                if !settings.defaultView {
                                    Divider()
                                        .background(settings.accentColor.color)
                                        .padding(.trailing, -100)
                                        .padding(.bottom, -100)
                                }
                                #endif
                            }
                        }
                    }
                    #if !os(watchOS)
                    .listRowSeparator(.hidden, edges: .bottom)
                    #endif
                    
                    ForEach(filteredAyahs, id: \.id) { ayah in
                        Group {
                            #if os(watchOS)
                            AyahRow(
                                surah: surah,
                                ayah: ayah,
                                scrollDown: $scrollDown,
                                searchText: $searchText
                            )
                            #else
                            Section {
                                AyahRow(
                                    surah: surah,
                                    ayah: ayah,
                                    scrollDown: $scrollDown,
                                    searchText: $searchText
                                )
                            }
                            #endif
                        }
                        .id(ayah.id)
                        .onAppear {
                            if !visibleAyahs.contains(ayah.id) { visibleAyahs.append(ayah.id) }
                        }
                        .onDisappear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                visibleAyahs.removeAll { $0 == ayah.id }
                            }
                        }
                        #if !os(watchOS)
                        .onChange(of: scrollDown) { value in
                            guard let target = value else { return }
                            if !searchText.isEmpty {
                                settings.hapticFeedback()
                                withAnimation {
                                    searchText = ""
                                    self.endEditing()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                                }
                            }
                            scrollDown = nil
                        }
                        #endif
                        #if !os(watchOS)
                        .listRowSeparator(
                            (ayah.id == filteredAyahs.first?.id && searchText.isEmpty) || settings.defaultView
                                ? .hidden : .visible,
                            edges: .top
                        )
                        .listRowSeparator(
                            ayah.id == filteredAyahs.last?.id || settings.defaultView
                                ? .hidden : .visible,
                            edges: .bottom
                        )
                        #else
                        .padding(.vertical)
                        #endif
                    }
                }
                .applyConditionalListStyle(defaultView: settings.defaultView)
                .dismissKeyboardOnScroll()
                
                .onAppear {
                    if let sel = ayah, !didScrollDown {
                        didScrollDown = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation { proxy.scrollTo(sel, anchor: .top) }
                        }
                    }
                }
                .onChange(of: quranPlayer.currentAyahNumber) { newVal in
                    if let id = newVal, surah.id == quranPlayer.currentSurahNumber {
                        withAnimation { proxy.scrollTo(id, anchor: .top) }
                    }
                }
                
                #if !os(watchOS)
                VStack {
                    if quranPlayer.isPlaying || quranPlayer.isPaused {
                        NowPlayingView(quranView: false)
                            .padding(.horizontal, 8)
                            .transition(.opacity)
                    }
                    
                    HStack {
                        SearchBar(text: $searchText.animation(.easeInOut))
                            .padding(.horizontal, 8)
                        
                        playButton(proxy: proxy)
                    }
                }
                .animation(.easeInOut, value: quranPlayer.isPlaying)
                #endif
            }
        }
        .environmentObject(quranPlayer)
        .onDisappear(perform: saveLastRead)
        .onChange(of: scenePhase) { _ in saveLastRead() }
        
        #if !os(watchOS)
        .navigationTitle(surah.nameEnglish)
        .navigationBarItems(trailing: navBarTitle)
        .sheet(isPresented: $showingSettingsSheet) { settingsSheet }
        .onChange(of: quranPlayer.showInternetAlert) { if $0 { showAlert = true; quranPlayer.showInternetAlert = false } }
        .confirmationDialog("Internet Connection Error",
                            isPresented: $showAlert,
                            titleVisibility: .visible) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to load the recitation due to an internet connection issue. Please check your connection and try again.")
        }
        #else
        .navigationTitle("\(surah.id) - \(surah.nameTransliteration)")
        #endif
    }
    
    #if !os(watchOS)
    @ViewBuilder
    private func playButton(proxy: ScrollViewProxy) -> some View {
        if let last = settings.lastListenedSurah,
           last.surahNumber == surah.id,
           !quranPlayer.isPlaying,
           !quranPlayer.isPaused {
            Menu {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: last.surahNumber,
                        surahName: last.surahName,
                        certainReciter: true
                    )
                } label: {
                    Label("Play from Last Listened", systemImage: "play.fill")
                }
                
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }
            } label: {
                playIcon()
            }
            .padding(.trailing, 28)
        } else {
            Button {
                settings.hapticFeedback()
                if quranPlayer.isLoading {
                    quranPlayer.isLoading = false
                    quranPlayer.pause(saveInfo: false)
                } else if quranPlayer.isPlaying || quranPlayer.isPaused {
                    quranPlayer.stop()
                } else {
                    quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                }
            } label: {
                playIcon()
            }
            .padding(.trailing, 28)
        }
    }
    
    @ViewBuilder
    private func playIcon() -> some View {
        if quranPlayer.isLoading {
            RotatingGearView().transition(.opacity)
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
    
    private var navBarTitle: some View {
        Button {
            settings.hapticFeedback()
            showingSettingsSheet = true
        } label: {
            VStack(alignment: .trailing) {
                Text("\(surah.nameArabic) - \(arabicNumberString(from: surah.id))")
                Text("\(surah.nameTransliteration) - \(surah.id)")
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
        }
    }
    
    private var settingsSheet: some View {
        NavigationView {
            List {
                SettingsQuranView(showEdits: false)
                    .environmentObject(quranData)
            }
            .accentColor(settings.accentColor.color)
            .preferredColorScheme(settings.colorScheme)
            .navigationTitle("Al-Quran Settings")
            .applyConditionalListStyle(defaultView: true)
        }
    }
    #endif
    
    private func saveLastRead() {
        DispatchQueue.main.async {
            withAnimation {
                settings.lastReadSurah = surah.id
                visibleAyahs.sort()
                if let firstVisible = visibleAyahs.first {
                    settings.lastReadAyah = firstVisible
                }
            }
        }
    }
}

struct RotatingGearView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        #if !os(watchOS)
        Image(systemName: "gear")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        #else
        Image(systemName: "gear")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        #endif
    }
}
