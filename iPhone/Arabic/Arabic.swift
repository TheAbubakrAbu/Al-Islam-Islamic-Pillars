import SwiftUI

class LetterDataFactory {
    private var idCounter = 1

    func makeLetterData(letter: String, forms: [String], name: String, transliteration: String, showTashkeel: Bool, sound: String) -> LetterData {
        let data = LetterData(id: idCounter, letter: letter, forms: forms, name: name, transliteration: transliteration, showTashkeel: showTashkeel, sound: sound)
        idCounter += 1
        return data
    }
}

let factory = LetterDataFactory()

let standardArabicLetters = [
    factory.makeLetterData(letter: "ا", forms: ["ـا", "ـا ـ", "ا ـ"], name: "اَلِف", transliteration: "alif", showTashkeel: false, sound: "a"),
    factory.makeLetterData(letter: "ب", forms: ["ـب", "ـبـ", "بـ"], name: "بَاء", transliteration: "baa", showTashkeel: true, sound: "b"),
    factory.makeLetterData(letter: "ت", forms: ["ـت", "ـتـ", "تـ"], name: "تَاء", transliteration: "taa", showTashkeel: true, sound: "t"),
    factory.makeLetterData(letter: "ث", forms: ["ـث", "ـثـ", "ثـ"], name: "ثَاء", transliteration: "thaa", showTashkeel: true, sound: "th"),
    factory.makeLetterData(letter: "ج", forms: ["ـج", "ـجـ", "جـ"], name: "جِيم", transliteration: "jeem", showTashkeel: true, sound: "j"),
    factory.makeLetterData(letter: "ح", forms: ["ـح", "ـحـ", "حـ"], name: "حَاء", transliteration: "Haa", showTashkeel: true, sound: "H"),
    factory.makeLetterData(letter: "خ", forms: ["ـخ", "ـخـ", "خـ"], name: "خَاء", transliteration: "khaa", showTashkeel: true, sound: "kh"),
    factory.makeLetterData(letter: "د", forms: ["ـد", "ـد ـ", "د ـ"], name: "دَال", transliteration: "daal", showTashkeel: true, sound: "d"),
    factory.makeLetterData(letter: "ذ", forms: ["ـذ", "ـذ ـ", "ذ ـ"], name: "ذَال", transliteration: "dhaal", showTashkeel: true, sound: "dh"),
    factory.makeLetterData(letter: "ر", forms: ["ـر", "ـر ـ", "ر ـ"], name: "رَاء", transliteration: "raa", showTashkeel: true, sound: "r"),
    factory.makeLetterData(letter: "ز", forms: ["ـز", "ـز ـ", "ز ـ"], name: "زَاي", transliteration: "zay", showTashkeel: true, sound: "z"),
    factory.makeLetterData(letter: "س", forms: ["ـس", "ـسـ", "سـ"], name: "سِين", transliteration: "seen", showTashkeel: true, sound: "s"),
    factory.makeLetterData(letter: "ش", forms: ["ـش", "ـشـ", "شـ"], name: "شِين", transliteration: "sheen", showTashkeel: true, sound: "sh"),
    factory.makeLetterData(letter: "ص", forms: ["ـص", "ـصـ", "صـ"], name: "صَاد", transliteration: "Saad", showTashkeel: true, sound: "S"),
    factory.makeLetterData(letter: "ض", forms: ["ـض", "ـضـ", "ضـ"], name: "ضَاد", transliteration: "Daad", showTashkeel: true, sound: "D"),
    factory.makeLetterData(letter: "ط", forms: ["ـط", "ـطـ", "طـ"], name: "طَاء", transliteration: "Taa", showTashkeel: true, sound: "T"),
    factory.makeLetterData(letter: "ظ", forms: ["ـظ", "ـظـ", "ظـ"], name: "ظَاء", transliteration: "Dhaa", showTashkeel: true, sound: "Dh"),
    factory.makeLetterData(letter: "ع", forms: ["ـع", "ـعـ", "عـ"], name: "عَين", transliteration: "'ayn", showTashkeel: true, sound: "'a"),
    factory.makeLetterData(letter: "غ", forms: ["ـغ", "ـغـ", "غـ"], name: "غَين", transliteration: "ghayn", showTashkeel: true, sound: "gh"),
    factory.makeLetterData(letter: "ف", forms: ["ـف", "ـفـ", "فـ"], name: "فَاء", transliteration: "faa", showTashkeel: true, sound: "f"),
    factory.makeLetterData(letter: "ق", forms: ["ـق", "ـقـ", "قـ"], name: "قَاف", transliteration: "qaaf", showTashkeel: true, sound: "q"),
    factory.makeLetterData(letter: "ك", forms: ["ـك", "ـكـ", "كـ"], name: "كَاف", transliteration: "kaaf", showTashkeel: true, sound: "k"),
    factory.makeLetterData(letter: "ل", forms: ["ـل", "ـلـ", "لـ"], name: "لَام", transliteration: "laam", showTashkeel: true, sound: "l"),
    factory.makeLetterData(letter: "م", forms: ["ـم", "ـمـ", "مـ"], name: "مِيم", transliteration: "meem", showTashkeel: true, sound: "m"),
    factory.makeLetterData(letter: "ن", forms: ["ـن", "ـنـ", "نـ"], name: "نُون", transliteration: "noon", showTashkeel: true, sound: "n"),
    factory.makeLetterData(letter: "ه", forms: ["ـه", "ـهـ", "هـ"], name: "هَاء", transliteration: "haa", showTashkeel: true, sound: "h"),
    factory.makeLetterData(letter: "و", forms: ["ـو", "ـو ـ", "و ـ"], name: "وَاو", transliteration: "waw", showTashkeel: true, sound: "w"),
    factory.makeLetterData(letter: "ي", forms: ["ـي", "ـيـ", "يـ"], name: "يَاء", transliteration: "yaa", showTashkeel: true, sound: "y"),
]

