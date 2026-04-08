import SwiftUI

// MARK: - Single source of truth: legend UI, Quran settings toggles, and TajweedStore coloring

enum TajweedLegendCategory: String, CaseIterable, Identifiable {
    case lamShamsiyah
    case hamzatWaslSilent
    case sukoonJazm
    case tafkhim
    case qalqalah
    case maddNatural2
    case maddSeparated
    case maddConnected
    case maddNecessary6
    case idghamBiGhunnah
    case ikhfaa
    case iqlab
    case idghamBilaGhunnah

    enum Section: String, CaseIterable, Identifiable {
        case silents
        case heavyAndQalqalah
        case idgham
        case madd

        var id: String { rawValue }

        var title: String {
            switch self {
            case .silents: return "Sukn - Silent"
            case .heavyAndQalqalah: return "Heavy / Qalqalah"
            case .idgham: return "Ghunnah - Nasal"
            case .madd: return "Madd - Elongation"
            }
        }
    }

    var id: String { rawValue }

    var englishTitle: String {
        switch self {
        case .lamShamsiyah: return "Solar Lam"
        case .hamzatWaslSilent: return "Joining Hamzah"
        case .sukoonJazm: return "Silent Letter"
        case .tafkhim: return "Heavy Letter"
        case .qalqalah: return "Bounce Letter"
        case .maddNatural2: return "Madd (2 Counts)"
        case .maddConnected: return "Madd in Same Word"
        case .maddSeparated: return "Madd Between Words"
        case .maddNecessary6: return "Madd (6 Counts)"
        case .idghamBiGhunnah: return "Merge with Ghunnah"
        case .ikhfaa: return "Hidden Letter"
        case .iqlab: return "Lam into Meem"
        case .idghamBilaGhunnah: return "Merge Without Ghunnah"
        @unknown default: return rawValue
        }
    }

    var arabicTitle: String {
        switch self {
        case .lamShamsiyah: return "لام شمسية"
        case .hamzatWaslSilent: return "همزة الوصل"
        case .sukoonJazm: return "سكون"
        case .tafkhim: return "تفخيم"
        case .qalqalah: return "قلقلة"
        case .maddNatural2: return "مد طبيعي"
        case .maddConnected: return "مد متصل"
        case .maddSeparated: return "مد منفصل"
        case .maddNecessary6: return "مد لازم"
        case .idghamBiGhunnah: return "إدغام بغنة"
        case .ikhfaa: return "إخفاء"
        case .iqlab: return "إقلاب"
        case .idghamBilaGhunnah: return "إدغام بلا غنة"
        @unknown default: return rawValue
        }
    }

    var transliteration: String {
        switch self {
        case .lamShamsiyah: return "Laam Shamiyyah"
        case .hamzatWaslSilent: return "Hamzat al-Wasl"
        case .sukoonJazm: return "Sukoon"
        case .tafkhim: return "Tafkheem"
        case .qalqalah: return "Qalqalah"
        case .maddNatural2: return "Madd Tabee"
        case .maddConnected: return "Madd Muttasil"
        case .maddSeparated: return "Madd Munfasil"
        case .maddNecessary6: return "Madd Laazim"
        case .idghamBiGhunnah: return "Idgham Bighunnah"
        case .ikhfaa: return "Ikhfa"
        case .iqlab: return "Iqlab"
        case .idghamBilaGhunnah: return "Idgham Bila Ghunnah"
        @unknown default: return rawValue
        }
    }

    var exactEnglishTranslation: String {
        switch self {
        case .lamShamsiyah: return "Solar Lam"
        case .hamzatWaslSilent: return "Connecting Hamzah"
        case .sukoonJazm: return "Sukoon"
        case .tafkhim: return "Heavy articulation"
        case .qalqalah: return "Echoing bounce"
        case .maddNatural2: return "Natural elongation"
        case .maddConnected: return "Connected elongation"
        case .maddSeparated: return "Separated elongation"
        case .maddNecessary6: return "Necessary elongation"
        case .idghamBiGhunnah: return "Merging with ghunnah"
        case .ikhfaa: return "Concealment"
        case .iqlab: return "Conversion"
        case .idghamBilaGhunnah: return "Merging without ghunnah"
        @unknown default: return rawValue
        }
    }

