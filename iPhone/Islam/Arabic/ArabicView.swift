import SwiftUI

struct ArabicView: View {
    @EnvironmentObject private var settings: Settings
    @State private var searchText = ""
    @AppStorage("groupingType") private var groupingType: String = "normal"

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
        guard !searchText.isEmpty else { return otherArabicLetters }
        let st = searchText.lowercased()
        return otherArabicLetters.filter {
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

    var body: some View {
        VStack {
            List {
                if searchText.isEmpty, !settings.favoriteLetters.isEmpty {
                    Section("FAVORITE LETTERS") {
                        ForEach(settings.favoriteLetters.sorted(), id: \.id) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }
                }

                if searchText.isEmpty {
                    if groupingType == "normal" {
                        Section("STANDARD ARABIC LETTERS") {
                            ForEach(standardArabicLetters, id: \.letter) {
                                ArabicLetterRow(letterData: $0)
                            }
                        }
                    } else {
                        ForEach(similarityGroups.indices, id: \.self) { idx in
                            let group = similarityGroups[idx]
                            let header = idx == 0 ? "VOWEL LETTERS" : group.joined(separator: " AND")
                            Section(header) {
                                ForEach(group, id: \.self) { ch in
                                    letterData(for: ch).map(ArabicLetterRow.init)
                                }
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
                } else {
                    Section("SEARCH RESULTS (\(filteredStandard.count + filteredOther.count))") {
                        ForEach(filteredStandard) {
                            ArabicLetterRow(letterData: $0)
                        }
                        
                        ForEach(filteredOther) {
                            ArabicLetterRow(letterData: $0)
                        }
                    }
                }
            }
            #if os(watchOS)
            .searchable(text: $searchText)
            #endif
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .dismissKeyboardOnScroll()

            #if !os(watchOS)
            Picker("Grouping", selection: $groupingType.animation(.easeInOut)) {
                Text("Normal Grouping").tag("normal")
                Text("Group by Similarity").tag("similarity")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            SearchBar(text: $searchText.animation(.easeInOut))
                .padding(.horizontal, 8)
            #endif
        }
        .navigationTitle("Arabic Alphabet")
    }

    private func letterData(for glyph: String) -> LetterData? {
        standardArabicLetters.first { $0.letter == glyph } ??
        otherArabicLetters.first   { $0.letter == glyph }
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

            Link("View More: Tajweed Rules & Stopping/Pausing Signs",
                 destination: URL(string: "https://studioarabiya.com/blog/tajweed-rules-stopping-pausing-signs/")!)
            .font(.subheadline)
            .foregroundColor(settings.accentColor.color)
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
                    .font(settings.useFontArabic
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
