import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

    init(id: Int, idArabic: String, nameArabic: String, nameTransliteration: String, nameEnglish: String, type: String, numberOfAyahs: Int, ayahs: [Ayah]) {
        self.id = id
        self.idArabic = idArabic
        self.nameArabic = nameArabic
        self.nameTransliteration = nameTransliteration
        self.nameEnglish = nameEnglish
        self.type = type
        self.numberOfAyahs = numberOfAyahs
        self.ayahs = ayahs
    }

    /// Ayah count for the given qiraah (e.g. Baqarah has 286 in Hafs but 285 in Warsh). Use for display and range selection.
    func numberOfAyahs(for displayQiraah: String?) -> Int {
        ayahs.filter { $0.existsInQiraah(displayQiraah) }.count
    }
}

struct Ayah: Codable, Identifiable {
    let id: Int
    let idArabic: String

    let textHafs: String
    let textTransliteration: String
    let textEnglishSaheeh: String
    let textEnglishMustafa: String

    let juz: Int?
    let page: Int?

    let textShubah: String?
    
    let textBuzzi: String?
    let textQunbul: String?
    
    let textWarsh: String?
    let textQaloon: String?
    
    let textDuri: String?
    let textSusi: String?

    enum CodingKeys: String, CodingKey {
        case id
        case textHafs = "textArabic"
        case textTransliteration, textEnglishSaheeh, textEnglishMustafa
        case juz, page
        case textWarsh, textQaloon, textDuri, textBuzzi, textQunbul, textShubah, textSusi
    }

