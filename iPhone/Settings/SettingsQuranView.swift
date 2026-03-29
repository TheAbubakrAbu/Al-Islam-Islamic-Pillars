import SwiftUI

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
            ToolbarItem(placement: .navigationBarTrailing) {
                if presentedAsSheet {
                    Button("Done") {
                        dismiss()
                    }
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

            HStack {
                Text(settings.reciter)
                    .foregroundColor(settings.accentColor.color)

                Spacer()
            }
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
            systemFontSizeToggle
        }
    }

    private var pageAndJuzDividersGroup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Show Page and Juz Dividers", isOn: pageJuzDividers.animation(.easeInOut))
                .font(.subheadline)

            if settings.showPageJuzDividers {
                Toggle("Show Overlay", isOn: $settings.showPageJuzOverlay.animation(.easeInOut))
                    .font(.subheadline)
            }
        }
    }

    private var systemFontSizeToggle: some View {
        Toggle("Use System Font Size", isOn: useSystemFontSizes)
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
            Toggle("Show Tajweed Colors", isOn: $settings.showTajweedColors.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)

            NavigationLink(destination: TajweedLegendSettingsView()) {
                Text("Customize Tajweed Legend")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }
            .disabled(!settings.showTajweedColors)

            Text(settings.isHafsDisplay
                 ? "Available for Hafs an Asim. Tajweed colors automatically fall back to plain Arabic when clean text or beginner spacing is enabled. Tajweed coloring is currently in beta and may not always be fully accurate."
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
        Section(header: Text("ENGLISH TEXT"), footer: Text("Transliteration, translations, and all English text apply only to default Hafs an Asim. For other riwayat, only the Arabic text is shown.")) {
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
        Section(
            header: Text("RIWAYAH / QIRAAH"),
            footer: Text("There is no dedicated audio for individual ayahs in other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")
        ) {
            qiraahPicker
            qiraahExplanation
            qiraahLinks
            qiraahHighlight
            comparisonModeGroup
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
        The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the early Muslim community. From these, the Ten Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

        The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

        To learn more about the Seven Ahruf and the Ten Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
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
        Text("***Hafs An Asim* is the most common and widespread Qiraah in the world today.**")
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

struct TajweedLegendSettingsView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        List {
            Section(header: Text("TAJWEED LEGEND")) {
                ForEach(TajweedLegendCategory.allCases) { item in
                    Toggle(isOn: Binding(
                        get: { settings.isTajweedCategoryVisible(item) },
                        set: { settings.setTajweedCategory(item, visible: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)

                                Text(item.englishTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                            }

                            Text(item.arabicTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .tint(item.color)
                }
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Tajweed Legend")
    }
}

struct ReciterListView: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.presentationMode) private var presentationMode
    @State private var didAutoScrollToSelection = false
    #if os(iOS)
    @StateObject private var downloadManager = ReciterDownloadManager.shared
    @State private var showDownloadedOnly = false
    #endif

    private static let defaultReciter = "Muhammad Al-Minshawi (Murattal)"
    var body: some View {
        ScrollViewReader { proxy in
            List {
                #if os(iOS)
                Section(header: Text("DOWNLOADED SURAHS")) {
                    Picker("Reciter Filter", selection: $showDownloadedOnly.animation(.easeInOut)) {
                        Text("All Reciters").tag(false)
                        Text("Downloaded Only").tag(true)
                    }
                    #if os(iOS)
                    .pickerStyle(.segmented)
                    #endif

                    Text("Downloads are full-reciter packages (all 114 surahs).")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Ayah download is not supported, only surah download.")
                        .font(.caption)
                        .foregroundColor(.secondary)

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
                
                #if os(iOS)
                if !showDownloadedOnly {
                    Section {
                        randomReciterButton
                    }
                }
                #else
                Section {
                    randomReciterButton
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
                    Section(header: Text("TEACHING (MUʿALLIM)")) {
                        reciterButtons(filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                    }
                }

                if !filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                    Section(header: Text("NORMAL (MURATTAL)")) {
                        reciterButtons(filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                    }
                }
                
                #if os(iOS)
                if !showDownloadedOnly {
                    Section(header: Text("ABOUT QIRAAT"), footer: Text("There is no dedicated audio for individual ayahs in other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                        Text("""
                        The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the early Muslim community. From these, the Ten Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                        The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                        To learn more about the Seven Ahruf and the Ten Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
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

                        Text("**All recitations above are *Hafs An Asim*, the most common and widespread Qiraah in the world today.**")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                        
                        Text("All reciters below are available only for full surahs. Ayah playback defaults to Minshawi (Murattal).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                #else
                Section(header: Text("ABOUT QIRAAT"), footer: Text("There is no dedicated audio for individual ayahs in other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                    Text("""
                    The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the early Muslim community. From these, the Ten Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                    The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                    To learn more about the Seven Ahruf and the Ten Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
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

                    Text("**All recitations above are *Hafs An Asim*, the most common and widespread Qiraah in the world today.**")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 4)

                    Text("All reciters below are available only for full surahs. Ayah playback defaults to Minshawi (Murattal).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                #endif

                #if os(iOS)
                if !showDownloadedOnly {
                    if settings.showOtherQiraatReciters {
                        if !filteredReciters(recitersKhalaf).isEmpty {
                            Section(header: Text("KHALAF AN HAMZAH")) {
                                reciterButtons(filteredReciters(recitersKhalaf), qiraah: true)
                            }
                        }

                        if !filteredReciters(recitersWarsh).isEmpty {
                            Section(header: Text("WARSH AN NAFI")) {
                                reciterButtons(filteredReciters(recitersWarsh), qiraah: true)
                            }
                        }

                        if !filteredReciters(recitersQaloon).isEmpty {
                            Section(header: Text("QALOON AN NAFI")) {
                                reciterButtons(filteredReciters(recitersQaloon), qiraah: true)
                            }
                        }

                        if !filteredReciters(recitersBuzzi).isEmpty {
                            Section(header: Text("AL-BUZZI AN IBN KATHIR")) {
                                reciterButtons(filteredReciters(recitersBuzzi), qiraah: true)
                            }
                        }

                        if !filteredReciters(recitersQunbul).isEmpty {
                            Section(header: Text("QUNBUL AN IBN KATHIR")) {
                                reciterButtons(filteredReciters(recitersQunbul), qiraah: true)
                            }
                        }

                        if !filteredReciters(recitersDuri).isEmpty {
                            Section(header: Text("AD-DURI AN ABI AMR")) {
                                reciterButtons(filteredReciters(recitersDuri), qiraah: true)
                            }
                        }
                    } else {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    settings.showOtherQiraatReciters = true
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
                if settings.showOtherQiraatReciters {
                    if !filteredReciters(recitersKhalaf).isEmpty {
                        Section(header: Text("KHALAF AN HAMZAH")) {
                            reciterButtons(filteredReciters(recitersKhalaf), qiraah: true)
                        }
                    }

                    if !filteredReciters(recitersWarsh).isEmpty {
                        Section(header: Text("WARSH AN NAFI")) {
                            reciterButtons(filteredReciters(recitersWarsh), qiraah: true)
                        }
                    }

                    if !filteredReciters(recitersQaloon).isEmpty {
                        Section(header: Text("QALOON AN NAFI")) {
                            reciterButtons(filteredReciters(recitersQaloon), qiraah: true)
                        }
                    }

                    if !filteredReciters(recitersBuzzi).isEmpty {
                        Section(header: Text("AL-BUZZI AN IBN KATHIR")) {
                            reciterButtons(filteredReciters(recitersBuzzi), qiraah: true)
                        }
                    }

                    if !filteredReciters(recitersQunbul).isEmpty {
                        Section(header: Text("QUNBUL AN IBN KATHIR")) {
                            reciterButtons(filteredReciters(recitersQunbul), qiraah: true)
                        }
                    }

                    if !filteredReciters(recitersDuri).isEmpty {
                        Section(header: Text("AD-DURI AN ABI AMR")) {
                            reciterButtons(filteredReciters(recitersDuri), qiraah: true)
                        }
                    }
                } else {
                    Section {
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.showOtherQiraatReciters = true
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
            .navigationTitle("Select Reciter")
            .applyConditionalListStyle(defaultView: true)
            .onAppear {
                if settings.reciter.isEmpty || (settings.reciter != Settings.randomReciterName && reciters.first(where: { $0.name == settings.reciter }) == nil) {
                    withAnimation {
                        settings.reciter = Self.defaultReciter
                    }
                }

                #if os(iOS)
                reciters.forEach { downloadManager.ensureStateLoaded(for: $0) }
                #endif

                if !didAutoScrollToSelection {
                    let target = settings.reciter
                    didAutoScrollToSelection = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
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

    private var randomReciterButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                settings.reciter = Settings.randomReciterName
            }
            #if os(watchOS)
            presentationMode.wrappedValue.dismiss()
            #endif
        } label: {
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
        }
        .id(Settings.randomReciterName)
    }

    @ViewBuilder
    private func reciterRow(_ reciter: Reciter, qiraah: Bool) -> some View {
        #if os(iOS)
        let state = downloadManager.stateSnapshot(for: reciter)
        let hasDownloads = state.completedSurahs > 0
        let isDownloading = state.isDownloading
        let overallProgress = min(
            max((Double(state.completedSurahs) + state.currentSurahProgress) / Double(max(state.totalSurahs, 1)), 0),
            1
        )

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reciter.name)
                        .font(.subheadline)
                        .foregroundColor(reciter.name == settings.reciter ? settings.accentColor.color : .primary)
                        .multilineTextAlignment(.leading)

                    if isDownloading {
                        ProgressView(value: overallProgress)
                            .padding(.top, 2)
                    }

                    if !qiraah && reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi") {
                        Text("This reciter is only available for surah recitation. Defaults to Minshawi (Murattal) for ayahs.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                VStack(alignment: .trailing, spacing: 10) {
                    HStack(spacing: 8) {
                        if isDownloading {
                            Button {
                                settings.hapticFeedback()
                                withAnimation {
                                    downloadManager.cancelDownload(for: reciter)
                                    downloadManager.deleteDownloads(for: reciter)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        } else if hasDownloads {
                            Button(role: .destructive) {
                                settings.hapticFeedback()
                                withAnimation {
                                    downloadManager.deleteDownloads(for: reciter)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                settings.hapticFeedback()
                                withAnimation {
                                    downloadManager.beginDownloadAll(for: reciter)
                                }
                            } label: {
                                Image(systemName: "icloud.and.arrow.down")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation {
                    settings.reciter = reciter.name
                }
            }

            if isDownloading {
                Text("Downloading surah \(state.currentSurahNumber ?? max(state.completedSurahs + 1, 1)) of \(state.totalSurahs) (\(Int(overallProgress * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if hasDownloads {
                Text("Storage used: \(downloadManager.storageText(bytes: state.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage = state.errorMessage, !errorMessage.isEmpty {
                Text("Download error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            downloadManager.ensureStateLoaded(for: reciter)
        }
        .id(reciter.name)
        #else
        Button {
            settings.hapticFeedback()
            withAnimation {
                settings.reciter = reciter.name
                presentationMode.wrappedValue.dismiss()
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reciter.name)
                        .font(.subheadline)
                        .foregroundColor(reciter.name == settings.reciter ? settings.accentColor.color : .primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "checkmark")
                        .foregroundColor(settings.accentColor.color)
                        .opacity(reciter.name == settings.reciter ? 1 : 0)
                }

                if !qiraah && reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi") {
                    Text("This reciter is only available for surah recitation. Defaults to Minshawi (Murattal) for ayahs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .id(reciter.name)
        #endif
    }
}

#if os(iOS)
enum FavoriteType {
    case surah, ayah, letter
}

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
                            SurahRow(surah: surah)
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
                        ArabicLetterRow(letterData: favorite)
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
}
#endif

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SettingsQuranView()
    }
}