let otherArabicLetters = [
    factory.makeLetterData(letter: "ة", forms: ["ـة", "ـة ـ", "ة ـ"], name: "تَاء مَربُوطَة", transliteration: "taa marbuuTa", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "ء", forms: ["ـ ء", "ـ ء ـ", "ء ـ"], name: "هَمزَة", transliteration: "hamza", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "أ", forms: ["ـأ", "ـأ ـ", "أ ـ"], name: "هَمزَة عَلَى أَلِف", transliteration: "hamza on alif", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "إ", forms: ["ـإ", "ـإ ـ", "إ ـ"], name: "هَمزَة عَلَى أَلِف", transliteration: "hamza on alif", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "ئ", forms: ["ـئ", "ـئ ـ", "ئ ـ"], name: "هَمزَة عَلَى يَاء", transliteration: "hamza on yaa", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "ؤ", forms: ["ـؤ", "ـؤ ـ", "ؤ ـ"], name: "هَمزَة عَلَى وَاو", transliteration: "hamza on waw", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "ٱ", forms: ["ٱـ", "ـٱ", "ـٱـ"], name: "هَمزَة الوَصل", transliteration: "hamzatul waSl", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "آ", forms: ["ـآ", "ـآ ـ", "آ ـ"], name: "أَلِف مَدَّ", transliteration: "alif mad", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "يٓ", forms: ["ـيٓ", "ـيٓـ", "يٓـ"], name: "يَاء مَدّ", transliteration: "yaa mad", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "وٓ", forms: ["ـوٓ", "ـوٓـ", "وٓـ"], name: "واو مَدّ", transliteration: "waw mad", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "ى", forms: ["ـى", "ـى ـ", "ى ـ"], name: "أَلِف مَقصُورَة", transliteration: "alif maqSoorah", showTashkeel: false, sound: ""),
    factory.makeLetterData(letter: "ل ا - لا", forms: ["ـلا", "ـلا ـ", "لا ـ"], name: "لَاء", transliteration: "laa", showTashkeel: false, sound: ""),
]

let numbers = [
    (number: "٠", name: "صِفر", transliteration: "sifr", englishNumber: "0"),
    (number: "١", name: "وَاحِد", transliteration: "waahid", englishNumber: "1"),
    (number: "٢", name: "اِثنَين", transliteration: "ithnaan", englishNumber: "2"),
    (number: "٣", name: "ثَلاثَة", transliteration: "thalaathah", englishNumber: "3"),
    (number: "٤", name: "أَربَعَة", transliteration: "arbaʿah", englishNumber: "4"),
    (number: "٥", name: "خَمسَة", transliteration: "khamsah", englishNumber: "5"),
    (number: "٦", name: "سِتَّة", transliteration: "sittah", englishNumber: "6"),
    (number: "٧", name: "سَبعَة", transliteration: "sabʿah", englishNumber: "7"),
    (number: "٨", name: "ثَمانِيَة", transliteration: "thamaaniyah", englishNumber: "8"),
    (number: "٩", name: "تِسعَة", transliteration: "tisʿah", englishNumber: "9"),
    (number: "١٠", name: "عَشَرَة", transliteration: "ʿasharah", englishNumber: "10"),
]

let tashkeels = [
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
    Tashkeel(english: "Miniature Yaa", arabic: "يَاء صغيرة", tashkeelMark: "ِۦ", transliteration: "ii"),
    Tashkeel(english: "Miniature Waw", arabic: "واو صغيرة", tashkeelMark: "ُۥ", transliteration: "uu"),
    Tashkeel(english: "Alif Mad", arabic: "أَلِف مَدّ", tashkeelMark: "َآ", transliteration: "aaaa"),
    Tashkeel(english: "Yaa Mad", arabic: "يَاء مَدّ", tashkeelMark: "ِيٓ", transliteration: "iiii"),
    Tashkeel(english: "Waw Mad", arabic: "واو مَدّ", tashkeelMark: "ُوٓ", transliteration: "uuuu"),
    Tashkeel(english: "Alif Maqsoorah", arabic: "ياء بلا نقاط", tashkeelMark: "َى", transliteration: "aa"),
    Tashkeel(english: "Shaddah", arabic: "شَدَّة", tashkeelMark: "ّ", transliteration: ""),
    Tashkeel(english: "Sukoon", arabic: "سُكُون", tashkeelMark: "ْ", transliteration: "")
]

struct Tashkeel {
    let english: String
    let arabic: String
    let tashkeelMark: String
    let transliteration: String
}
