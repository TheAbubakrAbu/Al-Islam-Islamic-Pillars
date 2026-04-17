import SwiftUI

enum TajweedLegendCategory: String, CaseIterable, Identifiable {
    case lamShamsiyah
    case droppedLetter
    case hamzatWaslSilent
    case idghamBilaGhunnah
    
    case idghamGhunnah
    case ikhfaaLight
    case ikhfaaHeavy
    case iqlaab
    
    case qalqalah
    case tafkhim
    
    case maddNatural
    case maddSukoon
    case maddSeparated
    case maddConnected
    case maddNecessary

    enum Section: String, CaseIterable, Identifiable {
        case silents
        case ghunnah
        case sifaat
        case madd

        var id: String { rawValue }

        var title: String {
            switch self {
            case .silents: return "Sukn - Silent"
            case .ghunnah: return "Ghunnah - Nasal"
            case .sifaat: return "Sifaat - Articulation"
            case .madd: return "Madd - Elongation"
            }
        }
    }

    var id: String { rawValue }

    var englishTitle: String {
        switch self {
        case .lamShamsiyah: return "Solar Lam"
        case .droppedLetter: return "Written but Not Pronounced"
        case .hamzatWaslSilent: return "Joining Hamzah"
        case .idghamBilaGhunnah: return "Merge Without Ghunnah"
            
        case .idghamGhunnah: return "Merge with Ghunnah"
        case .ikhfaaLight: return "Hidden Letter (Light)"
        case .ikhfaaHeavy: return "Hidden Letter (Heavy"
        case .iqlaab: return "Noon into Meem"
            
        case .qalqalah: return "Bounce Letter"
        case .tafkhim: return "Heavy Letter"
            
        case .maddNatural: return "Madd (2 Counts)"
        case .maddSukoon: return "Madd (2, 4, 6)"
        case .maddSeparated: return "Madd Between Words"
        case .maddConnected: return "Madd in Same Word"
        case .maddNecessary: return "Madd (6 Counts)"
            
        @unknown default: return rawValue
        }
    }

    var arabicTitle: String {

        switch self {
        case .lamShamsiyah: return "لَامٌ شَمسِيَّة"
        case .droppedLetter: return "حَرفٌ غَيرُ مَنطُوق"
        case .hamzatWaslSilent: return "هَمزَةُ الوَصل"
        case .idghamBilaGhunnah: return "إِدغَامٌ بِلَا غُنَّة"
            
        case .idghamGhunnah: return "إِدغَامٌ بِغُنَّةٍ"
        case .ikhfaaLight: return "إِخْفَاء مُرَقَّق"
        case .ikhfaaHeavy: return "إِخْفَاء مُفَخَّم"
        case .iqlaab: return "إِقلَاب"
            
        case .qalqalah: return "قَلقَلَة"
        case .tafkhim: return "تَفخِيم"
            
        case .maddNatural: return "مَدٌّ طَبِيعِي"
        case .maddSukoon: return "مَدٌّ عَارِضٌ لِلسُّكُون"
        case .maddSeparated: return "مَدٌّ مُنفَصِل"
        case .maddConnected: return "مَدٌّ مُتَّصِل"
        case .maddNecessary: return "مَدٌّ لَازِم"

        @unknown default: return rawValue

        }

    }

    var transliteration: String {
        switch self {
        case .lamShamsiyah: return "Laam Shamiyyah"
        case .droppedLetter: return "Harf Ghayr Mantuq"
        case .hamzatWaslSilent: return "Hamzat al-Wasl"
        case .idghamBilaGhunnah: return "Idgham Bilaa Ghunnah"
            
        case .idghamGhunnah: return "Idgham Bighunnah"
        case .ikhfaaLight: return "Ikhfaa (Light)"
        case .ikhfaaHeavy: return "Ikhfaa (Heavy)"
        case .iqlaab: return "Iqlaab"
            
        case .qalqalah: return "Qalqalah"
        case .tafkhim: return "Tafkheem"
            
        case .maddNatural: return "Madd Tabee"
        case .maddSukoon: return "Madd Aarid lis-Sukoon"
        case .maddSeparated: return "Madd Munfasil"
        case .maddConnected: return "Madd Muttasil"
        case .maddNecessary: return "Madd Laazim"
            
        @unknown default: return rawValue
        }
    }

