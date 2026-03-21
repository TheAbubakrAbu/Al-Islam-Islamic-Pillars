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
            $0.letter.lowercased().contains(st) ||
            $0.name.lowercased().contains(st)  ||
            $0.transliteration.lowercased().contains(st)
        }
    }
    
    private func matchesSearch(_ letter: LetterData, _ st: String) -> Bool {
        var parts: [String] = [
            letter.letter.lowercased(),
            letter.name.lowercased(),
            letter.transliteration.lowercased()
        ]

        if let w = letter.weight {
            switch w {
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
                            .conditionalGlassEffect(clear: false)
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
                .conditionalGlassEffect(clear: false)

                HStack {
//                    SearchBar(text: $searchText.animation(.easeInOut)).conditionalGlassEffect(clear: false)
                    GlassSearchBar(searchText: $searchText.animation(.easeInOut))

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
                            .frame(width: 25, height: 25)
                            .foregroundColor(settings.accentColor.color)
                            .transition(.opacity)
                    }
                    .padding()
                    .conditionalGlassEffect(clear: false)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .dismissKeyboardOnScroll()
        .navigationTitle("Arabic Alphabet")
    }

    private func letterData(for glyph: String) -> LetterData? {
        standardArabicLetters.first { $0.letter == glyph } ??
        otherArabicLetters.first   { $0.letter == glyph } ??
        nonArabicArabicScriptLetters.first { $0.letter == glyph }
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
                Link(
                    "View More: Tajweed Rules & Stopping/Pausing Signs",
                    destination: url
                )
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
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
                    .font((settings.useFontArabic && !letterData.isNonArabicScriptLetter)
                          ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                          : .title2)
                    .foregroundColor(settings.accentColor.color)
            }
            .padding(.vertical, -2)
        }
        #if !os(watchOS)
        .swipeActions(edge: .leading) { favButton(isFav: isFav) }
        .swipeActions(edge: .trailing){ favButton(isFav: isFav) }
        .contextMenu { contextItems(isFav: isFav) }
        #endif
    }

    @ViewBuilder private func favButton(isFav: Bool) -> some View {
        Button {
            settings.hapticFeedback()
            settings.toggleLetterFavorite(letterData: letterData)
        } label: {
            Image(systemName: isFav ? "star.fill" : "star")
        }
        .tint(settings.accentColor.color)
    }

    @ViewBuilder private func contextItems(isFav: Bool) -> some View {
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
        } label: { Label("Copy Letter", systemImage: "doc.on.doc") }

        Button {
            UIPasteboard.general.string = letterData.transliteration
            settings.hapticFeedback()
        } label: { Label("Copy Transliteration", systemImage: "doc.on.doc") }
        #endif
    }
}

struct ArabicNumberRow: View {
    @EnvironmentObject private var settings: Settings
    let numberData: (number: String, name: String, transliteration: String, englishNumber: String)

    var body: some View {
        HStack {
            Text(numberData.englishNumber).font(.title3)

            Spacer()

            VStack(alignment: .center) {
                Text(numberData.name)
                    .font(settings.useFontArabic
                          ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize)
                          : .subheadline)
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
            Text(title).font(.subheadline)
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
