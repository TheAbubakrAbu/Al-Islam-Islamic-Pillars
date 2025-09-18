import SwiftUI

struct LetterData: Identifiable, Codable, Equatable, Comparable {
    let id: Int
    let letter: String
    let forms: [String]
    let name: String
    let transliteration: String
    let showTashkeel: Bool
    let sound: String
    
    static func < (lhs: LetterData, rhs: LetterData) -> Bool {
        return lhs.id < rhs.id
    }
}

struct Tashkeel {
    let english: String
    let arabic: String
    let tashkeelMark: String
    let transliteration: String
}

private enum LetterID {
    private static var nextValue = 1
    static func next() -> Int { defer { nextValue += 1 }; return nextValue }
}

let standardArabicLetters: [LetterData] = [
    LetterData(id: LetterID.next(), letter: "ا", forms: ["ـا", "ـا ـ", "ا ـ"], name: "اَلِف", transliteration: "alif", showTashkeel: false, sound: "a"),
    LetterData(id: LetterID.next(), letter: "ب", forms: ["ـب", "ـبـ", "بـ"], name: "بَاء", transliteration: "baa", showTashkeel: true, sound: "b"),
    LetterData(id: LetterID.next(), letter: "ت", forms: ["ـت", "ـتـ", "تـ"], name: "تَاء", transliteration: "taa", showTashkeel: true, sound: "t"),
    LetterData(id: LetterID.next(), letter: "ث", forms: ["ـث", "ـثـ", "ثـ"], name: "ثَاء", transliteration: "thaa", showTashkeel: true, sound: "th"),
    LetterData(id: LetterID.next(), letter: "ج", forms: ["ـج", "ـجـ", "جـ"], name: "جِيم", transliteration: "jeem", showTashkeel: true, sound: "j"),
    LetterData(id: LetterID.next(), letter: "ح", forms: ["ـح", "ـحـ", "حـ"], name: "حَاء", transliteration: "Haa", showTashkeel: true, sound: "H"),
    LetterData(id: LetterID.next(), letter: "خ", forms: ["ـخ", "ـخـ", "خـ"], name: "خَاء", transliteration: "khaa", showTashkeel: true, sound: "kh"),
    LetterData(id: LetterID.next(), letter: "د", forms: ["ـد", "ـد ـ", "د ـ"], name: "دَال", transliteration: "daal", showTashkeel: true, sound: "d"),
    LetterData(id: LetterID.next(), letter: "ذ", forms: ["ـذ", "ـذ ـ", "ذ ـ"], name: "ذَال", transliteration: "dhaal", showTashkeel: true, sound: "dh"),
    LetterData(id: LetterID.next(), letter: "ر", forms: ["ـر", "ـر ـ", "ر ـ"], name: "رَاء", transliteration: "raa", showTashkeel: true, sound: "r"),
    LetterData(id: LetterID.next(), letter: "ز", forms: ["ـز", "ـز ـ", "ز ـ"], name: "زَاي", transliteration: "zay", showTashkeel: true, sound: "z"),
    LetterData(id: LetterID.next(), letter: "س", forms: ["ـس", "ـسـ", "سـ"], name: "سِين", transliteration: "seen", showTashkeel: true, sound: "s"),
    LetterData(id: LetterID.next(), letter: "ش", forms: ["ـش", "ـشـ", "شـ"], name: "شِين", transliteration: "sheen", showTashkeel: true, sound: "sh"),
    LetterData(id: LetterID.next(), letter: "ص", forms: ["ـص", "ـصـ", "صـ"], name: "صَاد", transliteration: "Saad", showTashkeel: true, sound: "S"),
    LetterData(id: LetterID.next(), letter: "ض", forms: ["ـض", "ـضـ", "ضـ"], name: "ضَاد", transliteration: "Daad", showTashkeel: true, sound: "D"),
    LetterData(id: LetterID.next(), letter: "ط", forms: ["ـط", "ـطـ", "طـ"], name: "طَاء", transliteration: "Taa", showTashkeel: true, sound: "T"),
    LetterData(id: LetterID.next(), letter: "ظ", forms: ["ـظ", "ـظـ", "ظـ"], name: "ظَاء", transliteration: "Dhaa", showTashkeel: true, sound: "Dh"),
    LetterData(id: LetterID.next(), letter: "ع", forms: ["ـع", "ـعـ", "عـ"], name: "عَين", transliteration: "'ayn", showTashkeel: true, sound: "'a"),
    LetterData(id: LetterID.next(), letter: "غ", forms: ["ـغ", "ـغـ", "غـ"], name: "غَين", transliteration: "ghayn", showTashkeel: true, sound: "gh"),
    LetterData(id: LetterID.next(), letter: "ف", forms: ["ـف", "ـفـ", "فـ"], name: "فَاء", transliteration: "faa", showTashkeel: true, sound: "f"),
    LetterData(id: LetterID.next(), letter: "ق", forms: ["ـق", "ـقـ", "قـ"], name: "قَاف", transliteration: "qaaf", showTashkeel: true, sound: "q"),
    LetterData(id: LetterID.next(), letter: "ك", forms: ["ـك", "ـكـ", "كـ"], name: "كَاف", transliteration: "kaaf", showTashkeel: true, sound: "k"),
    LetterData(id: LetterID.next(), letter: "ل", forms: ["ـل", "ـلـ", "لـ"], name: "لَام", transliteration: "laam", showTashkeel: true, sound: "l"),
    LetterData(id: LetterID.next(), letter: "م", forms: ["ـم", "ـمـ", "مـ"], name: "مِيم", transliteration: "meem", showTashkeel: true, sound: "m"),
    LetterData(id: LetterID.next(), letter: "ن", forms: ["ـن", "ـنـ", "نـ"], name: "نُون", transliteration: "noon", showTashkeel: true, sound: "n"),
    LetterData(id: LetterID.next(), letter: "ه", forms: ["ـه", "ـهـ", "هـ"], name: "هَاء", transliteration: "haa", showTashkeel: true, sound: "h"),
    LetterData(id: LetterID.next(), letter: "و", forms: ["ـو", "ـو ـ", "و ـ"], name: "وَاو", transliteration: "waw", showTashkeel: true, sound: "w"),
    LetterData(id: LetterID.next(), letter: "ي", forms: ["ـي", "ـيـ", "يـ"], name: "يَاء", transliteration: "yaa", showTashkeel: true, sound: "y")
]