    var exactEnglishTranslation: String {
        switch self {
        case .lamShamsiyah: return "Solar Lam"
        case .droppedLetter: return "Unpronounced letter"
        case .hamzatWaslSilent: return "Connecting Hamzah"
        case .idghamBilaGhunnah: return "Merging without nasal"
            
        case .idghamGhunnah: return "Merging with nasal"
        case .ikhfaaLight: return "Light Concealment"
        case .ikhfaaHeavy: return "Heavy Concealment"
        case .iqlaab: return "Conversion"
            
        case .qalqalah: return "Echoing bounce"
        case .tafkhim: return "Heavy articulation"
            
        case .maddNatural: return "Natural elongation"
        case .maddSukoon: return "Elongation due to end"
        case .maddSeparated: return "Separated elongation"
        case .maddConnected: return "Connected elongation"
        case .maddNecessary: return "Necessary elongation"
            
        @unknown default: return rawValue
        }
    }

    var englishMeaning: String {
        switch self {
        case .lamShamsiyah:
            return "Solar lam: the lam in al- is absorbed into the following sun letter, so that next letter is emphasized."
        case .droppedLetter:
            return "A letter is written in the mushaf but not fully pronounced in recitation."
        case .hamzatWaslSilent:
            return "Hamzat al-wasl is heard only when starting a word and dropped when reading continuously from before it."
        case .idghamBilaGhunnah:
            return "Idgham bilaa ghunnah merges noon/tanween directly into the next letter without nasalization."
            
        case .idghamGhunnah:
            return "Idgham with ghunnah merges noon or tanween into the next letter with a nasal sound."
        case .ikhfaaLight:
            return "Light Ikhfaa partially hides noon or tanween before certain letters with a lighter nasal ghunnah."
        case .ikhfaaHeavy:
            return "Heavy Ikhfaa partially hides noon or tanween before heavy letters with a stronger, fuller nasal ghunnah."
        case .iqlaab:
            return "Iqlaab changes noon/tanween to a meem-like sound before baa, with ghunnah."
            
        case .qalqalah:
            return "Qalqalah is a brief bounce on the Qutb Jad letters when they are sakin or when stopping on them."
        case .tafkhim:
            return "Tafkhim is a heavy, fuller articulation where the sound is pronounced with depth and thickness."
            
        case .maddNatural:
            return "Madd tabi'i is the baseline natural stretch of 2 counts on alif, waw, or ya after matching vowels."
        case .maddSukoon:
            return "Madd aarid lis-sukoon happens when stopping creates a temporary sukoon after a madd letter, read as 2, 4, or 6 counts."
        case .maddSeparated:
            return "Madd munfasil is when a word ends with madd and the next word begins with hamzah, so the stretch carries across words."
        case .maddConnected:
            return "Madd muttasil is when a madd letter is followed by hamzah in the same word, so it is lengthened beyond natural madd."
        case .maddNecessary:
            return "Madd lazim is an obligatory fixed stretch of 6 counts due to a shaddah after madd."

        @unknown default:
            return "Tajweed rule meaning"
        }
    }

    var countLabel: String? {
        switch self {
        case .maddNatural, .idghamGhunnah, .ikhfaaLight, .ikhfaaHeavy, .iqlaab:
            return "2 counts"
        case .maddSukoon:
            return "2, 4, or 6 counts"
        case .maddSeparated:
            return "2, 4, or 5 counts"
        case .maddConnected:
            return "4 or 5 counts"
        case .maddNecessary:
            return "6 counts"
        default:
            return nil
        }
    }

