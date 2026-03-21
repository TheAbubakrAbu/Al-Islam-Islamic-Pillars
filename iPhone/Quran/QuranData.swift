import SwiftUI

struct Surah: Codable, Identifiable {
    let id: Int
    let idArabic: String

    let nameArabic: String
    let nameTransliteration: String
    let nameEnglish: String

    let type: String
    let numberOfAyahs: Int

    let ayahs: [Ayah]

    enum CodingKeys: String, CodingKey {
        case id, nameArabic, nameTransliteration, nameEnglish, type, numberOfAyahs, ayahs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        nameArabic = try c.decode(String.self, forKey: .nameArabic)
        nameTransliteration = try c.decode(String.self, forKey: .nameTransliteration)
        nameEnglish = try c.decode(String.self, forKey: .nameEnglish)
        type = try c.decode(String.self, forKey: .type)
        numberOfAyahs = try c.decode(Int.self, forKey: .numberOfAyahs)
        ayahs = try c.decode([Ayah].self, forKey: .ayahs)

        idArabic = arabicNumberString(from: id)
    }

    init(id: Int, idArabic: String, nameArabic: String, nameTransliteration: String, nameEnglish: String, type: String, numberOfAyahs: Int, ayahs: [Ayah]) {
        self.id = id
        self.idArabic = idArabic
        self.nameArabic = nameArabic
        self.nameTransliteration = nameTransliteration
        self.nameEnglish = nameEnglish
        self.type = type
        self.numberOfAyahs = numberOfAyahs
        self.ayahs = ayahs
    }

    /// Ayah count for the given qiraah (e.g. Baqarah has 286 in Hafs but 285 in Warsh). Use for display and range selection.
    func numberOfAyahs(for displayQiraah: String?) -> Int {
        ayahs.filter { $0.existsInQiraah(displayQiraah) }.count
    }
}

struct Ayah: Codable, Identifiable {
    let id: Int
    let idArabic: String

    let textHafs: String
    let textTransliteration: String
    let textEnglishSaheeh: String
    let textEnglishMustafa: String

    let juz: Int?
    let page: Int?

    let textShubah: String?
    
    let textBuzzi: String?
    let textQunbul: String?
    
    let textWarsh: String?
    let textQaloon: String?
    
    let textDuri: String?
    let textSusi: String?

    enum CodingKeys: String, CodingKey {
        case id
        case textHafs = "textArabic"
        case textTransliteration, textEnglishSaheeh, textEnglishMustafa
        case juz, page
        case textWarsh, textQaloon, textDuri, textBuzzi, textQunbul, textShubah, textSusi
    }

