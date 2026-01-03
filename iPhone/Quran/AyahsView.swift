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
    @State private var showFloatingHeader = false
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
                    let cleanArabic = settings.cleanSearch(a.textCleanArabic)

                    return rawArabic.contains(cleanQuery)
                        || cleanArabic.contains(cleanQuery)
                        || settings.cleanSearch(a.textTransliteration).contains(cleanQuery)
                        || settings.cleanSearch(a.textEnglishSaheeh).contains(cleanQuery)
                        || settings.cleanSearch(a.textEnglishMustafa).contains(cleanQuery)
                        || settings.cleanSearch(String(a.id)).contains(cleanQuery)
                        || settings.cleanSearch(a.idArabic).contains(cleanQuery)
                        || Int(cleanQuery) == a.id
                }
                
                List {
                    if searchText.isEmpty {
                        Section(header:
                            SurahSectionHeader(surah: surah)
                                .onAppear {
                                    withAnimation {
                                        showFloatingHeader = false
                                    }
                                }
                                .onDisappear {
                                    withAnimation {
                                        showFloatingHeader = true
                                    }
                                }
                        ) {
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
                        #if !os(watchOS)
                        .listRowSeparator(.hidden, edges: .bottom)
                        #endif
                    }
                    
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
                            .animation(.easeInOut, value: quranPlayer.isPlaying)
                            .onTapGesture {
                                guard
                                    let curSurah = quranPlayer.currentSurahNumber,
                                    let curAyah  = quranPlayer.currentAyahNumber,
                                    curSurah == surah.id
                                else { return }

                                settings.hapticFeedback()

                                if !searchText.isEmpty {
                                    withAnimation {
                                        searchText = ""
                                        self.endEditing()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        withAnimation { proxy.scrollTo(curAyah, anchor: .top) }
                                    }
                                } else {
                                    withAnimation { proxy.scrollTo(curAyah, anchor: .top) }
                                }
                            }
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
        .overlay(alignment: .top) {
            SurahSectionHeader(surah: surah)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.clear.background(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
                #if !os(watchOS)
                .padding(.top, 6)
                .padding(.horizontal, settings.defaultView == true ? 20 : 16)
                #endif
                .background(Color.clear)
                .opacity(showFloatingHeader ? 1 : 0)
                .padding(.horizontal, 55)
                .zIndex(1)
                .transition(.move(edge: .top).combined(with: .opacity))
                .offset(y: showFloatingHeader ? 0 : -80)
                .opacity(showFloatingHeader ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: showFloatingHeader)
        }
        .navigationTitle(surah.nameEnglish)
        /*.toolbarTitleMenu {
            
        }*/
        .navigationBarItems(trailing: navBarTitle)
        .sheet(isPresented: $showingSettingsSheet) { settingsSheet }
        .onChange(of: quranPlayer.showInternetAlert) { if $0 { showAlert = true; quranPlayer.showInternetAlert = false } }
        .confirmationDialog("Internet Connection Error", isPresented: $showAlert, titleVisibility: .visible) {
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
        let playerIdle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused
        let canResumeLast = settings.lastListenedSurah?.surahNumber == surah.id
        let repeatCounts  = [2, 3, 5, 10]

        if playerIdle {
            Menu {
                if canResumeLast, let last = settings.lastListenedSurah {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(
                            surahNumber: last.surahNumber,
                            surahName:   last.surahName,
                            certainReciter: true
                        )
                    } label: {
                        Label("Play Last Listened", systemImage: "play.fill")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: surah.id,
                        surahName:   surah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }
                
                Menu {
                    ForEach(repeatCounts, id: \.self) { n in
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playSurah(
                                surahNumber: surah.id,
                                surahName: surah.nameTransliteration,
                                repeatCount: n
                            )
                        } label: {
                            Label("Repeat \(n)×", systemImage: "\(n).circle")
                        }
                    }
                } label: {
                    Label("Repeat Surah", systemImage: "repeat")
                }
                
                Button {
                    settings.hapticFeedback()
                    
                    if let randomAyah = surah.ayahs.randomElement() {
                        quranPlayer.playAyah(
                            surahNumber: surah.id,
                            ayahNumber: randomAyah.id,
                            continueRecitation: true
                        )
                    }
                } label: {
                    Label("Play Random Ayah", systemImage: "shuffle.circle.fill")
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
                Text("\(surah.nameArabic) - \(surah.idArabic)")
                Text("\(surah.nameTransliteration) - \(surah.id)")
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
        }
    }
    
    private var settingsSheet: some View {
        NavigationView { SettingsQuranView(showEdits: false) }
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
        Image(systemName: "gear")
            #if !os(watchOS)
            .font(.title3)
            #else
            .font(.subheadline)
            #endif
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    QuranView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