    var applicableLettersDetail: String? {
        switch self {
        case .idghamBilaGhunnah:
            return "When noon (ن) or tanween comes before: ل، ر"
            
        case .idghamGhunnah:
            return "When a noon sound (ن or tanween) comes before: ي، ن، م، و"
        case .ikhfaaLight:
            return "When a noon sound (ن or tanween) comes before lighter letters: ت، ث، ج، د، ذ، ز، س، ش"
        case .ikhfaaHeavy:
            return "When a noon sound (ن or tanween) comes before heavier letters: ص، ض، ط، ظ، ق، ك"
        case .iqlaab:
            return "When noon (ن) or tanween comes before: ب (changes to meem sound)"
            
        case .qalqalah:
            return "Letters that bounce when they have sukoon or are stopped on: ق، ط، ب، ج، د"
        case .tafkhim:
            return "Letters pronounced heavily (elevated tongue): خ، ص، ض، غ، ط، ق، ظ"
            
        case .maddNatural:
            return "Occurs on madd letters: ا، و، ي (normal 2-count elongation)"
        case .maddSukoon:
            return "When stopping causes sukoon after madd letters: ا، و، ي"
        case .maddSeparated:
            return "When madd letters (ا، و، ي) are followed by hamzah in the next word"
        case .maddConnected:
            return "When madd letters (ا، و، ي) are followed by hamzah in the same word"
        case .maddNecessary:
            return "When madd letters (ا، و، ي) are followed by a permanent sukoon or shaddah"
            
        default:
            return nil
        }
    }

    /// Canonical color for this rule everywhere in the app.
    var color: Color {
        switch self {
        case .lamShamsiyah: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .hamzatWaslSilent: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .droppedLetter: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .idghamBilaGhunnah: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
            
        case .idghamGhunnah: return Color(red: 0.4588, green: 0.6980, blue: 0.2000) // 75B233 olive-green
        case .ikhfaaLight: return Color(red: 0.2706, green: 0.7373, blue: 0.4510) // 45BC73 light green
        case .ikhfaaHeavy: return Color(red: 0.1216, green: 0.6667, blue: 0.5804) // 1FAA94 teal-accent green
        case .iqlaab: return Color(red: 0.1294, green: 0.6392, blue: 0.3529) // 21A35A distinct green
            
        case .tafkhim: return Color(red: 0.2314, green: 0.5216, blue: 0.7608) // 3B85C2
        case .qalqalah: return Color(red: 0.4706, green: 0.8000, blue: 0.9765) // 78CCF9
            
        case .maddNatural: return Color(red: 0.7255, green: 0.5490, blue: 0.1843) // B98C2F
        case .maddSukoon: return Color(red: 0.8902, green: 0.4745, blue: 0.2078) // E37935
        case .maddSeparated: return Color(red: 0.9216, green: 0.3176, blue: 0.6667) // EB51AA
        case .maddConnected: return Color(red: 0.8510, green: 0.2706, blue: 0.2431) // D9453E
        case .maddNecessary: return Color(red: 0.6824, green: 0.1451, blue: 0.0902) // AE2517
            
        @unknown default: return Color.secondary
        }
    }

    var section: Section {
        switch self {
        case .lamShamsiyah, .droppedLetter, .hamzatWaslSilent, .idghamBilaGhunnah:
            return .silents
        case .tafkhim, .qalqalah:
            return .sifaat
        case .maddNatural, .maddSukoon, .maddConnected, .maddSeparated, .maddNecessary:
            return .madd
        case .idghamGhunnah, .ikhfaaLight, .ikhfaaHeavy, .iqlaab:
            return .ghunnah
        }
    }

    var sortRank: Int {
        switch self {
        case .lamShamsiyah: return 0
        case .droppedLetter: return 1
        case .hamzatWaslSilent: return 2
        case .idghamBilaGhunnah: return 3
            
        case .idghamGhunnah: return 4
        case .ikhfaaLight: return 5
        case .ikhfaaHeavy: return 6
        case .iqlaab: return 7
            
        case .qalqalah: return 8
        case .tafkhim: return 9
            
        case .maddNatural: return 10
        case .maddSukoon: return 11
        case .maddSeparated: return 12
        case .maddConnected: return 13
        case .maddNecessary: return 14
        }
    }

