import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsQuranView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEdits: Bool
    private let presentedAsSheet: Bool

    init(showEdits: Bool = false, presentedAsSheet: Bool = false) {
        _showEdits = State(initialValue: showEdits)
        self.presentedAsSheet = presentedAsSheet
    }

    private var includeEnglish: Binding<Bool> {
        Binding(
            get: {
                settings.isHafsDisplay && (settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa)
            },
            set: { newValue in
                // If not on Hafs, English settings don't apply (toggle is disabled in UI).
                guard settings.isHafsDisplay else { return }
                withAnimation {
                    if newValue {
                        // Ensure at least one English option is enabled so this toggle can stay on.
                        if !(settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa) {
                            settings.showEnglishSaheeh = true
                        }
                    } else {
                        settings.showTransliteration = false
                        settings.showEnglishSaheeh = false
                        settings.showEnglishMustafa = false
                    }
                }
            }
        )
    }

    private var pageJuzDividers: Binding<Bool> {
        Binding(
            get: { settings.showPageJuzDividers },
            set: { newValue in
                withAnimation {
                    settings.showPageJuzDividers = newValue
                    if newValue {
                        settings.showPageJuzOverlay = true
                    }
                }
            }
        )
    }
    
    var body: some View {
        List {
            recitationSection
            displaySection
            arabicTextSection
            englishTextSection
            qiraahSection
            favoritesAndBookmarksSection
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Al-Quran Settings")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if presentedAsSheet {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(settings.accentColor.color)
                }
            }
        }
        #endif
    }

    private var recitationSection: some View {
        Section(header: Text("RECITATION")) {
            reciterSelection
            recitationEndingPicker
            recitationCaption
        }
    }

    private var reciterSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(destination: ReciterListView().environmentObject(settings)) {
                Label("Choose Reciter", systemImage: "headphones")
            }

            Text(settings.resolvedSelectedReciterIgnoringRandom()?.displayNameWithEnglishQiraah ?? settings.reciter)
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(settings.accentColor.color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recitationEndingPicker: some View {
        Picker("After Surah Recitation Ends", selection: $settings.reciteType.animation(.easeInOut)) {
            Text("Go to Next").tag("Continue to Next")
            Text("Go to Previous").tag("Continue to Previous")
            Text("End Recitation").tag("End Recitation")
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var recitationCaption: some View {
        #if os(iOS)
        Text("The Quran recitations are streamed online by default. You can open Choose Reciter to download full surahs per reciter for offline playback and reduced data use.")
            .font(.caption)
            .foregroundColor(.secondary)
        #endif
    }

    private var displaySection: some View {
        Section(header: Text("DISPLAY")) {
            pageAndJuzDividersGroup
            
            VStack(alignment: .leading) {
                Toggle("Show Full Surah Details", isOn: $settings.showFullSurahRow.animation(.easeInOut))
                    .font(.subheadline)
                
                Text("Shows each surah's extra information, such as revelation type, ayah count, page count, etc.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
            
            systemFontSizeToggle
        }
    }

    private var pageAndJuzDividersGroup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Show Page and Juz Dividers", isOn: pageJuzDividers.animation(.easeInOut))
                .font(.subheadline)
            
            if settings.showPageJuzDividers {
                Toggle("Show Floating Overlay", isOn: $settings.showPageJuzOverlay.animation(.easeInOut))
                    .font(.subheadline)
            }
        }
    }

    private var systemFontSizeToggle: some View {
        Toggle("Use System Font Size", isOn: useSystemFontSizes.animation(.easeInOut))
            .font(.subheadline)
    }

    private var useSystemFontSizes: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                var usesSystemSizes = true

                if settings.showArabicText {
                    usesSystemSizes = usesSystemSizes && (settings.fontArabicSize == systemBodySize + 10)
                }

                if settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa {
                    usesSystemSizes = usesSystemSizes && (settings.englishFontSize == systemBodySize)
                }
                return usesSystemSizes
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    if newValue {
                        settings.fontArabicSize = systemBodySize + 10
                        settings.englishFontSize = systemBodySize
                    } else {
                        settings.fontArabicSize = systemBodySize + 11
                        settings.englishFontSize = systemBodySize + 1
                    }
                }
            }
        )
    }

    private var arabicTextSection: some View {
        Section(header: Text("ARABIC TEXT")) {
            arabicVisibilityToggle
            tajweedSettingsGroup
            arabicDisplayControls
        }
    }

    private var arabicVisibilityToggle: some View {
        Toggle("Show Arabic Quran Text", isOn: $settings.showArabicText.animation(.easeInOut))
            .font(.subheadline)
            .disabled(!settings.showTransliteration && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
    }

    private var tajweedSettingsGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            let tajweedCanRenderNow = settings.showArabicText
                && settings.isHafsDisplay
                && !settings.beginnerMode
                && !settings.cleanArabicText
            let tajweedToggleBinding = Binding<Bool>(
                get: { settings.showTajweedColors && tajweedCanRenderNow },
                set: { settings.showTajweedColors = $0 }
            )
            
            Toggle("Show Tajweed Colors", isOn: tajweedToggleBinding.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!tajweedCanRenderNow)

            #if os(iOS)
            NavigationLink(destination: TajweedLegendView()) {
                Text("Customize Tajweed Colors")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }
            .disabled(!settings.showTajweedColors)
            #endif

            Text(settings.isHafsDisplay
                ? "Available for Hafs an Asim. If Clean Arabic or Beginner Mode is enabled, tajweed is temporarily inactive."
                : "Tajweed colors are currently available only for Hafs an Asim.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var arabicDisplayControls: some View {
        if settings.showArabicText {
            cleanArabicTextGroup
            arabicFontPicker
            arabicFontSizeControls
            beginnerModeGroup
        }
    }

    private var cleanArabicTextGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Remove Arabic Tashkeel (Vowel Diacritics) and Signs", isOn: $settings.cleanArabicText.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)

            #if os(iOS)
            Text("This option removes Tashkeel, which are vowel diacretic marks such as Fatha, Damma, Kasra, and others, while retaining essential vowels like Alif, Yaa, and Waw. It also adjusts \"Mad\" letters and the \"Hamzatul Wasl,\" and removes baby vowel letters, various textual annotations including stopping signs, chapter markers, and prayer indicators. This option is not recommended.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            #else
            Text("This option removes Tashkeel (vowel diacretics).")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            #endif
        }
    }

    private var arabicFontPicker: some View {
        Picker("Arabic Font", selection: $settings.fontArabic.animation(.easeInOut)) {
            Text("Uthmani").tag("KFGQPCQUMBULUthmanicScript-Regu")
            Text("Indopak").tag("Al_Mushaf")
        }
        #if os(iOS)
        .pickerStyle(SegmentedPickerStyle())
        #endif
        .disabled(!settings.showArabicText)
    }

    private var arabicFontSizeControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Stepper(value: $settings.fontArabicSize.animation(.easeInOut), in: 15...50, step: 1) {
                Text("Arabic Font Size: \(Int(settings.fontArabicSize))")
                    .font(.subheadline)
            }

            Slider(value: $settings.fontArabicSize.animation(.easeInOut), in: 15...50, step: 1)
        }
    }

    private var beginnerModeGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Arabic Beginner Mode", isOn: $settings.beginnerMode.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)

            Text("Puts a space between each Arabic letter to make it easier for beginners to read the Quran.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

    private var englishTextSection: some View {
        Section(header: Text("ENGLISH TEXT"), footer: settings.showQiraahDetails ? Text("Transliteration, translations, and all English text apply only to default Hafs an Asim. For other riwayat, only the Arabic text is shown.") : nil) {
            includeEnglishToggle
            englishDisplayToggles
            englishFontSizeControls
        }
    }

    private var includeEnglishToggle: some View {
        Toggle("Include English", isOn: includeEnglish.animation(.easeInOut))
            .font(.subheadline)
            .disabled(!settings.isHafsDisplay)
    }

    @ViewBuilder
    private var englishDisplayToggles: some View {
        if settings.isHafsDisplay && includeEnglish.wrappedValue {
            Toggle("Show Transliteration", isOn: $settings.showTransliteration.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)

            Toggle("Show English Translation\nSaheeh International", isOn: $settings.showEnglishSaheeh.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishMustafa)

            Toggle("Show English Translation\nClear Quran (Mustafa Khattab)", isOn: $settings.showEnglishMustafa.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishSaheeh)
        }
    }

    @ViewBuilder
    private var englishFontSizeControls: some View {
        if settings.isHafsDisplay && includeEnglish.wrappedValue && (settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa) {
            VStack(alignment: .leading, spacing: 16) {
                Stepper(value: $settings.englishFontSize.animation(.easeInOut), in: 13...20, step: 1) {
                    Text("English Font Size: \(Int(settings.englishFontSize))")
                        .font(.subheadline)
                }
                Slider(value: $settings.englishFontSize.animation(.easeInOut), in: 13...20, step: 1)
            }
        }
    }

    private var qiraahSection: some View {
        Section {
            if settings.showQiraahDetails {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.showQiraahDetails = false
                    }
                } label: {
                    HStack {
                        Text("Hide Riwayah / Qiraah")
                        Spacer()
                        Image(systemName: "chevron.up")
                    }
                    .foregroundColor(settings.accentColor.color)
                }
                                
                qiraahPicker
                qiraahExplanation
                qiraahLinks
                qiraahHighlight
                comparisonModeGroup
            } else {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.showQiraahDetails = true
                    }
                } label: {
                    HStack {
                        Text("Show Riwayah / Qiraah")
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(settings.accentColor.color)
                }
            }
        } header: {
            HStack(spacing: 6) {
                Text("RIWAYAH / QIRAAH")
                Text("- \(settings.displayQiraahArabicCaption)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Spacer(minLength: 0)
            }
        } footer: {
            if settings.showQiraahDetails {
                Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")
            }
        }
    }

    private var qiraahPicker: some View {
        ArabicTextRiwayahPicker(
            selection: $settings.displayQiraah.animation(.easeInOut),
            useSimpleIOSPicker: true
        )
        .font(.subheadline)
    }

    private var qiraahExplanation: some View {
        Text("""
        The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

        The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

        To learn more about the 7 Ahruf and the 10 Qiraat, see below and in \(AppIdentifiers.toolsView) View > Islamic Pillars and Basics.
        """)
            .font(.caption)
            .foregroundColor(.primary)
    }

    private var qiraahLinks: some View {
        Group {
            NavigationLink(destination: AhrufView()) {
                Text("The 7 Ahruf (Modes)")
            }
            .font(.caption)

            NavigationLink(destination: QiraatView()) {
                Text("The 10 Qiraat (Recitations)")
            }
            .font(.caption)
        }
    }

    private var qiraahHighlight: some View {
        Text("***Hafs an Asim* is the most common and widespread Qiraah in the world today.**")
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.top, 4)
    }

    private var comparisonModeGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Comparison mode", isOn: $settings.qiraatComparisonMode.animation(.easeInOut))
                .font(.subheadline)

            Text("When on, the ayah view shows a riwayah picker above the search bar so you can switch and compare qiraat in that screen.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var favoritesAndBookmarksSection: some View {
        #if os(iOS)
        if showEdits {
            Section(header: Text("FAVORITES AND BOOKMARKS")) {
                favoritesLink(title: "Edit Favorite Surahs", type: .surah)
                favoritesLink(title: "Edit Bookmarked Ayahs", type: .ayah)
                favoritesLink(title: "Edit Favorite Letters", type: .letter)
            }
        }
        #endif
    }

    #if os(iOS)
    private func favoritesLink(title: String, type: FavoriteType) -> some View {
        NavigationLink(destination: FavoritesView(type: type).environmentObject(quranData).accentColor(settings.accentColor.color)) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
        }
    }
    #endif
}

