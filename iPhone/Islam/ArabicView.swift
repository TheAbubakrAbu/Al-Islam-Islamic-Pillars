import SwiftUI

struct ArabicView: View {
    @EnvironmentObject private var settings: Settings
    @State private var searchText = ""
    @AppStorage("arabicFilterMode") private var filterModeRaw: String = ArabicFilterMode.normal.rawValue

    private enum ArabicFilterMode: String, CaseIterable {
        case normal
        case similarity
        case heavyLight

        var title: String {
            switch self {
            case .normal: return "Normal Grouping"
            case .similarity: return "Similar Letters"
            case .heavyLight: return "Heavy vs Light"
            }
        }

        var icon: String {
            switch self {
            case .normal: return "square.grid.2x2"
            case .similarity: return "square.grid.3x3"
            case .heavyLight: return "circle.lefthalf.filled"
            }
        }
    }

    private var filterMode: ArabicFilterMode {
        get { ArabicFilterMode(rawValue: filterModeRaw) ?? .normal }
        set { filterModeRaw = newValue.rawValue }
    }

    private let similarityGroups: [[String]] = [
        ["ا", "و", "ي"], ["ب", "ت", "ث"], ["ج", "ح", "خ"], ["د", "ذ"],
        ["ر", "ز"], ["س", "ش"], ["ص", "ض"], ["ط", "ظ"], ["ع", "غ"],
        ["ف", "ق"], ["ك", "ل"], ["م", "ن"], ["ه", "ة"]
    ]

    private var filteredStandard: [LetterData] {
        guard !searchText.isEmpty else { return standardArabicLetters }
        let st = searchText.lowercased()
        return standardArabicLetters.filter { matchesSearch($0, st) }
    }

    private var filteredOther: [LetterData] {
        let allOtherLetters = otherArabicLetters + nonArabicArabicScriptLetters
        guard !searchText.isEmpty else { return allOtherLetters }
        let st = searchText.lowercased()
        return allOtherLetters.filter {
            $0.letter.lowercased().contains(st)
                || $0.name.lowercased().contains(st)
                || $0.transliteration.lowercased().contains(st)
        }
    }

    private func matchesSearch(_ letter: LetterData, _ st: String) -> Bool {
        var parts: [String] = [
            letter.letter.lowercased(),
            letter.name.lowercased(),
            letter.transliteration.lowercased()
        ]

        if let weight = letter.weight {
            switch weight {
            case .heavy:
                parts += ["heavy", "tafkhim", "tafkhīm", "isti'la", "istila", "isti‘la"]
            case .light:
                parts += ["light", "tarqiq", "tarqīq"]
            case .conditional:
                parts += ["conditional"]
            case .followsPrevious:
                parts += ["follows previous", "follows", "previous"]
            }
        }

        if let rule = letter.weightRule?.lowercased() {
            parts.append(rule)
        }

        return parts.contains { $0.contains(st) }
    }

    private var filteredStandardForMode: [LetterData] {
        switch filterMode {
        case .normal, .similarity:
            return filteredStandard
        case .heavyLight:
            return filteredStandard.filter { $0.weight != nil }
        }
    }

