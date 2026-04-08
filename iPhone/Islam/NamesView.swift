import SwiftUI

struct NameOfAllah: Decodable, Identifiable {
    let number: Int
    let id: String
    let name: String
    let transliteration: String
    let found: String
    let meaning: String
    let otherNames: [String]
    let desc: String
    let numberArabic: String
    let searchTokens: [String]
    let firstFoundSurah: Int?
    let firstFoundAyah: Int?

    enum CodingKeys: String, CodingKey {
        case name, transliteration, number, found, meaning, otherNames, desc
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        number = try c.decode(Int.self, forKey: .number)
        name = try c.decode(String.self, forKey: .name)
        transliteration = try c.decode(String.self, forKey: .transliteration)
        found = try c.decode(String.self, forKey: .found)
        meaning = try c.decode(String.self, forKey: .meaning)
        otherNames = try c.decodeIfPresent([String].self, forKey: .otherNames) ?? []
        desc = try c.decode(String.self, forKey: .desc)

        id = "\(number)"
        numberArabic = arabicNumberString(from: number)
        let firstFound = Self.parseFirstFound(found)
        firstFoundSurah = firstFound?.surah
        firstFoundAyah = firstFound?.ayah

        searchTokens = [
            Self.clean(name),
            Self.clean(transliteration),
            Self.clean(meaning),
            otherNames.map(Self.clean).joined(separator: " "),
            Self.clean(desc),
            Self.clean(found),
            "\(number)",
            numberArabic
        ]
    }

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s
            .normalizingArabicIndicDigitsToWestern
            .filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }

    private static func parseFirstFound(_ found: String) -> (surah: Int, ayah: Int)? {
        let pattern = #"\((\d+)\s*:\s*(\d+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let fullRange = NSRange(found.startIndex..<found.endIndex, in: found)
        guard let match = regex.firstMatch(in: found, range: fullRange), match.numberOfRanges >= 3,
              let surahRange = Range(match.range(at: 1), in: found),
              let ayahRange = Range(match.range(at: 2), in: found),
              let surah = Int(found[surahRange]),
              let ayah = Int(found[ayahRange]) else {
            return nil
        }
        return (surah, ayah)
    }

    var firstFoundShort: String {
        guard let closingParen = found.firstIndex(of: ")") else { return found }
        return String(found[...closingParen])
    }
}

final class NamesViewModel: ObservableObject {
    static let shared = NamesViewModel()

    @Published var namesOfAllah: [NameOfAllah] = []
    @Published private(set) var firstFoundTargetsByNameNumber: [Int: (surahID: Int, ayahID: Int)] = [:]
    private var filterCache = [String: [NameOfAllah]]()

    private init() { loadJSON() }

    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "NamesOfAllah", withExtension: "json") else {
            logger.debug("❌ 99 Names JSON not found."); return
        }
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let names = (try? decoder.decode([NameOfAllah].self, from: data)) ?? []
                var targets = [Int: (surahID: Int, ayahID: Int)]()
                targets.reserveCapacity(names.count)
                for name in names {
                    guard let surah = name.firstFoundSurah,
                          let ayah = name.firstFoundAyah else { continue }
                    targets[name.number] = (surahID: surah, ayahID: ayah)
                }
                DispatchQueue.main.async {
                    self.namesOfAllah = names
                    self.firstFoundTargetsByNameNumber = targets
                    self.filterCache.removeAll()
                }
            } catch {
                logger.debug("❌ JSON decode error: \(error)")
            }
        }
    }

    func filteredNames(cleanedQuery: String) -> [NameOfAllah] {
        guard !cleanedQuery.isEmpty else { return namesOfAllah }

        if let cached = filterCache[cleanedQuery] {
            return cached
        }

        let matches = namesOfAllah.filter { name in
            if cleanedQuery.allSatisfy(\.isNumber), let n = Int(cleanedQuery) {
                return name.number == n
            }
            return name.searchTokens.contains { $0.contains(cleanedQuery) } || Int(cleanedQuery) == name.number
        }
        filterCache[cleanedQuery] = matches
        return matches
    }
}