let otherArabicLetters: [LetterData] = [
    LetterData(id: LetterID.next(), letter: "ة", forms: ["ـة", "ـة ـ", "ة ـ"], name: "تَاء مَربُوطَة", transliteration: "taa marbuuTa", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ء", forms: ["ـ ء", "ـ ء ـ", "ء ـ"], name: "هَمزَة", transliteration: "hamza", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "أ", forms: ["ـأ", "ـأ ـ", "أ ـ"], name: "هَمزَة عَلَى أَلِف", transliteration: "hamza on alif", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "إ", forms: ["ـإ", "ـإ ـ", "إ ـ"], name: "هَمزَة عَلَى أَلِف", transliteration: "hamza on alif", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ئ", forms: ["ـئ", "ـئ ـ", "ئ ـ"], name: "هَمزَة عَلَى يَاء", transliteration: "hamza on yaa", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ؤ", forms: ["ـؤ", "ـؤ ـ", "ؤ ـ"], name: "هَمزَة عَلَى وَاو", transliteration: "hamza on waw", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ٱ", forms: ["ٱـ", "ـٱ", "ـٱـ"], name: "هَمزَة الوَصل", transliteration: "hamzatul waSl", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "آ", forms: ["ـآ", "ـآ ـ", "آ ـ"], name: "أَلِف مَدَّ", transliteration: "alif mad", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "يٓ", forms: ["ـيٓ", "ـيٓـ", "يٓـ"], name: "يَاء مَدّ", transliteration: "yaa mad", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "وٓ", forms: ["ـوٓ", "ـوٓـ", "وٓـ"], name: "واو مَدّ", transliteration: "waw mad", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ى", forms: ["ـى", "ـى ـ", "ى ـ"], name: "أَلِف مَقصُورَة", transliteration: "alif maqSoorah", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ل ا - لا", forms: ["ـلا", "ـلا ـ", "لا ـ"], name: "لَاء", transliteration: "laa", showTashkeel: false, sound: "")
]