    var englishMeaning: String {
        switch self {
        case .lamShamsiyah:
            return "The lam in is silent before sun letters."
        case .hamzatWaslSilent:
            return "A joining hamzah is spoken only when starting from it."
        case .sukoonJazm:
            return "The letter is ignored."
        case .tafkhim:
            return "The letter is pronounced with a heavier sound."
        case .qalqalah:
            return "The letter bounces lightly when stopped or carrying sukoon."
        case .maddNatural2:
            return "The basic two-count elongation on the madd letters."
        case .maddConnected:
            return "A madd letter and hamzah appears right after in the same word."
        case .maddSeparated:
            return "A madd letter ends one word and hamzah begins the next."
        case .maddNecessary6:
            return "A fixed, longer elongation that occurs after a shaddah after a mad."
        case .idghamBiGhunnah:
            return "A noon or meem sound blends into the next letter with ghunnah."
        case .ikhfaa:
            return "The sound is partially hidden before the letter."
        case .iqlab:
            return "The noon sound turns into a meem sound before baa."
        case .idghamBilaGhunnah:
            return "A nun or meem sound gets skipped into the next letter."
        @unknown default:
            return "Tajweed rule meaning"
        }
    }

    var countLabel: String? {
        switch self {
        case .maddNatural2, .idghamBiGhunnah, .ikhfaa, .iqlab:
            return "2 counts"
        case .maddConnected:
            return "4 or 5 counts"
        case .maddSeparated:
            return "2, 4, or 5 counts"
        case .maddNecessary6:
            return "6 counts"
        default:
            return nil
        }
    }

    /// Canonical color for this rule everywhere in the app.
    var color: Color {
        switch self {
        case .lamShamsiyah: return Color(red: 0.66, green: 0.69, blue: 0.74) // soft gray
        case .hamzatWaslSilent: return Color(red: 0.66, green: 0.69, blue: 0.74) // soft gray
        case .sukoonJazm: return Color(red: 0.66, green: 0.69, blue: 0.74) // soft gray
        case .tafkhim: return Color.blue
        case .qalqalah: return Color.cyan
        case .maddNatural2: return Color(red: 0.95, green: 0.69, blue: 0.20) // amber
        case .maddConnected: return Color(red: 0.88, green: 0.35, blue: 0.36) // light red
        case .maddSeparated: return Color(red: 0.92, green: 0.54, blue: 0.12) // orange
        case .maddNecessary6: return Color(red: 0.65, green: 0.15, blue: 0.16) // darker deep red
        case .idghamBiGhunnah: return Color(red: 0.22, green: 0.65, blue: 0.35) // medium green
        case .ikhfaa: return Color(red: 0.13, green: 0.67, blue: 0.56) // teal-green
        case .iqlab: return Color(red: 0.10, green: 0.55, blue: 0.34) // darker emerald
        case .idghamBilaGhunnah: return Color(red: 0.34, green: 0.39, blue: 0.47) // darker slate
        @unknown default: return Color.secondary
        }
    }

    var section: Section {
        switch self {
        case .lamShamsiyah, .hamzatWaslSilent, .sukoonJazm, .idghamBilaGhunnah:
            return .silents
        case .tafkhim, .qalqalah:
            return .heavyAndQalqalah
        case .maddNatural2, .maddConnected, .maddSeparated, .maddNecessary6:
            return .madd
        case .idghamBiGhunnah, .ikhfaa, .iqlab:
            return .idgham
        }
    }

