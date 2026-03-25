import SwiftUI

struct Root: Decodable {
    let code: Int
    let status: String
    let data: [NameOfAllah]
}

struct NameTranslation: Decodable {
    let meaning: String
    let desc: String
}

struct NameOfAllah: Decodable, Identifiable {
    let number: Int
    let id: String
    let name: String
    let transliteration: String
    let found: String
    let meaning: String
    let desc: String
    let numberArabic: String
    let searchTokens: [String]

    enum CodingKeys: String, CodingKey {
        case name, transliteration, number, found, meaning, desc, en
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        number = try c.decode(Int.self, forKey: .number)
        name = try c.decode(String.self, forKey: .name)
        transliteration = try c.decode(String.self, forKey: .transliteration)
        found = try c.decode(String.self, forKey: .found)

        if let topLevelMeaning = try c.decodeIfPresent(String.self, forKey: .meaning),
           let topLevelDesc = try c.decodeIfPresent(String.self, forKey: .desc) {
            meaning = topLevelMeaning
            desc = topLevelDesc
        } else {
            let en = try c.decode(NameTranslation.self, forKey: .en)
            meaning = en.meaning
            desc = en.desc
        }

        id = "\(number)"
        numberArabic = arabicNumberString(from: number)

        searchTokens = [
            Self.clean(name),
            Self.clean(transliteration),
            Self.clean(meaning),
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

    var firstFoundShort: String {
        guard let closingParen = found.firstIndex(of: ")") else { return found }
        return String(found[...closingParen])
    }
}

final class NamesViewModel: ObservableObject {
    static let shared = NamesViewModel()

    @Published var namesOfAllah: [NameOfAllah] = []

    private init() { loadJSON() }

    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "99_Names_Of_Allah", withExtension: "json") else {
            logger.debug("❌ 99 Names JSON not found."); return
        }
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let decoder = JSONDecoder()

                if let names = try? decoder.decode([NameOfAllah].self, from: data) {
                    DispatchQueue.main.async { self.namesOfAllah = names }
                    return
                }

                let root = try decoder.decode(Root.self, from: data)
                DispatchQueue.main.async { self.namesOfAllah = root.data }
            } catch {
                logger.debug("❌ JSON decode error: \(error)")
            }
        }
    }
}

struct NamesView: View {
    @EnvironmentObject var settings: Settings
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

    private func matches(_ name: NameOfAllah) -> Bool {
        guard !cleanedSearch.isEmpty else { return true }
        if cleanedSearch.allSatisfy(\.isNumber), let n = Int(cleanedSearch) {
            return name.number == n
        }
        return name.searchTokens.contains { $0.contains(cleanedSearch) } || Int(cleanedSearch) == name.number
    }

    var body: some View {
        let filteredNames = namesData.namesOfAllah.filter(matches)
        let hasActiveSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        ScrollViewReader { proxy in
            List {
                Section(header:
                    HStack {
                        Text("DESCRIPTION")

                        Spacer()

                        Text(String(filteredNames.count))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            #if !os(watchOS)
                            .background(.ultraThinMaterial)
                            #endif
                            .clipShape(Capsule())
                            .conditionalGlassEffect()
                            .opacity(hasActiveSearch ? 1 : 0)
                    }
                    .padding(.vertical, 4)
                ) {
                    Text("Prophet Muhammad ﷺ said, “Allah has 99 names, and whoever believes in their meanings and acts accordingly, will enter Paradise” (Bukhari 6410).")
                        .font(.body)

                    Toggle("Show Description", isOn: $settings.showDescription.animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                }

                ForEach(Array(filteredNames.enumerated()), id: \.element.id) { _, name in
                    Section {
                        NameRow(
                            name: name,
                            showDescription: settings.showDescription,
                            isExpanded: expandedNameNumbers.contains(name.number)
                        ) {
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
                    }
                    .id("name_\(name.number)")
                }
            }
        }
        #if os(watchOS)
        .searchable(text: $searchText)
        #else
        .safeAreaInset(edge: .bottom) {
            GlassSearchBar(text: $searchText.animation(.easeInOut))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .dismissKeyboardOnScroll()
        .navigationTitle("99 Names of Allah")
    }
}

private struct NameRow: View {
    @EnvironmentObject var settings: Settings
    let name: NameOfAllah
    let showDescription: Bool
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        #if !os(watchOS)
        content.contextMenu { copyMenu }
        #else
        content
        #endif
    }

    private var content: some View {
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

            if showDescription || isExpanded {
                Text(name.desc)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !showDescription {
                settings.hapticFeedback()
                onTap()
            }
        }
    }

    #if !os(watchOS)
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
