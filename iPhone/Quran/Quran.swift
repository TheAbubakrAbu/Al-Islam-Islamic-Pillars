import SwiftUI

struct Juz: Codable, Identifiable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    
    let startSurah: Int
    let startAyah: Int
    
    let endSurah: Int
    let endAyah: Int
}

struct BookmarkedAyah: Codable, Identifiable, Equatable, Hashable {
    var id: String { "\(surah)-\(ayah)" }
    var surah: Int
    var ayah: Int
    
    var note: String? = nil
    var hasNote: Bool { !(note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
}

struct LastListenedSurah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    
    let reciter: Reciter
    
    let currentDuration: Double
    let fullDuration: Double
}

struct Reciter: Identifiable, Comparable, Codable, Hashable {
    var id: String { "\(name)|\(qiraah ?? "Hafs")|\(surahLink)" }
    let name: String
    let ayahIdentifier: String
    let ayahBitrate: String
    let surahLink: String
    var qiraah: String?

    static func < (lhs: Reciter, rhs: Reciter) -> Bool {
        return lhs.name < rhs.name
    }
    
    static func ==(l: Reciter, r: Reciter) -> Bool { l.id == r.id }
}

let reciters: [Reciter] = (
    recitersMurattal +
    recitersMujjawwad +
    recitersMuallim +
    recitersWarsh +
    recitersBuzzi +
    recitersQunbul +
    recitersQaloon +
    recitersDuri +
    recitersKhalaf
).sorted()

let recitersMurattal = [
    Reciter(name: "Abdul Basit (Murattal)", ayahIdentifier: "ar.abdulbasitmurattal", ayahBitrate: "192", surahLink: "https://server7.mp3quran.net/basit/"),
    
    Reciter(name: "Abdul Rahman Al-Sudais", ayahIdentifier: "ar.abdurrahmaansudais", ayahBitrate: "192", surahLink: "https://server11.mp3quran.net/sds/"),
    
    Reciter(name: "Abu Bakr Al-Shatri", ayahIdentifier: "ar.shaatree", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/shatri/"),
    
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.husary", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/"),
    
    Reciter(name: "Maher Al-Muaiqly (Murattal)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/"),
    
    Reciter(name: "Mishary Alafasy", ayahIdentifier: "ar.alafasy", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/afs/"),
    
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/"),
    
    Reciter(name: "Muhammad Jibreel", ayahIdentifier: "ar.muhammadjibreel", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/jbrl/"),
    
    Reciter(name: "Mustafa Ismail (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/"),
    
    Reciter(name: "Mahmoud Ali Al-Banna (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/"),
    
    Reciter(name: "Saud Al-Shuraim", ayahIdentifier: "ar.saoodshuraym", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/shur/"),
    
    Reciter(name: "Hani Al-Rifai", ayahIdentifier: "ar.hanirifai", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/hani/"),
    
    Reciter(name: "Ahmad Al-Ajmy", ayahIdentifier: "ar.ahmedajamy", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ajm/"),
    
    Reciter(name: "Muhammad Ayyub", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/ayyub/"),
    Reciter(name: "Muhammad Ayyub (Special)", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/ayyoub2/Rewayat-Hafs-A-n-Assem/"),
    
    // No Ayah Recitations - Default to Minshawi
    Reciter(name: "Abdulrahman Aloosi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/aloosi/"),
    
    Reciter(name: "Hazza Al-Balushi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/hazza/"),
    
    Reciter(name: "Ali Jaber", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/a_jbr/"),
    
    Reciter(name: "Saad Al-Ghamdi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/s_gmd/"),
    
    Reciter(name: "Yasser Al-Dosari", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/yasser/"),
        
    Reciter(name: "Abdullah Al-Mattrod", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mtrod/"),
].sorted()

let recitersMujjawwad = [
    Reciter(name: "Abdul Basit (Mujjawwad)", ayahIdentifier: "ar.abdulsamad", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/"),
            
    Reciter(name: "Mahmoud Al-Hussary (Mujjawwad)", ayahIdentifier: "ar.husarymujawwad", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/"),
    
    Reciter(name: "Maher Al-Muaiqly (Mujjawwad)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mojawwad/"),
        
    Reciter(name: "Muhammad Al-Minshawi (Mujjawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/"),
        
    Reciter(name: "Mustafa Ismail (Mujjawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/Almusshaf-Al-Mojawwad/"),
    
    Reciter(name: "Mahmoud Ali Al-Banna (Mujjawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/Almusshaf-Al-Mojawwad/"),
].sorted()

let recitersMuallim = [
    Reciter(name: "Maher Al-Muaiqly (Muʿallim)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mo-lim/"),
    
    Reciter(name: "Muhammad Al-Minshawi (Muʿallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/"),
].sorted()

let recitersKhalaf = [
    // Khalaf an Hamzah
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Khalaf-A-n-Hamzah/", qiraah: "Khalaf an Hamzah"),
].sorted()

let recitersWarsh = [
    // Warsh An Nafi
    Reciter(name: "Abdul Basit (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/basit/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Al-Qari Yassin", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/qari/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Al-Uyoun Al-Koshi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/koshi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Hisham Al Haraz", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/H-Lharraz/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Ibrahim Al-Dossary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ibrahim_dosri/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Muhammad Sayed", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/m_sayed/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Omar Al-Qazabri", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/omar_warsh/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Rachid Belalya", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/bl3/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Rachid Ifrad", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/ifrad/", qiraah: "Warsh An Nafi"),
    Reciter(name: "Younes Souilass", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/souilass/Rewayat-Warsh-A-n-Nafi/", qiraah: "Warsh An Nafi"),
].sorted()

let recitersBuzzi = [
    // Al-Buzzi an Ibn Kathir
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: "Al-Buzzi an Ibn Kathir"),
    
    Reciter(name: "Okasha Kameny", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/okasha/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: "Al-Buzzi an Ibn Kathir"),
].sorted()

let recitersQunbul = [
    // Qunbul an Ibn Kathir
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qunbol-A-n-Ibn-Katheer/", qiraah: "Qunbul an Ibn Kathir"),
].sorted()

let recitersQaloon = [
    // Qaloon An Nafi
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Qalon-A-n-Nafi/", qiraah: "Qaloon An Nafi"),
    
    Reciter(name: "Ahmed Al-Trabulsi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/trablsi/", qiraah: "Qaloon An Nafi"),
    
    Reciter(name: "Ibrahim Qushaydan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/i_kshidan/Rewayat-Qalon-A-n-Nafi/", qiraah: "Qaloon An Nafi"),
    
    Reciter(name: "Tareq Daawob", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/tareq/", qiraah: "Qaloon An Nafi"),
].sorted()

let recitersDuri = [
    // Ad-Duri an Abi Amr
    Reciter(name: "Noreen Mohammad Siddiq", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/nourin_siddig/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: "Ad-Duri an Abi Amr"),
    
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: "Ad-Duri an Abi Amr"),
].sorted()

struct Surah: Codable, Identifiable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    let nameEnglish: String
    
    let type: String
    let numberOfAyahs: Int
    
    var ayahs: [Ayah]
}

struct Ayah: Codable, Identifiable {
    let id: Int
    let textArabic: String
    var textClearArabic: String { textArabic.removingArabicDiacriticsAndSigns }
    let textTransliteration: String
    let textEnglishSaheeh: String
    let textEnglishMustafa: String
}

final class QuranData: ObservableObject {
    static let shared = QuranData()
    private let settings = Settings.shared

    @Published private(set) var quran: [Surah] = []

    private var surahIndex = [Int:Int]()
    private var ayahIndex = [[Int:Int]]()

    private init() {
        Task(priority: .userInitiated) { await load() }
    }
    
    private func load() async {
        guard let url = Bundle.main.url(forResource: "quran", withExtension: "json") else {
            fatalError("quran.json missing")
        }
        do {
            let data = try Data(contentsOf: url)
            let surahs = try JSONDecoder().decode([Surah].self, from: data)

            buildIndexes(for: surahs)

            await MainActor.run { self.quran = surahs }
        } catch {
            fatalError("Failed to load Quran: \(error)")
        }
    }

    private func buildIndexes(for surahs: [Surah]) {
        surahIndex = Dictionary(uniqueKeysWithValues: surahs.enumerated().map { ($1.id, $0) }
        )
        ayahIndex = surahs.map { surah in
            Dictionary(uniqueKeysWithValues: surah.ayahs.enumerated().map { ($1.id, $0) }
            )
        }
    }
    
    func surah(_ number: Int) -> Surah? {
        surahIndex[number].map { quran[$0] }
    }

    func ayah(surah: Int, ayah: Int) -> Ayah? {
        guard let sIdx = surahIndex[surah], let aIdx = ayahIndex[sIdx][ayah] else { return nil }
        return quran[sIdx].ayahs[aIdx]
    }
    
    let juzList: [Juz] = [
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
    
    lazy var verseIndex: [VerseIndexEntry] = {
        quran.flatMap { surah in
            surah.ayahs.map { ayah in
                let blob = [
                    ayah.textArabic,
                    ayah.textClearArabic,
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
    }()

    func searchVerses(term raw: String, limit: Int = 10, offset: Int = 0) -> [VerseIndexEntry] {
        let cleanedSearch = settings.cleanSearch(raw, whitespace: true)
        guard !cleanedSearch.isEmpty else { return [] }
        if cleanedSearch.rangeOfCharacter(from: .decimalDigits) != nil { return [] }

        let hits = verseIndex.filter { $0.searchBlob.contains(cleanedSearch) }

        if limit == .max {
            return Array(hits.dropFirst(offset))
        } else {
            return Array(hits.dropFirst(offset).prefix(limit))
        }
    }
    
    func searchVersesAll(term raw: String) -> [VerseIndexEntry] {
        searchVerses(term: raw, limit: .max, offset: 0)
    }
}

struct VerseIndexEntry: Identifiable, Hashable {
    let id: String
    let surah: Int
    let ayah: Int
    let searchBlob: String
}