struct NamesView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var namesData: NamesViewModel

    @State private var searchText = ""
    @State private var expandedNameNumbers = Set<Int>()

    private var cleanedSearch: String { Self.clean(searchText) }

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s
            .normalizingArabicIndicDigitsToWestern
            .filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }

    private var filteredNames: [NameOfAllah] {
        namesData.filteredNames(cleanedQuery: cleanedSearch)
    }

    var body: some View {
        let hasActiveSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        ScrollViewReader { proxy in
            List {
                descriptionSection(resultCount: filteredNames.count, hasActiveSearch: hasActiveSearch)
                namesSections(filteredNames: filteredNames, hasActiveSearch: hasActiveSearch, proxy: proxy)
                finalInvocationSection
            }
        }
        #if os(watchOS)
        .searchable(text: $searchText)
        #else
        .safeAreaInset(edge: .bottom) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .dismissKeyboardOnScroll()
        .navigationTitle("99 Names of Allah")
    }

    private func descriptionSection(resultCount: Int, hasActiveSearch: Bool) -> some View {
        Section(header: descriptionHeader(resultCount: resultCount, hasActiveSearch: hasActiveSearch)) {
            Text("Prophet Muhammad ﷺ said, “Allah has 99 names, and whoever believes in their meanings and acts accordingly, will enter Paradise” (Bukhari 6410).")
                .font(.body)

            Toggle("Show Description", isOn: $settings.showDescription.animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
        }
    }

    private func descriptionHeader(resultCount: Int, hasActiveSearch: Bool) -> some View {
        HStack {
            Text("DESCRIPTION")

            Spacer()

            Text(String(resultCount))
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .opacity(hasActiveSearch ? 1 : 0)
        }
    }

    @ViewBuilder
    private func namesSections(filteredNames: [NameOfAllah], hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        ForEach(filteredNames, id: \.id) { name in
            Section(header: nameSectionHeader(name: name, target: namesData.firstFoundTargetsByNameNumber[name.number])) {
                NameRow(
                    name: name,
                    showDescription: settings.showDescription,
                    isExpanded: expandedNameNumbers.contains(name.number)
                ) {
                    handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                }
            }
            .id("name_\(name.number)")
        }
    }

    private func nameSectionHeader(name: NameOfAllah, target: (surahID: Int, ayahID: Int)?) -> some View {
        #if os(iOS)
        HStack {
            Text("NAME \(name.number)")
            
            Spacer()

            if let target {
                NavigationLink(destination: ayahsDestination(for: target)) {
                    Image(systemName: "character.book.closed.ar")
                        .padding(4)
                        .conditionalGlassEffect()
                }
            }
        }
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private func ayahsDestination(for target: (surahID: Int, ayahID: Int)) -> some View {
        if let surah = quranData.surah(target.surahID) {
            AyahsView(surah: surah, ayah: target.ayahID)
        } else {
            Text("Reference not found")
        }
    }

    private func handleNameTap(name: NameOfAllah, hasActiveSearch: Bool, proxy: ScrollViewProxy) {
        if hasActiveSearch {
            let targetID = "name_\(name.number)"
            withAnimation {
                searchText = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    proxy.scrollTo(targetID, anchor: .top)
                }
            }
        } else {
            withAnimation {
                if expandedNameNumbers.contains(name.number) {
                    expandedNameNumbers.remove(name.number)
                } else {
                    expandedNameNumbers.insert(name.number)
                }
            }
        }
    }

    private var finalInvocationSection: some View {
        Section(header: Text("AFTER THE 99 NAMES")) {
            Text("Call upon Allah or call upon Ar-Rahman. Whichever Name you call, to Him belong the Most Beautiful Names.")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Surah Al-Isra 17:110")
                .font(.caption)
                .foregroundStyle(.secondary)

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:21",
                body: "If this Quran were sent upon a mountain, it would humble and break from awe of Allah. These examples are given so people reflect."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:22",
                body: "He is Allah, none is worthy of worship except Him. Knower of the seen and unseen, the Most Compassionate, the Most Merciful."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:23",
                body: "He is Allah: the King, the Most Holy, the Source of Peace, the Guardian, the Almighty, the Compeller, the Supreme. Exalted is He above all partners."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:24",
                body: "He is Allah, the Creator, the Originator, the Fashioner. To Him belong the Most Beautiful Names; all in the heavens and earth glorify Him."
            )
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        NamesView()
    }
}

private struct NameRow: View {
    @EnvironmentObject var settings: Settings
    let name: NameOfAllah
    let showDescription: Bool
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        #if os(iOS)
        content.contextMenu { copyMenu }
        #else
        content
        #endif
    }

    private var content: some View {
        Group {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("First Found: \(name.firstFoundShort)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(name.meaning).font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(name.name.removeDiacriticsFromLastLetter()) - \(name.numberArabic)")
                            .font(.headline)
                            .foregroundColor(settings.accentColor.color)
                        
                        Text("\(name.transliteration) - \(name.number)")
                            .font(.subheadline)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            .padding(.vertical, 4)
            
            if isExpanded {
                NameRowDetails(name: name, showDescription: showDescription, isExpanded: isExpanded)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !showDescription {
                settings.hapticFeedback()
                onTap()
            }
        }
    }

    #if os(iOS)
    private var copyMenu: some View {
        Group {
            menuItem("Copy All", text: """
            Arabic: \(name.name.removeDiacriticsFromLastLetter())
            Transliteration: \(name.transliteration)
            Translation: \(name.meaning)
            First Found: \(name.firstFoundShort)
            Description: \(name.desc)
            """)
            menuItem("Copy Arabic", text: name.name.removeDiacriticsFromLastLetter())
            menuItem("Copy Transliteration", text: name.transliteration)
            menuItem("Copy Translation", text: name.meaning)
            menuItem("Copy First Found", text: name.firstFoundShort)
            menuItem("Copy Description", text: name.desc)
        }
    }

    private func menuItem(_ label: String, text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            settings.hapticFeedback()
        } label: {
            Label(label, systemImage: "doc.on.doc")
        }
    }
    #endif
}

private struct NameRowDetails: View {
    @EnvironmentObject var settings: Settings
    let name: NameOfAllah
    let showDescription: Bool
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if showDescription || isExpanded {
                if !name.otherNames.isEmpty {
                    HStack {
                        Text("Other Names:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text(name.otherNames.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity)
                }

                Text(name.desc)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .padding(.top, 2)
            }
        }
    }
}

private struct VerseReflectionCard: View {
    let title: String
    let body: String

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    var body: some View {
        bodyView
    }
}