    /// Raw Arabic for the given display qiraah. Nil = Hafs.
    func textArabic(for displayQiraah: String?) -> String {
        let raw: String? = {
            guard let q = displayQiraah else { return nil }
            if q.contains("Warsh") { return textWarsh }
            if q.contains("Qaloon") { return textQaloon }
            if q.contains("Duri") || q.contains("Doori") { return textDuri }
            if q.contains("Buzzi") || q.contains("Bazzi") { return textBuzzi }
            if q.contains("Qunbul") || q.contains("Qumbul") { return textQunbul }
            if q.contains("Shu'bah") || q.contains("Shouba") { return textShubah }
            if q.contains("Susi") || q.contains("Soosi") { return textSusi }
            return nil
        }()
        return (raw ?? textHafs).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clean (no diacritics) Arabic for the given display qiraah.
    func textCleanArabic(for displayQiraah: String?) -> String {
        textArabic(for: displayQiraah).removingArabicDiacriticsAndSigns
    }

    /// True if this ayah exists as its own verse in the given qiraah. In Hafs every ayah exists; in Warsh/Qaloon/etc. some Hafs ayahs are merged, so we only show ayahs that have qiraah-specific text (e.g. Baqarah has 286 in Hafs but 285 in Warsh).
    func existsInQiraah(_ displayQiraah: String?) -> Bool {
        guard let q = displayQiraah, !q.isEmpty, q != "Hafs" else {
            return !textHafs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if q.contains("Warsh") { return textWarsh != nil }
        if q.contains("Qaloon") { return textQaloon != nil }
        if q.contains("Duri") || q.contains("Doori") { return textDuri != nil }
        if q.contains("Buzzi") || q.contains("Bazzi") { return textBuzzi != nil }
        if q.contains("Qunbul") || q.contains("Qumbul") { return textQunbul != nil }
        if q.contains("Shu'bah") || q.contains("Shouba") { return textShubah != nil }
        if q.contains("Susi") || q.contains("Soosi") { return textSusi != nil }
        return true
    }

    /// Current riwayah's Arabic (uses Settings.displayQiraahForArabic). Used for display, search, share.
    var textArabic: String { textArabic(for: Settings.shared.displayQiraahForArabic) }
    var textCleanArabic: String { textCleanArabic(for: Settings.shared.displayQiraahForArabic) }

    /// Clean Bismillah (no diacritics). Shown for Fatiha 1 when the riwayah’s first ayah is ta'awwudh.
    static let bismillahCleanArabic = "بسم الله الرحمن الرحيم"

    /// Arabic to show in UI. For Fatiha ayah 1 with clean mode, if the ayah doesn’t start with بسم (e.g. ta'awwudh), shows Bismillah instead.
    /// - Parameter qiraahOverride: When non-nil, use this qiraah instead of Settings (e.g. comparison mode). Use "" for Hafs.
    func displayArabicText(surahId: Int, clean: Bool, qiraahOverride: String? = nil) -> String {
        let qiraah: String? = if let override = qiraahOverride {
            (override.isEmpty || override == "Hafs") ? nil : override
        } else {
            Settings.shared.displayQiraahForArabic
        }
        let text = clean ? textCleanArabic(for: qiraah) : textArabic(for: qiraah)
        if surahId == 1 && id == 1 && clean {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.hasPrefix("بسم") {
                return Self.bismillahCleanArabic
            }
        }
        return text
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        textHafs = try c.decode(String.self, forKey: .textHafs)
        textTransliteration = try c.decode(String.self, forKey: .textTransliteration)
        textEnglishSaheeh = try c.decode(String.self, forKey: .textEnglishSaheeh)
        textEnglishMustafa = try c.decode(String.self, forKey: .textEnglishMustafa)
        juz = try c.decodeIfPresent(Int.self, forKey: .juz)
        page = try c.decodeIfPresent(Int.self, forKey: .page)
        textWarsh = try c.decodeIfPresent(String.self, forKey: .textWarsh)
        textQaloon = try c.decodeIfPresent(String.self, forKey: .textQaloon)
        textDuri = try c.decodeIfPresent(String.self, forKey: .textDuri)
        textBuzzi = try c.decodeIfPresent(String.self, forKey: .textBuzzi)
        textQunbul = try c.decodeIfPresent(String.self, forKey: .textQunbul)
        textShubah = try c.decodeIfPresent(String.self, forKey: .textShubah)
        textSusi = try c.decodeIfPresent(String.self, forKey: .textSusi)
        idArabic = arabicNumberString(from: id)
    }

    init(id: Int, idArabic: String, textHafs: String, textTransliteration: String, textEnglishSaheeh: String, textEnglishMustafa: String, juz: Int? = nil, page: Int? = nil, textWarsh: String?, textQaloon: String?, textDuri: String?, textBuzzi: String?, textQunbul: String?, textShubah: String?, textSusi: String?) {
        self.id = id
        self.idArabic = idArabic
        self.textHafs = textHafs
        self.textTransliteration = textTransliteration
        self.textEnglishSaheeh = textEnglishSaheeh
        self.textEnglishMustafa = textEnglishMustafa
        self.juz = juz
        self.page = page
        self.textWarsh = textWarsh
        self.textQaloon = textQaloon
        self.textDuri = textDuri
        self.textBuzzi = textBuzzi
        self.textQunbul = textQunbul
        self.textShubah = textShubah
        self.textSusi = textSusi
    }

    /// Arabic to display; pass qiraah and whether to strip diacritics.
    func displayArabic(qiraah: String?, clean: Bool) -> String {
        clean ? textCleanArabic(for: qiraah) : textArabic(for: qiraah)
    }
}

struct TajweedRange: Codable, Hashable {
    let rule: String
    let start: Int
    let end: Int
}

struct TajweedAyahEntry: Codable, Hashable {
    let surah: Int
    let ayah: Int
    let annotations: [TajweedRange]
}

enum TajweedLegendCategory: String, CaseIterable, Identifiable {
    case tafkhim
    case qalqalah
    case ikhfaGhunnah
    case idghaamSilent
    case madd246
    case madd2
    case madd6
    case madd45

    var id: String { rawValue }

    var englishTitle: String {
        switch self {
        case .tafkhim: return "Tafkhim"
        case .qalqalah: return "Qalqalah"
        case .ikhfaGhunnah: return "Ikhfa / Ghunnah"
        case .idghaamSilent: return "Idghaam / Silent"
        case .madd246: return "Madd 2, 4, or 6"
        case .madd2: return "Madd 2"
        case .madd6: return "Madd 6"
        case .madd45: return "Madd 4 or 5"
        }
    }

    var arabicTitle: String {
        switch self {
        case .tafkhim: return "تفخيم"
        case .qalqalah: return "قلقلة"
        case .ikhfaGhunnah: return "إخفاء / الغنة"
        case .idghaamSilent: return "إدغام / ما لا يُلفظ"
        case .madd246: return "مد ٢ أو ٤ أو ٦ جوازًا"
        case .madd2: return "مد حركتان"
        case .madd6: return "مد ٦ حركات لزوماً"
        case .madd45: return "مد واجب ٤ أو ٥ حركات"
        }
    }

    var color: Color {
        switch self {
        case .tafkhim: return Color(red: 0.0, green: 0.45, blue: 0.55)
        case .qalqalah: return Color(red: 0.0, green: 0.75, blue: 0.75)
        case .ikhfaGhunnah: return Color(red: 0.0, green: 0.65, blue: 0.30)
        case .idghaamSilent: return .gray
        case .madd246: return Color(red: 0.85, green: 0.50, blue: 0.0)
        case .madd2: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .madd6: return Color(red: 0.85, green: 0.0, blue: 0.45)
        case .madd45: return Color(red: 0.70, green: 0.0, blue: 0.60)
        }
    }

    var shortDescription: String {
        switch self {
        case .tafkhim: return "Heavy pronunciation."
        case .qalqalah: return "A bouncing echo sound."
        case .ikhfaGhunnah: return "Hidden or nasalized sound."
        case .idghaamSilent: return "Merged or not pronounced."
        case .madd246: return "Permissible madd length."
        case .madd2: return "Natural madd."
        case .madd6: return "Obligatory six counts."
        case .madd45: return "Obligatory connected madd."
        }
    }

    var longDescription: String {
        switch self {
        case .tafkhim:
            return "Tafkhim marks heavy pronunciation. This includes the permanently heavy letters, and also special heavy cases like heavy raa and the heavy laam in the Name of Allah in the right contexts."
        case .qalqalah:
            return "Qalqalah gives a slight echo or bounce to the letters of qalqalah when they are in sukoon, especially at a stop."
        case .ikhfaGhunnah:
            return "This color groups ikhfa, ghunnah, and similar nasalized recitation cases. It helps show where a softened hidden sound or clear nasal holding is needed."
        case .idghaamSilent:
            return "This color groups idghaam, letters that are not pronounced, and similar merged or dropped-reading cases."
        case .madd246:
            return "This marks permissible madd cases, such as places where the elongation may be read with multiple accepted lengths."
        case .madd2:
            return "This marks natural madd, where the sound is lengthened for two counts."
        case .madd6:
            return "This marks obligatory madd that is read with six counts."
        case .madd45:
            return "This marks madd wajib, such as madd muttasil, where the elongation is read with four or five counts."
        }
    }
}

final class TajweedStore {
    static let shared = TajweedStore()

    private static let implicitBismillahScalarCount = 39
    private static let resourceName = "TajweedRules"
    private static let heavyBaseLetters: Set<Character> = ["خ", "ص", "ض", "ط", "ظ", "غ", "ق"]
    private static let qalqalahLetters: Set<Character> = ["ق", "ط", "ب", "ج", "د"]
    private static let maddBaseLetters: Set<Character> = ["ا", "و", "ي", "ى", "آ"]
    private static let alifFollowerLetters: Set<Character> = ["ا", "ى"]
    private static let fatha = UnicodeScalar(0x064E)!
    private static let damma = UnicodeScalar(0x064F)!
    private static let fathatayn = UnicodeScalar(0x064B)!
    private static let dammatayn = UnicodeScalar(0x064C)!
    private static let kasra = UnicodeScalar(0x0650)!
    private static let kasratayn = UnicodeScalar(0x064D)!
    private static let sukoon = UnicodeScalar(0x0652)!
    private static let sukoonUthmani = UnicodeScalar(0x06E1)!
    private static let maddahAbove = UnicodeScalar(0x0653)!
    private static let daggerAlif = UnicodeScalar(0x0670)!
    private static let smallWaw = UnicodeScalar(0x06E5)!
    private static let smallYeh = UnicodeScalar(0x06E6)!

    private var ayahLookup: [Int: [Int: [TajweedRange]]] = [:]
    private var attributedCache: [Int: [Int: AttributedString]] = [:]
    private var lastVisibilitySignature = ""
    private let settings = Settings.shared

    private init() {
        load()
    }

    func attributedText(surah: Int, ayah: Int, text: String) -> AttributedString? {
        let visibilitySignature = tajweedVisibilitySignature()
        if visibilitySignature != lastVisibilitySignature {
            attributedCache.removeAll()
            lastVisibilitySignature = visibilitySignature
        }

        if let cached = attributedCache[surah]?[ayah] {
            return cached
        }

        let annotations = ayahLookup[surah]?[ayah] ?? []

        let normalized = normalizedAnnotations(
            annotations,
            surah: surah,
            ayah: ayah,
            textLength: text.unicodeScalars.count
        )

        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(
            .foregroundColor,
            value: platformColor(for: .primary),
            range: NSRange(location: 0, length: attributed.length)
        )

        for annotation in normalized {
            guard let category = category(for: annotation.rule), settings.isTajweedCategoryVisible(category) else {
                continue
            }
            guard let range = nsRange(
                source: text,
                rule: annotation.rule,
                start: annotation.start,
                end: annotation.end
            ) else { continue }
            attributed.addAttribute(
                .foregroundColor,
                value: platformColor(for: category.color),
                range: range
            )
        }

        let hasHeavyStyling = settings.isTajweedCategoryVisible(.tafkhim) && applyHeavyLetterColoring(to: attributed, source: text)

        if normalized.isEmpty && !hasHeavyStyling {
            return nil
        }

        let bridged = AttributedString(attributed)

        var cacheForSurah = attributedCache[surah] ?? [:]
        cacheForSurah[ayah] = bridged
        attributedCache[surah] = cacheForSurah

        return bridged
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: Self.resourceName, withExtension: "json", subdirectory: "JSONs")
                ?? Bundle.main.url(forResource: Self.resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TajweedAyahEntry].self, from: data) else {
            return
        }

        var lookup: [Int: [Int: [TajweedRange]]] = [:]
        lookup.reserveCapacity(114)

        for entry in decoded {
            var ayahsForSurah = lookup[entry.surah] ?? [:]
            ayahsForSurah[entry.ayah] = entry.annotations
            lookup[entry.surah] = ayahsForSurah
        }

        ayahLookup = lookup
    }

