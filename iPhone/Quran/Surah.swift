import SwiftUI

struct Juz: Codable, Identifiable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    let startSurah: Int
    let startAyah: Int
}

struct Surah: Codable, Identifiable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    let nameEnglish: String
    let type: String
    let numberOfAyahs: Int
    var ayahs: [Ayah]
    
    enum CodingKeys: String, CodingKey {
        case id
        case nameArabic = "name"
        case nameTransliteration = "transliteration"
        case nameEnglish = "translation"
        case type = "type"
        case numberOfAyahs = "total_verses"
        case ayahs = "verses"
    }
}

struct Ayah: Codable, Identifiable {
    let id: Int
    let textArabic: String
    var textClearArabic: String { textArabic.removingArabicDiacriticsAndSigns }
    let textTransliteration: String?
    var textEnglish: String?

    enum CodingKeys: String, CodingKey {
        case id
        case textArabic = "text"
        case textTransliteration = "transliteration"
        case textEnglish = "translation"
    }
}

struct BookmarkedAyah: Codable, Identifiable, Equatable {
    var id: String { "\(surah)-\(ayah)" }
    var surah: Int
    var ayah: Int
}

struct LastListenedSurah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    let currentDuration: Double
    let fullDuration: Double
}

struct Reciter: Comparable, Codable {
    let name: String
    let ayahIdentifier: String
    let ayahBitrate: String
    let surahLink: String

    static func < (lhs: Reciter, rhs: Reciter) -> Bool {
        return lhs.name < rhs.name
    }
}