    var shortDescription: String {
        switch self {
        case .lamShamsiyah:
            return "Lam of al- is silent before sun letters."
        case .droppedLetter:
            return "Letter written in the script but dropped in recitation."
        case .hamzatWaslSilent:
            return "Start-only hamzah; dropped when connecting."
        case .idghamBilaGhunnah:
            return "Silent-style merge into next without nasal sound."
            
        case .idghamGhunnah:
            return "Merge into the next letter with nasal."
        case .ikhfaaLight:
            return "Lightly hide noon or tanween with nasal."
        case .ikhfaaHeavy:
            return "Heavily hide noon or tanween with nasal."
        case .iqlaab:
            return "Noon/tanween turns to meem before baa."
            
        case .qalqalah:
            return "Qutb jad letters bounce on sukoon/stop."
        case .tafkhim:
            return "Heavy, full-mouth pronunciation."
            
        case .maddNatural:
            return "Normal 2-count madd elongation."
        case .maddSukoon:
            return "Stop-based madd with 2, 4, or 6 counts."
        case .maddSeparated:
            return "Madd at word end before next hamzah."
        case .maddConnected:
            return "Madd letter + hamzah in one word."
        case .maddNecessary:
            return "Fixed required madd due to shaddah after madd."
            
        @unknown default:
            return "Tajweed rule"
        }
    }

    var longDescription: String {
        switch self {
        case .lamShamsiyah:
            return "In connected recitation, this appears most clearly in words beginning with al- followed by sun letters (like ta, daal, seen, sheen). The lam remains in writing but is absorbed into the next consonant, which is heard with emphasis/doubling."
        case .droppedLetter:
            return "This is a practical reading aid for orthographic letters preserved in the Uthmani script while the transmitted recitation does not fully sound them. Examples can include dropped alif, dropped yaa, or similar written forms that remain visible for script fidelity."
        case .hamzatWaslSilent:
            return "Its role is to allow smooth word-initial pronunciation when starting, but to avoid extra breaks mid-flow when linking words. In practice, students should test both states: start from the word (hear hamzah), then connect from before it (hamzah drops)."
        case .idghamBilaGhunnah:
            return "Unlike ghunnah-based merges, no nasal hold is maintained here; the sound moves straight into the target letter. This makes timing cleaner and shorter, so avoid adding extra nasal color by habit."
            
        case .idghamGhunnah:
            return "This uses merging into the next letter with a gentle nasal ghunnah. The sound flows smoothly, with the noon or tanween fully blending into the following letter while maintaining clear timing and resonance."
        case .ikhfaaLight:
            return "This is a light concealment, where the noon or tanween is partially hidden with a soft nasal ghunnah. The sound remains subtle, balancing clarity and smooth transition without fully merging."
        case .ikhfaaHeavy:
            return "This is a heavier concealment, where the noon or tanween is partially hidden with a stronger nasal ghunnah. The tongue prepares for the next letter while the ghunnah carries the sound, requiring careful control and balance."
        case .iqlaab:
            return "The practical cue is the following baa: articulation shifts toward the lips with a meem-quality nasal sound before entering baa. Done correctly, the transition sounds natural and connected rather than abrupt."
            
        case .qalqalah:
            return "The effect is a quick release, not an added harakah and not a long vowel. Strength can vary by position, but the principle stays the same: keep it crisp and brief so the consonant remains clear without over-bouncing."
        case .tafkhim:
            return "A useful way to hear it is contrast: read the same syllable lightly, then with tafkhim, and notice the darker resonance. It is strongest on isti'la letters and should stay controlled so heaviness does not spread into nearby vowels or letters."
        
        case .maddNatural:
            return "Because it is the reference madd length, mastering its steady two-count rhythm helps calibrate all longer madd forms. The stretch should sound even and relaxed, not clipped and not drifting longer than intended."
        case .maddSukoon:
            return "The key condition is pausing at the word ending; if you continue reading (wasl), this special stop-based extension is usually not applied the same way. Recitation schools permit 2, 4, or 6 counts here, so consistency within a reading style matters."
        case .maddSeparated:
            return "Because the hamzah is in the following word, scholars classify this separately from muttasil. Allowed lengths vary by riwayah, so learners should follow one taught pattern and avoid switching counts randomly in the same recitation."
        case .maddConnected:
            return "Since both elements occur inside one word, this is treated as a stronger extension than natural madd. Keep the elongation measured and stable according to your riwayah so the hamzah after it remains clear and not swallowed."
        case .maddNecessary:
            return "This category is fixed and not flexible like optional madd forms, so it should be given its full required length whenever encountered. Its consistency is one of the easiest ways to stabilize rhythm and accuracy in longer passages."
            
        @unknown default:
            return "Tajweed rule"
        }
    }
}
