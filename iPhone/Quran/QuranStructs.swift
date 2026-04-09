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

    var hasNote: Bool {
        !(note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

struct VerseIndexEntry: Identifiable, Hashable {
    let id: String
    let surah: Int
    let ayah: Int
    let arabicTashkeelBlob: String
    let englishExactBlob: String
    let arabicBlob: String
    let englishBlob: String
    let arabicTokens: [String]
    let englishTokens: [String]
}

enum BoundaryDividerStyle {
    case allGreen
    case allSecondary
    case pageAccentJuzSecondary
    case allAccent
}

struct BoundaryDividerModel {
    let text: String
    let pageSegment: String
    let juzSegment: String?
    let style: BoundaryDividerStyle
}

struct SurahBoundaryModel {
    let startDivider: BoundaryDividerModel?
    let startDividerHighlighted: Bool
    let dividerBeforeAyah: [Int: BoundaryDividerModel]
    let endOfSurahDivider: BoundaryDividerModel?
    let endDivider: BoundaryDividerModel?
    let endDividerHighlighted: Bool
}

extension String {
    var containsArabicLetters: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0600...0x06FF,
                 0x0750...0x077F,
                 0x08A0...0x08FF,
                 0xFB50...0xFDFF,
                 0xFE70...0xFEFF,
                 0x1EE00...0x1EEFF:
                return true
            default:
                return false
            }
        }
    }
}

struct LastListenedSurah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    let currentDuration: Double
    let fullDuration: Double
}

struct ListeningHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    var timestamp: Date = Date()
}

struct ReadingHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    var timestamp: Date = Date()
}

struct ShareSettings: Equatable {
    var arabic = false
    var transliteration = false
    var englishSaheeh = false
    var englishMustafa = false
    var includeQiraah = false
    var shareArabicFont = ""
    var cleanArabic = false
}

struct Reciter: Identifiable, Comparable, Codable, Hashable {
    var id: String { "\(name)|\(qiraah ?? "Hafs")|\(surahLink)" }

    let name: String
    let ayahIdentifier: String
    let ayahBitrate: String
    let surahLink: String
    var qiraah: String?

    /// Settings / lists: append English riwayah when this row is a non-Hafs surah feed.
    var displayNameWithEnglishQiraah: String {
        if let q = qiraah, !q.isEmpty { return "\(name) (\(q))" }
        return name
    }

    /// Lock screen and now playing: show the selected reciter name, plus riwayah for qiraat surah feeds.
    var displayNameForNowPlaying: String {
        let base = name
        if let q = qiraah, !q.isEmpty { return "\(base) (\(q))" }
        return base
    }

    static func < (lhs: Reciter, rhs: Reciter) -> Bool {
        lhs.name < rhs.name
    }

    static func == (lhs: Reciter, rhs: Reciter) -> Bool {
        lhs.id == rhs.id
    }
}

let reciters: [Reciter] = (
    recitersMinshawi +
    recitersMurattal +
    recitersMujawwad +
    recitersMuallim +
    
    recitersShubah +
    recitersWarsh +
    recitersBuzzi +
    recitersQunbul +
    recitersQaloon +
    recitersDuri +
    recitersKhalaf
).sorted()

let recitersMinshawi = [
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/"),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Muhammad Al-Minshawi (Muallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/")
].sorted()

