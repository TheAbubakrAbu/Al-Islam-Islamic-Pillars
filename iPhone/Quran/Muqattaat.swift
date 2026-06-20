import Foundation

/// Spelled-out pronunciation data for the muqatta'at — the disconnected opening letters of 29 surahs
/// (e.g. الٓمٓ). The mushaf prints them joined with maddah marks, but they are recited letter by letter
/// ("Alif Lām Mīm"), so this provides the individual letters, their fully-vocalized Arabic names, and a
/// transliteration to display as a reading aid above the ayah.
///
/// Tashkeel notes (so the names recite — and colour — correctly):
/// - Letters whose names carry a 6-count madd lāzim (نقص عسلكم → ن ق ص ع س ل ك م) are marked with the
///   maddah sign (U+0653) on their long vowel, exactly the way the mushaf marks الٓمٓ. That sign is what
///   the tajweed engine keys madd-lāzim colouring off, so the spelled-out names colour like the real ayah.
/// - The remaining letters (حي طهر → ح ي ط ه ر) take an ordinary 2-count madd, so they get the plain
///   long vowel with no maddah sign.
/// - The shaddah on a final consonant is contextual idghām between adjacent letters, not part of an
///   isolated name. It is applied only where that idghām genuinely happens (e.g. لام → ميم in الٓمٓ
///   gives لَآمّ), and a sukūn is used everywhere else.
enum Muqattaat {
    struct LetterName {
        let letter: Character       // ا
        let transliteration: String // Alif
    }

    /// The 14 distinct letters that appear in the muqatta'at: bare letter + transliteration.
    static let letterNames: [Character: LetterName] = [
        "ا": LetterName(letter: "ا", transliteration: "Alif"),
        "ل": LetterName(letter: "ل", transliteration: "Lām"),
        "م": LetterName(letter: "م", transliteration: "Mīm"),
        "ص": LetterName(letter: "ص", transliteration: "Ṣād"),
        "ر": LetterName(letter: "ر", transliteration: "Rā"),
        "ك": LetterName(letter: "ك", transliteration: "Kāf"),
        "ه": LetterName(letter: "ه", transliteration: "Hā"),
        "ي": LetterName(letter: "ي", transliteration: "Yā"),
        "ع": LetterName(letter: "ع", transliteration: "ʿAyn"),
        "ط": LetterName(letter: "ط", transliteration: "Ṭā"),
        "س": LetterName(letter: "س", transliteration: "Sīn"),
        "ح": LetterName(letter: "ح", transliteration: "Ḥā"),
        "ق": LetterName(letter: "ق", transliteration: "Qāf"),
        "ن": LetterName(letter: "ن", transliteration: "Nūn"),
    ]

    /// Ordered bare letters for each muqatta'at ayah, keyed by surah then ayah. Almost always ayah 1;
    /// Ash-Shura (42) is the exception — its muqatta'at span ayah 1 (Ḥā Mīm) and ayah 2 (ʿAyn Sīn Qāf).
    private static let lettersBySurahAyah: [Int: [Int: [Character]]] = [
        2:  [1: ["ا", "ل", "م"]],
        3:  [1: ["ا", "ل", "م"]],
        7:  [1: ["ا", "ل", "م", "ص"]],
        10: [1: ["ا", "ل", "ر"]],
        11: [1: ["ا", "ل", "ر"]],
        12: [1: ["ا", "ل", "ر"]],
        13: [1: ["ا", "ل", "م", "ر"]],
        14: [1: ["ا", "ل", "ر"]],
        15: [1: ["ا", "ل", "ر"]],
        19: [1: ["ك", "ه", "ي", "ع", "ص"]],
        20: [1: ["ط", "ه"]],
        26: [1: ["ط", "س", "م"]],
        27: [1: ["ط", "س"]],
        28: [1: ["ط", "س", "م"]],
        29: [1: ["ا", "ل", "م"]],
        30: [1: ["ا", "ل", "م"]],
        31: [1: ["ا", "ل", "م"]],
        32: [1: ["ا", "ل", "م"]],
        36: [1: ["ي", "س"]],
        38: [1: ["ص"]],
        40: [1: ["ح", "م"]],
        41: [1: ["ح", "م"]],
        42: [1: ["ح", "م"], 2: ["ع", "س", "ق"]],
        43: [1: ["ح", "م"]],
        44: [1: ["ح", "م"]],
        45: [1: ["ح", "م"]],
        46: [1: ["ح", "م"]],
        50: [1: ["ق"]],
        68: [1: ["ن"]],
    ]