    private func normalizedAnnotations(
        _ annotations: [TajweedRange],
        surah: Int,
        ayah: Int,
        textLength: Int
    ) -> [TajweedRange] {
        let direct = annotations.filter { isValid($0, textLength: textLength) }
        if direct.count == annotations.count {
            return direct
        }

        guard ayah == 1, surah != 1, surah != 9 else {
            return direct
        }

        let shifted = annotations.compactMap { annotation -> TajweedRange? in
            let shiftedAnnotation = TajweedRange(
                rule: annotation.rule,
                start: annotation.start - Self.implicitBismillahScalarCount,
                end: annotation.end - Self.implicitBismillahScalarCount
            )
            return isValid(shiftedAnnotation, textLength: textLength) ? shiftedAnnotation : nil
        }

        return shifted.isEmpty ? direct : shifted
    }

    private func isValid(_ annotation: TajweedRange, textLength: Int) -> Bool {
        annotation.start >= 0 && annotation.end > annotation.start && annotation.end <= textLength
    }

    private func nsRange(
        source: String,
        rule: String,
        start: Int,
        end: Int
    ) -> NSRange? {
        if rule == "lam_shamsiyyah" {
            return singleScalarNSRange(in: source, startScalar: start, endScalar: end, preferredScalar: "ل")
        }
        if rule == "qalqalah" {
            return singleClusterNSRange(
                in: source,
                startScalar: start,
                endScalar: end,
                preferredBases: Self.qalqalahLetters,
                includePreviousPreferredBaseForCombiningCluster: true
            )
        }
        if isMaddRule(rule) {
            return maddNSRange(in: source, startScalar: start, endScalar: end)
        }

        guard let clusterRange = characterClusterUTF16Range(
            in: source,
            startScalar: start,
            endScalar: end,
            extendForwardClusters: 0
        ) else {
            return nil
        }

        return NSRange(location: clusterRange.lowerBound, length: clusterRange.upperBound - clusterRange.lowerBound)
    }

    private func singleScalarNSRange(
        in text: String,
        startScalar: Int,
        endScalar: Int,
        preferredScalar: Character? = nil
    ) -> NSRange? {
        guard startScalar >= 0, endScalar > startScalar else { return nil }

        var scalarOffset = 0
        var utf16Offset = 0
        var fallbackRange: NSRange?

        for scalar in text.unicodeScalars {
            let length = String(scalar).utf16.count
            defer {
                scalarOffset += 1
                utf16Offset += length
            }

            guard scalarOffset >= startScalar, scalarOffset < endScalar else { continue }

            let range = NSRange(location: utf16Offset, length: length)
            if fallbackRange == nil {
                fallbackRange = range
            }

            if preferredScalar == nil || Character(scalar) == preferredScalar {
                return range
            }
        }

        return fallbackRange
    }

    private func singleClusterNSRange(
        in text: String,
        startScalar: Int,
        endScalar: Int,
        preferredBases: Set<Character>,
        includePreviousPreferredBaseForCombiningCluster: Bool = false
    ) -> NSRange? {
        guard startScalar >= 0, endScalar > startScalar else { return nil }

        let targetScalars = startScalar..<endScalar
        let characters = Array(text)
        var currentScalarOffset = 0
        var currentUTF16Offset = 0

        for (index, character) in characters.enumerated() {
            let clusterText = String(character)
            let scalarCount = character.unicodeScalars.count
            let utf16Count = clusterText.utf16.count
            let scalarRange = currentScalarOffset..<(currentScalarOffset + scalarCount)
            let utf16Range = NSRange(location: currentUTF16Offset, length: utf16Count)

            defer {
                currentScalarOffset += scalarCount
                currentUTF16Offset += utf16Count
            }

            guard scalarRange.overlaps(targetScalars) else { continue }

            if let base = clusterText.first, preferredBases.contains(base) {
                return utf16Range
            }

            if includePreviousPreferredBaseForCombiningCluster,
               isCombiningOnlyCluster(character),
               index > 0 {
                if let previousRange = previousPreferredClusterRange(
                    in: characters,
                    before: index,
                    preferredBases: preferredBases
                ) {
                    return NSRange(
                        location: previousRange.location,
                        length: (utf16Range.location + utf16Range.length) - previousRange.location
                    )
                }
            }
        }

        return nil
    }