let reciters = [
    Reciter(name: "Abdul Basit (Murattal)", ayahIdentifier: "ar.abdulbasitmurattal", ayahBitrate: "192", surahLink: "https://server7.mp3quran.net/basit/"),
    Reciter(name: "Abdul Basit (Mujawwad)", ayahIdentifier: "ar.abdulsamad", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Abdul Rahman Al-Sudais", ayahIdentifier: "ar.abdurrahmaansudais", ayahBitrate: "192", surahLink: "https://server11.mp3quran.net/sds/"),
    Reciter(name: "Abu Bakr Al-Shatri", ayahIdentifier: "ar.shaatree", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/shatri/"),
    Reciter(name: "Mishary Alafasy", ayahIdentifier: "ar.alafasy", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/afs/"),
    Reciter(name: "Hani Al-Rifai", ayahIdentifier: "ar.hanirifai", ayahBitrate: "192", surahLink: "https://server8.mp3quran.net/hani/"),
    
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.husary", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/"),
    Reciter(name: "Mahmoud Al-Hussary (Mujawwad)", ayahIdentifier: "ar.husarymujawwad", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/"),
    
    Reciter(name: "Maher Al-Muaiqly", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/"),
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/"),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Muhammad Jibreel", ayahIdentifier: "ar.muhammadjibreel", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/jbrl/"),
    Reciter(name: "Saud Al-Shuraim", ayahIdentifier: "ar.saoodshuraym", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/shur/")
].sorted()

class QuranData: ObservableObject {
    static let shared = QuranData()
    
    @Published var quran: [Surah] = []
    
    var juzList: [Juz] = [
        Juz(id: 1, nameArabic: "آلم", nameTransliteration: "Alif Lam Meem", startSurah: 1, startAyah: 1),
        Juz(id: 2, nameArabic: "سَيَقُولُ", nameTransliteration: "Sayaqoolu", startSurah: 2, startAyah: 142),
        Juz(id: 3, nameArabic: "تِلْكَ ٱلْرُّسُلُ", nameTransliteration: "Tilka Rusulu", startSurah: 2, startAyah: 253),
        Juz(id: 4, nameArabic: "ْلَنْ تَنالُوا", nameTransliteration: "Lan Tanaaloo", startSurah: 3, startAyah: 93),
        Juz(id: 5, nameArabic: "وَٱلْمُحْصَنَاتُ", nameTransliteration: "Walmohsanaatu", startSurah: 4, startAyah: 24),
        Juz(id: 6, nameArabic: "لَا يُحِبُّ ٱللهُ", nameTransliteration: "Laa Yuhibbu Allahu", startSurah: 4, startAyah: 148),
        Juz(id: 7, nameArabic: "ْوَإِذَا سَمِعُوا", nameTransliteration: "Waidhaa Samioo", startSurah: 5, startAyah: 82),
        Juz(id: 8, nameArabic: "وَلَوْ أَنَّنَا", nameTransliteration: "Walau Annanaa", startSurah: 6, startAyah: 111),
        Juz(id: 9, nameArabic: "قَالَ ٱلْمَلَأُ", nameTransliteration: "Qaalal-Mala'u", startSurah: 7, startAyah: 88),
        Juz(id: 10, nameArabic: "وَٱعْلَمُواْ", nameTransliteration: "Wa'alamu", startSurah: 8, startAyah: 41),
        Juz(id: 11, nameArabic: "يَعْتَذِرُونَ", nameTransliteration: "Ya'atadheroon", startSurah: 9, startAyah: 93),
        Juz(id: 12, nameArabic: "وَمَا مِنْ دَآبَّةٍ", nameTransliteration: "Wamaa Min Da'abatin", startSurah: 11, startAyah: 6),
        Juz(id: 13, nameArabic: "وَمَا أُبَرِّئُ", nameTransliteration: "Wamaa Ubari'oo", startSurah: 12, startAyah: 53),
        Juz(id: 14, nameArabic: "رُبَمَا", nameTransliteration: "Rubamaa", startSurah: 15, startAyah: 1),
        Juz(id: 15, nameArabic: "سُبْحَانَ ٱلَّذِى", nameTransliteration: "Subhana Allathee", startSurah: 17, startAyah: 1),
        Juz(id: 16, nameArabic: "قَالَ أَلَمْ", nameTransliteration: "Qaala Alam", startSurah: 18, startAyah: 75),
        Juz(id: 17, nameArabic: "ٱقْتَرَبَ لِلْنَّاسِ", nameTransliteration: "Iqtaraba Linnaasi", startSurah: 21, startAyah: 1),
        Juz(id: 18, nameArabic: "قَدْ أَفْلَحَ", nameTransliteration: "Qad Aflaha", startSurah: 23, startAyah: 1),
        Juz(id: 19, nameArabic: "وَقَالَ ٱلَّذِينَ", nameTransliteration: "Waqaal Alladheena", startSurah: 25, startAyah: 21),
        Juz(id: 20, nameArabic: "أَمَّنْ خَلَقَ", nameTransliteration: "A'man Khalaqa", startSurah: 27, startAyah: 56),
        Juz(id: 21, nameArabic: "أُتْلُ مَاأُوْحِیَ", nameTransliteration: "Utlu Maa Oohia", startSurah: 29, startAyah: 46),
        Juz(id: 22, nameArabic: "وَمَنْ يَّقْنُتْ", nameTransliteration: "Waman Yaqnut", startSurah: 33, startAyah: 31),
        Juz(id: 23, nameArabic: "وَمَآ لِي", nameTransliteration: "Wamaa Lee", startSurah: 36, startAyah: 28),
        Juz(id: 24, nameArabic: "فَمَنْ أَظْلَمُ", nameTransliteration: "Faman Adhlamu", startSurah: 39, startAyah: 32),
        Juz(id: 25, nameArabic: "إِلَيْهِ يُرَدُّ", nameTransliteration: "Ilayhi Yuraddu", startSurah: 41, startAyah: 47),
        Juz(id: 26, nameArabic: "حم", nameTransliteration: "Haaa Meem", startSurah: 46, startAyah: 1),
        Juz(id: 27, nameArabic: "قَالَ فَمَا خَطْبُكُم", nameTransliteration: "Qaala Famaa Khatbukum", startSurah: 51, startAyah: 31),
        Juz(id: 28, nameArabic: "قَدْ سَمِعَ ٱللهُ", nameTransliteration: "Qadd Samia Allahu", startSurah: 58, startAyah: 1),
        Juz(id: 29, nameArabic: "تَبَارَكَ ٱلَّذِى", nameTransliteration: "Tabaraka Alladhee", startSurah: 67, startAyah: 1),
        Juz(id: 30, nameArabic: "عَمَّ", nameTransliteration: "'Amma", startSurah: 78, startAyah: 1)
    ]

    init() {
        loadQuranData()
    }

    private func loadQuranData() {
        guard let quranUrl = Bundle.main.url(forResource: "quran", withExtension: "json"),
              let quranEnUrl = Bundle.main.url(forResource: "quran_en", withExtension: "json") else {
            return
        }
        
        do {
            let quranData = try Data(contentsOf: quranUrl)
            var quran = try JSONDecoder().decode([Surah].self, from: quranData)
            
            let quranEnData = try Data(contentsOf: quranEnUrl)
            let quranEnJson = try JSONSerialization.jsonObject(with: quranEnData, options: []) as? [String: Any]
            let enSahih = (quranEnJson?["quran"] as? [String: Any])?["en.sahih"] as? [String: [String: Any]] ?? [:]
            
            for (_, verseData) in enSahih {
                guard let surahNumber = verseData["surah"] as? Int,
                      let ayahNumber = verseData["ayah"] as? Int,
                      let verseText = verseData["verse"] as? String else { continue }
                
                if let surahIndex = quran.firstIndex(where: { $0.id == surahNumber }),
                   let ayahIndex = quran[surahIndex].ayahs.firstIndex(where: { $0.id == ayahNumber }) {
                    quran[surahIndex].ayahs[ayahIndex].textEnglish = verseText
                }
            }
            
            DispatchQueue.main.async {
                self.quran = quran
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}

extension String {
    var removingArabicDiacriticsAndSigns: String {
        let diacriticRange = UnicodeScalar("ً")...UnicodeScalar("ٓ")
        let quranicSignsRange = UnicodeScalar("ۖ")...UnicodeScalar("۩")
        let shortAlif = UnicodeScalar("ٰ")
        let daggerAlif = UnicodeScalar("ٗ")
        let hamzatulWasl = UnicodeScalar("ٱ")
        let regularAlif = UnicodeScalar("ا")
        let maddaSign = UnicodeScalar("ٞ")
        let openTaMarbutaSign = UnicodeScalar("ٖ")
        return self.unicodeScalars.map { scalar in
            if scalar == hamzatulWasl {
                return regularAlif
            } else if diacriticRange.contains(scalar) || quranicSignsRange.contains(scalar) || scalar == shortAlif || scalar == daggerAlif || scalar == maddaSign || scalar == openTaMarbutaSign {
                return nil
            } else {
                return scalar
            }
        }.compactMap { $0 }.map { Character($0) }.reduce("") { $0 + String($1) }
    }
    
    subscript(_ range: Range<Int>) -> Substring {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        return self[startIndex..<endIndex]
    }
}
