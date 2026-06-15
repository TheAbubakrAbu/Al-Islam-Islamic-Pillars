#if os(iOS)
import SwiftUI

struct PlayCustomRangeSheet: View {
    @EnvironmentObject var settings: Settings

    enum SelectionMode: String, CaseIterable {
        case ayahs, pages
        var title: String { self == .ayahs ? "Ayahs" : "Pages" }
    }

    let surah: Surah
    let initialStartAyah: Int
    let initialEndAyah: Int
    let onPlay: (Int, Int, Int, Int) -> Void
    let onCancel: () -> Void

    @AppStorage("customRangeSelectionMode") private var selectionMode: SelectionMode = .ayahs
    @State private var startAyah: Int
    @State private var endAyah: Int
    @State private var startAyahText: String
    @State private var endAyahText: String
    @State private var repeatPerAyah: Int
    @State private var repeatSection: Int
    @State private var repeatPerAyahText: String
    @State private var repeatSectionText: String
    @AppStorage("customRangeRepeatPerAyah") private var storedRepeatPerAyah = 1
    @AppStorage("customRangeRepeatSection") private var storedRepeatSection = 1
    
    @FocusState private var startAyahFocused: Bool
    @FocusState private var endAyahFocused: Bool
    @FocusState private var repeatPerAyahFocused: Bool
    @FocusState private var repeatSectionFocused: Bool

    private static let repeatMin = 1
    private static let repeatMax = 20
    private static let repeatOptions = [1, 2, 3, 5, 10, 15, 20]
    private static let repeatPerAyahStorageKey = "customRangeRepeatPerAyah"
    private static let repeatSectionStorageKey = "customRangeRepeatSection"

    /// End ayah defaults to the ayah after `startAyah` (one-ayah range when possible); if `startAyah` is the last ayah, end matches start.
    static func defaultEndAyah(startAyah: Int, surah: Surah, displayQiraah: String?) -> Int {
        let maxA = surah.numberOfAyahs(for: displayQiraah)
        return min(max(startAyah + 1, 1), maxA)
    }

    private static func storedRepeatValue(for key: String) -> Int {
        let saved = UserDefaults.standard.object(forKey: key) as? Int ?? repeatMin
        return min(Swift.max(repeatMin, saved), repeatMax)
    }