    private func isMaddRule(_ rule: String) -> Bool {
        rule == "madd_2"
        || rule == "madd_246"
        || rule == "madd_6"
        || rule == "madd_muttasil"
        || rule == "madd_munfasil"
    }

    private func maddNSRange(in text: String, startScalar: Int, endScalar: Int) -> NSRange? {
        guard startScalar >= 0, endScalar > startScalar else { return nil }

        let targetScalars = startScalar..<endScalar
        let characters = Array(text)
        var currentScalarOffset = 0
        var currentUTF16Offset = 0

        for (index, character) in characters.enumerated() {
            let clusterText = String(character)
            let scalarCount = character.unicodeScalars.count
            let utf16Count = clusterText.utf16.count
            let scalarRange = currentScalarOffset..<(currentScalarOffset + scalarCount)
            let utf16Range = NSRange(location: currentUTF16Offset, length: utf16Count)

            defer {
                currentScalarOffset += scalarCount
                currentUTF16Offset += utf16Count
            }

            guard scalarRange.overlaps(targetScalars) else { continue }

            if let tinyRange = selectedScalarsRange(
                in: clusterText,
                globalUTF16Offset: currentUTF16Offset,
                matching: { scalar in
                    scalar == Self.daggerAlif
                    || scalar == Self.smallWaw
                    || scalar == Self.smallYeh
                    || scalar == Self.maddahAbove
                },
                requiring: { scalars in
                    scalars.contains(Self.daggerAlif)
                    || scalars.contains(Self.smallWaw)
                    || scalars.contains(Self.smallYeh)
                }
            ) {
                return tinyRange
            }

            if let base = clusterText.first, Self.maddBaseLetters.contains(base) {
                return utf16Range
            }

            if clusterText.unicodeScalars.contains(Self.maddahAbove) {
                return utf16Range
            }

            if isCombiningOnlyCluster(character), index > 0 {
                if let previousRange = previousPreferredClusterRange(
                    in: characters,
                    before: index,
                    preferredBases: Self.maddBaseLetters
                ) {
                    return NSRange(
                        location: previousRange.location,
                        length: (utf16Range.location + utf16Range.length) - previousRange.location
                    )
                }
            }
        }

        return nil
    }

    private func previousPreferredClusterRange(
        in characters: [Character],
        before index: Int,
        preferredBases: Set<Character>
    ) -> NSRange? {
        guard index > 0 else { return nil }

        var utf16Offset = 0
        var ranges: [NSRange] = []
        ranges.reserveCapacity(characters.count)

        for character in characters {
            let length = String(character).utf16.count
            ranges.append(NSRange(location: utf16Offset, length: length))
            utf16Offset += length
        }

        var candidateIndex = index - 1
        while candidateIndex >= 0 {
            let text = String(characters[candidateIndex])
            if isCombiningOnlyCluster(characters[candidateIndex]) {
                candidateIndex -= 1
                continue
            }
            if let base = text.first, preferredBases.contains(base) {
                return ranges[candidateIndex]
            }
            break
        }

        return nil
    }

    private func selectedScalarsRange(
        in clusterText: String,
        globalUTF16Offset: Int,
        matching: (UnicodeScalar) -> Bool,
        requiring requirement: ([UnicodeScalar]) -> Bool
    ) -> NSRange? {
        let scalars = Array(clusterText.unicodeScalars)
        guard requirement(scalars) else { return nil }

        var localUTF16Offset = 0
        var start: Int?
        var end: Int?

        for scalar in scalars {
            let length = String(scalar).utf16.count
            defer { localUTF16Offset += length }

            guard matching(scalar) else { continue }
            if start == nil {
                start = globalUTF16Offset + localUTF16Offset
            }
            end = globalUTF16Offset + localUTF16Offset + length
        }

        guard let start, let end, end > start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    private func isCombiningOnlyCluster(_ character: Character) -> Bool {
        let scalars = Array(String(character).unicodeScalars)
        guard !scalars.isEmpty else { return false }
        return scalars.allSatisfy { $0.properties.generalCategory == .nonspacingMark || $0.properties.generalCategory == .spacingMark }
    }

    private func characterClusterUTF16Range(
        in text: String,
        startScalar: Int,
        endScalar: Int,
        extendForwardClusters: Int = 0
    ) -> Range<Int>? {
        guard startScalar >= 0, endScalar > startScalar else { return nil }

        struct ClusterSlice {
            let scalarRange: Range<Int>
            let utf16Range: Range<Int>
        }

        var clusters: [ClusterSlice] = []
        clusters.reserveCapacity(text.count)

        var currentScalarOffset = 0
        var currentUTF16Offset = 0

        for character in text {
            let scalarCount = character.unicodeScalars.count
            let utf16Count = String(character).utf16.count
            let scalarRange = currentScalarOffset..<(currentScalarOffset + scalarCount)
            let utf16Range = currentUTF16Offset..<(currentUTF16Offset + utf16Count)

            clusters.append(ClusterSlice(scalarRange: scalarRange, utf16Range: utf16Range))

            currentScalarOffset += scalarCount
            currentUTF16Offset += utf16Count
        }

        guard endScalar <= currentScalarOffset else { return nil }

        let targetScalars = startScalar..<endScalar
        guard let firstIndex = clusters.firstIndex(where: { $0.scalarRange.overlaps(targetScalars) }) else {
            return nil
        }

        guard let lastMatchedIndex = clusters.lastIndex(where: { $0.scalarRange.overlaps(targetScalars) }) else {
            return nil
        }

        let lastIndex = min(lastMatchedIndex + extendForwardClusters, clusters.count - 1)
        return clusters[firstIndex].utf16Range.lowerBound..<clusters[lastIndex].utf16Range.upperBound
    }

    private func platformColor(for color: Color) -> AnyObject {
        #if canImport(UIKit)
        return UIColor(color)
        #elseif canImport(AppKit)
        return NSColor(color)
        #else
        return color as AnyObject
        #endif
    }

    private struct CharacterClusterInfo {
        let text: String
        let utf16Range: Range<Int>

        var base: Character? {
            text.first
        }

        func contains(_ scalar: UnicodeScalar) -> Bool {
            text.unicodeScalars.contains(scalar)
        }
    }

    private func characterClusters(in text: String) -> [CharacterClusterInfo] {
        var clusters: [CharacterClusterInfo] = []
        clusters.reserveCapacity(text.count)

        var currentUTF16Offset = 0
        for character in text {
            let clusterText = String(character)
            let utf16Count = clusterText.utf16.count
            let utf16Range = currentUTF16Offset..<(currentUTF16Offset + utf16Count)
            clusters.append(CharacterClusterInfo(text: clusterText, utf16Range: utf16Range))
            currentUTF16Offset += utf16Count
        }

        return clusters
    }

    private func tajweedVisibilitySignature() -> String {
        TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined(separator: "")
    }

    private func applyHeavyLetterColoring(to attributed: NSMutableAttributedString, source text: String) -> Bool {
        let clusters = characterClusters(in: text)
        var applied = false

        for index in clusters.indices where shouldUseHeavyColor(clusters: clusters, index: index) {
            let range = NSRange(
                location: clusters[index].utf16Range.lowerBound,
                length: clusters[index].utf16Range.upperBound - clusters[index].utf16Range.lowerBound
            )
            attributed.addAttribute(
                .foregroundColor,
                value: platformColor(for: TajweedLegendCategory.tafkhim.color),
                range: range
            )
            applied = true
        }

        return applied
    }

    private func shouldUseHeavyColor(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let base = clusters[index].base else { return false }

        if Self.heavyBaseLetters.contains(base) {
            return true
        }

        if base == "ر" {
            return isHeavyRaa(clusters: clusters, index: index)
        }

        if base == "ل" {
            return isHeavyAllahLam(clusters: clusters, index: index)
        }

        if Self.alifFollowerLetters.contains(base), index > 0 {
            return isHeavyCarrier(clusters: clusters, index: index - 1)
        }

        return false
    }

    private func isHeavyCarrier(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let base = clusters[index].base else { return false }
        if Self.heavyBaseLetters.contains(base) {
            return true
        }
        if base == "ر" {
            return isHeavyRaa(clusters: clusters, index: index)
        }
        if base == "ل" {
            return isHeavyAllahLam(clusters: clusters, index: index)
        }
        return false
    }

    private func previousCluster(in clusters: [CharacterClusterInfo], before index: Int) -> CharacterClusterInfo? {
        guard index > 0 else { return nil }
        return clusters[index - 1]
    }

    private func hasHeavyOpenVowel(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.fatha) ||
        cluster.contains(Self.damma) ||
        cluster.contains(Self.fathatayn) ||
        cluster.contains(Self.dammatayn)
    }

