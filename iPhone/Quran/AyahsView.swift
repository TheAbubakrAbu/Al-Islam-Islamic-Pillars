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
    @State private var showCustomRangeSheet = false

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
        #if !os(watchOS)
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: 1,
                initialEndAyah: surah.numberOfAyahs,
                onPlay: { start, end, repAyah, repSec in
                    quranPlayer.playCustomRange(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration,
                        startAyah: start,
                        endAyah: end,
                        repeatPerAyah: repAyah,
                        repeatSection: repSec
                    )
                },
                onCancel: { showCustomRangeSheet = false }
            )
            .environmentObject(settings)
        }
        #endif
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
                    showCustomRangeSheet = true
                } label: {
                    Label("Play Custom Range", systemImage: "slider.horizontal.3")
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

#if !os(watchOS)
struct PlayCustomRangeSheet: View {
    @EnvironmentObject var settings: Settings

    let surah: Surah
    let initialStartAyah: Int
    let initialEndAyah: Int
    let onPlay: (Int, Int, Int, Int) -> Void
    let onCancel: () -> Void

    @State private var startAyah: Int
    @State private var endAyah: Int
    @State private var startAyahText: String
    @State private var endAyahText: String
    @State private var repeatPerAyah: Int
    @State private var repeatSection: Int

    private static let repeatOptions = [1, 2, 3, 5, 10, 20]

    init(
        surah: Surah,
        initialStartAyah: Int,
        initialEndAyah: Int,
        onPlay: @escaping (Int, Int, Int, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.surah = surah
        self.initialStartAyah = initialStartAyah
        self.initialEndAyah = initialEndAyah
        self.onPlay = onPlay
        self.onCancel = onCancel
        _startAyah = State(initialValue: initialStartAyah)
        _endAyah = State(initialValue: initialEndAyah)
        _startAyahText = State(initialValue: "\(initialStartAyah)")
        _endAyahText = State(initialValue: "\(initialEndAyah)")
        _repeatPerAyah = State(initialValue: 1)
        _repeatSection = State(initialValue: 1)
    }

    private var canPlay: Bool {
        startAyah >= 1 && endAyah <= surah.numberOfAyahs && startAyah <= endAyah
    }

    private var ayahCount: Int {
        max(0, endAyah - startAyah + 1)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    surahHeaderCard
                    rangeCard
                    repeatsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        settings.hapticFeedback()
                        onCancel()
                    }
                    .foregroundColor(settings.accentColor.color)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                playButtonBar
            }
        }
        .id("\(initialStartAyah)-\(initialEndAyah)")
    }

    private var surahHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundStyle(settings.accentColor.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliteration)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Surah \(surah.id) · \(surah.numberOfAyahs) ayahs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ayah range", systemImage: "number")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                rangeField(title: "From", value: $startAyah, text: $startAyahText, max: surah.numberOfAyahs) { new in
                    if new > endAyah { endAyah = new; endAyahText = "\(endAyah)" }
                }
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))
                rangeField(title: "To", value: $endAyah, text: $endAyahText, max: surah.numberOfAyahs) { new in
                    if new < startAyah { startAyah = new; startAyahText = "\(startAyah)" }
                }
            }
            .onChange(of: startAyah) { ayah in
                startAyahText = "\(ayah)"
            }
            .onChange(of: endAyah) { ayah in
                endAyahText = "\(endAyah)"
            }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.2)) {
                    startAyah = 1
                    endAyah = surah.numberOfAyahs
                    startAyahText = "1"
                    endAyahText = "\(surah.numberOfAyahs)"
                }
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Whole surah (1–\(surah.numberOfAyahs))")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(settings.accentColor.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("\(ayahCount) ayah\(ayahCount == 1 ? "" : "s") in range")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func rangeField(title: String, value: Binding<Int>, text: Binding<String>, max: Int, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 0) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        let new = value.wrappedValue > 1 ? value.wrappedValue - 1 : 1
                        value.wrappedValue = new
                        text.wrappedValue = "\(new)"
                        onChange(new)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue > 1 ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(value.wrappedValue <= 1)

                Spacer()
                TextField("", text: text)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 44, alignment: .center)
                    .onSubmit {
                        commitAyahInput(value: value, text: text, max: max, onChange: onChange)
                    }
                Spacer()

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        let new = value.wrappedValue < max ? value.wrappedValue + 1 : max
                        value.wrappedValue = new
                        text.wrappedValue = "\(new)"
                        onChange(new)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue < max ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(value.wrappedValue >= max)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private func commitAyahInput(value: Binding<Int>, text: Binding<String>, max: Int, onChange: @escaping (Int) -> Void) {
        let parsed = Int(text.wrappedValue.trimmingCharacters(in: .whitespaces)) ?? value.wrappedValue
        let clamped = min(Swift.max(1, parsed), max)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
        onChange(clamped)
    }

    private func commitBothAyahFields() {
        let maxAyah = surah.numberOfAyahs
        let s = min(Swift.max(1, Int(startAyahText.trimmingCharacters(in: .whitespaces)) ?? startAyah), maxAyah)
        let e = min(Swift.max(1, Int(endAyahText.trimmingCharacters(in: .whitespaces)) ?? endAyah), maxAyah)
        let from = min(s, e)
        let to = Swift.max(s, e)
        startAyah = from
        endAyah = to
        startAyahText = "\(from)"
        endAyahText = "\(to)"
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private var repeatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Repeats", systemImage: "repeat")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Each ayah")
                    .font(.caption)
                    .foregroundColor(.secondary)
                repeatOptionStrip(selection: $repeatPerAyah)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Whole section")
                    .font(.caption)
                    .foregroundColor(.secondary)
                repeatOptionStrip(selection: $repeatSection)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func repeatOptionStrip(selection: Binding<Int>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.repeatOptions, id: \.self) { n in
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection.wrappedValue = n
                        }
                    } label: {
                        Text("\(n)×")
                            .font(.subheadline.weight(selection.wrappedValue == n ? .semibold : .regular))
                            .foregroundColor(selection.wrappedValue == n ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selection.wrappedValue == n
                                    ? settings.accentColor.color
                                    : Color(UIColor.tertiarySystemFill)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var playButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                settings.hapticFeedback()
                commitBothAyahFields()
                onPlay(startAyah, endAyah, repeatPerAyah, repeatSection)
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Play range")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .background(canPlay ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canPlay)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}
#endif

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