    var body: some View {
        List {
            if searchText.isEmpty, !settings.favoriteLetters.isEmpty {
                Section("FAVORITE LETTERS") {
                    ForEach(settings.favoriteLetters.sorted(), id: \.id) {
                        ArabicLetterRow(letterData: $0)
                    }
                }
            }

            if searchText.isEmpty {
                if filterMode == .normal {
                    Section("STANDARD ARABIC LETTERS") {
                        ForEach(standardArabicLetters, id: \.letter) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }
                } else if filterMode == .similarity {
                    ForEach(similarityGroups.indices, id: \.self) { idx in
                        let group = similarityGroups[idx]
                        let header = idx == 0 ? "VOWEL LETTERS" : group.joined(separator: " AND")
                        Section(header) {
                            ForEach(group, id: \.self) { ch in
                                letterData(for: ch).map(ArabicLetterRow.init)
                            }
                        }
                    }
                } else if filterMode == .heavyLight {
                    Section("HEAVY LETTERS") {
                        ForEach(standardArabicLetters.filter { $0.weight == .heavy }, id: \.letter) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }

                    Section("LIGHT LETTERS") {
                        ForEach((standardArabicLetters + otherArabicLetters).filter {
                            $0.weight == .light
                                || $0.transliteration == "taa marbuuTa"
                                || $0.transliteration.lowercased().contains("hamza")
                        }, id: \.id) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }

                    Section("CONDITIONAL") {
                        ForEach(standardArabicLetters.filter { $0.weight == .conditional }, id: \.letter) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }

                    Section("FOLLOWS PREVIOUS") {
                        ForEach(standardArabicLetters.filter { $0.weight == .followsPrevious }, id: \.letter) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }
                } else {
                    Section("STANDARD ARABIC LETTERS") {
                        ForEach(standardArabicLetters, id: \.letter) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }
                }

                Section("SPECIAL ARABIC LETTERS") {
                    ForEach(otherArabicLetters, id: \.letter) {
                        ArabicLetterRow(letterData: $0)
                    }
                }

                Section("ARABIC NUMBERS") {
                    ForEach(numbers, id: \.number) { ArabicNumberRow(numberData: $0) }
                }

                tajweedSection

                Section("NON-ARABIC LETTERS") {
                    ForEach(nonArabicArabicScriptLetters, id: \.letter) {
                        ArabicLetterRow(letterData: $0)
                    }
                }
            } else {
                Section {
                    ForEach(filteredStandardForMode) {
                        ArabicLetterRow(letterData: $0)
                    }

                    ForEach(filteredOther) {
                        ArabicLetterRow(letterData: $0)
                    }
                } header: {
                    HStack {
                        Text("ARABIC SEARCH RESULTS")

                        Spacer()

                        Text("\(filteredStandardForMode.count + filteredOther.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            #if !os(watchOS)
                            .background(.ultraThinMaterial)
                            #endif
                            .clipShape(Capsule())
                            .conditionalGlassEffect()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        #if os(watchOS)
        .searchable(text: $searchText)
        #else
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
                    Text("Quranic Font").tag(true)
                    Text("Basic Font").tag(false)
                }
                .pickerStyle(.segmented)
                .conditionalGlassEffect()

                HStack(spacing: 0) {
                    SearchBar(text: $searchText.animation(.easeInOut))

                    Menu {
                        Picker("Arabic Filter", selection: $filterModeRaw.animation(.easeInOut)) {
                            ForEach(ArabicFilterMode.allCases, id: \.rawValue) { mode in
                                Label(mode.title, systemImage: mode.icon).tag(mode.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: filterMode.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(settings.accentColor.color)
                            .transition(.opacity)
                    }
                    .frame(width: 30, height: 30)
                    .padding()
                    .conditionalGlassEffect()
                }
                .padding([.leading, .top], -8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .dismissKeyboardOnScroll()
        .navigationTitle("Arabic Alphabet")
    }

    private func letterData(for glyph: String) -> LetterData? {
        standardArabicLetters.first { $0.letter == glyph }
            ?? otherArabicLetters.first { $0.letter == glyph }
            ?? nonArabicArabicScriptLetters.first { $0.letter == glyph }
    }

    @ViewBuilder
    private var tajweedSection: some View {
        Section("QURAN SIGNS") {
            StopInfoRow(title: "Make Sujood (Prostration)", symbol: "۩", color: settings.accentColor.color)
            StopInfoRow(title: "The Mandatory Stop", symbol: "مـ", color: settings.accentColor.color)
            StopInfoRow(title: "The Preferred Stop", symbol: "قلى", color: settings.accentColor.color)
            StopInfoRow(title: "The Permissible Stop", symbol: "ج", color: settings.accentColor.color)
            StopInfoRow(title: "The Short Pause", symbol: "س", color: settings.accentColor.color)
            StopInfoRow(title: "Stop at One", symbol: "∴ ∴", color: settings.accentColor.color)
            StopInfoRow(title: "The Preferred Continuation", symbol: "صلى", color: settings.accentColor.color)
            StopInfoRow(title: "The Mandatory Continuation", symbol: "لا", color: settings.accentColor.color)

            if let url = URL(string: "https://studioarabiya.com/blog/tajweed-rules-stopping-pausing-signs/") {
                Link("View More: Tajweed Rules & Stopping/Pausing Signs", destination: url)
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }
        }
    }
}

struct LetterSectionHeader: View {
    @EnvironmentObject var settings: Settings
    let letterData: LetterData

    var body: some View {
        HStack {
            Text("LETTER")
                .font(.subheadline)

            Spacer()

            Image(systemName: settings.isLetterFavorite(letterData: letterData) ? "star.fill" : "star")
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    settings.toggleLetterFavorite(letterData: letterData)
                }
        }
    }
}

struct ArabicLetterView: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData

    private var useQuranicFontForLetter: Bool {
        settings.useFontArabic && !letterData.isNonArabicScriptLetter
    }

    private var nonArabicBaseSound: String {
        switch letterData.transliteration {
        case "pe": return "p"
        case "che": return "ch"
        case "ve": return "v"
        case "gaaf (gaa)": return "g"
        case "ngaf": return "ng"
        case "zhe": return "zh"
        default: return letterData.transliteration
        }
    }

    var body: some View {
        List {
            Section(header: LetterSectionHeader(letterData: letterData)) {
                VStack {
                    HStack(alignment: .center) {
                        Spacer()

                        Text(letterData.transliteration)
                            .font(.subheadline)

                        Spacer()

                        Text(letterData.name)
                            .font(
                                useQuranicFontForLetter
                                    ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                    : .title2
                            )

                        Spacer()
                    }
                }
                #if !os(watchOS)
                .listRowSeparator(.hidden, edges: .bottom)
                #endif
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if let weight = letterData.weight {
                Section(header: Text("LIGHT / HEAVY PRONUNCIATION")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(weight == .heavy ? "Heavy letter (Tafkhīm)"
                             : weight == .light ? "Light letter (Tarqīq)"
                             : weight == .conditional ? "Conditional letter"
                             : "Follows previous letter")
                            .font(.headline)

                        if let weightRule = letterData.weightRule {
                            Text(weightRule)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(header: Text("DIFFERENT FORMS")) {
                VStack {
                    HStack(alignment: .center) {
                        ForEach(0..<3, id: \.self) { index in
                            Spacer()

                            Text(letterData.forms[index])
                                .font(
                                    useQuranicFontForLetter
                                        ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                        : .title2
                                )

                            Spacer()
                        }
                    }
                }
                #if !os(watchOS)
                .listRowSeparator(.hidden, edges: .bottom)
                #endif
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if ["alif", "waw", "yaa"].contains(letterData.transliteration) {
                Section(header: Text("SPECIAL ROLE OF VOWEL LETTERS")) {
                    Text("In Arabic, three letters (Alif, Waw, and Yaa) have a special dual role:")
                        .font(.body)

                    if letterData.transliteration == "alif" {
                        Text("- **Alif (ا)**: Functions as a long vowel 'aa' when used after a letter with a fatha. For example, كِتَاب (kitaab - book). Alif never carries tashkeel unless it represents Hamza.")
                            .font(.body)
                    }

                    if letterData.transliteration == "waw" {
                        Text("- **Waw (و)**: Functions as a long vowel 'uu' when used after a letter with a damma, like in رَسُول (rasool - messenger). As a consonant, it makes the 'w' sound, like in وَقَفَ (waqafa - stood).")
                            .font(.body)
                    }

                    if letterData.transliteration == "yaa" {
                        Text("- **Yaa (ي)**: Functions as a long vowel 'ii' when used after a letter with a kasra, like in كِتَابِي (kitaabi - my book). As a consonant, it makes the 'y' sound, like in يَد (yad - hand).")
                            .font(.body)
                    }

                    Text("These letters serve as vowels when they follow specific diacritics, and as consonants when they begin a word or are preceded by a sukoon.")
                        .font(.body)
                }
            }

            if letterData.showTashkeel {
                Section(header: Text("DIFFERENT HARAKAAT (VOWELS)")) {
                    let chunks = tashkeels.chunked(into: 3)
                    ForEach(chunks.indices, id: \.self) { idx in
                        VStack {
                            #if !os(watchOS)
                            if idx > 0 {
                                Divider().padding(.trailing, -100)
                            }
                            #endif

                            TashkeelRow(
                                letterData: letterData,
                                tashkeels: chunks[idx],
                                useQuranicFontForLetter: useQuranicFontForLetter
                            )
                            .padding(.top, 14)
                        }
                        #if !os(watchOS)
                        .listRowSeparator(.hidden, edges: .bottom)
                        #endif
                    }

                    #if !os(watchOS)
                    Text("WITH ALIF HAMZA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HamzaPracticeRow(
                        letterData: letterData,
                        useQuranicFontForLetter: useQuranicFontForLetter
                    )
                    .padding(.bottom, 8)
                    .listRowSeparator(.hidden, edges: .bottom)
                    #else
                    HamzaPracticeRow(
                        letterData: letterData,
                        useQuranicFontForLetter: useQuranicFontForLetter
                    )
                    #endif
                }
            }

            if letterData.isNonArabicScriptLetter {
                Section(header: Text("SOUND WITH HARAKAAT")) {
                    NonArabicVowelPracticeRow(
                        letterData: letterData,
                        baseSound: nonArabicBaseSound,
                        useQuranicFontForLetter: useQuranicFontForLetter
                    )
                }
            }

            if (!letterData.showTashkeel && letterData.transliteration != "alif")
                || letterData.transliteration == "yaa" {
                Section(header: Text("PURPOSE")) {
                    purposeSection(for: letterData)
                }
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .dismissKeyboardOnScroll()
        .navigationTitle(letterData.letter)
    }

    @ViewBuilder
    private func purposeSection(for data: LetterData) -> some View {
        if data.isNonArabicScriptLetter {
            Group {
                Text("This letter is used in non-Arabic languages that use Arabic script.")
                Text("It is not one of the 28 standard Arabic alphabet letters.")
            }
            .font(.body)
        } else {
            switch data.transliteration {
            case "yaa":
                Text("In the Uthmani script of the Quran, when 'yaa' is written at the end of a word (or by itself), it is usually written without the two dots underneath.")
                    .font(.body)
            case "taa marbuuTa":
                Group {
                    Text("\"Taa marbuuTa\" means \"tied taa\" and is used to indicate the feminine gender in Arabic.")
                    Text("It is typically added to the end of a noun to show that the noun is feminine. For example, the Arabic word for teacher is \"معلم\" (mu'allim) for a male and \"معلمة\" (mu'allima) for a female.")
                    Text("Taa marbuuTa is pronounced as a \"t\" sound in certain cases, such as when the word is in the construct state or has a suffix. Otherwise, it is often silent but affects the preceding vowel, usually creating a short \"ah\" sound, similar to 'ه' (as in \"mu'allimah\").")
                }
                .font(.body)
            case "hamzatul waSl":
                Group {
                    Text("The term \"hamzatul waSl\" translates to \"connecting hamza\" or \"hamza of connection.\"")
                    Text("Hamzatul waSl is always written as an Alif (ا) and is pronounced only if it begins a word at the start of speech. When the word follows another in a sentence, the hamzatul waSl is not pronounced, creating a smooth connection between words.")
                    Text("If a word starts with hamzatul waSl, its pronunciation depends on the third letter of the word. For verbs: if the third letter has a damma, pronounce it with a damma (أُ); if it has a kasra or fatha, pronounce it with a kasra (إِ).")
                    Text("In the Quran, there are seven nouns that start with hamzatul waSl. These nouns always begin with a kasra when pronounced in isolation.")
                    Text("Hamzatul waSl is usually not written with diacritics, but in learner texts or the Quran, it may be marked with a small ص above the Alif, indicating waSl.")
                }
                .font(.body)
            default:
                if data.transliteration.contains("hamza") {
                    Group {
                        Text("The letter Hamza has multiple forms, depending on its position and the surrounding vowels or diacritics (tashkeel):")
                        Text("Hamza on its own (ء): Used when Hamza appears in the middle or end of a word without a preceding vowel.")
                        Text("Hamza on an Alif (أ or إ): When Hamza begins a word, it is written on an Alif. A fatha or damma places it above (أ), while a kasra places it below (إ).")
                        Text("Hamza on a Waw (ؤ): Appears after a damma or following a Waw.")
                        Text("Hamza on a Yaa (ئ): Appears after a kasra or following a Yaa.")
                        Text("Although Hamza takes different forms, it represents the same sound ('ah'). These forms are based on Arabic orthography (spelling conventions) rather than phonetics.")
                    }
                    .font(.body)
                } else if data.transliteration.contains("mad") {
                    Group {
                        Text("The wavy line above a vowel letter is called a 'mad'. It elongates the vowel sound, typically lasting 4 counts.")
                        + (
                            data.transliteration.contains("alif")
                                ? Text("\nIf an Alif Mad is followed by a letter with a shaddah, the elongation extends to 6 counts.")
                                : Text("")
                        )
                    }
                    .font(.body)
                } else if data.transliteration == "alif maqSoorah" {
                    Text("Alif maqSoorah resembles a Yaa without dots and usually replaces a regular Alif at the end of a word. It is used in certain cases, including some Quranic words and non-Arabic proper nouns. It is the exact same and sounds the same as alif.")
                        .font(.body)
                } else if data.transliteration == "laa" {
                    Text("The combination of ل and ا forms a unique shape: لا.")
                        .font(.body)
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct TashkeelRow: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData
    let tashkeels: [Tashkeel]
    let useQuranicFontForLetter: Bool

    private var baseSound: String {
        letterData.sound
    }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(tashkeels, id: \.english) { tk in
                VStack(spacing: useQuranicFontForLetter ? 4 : 8) {
                    Group {
                        if !tk.transliteration.isEmpty {
                            Text(baseSound + tk.transliteration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if tk.english == "Shaddah" {
                            Text(baseSound + baseSound)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if tk.english.contains("Sukoon") {
                            Text(baseSound)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                    Text(letterData.letter + tk.tashkeelMark)
                        .font(
                            useQuranicFontForLetter
                                ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                : .title
                        )
                        .frame(maxWidth: .infinity)

                    #if !os(watchOS)
                    Text(tk.english)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    #endif
                }
            }
        }
    }
}

struct HamzaPracticeRow: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData
    let useQuranicFontForLetter: Bool

    private var syllables: [(latin: String, arabic: String)] {
        let sound = letterData.sound
        let letter = letterData.letter

        return [
            ("A" + sound, "أَ" + letter),
            ("I" + sound, "إِ" + letter),
            ("U" + sound, "أُ" + letter)
        ]
    }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(syllables, id: \.latin) { syllable in
                VStack {
                    Text(syllable.latin)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                : .title
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
            }
        }
        .padding(.top, 6)
    }
}

struct NonArabicVowelPracticeRow: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData
    let baseSound: String
    let useQuranicFontForLetter: Bool

    private var syllables: [(latin: String, arabic: String)] {
        [
            (baseSound + "a", letterData.letter + "َ"),
            (baseSound + "i", letterData.letter + "ِ"),
            (baseSound + "u", letterData.letter + "ُ")
        ]
    }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(syllables, id: \.latin) { syllable in
                VStack {
                    Text(syllable.latin)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                : .title
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
            }
        }
    }
}

struct ArabicLetterRow: View {
    @EnvironmentObject private var settings: Settings
    let letterData: LetterData

    var body: some View {
        let isFav = settings.isLetterFavorite(letterData: letterData)

        NavigationLink(destination: ArabicLetterView(letterData: letterData)) {
            HStack {
                Text(letterData.transliteration)
                    .font(.subheadline)

                Spacer()

                Text(letterData.letter)
                    .font(
                        (settings.useFontArabic && !letterData.isNonArabicScriptLetter)
                            ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                            : .title2
                    )
                    .foregroundColor(settings.accentColor.color)
            }
            .padding(.vertical, -2)
        }
        #if !os(watchOS)
        .swipeActions(edge: .leading) { favButton(isFav: isFav) }
        .swipeActions(edge: .trailing) { favButton(isFav: isFav) }
        .contextMenu { contextItems(isFav: isFav) }
        #endif
    }

    @ViewBuilder
    private func favButton(isFav: Bool) -> some View {
        Button {
            settings.hapticFeedback()
            settings.toggleLetterFavorite(letterData: letterData)
        } label: {
            Image(systemName: isFav ? "star.fill" : "star")
        }
        .tint(settings.accentColor.color)
    }

    @ViewBuilder
    private func contextItems(isFav: Bool) -> some View {
        #if !os(watchOS)
        Button(role: isFav ? .destructive : nil) {
            settings.hapticFeedback()
            settings.toggleLetterFavorite(letterData: letterData)
        } label: {
            Label(isFav ? "Unfavorite Letter" : "Favorite Letter",
                  systemImage: isFav ? "star.fill" : "star")
        }

        Button {
            UIPasteboard.general.string = letterData.letter
            settings.hapticFeedback()
        } label: {
            Label("Copy Letter", systemImage: "doc.on.doc")
        }

        Button {
            UIPasteboard.general.string = letterData.transliteration
            settings.hapticFeedback()
        } label: {
            Label("Copy Transliteration", systemImage: "doc.on.doc")
        }
        #endif
    }
}

struct ArabicNumberRow: View {
    @EnvironmentObject private var settings: Settings
    let numberData: (number: String, name: String, transliteration: String, englishNumber: String)

    var body: some View {
        HStack {
            Text(numberData.englishNumber)
                .font(.title3)

            Spacer()

            VStack(alignment: .center) {
                Text(numberData.name)
                    .font(
                        settings.useFontArabic
                            ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize)
                            : .subheadline
                    )
                    .foregroundColor(settings.accentColor.color)

                Text(numberData.transliteration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(numberData.number)
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

struct StopInfoRow: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Text(symbol)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ArabicView()
        .environmentObject(Settings.shared)
}
