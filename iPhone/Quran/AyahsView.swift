import SwiftUI

struct AyahsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var searchText = ""
    @State private var firstVisibleAyahID: Int? = nil
    @State private var visibleAyahIDs = Set<Int>()
    @State private var visibleBoundaryAyahIDs = Set<Int>()
    @State private var cachedAyahsForQiraah: [Ayah] = []
    @State private var cachedAyahByID: [Int: Ayah] = [:]
    @State private var overlayDividerByAyahID: [Int: BoundaryDividerModel] = [:]
    @State private var cacheQiraahKey: String = ""
    @State private var scrollDown: Int? = nil
    @State private var didScrollDown = false
    @State private var showingSettingsSheet = false
    @State private var showFloatingHeader = false
    @State private var showAlert = false
    @State private var showCustomRangeSheet = false
    @State private var showSurahPickerSheet = false
    @State private var selectedSurahNavigation: Int? = nil
    let surah: Surah
    var ayah: Int? = nil

    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()

    private func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        AyahsView.arFormatter.number(from: arabicNumber)?.intValue
    }

    private struct PageJuzQuery {
        let page: Int?
        let juz: Int?
    }

    private enum DividerKeywordMode {
        case page
        case juz
    }

    private func boundaryDividerStyleEquals(_ lhs: BoundaryDividerStyle, _ rhs: BoundaryDividerStyle) -> Bool {
        switch (lhs, rhs) {
        case (.allGreen, .allGreen),
             (.allSecondary, .allSecondary),
             (.pageAccentJuzSecondary, .pageAccentJuzSecondary),
             (.allAccent, .allAccent):
            return true
        default:
            return false
        }
    }

    private func boundaryDividerEquals(_ lhs: BoundaryDividerModel?, _ rhs: BoundaryDividerModel?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return l.text == r.text &&
                l.pageSegment == r.pageSegment &&
                l.juzSegment == r.juzSegment &&
                boundaryDividerStyleEquals(l.style, r.style)
        default:
            return false
        }
    }

    private func boundaryDividerID(_ model: BoundaryDividerModel) -> String {
        let juz = model.juzSegment ?? ""
        let style: String
        switch model.style {
        case .allGreen: style = "allGreen"
        case .allSecondary: style = "allSecondary"
        case .pageAccentJuzSecondary: style = "pageAccentJuzSecondary"
        case .allAccent: style = "allAccent"
        }
        return "\(model.text)|\(model.pageSegment)|\(juz)|\(style)"
    }

    private func boundaryText(for ayah: Ayah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page = ayah.page {
            return "Page \(page)"
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func parsePageJuzQuery(from raw: String) -> PageJuzQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return PageJuzQuery(page: nil, juz: nil) }

        let lowered = trimmed.lowercased()

        if lowered.hasPrefix("page ") {
            let valueText = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            let n = Int(valueText) ?? arabicToEnglishNumber(valueText)
            if let n, (1...630).contains(n) { return PageJuzQuery(page: n, juz: nil) }
            return PageJuzQuery(page: nil, juz: nil)
        }

        if lowered.hasPrefix("juz ") {
            let valueText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            let n = Int(valueText) ?? arabicToEnglishNumber(valueText)
            if let n, (1...30).contains(n) { return PageJuzQuery(page: nil, juz: n) }
            return PageJuzQuery(page: nil, juz: nil)
        }

        return PageJuzQuery(page: nil, juz: nil)
    }

    private func rebuildQiraahCaches() {
        let key = settings.displayQiraahForArabic ?? ""
        guard key != cacheQiraahKey || cachedAyahsForQiraah.isEmpty else { return }

        let ayahs = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
        cachedAyahsForQiraah = ayahs
        cachedAyahByID = Dictionary(uniqueKeysWithValues: ayahs.map { ($0.id, $0) })

        var overlayMap: [Int: BoundaryDividerModel] = [:]
        overlayMap.reserveCapacity(ayahs.count)

        for ayah in ayahs {
            let pageSegment: String
            if let page = ayah.page {
                pageSegment = "Page \(page)"
            } else if let juz = ayah.juz {
                pageSegment = "Juz \(juz)"
            } else {
                continue
            }

            let juzSegment = (ayah.page != nil) ? ayah.juz.map { "Juz \($0)" } : nil
            overlayMap[ayah.id] = BoundaryDividerModel(
                text: boundaryText(for: ayah) ?? pageSegment,
                pageSegment: pageSegment,
                juzSegment: juzSegment,
                style: .allAccent
            )
        }

        overlayDividerByAyahID = overlayMap
        cacheQiraahKey = key

        let fallbackID = ayahs.first?.id
        if let firstVisibleAyahID {
            if cachedAyahByID[firstVisibleAyahID] == nil {
                self.firstVisibleAyahID = fallbackID
            }
        } else {
            self.firstVisibleAyahID = fallbackID
        }
    }

    private func boundaryDivider(model: BoundaryDividerModel, isOverlay: Bool = false, nextAyahID: Int? = nil) -> some View {
        let accent = settings.accentColor.color
        let dividerColor: Color = {
            if isOverlay { return .green }
            switch model.style {
            case .allGreen: return .green
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let pageColor: Color = {
            if isOverlay { return accent }
            switch model.style {
            case .allGreen: return .green
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let juzColor: Color = {
            if isOverlay { return .green }
            switch model.style {
            case .allGreen: return .green
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary: return .secondary
            case .allAccent: return accent
            }
        }()
        let separatorColor: Color = {
            if isOverlay { return .green }
            switch model.style {
            case .allGreen: return .green
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()

        let dividerContent = HStack(spacing: isOverlay ? 8 : 10) {
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(minWidth: 10, maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(height: 1)
                        .frame(minWidth: 18)
                }
            }

            (
                Text(model.pageSegment)
                    .foregroundColor(pageColor)
                +
                (model.juzSegment.map {
                    Text(" • ").foregroundColor(separatorColor)
                    + Text($0).foregroundColor(juzColor)
                } ?? Text(""))
            )
            .font((isOverlay ? Font.caption : Font.caption).weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(isOverlay ? 0.5 : 0.6)
            .allowsTightening(!isOverlay)
            .layoutPriority(2)
            .fixedSize(horizontal: isOverlay, vertical: true)

            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(minWidth: 10, maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(height: 1)
                        .frame(minWidth: 18)
                }
            }
        }
        .padding(.vertical, isOverlay ? 4 : 6)
        .padding(.horizontal, isOverlay ? 10 : 0)
        .frame(maxWidth: isOverlay ? .infinity : nil)
        
        #if !os(watchOS)
        if !searchText.isEmpty, let ayahID = nextAyahID {
            return AnyView(
                Button { 
                    settings.hapticFeedback()
                    scrollDown = ayahID
                } label: {
                    dividerContent
                }
                .buttonStyle(.plain)
            )
        }
        #endif
        
        return AnyView(dividerContent)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ayahListScreen(proxy: proxy)
        }
        .environmentObject(quranPlayer)
        .onDisappear(perform: saveLastRead)
        .onChange(of: scenePhase) { _ in saveLastRead() }
        #if !os(watchOS)
        .navigationTitle(surah.nameEnglish)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                navBarTitle
            }
        }
        .onAppear {
            quranPlayer.recordReadingHistory(surahNumber: surah.id, surahName: surah.nameTransliteration, ayahNumber: ayah ?? 1)
        }
        .sheet(isPresented: $showingSettingsSheet) { settingsSheet }
        .sheet(isPresented: $showSurahPickerSheet) {
            SurahPickerSheet(currentSurahID: surah.id) { selectedSurah in
                settings.hapticFeedback()
                showSurahPickerSheet = false

                guard selectedSurah.id != surah.id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    selectedSurahNavigation = selectedSurah.id
                }
            }
            .environmentObject(settings)
            .environmentObject(quranData)
        }
        #if !os(watchOS)
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: 1,
                initialEndAyah: surah.numberOfAyahs(for: settings.displayQiraahForArabic),
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
        .confirmationDialog(quranPlayer.playbackAlertTitle, isPresented: $showAlert, titleVisibility: .visible) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(quranPlayer.playbackAlertMessage)
        }
        .background(
            NavigationLink(
                destination: selectedSurahNavigationDestination,
                isActive: Binding(
                    get: { selectedSurahNavigation != nil },
                    set: { isActive in
                        if !isActive {
                            selectedSurahNavigation = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        #else
        .navigationTitle("\(surah.id) - \(surah.nameTransliteration)")
        #endif
    }

    private func ayahListScreen(proxy: ScrollViewProxy) -> some View {
        let cleanQuery = settings.cleanSearch(searchText, whitespace: true)
        let pageJuzQuery = parsePageJuzQuery(from: searchText)
        let trimmedLowerSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dividerKeywordMode: DividerKeywordMode? = {
            if trimmedLowerSearch == "page" || trimmedLowerSearch == "pages" { return .page }
            if trimmedLowerSearch == "juz" { return .juz }
            return nil
        }()
        let isDividerKeywordSearch = dividerKeywordMode != nil
        let isPageOrJuzSearch = pageJuzQuery.page != nil || pageJuzQuery.juz != nil
        let showBoundaryDividers = settings.showPageJuzDividers && (searchText.isEmpty || isPageOrJuzSearch || isDividerKeywordSearch)
        let ayahsForQiraah = cachedAyahsForQiraah.isEmpty
            ? surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
            : cachedAyahsForQiraah
        let ayahByID = cachedAyahByID.isEmpty
            ? Dictionary(uniqueKeysWithValues: ayahsForQiraah.map { ($0.id, $0) })
            : cachedAyahByID
        let filteredAyahs = ayahsForQiraah.filter { a in
            guard !cleanQuery.isEmpty else { return true }

            if isDividerKeywordSearch {
                return false
            }

            if isPageOrJuzSearch {
                let pageMatch = pageJuzQuery.page != nil && a.page == pageJuzQuery.page
                let juzMatch = pageJuzQuery.juz != nil && a.juz == pageJuzQuery.juz
                return pageMatch || juzMatch
            }

            let rawArabic = settings.cleanSearch(a.textArabic)
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
        let boundaryModel = showBoundaryDividers ? quranData.boundaryModel(forSurah: surah.id) : nil
        let trailingSearchBoundaryDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, isPageOrJuzSearch, !isDividerKeywordSearch else { return nil }
            guard let boundaryModel else { return nil }
            guard let lastFilteredAyahID = filteredAyahs.last?.id else { return nil }

            if let idx = ayahsForQiraah.firstIndex(where: { $0.id == lastFilteredAyahID }) {
                let nextIndex = ayahsForQiraah.index(after: idx)
                if nextIndex < ayahsForQiraah.endIndex {
                    let nextAyah = ayahsForQiraah[nextIndex]
                    return boundaryModel.dividerBeforeAyah[nextAyah.id]
                }
            }

            return boundaryModel.endDivider
        }()
        let startOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, searchText.isEmpty else { return nil }
            return boundaryModel?.startDivider
        }()
        let endOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, searchText.isEmpty else { return nil }
            return boundaryModel?.endOfSurahDivider
        }()
        let currentFloatingAyah = firstVisibleAyahID
            .flatMap { visibleID in ayahByID[visibleID] }
            ?? ayahsForQiraah.first
        let floatingDividerModel: BoundaryDividerModel? = {
            guard showBoundaryDividers, settings.showPageJuzOverlay, searchText.isEmpty else { return nil }
            guard let currentFloatingAyah else { return nil }
            return overlayDividerByAyahID[currentFloatingAyah.id]
        }()
        let floatingDividerAnimationKey = floatingDividerModel.map(boundaryDividerID) ?? "none"
        let keywordDividerModels: [BoundaryDividerModel] = {
            guard let mode = dividerKeywordMode else { return [] }
            guard let boundaryModel else { return [] }

            var allDividerModels: [BoundaryDividerModel] = []

            if let start = boundaryModel.startDivider {
                allDividerModels.append(start)
            }

            for ayah in ayahsForQiraah {
                if let model = boundaryModel.dividerBeforeAyah[ayah.id] {
                    allDividerModels.append(model)
                }
            }

            if let end = boundaryModel.endDivider {
                allDividerModels.append(end)
            }

            var seen = Set<String>()
            return allDividerModels.filter { model in
                let matches: Bool
                let dedupeKey: String
                switch mode {
                case .page:
                    matches = model.text.localizedCaseInsensitiveContains("Page")
                    dedupeKey = model.text
                case .juz:
                    matches = model.text.localizedCaseInsensitiveContains("Juz")
                    dedupeKey = model.juzSegment
                        ?? (model.pageSegment.localizedCaseInsensitiveContains("Juz") ? model.pageSegment : model.text)
                }
                guard matches else { return false }
                return seen.insert(dedupeKey).inserted
            }
        }()
        let searchCount = isDividerKeywordSearch ? keywordDividerModels.count : filteredAyahs.count
        let syncVisibleAyahAnchor: () -> Void = {
            let nextVisibleAyahID: Int?
            if let topVisibleAyahID = (visibleAyahIDs.union(visibleBoundaryAyahIDs)).min() {
                nextVisibleAyahID = topVisibleAyahID
            } else if let sel = ayah, ayahByID[sel] != nil {
                nextVisibleAyahID = sel
            } else {
                nextVisibleAyahID = ayahsForQiraah.first?.id
            }

            guard nextVisibleAyahID != firstVisibleAyahID else { return }
            firstVisibleAyahID = nextVisibleAyahID
        }

        return List {
                Section {
                    VStack {
                        let firstAyahClean = ayahsForQiraah.first?.textCleanArabic.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let showTaawwudh = (surah.id == 9) || (surah.id == 1 && firstAyahClean.hasPrefix("بسم"))
                        if showTaawwudh {
                            HeaderRow(
                                arabicText: "أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيۡطَانِ ٱلرَّجِيمِ",
                                englishTransliteration: "Audhu billahi minashaitanir rajeem",
                                englishTranslation: "I seek refuge in Allah from the accursed Satan."
                            )
                            .padding(.vertical)
                        } else {
                            HeaderRow(
                                arabicText: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِِ",
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
                } header: {
                    ZStack {
                        if searchText.isEmpty {
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
                        }
                        
                        HStack {
                            if !searchText.isEmpty { Spacer() }
                            
                            Text(String(searchCount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                #if !os(watchOS)
                                .background(.ultraThinMaterial)
                                #endif
                                .clipShape(Capsule())
                                .conditionalGlassEffect()
                                .opacity(searchText.isEmpty ? 0 : 1)
                        }
                    }
                    .animation(.easeInOut, value: searchText)
                    .transition(.opacity)
                }

                #if !os(watchOS)
                .listRowSeparator(.hidden, edges: .bottom)
                #endif

                if isDividerKeywordSearch {
                    ForEach(Array(keywordDividerModels.enumerated()), id: \.offset) { _, dividerModel in
                        Section {
                            boundaryDivider(model: dividerModel, nextAyahID: filteredAyahs.first?.id)
                        }
                        #if !os(watchOS)
                        .listRowSeparator(.hidden)
                        #endif
                    }
                } else {
                    if let startOfSurahDivider {
                        Section {
                            boundaryDivider(model: startOfSurahDivider, nextAyahID: filteredAyahs.first?.id)
                        }
                        .onAppear {
                            if let nextID = filteredAyahs.first?.id {
                                visibleBoundaryAyahIDs.insert(nextID)
                                syncVisibleAyahAnchor()
                            }
                        }
                        .onDisappear {
                            if let nextID = filteredAyahs.first?.id {
                                visibleBoundaryAyahIDs.remove(nextID)
                                syncVisibleAyahAnchor()
                            }
                        }
                        #if !os(watchOS)
                        .listRowSeparator(.hidden)
                        #endif
                    }

                    ForEach(filteredAyahs, id: \.id) { ayah in
                        let dividerBefore = showBoundaryDividers ? boundaryModel?.dividerBeforeAyah[ayah.id] : nil

                        if let dividerBefore {
                            Section {
                                boundaryDivider(model: dividerBefore, nextAyahID: ayah.id)
                            }
                            .onAppear {
                                visibleBoundaryAyahIDs.insert(ayah.id)
                                syncVisibleAyahAnchor()
                            }
                            .onDisappear {
                                visibleBoundaryAyahIDs.remove(ayah.id)
                                syncVisibleAyahAnchor()
                            }
                            #if !os(watchOS)
                            .listRowSeparator(.hidden)
                            #endif
                        }

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
                            visibleAyahIDs.insert(ayah.id)
                            syncVisibleAyahAnchor()
                        }
                        .onDisappear {
                            visibleAyahIDs.remove(ayah.id)
                            syncVisibleAyahAnchor()
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

                    if let endOfSurahDivider {
                        Section {
                            boundaryDivider(model: endOfSurahDivider, nextAyahID: nil)
                        }
                        #if !os(watchOS)
                        .listRowSeparator(.hidden)
                        #endif
                    }

                    if let trailingSearchBoundaryDivider {
                        Section {
                            boundaryDivider(model: trailingSearchBoundaryDivider, nextAyahID: nil)
                        }
                        #if !os(watchOS)
                        .listRowSeparator(.hidden)
                        #endif
                    }
                }
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .compactListSectionSpacing()
            .dismissKeyboardOnScroll()
            .onAppear {
                rebuildQiraahCaches()
                visibleAyahIDs.removeAll()
                visibleBoundaryAyahIDs.removeAll()
                if let sel = ayah, ayahByID[sel] != nil {
                    firstVisibleAyahID = sel
                } else if firstVisibleAyahID == nil {
                    firstVisibleAyahID = ayahsForQiraah.first?.id
                }

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
            .onChange(of: settings.displayQiraah) { _ in
                cacheQiraahKey = ""
                rebuildQiraahCaches()
                visibleAyahIDs.removeAll()
                visibleBoundaryAyahIDs.removeAll()
            }
            #if !os(watchOS)
            .overlay(alignment: .top) {
                floatingHeaderOverlay(
                    floatingDividerModel: floatingDividerModel,
                    floatingDividerAnimationKey: floatingDividerAnimationKey
                )
            }
            .safeAreaInset(edge: .bottom) {
                bottomInsetContent(proxy: proxy)
            }
            #endif
    }

    private func floatingHeaderOverlay(
        floatingDividerModel: BoundaryDividerModel?,
        floatingDividerAnimationKey: String
    ) -> some View {
        VStack(spacing: 6) {
            SurahSectionHeader(surah: surah)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
                .conditionalGlassEffect()

            ZStack {
                if let floatingDividerModel {
                    boundaryDivider(model: floatingDividerModel, isOverlay: true)
                        .id(boundaryDividerID(floatingDividerModel))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
                        .conditionalGlassEffect()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .animation(.easeInOut(duration: 0.18), value: floatingDividerAnimationKey)
        }
        .padding(.top, 6)
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .background(Color.clear)
        .opacity(showFloatingHeader ? 1 : 0)
        .padding(.horizontal, 30)
        .zIndex(1)
        .offset(y: showFloatingHeader ? 0 : -80)
        .opacity(showFloatingHeader ? 1 : 0)
    }

    #if !os(watchOS)
    private func bottomInsetContent(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 8) {
            qiraatAndTajweedControls
            playbackAndSearchControls(proxy: proxy)
        }
    }

    @ViewBuilder
    private var qiraatAndTajweedControls: some View {
        if settings.qiraatComparisonMode || settings.showTajweedColors {
            HStack(alignment: .bottom, spacing: 8) {
                if settings.showTajweedColors {
                    TajweedLegendMenu(expandsToFillRow: !settings.qiraatComparisonMode)
                }

                if settings.qiraatComparisonMode {
                    Spacer()
                    ArabicTextRiwayahPicker(selection: $settings.displayQiraah.animation(.easeInOut))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func playbackAndSearchControls(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 6) {
            nowPlayingInset(proxy: proxy)
            HStack(spacing: 0) {
                SearchBar(text: $searchText.animation(.easeInOut))

                playButton(proxy: proxy)
                    .frame(width: 26, height: 26)
                    .padding()
                    .conditionalGlassEffect()
            }
            .padding([.leading, .top], -8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.00001))
        .animation(.easeInOut, value: quranPlayer.isPlaying)
    }
    #endif

    @ViewBuilder
    private func nowPlayingInset(proxy: ScrollViewProxy) -> some View {
        if quranPlayer.isPlaying || quranPlayer.isPaused {
            NowPlayingView(quranView: false)
                .animation(.easeInOut, value: quranPlayer.isPlaying)
                .onTapGesture {
                    guard
                        let curSurah = quranPlayer.currentSurahNumber,
                        let curAyah = quranPlayer.currentAyahNumber,
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
    }
    
    #if !os(watchOS)
    @ViewBuilder
    private func playButton(proxy: ScrollViewProxy) -> some View {
        let playerIdle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused
        let canResumeLast = settings.lastListenedSurah?.surahNumber == surah.id
        let repeatCounts  = [20, 15, 10, 5, 3, 2]

        if playerIdle {
            Menu {
                if canResumeLast, let last = settings.lastListenedSurah {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(
                            surahNumber: last.surahNumber,
                            surahName: last.surahName,
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
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }
                
                Menu {
                    Button {
                        settings.hapticFeedback()
                        showCustomRangeSheet = true
                    } label: {
                        Label("Play Custom Range", systemImage: "slider.horizontal.3")
                    }
                    
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(
                            surahNumber: surah.id,
                            ayahNumber: 1,
                            continueRecitation: true
                        )
                    } label: {
                        Label("Play Ayah by Ayah", systemImage: "list.number")
                    }
                    
                    Button {
                        settings.hapticFeedback()
                        let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
                        if let randomAyah = ayahsForQiraah.randomElement() {
                            quranPlayer.playAyah(
                                surahNumber: surah.id,
                                ayahNumber: randomAyah.id,
                                continueRecitation: true
                            )
                        }
                    } label: {
                        Label("Play Random Ayah", systemImage: "shuffle")
                    }
                    
                    Button {
                        settings.hapticFeedback()
                        playRandomReciterForCurrentSurah()
                    } label: {
                        Label("Play Random Reciter", systemImage: "person.wave.2")
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
                } label: {
                    Label("Other Options", systemImage: "ellipsis.circle")
                }
            } label: {
                playIcon()
            }
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
        }
    }

    private func playRandomReciterForCurrentSurah() {
        guard let randomReciter = reciters.randomElement() else { return }
        settings.reciter = randomReciter.name
        quranPlayer.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration
        )
    }
    
    @ViewBuilder
    private func playIcon() -> some View {
        if quranPlayer.isLoading {
            RotatingGearView().transition(.opacity)
        } else if quranPlayer.isPlaying || quranPlayer.isPaused {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .transition(.opacity)
        } else {
            Image(systemName: "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .transition(.opacity)
        }
    }
    
    private var surahTitlePickerButton: some View {
        Button {
            settings.hapticFeedback()
            showSurahPickerSheet = true
        } label: {
            Text(surah.nameEnglish)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.primary)
                .padding(6)
                .conditionalGlassEffect()
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
            .padding(6)
        }
    }

    @ViewBuilder
    private var selectedSurahNavigationDestination: some View {
        if let targetID = selectedSurahNavigation,
           let targetSurah = quranData.surah(targetID) {
            AyahsView(surah: targetSurah)
        } else {
            EmptyView()
        }
    }
    
    private var settingsSheet: some View {
        NavigationView { SettingsQuranView(showEdits: false, presentedAsSheet: true) }
    }
    #endif
    
    private func saveLastRead() {
        let topVisible = visibleAyahIDs.min()
        let targetAyah = topVisible
            ?? firstVisibleAyahID
            ?? ayah
            ?? cachedAyahsForQiraah.first?.id

        guard let targetAyah else { return }

        if settings.lastReadSurah == surah.id, settings.lastReadAyah == targetAyah {
            return
        }

        withAnimation {
            settings.lastReadSurah = surah.id
            settings.lastReadAyah = targetAyah
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

#if !os(watchOS)
private struct SurahPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData

    @State private var searchText = ""

    let currentSurahID: Int
    let onSelect: (Surah) -> Void

    private var filteredSurahs: [Surah] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return quranData.quran }

        return quranData.quran.filter { surah in
            let tokens = [
                "\(surah.id)",
                normalized(surah.nameEnglish),
                normalized(surah.nameTransliteration),
                normalized(surah.nameArabic)
            ]
            return tokens.contains { $0.contains(query) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSurahs, id: \.id) { surah in
                    Button {
                        onSelect(surah)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            SurahRow(surah: surah)

                            if surah.id == currentSurahID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search surah")
            .navigationTitle("All Surahs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func normalized(_ text: String) -> String {
        settings.cleanSearch(text, whitespace: true)
    }
}
#endif

struct ArabicTextRiwayahPicker: View {
    @EnvironmentObject private var settings: Settings
    @Binding var selection: String
    var useSimpleIOSPicker: Bool = false

    private static let options: [(label: String, tag: String)] = [
        ("Hafs an Asim (default)", ""),
        ("Shu'bah an Asim", "Shu'bah an Asim"),
        
        ("Al-Buzzi an Ibn Kathir", "Al-Buzzi an Ibn Kathir"),
        ("Qunbul an Ibn Kathir", "Qunbul an Ibn Kathir"),
        
        ("Warsh an Nafi", "Warsh an Nafi"),
        ("Qaloon an Nafi", "Qaloon an Nafi"),
        
        ("Ad-Duri an Abi Amr", "Ad-Duri an Abi Amr"),
        ("As-Susi an Abi Amr", "As-Susi an Abi Amr")
    ]

    private var currentLabel: String {
        Self.options.first(where: { $0.tag == selection })?.label ?? "Arabic Riwayah"
    }

    var body: some View {
        #if os(watchOS)
        Picker("Arabic Riwayah", selection: $selection) {
            ForEach(Self.options, id: \.tag) { option in
                Text(option.label).tag(option.tag)
            }
        }
        #else
        if useSimpleIOSPicker {
            Picker("Arabic Riwayah", selection: $selection) {
                ForEach(Self.options, id: \.tag) { option in
                    Text(option.label).tag(option.tag)
                }
            }
        } else {
            Menu {
                ForEach(Array(Self.options.reversed()), id: \.tag) { option in
                    Button {
                        selection = option.tag
                    } label: {
                        HStack {
                            if option.tag == selection {
                                Image(systemName: "checkmark")
                            }
                            
                            Text(option.label)
                        }
                        .font(.caption)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentLabel)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(settings.accentColor.color.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
                .conditionalGlassEffect()
            }
        }
        #endif
    }
}

#if !os(watchOS)
private struct TajweedLegendMenu: View {
    @EnvironmentObject private var settings: Settings
    @State private var showingSheet = false
    var expandsToFillRow: Bool = false

    private let items = TajweedLegendCategory.allCases

    private var quickLegendColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10, alignment: .top),
            GridItem(.flexible(), spacing: 10, alignment: .top)
        ]
    }

    var body: some View {
        Button {
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach([Color.red, Color.orange, Color.yellow, Color.green, Color.blue], id: \.self) { item in
                        Circle()
                            .fill(item)
                            .frame(width: 5, height: 5)
                    }
                }

                Text("Legend")
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)
            }
            .frame(maxWidth: expandsToFillRow ? .infinity : nil, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
            .conditionalGlassEffect()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            if #available(iOS 16.0, *) {
                legendSheetContent
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                legendSheetContent
            }
        }
    }

    private var legendSheetContent: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tajweed Legend")
                            .font(.title3.weight(.semibold))

                        Text("Use the colors as a quick guide, then read the longer notes below for what each rule is doing in recitation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Guide")
                            .font(.headline)

                        LazyVGrid(columns: quickLegendColumns, alignment: .leading, spacing: 10) {
                            ForEach(items) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .center, spacing: 8) {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 11, height: 11)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.englishTitle)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)

                                            Text(item.arabicTitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    if #available(iOS 16.0, *) {
                                        Text(item.shortDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2, reservesSpace: true)
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else {
                                        Text(item.shortDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    HStack {
                                        Spacer()

                                        Button {
                                            settings.hapticFeedback()
                                            withAnimation(.easeInOut(duration: 0.18)) {
                                                settings.setTajweedCategory(item, visible: !settings.isTajweedCategoryVisible(item))
                                            }
                                        } label: {
                                            Image(systemName: settings.isTajweedCategoryVisible(item) ? "eye.fill" : "eye.slash.fill")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(settings.isTajweedCategoryVisible(item) ? item.color : .secondary)
                                                .frame(width: 22, height: 22)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.18), value: settings.isTajweedCategoryVisible(item))
                                .opacity(settings.isTajweedCategoryVisible(item) ? 1 : 0.45)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.primary.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(item.color.opacity(0.35), lineWidth: 1)
                                )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("More Detail")
                            .font(.headline)

                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 12, height: 12)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.englishTitle)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)

                                        Text(item.arabicTitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 6)

                                    Button(settings.isTajweedCategoryVisible(item) ? "Hide" : "Show") {
                                        settings.hapticFeedback()
                                        
                                        withAnimation {
                                            settings.setTajweedCategory(item, visible: !settings.isTajweedCategoryVisible(item))
                                        }
                                    }
                                    .font(.caption.weight(.semibold))
                                }

                                Text(item.longDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .opacity(settings.isTajweedCategoryVisible(item) ? 1 : 0.45)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip")
                            .font(.headline)

                        Text("These colors help you notice recitation patterns quickly, but listening to a qualified reciter is still the best way to hear how each rule should sound.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(settings.accentColor.color.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(settings.accentColor.color.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Legend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSheet = false
                    }
                }
            }
        }
    }
}

#endif

#Preview {
    AlIslamPreviewContainer {
        AyahsView(surah: AlIslamPreviewData.surah)
    }
}
