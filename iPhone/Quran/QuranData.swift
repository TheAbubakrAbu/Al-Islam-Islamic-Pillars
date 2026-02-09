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
}

struct Ayah: Codable, Identifiable {
    let id: Int
    let idArabic: String

    let textHafs: String
    let textTransliteration: String
    let textEnglishSaheeh: String
    let textEnglishMustafa: String

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
        textWarsh = try c.decodeIfPresent(String.self, forKey: .textWarsh)
        textQaloon = try c.decodeIfPresent(String.self, forKey: .textQaloon)
        textDuri = try c.decodeIfPresent(String.self, forKey: .textDuri)
        textBuzzi = try c.decodeIfPresent(String.self, forKey: .textBuzzi)
        textQunbul = try c.decodeIfPresent(String.self, forKey: .textQunbul)
        textShubah = try c.decodeIfPresent(String.self, forKey: .textShubah)
        textSusi = try c.decodeIfPresent(String.self, forKey: .textSusi)
        idArabic = arabicNumberString(from: id)
    }

    init(id: Int, idArabic: String, textHafs: String, textTransliteration: String, textEnglishSaheeh: String, textEnglishMustafa: String, textWarsh: String?, textQaloon: String?, textDuri: String?, textBuzzi: String?, textQunbul: String?, textShubah: String?, textSusi: String?) {
        self.id = id
        self.idArabic = idArabic
        self.textHafs = textHafs
        self.textTransliteration = textTransliteration
        self.textEnglishSaheeh = textEnglishSaheeh
        self.textEnglishMustafa = textEnglishMustafa
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
        guard let url = Bundle.main.url(forResource: "quran", withExtension: "json") else {
            fatalError("quran.json missing")
        }

        do {
            let data = try Data(contentsOf: url)
            var surahs = try JSONDecoder().decode([Surah].self, from: data)

            let overlay = loadQiraatOverlay()
            if !overlay.isEmpty {
                surahs = surahs.map { surah in
                    let ayahs = surah.ayahs.map { ayah in
                        let textWarsh = overlay["textWarsh"]?[surah.id]?[ayah.id]
                        let textQaloon = overlay["textQaloon"]?[surah.id]?[ayah.id]
                        let textDuri = overlay["textDuri"]?[surah.id]?[ayah.id]
                        let textBuzzi = overlay["textBuzzi"]?[surah.id]?[ayah.id]
                        let textQunbul = overlay["textQunbul"]?[surah.id]?[ayah.id]
                        let textShubah = overlay["textShubah"]?[surah.id]?[ayah.id]
                        let textSusi = overlay["textSusi"]?[surah.id]?[ayah.id]
                        return Ayah(id: ayah.id, idArabic: ayah.idArabic, textHafs: ayah.textHafs, textTransliteration: ayah.textTransliteration, textEnglishSaheeh: ayah.textEnglishSaheeh, textEnglishMustafa: ayah.textEnglishMustafa, textWarsh: textWarsh, textQaloon: textQaloon, textDuri: textDuri, textBuzzi: textBuzzi, textQunbul: textQunbul, textShubah: textShubah, textSusi: textSusi)
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

            await MainActor.run {
                self.surahIndex = sIndex
                self.ayahIndex = aIndex
                self.quran = surahsToPublish
                self.verseIndex = vIndex
                self.cachedVerseIndexQiraah = displayQiraah ?? ""
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
            nameArabic: "تِلْكَ ٱلْرُّسُلُ",
            nameTransliteration: "Tilka Rusulu",
            startSurah: 2, startAyah: 253,
            endSurah: 3, endAyah: 92
        ),

        Juz(id: 4,
            nameArabic: "لَنْ تَنالُوا",
            nameTransliteration: "Lan Tanaaloo",
            startSurah: 3, startAyah: 93,
            endSurah: 4, endAyah: 23
        ),

        Juz(id: 5,
            nameArabic: "وَٱلْمُحْصَنَاتُ",
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
            nameArabic: "وَلَوْ أَنَّنَا",
            nameTransliteration: "Walau Annanaa",
            startSurah: 6, startAyah: 111,
            endSurah: 7, endAyah: 87
        ),

        Juz(id: 9,
            nameArabic: "قَالَ ٱلْمَلَأُ",
            nameTransliteration: "Qaalal-Mala'u",
            startSurah: 7, startAyah: 88,
            endSurah: 8, endAyah: 40
        ),

        Juz(id: 10,
            nameArabic: "وَٱعْلَمُواْ",
            nameTransliteration: "Wa'alamu",
            startSurah: 8, startAyah: 41,
            endSurah: 9, endAyah: 92
        ),

        Juz(id: 11,
            nameArabic: "يَعْتَذِرُونَ",
            nameTransliteration: "Ya'atadheroon",
            startSurah: 9, startAyah: 93,
            endSurah: 11, endAyah: 5
        ),

        Juz(id: 12,
            nameArabic: "وَمَا مِنْ دَآبَّةٍ",
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
            nameArabic: "سُبْحَانَ ٱلَّذِى",
            nameTransliteration: "Subhana Allathee",
            startSurah: 17, startAyah: 1,
            endSurah: 18, endAyah: 74
        ),

        Juz(id: 16,
            nameArabic: "قَالَ أَلَمْ",
            nameTransliteration: "Qaala Alam",
            startSurah: 18, startAyah: 75,
            endSurah: 20, endAyah: 135
        ),

        Juz(id: 17,
            nameArabic: "ٱقْتَرَبَ لِلْنَّاسِ",
            nameTransliteration: "Iqtaraba Linnaasi",
            startSurah: 21, startAyah: 1,
            endSurah: 22, endAyah: 78
        ),

        Juz(id: 18,
            nameArabic: "قَدْ أَفْلَحَ",
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
            nameArabic: "أَمَّنْ خَلَقَ",
            nameTransliteration: "A'man Khalaqa",
            startSurah: 27, startAyah: 56,
            endSurah: 29, endAyah: 45
        ),

        Juz(id: 21,
            nameArabic: "أُتْلُ مَاأُوْحِیَ",
            nameTransliteration: "Utlu Maa Oohia",
            startSurah: 29, startAyah: 46,
            endSurah: 33, endAyah: 30
        ),

        Juz(id: 22,
            nameArabic: "وَمَنْ يَّقْنُتْ",
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
            nameArabic: "فَمَنْ أَظْلَمُ",
            nameTransliteration: "Faman Adhlamu",
            startSurah: 39, startAyah: 32,
            endSurah: 41, endAyah: 46
        ),

        Juz(id: 25,
            nameArabic: "إِلَيْهِ يُرَدُّ",
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
            nameArabic: "قَالَ فَمَا خَطْبُكُم",
            nameTransliteration: "Qaala Famaa Khatbukum",
            startSurah: 51, startAyah: 31,
            endSurah: 57, endAyah: 29
        ),

        Juz(id: 28,
            nameArabic: "قَدْ سَمِعَ ٱللهُ",
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