let numbers = [
    (number: "٠", name: "صِفر", transliteration: "sifr", englishNumber: "0"),
    (number: "١", name: "وَاحِد", transliteration: "waahid", englishNumber: "1"),
    (number: "٢", name: "اِثنَين", transliteration: "ithnaan", englishNumber: "2"),
    (number: "٣", name: "ثَلاثَة", transliteration: "thalaathah", englishNumber: "3"),
    (number: "٤", name: "أَرْبَعَة", transliteration: "arbaʿah", englishNumber: "4"),
    (number: "٥", name: "خَمْسَة", transliteration: "khamsah", englishNumber: "5"),
    (number: "٦", name: "سِتَّة", transliteration: "sittah", englishNumber: "6"),
    (number: "٧", name: "سَبْعَة", transliteration: "sabʿah", englishNumber: "7"),
    (number: "٨", name: "ثَمَانِيَة", transliteration: "thamaaniyah", englishNumber: "8"),
    (number: "٩", name: "تِسْعَة", transliteration: "tisʿah", englishNumber: "9"),
    (number: "١٠", name: "عَشَرَة", transliteration: "ʿasharah", englishNumber: "10")
]

let tashkeels: [Tashkeel] = [
    Tashkeel(english: "Fatha", arabic: "فَتْحَة", tashkeelMark: "َ", transliteration: "a"),
    Tashkeel(english: "Kasra", arabic: "كَسْرَة", tashkeelMark: "ِ", transliteration: "i"),
    Tashkeel(english: "Damma", arabic: "ضَمَّة", tashkeelMark: "ُ", transliteration: "u"),
    Tashkeel(english: "Fathatayn", arabic: "فَتْحَتَيْن", tashkeelMark: "ًا", transliteration: "an"),
    Tashkeel(english: "Kasratayn", arabic: "كَسْرَتَيْن", tashkeelMark: "ٍ", transliteration: "in"),
    Tashkeel(english: "Dammatayn", arabic: "ضَمَّتَيْن", tashkeelMark: "ٌ", transliteration: "un"),
    Tashkeel(english: "Alif", arabic: "أَلِف", tashkeelMark: "َا", transliteration: "aa"),
    Tashkeel(english: "Yaa", arabic: "يَاء", tashkeelMark: "ِي", transliteration: "ii"),
    Tashkeel(english: "Waw", arabic: "وَاو", tashkeelMark: "ُو", transliteration: "uu"),
    Tashkeel(english: "Dagger Alif", arabic: "ألف خنجرية", tashkeelMark: "َٰ", transliteration: "aa"),
    Tashkeel(english: "Miniature Yaa",arabic: "يَاء صغيرة", tashkeelMark: "ِۦ", transliteration: "ii"),
    Tashkeel(english: "Miniature Waw",arabic: "واو صغيرة", tashkeelMark: "ُۥ", transliteration: "uu"),
    Tashkeel(english: "Alif Mad", arabic: "أَلِف مَدّ", tashkeelMark: "َآ", transliteration: "aaaa"),
    Tashkeel(english: "Yaa Mad", arabic: "يَاء مَدّ", tashkeelMark: "ِيٓ", transliteration: "iiii"),
    Tashkeel(english: "Waw Mad", arabic: "واو مَدّ", tashkeelMark: "ُوٓ", transliteration: "uuuu"),
    Tashkeel(english: "Alif Maqsoorah",arabic: "ياء بلا نقاط", tashkeelMark: "َى", transliteration: "aa"),
    Tashkeel(english: "Shaddah", arabic: "شَدَّة", tashkeelMark: "ّ", transliteration: ""),
    Tashkeel(english: "Sukoon", arabic: "سُكُون", tashkeelMark: "ْ", transliteration: "")
]
