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
}

struct Ayah: Codable, Identifiable {
    let id: Int
    let idArabic: String

    let textArabic: String
    let textCleanArabic: String

    let textTransliteration: String
    let textEnglishSaheeh: String
    let textEnglishMustafa: String

    enum CodingKeys: String, CodingKey {
        case id, textArabic, textTransliteration, textEnglishSaheeh, textEnglishMustafa
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        textArabic = try c.decode(String.self, forKey: .textArabic)
        textTransliteration = try c.decode(String.self, forKey: .textTransliteration)
        textEnglishSaheeh = try c.decode(String.self, forKey: .textEnglishSaheeh)
        textEnglishMustafa = try c.decode(String.self, forKey: .textEnglishMustafa)

        textCleanArabic = textArabic.removingArabicDiacriticsAndSigns
        idArabic = arabicNumberString(from: id)
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

    private func load() async {
        guard let url = Bundle.main.url(forResource: "quran", withExtension: "json") else {
            fatalError("quran.json missing")
        }

        do {
            let data = try Data(contentsOf: url)
            let surahs = try JSONDecoder().decode([Surah].self, from: data)
            let (sIndex, aIndex) = buildIndexes(for: surahs)

            let vIndex = surahs.flatMap { surah in
                surah.ayahs.map { ayah in
                    let blob = [
                        ayah.textArabic,
                        ayah.textCleanArabic,
                        ayah.textEnglishSaheeh,
                        ayah.textEnglishMustafa,
                        ayah.textTransliteration
                    ]
                    .map { settings.cleanSearch($0) }
                    .joined(separator: " ")

                    return VerseIndexEntry(
                        id: "\(surah.id):\(ayah.id)",
                        surah: surah.id,
                        ayah: ayah.id,
                        searchBlob: blob
                    )
                }
            }

            await MainActor.run {
                self.surahIndex = sIndex
                self.ayahIndex = aIndex
                self.quran = surahs
                self.verseIndex = vIndex
            }
        } catch {
            fatalError("Failed to load Quran: \(error)")
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
        guard !verseIndex.isEmpty else { return [] }

        let q = settings.cleanSearch(raw, whitespace: true)
        guard !q.isEmpty else { return [] }
        if q.rangeOfCharacter(from: .decimalDigits) != nil { return [] }

        var results: [VerseIndexEntry] = []
        results.reserveCapacity(limit == .max ? 64 : min(limit, 64))

        var skipped = 0
        for entry in verseIndex {
            if entry.searchBlob.contains(q) {
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
