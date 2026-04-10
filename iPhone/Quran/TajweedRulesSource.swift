import SwiftUI

// MARK: - Single source of truth: legend UI, Quran settings toggles, and TajweedStore coloring

enum TajweedLegendCategory: String, CaseIterable, Identifiable {
    case lamShamsiyah
    case hamzatWaslSilent
    case sukoonJazm
    case tafkhim
    case qalqalah
    case maddNatural2
    case madd246
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
        case ghunnah
        case idgham
        case madd

        var id: String { rawValue }

        var title: String {
            switch self {
            case .silents: return "Sukn - Silent"
            case .heavyAndQalqalah: return "Heavy / Qalqalah"
            case .ghunnah: return "Ghunnah - Nasal"
            case .idgham: return "Idgham - Merge"
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
        case .madd246: return "Madd (2, 4, 6)"
        case .maddConnected: return "Madd in Same Word"
        case .maddSeparated: return "Madd Between Words"
        case .maddNecessary6: return "Madd (6 Counts)"
        case .idghamBiGhunnah: return "Merge with Ghunnah (Light)"
        case .ikhfaa: return "Hidden Letter"
        case .iqlab: return "Lam into Meem"
        case .idghamBilaGhunnah: return "Merge Without Ghunnah (Heavy)"
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
        case .madd246: return "مد ٢ ٤ ٦"
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
        case .madd246: return "Madd 2, 4, 6"
        case .maddConnected: return "Madd Muttasil"
        case .maddSeparated: return "Madd Munfasil"
        case .maddNecessary6: return "Madd Laazim"
        case .idghamBiGhunnah: return "Idgham Bighunnah"
        case .ikhfaa: return "Ikhfaa"
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
        case .madd246: return "Elongation (2, 4, 6)"
        case .maddConnected: return "Connected elongation"
        case .maddSeparated: return "Separated elongation"
        case .maddNecessary6: return "Necessary elongation"
        case .idghamBiGhunnah: return "Merging with light ghunnah"
        case .ikhfaa: return "Concealment"
        case .iqlab: return "Conversion"
        case .idghamBilaGhunnah: return "Merging without ghunnah (heavier)"
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
        case .madd246:
            return "Reserved in legend for 2, 4, 6-count madd usage."
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
            return "A nun or meem sound gets skipped into the next letter without ghunnah."
        @unknown default:
            return "Tajweed rule meaning"
        }
    }

    var countLabel: String? {
        switch self {
        case .maddNatural2, .idghamBiGhunnah, .ikhfaa, .iqlab:
            return "2 counts"
        case .madd246:
            return "2, 4, or 6 counts"
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
        case .lamShamsiyah: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .hamzatWaslSilent: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .sukoonJazm: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .tafkhim: return Color(red: 0.2314, green: 0.5216, blue: 0.7608) // 3B85C2
        case .qalqalah: return Color(red: 0.4706, green: 0.8000, blue: 0.9765) // 78CCF9
        case .maddNatural2: return Color(red: 0.7255, green: 0.5490, blue: 0.1843) // B98C2F
        case .madd246: return Color(red: 0.8902, green: 0.4745, blue: 0.2078) // E37935
        case .maddConnected: return Color(red: 0.8510, green: 0.2706, blue: 0.2431) // D9453E
        case .maddSeparated: return Color(red: 0.9216, green: 0.3176, blue: 0.6667) // EB51AA
        case .maddNecessary6: return Color(red: 0.6824, green: 0.1451, blue: 0.0902) // AE2517
        case .idghamBiGhunnah: return Color(red: 0.3412, green: 0.7373, blue: 0.4706) // 57BC78
        case .ikhfaa: return Color(red: 0.2549, green: 0.6941, blue: 0.4824) // 41B17B
        case .iqlab: return Color(red: 0.2118, green: 0.6431, blue: 0.5255) // 36A485
        case .idghamBilaGhunnah: return Color(red: 0.1961, green: 0.5922, blue: 0.6157) // 32979D
        @unknown default: return Color.secondary
        }
    }

    var section: Section {
        switch self {
        case .lamShamsiyah, .hamzatWaslSilent, .sukoonJazm:
            return .silents
        case .tafkhim, .qalqalah:
            return .heavyAndQalqalah
        case .maddNatural2, .madd246, .maddConnected, .maddSeparated, .maddNecessary6:
            return .madd
        case .idghamBiGhunnah, .ikhfaa, .iqlab:
            return .ghunnah
        case .idghamBilaGhunnah:
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
        case .madd246: return 6
        case .maddConnected: return 7
        case .maddSeparated: return 8
        case .maddNecessary6: return 9
        case .idghamBiGhunnah: return 10
        case .ikhfaa: return 11
        case .iqlab: return 12
        case .idghamBilaGhunnah: return 13
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
        case .madd246:
            return "Reserved madd color slot (2, 4, 6)."
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
            return "Heavier merge into next without nasal sound."
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
        case .madd246:
            return "This slot is reserved in the legend for madd readings that may be applied as 2, 4, or 6 counts in certain stop/recitation contexts. (No automatic rule coloring is assigned to this category yet.)"
        case .maddConnected:
            return "Madd muttasil occurs when a madd letter is followed by hamzah in the same word. It is lengthened beyond natural madd, commonly 4 to 5 counts in recitation."
        case .maddSeparated:
            return "Madd munfasil occurs when a word ends with a madd letter and the next word begins with hamzah. It is lengthened, often 2, 4, or 5 counts depending on the riwayah."
        case .maddNecessary6:
            return "Madd lazim is a required heavy elongation with a fixed 6 counts. It appears where the madd is followed by a permanent sukoon/shaddah pattern and is not shortened."
        case .idghamBiGhunnah:
            return "Idgham with ghunnah merges the noon/tanween sound into the next letter while keeping a light nasal resonance. The merge is smooth and the ghunnah is clearly sustained."
        case .ikhfaa:
            return "Ikhfa hides the noon/tanween sound before specific letters so it is neither fully clear nor fully merged. A controlled ghunnah is heard during this concealed transition."
        case .iqlab:
            return "Iqlab changes noon sakinah or tanween into a meem-like sound before baa, with ghunnah. The articulation shifts to the lips while preserving a smooth flow."
        case .idghamBilaGhunnah:
            return "Idgham without ghunnah merges the noon/tanween sound into the next letter with no nasalization. It is typically perceived heavier and more direct than ghunnah-based merges."
        @unknown default:
            return "Tajweed rule"
        }
    }
}