    private func hasKasraFamily(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.kasra) ||
        cluster.contains(Self.kasratayn)
    }

    private func hasSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoon) || cluster.contains(Self.sukoonUthmani)
    }

    private func hasDaggerAlif(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.daggerAlif)
    }

    private func isHeavyRaa(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        let current = clusters[index]

        if hasKasraFamily(current) {
            return false
        }

        if hasHeavyOpenVowel(current) {
            return true
        }

        guard hasSukoon(current), let prev = previousCluster(in: clusters, before: index) else {
            return false
        }

        if hasHeavyOpenVowel(prev) || hasDaggerAlif(prev) {
            return true
        }

        if let prevBase = prev.base, Self.alifFollowerLetters.contains(prevBase), index >= 2 {
            let beforePrev = clusters[index - 2]
            if hasHeavyOpenVowel(beforePrev) || hasDaggerAlif(beforePrev) {
                return true
            }
        }

        if prev.base == "و", hasSukoon(prev), index >= 2 {
            let beforePrev = clusters[index - 2]
            if beforePrev.contains(Self.damma) || beforePrev.contains(Self.dammatayn) {
                return true
            }
        }

        return false
    }

    private func isHeavyAllahLam(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].base == "ل" else { return false }

        let isFirstLamInAllah =
            index >= 1 &&
            clusters[index - 1].base == "ا" &&
            index + 2 < clusters.count &&
            clusters[index + 1].base == "ل" &&
            clusters[index + 2].base == "ه"

        let isSecondLamInAllah =
            index >= 2 &&
            clusters[index - 2].base == "ا" &&
            clusters[index - 1].base == "ل" &&
            index + 1 < clusters.count &&
            clusters[index + 1].base == "ه"

        guard isFirstLamInAllah || isSecondLamInAllah else { return false }

        let wordStartIndex = isFirstLamInAllah ? index - 1 : index - 2
        guard wordStartIndex > 0 else { return false }

        let prev = clusters[wordStartIndex - 1]
        return hasHeavyOpenVowel(prev)
    }

    private func category(for rule: String) -> TajweedLegendCategory? {
        if rule == "madd_2" { return .madd2 }
        if rule == "madd_6" { return .madd6 }
        if rule == "madd_muttasil" { return .madd45 }
        if rule == "madd_246" || rule == "madd_munfasil" { return .madd246 }
        if rule == "ghunnah" || rule == "iqlab" || rule.hasPrefix("ikhfa") { return .ikhfaGhunnah }
        if rule.hasPrefix("idghaam") || rule == "lam_shamsiyyah" || rule == "silent" {
            return .idghaamSilent
        }
        if rule == "qalqalah" { return .qalqalah }
        return nil
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
    /// Qiraah key the verse index was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedVerseIndexQiraah: String? = nil
    /// Qiraah key the boundary model was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedBoundaryQiraah: String? = nil
    private var surahBoundaryModels = [Int: SurahBoundaryModel]()

    private var loadTask: Task<Void, Never>?
    private static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }

    private init() {}

    private func startLoading() {
        loadTask = Task(priority: .userInitiated) { [weak self] in
            await self?.load()
        }
    }

    func waitUntilLoaded() async {
        await loadTask?.value
    }

    private struct QiraatAyahEntry: Codable {
        let id: Int
        let text: String?
        let textArabic: String?
        var displayText: String? { text ?? textArabic }
    }

    private static let qiraatKeys: [(filename: String, key: String)] = [
        ("QiraahWarsh", "textWarsh"),
        ("QiraahQaloon", "textQaloon"),
        ("QiraahDuri", "textDuri"),
        ("QiraahBuzzi", "textBuzzi"),
        ("QiraahQunbul", "textQunbul"),
        ("QiraahShubah", "textShubah"),
        ("QiraahSusi", "textSusi"),
    ]

    /// key (e.g. "textWarsh") -> surahId -> ayahId -> text
    private func loadQiraatOverlay() -> [String: [Int: [Int: String]]] {
        var result: [String: [Int: [Int: String]]] = [:]
        for (filename, key) in Self.qiraatKeys {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "JSONs/Qiraat")
                ?? Bundle.main.url(forResource: filename, withExtension: "json") else { continue }
            guard let data = try? Data(contentsOf: url),
                  let raw = try? JSONDecoder().decode([String: [QiraatAyahEntry]].self, from: data) else { continue }
            var bySurah: [Int: [Int: String]] = [:]
            for (surahStr, ayahs) in raw {
                guard let surahId = Int(surahStr) else { continue }
                var lookup: [Int: String] = [:]
                for entry in ayahs {
                    if let t = entry.displayText, !t.isEmpty { lookup[entry.id] = t }
                }
                bySurah[surahId] = lookup
            }
            result[key] = bySurah
        }
        return result
    }

    private func load() async {
        guard let url = Bundle.main.url(forResource: "Quran", withExtension: "json") else {
            let message = "Quran.json missing"
            logger.error("\(message)")
            if Self.isRunningInPreview { return }
            fatalError(message)
        }

        do {
            let data = try Data(contentsOf: url)
            var surahs = try JSONDecoder().decode([Surah].self, from: data)

            let overlay = loadQiraatOverlay()
            if !overlay.isEmpty {
                surahs = surahs.map { surah in
                    let baseAyahsByID = Dictionary(uniqueKeysWithValues: surah.ayahs.map { ($0.id, $0) })

                    var allAyahIDs = Set(baseAyahsByID.keys)
                    for key in ["textWarsh", "textQaloon", "textDuri", "textBuzzi", "textQunbul", "textShubah", "textSusi"] {
                        if let overlayIDs = overlay[key]?[surah.id]?.keys {
                            allAyahIDs.formUnion(overlayIDs)
                        }
                    }

                    let ayahs = allAyahIDs.sorted().map { ayahID in
                        let base = baseAyahsByID[ayahID]

                        return Ayah(
                            id: ayahID,
                            idArabic: base?.idArabic ?? arabicNumberString(from: ayahID),
                            textHafs: base?.textHafs ?? "",
                            textTransliteration: base?.textTransliteration ?? "",
                            textEnglishSaheeh: base?.textEnglishSaheeh ?? "",
                            textEnglishMustafa: base?.textEnglishMustafa ?? "",
                            juz: base?.juz,
                            page: base?.page,
                            textWarsh: overlay["textWarsh"]?[surah.id]?[ayahID] ?? base?.textWarsh,
                            textQaloon: overlay["textQaloon"]?[surah.id]?[ayahID] ?? base?.textQaloon,
                            textDuri: overlay["textDuri"]?[surah.id]?[ayahID] ?? base?.textDuri,
                            textBuzzi: overlay["textBuzzi"]?[surah.id]?[ayahID] ?? base?.textBuzzi,
                            textQunbul: overlay["textQunbul"]?[surah.id]?[ayahID] ?? base?.textQunbul,
                            textShubah: overlay["textShubah"]?[surah.id]?[ayahID] ?? base?.textShubah,
                            textSusi: overlay["textSusi"]?[surah.id]?[ayahID] ?? base?.textSusi
                        )
                    }

                    return Surah(id: surah.id, idArabic: surah.idArabic, nameArabic: surah.nameArabic, nameTransliteration: surah.nameTransliteration, nameEnglish: surah.nameEnglish, type: surah.type, numberOfAyahs: surah.numberOfAyahs, ayahs: ayahs)
                }
            }

            let (sIndex, aIndex) = buildIndexes(for: surahs)
            let surahsToPublish = surahs
            let displayQiraah = settings.displayQiraahForArabic
            let vIndex = surahsToPublish.flatMap { surah in
                surah.ayahs.map { ayah in
                    let raw = ayah.textArabic(for: displayQiraah)
                    let clean = ayah.textCleanArabic(for: displayQiraah)
                    let arabicBlob = [raw, clean].map { settings.cleanSearch($0) }.joined(separator: " ")
                    let latinBlob = [
                        ayah.textEnglishSaheeh,
                        ayah.textEnglishMustafa,
                        ayah.textTransliteration
                    ].map { settings.cleanSearch($0) }.joined(separator: " ")
                    return VerseIndexEntry(
                        id: "\(surah.id):\(ayah.id)",
                        surah: surah.id,
                        ayah: ayah.id,
                        arabicBlob: arabicBlob,
                        englishBlob: latinBlob
                    )
                }
            }
            let boundaryModels = buildBoundaryModels(for: surahsToPublish, displayQiraah: displayQiraah)

            await MainActor.run {
                self.surahIndex = sIndex
                self.ayahIndex = aIndex
                self.quran = surahsToPublish
                self.verseIndex = vIndex
                self.cachedVerseIndexQiraah = displayQiraah ?? ""
                self.surahBoundaryModels = boundaryModels
                self.cachedBoundaryQiraah = displayQiraah ?? ""
            }
        } catch {
            let message = "Failed to load Quran: \(error.localizedDescription)"
            logger.error("\(message)")
            if Self.isRunningInPreview { return }
            fatalError(message)
        }
    }

    private func rebuildVerseIndex() {
        let displayQiraah = settings.displayQiraahForArabic
        verseIndex = quran.flatMap { surah in
            surah.ayahs.map { ayah in
                let raw = ayah.textArabic(for: displayQiraah)
                let clean = ayah.textCleanArabic(for: displayQiraah)
                let arabicBlob = [raw, clean].map { settings.cleanSearch($0) }.joined(separator: " ")
                let latinBlob = [
                    ayah.textEnglishSaheeh,
                    ayah.textEnglishMustafa,
                    ayah.textTransliteration
                ].map { settings.cleanSearch($0) }.joined(separator: " ")
                return VerseIndexEntry(
                    id: "\(surah.id):\(ayah.id)",
                    surah: surah.id,
                    ayah: ayah.id,
                    arabicBlob: arabicBlob,
                    englishBlob: latinBlob
                )
            }
        }
    }

    private func rebuildBoundaryModels() {
        let displayQiraah = settings.displayQiraahForArabic
        surahBoundaryModels = buildBoundaryModels(for: quran, displayQiraah: displayQiraah)
        cachedBoundaryQiraah = displayQiraah ?? ""
    }

    private func boundaryText(from oldAyah: Ayah, to newAyah: Ayah) -> String? {
        let pageChanged = oldAyah.page != newAyah.page
        let juzChanged = oldAyah.juz != newAyah.juz
        guard pageChanged || juzChanged else { return nil }

        if let page = newAyah.page, let juz = newAyah.juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page = newAyah.page {
            return "Page \(page)"
        }
        if let juz = newAyah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func boundaryText(for ayah: Ayah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page = ayah.page {
            return "Page \(page)"
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func boundaryStyle(pageChanged: Bool, juzChanged: Bool) -> BoundaryDividerStyle {
        if pageChanged {
            return juzChanged ? .allAccent : .pageAccentJuzSecondary
        }
        if juzChanged {
            return .allAccent
        }
        return .allSecondary
    }

    private func dividerModel(from text: String, style: BoundaryDividerStyle) -> BoundaryDividerModel {
        if let juzRange = text.range(of: "Juz ") {
            let prefix = String(text[..<juzRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if prefix.isEmpty {
                return BoundaryDividerModel(
                    text: text,
                    pageSegment: text,
                    juzSegment: nil,
                    style: style
                )
            }
            let pageSegment = prefix.trimmingCharacters(in: CharacterSet(charactersIn: " -•").union(.whitespacesAndNewlines))
            let juzSegment = String(text[juzRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return BoundaryDividerModel(
                text: text,
                pageSegment: pageSegment,
                juzSegment: juzSegment,
                style: style
            )
        }

        return BoundaryDividerModel(
            text: text,
            pageSegment: text,
            juzSegment: nil,
            style: style
        )
    }

    private func buildBoundaryModels(for surahs: [Surah], displayQiraah: String?) -> [Int: SurahBoundaryModel] {
        var result = [Int: SurahBoundaryModel]()
        result.reserveCapacity(surahs.count)

        for (index, surah) in surahs.enumerated() {
            let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(displayQiraah) }
            guard !ayahsForQiraah.isEmpty else {
                result[surah.id] = SurahBoundaryModel(
                    startDivider: nil,
                    startDividerHighlighted: false,
                    dividerBeforeAyah: [:],
                    endOfSurahDivider: nil,
                    endDivider: nil,
                    endDividerHighlighted: false
                )
                continue
            }

            let startDividerText = ayahsForQiraah.first.flatMap { boundaryText(for: $0) }
            let startDividerHighlighted: Bool = {
                guard index > 0,
                      let firstAyah = ayahsForQiraah.first else { return false }
                let previousSurah = surahs[index - 1]
                let previousLastAyah = previousSurah.ayahs.last { $0.existsInQiraah(displayQiraah) }
                guard let previousLastAyah else { return false }
                return previousLastAyah.page != firstAyah.page || previousLastAyah.juz != firstAyah.juz
            }()
            let startDividerStyle: BoundaryDividerStyle = {
                if surah.id == 1 { return .allGreen }
                guard index > 0,
                      let firstAyah = ayahsForQiraah.first else { return .allSecondary }
                let previousSurah = surahs[index - 1]
                let previousLastAyah = previousSurah.ayahs.last { $0.existsInQiraah(displayQiraah) }
                guard let previousLastAyah else { return .allSecondary }
                return boundaryStyle(
                    pageChanged: previousLastAyah.page != firstAyah.page,
                    juzChanged: previousLastAyah.juz != firstAyah.juz
                )
            }()

            var dividerBeforeAyah = [Int: BoundaryDividerModel]()
            if ayahsForQiraah.count > 1 {
                for i in 1..<ayahsForQiraah.count {
                    let prev = ayahsForQiraah[i - 1]
                    let current = ayahsForQiraah[i]
                    if let text = boundaryText(from: prev, to: current) {
                        dividerBeforeAyah[current.id] = dividerModel(
                            from: text,
                            style: boundaryStyle(pageChanged: prev.page != current.page, juzChanged: prev.juz != current.juz)
                        )
                    }
                }
            }

            var endDividerText: String? = nil
            var endDividerHighlighted = false
            var endOfSurahDividerText: String? = nil
            var endBoundaryJuzChanged = false
            var endBoundaryPageChanged = false
            var nextFirstAyah: Ayah? = nil
            if index + 1 < surahs.count {
                let nextSurah = surahs[index + 1]
                if let lastAyah = ayahsForQiraah.last,
                   let nextAyah = nextSurah.ayahs.first(where: { $0.existsInQiraah(displayQiraah) }) {
                    nextFirstAyah = nextAyah
                    endDividerText = boundaryText(from: lastAyah, to: nextAyah)
                    endBoundaryPageChanged = lastAyah.page != nextAyah.page
                    endBoundaryJuzChanged = lastAyah.juz != nextAyah.juz
                    endDividerHighlighted = lastAyah.page != nextAyah.page || lastAyah.juz != nextAyah.juz
                }
            }

            if let nextFirstAyah {
                endOfSurahDividerText = boundaryText(for: nextFirstAyah)
            } else if let lastAyah = ayahsForQiraah.last {
                if let page = lastAyah.page {
                    if let juz = lastAyah.juz {
                        endOfSurahDividerText = "Page \(page) • Juz \(juz)"
                    } else {
                        endOfSurahDividerText = "Page \(page)"
                    }
                } else if let juz = lastAyah.juz {
                    endOfSurahDividerText = "Juz \(juz)"
                }
            }
            let endDividerStyle = boundaryStyle(pageChanged: endBoundaryPageChanged, juzChanged: endBoundaryJuzChanged)
            let endOfSurahDividerStyle: BoundaryDividerStyle = {
                if surah.id == 114 { return .allGreen }
                return endDividerStyle
            }()

            result[surah.id] = SurahBoundaryModel(
                startDivider: startDividerText.map { dividerModel(from: $0, style: startDividerStyle) },
                startDividerHighlighted: startDividerHighlighted,
                dividerBeforeAyah: dividerBeforeAyah,
                endOfSurahDivider: endOfSurahDividerText.map { dividerModel(from: $0, style: endOfSurahDividerStyle) },
                endDivider: endDividerText.map { dividerModel(from: $0, style: endDividerStyle) },
                endDividerHighlighted: endDividerHighlighted
            )
        }

        return result
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
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedVerseIndexQiraah != currentKey {
            rebuildVerseIndex()
            cachedVerseIndexQiraah = currentKey
        }
        guard !verseIndex.isEmpty else { return [] }

        let q = settings.cleanSearch(raw, whitespace: true)
        guard !q.isEmpty else { return [] }
        if q.rangeOfCharacter(from: .decimalDigits) != nil { return [] }

        let useArabic = raw.containsArabicLetters

        var results: [VerseIndexEntry] = []
        results.reserveCapacity(limit == .max ? 64 : min(limit, 64))

        var skipped = 0
        for entry in verseIndex {
            let haystack = useArabic ? entry.arabicBlob : entry.englishBlob
            if haystack.contains(q) {
                if skipped < offset { skipped += 1; continue }
                results.append(entry)
                if limit != .max, results.count >= limit { break }
            }
        }

        return results
    }

    func boundaryModel(forSurah surahID: Int) -> SurahBoundaryModel? {
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedBoundaryQiraah != currentKey {
            rebuildBoundaryModels()
        }
        return surahBoundaryModels[surahID]
    }
    
    func searchVersesAll(term raw: String) -> [VerseIndexEntry] {
        withAnimation {
            searchVerses(term: raw, limit: .max, offset: 0)
        }
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
            nameArabic: "تِلكَ ٱلرُّسُلُ",
            nameTransliteration: "Tilka Rusulu",
            startSurah: 2, startAyah: 253,
            endSurah: 3, endAyah: 92
        ),

        Juz(id: 4,
            nameArabic: "كُلُّ ٱلطَّعَامِ",
            nameTransliteration: "Kullu al-ta'am",
            startSurah: 3, startAyah: 93,
            endSurah: 4, endAyah: 23
        ),

        Juz(id: 5,
            nameArabic: "وَٱلمُحصَنَاتُ",
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
            nameArabic: "لَتَجِدَنَّ أَشَدَّ",
            nameTransliteration: "Latajidanna Ashadd",
            startSurah: 5, startAyah: 82,
            endSurah: 6, endAyah: 110
        ),

        Juz(id: 8,
            nameArabic: "وَلَو أَنَّنَا",
            nameTransliteration: "Walau Annanaa",
            startSurah: 6, startAyah: 111,
            endSurah: 7, endAyah: 87
        ),

        Juz(id: 9,
            nameArabic: "قَالَ ٱلمَلَأُ",
            nameTransliteration: "Qaalal-Mala'u",
            startSurah: 7, startAyah: 88,
            endSurah: 8, endAyah: 40
        ),

        Juz(id: 10,
            nameArabic: "وَٱعلَمُوا",
            nameTransliteration: "Wa'alamu",
            startSurah: 8, startAyah: 41,
            endSurah: 9, endAyah: 92
        ),

        Juz(id: 11,
            nameArabic: "إِنَّمَا ٱلسَّبِيلُ",
            nameTransliteration: "Innama al-sabeel",
            startSurah: 9, startAyah: 93,
            endSurah: 11, endAyah: 5
        ),

        Juz(id: 12,
            nameArabic: "وَمَا مِن دَآبَّةٍ",
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
            nameArabic: "سُبحَانَ ٱلَّذِى",
            nameTransliteration: "Subhana Allathee",
            startSurah: 17, startAyah: 1,
            endSurah: 18, endAyah: 74
        ),

        Juz(id: 16,
            nameArabic: "قَالَ أَلَم",
            nameTransliteration: "Qaala Alam",
            startSurah: 18, startAyah: 75,
            endSurah: 20, endAyah: 135
        ),

        Juz(id: 17,
            nameArabic: "ٱقتَرَبَ لِلنَّاسِ",
            nameTransliteration: "Iqtaraba Linnaasi",
            startSurah: 21, startAyah: 1,
            endSurah: 22, endAyah: 78
        ),

        Juz(id: 18,
            nameArabic: "قَد أَفلَحَ",
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
            nameArabic: "فَمَا كَانَ جَوَابَ",
            nameTransliteration: "Fama kana jawaab",
            startSurah: 27, startAyah: 56,
            endSurah: 29, endAyah: 45
        ),

        Juz(id: 21,
            nameArabic: "وَلَا تُجَٰدِلُوٓاْ",
            nameTransliteration: "Wa la tujadiloo",
            startSurah: 29, startAyah: 46,
            endSurah: 33, endAyah: 30
        ),

        Juz(id: 22,
            nameArabic: "وَمَن يَّقنُت",
            nameTransliteration: "Waman Yaqnut",
            startSurah: 33, startAyah: 31,
            endSurah: 36, endAyah: 27
        ),

        Juz(id: 23,
            nameArabic: "وَمَآ أَنزَلۡنَا",
            nameTransliteration: "Wa ma anzalna",
            startSurah: 36, startAyah: 28,
            endSurah: 39, endAyah: 31
        ),

        Juz(id: 24,
            nameArabic: "فَمَن أَظلَمُ",
            nameTransliteration: "Faman Adhlamu",
            startSurah: 39, startAyah: 32,
            endSurah: 41, endAyah: 46
        ),

        Juz(id: 25,
            nameArabic: "إِلَيهِ يُرَدُّ",
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
            nameArabic: "قَالَ فَمَا خَطبُكُم",
            nameTransliteration: "Qaala Famaa Khatbukum",
            startSurah: 51, startAyah: 31,
            endSurah: 57, endAyah: 29
        ),

        Juz(id: 28,
            nameArabic: "قَد سَمِعَ ٱللهُ",
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
