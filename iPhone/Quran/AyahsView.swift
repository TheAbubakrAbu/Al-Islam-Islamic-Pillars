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
    @State private var cachedSearchBlobByAyahID: [Int: String] = [:]
    @State private var overlayDividerByAyahID: [Int: BoundaryDividerModel] = [:]
    @State private var cacheQiraahKey: String = ""
    /// Busts qiraah caches when navigating to a different surah (e.g. iPad `NavigationSplitView` reusing one `AyahsView`).
    @State private var qiraahCacheSurahID: Int? = nil
    @State private var scrollDown: Int? = nil
    @State private var pendingScrollAfterSearchClear: Int? = nil
    @State private var didScrollDown = false
    @State private var showingSettingsSheet = false
    @State private var showFloatingHeader = false
    @State private var showAlert = false
    @State private var showCustomRangeSheet = false
    @State private var showReciterPickerSheet = false
    @State private var showSurahPickerSheet = false
    @State private var isAyahSearchFocused = false
    @State private var selectedSurahNavigation: Int? = nil
    @State private var dividerInfo: DividerInfo? = nil
    @State private var surahInfoDialog: SurahInfoDialog? = nil
    let surah: Surah
    var ayah: Int? = nil

    private struct DividerInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private struct SurahInfoDialog: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

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

    @ViewBuilder
    private func listBoundaryDivider(model: BoundaryDividerModel, nextAyahID: Int? = nil) -> some View {
        if settings.defaultView {
            boundaryDivider(model: model, nextAyahID: nextAyahID)
        } else {
            VStack {
                boundaryDivider(model: model, nextAyahID: nextAyahID)
                
                Divider()
                    .padding(.top, 7)
            }
            #if os(iOS)
            .listRowSeparator(.hidden)
            #endif
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

    private func boundaryDividerInfo(for model: BoundaryDividerModel) -> DividerInfo {
        let title: String
        let message: String

        switch model.style {
        case .allGreen:
            title = "Highlighted divider"
            message = "\(model.text)\n\nThis divider is highlighted because it marks a surah start or end. It is mostly a visual marker, not a page or juz change."
        case .allSecondary:
            title = "Surah boundary"
            message = "\(model.text)\n\nGray means the page and juz do not change here. It is mainly showing a surah start or end."
        case .pageAccentJuzSecondary:
            title = "Page boundary"
            message = "\(model.text)\n\nThe color change means the page changes here. The juz stays the same."
        case .allAccent:
            title = "Page and juz boundary"
            message = "\(model.text)\n\nThe color change means both the page and the juz change here."
        }

        return DividerInfo(title: title, message: message)
    }

    private func surahInfoDialog(for surah: Surah) -> SurahInfoDialog {
        let revelationOrderText = surah.revelationOrder.map(String.init) ?? "Unknown"
        var message = "Revelation order: #\(revelationOrderText)"

        if let exceptions = surah.revelationExceptions?.trimmingCharacters(in: .whitespacesAndNewlines), !exceptions.isEmpty {
            message += "\n\nExceptions: \(exceptions)"
        }

        return SurahInfoDialog(title: "Surah Info", message: message)
    }

    /// Ayah row id to scroll to after clearing search (first ayah following this boundary).
    private func scrollTargetAyahID(
        forDivider model: BoundaryDividerModel,
        boundaryModel: SurahBoundaryModel,
        ayahsForQiraah: [Ayah]
    ) -> Int? {
        if let start = boundaryModel.startDivider, boundaryDividerEquals(start, model) {
            return ayahsForQiraah.first?.id
        }
        for ayah in ayahsForQiraah {
            if let d = boundaryModel.dividerBeforeAyah[ayah.id], boundaryDividerEquals(d, model) {
                return ayah.id
            }
        }
        if let end = boundaryModel.endOfSurahDivider, boundaryDividerEquals(end, model) {
            return ayahsForQiraah.last?.id
        }
        if let end = boundaryModel.endDivider, boundaryDividerEquals(end, model) {
            return ayahsForQiraah.last?.id
        }
        return nil
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

    private func parseAyahNumberQuery(from raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowered = trimmed.lowercased()
        let prefixes = ["ayah ", "ayahs ", "aayah ", "aayahs ", "verse ", "verses "]
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            let valueText = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = Int(valueText) ?? arabicToEnglishNumber(valueText), n >= 1 {
                return n
            }
        }

        return nil
    }

    private func booleanAyahSearchGroups(from rawQuery: String) -> [[BooleanAyahTerm]]? {
        let normalized = rawQuery
            .replacingOccurrences(of: "&&", with: "&")
            .replacingOccurrences(of: "||", with: "|")

        guard normalized.contains("&") || normalized.contains("|") || normalized.contains("!") || normalized.contains("#") else {
            return nil
        }

        return normalized
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { part in
                part
                    .split(separator: "&", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap(booleanAyahSearchTerm(from:))
            }
            .filter { !$0.isEmpty }
    }

    private struct BooleanAyahTerm {
        let value: String
        let isNegated: Bool
        let requiresTashkeelMatch: Bool
        let tashkeelPattern: String
        let requiresExactEnglishMatch: Bool
        let exactEnglishPhrase: String
    }

    private static let arabicTashkeelCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{0610}"..."\u{061A}")
        set.insert(charactersIn: "\u{064B}"..."\u{065F}")
        set.insert(charactersIn: "\u{0670}"..."\u{0670}")
        set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
        return set
    }()

    private func arabicTashkeelBlob(_ text: String) -> String {
        String(text.unicodeScalars.filter { Self.arabicTashkeelCharacterSet.contains($0) })
    }

    private func exactPhraseBlob(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func booleanAyahSearchTerm(from rawTerm: String) -> BooleanAyahTerm? {
        var term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }

        var isNegated = false
        while term.hasPrefix("!") {
            isNegated.toggle()
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var requiresTashkeelMatch = false
        while term.hasPrefix("#") {
            requiresTashkeelMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !term.isEmpty else { return nil }
        let cleaned = settings.cleanSearch(term, whitespace: true)
        guard !cleaned.isEmpty else { return nil }

        return BooleanAyahTerm(
            value: cleaned,
            isNegated: isNegated,
            requiresTashkeelMatch: requiresTashkeelMatch && term.containsArabicLetters,
            tashkeelPattern: arabicTashkeelBlob(term),
            requiresExactEnglishMatch: requiresTashkeelMatch && !term.containsArabicLetters,
            exactEnglishPhrase: exactPhraseBlob(term)
        )
    }

    private func matchesBooleanAyahSearch(ayah: Ayah, haystack: String, groups: [[BooleanAyahTerm]]) -> Bool {
        groups.contains { andTerms in
            andTerms.allSatisfy { term in
                let containsTerm: Bool
                if term.requiresTashkeelMatch {
                    let lettersMatch = haystack.contains(term.value)
                    let tashkeelHaystack = arabicTashkeelBlob(ayah.textArabic(for: settings.displayQiraahForArabic))
                    let tashkeelMatch = term.tashkeelPattern.isEmpty || tashkeelHaystack.contains(term.tashkeelPattern)
                    containsTerm = lettersMatch && tashkeelMatch
                } else if term.requiresExactEnglishMatch {
                    let englishExactHaystack = exactPhraseBlob([
                        ayah.textTransliteration,
                        ayah.textEnglishSaheeh,
                        ayah.textEnglishMustafa
                    ].joined(separator: " "))
                    containsTerm = !term.exactEnglishPhrase.isEmpty && englishExactHaystack.contains(term.exactEnglishPhrase)
                } else {
                    containsTerm = haystack.contains(term.value)
                }
                return term.isNegated ? !containsTerm : containsTerm
            }
        }
    }

    private func rebuildQiraahCaches() {
        let key = settings.displayQiraahForArabic ?? ""
        if qiraahCacheSurahID == surah.id, key == cacheQiraahKey, !cachedAyahsForQiraah.isEmpty {
            return
        }

        let ayahs = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
        cachedAyahsForQiraah = ayahs
        cachedAyahByID = Dictionary(uniqueKeysWithValues: ayahs.map { ($0.id, $0) })
        let displayQiraah = settings.displayQiraahForArabic

        var overlayMap: [Int: BoundaryDividerModel] = [:]
        var searchBlobMap: [Int: String] = [:]
        overlayMap.reserveCapacity(ayahs.count)
        searchBlobMap.reserveCapacity(ayahs.count)

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

            let searchBlob = [
                ayah.textArabic(for: displayQiraah),
                ayah.textCleanArabic(for: displayQiraah),
                ayah.textTransliteration,
                ayah.textEnglishSaheeh,
                ayah.textEnglishMustafa,
                String(ayah.id),
                ayah.idArabic
            ]
            .map { settings.cleanSearch($0) }
            .joined(separator: " ")
            searchBlobMap[ayah.id] = searchBlob
        }

        overlayDividerByAyahID = overlayMap
        cachedSearchBlobByAyahID = searchBlobMap
        cacheQiraahKey = key
        qiraahCacheSurahID = surah.id

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
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let pageColor: Color = {
            if isOverlay { return accent }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let juzColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary: return .secondary
            case .allAccent: return accent
            }
        }()
        let separatorColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()

        let dividerContent = HStack(spacing: isOverlay ? 8 : 10) {
            #if os(iOS)
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(maxHeight: 1)
                }
            }
            #else
            Spacer()
            #endif

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

            #if os(iOS)
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(maxHeight: 1)
                }
            }
            #else
            Spacer()
            #endif
        }
        .padding(.vertical, isOverlay ? 4 : 6)
        .padding(.horizontal, isOverlay ? 10 : 0)
        .frame(maxWidth: isOverlay ? .infinity : nil)
        .contentShape(Rectangle())
        
        #if os(iOS)
        if !searchText.isEmpty, let ayahID = nextAyahID {
            return AnyView(
                dividerContent
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.hapticFeedback()
                        scrollDown = ayahID
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.45)
                            .onEnded { _ in
                                settings.hapticFeedback()
                                dividerInfo = boundaryDividerInfo(for: model)
                            }
                    )
            )
        }
        #endif
        
        return AnyView(
            dividerContent
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.45)
                        .onEnded { _ in
                            settings.hapticFeedback()
                            dividerInfo = boundaryDividerInfo(for: model)
                        }
                )
        )
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ayahListScreen(proxy: proxy)
        }
        .environmentObject(quranPlayer)
        .onDisappear(perform: saveLastRead)
        .onChange(of: scenePhase) { _ in saveLastRead() }
        #if os(iOS)
        //.navigationTitle(surah.nameEnglish)
        .toolbar {
            ToolbarItem(placement: .principal) {
                surahTitlePickerButton
            }

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
            .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: 1,
                initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                    startAyah: 1,
                    surah: surah,
                    displayQiraah: settings.displayQiraahForArabic
                ),
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
        .sheet(isPresented: $showReciterPickerSheet) {
            NavigationView {
                ReciterListView(dismissAfterSelectingReciter: true, autoScrollToInitialSelection: false)
                    .environmentObject(settings)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                settings.hapticFeedback()
                                showReciterPickerSheet = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .tint(settings.accentColor.color)
                        }
                    }
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        .confirmationDialog(
            dividerInfo?.title ?? "Boundary",
            isPresented: Binding(
                get: { dividerInfo != nil },
                set: { if !$0 { dividerInfo = nil } }
            ),
            presenting: dividerInfo
        ) { _ in
            Button("OK") {
                dividerInfo = nil
            }
        } message: { info in
            Text(info.message)
        }
        .confirmationDialog(
            surahInfoDialog?.title ?? "Surah Info",
            isPresented: Binding(
                get: { surahInfoDialog != nil },
                set: { if !$0 { surahInfoDialog = nil } }
            ),
            presenting: surahInfoDialog
        ) { _ in
            Button("OK") {
                surahInfoDialog = nil
            }
        } message: { info in
            Text(info.message)
        }
        .onChange(of: quranPlayer.showInternetAlert) { if $0 { showAlert = true; quranPlayer.showInternetAlert = false } }
        .confirmationDialog(quranPlayer.playbackAlertTitle, isPresented: $showAlert, titleVisibility: .visible) {
            Button("OK") { }
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
        let booleanGroups = booleanAyahSearchGroups(from: searchText)
        let pageJuzQuery = parsePageJuzQuery(from: searchText)
        let ayahNumberQuery = parseAyahNumberQuery(from: searchText)
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

            if let ayahNumberQuery {
                return a.id == ayahNumberQuery
            }

            if let blob = cachedSearchBlobByAyahID[a.id] {
                if let booleanGroups {
                    if booleanGroups.isEmpty { return false }
                    return matchesBooleanAyahSearch(ayah: a, haystack: blob, groups: booleanGroups)
                }
                return blob.contains(cleanQuery)
            }

            let fallbackBlob = [
                settings.cleanSearch(a.textArabic),
                settings.cleanSearch(a.textCleanArabic),
                settings.cleanSearch(a.textTransliteration),
                settings.cleanSearch(a.textEnglishSaheeh),
                settings.cleanSearch(a.textEnglishMustafa),
                settings.cleanSearch(String(a.id)),
                settings.cleanSearch(a.idArabic)
            ]
            .joined(separator: " ")

            if let booleanGroups {
                if booleanGroups.isEmpty { return false }
                return matchesBooleanAyahSearch(ayah: a, haystack: fallbackBlob, groups: booleanGroups)
            }

            return fallbackBlob.contains(cleanQuery)
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
        let trailingSearchBoundaryScrollTarget: Int? = {
            guard showBoundaryDividers, isPageOrJuzSearch, !isDividerKeywordSearch else { return nil }
            guard let boundaryModel else { return nil }
            guard let lastFilteredAyahID = filteredAyahs.last?.id else { return nil }

            if let idx = ayahsForQiraah.firstIndex(where: { $0.id == lastFilteredAyahID }) {
                let nextIndex = ayahsForQiraah.index(after: idx)
                if nextIndex < ayahsForQiraah.endIndex {
                    let nextAyah = ayahsForQiraah[nextIndex]
                    if boundaryModel.dividerBeforeAyah[nextAyah.id] != nil {
                        return nextAyah.id
                    }
                }
            }
            if boundaryModel.endDivider != nil {
                return ayahsForQiraah.last?.id
            }
            return nil
        }()
        let startOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, searchText.isEmpty else { return nil }
            return boundaryModel?.startDivider
        }()
        let endOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, searchText.isEmpty else { return nil }
            return boundaryModel?.endOfSurahDivider
        }()
        //let previousSurah = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? neighboringSurah(before: surah.id) : nil
        let nextSurah = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? neighboringSurah(after: surah.id)
            : nil
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

        return
            List {
                Section {
                    SurahRow(surah: surah, hideInfo: true).equatable()
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.45) {
                            settings.hapticFeedback()
                            surahInfoDialog = surahInfoDialog(for: surah)
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
                                .conditionalGlassEffect()
                                .padding(.vertical, -16)
                                .opacity(searchText.isEmpty ? 0 : 1)
                        }
                    }
                    .animation(.easeInOut, value: searchText)
                    .transition(.opacity)
                }
                
                /*if let previousSurah {
                    Section {
                        surahNavigationButton(title: "Go to Previous Surah", surah: previousSurah, systemImage: "chevron.up")
                    }
                }*/
                 
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
                        } else {
                            HeaderRow(
                                arabicText: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِِ",
                                englishTransliteration: "Bismi Allahi alrrahmani alrraheemi",
                                englishTranslation: "In the name of Allah, the Compassionate, the Merciful."
                            )
                        }
                    }
                }

                if isDividerKeywordSearch {
                    ForEach(Array(keywordDividerModels.enumerated()), id: \.offset) { _, dividerModel in
                        Section {
                            if let bm = boundaryModel {
                                listBoundaryDivider(
                                    model: dividerModel,
                                    nextAyahID: scrollTargetAyahID(
                                        forDivider: dividerModel,
                                        boundaryModel: bm,
                                        ayahsForQiraah: ayahsForQiraah
                                    )
                                )
                            } else {
                                listBoundaryDivider(model: dividerModel, nextAyahID: nil)
                            }
                        }
                    }
                } else {
                    if let startOfSurahDivider {
                        Section {
                            listBoundaryDivider(model: startOfSurahDivider, nextAyahID: ayahsForQiraah.first?.id)
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
                    }

                    ForEach(filteredAyahs, id: \.id) { ayah in
                        let dividerBefore = showBoundaryDividers ? boundaryModel?.dividerBeforeAyah[ayah.id] : nil

                        if let dividerBefore {
                            Section {
                                listBoundaryDivider(model: dividerBefore, nextAyahID: ayah.id)
                            }
                            .onAppear {
                                visibleBoundaryAyahIDs.insert(ayah.id)
                                syncVisibleAyahAnchor()
                            }
                            .onDisappear {
                                visibleBoundaryAyahIDs.remove(ayah.id)
                                syncVisibleAyahAnchor()
                            }
                        }

                        Group {
                            #if os(iOS)
                            Section {
                                AyahRow(
                                    surah: surah,
                                    ayah: ayah,
                                    scrollDown: $scrollDown,
                                    searchText: $searchText
                                )
                                .equatable()
                            }
                            #else
                            AyahRow(
                                surah: surah,
                                ayah: ayah,
                                scrollDown: $scrollDown,
                                searchText: $searchText
                            )
                            .equatable()
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
                        #if os(watchOS)
                        .padding(.vertical)
                        #endif
                    }

                    if let endOfSurahDivider {
                        Section {
                            listBoundaryDivider(model: endOfSurahDivider, nextAyahID: nil)
                        }
                    }

                    if let nextSurah {
                        Section {
                            surahNavigationButton(title: "Go to Next Surah", surah: nextSurah, systemImage: "chevron.down")
                        }
                    }

                    if let trailingSearchBoundaryDivider {
                        Section {
                            listBoundaryDivider(
                                model: trailingSearchBoundaryDivider,
                                nextAyahID: trailingSearchBoundaryScrollTarget
                            )
                        }
                    }
                }
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .compactListSectionSpacing()
            #if os(iOS)
            .onChange(of: scrollDown) { value in
                guard let target = value else { return }
                if !searchText.isEmpty {
                    settings.hapticFeedback()
                    pendingScrollAfterSearchClear = target
                    withAnimation {
                        searchText = ""
                        self.endEditing()
                    }
                } else {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
                scrollDown = nil
            }
            .onChange(of: searchText) { newValue in
                guard newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let target = pendingScrollAfterSearchClear else { return }
                pendingScrollAfterSearchClear = nil
                DispatchQueue.main.async {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                }
            }
            #endif
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
                qiraahCacheSurahID = nil
                rebuildQiraahCaches()
                visibleAyahIDs.removeAll()
                visibleBoundaryAyahIDs.removeAll()
            }
            .onChange(of: surah.id) { _ in
                rebuildQiraahCaches()
                visibleAyahIDs.removeAll()
                visibleBoundaryAyahIDs.removeAll()
                didScrollDown = false
                let ayahs = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
                let byID = Dictionary(uniqueKeysWithValues: ayahs.map { ($0.id, $0) })
                if let sel = ayah, byID[sel] != nil {
                    firstVisibleAyahID = sel
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation { proxy.scrollTo(sel, anchor: .top) }
                    }
                } else if let top = ayahs.first?.id {
                    firstVisibleAyahID = top
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo(top, anchor: .top) }
                    }
                }
            }
            #if os(iOS)
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    floatingHeaderOverlay(
                        floatingDividerModel: floatingDividerModel,
                        floatingDividerAnimationKey: floatingDividerAnimationKey
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                    qiraatAndTajweedControls
                    
                    if quranPlayer.isPlaying || quranPlayer.isPaused {
                        nowPlayingInset(proxy: proxy).padding(.horizontal, 24)
                            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
                    }
                }
                .padding(.bottom, 8)
            }
            .adaptiveSafeArea(edge: .bottom) {
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

            if let floatingDividerModel {
                boundaryDivider(model: floatingDividerModel, isOverlay: true)
                    .id(boundaryDividerID(floatingDividerModel))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
                    .conditionalGlassEffect()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(.easeInOut(duration: 0.18), value: floatingDividerAnimationKey)
            }
        }
        .padding(.top, {
            if #available(iOS 26, *) { 0 } else { 4 }
        }())
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .background(Color.clear)
        .opacity(showFloatingHeader ? 1 : 0)
        .padding(.horizontal, 50)
        .zIndex(1)
        .offset(y: showFloatingHeader ? 0 : -80)
        .opacity(showFloatingHeader ? 1 : 0)
    }

    #if os(iOS)
    private func bottomInsetContent(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            playbackAndSearchControls(proxy: proxy)
        }
    }

    @ViewBuilder
    private var qiraatAndTajweedControls: some View {
        let tajweedCanRenderNow = settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
            && !settings.beginnerMode
            && !settings.cleanArabicText

        if settings.qiraatComparisonMode || tajweedCanRenderNow {
            HStack(alignment: .bottom, spacing: 8) {
                if tajweedCanRenderNow {
                    TajweedLegendMenu()
                }

                Spacer()

                if settings.qiraatComparisonMode {
                    ArabicTextRiwayahPicker(selection: $settings.displayQiraah.animation(.easeInOut))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func playbackAndSearchControls(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            HStack(spacing: 0) {
                SearchBar(
                    text: $searchText.animation(.easeInOut),
                    onFocusChanged: { focused in
                        withAnimation {
                            isAyahSearchFocused = focused
                        }
                    }
                )

                playButton(proxy: proxy)
                    .frame(width: 27, height: 27)
                    .padding()
                    .conditionalGlassEffect()
                    .padding(.bottom, 2)
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
    
    #if os(iOS)
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

                Button {
                    settings.hapticFeedback()
                    showReciterPickerSheet = true
                } label: {
                    Label("Choose Reciter", systemImage: "headphones")
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
                        Label("Play Random Ayah", systemImage: "shuffle.circle")
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
        settings.setSelectedReciter(randomReciter)
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
            Text("\(surah.id) - \(surah.nameTransliteration)")
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)
                .contentShape(Rectangle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .conditionalGlassEffect()
        }
    }

    private var navBarTitle: some View {
        Button {
            settings.hapticFeedback()
            showingSettingsSheet = true
        } label: {
            Image(systemName: "gear")
            
            /*VStack(alignment: .trailing) {
                Text("\(surah.nameArabic) - \(surah.idArabic)")
                Text("\(surah.nameTransliteration) - \(surah.id)")
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
            .padding(6)*/
        }
    }

    @ViewBuilder
    private var selectedSurahNavigationDestination: some View {
        if let targetID = selectedSurahNavigation,
           let targetSurah = quranData.surah(targetID) {
            AyahsView(surah: targetSurah)
                .id("ayahs-selected-\(targetSurah.id)")
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

    private func neighboringSurah(before currentSurahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == currentSurahID }), index > 0 else { return nil }
        return quranData.quran[index - 1]
    }

    private func neighboringSurah(after currentSurahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == currentSurahID }), index + 1 < quranData.quran.count else { return nil }
        return quranData.quran[index + 1]
    }

    private func navigateToSurah(_ targetSurah: Surah) {
        guard targetSurah.id != surah.id else { return }
        settings.hapticFeedback()
        selectedSurahNavigation = targetSurah.id
    }

    @ViewBuilder
    private func surahNavigationButton(title: String, surah targetSurah: Surah, systemImage: String) -> some View {
        Button {
            navigateToSurah(targetSurah)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 22)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(targetSurah.id) - \(targetSurah.nameTransliteration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .contentShape(Rectangle())
        }
    }
}

struct RotatingGearView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "gear")
            #if os(iOS)
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

#if os(iOS)
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

    private func adjacentSurah(before surahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == surahID }), index > 0 else { return nil }
        return quranData.quran[index - 1]
    }

    private func adjacentSurah(after surahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == surahID }), index + 1 < quranData.quran.count else { return nil }
        return quranData.quran[index + 1]
    }

    private func select(_ surah: Surah) {
        onSelect(surah)
        dismiss()
    }

    private func scrollToCurrentSurah(_ proxy: ScrollViewProxy) {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard filteredSurahs.contains(where: { $0.id == currentSurahID }) else { return }

        let requestScroll = {
            withAnimation(.easeInOut) {
                proxy.scrollTo(currentSurahID, anchor: .center)
            }
        }

        DispatchQueue.main.async {
            requestScroll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                requestScroll()
            }
        }
    }

    private var ayahHighlightBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return -11
        }
        return -2
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    ForEach(filteredSurahs, id: \.id) { surah in
                        Section {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        surah.id == currentSurahID
                                        ? settings.accentColor.color.opacity(0.15)
                                        : .clear
                                    )
                                    .padding(.horizontal, -12)
                                    .padding(.vertical, ayahHighlightBackgroundVerticalPadding)
                                
                                Button {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        select(surah)
                                    }
                                } label: {
                                    SurahRow(surah: surah, isFavorite: settings.favoriteSurahs.contains(surah.id), hideInfo: true).equatable()
                                        .contentShape(Rectangle())
                                }
                                .id(surah.id)
                            }
                        }
                    }
                }
                .applyConditionalListStyle(defaultView: true)
                .compactListSectionSpacing()
                .searchable(text: $searchText.animation(.easeInOut), prompt: "Search surah")
                .navigationTitle("Choose Surah")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            settings.hapticFeedback()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .tint(settings.accentColor.color)
                    }
                }
                .onAppear {
                    scrollToCurrentSurah(proxy)
                }
                .onChange(of: searchText) { _ in
                    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    scrollToCurrentSurah(proxy)
                }
                .onChange(of: filteredSurahs.count) { _ in scrollToCurrentSurah(proxy) }
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

    private static let options: [(label: String, tag: String)] = Settings.Riwayah.menuOptions

    private var currentLabel: String {
        let tag = Settings.normalizeLegacyRiwayahTag(selection)
        return Self.options.first(where: { $0.tag == tag })?.label ?? "Arabic Riwayah"
    }

    var body: some View {
        #if os(iOS)
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
                        withAnimation {
                            selection = option.tag
                        }
                    } label: {
                        HStack {
                            if option.tag == Settings.normalizeLegacyRiwayahTag(selection) {
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
        #else
        Picker("Arabic Riwayah", selection: $selection) {
            ForEach(Self.options, id: \.tag) { option in
                Text(option.label).tag(option.tag)
            }
        }
        #endif
    }
}

#if os(iOS)
private struct TajweedLegendMenu: View {
    @EnvironmentObject private var settings: Settings

    @State private var showingSheet = false

    var expandsToFillRow: Bool = false

    var body: some View {
        Button {
            settings.hapticFeedback()
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach([Color.red, .orange, .yellow, .green, .blue], id: \.self) { item in
                        Circle()
                            .fill(item)
                            .frame(width: 5, height: 5)
                    }
                }

                Text("Legend")
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
            .conditionalGlassEffect()
        }
        .sheet(isPresented: $showingSheet) {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    TajweedLegendView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            } else {
                NavigationView {
                    TajweedLegendView()
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