    /// Raw Arabic for the given display qiraah. Nil = Hafs.
    func textArabic(for displayQiraah: String?) -> String {
        let raw: String? = {
            guard let q = displayQiraah else { return nil }
            if q.contains("Warsh") { return textWarsh }
            if q.contains("Qaloon") { return textQaloon }
            if q.contains("Duri") || q.contains("Doori") { return textDuri }
            if q.contains("Buzzi") || q.contains("Bazzi") { return textBuzzi }
            if q.contains("Qunbul") || q.contains("Qumbul") { return textQunbul }
            if q.contains("Shu'bah") || q.contains("Shouba") { return textShubah }
            if q.contains("Susi") || q.contains("Soosi") { return textSusi }
            return nil
        }()
        return (raw ?? textHafs).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clean (no diacritics) Arabic for the given display qiraah.
    func textCleanArabic(for displayQiraah: String?) -> String {
        textArabic(for: displayQiraah).removingArabicDiacriticsAndSigns
    }

    /// True if this ayah exists as its own verse in the given qiraah. In Hafs every ayah exists; in Warsh/Qaloon/etc. some Hafs ayahs are merged, so we only show ayahs that have qiraah-specific text (e.g. Baqarah has 286 in Hafs but 285 in Warsh).
    func existsInQiraah(_ displayQiraah: String?) -> Bool {
        guard let q = displayQiraah, !q.isEmpty, q != "Hafs" else {
            return !textHafs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if q.contains("Warsh") { return textWarsh != nil }
        if q.contains("Qaloon") { return textQaloon != nil }
        if q.contains("Duri") || q.contains("Doori") { return textDuri != nil }
        if q.contains("Buzzi") || q.contains("Bazzi") { return textBuzzi != nil }
        if q.contains("Qunbul") || q.contains("Qumbul") { return textQunbul != nil }
        if q.contains("Shu'bah") || q.contains("Shouba") { return textShubah != nil }
        if q.contains("Susi") || q.contains("Soosi") { return textSusi != nil }
        return true
    }

    /// Current riwayah's Arabic (uses Settings.displayQiraahForArabic). Used for display, search, share.
    var textArabic: String { textArabic(for: Settings.shared.displayQiraahForArabic) }
    var textCleanArabic: String { textCleanArabic(for: Settings.shared.displayQiraahForArabic) }

    /// Clean Bismillah (no diacritics). Shown for Fatiha 1 when the riwayah’s first ayah is ta'awwudh.
    static let bismillahCleanArabic = "بسم الله الرحمن الرحيم"

    /// Arabic to show in UI. For Fatiha ayah 1 with clean mode, if the ayah doesn’t start with بسم (e.g. ta'awwudh), shows Bismillah instead.
    /// - Parameter qiraahOverride: When non-nil, use this qiraah instead of Settings (e.g. comparison mode). Use "" for Hafs.
    func displayArabicText(surahId: Int, clean: Bool, qiraahOverride: String? = nil) -> String {
        let qiraah: String? = if let override = qiraahOverride {
            (override.isEmpty || override == "Hafs") ? nil : override
        } else {
            Settings.shared.displayQiraahForArabic
        }
        let text = clean ? textCleanArabic(for: qiraah) : textArabic(for: qiraah)
        if surahId == 1 && id == 1 && clean {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.hasPrefix("بسم") {
                return Self.bismillahCleanArabic
            }
        }
        return text
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        textHafs = try c.decode(String.self, forKey: .textHafs)
        textTransliteration = try c.decode(String.self, forKey: .textTransliteration)
        textEnglishSaheeh = try c.decode(String.self, forKey: .textEnglishSaheeh)
        textEnglishMustafa = try c.decode(String.self, forKey: .textEnglishMustafa)
        juz = try c.decodeIfPresent(Int.self, forKey: .juz)
        page = try c.decodeIfPresent(Int.self, forKey: .page)
        textWarsh = try c.decodeIfPresent(String.self, forKey: .textWarsh)
        textQaloon = try c.decodeIfPresent(String.self, forKey: .textQaloon)
        textDuri = try c.decodeIfPresent(String.self, forKey: .textDuri)
        textBuzzi = try c.decodeIfPresent(String.self, forKey: .textBuzzi)
        textQunbul = try c.decodeIfPresent(String.self, forKey: .textQunbul)
        textShubah = try c.decodeIfPresent(String.self, forKey: .textShubah)
        textSusi = try c.decodeIfPresent(String.self, forKey: .textSusi)
        idArabic = arabicNumberString(from: id)
    }

    init(id: Int, idArabic: String, textHafs: String, textTransliteration: String, textEnglishSaheeh: String, textEnglishMustafa: String, juz: Int? = nil, page: Int? = nil, textWarsh: String?, textQaloon: String?, textDuri: String?, textBuzzi: String?, textQunbul: String?, textShubah: String?, textSusi: String?) {
        self.id = id
        self.idArabic = idArabic
        self.textHafs = textHafs
        self.textTransliteration = textTransliteration
        self.textEnglishSaheeh = textEnglishSaheeh
        self.textEnglishMustafa = textEnglishMustafa
        self.juz = juz
        self.page = page
        self.textWarsh = textWarsh
        self.textQaloon = textQaloon
        self.textDuri = textDuri
        self.textBuzzi = textBuzzi
        self.textQunbul = textQunbul
        self.textShubah = textShubah
        self.textSusi = textSusi
    }

    /// Arabic to display; pass qiraah and whether to strip diacritics.
    func displayArabic(qiraah: String?, clean: Bool) -> String {
        clean ? textCleanArabic(for: qiraah) : textArabic(for: qiraah)
    }
}

final class QuranData: ObservableObject {
    static let shared: QuranData = {
        let q = QuranData()
        q.startLoading()
        return q
    }()

    private let settings = Settings.shared

    @Published private(set) var quran: [Surah] = []
    private(set) var verseIndex: [VerseIndexEntry] = []

    private var surahIndex = [Int:Int]()
    private var ayahIndex = [[Int:Int]]()
    /// Qiraah key the verse index was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedVerseIndexQiraah: String? = nil
    /// Qiraah key the boundary model was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedBoundaryQiraah: String? = nil
    private var surahBoundaryModels = [Int: SurahBoundaryModel]()

    private var loadTask: Task<Void, Never>?

    private init() {}

    private func startLoading() {
        loadTask = Task(priority: .userInitiated) { [weak self] in
            await self?.load()
        }
    }

    func waitUntilLoaded() async {
        await loadTask?.value
    }

    private struct QiraatAyahEntry: Codable {
        let id: Int
        let text: String?
        let textArabic: String?
        var displayText: String? { text ?? textArabic }
    }

    private static let qiraatKeys: [(filename: String, key: String)] = [
        ("QiraahWarsh", "textWarsh"),
        ("QiraahQaloon", "textQaloon"),
        ("QiraahDuri", "textDuri"),
        ("QiraahBuzzi", "textBuzzi"),
        ("QiraahQunbul", "textQunbul"),
        ("QiraahShubah", "textShubah"),
        ("QiraahSusi", "textSusi"),
    ]

    /// key (e.g. "textWarsh") -> surahId -> ayahId -> text
    private func loadQiraatOverlay() -> [String: [Int: [Int: String]]] {
        var result: [String: [Int: [Int: String]]] = [:]
        for (filename, key) in Self.qiraatKeys {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "JSONs/Qiraat")
                ?? Bundle.main.url(forResource: filename, withExtension: "json") else { continue }
            guard let data = try? Data(contentsOf: url),
                  let raw = try? JSONDecoder().decode([String: [QiraatAyahEntry]].self, from: data) else { continue }
            var bySurah: [Int: [Int: String]] = [:]
            for (surahStr, ayahs) in raw {
                guard let surahId = Int(surahStr) else { continue }
                var lookup: [Int: String] = [:]
                for entry in ayahs {
                    if let t = entry.displayText, !t.isEmpty { lookup[entry.id] = t }
                }
                bySurah[surahId] = lookup
            }
            result[key] = bySurah
        }
        return result
    }

    private func load() async {
        guard let url = Bundle.main.url(forResource: "Quran", withExtension: "json") else {
            fatalError("Quran.json missing")
        }

        do {
            let data = try Data(contentsOf: url)
            var surahs = try JSONDecoder().decode([Surah].self, from: data)

            let overlay = loadQiraatOverlay()
            if !overlay.isEmpty {
                surahs = surahs.map { surah in
                    let baseAyahsByID = Dictionary(uniqueKeysWithValues: surah.ayahs.map { ($0.id, $0) })

                    var allAyahIDs = Set(baseAyahsByID.keys)
                    for key in ["textWarsh", "textQaloon", "textDuri", "textBuzzi", "textQunbul", "textShubah", "textSusi"] {
                        if let overlayIDs = overlay[key]?[surah.id]?.keys {
                            allAyahIDs.formUnion(overlayIDs)
                        }
                    }

                    let ayahs = allAyahIDs.sorted().map { ayahID in
                        let base = baseAyahsByID[ayahID]

                        return Ayah(
                            id: ayahID,
                            idArabic: base?.idArabic ?? arabicNumberString(from: ayahID),
                            textHafs: base?.textHafs ?? "",
                            textTransliteration: base?.textTransliteration ?? "",
                            textEnglishSaheeh: base?.textEnglishSaheeh ?? "",
                            textEnglishMustafa: base?.textEnglishMustafa ?? "",
                            juz: base?.juz,
                            page: base?.page,
                            textWarsh: overlay["textWarsh"]?[surah.id]?[ayahID] ?? base?.textWarsh,
                            textQaloon: overlay["textQaloon"]?[surah.id]?[ayahID] ?? base?.textQaloon,
                            textDuri: overlay["textDuri"]?[surah.id]?[ayahID] ?? base?.textDuri,
                            textBuzzi: overlay["textBuzzi"]?[surah.id]?[ayahID] ?? base?.textBuzzi,
                            textQunbul: overlay["textQunbul"]?[surah.id]?[ayahID] ?? base?.textQunbul,
                            textShubah: overlay["textShubah"]?[surah.id]?[ayahID] ?? base?.textShubah,
                            textSusi: overlay["textSusi"]?[surah.id]?[ayahID] ?? base?.textSusi
                        )
                    }

                    return Surah(id: surah.id, idArabic: surah.idArabic, nameArabic: surah.nameArabic, nameTransliteration: surah.nameTransliteration, nameEnglish: surah.nameEnglish, type: surah.type, numberOfAyahs: surah.numberOfAyahs, ayahs: ayahs)
                }
            }

            let (sIndex, aIndex) = buildIndexes(for: surahs)
            let surahsToPublish = surahs
            let displayQiraah = settings.displayQiraahForArabic
            let vIndex = surahsToPublish.flatMap { surah in
                surah.ayahs.map { ayah in
                    let raw = ayah.textArabic(for: displayQiraah)
                    let clean = ayah.textCleanArabic(for: displayQiraah)
                    let arabicBlob = [raw, clean].map { settings.cleanSearch($0) }.joined(separator: " ")
                    let latinBlob = [
                        ayah.textEnglishSaheeh,
                        ayah.textEnglishMustafa,
                        ayah.textTransliteration
                    ].map { settings.cleanSearch($0) }.joined(separator: " ")
                    return VerseIndexEntry(
                        id: "\(surah.id):\(ayah.id)",
                        surah: surah.id,
                        ayah: ayah.id,
                        arabicBlob: arabicBlob,
                        englishBlob: latinBlob
                    )
                }
            }
            let boundaryModels = buildBoundaryModels(for: surahsToPublish, displayQiraah: displayQiraah)

            await MainActor.run {
                self.surahIndex = sIndex
                self.ayahIndex = aIndex
                self.quran = surahsToPublish
                self.verseIndex = vIndex
                self.cachedVerseIndexQiraah = displayQiraah ?? ""
                self.surahBoundaryModels = boundaryModels
                self.cachedBoundaryQiraah = displayQiraah ?? ""
            }
        } catch {
            fatalError("Failed to load Quran: \(error)")
        }
    }

    private func rebuildVerseIndex() {
        let displayQiraah = settings.displayQiraahForArabic
        verseIndex = quran.flatMap { surah in
            surah.ayahs.map { ayah in
                let raw = ayah.textArabic(for: displayQiraah)
                let clean = ayah.textCleanArabic(for: displayQiraah)
                let arabicBlob = [raw, clean].map { settings.cleanSearch($0) }.joined(separator: " ")
                let latinBlob = [
                    ayah.textEnglishSaheeh,
                    ayah.textEnglishMustafa,
                    ayah.textTransliteration
                ].map { settings.cleanSearch($0) }.joined(separator: " ")
                return VerseIndexEntry(
                    id: "\(surah.id):\(ayah.id)",
                    surah: surah.id,
                    ayah: ayah.id,
                    arabicBlob: arabicBlob,
                    englishBlob: latinBlob
                )
            }
        }
    }

    private func rebuildBoundaryModels() {
        let displayQiraah = settings.displayQiraahForArabic
        surahBoundaryModels = buildBoundaryModels(for: quran, displayQiraah: displayQiraah)
        cachedBoundaryQiraah = displayQiraah ?? ""
    }

    private func boundaryText(from oldAyah: Ayah, to newAyah: Ayah) -> String? {
        let pageChanged = oldAyah.page != newAyah.page
        let juzChanged = oldAyah.juz != newAyah.juz
        guard pageChanged || juzChanged else { return nil }

        if let page = newAyah.page, let juz = newAyah.juz {
            return "Page \(page) - Juz \(juz)"
        }
        if let page = newAyah.page {
            return "Page \(page)"
        }
        if let juz = newAyah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func boundaryText(for ayah: Ayah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "Page \(page) - Juz \(juz)"
        }
        if let page = ayah.page {
            return "Page \(page)"
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func boundaryStyle(pageChanged: Bool, juzChanged: Bool) -> BoundaryDividerStyle {
        if pageChanged {
            return juzChanged ? .allAccent : .pageAccentJuzSecondary
        }
        if juzChanged {
            return .allAccent
        }
        return .allSecondary
    }

    private func dividerModel(from text: String, style: BoundaryDividerStyle) -> BoundaryDividerModel {
        if let juzRange = text.range(of: "Juz ") {
            let prefix = String(text[..<juzRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if prefix.isEmpty {
                return BoundaryDividerModel(
                    text: text,
                    pageSegment: text,
                    juzSegment: nil,
                    style: style
                )
            }
            let pageSegment = prefix.trimmingCharacters(in: CharacterSet(charactersIn: " -•").union(.whitespacesAndNewlines))
            let juzSegment = String(text[juzRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return BoundaryDividerModel(
                text: text,
                pageSegment: pageSegment,
                juzSegment: juzSegment,
                style: style
            )
        }

        return BoundaryDividerModel(
            text: text,
            pageSegment: text,
            juzSegment: nil,
            style: style
        )
    }

    private func buildBoundaryModels(for surahs: [Surah], displayQiraah: String?) -> [Int: SurahBoundaryModel] {
        var result = [Int: SurahBoundaryModel]()
        result.reserveCapacity(surahs.count)

        for (index, surah) in surahs.enumerated() {
            let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(displayQiraah) }
            guard !ayahsForQiraah.isEmpty else {
                result[surah.id] = SurahBoundaryModel(
                    startDivider: nil,
                    startDividerHighlighted: false,
                    dividerBeforeAyah: [:],
                    endOfSurahDivider: nil,
                    endDivider: nil,
                    endDividerHighlighted: false
                )
                continue
            }

            let startDividerText = ayahsForQiraah.first.flatMap { boundaryText(for: $0) }
            let startDividerHighlighted: Bool = {
                guard index > 0,
                      let firstAyah = ayahsForQiraah.first else { return false }
                let previousSurah = surahs[index - 1]
                let previousLastAyah = previousSurah.ayahs.last { $0.existsInQiraah(displayQiraah) }
                guard let previousLastAyah else { return false }
                return previousLastAyah.page != firstAyah.page || previousLastAyah.juz != firstAyah.juz
            }()
            let startDividerStyle: BoundaryDividerStyle = {
                if surah.id == 1 { return .allGreen }
                guard index > 0,
                      let firstAyah = ayahsForQiraah.first else { return .allSecondary }
                let previousSurah = surahs[index - 1]
                let previousLastAyah = previousSurah.ayahs.last { $0.existsInQiraah(displayQiraah) }
                guard let previousLastAyah else { return .allSecondary }
                return boundaryStyle(
                    pageChanged: previousLastAyah.page != firstAyah.page,
                    juzChanged: previousLastAyah.juz != firstAyah.juz
                )
            }()

            var dividerBeforeAyah = [Int: BoundaryDividerModel]()
            if ayahsForQiraah.count > 1 {
                for i in 1..<ayahsForQiraah.count {
                    let prev = ayahsForQiraah[i - 1]
                    let current = ayahsForQiraah[i]
                    if let text = boundaryText(from: prev, to: current) {
                        dividerBeforeAyah[current.id] = dividerModel(
                            from: text,
                            style: boundaryStyle(pageChanged: prev.page != current.page, juzChanged: prev.juz != current.juz)
                        )
                    }
                }
            }

            var endDividerText: String? = nil
            var endDividerHighlighted = false
            var endOfSurahDividerText: String? = nil
            var endBoundaryJuzChanged = false
            var endBoundaryPageChanged = false
            var nextFirstAyah: Ayah? = nil
            if index + 1 < surahs.count {
                let nextSurah = surahs[index + 1]
                if let lastAyah = ayahsForQiraah.last,
                   let nextAyah = nextSurah.ayahs.first(where: { $0.existsInQiraah(displayQiraah) }) {
                    nextFirstAyah = nextAyah
                    endDividerText = boundaryText(from: lastAyah, to: nextAyah)
                    endBoundaryPageChanged = lastAyah.page != nextAyah.page
                    endBoundaryJuzChanged = lastAyah.juz != nextAyah.juz
                    endDividerHighlighted = lastAyah.page != nextAyah.page || lastAyah.juz != nextAyah.juz
                }
            }

            if let nextFirstAyah {
                endOfSurahDividerText = boundaryText(for: nextFirstAyah)
            } else if let lastAyah = ayahsForQiraah.last {
                if let page = lastAyah.page {
                    if let juz = lastAyah.juz {
                        endOfSurahDividerText = "Page \(page) - Juz \(juz)"
                    } else {
                        endOfSurahDividerText = "Page \(page)"
                    }
                } else if let juz = lastAyah.juz {
                    endOfSurahDividerText = "Juz \(juz)"
                }
            }
            let endDividerStyle = boundaryStyle(pageChanged: endBoundaryPageChanged, juzChanged: endBoundaryJuzChanged)

            result[surah.id] = SurahBoundaryModel(
                startDivider: startDividerText.map { dividerModel(from: $0, style: startDividerStyle) },
                startDividerHighlighted: startDividerHighlighted,
                dividerBeforeAyah: dividerBeforeAyah,
                endOfSurahDivider: endOfSurahDividerText.map { dividerModel(from: $0, style: endDividerStyle) },
                endDivider: endDividerText.map { dividerModel(from: $0, style: endDividerStyle) },
                endDividerHighlighted: endDividerHighlighted
            )
        }

        return result
    }

    private func buildIndexes(for surahs: [Surah]) -> ([Int:Int], [[Int:Int]]) {
        let sIndex = Dictionary(uniqueKeysWithValues: surahs.enumerated().map { ($1.id, $0) })
        let aIndex = surahs.map { surah in
            Dictionary(uniqueKeysWithValues: surah.ayahs.enumerated().map { ($1.id, $0) })
        }
        return (sIndex, aIndex)
    }
    
    func surah(_ number: Int) -> Surah? {
        surahIndex[number].map { quran[$0] }
    }

    func ayah(surah: Int, ayah: Int) -> Ayah? {
        guard let sIdx = surahIndex[surah], let aIdx = ayahIndex[sIdx][ayah] else { return nil }
        return quran[sIdx].ayahs[aIdx]
    }

    func searchVerses(term raw: String, limit: Int = 10, offset: Int = 0) -> [VerseIndexEntry] {
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedVerseIndexQiraah != currentKey {
            rebuildVerseIndex()
            cachedVerseIndexQiraah = currentKey
        }
        guard !verseIndex.isEmpty else { return [] }

        let q = settings.cleanSearch(raw, whitespace: true)
        guard !q.isEmpty else { return [] }
        if q.rangeOfCharacter(from: .decimalDigits) != nil { return [] }

        let useArabic = raw.containsArabicLetters

        var results: [VerseIndexEntry] = []
        results.reserveCapacity(limit == .max ? 64 : min(limit, 64))

        var skipped = 0
        for entry in verseIndex {
            let haystack = useArabic ? entry.arabicBlob : entry.englishBlob
            if haystack.contains(q) {
                if skipped < offset { skipped += 1; continue }
                results.append(entry)
                if limit != .max, results.count >= limit { break }
            }
        }

        return results
    }

    func boundaryModel(forSurah surahID: Int) -> SurahBoundaryModel? {
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedBoundaryQiraah != currentKey {
            rebuildBoundaryModels()
        }
        return surahBoundaryModels[surahID]
    }
    
    func searchVersesAll(term raw: String) -> [VerseIndexEntry] {
        searchVerses(term: raw, limit: .max, offset: 0)
    }
    
    static let juzList: [Juz] = [
        Juz(id: 1,
            nameArabic: "آلم",
            nameTransliteration: "Alif Lam Meem",
            startSurah: 1, startAyah: 1,
            endSurah: 2, endAyah: 141
        ),

        Juz(id: 2,
            nameArabic: "سَيَقُولُ",
            nameTransliteration: "Sayaqoolu",
            startSurah: 2, startAyah: 142,
            endSurah: 2, endAyah: 252
        ),

        Juz(id: 3,
            nameArabic: "تِلكَ ٱلرُّسُلُ",
            nameTransliteration: "Tilka Rusulu",
            startSurah: 2, startAyah: 253,
            endSurah: 3, endAyah: 92
        ),

        Juz(id: 4,
            nameArabic: "لَن تَنالُوا",
            nameTransliteration: "Lan Tanaaloo",
            startSurah: 3, startAyah: 93,
            endSurah: 4, endAyah: 23
        ),

        Juz(id: 5,
            nameArabic: "وَٱلمُحصَنَاتُ",
            nameTransliteration: "Walmohsanaatu",
            startSurah: 4, startAyah: 24,
            endSurah: 4, endAyah: 147
        ),

        Juz(id: 6,
            nameArabic: "لَا يُحِبُّ ٱللهُ",
            nameTransliteration: "Laa Yuhibbu Allahu",
            startSurah: 4, startAyah: 148,
            endSurah: 5, endAyah: 81
        ),

        Juz(id: 7,
            nameArabic: "وَإِذَا سَمِعُوا",
            nameTransliteration: "Waidhaa Samioo",
            startSurah: 5, startAyah: 82,
            endSurah: 6, endAyah: 110
        ),

        Juz(id: 8,
            nameArabic: "وَلَو أَنَّنَا",
            nameTransliteration: "Walau Annanaa",
            startSurah: 6, startAyah: 111,
            endSurah: 7, endAyah: 87
        ),

        Juz(id: 9,
            nameArabic: "قَالَ ٱلمَلَأُ",
            nameTransliteration: "Qaalal-Mala'u",
            startSurah: 7, startAyah: 88,
            endSurah: 8, endAyah: 40
        ),

        Juz(id: 10,
            nameArabic: "وَٱعلَمُوا",
            nameTransliteration: "Wa'alamu",
            startSurah: 8, startAyah: 41,
            endSurah: 9, endAyah: 92
        ),

        Juz(id: 11,
            nameArabic: "يَعتَذِرُونَ",
            nameTransliteration: "Ya'atadheroon",
            startSurah: 9, startAyah: 93,
            endSurah: 11, endAyah: 5
        ),

        Juz(id: 12,
            nameArabic: "وَمَا مِن دَآبَّةٍ",
            nameTransliteration: "Wamaa Min Da'abatin",
            startSurah: 11, startAyah: 6,
            endSurah: 12, endAyah: 52
        ),

        Juz(id: 13,
            nameArabic: "وَمَا أُبَرِّئُ",
            nameTransliteration: "Wamaa Ubari'oo",
            startSurah: 12, startAyah: 53,
            endSurah: 14, endAyah: 52
        ),

        Juz(id: 14,
            nameArabic: "رُبَمَا",
            nameTransliteration: "Rubamaa",
            startSurah: 15, startAyah: 1,
            endSurah: 16, endAyah: 128
        ),

        Juz(id: 15,
            nameArabic: "سُبحَانَ ٱلَّذِى",
            nameTransliteration: "Subhana Allathee",
            startSurah: 17, startAyah: 1,
            endSurah: 18, endAyah: 74
        ),

        Juz(id: 16,
            nameArabic: "قَالَ أَلَم",
            nameTransliteration: "Qaala Alam",
            startSurah: 18, startAyah: 75,
            endSurah: 20, endAyah: 135
        ),

        Juz(id: 17,
            nameArabic: "ٱقتَرَبَ لِلنَّاسِ",
            nameTransliteration: "Iqtaraba Linnaasi",
            startSurah: 21, startAyah: 1,
            endSurah: 22, endAyah: 78
        ),

        Juz(id: 18,
            nameArabic: "قَد أَفلَحَ",
            nameTransliteration: "Qad Aflaha",
            startSurah: 23, startAyah: 1,
            endSurah: 25, endAyah: 20
        ),

        Juz(id: 19,
            nameArabic: "وَقَالَ ٱلَّذِينَ",
            nameTransliteration: "Waqaal Alladheena",
            startSurah: 25, startAyah: 21,
            endSurah: 27, endAyah: 55
        ),

        Juz(id: 20,
            nameArabic: "أَمَّن خَلَقَ",
            nameTransliteration: "A'man Khalaqa",
            startSurah: 27, startAyah: 56,
            endSurah: 29, endAyah: 45
        ),

        Juz(id: 21,
            nameArabic: "أُتلُ مَاأُوحِیَ",
            nameTransliteration: "Utlu Maa Oohia",
            startSurah: 29, startAyah: 46,
            endSurah: 33, endAyah: 30
        ),

        Juz(id: 22,
            nameArabic: "وَمَن يَّقنُت",
            nameTransliteration: "Waman Yaqnut",
            startSurah: 33, startAyah: 31,
            endSurah: 36, endAyah: 27
        ),

        Juz(id: 23,
            nameArabic: "وَمَآ لِي",
            nameTransliteration: "Wamaa Lee",
            startSurah: 36, startAyah: 28,
            endSurah: 39, endAyah: 31
        ),

        Juz(id: 24,
            nameArabic: "فَمَن أَظلَمُ",
            nameTransliteration: "Faman Adhlamu",
            startSurah: 39, startAyah: 32,
            endSurah: 41, endAyah: 46
        ),

        Juz(id: 25,
            nameArabic: "إِلَيهِ يُرَدُّ",
            nameTransliteration: "Ilayhi Yuraddu",
            startSurah: 41, startAyah: 47,
            endSurah: 45, endAyah: 37
        ),

        Juz(id: 26,
            nameArabic: "حم",
            nameTransliteration: "Haaa Meem",
            startSurah: 46, startAyah: 1,
            endSurah: 51, endAyah: 30
        ),

        Juz(id: 27,
            nameArabic: "قَالَ فَمَا خَطبُكُم",
            nameTransliteration: "Qaala Famaa Khatbukum",
            startSurah: 51, startAyah: 31,
            endSurah: 57, endAyah: 29
        ),

        Juz(id: 28,
            nameArabic: "قَد سَمِعَ ٱللهُ",
            nameTransliteration: "Qadd Samia Allahu",
            startSurah: 58, startAyah: 1,
            endSurah: 66, endAyah: 12
        ),

        Juz(id: 29,
            nameArabic: "تَبَارَكَ ٱلَّذِى",
            nameTransliteration: "Tabaraka Alladhee",
            startSurah: 67, startAyah: 1,
            endSurah: 77, endAyah: 50
        ),

        Juz(id: 30,
            nameArabic: "عَمَّ",
            nameTransliteration: "'Amma",
            startSurah: 78, startAyah: 1,
            endSurah: 114, endAyah: 6
        )
    ]
}