    var sortRank: Int {
        switch self {
        case .lamShamsiyah: return 0
        case .hamzatWaslSilent: return 1
        case .sukoonJazm: return 2
        case .tafkhim: return 3
        case .qalqalah: return 4
        case .maddNatural2: return 5
        case .maddConnected: return 6
        case .maddSeparated: return 7
        case .maddNecessary6: return 8
        case .idghamBiGhunnah: return 9
        case .ikhfaa: return 10
        case .iqlab: return 11
        case .idghamBilaGhunnah: return 12
        }
    }

    var shortDescription: String {
        switch self {
        case .lamShamsiyah:
            return "Lam of al- is silent before sun letters."
        case .hamzatWaslSilent:
            return "Start-only hamzah; dropped when connecting."
        case .sukoonJazm:
            return "Stop consonant with no vowel sound."
        case .tafkhim:
            return "Heavy, full-mouth pronunciation."
        case .qalqalah:
            return "Qutb jad letters bounce on sukoon/stop."
        case .maddNatural2:
            return "Natural 2-count madd elongation."
        case .maddConnected:
            return "Madd letter + hamzah in one word."
        case .maddSeparated:
            return "Madd at word end before next hamzah."
        case .maddNecessary6:
            return "Fixed 6-count required madd always."
        case .idghamBiGhunnah:
            return "Merge into next with nasal ghunnah."
        case .ikhfaa:
            return "Hide noon/tanween with ghunnah."
        case .iqlab:
            return "Noon/tanween turns to meem before baa."
        case .idghamBilaGhunnah:
            return "Merge into next without nasal sound."
        @unknown default:
            return "Tajweed rule"
        }
    }

    var longDescription: String {
        switch self {
        case .lamShamsiyah:
            return "The lam in al- is not pronounced before the sun letters. Instead, it assimilates into the next letter, often heard as a doubled sound. Example: al-shams is read as ash-shams."
        case .hamzatWaslSilent:
            return "Hamzat al-wasl is pronounced when you begin from that word, but it drops when you connect from the previous word. It helps joining without adding an extra stop."
        case .sukoonJazm:
            return "Sukoon means the letter carries no vowel. You pronounce only the consonant sound, creating a clean stop or closure on that letter."
        case .tafkhim:
            return "Tafkhim is a heavy, full articulation. It is most obvious on the isti'la letters, where the tongue rises and the sound gains depth compared with light letters."
        case .qalqalah:
            return "Qalqalah is a slight echo/bounce on the letters of qutb jad when they are sakin (or when stopping on them). The sound is crisp and brief, not a stretched vowel."
        case .maddNatural2:
            return "This is the baseline madd: a natural 2-count elongation on alif, waw, or ya after their matching vowels. Other madd lengths are measured relative to this one."
        case .maddConnected:
            return "Madd muttasil occurs when a madd letter is followed by hamzah in the same word. It is lengthened beyond natural madd, commonly 4 to 5 counts in recitation."
        case .maddSeparated:
            return "Madd munfasil occurs when a word ends with a madd letter and the next word begins with hamzah. It is lengthened, often 2, 4, or 5 counts depending on the riwayah."
        case .maddNecessary6:
            return "Madd lazim is a required heavy elongation with a fixed 6 counts. It appears where the madd is followed by a permanent sukoon/shaddah pattern and is not shortened."
        case .idghamBiGhunnah:
            return "Idgham with ghunnah merges the noon/tanween sound into the next letter while keeping a nasal resonance. The merge is smooth and the ghunnah is clearly sustained."
        case .ikhfaa:
            return "Ikhfa hides the noon/tanween sound before specific letters so it is neither fully clear nor fully merged. A controlled ghunnah is heard during this concealed transition."
        case .iqlab:
            return "Iqlab changes noon sakinah or tanween into a meem-like sound before baa, with ghunnah. The articulation shifts to the lips while preserving a smooth flow."
        case .idghamBilaGhunnah:
            return "Idgham without ghunnah merges the noon/tanween sound into the next letter but without nasalization. The transition is direct and clean."
        @unknown default:
            return "Tajweed rule"
        }
    }
}