    // Combining marks (kept explicit so the vocalization is unambiguous).
    private static let fatha   = "\u{064E}"
    private static let kasra   = "\u{0650}"
    private static let damma   = "\u{064F}"
    private static let maddah  = "\u{0653}" // the mushaf's madd-lāzim sign, e.g. الٓمٓ
    private static let shaddah = "\u{0651}"
    private static let sukoon  = "\u{0652}"

    // Fully vocalized letter names.
    // Madd-lāzim letters: long vowel + maddah, final consonant sukūn (…ّ when it idghāms into the next).
    private static let alif      = "\u{0623}" + fatha + "\u{0644}" + kasra + "\u{0641}" + sukoon            // أَلِفْ (no madd)
    private static let lamSukoon = "\u{0644}" + fatha + "\u{0627}" + maddah + "\u{0645}" + sukoon           // لَآمْ
    private static let lamIdgham = "\u{0644}" + fatha + "\u{0627}" + maddah + "\u{0645}" + shaddah          // لَآمّ (→ mīm)
    private static let mim       = "\u{0645}" + kasra + "\u{064A}" + maddah + "\u{0645}" + sukoon           // مِيٓمْ
    private static let sad       = "\u{0635}" + fatha + "\u{0627}" + maddah + "\u{062F}" + sukoon           // صَآدْ
    private static let kaf       = "\u{0643}" + fatha + "\u{0627}" + maddah + "\u{0641}" + sukoon           // كَآفْ
    private static let sin       = "\u{0633}" + kasra + "\u{064A}" + maddah + "\u{0646}" + sukoon           // سِيٓنْ
    private static let ayn       = "\u{0639}" + fatha + "\u{064A}" + maddah + "\u{0646}" + sukoon           // عَيٓنْ
    private static let qaf       = "\u{0642}" + fatha + "\u{0627}" + maddah + "\u{0641}" + sukoon           // قَآفْ
    private static let nun       = "\u{0646}" + damma + "\u{0648}" + maddah + "\u{0646}" + sukoon           // نُوٓنْ
    // Natural 2-count madd letters: plain long vowel, no maddah sign.
    private static let ra        = "\u{0631}" + fatha + "\u{0627}"                                          // رَا
    private static let ha        = "\u{0647}" + fatha + "\u{0627}"                                          // هَا
    private static let ya        = "\u{064A}" + fatha + "\u{0627}"                                          // يَا
    private static let taa       = "\u{0637}" + fatha + "\u{0627}"                                          // طَا
    private static let haa       = "\u{062D}" + fatha + "\u{0627}"                                          // حَا

    /// Fully vocalized recitation of each distinct combination, keyed by the bare letters joined.
    private static let vocalizedByLetters: [String: String] = [
        "الم":   [alif, lamIdgham, mim].joined(separator: " "),
        "المص":  [alif, lamIdgham, mim, sad].joined(separator: " "),
        "الر":   [alif, lamSukoon, ra].joined(separator: " "),
        "المر":  [alif, lamIdgham, mim, ra].joined(separator: " "),
        "كهيعص": [kaf, ha, ya, ayn, sad].joined(separator: " "),
        "طه":    [taa, ha].joined(separator: " "),
        "طسم":   [taa, sin, mim].joined(separator: " "),
        "طس":    [taa, sin].joined(separator: " "),
        "يس":    [ya, sin].joined(separator: " "),
        "ص":     sad,
        "حم":    [haa, mim].joined(separator: " "),
        "عسق":   [ayn, sin, qaf].joined(separator: " "),
        "ق":     qaf,
        "ن":     nun,
    ]

    struct Pronunciation {
        let letters: [LetterName]
        /// Fully vocalized letter names, e.g. "أَلِفْ لَآمّ مِيٓمْ".
        let spelledOutArabic: String
        /// Individual letters separated for clarity, e.g. "ا ل م".
        var individualLetters: String { letters.map { String($0.letter) }.joined(separator: " ") }
        /// Transliteration of the letter names, e.g. "Alif Lām Mīm".
        var transliteration: String { letters.map { $0.transliteration }.joined(separator: " ") }
    }

    /// The muqatta'at pronunciation for the given ayah, or nil if that ayah does not open with them.
    static func pronunciation(surah: Int, ayah: Int) -> Pronunciation? {
        guard let chars = lettersBySurahAyah[surah]?[ayah] else { return nil }
        let names = chars.compactMap { letterNames[$0] }
        guard names.count == chars.count, !names.isEmpty else { return nil }
        let vocalized = vocalizedByLetters[String(chars)] ?? names.map { $0.transliteration }.joined(separator: " ")
        return Pronunciation(letters: names, spelledOutArabic: vocalized)
    }
}