let recitersMurattal = [
    Reciter(name: "Abdul Basit (Murattal)", ayahIdentifier: "ar.abdulbasitmurattal", ayahBitrate: "192", surahLink: "https://server7.mp3quran.net/basit/"),
    Reciter(name: "Abdul Rahman Al-Sudais", ayahIdentifier: "ar.abdurrahmaansudais", ayahBitrate: "192", surahLink: "https://server11.mp3quran.net/sds/"),
    Reciter(name: "Abu Bakr Al-Shatri", ayahIdentifier: "ar.shaatree", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/shatri/"),
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.husary", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/"),
    Reciter(name: "Maher Al-Muaiqly (Murattal)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/"),
    Reciter(name: "Mishary Alafasy", ayahIdentifier: "ar.alafasy", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/afs/"),
    Reciter(name: "Abdullah Al-Juhany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/jhn/"),
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Bandar Baleela", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/balilah/"),
    Reciter(name: "Badr Al-Turki", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/bader/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Muhammad Al-Luhaidan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/lhdan/"),
    Reciter(name: "Abdullah Al Qarafi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/a_alqrafi/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/"),
    Reciter(name: "Muhammad Jibreel", ayahIdentifier: "ar.muhammadjibreel", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/jbrl/"),
    Reciter(name: "Mustafa Ismail (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/"),
    Reciter(name: "Mahmoud Ali Al-Banna (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/"),
    Reciter(name: "Saud Al-Shuraim", ayahIdentifier: "ar.saoodshuraym", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/shur/"),
    Reciter(name: "Hani Al-Rifai", ayahIdentifier: "ar.hanirifai", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/hani/"),
    Reciter(name: "Ahmad Al-Ajmy", ayahIdentifier: "ar.ahmedajamy", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ajm/"),
    Reciter(name: "Muhammad Ayyub", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/ayyub/"),
    Reciter(name: "Muhammad Ayyub (Special)", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/ayyoub2/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Abdulrahman Aloosi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/aloosi/"),
    Reciter(name: "Hazza Al-Balushi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/hazza/"),
    Reciter(name: "Ali Jaber", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/a_jbr/"),
    Reciter(name: "Saad Al-Ghamdi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/s_gmd/"),
    Reciter(name: "Yasser Al-Dosari", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/yasser/"),
    Reciter(name: "Abdullah Al-Mattrod", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mtrod/")
].sorted()

let recitersMujawwad = [
    Reciter(name: "Abdul Basit (Mujawwad)", ayahIdentifier: "ar.abdulsamad", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Mahmoud Al-Hussary (Mujawwad)", ayahIdentifier: "ar.husarymujawwad", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Maher Al-Muaiqly (Mujawwad)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Mustafa Ismail (Mujawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Mahmoud Ali Al-Banna (Mujawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/Almusshaf-Al-Mojawwad/")
].sorted()

let recitersMuallim = [
    Reciter(name: "Maher Al-Muaiqly (Muallim)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mo-lim/"),
    Reciter(name: "Muhammad Al-Minshawi (Muallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/")
].sorted()

let recitersShubah = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Sho-bah-A-n-Asim/001.mp3", qiraah: Settings.Riwayah.shubah),
].sorted()

let recitersKhalaf = [
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Khalaf-A-n-Hamzah/", qiraah: Settings.Riwayah.khalaf)
].sorted()

let recitersWarsh = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Warsh-A-n-Nafi-Men-Tariq-Alazraq/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Abdul Basit", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/basit/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Al-Qari Yassin", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/qari/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Al-Uyoun Al-Koshi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/koshi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Hisham Al Haraz", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/H-Lharraz/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Ibrahim Al-Dossary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ibrahim_dosri/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Muhammad Sayed", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/m_sayed/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Omar Al-Qazabri", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/omar_warsh/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Rachid Belalya", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/bl3/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Rachid Ifrad", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/ifrad/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Younes Souilass", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/souilass/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh)
].sorted()

let recitersBuzzi = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.buzzi),
    Reciter(name: "Okasha Kameny", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/okasha/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.buzzi)
].sorted()

let recitersQunbul = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qunbol-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.qunbul)
].sorted()

let recitersQaloon = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ahmed Al-Trabulsi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/trablsi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ibrahim Qushaydan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/i_kshidan/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Tareq Daawob", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/tareq/", qiraah: Settings.Riwayah.qaloon)
].sorted()

let recitersDuri = [
    Reciter(name: "Noreen Mohammad Siddiq", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/nourin_siddig/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri)
].sorted()