/// Section header for qiraat reciter groups: title and Arabic on one row (same idea as `JuzHeader`).
private struct QiraahReciterSectionHeader: View {
    let title: String
    let arabic: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            
            Text("- \(arabic)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
            Spacer(minLength: 0)
        }
    }
}

private struct MurattalSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

struct ReciterListView: View {
    /// When `true`, dismisses the sheet (or pops navigation) after the user picks a reciter or Random.
    var dismissAfterSelectingReciter = false
    /// When `false`, list opens at top without scrolling to favorites/selected reciter.
    var autoScrollToInitialSelection = true

    @EnvironmentObject var settings: Settings
    @Environment(\.presentationMode) private var presentationMode
    @State private var didAutoScrollToSelection = false
    @State private var searchText = ""
    @State private var pendingQiraahReciter: Reciter?
    @State private var pendingDisplayQiraahTag: String?
    @State private var pendingScrollToReciterID: String? = nil
    @AppStorage("splitMurattalRecitersByGroup") private var splitMurattalRecitersByGroup = false
    #if os(iOS)
    @StateObject private var downloadManager = ReciterDownloadManager.shared
    @State private var showDownloadedOnly = false
    #endif

    private struct MurattalReciterGroup: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let reciters: [Reciter]
    }

    private var qiraahChangeDialogTitle: String {
        pendingRequestedQiraahIsUnsupported ? "Qiraah Text Not Supported" : "Change Quran Text?"
    }

    private var qiraahChangeDialogMessage: String {
        if pendingRequestedQiraahIsUnsupported {
            let qiraahName = pendingQiraahReciter?.qiraah?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let qiraahName, !qiraahName.isEmpty {
                return "This reciter uses \(qiraahName). This qiraah text form is not supported right now. Keep your current Quran text and continue?"
            }
            return "This reciter's qiraah text form is not supported right now. Keep your current Quran text and continue?"
        }

        if pendingDisplayQiraahTag == nil {
            return "This reciter uses Hafs an Asim (default). Would you like to switch the Quran text to match it?"
        }

        guard let pendingQiraahReciter,
              let qiraah = pendingQiraahReciter.qiraah,
              !qiraah.isEmpty else {
            return "This reciter uses a different riwayah. Would you like to switch the Quran text to match it?"
        }

        return "This reciter uses \(qiraah). Would you like to switch the Quran text to match it?"
    }

    private func resolvedQiraahTag(for reciter: Reciter) -> String? {
        if let qiraah = reciter.qiraah, !qiraah.isEmpty {
            return qiraah
        }

        // Hafs reciters are represented by nil/empty qiraah in these primary sections.
        return nil
    }

    private func isSupportedQiraahForText(_ qiraahTag: String?) -> Bool {
        guard let qiraahTag, !qiraahTag.isEmpty else { return true }
        return Settings.Riwayah.menuOptions.contains(where: { $0.tag == qiraahTag })
    }

    private var pendingRequestedQiraahIsUnsupported: Bool {
        !isSupportedQiraahForText(pendingDisplayQiraahTag)
    }

    private struct ReciterSectionGroup: Identifiable {
        let id: String
        let title: String
        let arabic: String?
        let reciters: [Reciter]
        let isQiraah: Bool

        func withReciters(_ reciters: [Reciter]) -> ReciterSectionGroup {
            ReciterSectionGroup(id: id, title: title, arabic: arabic, reciters: reciters, isQiraah: isQiraah)
        }
    }

    private static let qiraahSearchKeywords = [
        "qiraah",
        "qiraat",
        "riwayah",
        "riwayaat",
        "recitation",
        "recitations"
    ]

    private static let hafsSearchKeywords = [
        "hafs",
        "asim",
        "aasim",
        "asim",
        "حفص",
        "عاصم"
    ]

    private func isSelectedReciter(_ reciter: Reciter) -> Bool {
        guard settings.reciter != Settings.randomReciterName else { return false }
        if !settings.reciterId.isEmpty {
            return settings.reciterId == reciter.id
        }
        return false
    }

    private var orderedUniqueReciters: [Reciter] {
        var seen = Set<String>()
        return allReciterSections
            .flatMap(\.reciters)
            .filter { seen.insert($0.id).inserted }
    }

    private var favoriteReciters: [Reciter] {
        orderedUniqueReciters.filter { settings.isReciterFavorite(reciterID: $0.id) }
    }

    /// Matches row `.id(...)` for `ScrollViewReader.scrollTo`.
    private var reciterListScrollTargetID: String {
        if let firstFavorite = favoriteReciters.first {
            return firstFavorite.id
        }
        if settings.reciter == Settings.randomReciterName {
            return Settings.randomReciterName
        }
        if !settings.reciterId.isEmpty {
            return settings.reciterId
        }
        return settings.resolvedSelectedReciterIgnoringRandom()?.id ?? settings.reciter
    }

    private var normalizedSearchText: String {
        normalized(searchText)
    }

    private var isSearchingReciters: Bool {
        !normalizedSearchText.isEmpty
    }

    private var primaryReciterSections: [ReciterSectionGroup] {
        [
            ReciterSectionGroup(
                id: "minshawi",
                title: "MUHAMMAD SIDDIQ AL-MINSHAWI",
                arabic: nil,
                reciters: filteredReciters(recitersMinshawi),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "mujawwad",
                title: "SLOW & MELODIC (MUJAWWAD)",
                arabic: nil,
                reciters: filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "muallim",
                title: "TEACHING (MUALLIM)",
                arabic: nil,
                reciters: filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "murattal",
                title: "NORMAL (MURATTAL)",
                arabic: nil,
                reciters: filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            )
        ]
    }

    private var qiraahReciterSections: [ReciterSectionGroup] {
        [
            ReciterSectionGroup(
                id: "khalaf",
                title: Settings.Riwayah.khalaf.uppercased(),
                arabic: Settings.Riwayah.khalafArabic,
                reciters: filteredReciters(recitersKhalaf),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "warsh",
                title: Settings.Riwayah.warsh.uppercased(),
                arabic: Settings.Riwayah.warshArabic,
                reciters: filteredReciters(recitersWarsh),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "qaloon",
                title: Settings.Riwayah.qaloon.uppercased(),
                arabic: Settings.Riwayah.qaloonArabic,
                reciters: filteredReciters(recitersQaloon),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "buzzi",
                title: Settings.Riwayah.buzzi.uppercased(),
                arabic: Settings.Riwayah.buzziArabic,
                reciters: filteredReciters(recitersBuzzi),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "qunbul",
                title: Settings.Riwayah.qunbul.uppercased(),
                arabic: Settings.Riwayah.qunbulArabic,
                reciters: filteredReciters(recitersQunbul),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "duri",
                title: Settings.Riwayah.duri.uppercased(),
                arabic: Settings.Riwayah.duriArabic,
                reciters: filteredReciters(recitersDuri),
                isQiraah: true
            )
        ]
    }

    private var allReciterSections: [ReciterSectionGroup] {
        primaryReciterSections + murattalGroupedSections.map { section in
            ReciterSectionGroup(id: section.id, title: section.title, arabic: nil, reciters: section.reciters, isQiraah: false)
        } + qiraahReciterSections
    }

    private var availableQiraahSections: [ReciterSectionGroup] {
        settings.showQiraahDetails ? qiraahReciterSections : []
    }

    private var searchResultTitle: String {
        isSearchingReciters ? "SEARCH RESULTS" : ""
    }

    private var searchableReciterSections: [ReciterSectionGroup] {
        var sections = primaryReciterSections.filter { $0.id != "murattal" }

        sections += murattalGroupedSections.map { group in
            ReciterSectionGroup(id: group.id, title: group.title, arabic: nil, reciters: group.reciters, isQiraah: false)
        }

        sections.append(primaryReciterSections.first { $0.id == "murattal" } ?? ReciterSectionGroup(id: "murattal", title: "NORMAL (MURATTAL)", arabic: nil, reciters: [], isQiraah: false))
        sections += availableQiraahSections
        return sections.filter { !$0.reciters.isEmpty }
    }

    private var searchResultSections: [ReciterSectionGroup] {
        guard isSearchingReciters else { return [] }

        return searchableReciterSections.compactMap { section in
            let sectionMatchesTitle = matchesSectionTitle(section, query: normalizedSearchText)
            let reciters = sectionMatchesTitle
                ? section.reciters
                : section.reciters.filter { reciterMatchesSearch($0, query: normalizedSearchText) }

            guard !reciters.isEmpty else { return nil }
            return section.withReciters(reciters)
        }
    }

    private var searchResultCount: Int {
        searchResultSections.reduce(0) { $0 + $1.reciters.count }
    }

    private func requestScrollToReciter(_ reciter: Reciter) {
        withAnimation {
            searchText = ""
            pendingScrollToReciterID = reciter.id
            endEditing()
        }
    }

    private var murattalRecitersFiltered: [Reciter] {
        filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries)
    }

    private var murattalGroupedSections: [MurattalReciterGroup] {
        var groups: [MurattalReciterGroup] = []

        let all = murattalRecitersFiltered

        func matches(_ reciter: Reciter, containsAny values: [String]) -> Bool {
            let n = normalized(reciter.name)
            return values.contains { n.contains($0) }
        }

        func group(id: String, title: String, subtitle: String, containsAny values: [String]) -> [Reciter] {
            all.filter { reciter in matches(reciter, containsAny: values) }
        }

        let haramain = group(
            id: "haramain",
            title: "HARAMAIN (MAKKAH & MADINAH)",
            subtitle: "Most recognized globally",
            containsAny: [
                "abdul rahman al-sudais",
                "saud al-shuraim",
                "maher al-muaiqly",
                "abdullah al-juhany",
                "bandar baleela",
                "yasser al-dosari",
                "badr al-turki"
            ]
        )

        let classicalEgyptian = group(
            id: "classical-egypt",
            title: "CLASSICAL EGYPTIAN SCHOOL",
            subtitle: "Deep tajweed and slower murattal",
            containsAny: [
                "abdul basit",
                "mahmoud al-hussary",
                "muhammad al-minshawi",
                "mustafa ismail",
                "mahmoud ali al-banna"
            ]
        )

        let contemporary = group(
            id: "contemporary",
            title: "FAMOUS CONTEMPORARY RECITERS",
            subtitle: "Well-known and widely listened to",
            containsAny: [
                "mishary alafasy",
                "ahmad al-ajmy",
                "saad al-ghamdi",
                "hani al-rifai",
                "abu bakr al-shatri",
                "muhammad al-luhaidan",
                "hazza al-balushi"
            ]
        )

        let classicHaramain = group(
            id: "classic-haramain",
            title: "CLASSIC HARAMAIN & OLDER IMAMS",
            subtitle: "Older but iconic voices",
            containsAny: [
                "ali jaber",
                "muhammad ayyub"
            ]
        )

        let usedIDs = Set((haramain + classicalEgyptian + contemporary + classicHaramain).map(\.id))
        let other = all.filter { !usedIDs.contains($0.id) }

        if !haramain.isEmpty {
            groups.append(.init(id: "haramain", title: "HARAMAIN (MAKKAH & MADINAH)", subtitle: "Most recognized globally", reciters: haramain))
        }
        if !classicalEgyptian.isEmpty {
            groups.append(.init(id: "classical-egypt", title: "CLASSICAL EGYPTIAN SCHOOL", subtitle: "Deep tajweed and slower murattal", reciters: classicalEgyptian))
        }
        if !contemporary.isEmpty {
            groups.append(.init(id: "contemporary", title: "FAMOUS CONTEMPORARY RECITERS", subtitle: "Well-known and widely listened to", reciters: contemporary))
        }
        if !classicHaramain.isEmpty {
            groups.append(.init(id: "classic-haramain", title: "CLASSIC HARAMAIN & OLDER IMAMS", subtitle: "Older but iconic voices", reciters: classicHaramain))
        }
        if !other.isEmpty {
            groups.append(.init(id: "other", title: "OTHER RECITERS", subtitle: "Less mainstream or distinct styles", reciters: other))
        }

        return groups
    }

    private var searchableQiraahSections: [ReciterSectionGroup] {
        qiraahReciterSections.filter { !$0.reciters.isEmpty }
    }

    private func searchResultsBanner() -> some View {
        HStack(spacing: 10) {
            Text(searchResultTitle)

            Spacer()

            Text("\(searchResultCount)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private var noSearchResultsView: some View {
        Text("No reciters matched your search.")
            .foregroundStyle(.secondary)
    }

    private var reciterSearchControlsInset: some View {
        #if os(iOS)
        SearchBar(text: $searchText.animation(.easeInOut))
        .padding([.leading, .top], -8)
        #else
        EmptyView()
        #endif
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isGeneralQiraahSearch(_ query: String) -> Bool {
        Self.qiraahSearchKeywords.contains { query.contains($0) }
    }

    private func isGeneralHafsSearch(_ query: String) -> Bool {
        Self.hafsSearchKeywords.contains { query.contains($0) }
    }

    private func matchesSectionTitle(_ section: ReciterSectionGroup, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return normalized(section.title).contains(query)
            || normalized(section.arabic ?? "").contains(query)
    }

    private func reciterMatchesSearch(_ reciter: Reciter, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return normalized(reciter.name).contains(query)
    }

    @discardableResult
    private func selectReciter(_ reciter: Reciter) -> Bool {
        settings.setSelectedReciter(reciter)

        let targetQiraahTag = resolvedQiraahTag(for: reciter)
        if !isSupportedQiraahForText(targetQiraahTag) {
            pendingQiraahReciter = reciter
            pendingDisplayQiraahTag = targetQiraahTag
            return false
        }

        if settings.displayQiraahForArabic != targetQiraahTag {
            pendingQiraahReciter = reciter
            pendingDisplayQiraahTag = targetQiraahTag
            return false
        }

        pendingQiraahReciter = nil
        pendingDisplayQiraahTag = nil
        return true
    }

    private func confirmPendingQiraahSelection() {
        guard pendingQiraahReciter != nil else { return }

        if pendingRequestedQiraahIsUnsupported {
            self.pendingQiraahReciter = nil
            self.pendingDisplayQiraahTag = nil

            if dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
            return
        }

        settings.displayQiraah = pendingDisplayQiraahTag ?? Settings.Riwayah.hafsTag
        self.pendingQiraahReciter = nil
        self.pendingDisplayQiraahTag = nil

        if dismissAfterSelectingReciter {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func declinePendingQiraahSelection() {
        pendingQiraahReciter = nil
        pendingDisplayQiraahTag = nil

        if dismissAfterSelectingReciter {
            presentationMode.wrappedValue.dismiss()
        }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                if isSearchingReciters {
                    searchResultsBanner()

                    if searchResultSections.isEmpty {
                        noSearchResultsView
                    } else {
                        ForEach(searchResultSections) { section in
                            reciterSection(section)
                        }
                    }
                } else {
                    if !favoriteReciters.isEmpty {
                        Section(header: Text("FAVORITE RECITERS")) {
                            reciterButtons(favoriteReciters)
                        }
                    }
                    
                    Section {
                        randomReciterButton
                    }

                    #if os(iOS)
                    Section(header: Text("DOWNLOADED SURAHS")) {
                        Picker("Reciter Filter", selection: $showDownloadedOnly.animation(.easeInOut)) {
                            Text("All Reciters").tag(false)
                            Text("Downloaded Only").tag(true)
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Downloads are full-reciter packages (all 114 surahs).")
                                .font(.caption)
                                .foregroundColor(.primary)

                            Text("Ayah download is not supported, only surah download.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        let downloadedCount = uniqueDownloadedReciterCount
                        Text("Downloaded reciters: \(downloadedCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if downloadedCount > 0 {
                            Button(role: .destructive) {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    downloadManager.deleteAllDownloads()
                                }
                            } label: {
                                Label("Delete All Downloads", systemImage: "trash.fill")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.red)
                                    .tint(.red)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption.weight(.semibold))
                        }
                    }
                    #endif

                    if !filteredReciters(recitersMinshawi).isEmpty {
                        Section(header: Text("MUHAMMAD SIDDIQ AL-MINSHAWI")) {
                            reciterButtons(filteredReciters(recitersMinshawi))
                        }
                    }
                    
                    if !filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                        Section(header: Text("SLOW & MELODIC (MUJAWWAD)")) {
                            reciterButtons(filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                        }
                    }

                    if !filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                        Section(header: Text("TEACHING (MUALLIM)")) {
                            reciterButtons(filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                        }
                    }

                    if !murattalRecitersFiltered.isEmpty {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation {
                                    splitMurattalRecitersByGroup.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(splitMurattalRecitersByGroup ? "Show Murattal as One Section" : "Group Murattal Reciters")

                                    Spacer()

                                    Image(systemName: splitMurattalRecitersByGroup ? "rectangle.grid.1x2" : "square.grid.2x2")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }

                        if splitMurattalRecitersByGroup {
                            ForEach(murattalGroupedSections) { group in
                                Section(header: MurattalSectionHeader(title: group.title, subtitle: group.subtitle)) {
                                    reciterButtons(group.reciters)
                                }
                            }
                        } else {
                            Section(header: Text("NORMAL (MURATTAL)")) {
                                reciterButtons(murattalRecitersFiltered)
                            }
                        }
                    }
                    
                    #if os(iOS)
                    if !showDownloadedOnly {
                        if settings.showQiraahDetails {
                            Section {
                                Button {
                                    settings.hapticFeedback()
                                    withAnimation(.easeInOut) {
                                        settings.showQiraahDetails = false
                                    }
                                } label: {
                                    HStack {
                                        Text("Hide Other Qiraat Reciters")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up")
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                }
                            }
                            
                            Section(header: Text("ABOUT QIRAAT"), footer: Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                                Text("""
                                The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                                The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                                To learn more about the 7 Ahruf and the 10 Qiraat, see below and in \(AppIdentifiers.toolsView) View > Islamic Pillars and Basics.
                                """)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                                NavigationLink(destination: AhrufView()) {
                                    Text("The 7 Ahruf (Modes)")
                                }
                                .font(.subheadline)

                                NavigationLink(destination: QiraatView()) {
                                    Text("The 10 Qiraat (Recitations)")
                                }
                                .font(.subheadline)

                                Text("**All recitations above are *Hafs an Asim*, the most common and widespread Qiraah in the world today.**")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.top, 4)
                                
                                Text("All reciters below are available only for full surahs. Play Ayahs is unsupported for other qiraat.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            ForEach(searchableQiraahSections) { section in
                                reciterSection(section)
                            }
                        } else {
                            Section {
                                Button {
                                    settings.hapticFeedback()
                                    withAnimation(.easeInOut) {
                                        settings.showQiraahDetails = true
                                    }
                                } label: {
                                    HStack {
                                        Text("Show Other Qiraat Reciters")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                }
                            }
                        }
                    }
                    #else
                    if settings.showQiraahDetails {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    settings.showQiraahDetails = false
                                }
                            } label: {
                                HStack {
                                    Text("Hide Other Qiraat Reciters")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }
                        
                        Section(header: Text("ABOUT QIRAAT"), footer: Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                            Text("""
                            The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                            The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                            To learn more about the 7 Ahruf and the 10 Qiraat, see below and in \(AppIdentifiers.toolsView) View > Islamic Pillars and Basics.
                            """)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                            NavigationLink(destination: AhrufView()) {
                                Text("The 7 Ahruf (Modes)")
                            }
                            .font(.subheadline)

                            NavigationLink(destination: QiraatView()) {
                                Text("The 10 Qiraat (Recitations)")
                            }
                            .font(.subheadline)

                            Text("**All recitations above are *Hafs an Asim*, the most common and widespread Qiraah in the world today.**")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.top, 4)

                            Text("All reciters below are available only for full surahs. Play Ayahs is unsupported for other qiraat.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        ForEach(searchableQiraahSections) { section in
                            reciterSection(section)
                        }
                    } else {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    settings.showQiraahDetails = true
                                }
                            } label: {
                                HStack {
                                    Text("Show Other Qiraat Reciters")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("Select Reciter")
            #if os(iOS)
            .adaptiveSafeArea(edge: .bottom) {
                reciterSearchControlsInset
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .background(Color.white.opacity(0.00001))
            }
            #elseif os(watchOS)
            .searchable(text: $searchText)
            #endif
            .applyConditionalListStyle(defaultView: true)
            .confirmationDialog(qiraahChangeDialogTitle, isPresented: Binding(
                get: { pendingQiraahReciter != nil },
                set: {
                    if !$0 {
                        pendingQiraahReciter = nil
                        pendingDisplayQiraahTag = nil
                    }
                }
            ), titleVisibility: .visible) {
                Button(pendingRequestedQiraahIsUnsupported ? "Yes, Keep Current Quran Text" : "Confirm and Change") {
                    settings.hapticFeedback()
                    confirmPendingQiraahSelection()
                }

                Button(pendingRequestedQiraahIsUnsupported ? "Cancel Selection" : "No, Don't Change Qiraah") {
                    settings.hapticFeedback()
                    declinePendingQiraahSelection()
                }
            } message: {
                Text(qiraahChangeDialogMessage)
            }
            .onChange(of: pendingScrollToReciterID) { id in
                guard let id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(id, anchor: .top)
                        pendingScrollToReciterID = nil
                    }
                }
            }
            .onAppear {
                settings.migrateLegacyReciterIdIfNeeded()

                if settings.reciter.isEmpty
                    || (settings.reciter != Settings.randomReciterName && settings.resolvedSelectedReciterIgnoringRandom() == nil) {
                    withAnimation {
                        settings.applyDefaultReciterSelection()
                    }
                }

                #if os(iOS)
                reciters.forEach { downloadManager.ensureStateLoaded(for: $0) }
                downloadManager.purgeIncompleteReciterDownloads()
                #endif

                if autoScrollToInitialSelection && !didAutoScrollToSelection {
                    let target = reciterListScrollTargetID
                    didAutoScrollToSelection = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func filteredReciters(_ list: [Reciter], excludingFeaturedMinshawi: Bool = false) -> [Reciter] {
        let baseList = excludingFeaturedMinshawi
            ? list.filter { !recitersMinshawi.contains($0) }
            : list

        #if os(iOS)
        guard showDownloadedOnly else { return baseList }
        return baseList.filter { downloadManager.stateSnapshot(for: $0).completedSurahs > 0 }
        #else
        return baseList
        #endif
    }

    #if os(iOS)
    private var uniqueDownloadedReciterCount: Int {
        var seen = Set<String>()
        return reciters.reduce(into: 0) { count, reciter in
            guard downloadManager.stateSnapshot(for: reciter).completedSurahs > 0 else { return }
            guard seen.insert(reciter.id).inserted else { return }
            count += 1
        }
    }

    private var shouldHideDuplicateMinshawiEntries: Bool {
        showDownloadedOnly
    }
    #else
    private var shouldHideDuplicateMinshawiEntries: Bool {
        false
    }
    #endif

    @ViewBuilder
    private func reciterButtons(_ list: [Reciter], qiraah: Bool = false) -> some View {
        ForEach(list) { reciter in
            reciterRow(reciter, qiraah: qiraah)
        }
    }

    @ViewBuilder
    private func reciterSection(_ section: ReciterSectionGroup) -> some View {
        if section.isQiraah {
            Section(header: QiraahReciterSectionHeader(title: section.title, arabic: section.arabic ?? "")) {
                reciterButtons(section.reciters, qiraah: true)
            }
            .id("search-qiraah-\(section.id)")
        } else {
            Section(header: Text(section.title)) {
                reciterButtons(section.reciters)
            }
        }
    }

    private var randomReciterButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                settings.setRandomReciterMode()
            }
            #if os(watchOS)
            presentationMode.wrappedValue.dismiss()
            #elseif os(iOS)
            if dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
            #endif
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Label(Settings.randomReciterName, systemImage: "shuffle")
                        .foregroundColor(settings.reciter == Settings.randomReciterName ? settings.accentColor.color : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(settings.accentColor.color)
                        .opacity(settings.reciter == Settings.randomReciterName ? 1 : 0)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
                
                Text("A new reciter is chosen at random for every session.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .id(Settings.randomReciterName)
    }

    @ViewBuilder
    private func reciterRow(_ reciter: Reciter, qiraah: Bool) -> some View {
        #if os(iOS)
        ReciterRow(
            reciter: reciter,
            qiraah: qiraah,
            isFavorite: settings.isReciterFavorite(reciterID: reciter.id),
            isSelected: isSelectedReciter(reciter),
            downloadState: downloadManager.stateSnapshot(for: reciter),
            accentColor: settings.accentColor,
            onSelect: {
                settings.hapticFeedback()
                withAnimation {
                    let selectedImmediately = selectReciter(reciter)
                    if selectedImmediately && dismissAfterSelectingReciter {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            },
            onScrollToReciter: {
                settings.hapticFeedback()
                requestScrollToReciter(reciter)
            }
        )
        .environmentObject(downloadManager)
        .id(reciter.id)
        #else
        WatchReciterRow(
            reciter: reciter,
            qiraah: qiraah,
            isFavorite: settings.isReciterFavorite(reciterID: reciter.id),
            isSelected: isSelectedReciter(reciter),
            accentColor: settings.accentColor,
            onSelect: {
                settings.hapticFeedback()
                withAnimation {
                    let selectedImmediately = selectReciter(reciter)
                    if selectedImmediately {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        )
        .id(reciter.id)
        #endif
    }
}

#if os(iOS)
private struct ReciterRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var downloadManager: ReciterDownloadManager

    let reciter: Reciter
    let qiraah: Bool
    let isFavorite: Bool
    let isSelected: Bool
    let downloadState: ReciterDownloadManager.DownloadState
    let accentColor: AccentColor
    let onSelect: () -> Void
    let onScrollToReciter: () -> Void

    var body: some View {
        let hasDownloads = downloadState.completedSurahs > 0
        let isDownloading = downloadState.isDownloading
        let overallProgress = min(
            max((Double(downloadState.completedSurahs) + downloadState.currentSurahProgress) / Double(max(downloadState.totalSurahs, 1)), 0),
            1
        )

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.body.weight(.semibold))
                    .foregroundColor(accentColor.color)
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.toggleReciterFavorite(reciterID: reciter.id)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reciter.name)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? accentColor.color : .primary)
                        .multilineTextAlignment(.leading)

                    if isDownloading {
                        ProgressView(value: overallProgress)
                            .padding(.top, 2)
                    }

                    if !qiraah && reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi") {
                        Text("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                VStack(alignment: .trailing, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(accentColor.color)
                            .opacity(isSelected ? 1 : 0)

                        if isDownloading {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.cancelDownload(for: reciter)
                                        downloadManager.deleteDownloads(for: reciter)
                                    }
                                }
                        } else if hasDownloads {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.deleteDownloads(for: reciter)
                                    }
                                }
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.beginDownloadAll(for: reciter)
                                    }
                                }
                        }
                    }
                }
                .padding(.top, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onScrollToReciter()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            .contextMenu {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = reciter.displayNameWithEnglishQiraah
                } label: {
                    Label("Copy Name", systemImage: "doc.on.doc")
                }

                Button {
                    onScrollToReciter()
                } label: {
                    Label("Scroll to Reciter", systemImage: "arrow.down.circle")
                }
            }

            if isDownloading {
                Text("Downloading surah \(downloadState.currentSurahNumber ?? max(downloadState.completedSurahs + 1, 1)) of \(downloadState.totalSurahs) (\(Int(overallProgress * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if hasDownloads {
                Text("Storage used: \(downloadManager.storageText(bytes: downloadState.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage = downloadState.errorMessage, !errorMessage.isEmpty {
                Text("Download error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            downloadManager.ensureStateLoaded(for: reciter)
        }
    }

}
#else
private struct WatchReciterRow: View {
    @EnvironmentObject private var settings: Settings

    let reciter: Reciter
    let qiraah: Bool
    let isFavorite: Bool
    let isSelected: Bool
    let accentColor: AccentColor
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(accentColor.color)

                    Text(reciter.name)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? accentColor.color : .primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor.color)
                        .opacity(isSelected ? 1 : 0)
                }

                if !qiraah && reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi") {
                    Text("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

}
#endif
enum FavoriteType {
    case surah, ayah, letter
}

#if os(iOS)
struct FavoritesView: View {
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var settings: Settings
    
    @State private var editMode: EditMode = .inactive

    let type: FavoriteType

    var body: some View {
        List {
            switch type {
            case .surah:
                if settings.favoriteSurahs.isEmpty {
                    Text("No favorite surahs here, long tap a surah to favorite it.")
                } else {
                    ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahId in
                        if let surah = quranData.quran.first(where: { $0.id == surahId }) {
                            SurahRow(surah: surah, isFavorite: true).equatable()
                        }
                    }
                    .onDelete(perform: removeSurahs)
                }
            case .ayah:
                if settings.bookmarkedAyahs.isEmpty {
                    Text("No bookmarked ayahs here, long tap an ayah to bookmark it.")
                } else {
                    ForEach(settings.bookmarkedAyahs.sorted {
                        $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                    }, id: \.id) { bookmarkedAyah in
                        if let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah }), let ayah = surah.ayahs.first(where: { $0.id == bookmarkedAyah.ayah }) {
                                SurahAyahRow(surah: surah, ayah: ayah)
                            }
                    }
                    .onDelete(perform: removeAyahs)
                }
            case .letter:
                if settings.favoriteLetters.isEmpty {
                    Text("No favorite letters here, long tap a letter to favorite it.")
                } else {
                    ForEach(settings.favoriteLetters.sorted(), id: \.id) { favorite in
                        ArabicLetterRow(letterData: favorite).equatable()
                    }
                    .onDelete(perform: removeLetters)
                }
            }
            
            Section {
                if !isListEmpty {
                    Button("Delete All") {
                        deleteAll()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle(titleForFavoriteType(type))
        .toolbar {
            EditButton()
        }
        .environment(\.editMode, $editMode)
    }

    private var isListEmpty: Bool {
        switch type {
        case .surah: return settings.favoriteSurahs.isEmpty
        case .ayah: return settings.bookmarkedAyahs.isEmpty
        case .letter: return settings.favoriteLetters.isEmpty
        }
    }

    private func deleteAll() {
        switch type {
        case .surah:
            settings.favoriteSurahs.removeAll()
        case .ayah:
            settings.bookmarkedAyahs.removeAll()
        case .letter:
            settings.favoriteLetters.removeAll()
        }
    }
    
    private func removeSurahs(at offsets: IndexSet) {
        settings.favoriteSurahs.remove(atOffsets: offsets)
    }

    private func removeAyahs(at offsets: IndexSet) {
        settings.bookmarkedAyahs.remove(atOffsets: offsets)
    }

    private func removeLetters(at offsets: IndexSet) {
        settings.favoriteLetters.remove(atOffsets: offsets)
    }
    
    private func titleForFavoriteType(_ type: FavoriteType) -> String {
        switch type {
        case .surah:
            return "Favorite Surahs"
        case .ayah:
            return "Bookmarked Ayahs"
        case .letter:
            return "Favorite Letters"
        }
    }
    
    func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            toolLabel(title, systemImage: systemImage)
        }
        .tint(settings.accentColor.color)
    }

    func toolLabel(_ title: String, systemImage: String) -> some View {
        Label(
            title: { Text(title) },
            icon: {
                Image(systemName: systemImage)
                    .foregroundColor(settings.accentColor.color)
            }
        )
        .padding(.vertical, 4)
        .accentColor(settings.accentColor.color)
    }

    func leaveReview() {
        settings.hapticFeedback()

        withAnimation(.smooth()) {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6449729655?action=write-review") {
                UIApplication.shared.open(url)
            }
        }
    }

    func openAppSettings() {
        settings.hapticFeedback()

        withAnimation(.smooth()) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    func columnWidth(for textStyle: UIFont.TextStyle, extra: CGFloat = 4, sample: String? = nil, fontName: String? = nil) -> CGFloat {
        let sampleString = (sample ?? "M") as NSString
        let font: UIFont

        if let fontName = fontName, let customFont = UIFont(name: fontName, size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) {
            font = customFont
        } else {
            font = UIFont.preferredFont(forTextStyle: textStyle)
        }

        return ceil(sampleString.size(withAttributes: [.font: font]).width) + extra
    }

    var glyphWidth: CGFloat {
        columnWidth(for: .subheadline, extra: 0, sample: "Contact: ")
    }
}
#endif

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        SettingsQuranView()
    }
}