    private var maxAyah: Int { surah.numberOfAyahs(for: settings.displayQiraahForArabic) }

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
        let savedRepeatPerAyah = Self.storedRepeatValue(for: Self.repeatPerAyahStorageKey)
        let savedRepeatSection = Self.storedRepeatValue(for: Self.repeatSectionStorageKey)
        _repeatPerAyah = State(initialValue: savedRepeatPerAyah)
        _repeatSection = State(initialValue: savedRepeatSection)
        _repeatPerAyahText = State(initialValue: "\(savedRepeatPerAyah)")
        _repeatSectionText = State(initialValue: "\(savedRepeatSection)")
    }

    private var canPlay: Bool {
        startAyah >= 1 && endAyah <= maxAyah && startAyah <= endAyah
    }

    private func clampRangeToMaxAyah() {
        let m = maxAyah
        if endAyah > m { endAyah = m; endAyahText = "\(m)" }
        if startAyah > m { startAyah = m; startAyahText = "\(m)" }
        if startAyah < 1 { startAyah = 1; startAyahText = "1" }
        if endAyah < 1 { endAyah = 1; endAyahText = "1" }
        if startAyah > endAyah { endAyah = startAyah; endAyahText = "\(startAyah)" }
    }

    private var ayahCount: Int {
        max(0, endAyah - startAyah + 1)
    }

    /// "Ayah N" plus the mushaf page it falls on (when page data is available).
    private func ayahPageLabel(_ ayahID: Int) -> String {
        if hasPageData, let page = pageNumber(forAyah: ayahID) {
            return "Ayah \(ayahID) · Page \(page)"
        }
        return "Ayah \(ayahID)"
    }

    /// Mushaf pages within this surah (clamped to the active qiraah), each mapped to its first/last ayah. Ordered by page number.
    private var pageGroups: [(page: Int, firstAyah: Int, lastAyah: Int)] {
        var bounds: [Int: (first: Int, last: Int)] = [:]
        var order: [Int] = []
        for ayah in surah.ayahs where ayah.id <= maxAyah {
            guard let page = ayah.page else { continue }
            if let existing = bounds[page] {
                bounds[page] = (first: Swift.min(existing.first, ayah.id), last: Swift.max(existing.last, ayah.id))
            } else {
                bounds[page] = (first: ayah.id, last: ayah.id)
                order.append(page)
            }
        }
        return order.sorted().map { (page: $0, firstAyah: bounds[$0]!.first, lastAyah: bounds[$0]!.last) }
    }

    /// True when we have any page data for this surah (drives whether the Ayahs/Pages toggle is shown).
    private var hasPageData: Bool { !pageGroups.isEmpty }

    /// True when this surah spans more than one mushaf page (drives the page-snap helpers in Ayahs mode).
    private var hasMultiplePages: Bool { pageGroups.count > 1 }

    /// Index into `pageGroups` of the page containing the given ayah (falls back to the nearest preceding page).
    private func pageIndex(containing ayah: Int) -> Int? {
        let groups = pageGroups
        if let idx = groups.firstIndex(where: { ayah >= $0.firstAyah && ayah <= $0.lastAyah }) {
            return idx
        }
        return groups.lastIndex(where: { $0.firstAyah <= ayah }) ?? (groups.isEmpty ? nil : 0)
    }

    private var fromPageIndex: Int { pageIndex(containing: startAyah) ?? 0 }
    private var toPageIndex: Int { pageIndex(containing: endAyah) ?? fromPageIndex }

    /// Mushaf page number that the given ayah falls on, if known.
    private func pageNumber(forAyah ayah: Int) -> Int? {
        guard let idx = pageIndex(containing: ayah) else { return nil }
        return pageGroups[idx].page
    }

    /// True when the start ayah is already the first ayah of its page (so "Start of page" would be a no-op).
    private var startAtPageStart: Bool {
        guard let idx = pageIndex(containing: startAyah) else { return true }
        return startAyah <= pageGroups[idx].firstAyah
    }

    /// True when the end ayah is already the last ayah of its page (so "End of page" would be a no-op).
    private var endAtPageEnd: Bool {
        guard let idx = pageIndex(containing: endAyah) else { return true }
        return endAyah >= pageGroups[idx].lastAyah
    }

    /// Sets the start of the range to the first ayah of `pageGroups[index]` (clamped so start never passes the end page).
    private func setFromPage(to index: Int) {
        let groups = pageGroups
        let clamped = min(Swift.max(0, index), toPageIndex)
        guard groups.indices.contains(clamped) else { return }
        let a = groups[clamped].firstAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            startAyah = a
            startAyahText = "\(a)"
        }
    }

    /// Sets the end of the range to the last ayah of `pageGroups[index]` (clamped so end never passes the start page).
    private func setToPage(to index: Int) {
        let groups = pageGroups
        let clamped = min(Swift.max(fromPageIndex, index), groups.count - 1)
        guard groups.indices.contains(clamped) else { return }
        let a = groups[clamped].lastAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            endAyah = a
            endAyahText = "\(a)"
        }
    }

    /// Expands the current ayah range out to whole-page boundaries — used when switching into Pages mode.
    private func snapRangeToPages() {
        let groups = pageGroups
        guard !groups.isEmpty else { return }
        let lo = min(fromPageIndex, toPageIndex)
        let hi = Swift.max(fromPageIndex, toPageIndex)
        let a = groups[lo].firstAyah
        let b = groups[hi].lastAyah
        startAyah = a; startAyahText = "\(a)"
        endAyah = b; endAyahText = "\(b)"
    }

    /// In Ayahs mode: move the start back to the first ayah of its page.
    private func snapStartToPageStart() {
        guard let idx = pageIndex(containing: startAyah) else { return }
        commitBothAyahFields()
        let a = pageGroups[idx].firstAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            startAyah = a
            startAyahText = "\(a)"
            if endAyah < a { endAyah = a; endAyahText = "\(a)" }
        }
    }

    /// In Ayahs mode: extend the end out to the last ayah of its page.
    private func snapEndToPageEnd() {
        guard let idx = pageIndex(containing: endAyah) else { return }
        commitBothAyahFields()
        let a = pageGroups[idx].lastAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            endAyah = a
            endAyahText = "\(a)"
        }
    }

    private var availableAyahReciters: [Reciter] {
        reciters.filter { $0.qiraah == nil && !$0.ayahIdentifier.isEmpty }
    }

    private var selectedRangeReciter: Reciter? {
        settings.resolvedSelectedReciterIgnoringRandom() ?? availableAyahReciters.first
    }

    private var selectedRangeReciterName: String {
        selectedRangeReciter?.displayNameWithEnglishQiraah ?? settings.reciter
    }

    /// Two-line summary shown in both Ayahs and Pages modes:
    ///   line 1 — the current selection ("X ayahs · Y pages in range")
    ///   line 2 — the whole-surah totals ("M ayahs · N pages in Surah")
    private var rangeSummary: some View {
        let pagesInRange = Swift.max(1, toPageIndex - fromPageIndex + 1)
        return VStack(alignment: .center, spacing: 2) {
            rangeSummaryRow(
                hasPageData
                    ? "\(ayahCount) ayah\(ayahCount == 1 ? "" : "s") · \(pagesInRange) page\(pagesInRange == 1 ? "" : "s") in range"
                    : "\(ayahCount) ayah\(ayahCount == 1 ? "" : "s") in range"
            )
            rangeSummaryRow(
                hasPageData
                    ? "\(maxAyah) ayah\(maxAyah == 1 ? "" : "s") · \(pageGroups.count) page\(pageGroups.count == 1 ? "" : "s") in Surah"
                    : "\(maxAyah) ayah\(maxAyah == 1 ? "" : "s") in Surah"
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func rangeSummaryRow(_ text: String) -> some View {
        let label = Text(text)
            .font(.caption.monospaced())
            .foregroundColor(Color(.tertiaryLabel))

        if #available(iOS 16.0, watchOS 9.0, *) {
            label.contentTransition(.numericText())
        } else {
            label
        }
    }

    private func sanitizedNumberText(from value: String) -> String {
        value.filter(\.isNumber)
    }

    private func syncAyahTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)
        
        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }
        
        // While keyboard is active, allow any value (even empty or invalid)
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = parsed
            }
            return
        }
        
        // When keyboard is dismissed, validate and clamp
        guard !sanitized.isEmpty else {
            text.wrappedValue = "\(value.wrappedValue)"
            value.wrappedValue = 1
            return
        }
        
        let parsed = Int(sanitized) ?? 1
        let clamped = min(Swift.max(1, parsed), maxAyah)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    private func syncRepeatTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        // While keyboard is active, allow any value (even empty or invalid)
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = parsed
            }
            return
        }
        
        // When keyboard is dismissed, validate and clamp
        guard !sanitized.isEmpty else {
            text.wrappedValue = "\(value.wrappedValue)"
            value.wrappedValue = Self.repeatMin
            return
        }

        let parsed = Int(sanitized) ?? Self.repeatMin
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    private func adjustAyahValue(_ value: Binding<Int>, text: Binding<String>, delta: Int, onChange: @escaping (Int) -> Void) {
        commitBothAyahFields()

        let newValue = min(Swift.max(1, value.wrappedValue + delta), maxAyah)
        withAnimation(.easeInOut(duration: 0.15)) {
            value.wrappedValue = newValue
            text.wrappedValue = "\(newValue)"
            onChange(newValue)
        }
    }

    private func adjustRepeatValue(_ value: Binding<Int>, text: Binding<String>, delta: Int) {
        commitRepeatInput(value: value, text: text)

        let newValue = min(Swift.max(Self.repeatMin, value.wrappedValue + delta), Self.repeatMax)
        withAnimation(.easeInOut(duration: 0.15)) {
            value.wrappedValue = newValue
            text.wrappedValue = "\(newValue)"
        }
        persistRepeatValues()
    }

    private func syncRepeatTextInput(value: Binding<Int>, text: Binding<String>) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        guard !sanitized.isEmpty else { return }

        let parsed = Int(sanitized) ?? value.wrappedValue
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)

        if parsed != clamped {
            text.wrappedValue = "\(clamped)"
        }

        if value.wrappedValue != clamped {
            withAnimation(.easeInOut(duration: 0.18)) {
                value.wrappedValue = clamped
            }
        }
    }

    private func clampStoredRepeatValues() {
        let perAyah = min(Swift.max(Self.repeatMin, storedRepeatPerAyah), Self.repeatMax)
        let section = min(Swift.max(Self.repeatMin, storedRepeatSection), Self.repeatMax)
        storedRepeatPerAyah = perAyah
        storedRepeatSection = section
        repeatPerAyah = perAyah
        repeatSection = section
        repeatPerAyahText = "\(perAyah)"
        repeatSectionText = "\(section)"
    }

    private func persistRepeatValues() {
        storedRepeatPerAyah = min(Swift.max(Self.repeatMin, repeatPerAyah), Self.repeatMax)
        storedRepeatSection = min(Swift.max(Self.repeatMin, repeatSection), Self.repeatMax)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    surahHeaderCard
                    reciterCard
                    rangeCard
                    arabicVersesCard
                    repeatsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        settings.hapticFeedback()
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .adaptiveSafeArea(edge: .bottom) {
                playButtonBar
            }
        }
        .onAppear {
            clampRangeToMaxAyah()
            clampStoredRepeatValues()
        }
        .onChange(of: settings.displayQiraahForArabic) { _ in clampRangeToMaxAyah() }
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
                
                Text("Surah \(surah.id) · \(maxAyah) ayahs\(hasPageData ? " · \(pageGroups.count) page\(pageGroups.count == 1 ? "" : "s")" : "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var reciterCard: some View {
        NavigationLink {
            ReciterListView()
                .environmentObject(settings)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Reciter")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(selectedRangeReciterName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if selectedRangeReciter?.defaultToMinshawi == true {
                        Text("Ayahs default to \(Reciter.minshawiAyahFallbackName).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectionMode == .pages && hasPageData {
                pageSelectionSection
            } else {
                ayahSelectionSection
            }

            rangeSummary

            if hasPageData {
                Picker("Selection mode", selection: $selectionMode.animation(.easeInOut)) {
                    ForEach(SelectionMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectionMode) { mode in
                    settings.hapticFeedback()
                    if mode == .pages { snapRangeToPages() }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .animation(.easeInOut, value: startAyah)
        .animation(.easeInOut, value: endAyah)
    }

    private var ayahSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ayah range", systemImage: "number")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(alignment: .center, spacing: 12) {
                rangeField(title: "From", value: $startAyah, text: $startAyahText, isFocused: $startAyahFocused) { new in
                    if new > endAyah {
                        startAyah = endAyah
                        startAyahText = "\(endAyah)"
                    }
                }

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))

                rangeField(title: "To", value: $endAyah, text: $endAyahText, isFocused: $endAyahFocused) { new in
                    if new < startAyah {
                        endAyah = startAyah
                        endAyahText = "\(startAyah)"
                    }
                }
            }
            .onChange(of: startAyah) { ayah in
                startAyahText = "\(ayah)"
            }
            .onChange(of: endAyah) { ayah in
                endAyahText = "\(endAyah)"
            }

            if hasPageData {
                HStack(spacing: 10) {
                    quickActionButton(title: "Start of page", systemImage: "arrow.up.to.line", enabled: hasMultiplePages && !startAtPageStart) {
                        snapStartToPageStart()
                    }

                    quickActionButton(title: "End of page", systemImage: "arrow.down.to.line", enabled: hasMultiplePages && !endAtPageEnd) {
                        snapEndToPageEnd()
                    }
                }

                perFieldPageLabels
            }

            HStack(spacing: 10) {
                quickActionButton(title: "Go to start", systemImage: "arrow.left.to.line") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        startAyah = 1
                        startAyahText = "1"
                    }
                }

                quickActionButton(title: "Go to end", systemImage: "arrow.right.to.line") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        endAyah = maxAyah
                        endAyahText = "\(maxAyah)"
                    }
                }
            }

            quickActionButton(title: "Whole surah (1–\(maxAyah))", systemImage: "doc.text.fill", prominent: true) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    startAyah = 1
                    endAyah = maxAyah
                    startAyahText = "1"
                    endAyahText = "\(maxAyah)"
                }
            }
        }
    }

    /// The mushaf page of the From / To ayah, centered directly under each big ayah field.
    private var perFieldPageLabels: some View {
        HStack(spacing: 12) {
            pageLabelColumn(forAyah: startAyah)

            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.medium))
                .hidden()

            pageLabelColumn(forAyah: endAyah)
        }
    }

    private func pageLabelColumn(forAyah ayah: Int) -> some View {
        Text(pageNumber(forAyah: ayah).map { "Page \($0)" } ?? " ")
            .font(.caption)
            .foregroundColor(Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var pageSelectionSection: some View {
        let groups = pageGroups
        let fromIdx = fromPageIndex
        let toIdx = toPageIndex

        VStack(alignment: .leading, spacing: 16) {
            Label("Page range", systemImage: "doc.text")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                pageField(
                    title: "From page",
                    pageNumber: groups.indices.contains(fromIdx) ? groups[fromIdx].page : nil,
                    canDecrement: fromIdx > 0,
                    canIncrement: fromIdx < toIdx,
                    onDecrement: { setFromPage(to: fromIdx - 1) },
                    onIncrement: { setFromPage(to: fromIdx + 1) }
                )

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))

                pageField(
                    title: "To page",
                    pageNumber: groups.indices.contains(toIdx) ? groups[toIdx].page : nil,
                    canDecrement: toIdx > fromIdx,
                    canIncrement: toIdx < groups.count - 1,
                    onDecrement: { setToPage(to: toIdx - 1) },
                    onIncrement: { setToPage(to: toIdx + 1) }
                )
            }

            HStack(spacing: 10) {
                quickActionButton(title: "First page", systemImage: "arrow.left.to.line", enabled: fromIdx > 0) {
                    setFromPage(to: 0)
                }

                quickActionButton(title: "Last page", systemImage: "arrow.right.to.line", enabled: toIdx < groups.count - 1) {
                    setToPage(to: groups.count - 1)
                }
            }

            quickActionButton(title: "All pages (\(groups.count))", systemImage: "doc.text.fill", prominent: true, enabled: !(fromIdx == 0 && toIdx == groups.count - 1)) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    startAyah = 1
                    endAyah = maxAyah
                    startAyahText = "1"
                    endAyahText = "\(maxAyah)"
                }
            }
        }
    }

    private func quickActionButton(title: String, systemImage: String, prominent: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        let tint = enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel)
        return Button {
            settings.hapticFeedback()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, prominent ? 12 : 10)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: prominent ? 16 : 14, style: .continuous))
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
    }

    private func pageField(title: String, pageNumber: Int?, canDecrement: Bool, canIncrement: Bool, onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 0) {
                Button {
                    settings.hapticFeedback()
                    onDecrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canDecrement ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .disabled(!canDecrement)

                Spacer()

                Text(pageNumber.map { "\($0)" } ?? "—")
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(minWidth: 44, alignment: .center)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    onIncrement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canIncrement ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .disabled(!canIncrement)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
    }

    private func rangeField(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 0) {
                Button {
                    settings.hapticFeedback()
                    adjustAyahValue(value, text: text, delta: -1, onChange: onChange)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue > 1 ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .disabled(value.wrappedValue <= 1)

                Spacer()
                
                TextField("", text: text)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 44, alignment: .center)
                    .focused(isFocused)
                    .onChange(of: text.wrappedValue) { _ in
                        syncAyahTextInput(value: value, text: text, isFocused: isFocused.wrappedValue)
                    }
                    .onChange(of: isFocused.wrappedValue) { newValue in
                        // When keyboard dismisses (newValue = false), validate both fields together
                        if !newValue {
                            commitBothAyahFields()
                        }
                    }
                    .onSubmit {
                        commitBothAyahFields()
                    }
                
                Spacer()
                
                Button {
                    settings.hapticFeedback()
                    adjustAyahValue(value, text: text, delta: 1, onChange: onChange)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue < maxAyah ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .disabled(value.wrappedValue >= maxAyah)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
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
        let s = Int(startAyahText.trimmingCharacters(in: .whitespaces)) ?? startAyah
        let e = Int(endAyahText.trimmingCharacters(in: .whitespaces)) ?? endAyah
        
        // Clamp to 1...maxAyah (handles negatives and out-of-range)
        let clampedStart = min(Swift.max(1, s), maxAyah)
        let clampedEnd = min(Swift.max(1, e), maxAyah)
        
        // Ensure start <= end (if not, swap to make valid range)
        let from = min(clampedStart, clampedEnd)
        let to = Swift.max(clampedStart, clampedEnd)
        
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

            repeatRow(title: "Each ayah", value: $repeatPerAyah, text: $repeatPerAyahText, isFocused: $repeatPerAyahFocused)
            repeatRow(title: "Whole section", value: $repeatSection, text: $repeatSectionText, isFocused: $repeatSectionFocused)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var arabicVersesCard: some View {
        Group {
            if let first = surah.ayahs.first(where: { $0.id == startAyah }),
               let last = surah.ayahs.first(where: { $0.id == endAyah }) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("First & last ayah", systemImage: "text.quote.rtl")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ayahPageLabel(startAyah))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        Text(first.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                            .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(nil)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if startAyah != endAyah {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ayahPageLabel(endAyah))
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Color(.tertiaryLabel))
                            
                            Text(last.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                                .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                                .multilineTextAlignment(.trailing)
                                .lineLimit(nil)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeInOut, value: startAyah)
                .animation(.easeInOut, value: endAyah)
            }
        }
    }

    private func repeatRow(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.repeatOptions, id: \.self) { n in
                            Button {
                                settings.hapticFeedback()
                                withAnimation {
                                    value.wrappedValue = n
                                    text.wrappedValue = "\(n)"
                                }
                            } label: {
                                Text("\(n)×")
                                    .font(.subheadline.weight(value.wrappedValue == n ? .semibold : .regular))
                                    .foregroundColor(value.wrappedValue == n ? .white : .primary)
                                    .padding(8)
                                    .background(
                                        value.wrappedValue == n
                                            ? settings.accentColor.color
                                            : Color(UIColor.tertiarySystemFill)
                                    )
                                    .clipShape(Capsule())
                                    .contentShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)

                repeatStepper(value: value, text: text, isFocused: isFocused)
            }
        }
        .onChange(of: value.wrappedValue) { newValue in
            text.wrappedValue = "\(newValue)"
            persistRepeatValues()
        }
    }

    private func repeatStepper(value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        HStack(spacing: 4) {
            Button {
                settings.hapticFeedback()
                adjustRepeatValue(value, text: text, delta: -1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.body)
                    .foregroundStyle(value.wrappedValue > Self.repeatMin ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
            }
            .disabled(value.wrappedValue <= Self.repeatMin)

            TextField("", text: text)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 32, alignment: .center)
                .focused(isFocused)
                .onChange(of: text.wrappedValue) { _ in
                    syncRepeatTextInput(value: value, text: text, isFocused: isFocused.wrappedValue)
                }
                .onChange(of: isFocused.wrappedValue) { newValue in
                    // When keyboard dismisses (newValue = false), validate
                    if !newValue {
                        commitAllRepeatFields()
                    }
                }
                .onSubmit { commitAllRepeatFields() }

            Button {
                settings.hapticFeedback()
                adjustRepeatValue(value, text: text, delta: 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                    .foregroundStyle(value.wrappedValue < Self.repeatMax ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
            }
            .disabled(value.wrappedValue >= Self.repeatMax)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private func commitRepeatInput(value: Binding<Int>, text: Binding<String>) {
        let parsed = Int(text.wrappedValue.trimmingCharacters(in: .whitespaces)) ?? value.wrappedValue
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
        persistRepeatValues()
    }

    private func commitAllRepeatFields() {
        commitRepeatInput(value: $repeatPerAyah, text: $repeatPerAyahText)
        commitRepeatInput(value: $repeatSection, text: $repeatSectionText)
    }

    private var playButtonBar: some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            Button {
                settings.hapticFeedback()
                commitBothAyahFields()
                commitAllRepeatFields()
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
                .conditionalGlassEffect(
                    useColor: 0.35,
                    customTint: canPlay ? settings.accentColor.color : .secondary
                )
                .contentShape(Rectangle())
            }
            .disabled(!canPlay)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        PlayCustomRangeSheet(
            surah: AlIslamPreviewData.surah,
            initialStartAyah: 1,
            initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                startAyah: 1,
                surah: AlIslamPreviewData.surah,
                displayQiraah: AlIslamPreviewData.settings.displayQiraahForArabic
            ),
            onPlay: { _, _, _, _ in },
            onCancel: {}
        )
    }
}
#endif
