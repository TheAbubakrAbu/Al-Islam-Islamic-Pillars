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
    let similarNames: [String]

    let type: String
    let numberOfAyahs: Int

    let revelationOrder: Int?
    let revelationExceptions: String?

    let pageStart: Int?
    let pageEnd: Int?
    let numberOfPages: Int?
    let isLessThanOnePage: Bool?

    let firstJuz: Int?
    let lastJuz: Int?
    let juzs: [Int]?

    let ayahs: [Ayah]

    enum CodingKeys: String, CodingKey {
        case id, nameArabic, nameTransliteration, nameEnglish, similarNames, type, numberOfAyahs
        case revelationOrder, revelationExceptions
        case pageStart, pageEnd, numberOfPages, isLessThanOnePage
        case firstJuz, lastJuz, juzs
        case ayahs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        nameArabic = try c.decode(String.self, forKey: .nameArabic)
        nameTransliteration = try c.decode(String.self, forKey: .nameTransliteration)
        nameEnglish = try c.decode(String.self, forKey: .nameEnglish)
        similarNames = try c.decodeIfPresent([String].self, forKey: .similarNames) ?? []
        type = try c.decode(String.self, forKey: .type)
        numberOfAyahs = try c.decode(Int.self, forKey: .numberOfAyahs)
        ayahs = try c.decode([Ayah].self, forKey: .ayahs)

        revelationOrder = try c.decodeIfPresent(Int.self, forKey: .revelationOrder)
        revelationExceptions = try c.decodeIfPresent(String.self, forKey: .revelationExceptions)

        pageStart = try c.decodeIfPresent(Int.self, forKey: .pageStart)
        pageEnd = try c.decodeIfPresent(Int.self, forKey: .pageEnd)
        numberOfPages = try c.decodeIfPresent(Int.self, forKey: .numberOfPages)
        isLessThanOnePage = try c.decodeIfPresent(Bool.self, forKey: .isLessThanOnePage)

        firstJuz = try c.decodeIfPresent(Int.self, forKey: .firstJuz)
        lastJuz = try c.decodeIfPresent(Int.self, forKey: .lastJuz)
        juzs = try c.decodeIfPresent([Int].self, forKey: .juzs)

        idArabic = arabicNumberString(from: id)
    }

    init(
        id: Int,
        idArabic: String,
        nameArabic: String,
        nameTransliteration: String,
        nameEnglish: String,
        similarNames: [String] = [],
        type: String,
        numberOfAyahs: Int,
        revelationOrder: Int? = nil,
        revelationExceptions: String? = nil,
        pageStart: Int? = nil,
        pageEnd: Int? = nil,
        numberOfPages: Int? = nil,
        isLessThanOnePage: Bool? = nil,
        firstJuz: Int? = nil,
        lastJuz: Int? = nil,
        juzs: [Int]? = nil,
        ayahs: [Ayah]
    ) {
        self.id = id
        self.idArabic = idArabic
        self.nameArabic = nameArabic
        self.nameTransliteration = nameTransliteration
        self.nameEnglish = nameEnglish
        self.similarNames = similarNames
        self.type = type
        self.numberOfAyahs = numberOfAyahs
        self.revelationOrder = revelationOrder
        self.revelationExceptions = revelationExceptions

        self.pageStart = pageStart
        self.pageEnd = pageEnd
        self.numberOfPages = numberOfPages
        self.isLessThanOnePage = isLessThanOnePage

        self.firstJuz = firstJuz
        self.lastJuz = lastJuz
        self.juzs = juzs

        self.ayahs = ayahs
    }

    var pageCount: Int {
        if let n = numberOfPages, n > 0 { return n }
        if let start = pageStart, let end = pageEnd, end >= start {
            return (end - start) + 1
        }
        return 1
    }

    var pageCountLabel: String {
        let count = max(pageCount, 1)
        if count == 1, isLessThanOnePage == true {
            #if os(iOS)
            return "<1 Page"
            #else
            return "<1 Pg"
            #endif
        }
        
        #if os(iOS)
        return count == 1 ? "1 Page" : "\(count) Pages"
        #else
        return count == 1 ? "1 Pg" : "\(count) Pgs"
        #endif
    }

    func ayahCountLabel(for displayQiraah: String? = nil) -> String {
        let count = displayQiraah == nil ? numberOfAyahs : numberOfAyahs(for: displayQiraah)
        return count == 1 ? "1 Ayah" : "\(count) Ayahs"
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
            guard let qIn = displayQiraah else { return nil }
            let q = Settings.normalizeLegacyRiwayahTag(qIn)
            switch q {
            case Settings.Riwayah.warsh: return textWarsh
            case Settings.Riwayah.qaloon: return textQaloon
            case Settings.Riwayah.duri: return textDuri
            case Settings.Riwayah.buzzi: return textBuzzi
            case Settings.Riwayah.qunbul: return textQunbul
            case Settings.Riwayah.shubah: return textShubah
            case Settings.Riwayah.susi: return textSusi
            default: return nil
            }
        }()
        return (raw ?? textHafs).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clean (no diacritics) Arabic for the given display qiraah.
    func textCleanArabic(for displayQiraah: String?) -> String {
        textArabic(for: displayQiraah).removingArabicDiacriticsAndSigns
    }

    /// True if this ayah exists as its own verse in the given qiraah. In Hafs every ayah exists; in Warsh/Qaloon/etc. some Hafs ayahs are merged, so we only show ayahs that have qiraah-specific text (e.g. Baqarah has 286 in Hafs but 285 in Warsh).
    func existsInQiraah(_ displayQiraah: String?) -> Bool {
        guard let qIn = displayQiraah, !qIn.isEmpty, qIn != "Hafs" else {
            return !textHafs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let q = Settings.normalizeLegacyRiwayahTag(qIn)
        switch q {
        case Settings.Riwayah.hafsTag: return !textHafs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case Settings.Riwayah.warsh: return textWarsh != nil
        case Settings.Riwayah.qaloon: return textQaloon != nil
        case Settings.Riwayah.duri: return textDuri != nil
        case Settings.Riwayah.buzzi: return textBuzzi != nil
        case Settings.Riwayah.qunbul: return textQunbul != nil
        case Settings.Riwayah.shubah: return textShubah != nil
        case Settings.Riwayah.susi: return textSusi != nil
        default: return true
        }
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

final class TajweedStore {
    static let shared = TajweedStore()

    private static let heavyBaseLetters: Set<Character> = ["خ", "ص", "ض", "ط", "ظ", "غ", "ق"]
    private static let qalqalahLetters: Set<Character> = ["ق", "ط", "ب", "ج", "د"]
    private static let sunLetters: Set<Character> = ["ت", "ث", "د", "ذ", "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ", "ل", "ن"]
    private static let alifFollowerLetters: Set<Character> = ["ا", "ى"]
    private static let fatha = UnicodeScalar(0x064E)!
    private static let damma = UnicodeScalar(0x064F)!
    private static let fathatayn = UnicodeScalar(0x064B)!
    private static let dammatayn = UnicodeScalar(0x064C)!
    private static let kasra = UnicodeScalar(0x0650)!
    private static let kasratayn = UnicodeScalar(0x064D)!
    private static let sukoon = UnicodeScalar(0x0652)!
    private static let sukoonUthmani = UnicodeScalar(0x06E1)!
    private static let shadda = UnicodeScalar(0x0651)!
    private static let daggerAlif = UnicodeScalar(0x0670)!
    private static let maddah = UnicodeScalar(0x0653)!
    private static let hamzatWasl = UnicodeScalar(0x0671)!
    private static let smallWaw = UnicodeScalar(0x06E5)!
    private static let smallYeh = UnicodeScalar(0x06E6)!

    /// Surahs whose first ayah opens with disconnected letters (حروف مقطعة); maddah on those letters uses madd lazim coloring.
    private static let surahsOpeningMuqattaat: Set<Int> = [
        2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 26, 27, 28, 29, 30, 31, 32,
        36, 38, 40, 41, 42, 43, 44, 45, 46, 50, 68,
    ]

    /// Quranic pause / ornamental marks (U+06D6...U+06ED) - never tajweed-colored. Keep Uthmani sukun and miniature madd letters paintable.
    private static let waqfScalarSkipColorLower: UInt32 = 0x06D6
    private static let waqfScalarSkipColorUpper: UInt32 = 0x06ED
    private static let waqfScalarExceptions: Set<UInt32> = [0x06E1, 0x06E5, 0x06E6]

    /// Higher value wins when painting overlapping UTF-16 units.
    private enum PaintPriority {
        static let tafkhim = 1
        static let sukoonJazm = 2
        static let lamShamsiyah = 3
        static let qalqalah = 4
        static let idghamBiGhunnah = 5
        static let ikhfaa = 6
        static let iqlab = 7
        static let idghamBilaGhunnah = 8
        static let maddNatural2 = 12
        /// Miniature madd scalars (U+06E5, U+06E6, U+0670) use same category as natural madd; slightly higher priority than letter-body natural madd.
        static let maddNatural2MiniatureScalars = 13
        static let maddNecessary6 = 18
        static let maddSeparated = 19
        static let maddConnected = 20
        static let hamzatWaslSilent = 50
    }

    private struct AttributedCacheKey: Hashable {
        let surah: Int
        let ayah: Int
        let textDigest: UInt64
    }

    private struct TajweedAyahKey: Hashable {
        let surah: Int
        let ayah: Int
    }

    private struct TajweedRuleAnnotation: Decodable {
        let start: Int
        let end: Int
        let rule: String
    }

    private struct TajweedRuleAyah: Decodable {
        let surah: Int
        let ayah: Int
        let annotations: [TajweedRuleAnnotation]
    }

    private static let treeDrivenRuleMap: [String: TajweedLegendCategory] = [
        "madd_2": .maddNatural2,
        "madd_munfasil": .maddSeparated,
        "madd_muttasil": .maddConnected,
        "madd_6": .maddNecessary6,
        "madd_246": .maddNecessary6,
        "qalqalah": .qalqalah,
        "silent": .hamzatWaslSilent,
        "idghaam_ghunnah": .idghamBiGhunnah,
        "idghaam_shafawi": .idghamBiGhunnah,
        "idghaam_no_ghunnah": .idghamBilaGhunnah,
        "idghaam_mutajanisayn": .idghamBiGhunnah,
        "idghaam_mutaqaribayn": .idghamBiGhunnah,
        "ikhfa": .ikhfaa,
        "ikhfa_shafawi": .ikhfaa,
        "iqlab": .iqlab,
    ]

    private static let specialTanweenCategories: Set<TajweedLegendCategory> = [
        .idghamBiGhunnah,
        .ikhfaa,
        .iqlab,
        .idghamBilaGhunnah,
    ]

    private static let tajweedRuleTreesByAyah: [TajweedAyahKey: [TajweedRuleAnnotation]] = {
        guard let url = tajweedRulesResourceURL() else { return [:] }
        guard let data = try? Data(contentsOf: url) else { return [:] }
        guard let decoded = try? JSONDecoder().decode([TajweedRuleAyah].self, from: data) else { return [:] }
        var out: [TajweedAyahKey: [TajweedRuleAnnotation]] = [:]
        out.reserveCapacity(decoded.count)
        for item in decoded {
            out[TajweedAyahKey(surah: item.surah, ayah: item.ayah)] = item.annotations
        }
        return out
    }()

    private static func tajweedRulesResourceURL() -> URL? {
        let bundle = Bundle.main
        if let nested = bundle.url(forResource: "TajweedRules", withExtension: "json", subdirectory: "JSONs") {
            return nested
        }
        return bundle.url(forResource: "TajweedRules", withExtension: "json")
    }

    private var attributedCache: [AttributedCacheKey: AttributedString] = [:]
    private var lastVisibilitySignature = ""
    private let settings = Settings.shared

    private struct PaintOp {
        let range: NSRange
        let priority: Int
        let category: TajweedLegendCategory
        let color: Color?

        init(range: NSRange, priority: Int, category: TajweedLegendCategory, color: Color? = nil) {
            self.range = range
            self.priority = priority
            self.category = category
            self.color = color
        }
    }

    private static let bareTashkeelScalars: Set<UInt32> = [
        0x064B, 0x064C, 0x064D, 0x064E, 0x064F, 0x0650,
        0x0651, 0x0652, 0x0653, 0x0656, 0x0657, 0x0670,
        0x06E1, 0x06E5, 0x06E6
    ]

    private init() {}

    /// Stable fingerprint so cache invalidates when verse text changes (qiraah, data updates).
    private static func stableTextDigest(_ string: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    func attributedText(surah: Int, ayah: Int, text: String) -> AttributedString? {
        let visibilitySignature = tajweedVisibilitySignature()
        if visibilitySignature != lastVisibilitySignature {
            attributedCache.removeAll()
            lastVisibilitySignature = visibilitySignature
        }

        let cacheKey = AttributedCacheKey(surah: surah, ayah: ayah, textDigest: Self.stableTextDigest(text))
        if let cached = attributedCache[cacheKey] {
            return cached
        }

        guard !text.isEmpty else { return nil }
        guard TajweedLegendCategory.allCases.contains(where: { settings.isTajweedCategoryVisible($0) }) else {
            return nil
        }

        // Use NSAttributedString for UTF-16 painting. Per-code-unit Swift `Range(NSRange,in: String)` often
        // fails inside Arabic grapheme clusters, so `AttributedString.Index(..., within:)` skipped all colors.
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.foregroundColor, value: platformLabelColor(), range: fullRange)

        let utf16Count = attributed.length
        var priorityPerUTF16 = [Int](repeating: 0, count: utf16Count)

        var ops: [PaintOp] = []
        let clusters = characterClusters(in: text)

        if settings.isTajweedCategoryVisible(.tafkhim) {
            for index in clusters.indices where shouldUseHeavyColor(clusters: clusters, index: index) {
                ops.append(PaintOp(range: nsRange(for: clusters[index]), priority: PaintPriority.tafkhim, category: .tafkhim))
            }
        }

        if settings.isTajweedCategoryVisible(.sukoonJazm) {
            for cluster in clusters where hasStandardSukoon(cluster) {
                guard let base = cluster.primaryArabicLetter, isArabicLetterBase(base) else { continue }
                if Self.qalqalahLetters.contains(base), settings.isTajweedCategoryVisible(.qalqalah) {
                    continue
                }
                ops.append(PaintOp(range: nsRange(for: cluster), priority: PaintPriority.sukoonJazm, category: .sukoonJazm))
            }
        }

        if settings.isTajweedCategoryVisible(.lamShamsiyah) {
            for index in clusters.indices where isLamShamsiyah(clusters: clusters, index: index) {
                ops.append(PaintOp(range: nsRange(for: clusters[index]), priority: PaintPriority.lamShamsiyah, category: .lamShamsiyah))
            }
        }

        if settings.isTajweedCategoryVisible(.qalqalah) {
            let verseFinalQalqalahIndex = indexOfVerseFinalQalqalahCluster(clusters: clusters)
            for idx in clusters.indices {
                let cluster = clusters[idx]
                guard let base = cluster.primaryArabicLetter, Self.qalqalahLetters.contains(base) else { continue }
                // If the qalqalah letter itself carries maddah, treat it as madd-driven instead of qalqalah.
                guard !hasMaddah(cluster) else { continue }
                let uthmaniHere = hasUthmaniSukoon(cluster)
                let splitUthmani = !uthmaniHere && idx + 1 < clusters.count
                    && clusterIsOnlyUthmaniSukoonMark(clusters[idx + 1])
                if uthmaniHere || splitUthmani || hasStandardSukoon(cluster) {
                    let r = expandedQalqalahNSRange(clusters: clusters, index: idx)
                    ops.append(PaintOp(range: r, priority: PaintPriority.qalqalah, category: .qalqalah))
                    continue
                }
                guard verseFinalQalqalahIndex == idx else { continue }
                let r = qalqalahLetterNSRange(clusters: clusters, index: idx)
                ops.append(PaintOp(range: r, priority: PaintPriority.qalqalah, category: .qalqalah))
            }
        }

        let _ = wordClusterRanges(clusters: clusters)

        appendTreeDrivenPaintOps(surah: surah, ayah: ayah, text: text, utf16Count: utf16Count, into: &ops)
        appendNuunMeemGhunnahHeuristicPaintOps(text: text, into: &ops)

        collectMaddAndWaslPaintOps(surah: surah, ayah: ayah, text: text, clusters: clusters, into: &ops)

        let waqfUTF16Skip = Self.utf16IndicesOfWaqfOrnaments(in: text)
        for op in ops.sorted(by: { $0.priority < $1.priority }) {
            let lo = op.range.location
            let hi = lo + op.range.length
            guard lo >= 0, hi <= utf16Count, hi >= lo else { continue }
            for i in lo..<hi {
                if waqfUTF16Skip.contains(i) { continue }
                guard op.priority >= priorityPerUTF16[i] else { continue }
                priorityPerUTF16[i] = op.priority
                attributed.addAttribute(
                    .foregroundColor,
                    value: platformTajweedColor(op.color ?? op.category.color),
                    range: NSRange(location: i, length: 1)
                )
            }
        }

        let anyPainted = priorityPerUTF16.contains { $0 > 0 }
        guard anyPainted else { return nil }

        let result = AttributedString(attributed)
        attributedCache[cacheKey] = result
        return result
    }

    private func platformLabelColor() -> AnyObject {
        #if canImport(UIKit)
        #if os(watchOS)
        return UIColor(Color.primary)
        #else
        return UIColor.label
        #endif
        #elseif canImport(AppKit)
        return NSColor.labelColor
        #else
        return Color.primary as AnyObject
        #endif
    }

    private func platformTajweedColor(_ color: Color) -> AnyObject {
        #if canImport(UIKit)
        return UIColor(color)
        #elseif canImport(AppKit)
        return NSColor(color)
        #else
        return color as AnyObject
        #endif
    }

    private static func utf16IndicesOfWaqfOrnaments(in text: String) -> Set<Int> {
        var out = Set<Int>()
        var offset = 0
        for ch in text {
            let s = String(ch)
            var scalarOffset = offset
            for sc in s.unicodeScalars {
                let hit = {
                let v = sc.value
                guard v >= waqfScalarSkipColorLower, v <= waqfScalarSkipColorUpper else { return false }
                return !waqfScalarExceptions.contains(v)
                }()
                if hit {
                    let len = sc.utf16.count
                    for j in 0..<len { out.insert(scalarOffset + j) }
                }
                scalarOffset += sc.utf16.count
            }
            offset += s.utf16.count
        }
        return out
    }

    private func collectMaddAndWaslPaintOps(surah: Int, ayah: Int, text: String, clusters: [CharacterClusterInfo], into ops: inout [PaintOp]) {
        let words = wordClusterRanges(clusters: clusters)

        if settings.isTajweedCategoryVisible(.maddNatural2) {
            appendScalarPaintOps(
                text: text,
                scalars: [Self.smallWaw.value, Self.smallYeh.value, Self.daggerAlif.value],
                priority: PaintPriority.maddNatural2MiniatureScalars,
                category: .maddNatural2,
                into: &ops
            )
        }

        if settings.isTajweedCategoryVisible(.maddNecessary6) {
            for cluster in clusters where isLazimCombinedAlifCluster(cluster) {
                ops.append(PaintOp(range: nsRange(for: cluster), priority: PaintPriority.maddNecessary6, category: .maddNecessary6))
            }
            // Alif + maddah (ٓ) after an istila letter, without ٓاْ on one cluster - e.g. ٱلضَّآلِّينَ (lazim-style coloring).
            for i in clusters.indices where i > 0 {
                let cur = clusters[i]
                guard isBareAlifForMadd(cur), hasMaddah(cur) else { continue }
                if isLazimCombinedAlifCluster(cur) { continue }
                let prev = clusters[i - 1]
                guard let pl = prev.primaryArabicLetter, Self.heavyBaseLetters.contains(pl) else { continue }
                ops.append(PaintOp(range: nsRange(for: cur), priority: PaintPriority.maddNecessary6, category: .maddNecessary6))
            }
            for i in clusters.indices where isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) {
                ops.append(PaintOp(range: nsRange(for: clusters[i]), priority: PaintPriority.maddNecessary6, category: .maddNecessary6))
                ops.append(PaintOp(range: nsRange(for: clusters[i + 1]), priority: PaintPriority.maddNecessary6, category: .maddNecessary6))
            }
            if ayah == 1, Self.surahsOpeningMuqattaat.contains(surah) {
                for i in clusters.indices {
                    guard hasMaddah(clusters[i]) else { continue }
                    if isLazimCombinedAlifCluster(clusters[i]) { continue }
                    if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) { continue }
                    ops.append(PaintOp(range: nsRange(for: clusters[i]), priority: PaintPriority.maddNecessary6, category: .maddNecessary6))
                }
            }
        }

        if settings.isTajweedCategoryVisible(.maddConnected) {
            for w in words {
                let lo = w.lowerBound, hi = w.upperBound
                guard hi - lo >= 3 else { continue }
                for i in lo..<(hi - 1) {
                    if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) { continue }
                    if isLazimCombinedAlifCluster(clusters[i]) { continue }
                    guard isNaturalMaddCarrier(clusters: clusters, index: i, wordStart: lo) else { continue }
                    guard i + 1 < hi, hasStandardSukoon(clusters[i + 1]) else { continue }
                    var foundHamza = false
                    var k = i + 2
                    while k < hi {
                        if isHamzaCarrier(clusters[k]) { foundHamza = true; break }
                        k += 1
                    }
                    if foundHamza {
                        appendNaturalMaddPaintOps(
                            clusters: clusters,
                            index: i,
                            priority: PaintPriority.maddConnected,
                            category: .maddConnected,
                            into: &ops
                        )
                    }
                }
            }
        }

        if settings.isTajweedCategoryVisible(.maddSeparated) {
            for wi in words.indices.dropLast() {
                let w1 = words[wi], w2 = words[wi + 1]
                guard w1.upperBound - w1.lowerBound >= 2 else { continue }
                let pen = w1.upperBound - 2
                let last = w1.upperBound - 1
                if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: pen) { continue }
                if isLazimCombinedAlifCluster(clusters[last]) { continue }
                guard isNaturalMaddCarrier(clusters: clusters, index: pen, wordStart: w1.lowerBound) else { continue }
                guard hasStandardSukoon(clusters[last]) else { continue }
                let firstNext = w2.lowerBound
                guard firstNext < clusters.count, isHamzaCarrier(clusters[firstNext]) else { continue }
                appendNaturalMaddPaintOps(
                    clusters: clusters,
                    index: pen,
                    priority: PaintPriority.maddSeparated,
                    category: .maddSeparated,
                    into: &ops
                )
            }
        }

        // Fallback: explicit maddah (ٓ) is not madd tabi'i.
        // If not already covered by connected/separated/necessary logic, color as necessary.
        if settings.isTajweedCategoryVisible(.maddNecessary6) {
            for i in clusters.indices where hasMaddah(clusters[i]) {
                if strongerMaddRuleCoversCluster(index: i, ops: ops, clusters: clusters) { continue }
                appendSpecialMaddPaintOps(
                    text: text,
                    range: nsRange(for: clusters[i]),
                    priority: PaintPriority.maddNecessary6,
                    category: .maddNecessary6,
                    into: &ops
                )
            }
        }

        if settings.isTajweedCategoryVisible(.maddNatural2) {
            for w in words {
                let lo = w.lowerBound, hi = w.upperBound
                for i in lo..<hi {
                    guard shouldOfferNaturalMadd2(clusters: clusters, index: i, wordStart: lo) else { continue }
                    if strongerMaddRuleCoversCluster(index: i, ops: ops, clusters: clusters) { continue }
                    appendNaturalMaddPaintOps(
                        clusters: clusters,
                        index: i,
                        priority: PaintPriority.maddNatural2,
                        category: .maddNatural2,
                        into: &ops
                    )
                }
            }
        }

        if settings.isTajweedCategoryVisible(.hamzatWaslSilent),
           let firstContentUTF16 = utf16StartOfFirstNonWhitespace(clusters: clusters) {
            for cl in clusters where cl.contains(Self.hamzatWasl) {
                if cl.utf16Range.lowerBound > firstContentUTF16 {
                    ops.append(PaintOp(range: nsRange(for: cl), priority: PaintPriority.hamzatWaslSilent, category: .hamzatWaslSilent))
                }
            }
            // Standard sukun (ْ) on و / ي / ا: silent (not read); Uthmani ۡ (U+06E1) is excluded so وۡ can still be a madd carrier.
            for cl in clusters {
                guard hasStandardSukoon(cl), !hasUthmaniSukoon(cl) else { continue }
                if cl.contains(Self.hamzatWasl) { continue }
                guard let base = cl.primaryArabicLetter else { continue }
                let silentCarrier = base == "و" || isYaBase(cl) || (base == "ا" && isBareAlifForMadd(cl))
                guard silentCarrier else { continue }
                ops.append(PaintOp(range: nsRange(for: cl), priority: PaintPriority.hamzatWaslSilent, category: .hamzatWaslSilent))
            }
        }
    }

    /// Necessary / separated / connected madd already paint this cluster; skip natural madd.
    private func strongerMaddRuleCoversCluster(index: Int, ops: [PaintOp], clusters: [CharacterClusterInfo]) -> Bool {
        let r = nsRange(for: clusters[index])
        let blocking: Set<TajweedLegendCategory> = [.maddNecessary6, .maddSeparated, .maddConnected]
        for op in ops where blocking.contains(op.category) {
            let olo = op.range.location, ohi = olo + op.range.length
            if r.location < ohi && r.location + r.length > olo { return true }
        }
        return false
    }

    private func appendNaturalMaddPaintOps(
        clusters: [CharacterClusterInfo],
        index: Int,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let cluster = clusters[index]
        let skipScalars: Set<UInt32> = [Self.daggerAlif.value, Self.smallWaw.value, Self.smallYeh.value]
        var u = cluster.utf16Range.lowerBound
        for s in cluster.text.unicodeScalars {
            if !skipScalars.contains(s.value) {
                let len = utf16Length(of: s)
                ops.append(PaintOp(range: NSRange(location: u, length: len), priority: priority, category: category))
            }
            u += utf16Length(of: s)
        }
    }

    private func utf16Length(of scalar: UnicodeScalar) -> Int {
        scalar.value > 0xFFFF ? 2 : 1
    }

    private func appendScalarPaintOps(
        text: String,
        scalars: [UInt32],
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let want = Set(scalars)
        var u16 = 0
        for s in text.unicodeScalars {
            let w = utf16Length(of: s)
            if want.contains(s.value) {
                ops.append(PaintOp(range: NSRange(location: u16, length: w), priority: priority, category: category))
            }
            u16 += w
        }
    }

    private func isWhitespaceOnly(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.text.allSatisfy { $0.isWhitespace }
    }

    /// Uthmani end-of-ayah marker and similar ornaments (not a spoken letter).
    private func isAyahEndOrDecorativeCluster(_ cluster: CharacterClusterInfo) -> Bool {
        guard let v = cluster.base?.unicodeScalars.first?.value else { return false }
        switch v {
        case 0x06DD: return true // ۝
        case 0x061E: return true // ۞
        default: return false
        }
    }

    /// True when the cluster is only U+06E1 (Uthmani sukun mark), optional VS / whitespace.
    private func clusterIsOnlyUthmaniSukoonMark(_ cluster: CharacterClusterInfo) -> Bool {
        var found = false
        for s in cluster.text.unicodeScalars {
            if s.value == Self.sukoonUthmani.value {
                found = true
                continue
            }
            if s.value == 0xFE0E || s.value == 0xFE0F { continue }
            if CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(s.value)!) { continue }
            return false
        }
        return found
    }

    /// UTF-16 range for qalqalah coloring: letter cluster plus a following standalone U+06E1 grapheme when the font splits them.
    private func expandedQalqalahNSRange(clusters: [CharacterClusterInfo], index i: Int) -> NSRange {
        let cl = clusters[i]
        let lo = cl.utf16Range.lowerBound
        var hi = cl.utf16Range.upperBound
        if !hasUthmaniSukoon(cl), i + 1 < clusters.count, clusterIsOnlyUthmaniSukoonMark(clusters[i + 1]) {
            hi = clusters[i + 1].utf16Range.upperBound
        }
        return NSRange(location: lo, length: hi - lo)
    }

    /// Only the qalqalah letter itself, used for ayah-final letters so tashkeel does not change color.
    private func qalqalahLetterNSRange(clusters: [CharacterClusterInfo], index i: Int) -> NSRange {
        let cl = clusters[i]
        let lo = cl.utf16Range.lowerBound
        let len = String(cl.base ?? Character(" ")).utf16.count
        return NSRange(location: lo, length: max(1, len))
    }

    /// Last qalqalah letter of the ayah (waqf implies sukun), skipping trailing space and ۝.
    private func indexOfVerseFinalQalqalahCluster(clusters: [CharacterClusterInfo]) -> Int? {
        var i = clusters.count - 1
        while i >= 0 {
            let cl = clusters[i]
            if isWhitespaceOnly(cl) {
                i -= 1
                continue
            }
            if isAyahEndOrDecorativeCluster(cl) {
                i -= 1
                continue
            }
            guard let p = cl.primaryArabicLetter else {
                i -= 1
                continue
            }
            if Self.qalqalahLetters.contains(p) {
                return i
            }
            if isArabicLetterBase(p) {
                return nil
            }
            i -= 1
        }
        return nil
    }

    private func wordClusterRanges(clusters: [CharacterClusterInfo]) -> [Range<Int>] {
        var out: [Range<Int>] = []
        var start = 0
        for idx in clusters.indices {
            if isWhitespaceOnly(clusters[idx]) {
                if start < idx { out.append(start..<idx) }
                start = idx + 1
            }
        }
        if start < clusters.count { out.append(start..<clusters.count) }
        return out
    }

    private func utf16StartOfFirstNonWhitespace(clusters: [CharacterClusterInfo]) -> Int? {
        clusters.first(where: { !isWhitespaceOnly($0) })?.utf16Range.lowerBound
    }

    private func hasMaddah(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.maddah)
    }

    private func isBareAlifForMadd(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.primaryArabicLetter == "ا" && !cluster.contains(Self.hamzatWasl)
    }

    private func isLazimCombinedAlifCluster(_ cluster: CharacterClusterInfo) -> Bool {
        hasMaddah(cluster) && isBareAlifForMadd(cluster) && hasStandardSukoon(cluster)
    }

    private func isLazimWawThenAlifSukoon(clusters: [CharacterClusterInfo], wawIndex: Int) -> Bool {
        guard wawIndex + 1 < clusters.count else { return false }
        let w = clusters[wawIndex], a = clusters[wawIndex + 1]
        guard w.primaryArabicLetter == "و", hasMaddah(w) else { return false }
        return isBareAlifForMadd(a) && hasStandardSukoon(a)
    }

    private func hasArabicVowelOnCluster(_ cluster: CharacterClusterInfo) -> Bool {
        hasHeavyOpenVowel(cluster) || hasKasraFamily(cluster)
    }

    private func hasFathaFamily(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.fatha) || cluster.contains(Self.fathatayn)
    }

    private func hasDammaFamily(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.damma) || cluster.contains(Self.dammatayn)
    }

    private func isYaBase(_ cluster: CharacterClusterInfo) -> Bool {
        guard let p = cluster.primaryArabicLetter else { return false }
        return p == "ي" || p == "ى"
    }

    private func isHamzaCarrier(_ cluster: CharacterClusterInfo) -> Bool {
        if cluster.contains(Self.hamzatWasl) { return false }
        guard let b = cluster.primaryArabicLetter else { return false }
        switch b {
        case "ء", "أ", "إ", "ئ", "ؤ", "آ": return true
        default: return false
        }
    }

    private func nextMeaningfulClusterIndex(clusters: [CharacterClusterInfo], after index: Int) -> Int? {
        var nextIndex = index + 1
        while nextIndex < clusters.count {
            if !isWhitespaceOnly(clusters[nextIndex]) {
                return nextIndex
            }
            nextIndex += 1
        }
        return nil
    }

    /// Madd before ٱ merges (e.g. بِٱلله); not a stand-alone two-count madd.
    private func nextClusterIsHamzatWasl(clusters: [CharacterClusterInfo], after i: Int) -> Bool {
        guard let nextIndex = nextMeaningfulClusterIndex(clusters: clusters, after: i) else { return false }
        return clusters[nextIndex].contains(Self.hamzatWasl)
    }

    /// ي / ى carrying natural madd: kasrah on the letter before the ya.
    private func isYaaMaddLetterCluster(clusters: [CharacterClusterInfo], yaIndex: Int) -> Bool {
        guard yaIndex > 0, yaIndex < clusters.count else { return false }
        guard isYaBase(clusters[yaIndex]) else { return false }
        return hasKasraFamily(clusters[yaIndex - 1])
    }

    private func isNaturalMaddCarrier(clusters: [CharacterClusterInfo], index i: Int, wordStart: Int) -> Bool {
        guard i >= wordStart, i > 0 else { return false }
        let cur = clusters[i], prev = clusters[i - 1]
        if isWhitespaceOnly(cur) || isWhitespaceOnly(prev) { return false }
        // Explicit maddah (ٓ) must never be classified as madd tabi'i.
        if hasMaddah(cur) { return false }
        guard !hasArabicVowelOnCluster(cur) else { return false }
        if isLazimCombinedAlifCluster(cur) { return false }
        if isBareAlifForMadd(cur) {
            if hasStandardSukoon(cur) { return false }
            if cur.contains(Self.hamzatWasl) { return false }
            guard hasFathaFamily(prev) else { return false }
            // Tanwin fath (ً U+064B on previous letter) + following alif: not colored as natural madd.
            if prev.contains(Self.fathatayn) { return false }
            return !nextClusterIsHamzatWasl(clusters: clusters, after: i)
        }
        if cur.primaryArabicLetter == "و" {
            if hasStandardSukoon(cur) { return false }
            if hasMaddah(cur), i + 1 < clusters.count,
               isBareAlifForMadd(clusters[i + 1]), hasStandardSukoon(clusters[i + 1]) {
                return false
            }
            let ok = hasDammaFamily(prev)
            return ok && !nextClusterIsHamzatWasl(clusters: clusters, after: i)
        }
        if isYaBase(cur) {
            if hasStandardSukoon(cur) { return false }
            let ok = hasKasraFamily(prev)
            return ok && !nextClusterIsHamzatWasl(clusters: clusters, after: i)
        }
        return false
    }

    private func shouldOfferNaturalMadd2(clusters: [CharacterClusterInfo], index i: Int, wordStart: Int) -> Bool {
        guard isNaturalMaddCarrier(clusters: clusters, index: i, wordStart: wordStart) else { return false }
        if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) { return false }
        if isLazimCombinedAlifCluster(clusters[i]) { return false }
        return true
    }

    private func nsRange(for info: CharacterClusterInfo) -> NSRange {
        NSRange(location: info.utf16Range.lowerBound, length: info.utf16Range.upperBound - info.utf16Range.lowerBound)
    }

    private func tajweedVisibilitySignature() -> String {
        TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined(separator: "")
    }

    private struct CharacterClusterInfo {
        let text: String
        let utf16Range: Range<Int>

        /// The full Swift grapheme (may bundle letter + diacritics).
        var base: Character? { text.first }

        /// First main Arabic letter in this cluster. `base` alone is wrong for sets like `heavyBaseLetters`
        /// because `Character("ضَّ")` ≠ `Character("ض")`.
        var primaryArabicLetter: Character? {
            for s in text.unicodeScalars {
                let v = s.value
                if (0x0621...0x063A).contains(v) || (0x0641...0x064A).contains(v) || v == 0x0671 {
                    return Character(s)
                }
            }
            return nil
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

    private func isArabicLetterBase(_ c: Character) -> Bool {
        guard let v = c.unicodeScalars.first?.value else { return false }
        return (0x0600...0x06FF).contains(v)
            || (0x0750...0x077F).contains(v)
            || (0x08A0...0x08FF).contains(v)
    }

    private func hasStandardSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoon)
    }

    private func hasUthmaniSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoonUthmani)
    }

    private func hasShadda(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.shadda)
    }

    private func appendTreeDrivenPaintOps(surah: Int, ayah: Int, text: String, utf16Count: Int, into ops: inout [PaintOp]) {
        let key = TajweedAyahKey(surah: surah, ayah: ayah)
        guard let annotations = Self.tajweedRuleTreesByAyah[key], !annotations.isEmpty else { return }

        for annotation in annotations {
            guard let category = Self.treeDrivenRuleMap[annotation.rule] else { continue }
            guard settings.isTajweedCategoryVisible(category) else { continue }
            let start = max(0, min(annotation.start, utf16Count))
            let end = max(start, min(annotation.end, utf16Count))
            guard end > start else { continue }
            let priority: Int
            switch category {
            case .maddNatural2:
                priority = PaintPriority.maddNatural2
            case .maddSeparated:
                priority = PaintPriority.maddSeparated
            case .maddConnected:
                priority = PaintPriority.maddConnected
            case .maddNecessary6:
                priority = PaintPriority.maddNecessary6
            case .qalqalah:
                priority = PaintPriority.qalqalah
            case .hamzatWaslSilent:
                priority = PaintPriority.hamzatWaslSilent
            case .idghamBiGhunnah:
                priority = PaintPriority.idghamBiGhunnah
            case .ikhfaa:
                priority = PaintPriority.ikhfaa
            case .iqlab:
                priority = PaintPriority.iqlab
            case .idghamBilaGhunnah:
                priority = PaintPriority.idghamBilaGhunnah
            default:
                continue
            }

            if Self.specialTanweenCategories.contains(category) {
                appendSpecialTanweenPaintOps(
                    text: text,
                    range: NSRange(location: start, length: end - start),
                    priority: priority,
                    category: category,
                    into: &ops
                )
                continue
            }

            if category == .maddNatural2 || category == .maddSeparated || category == .maddConnected || category == .maddNecessary6 {
                appendSpecialMaddPaintOps(
                    text: text,
                    range: NSRange(location: start, length: end - start),
                    priority: priority,
                    category: category,
                    into: &ops
                )
                continue
            }

            ops.append(
                PaintOp(
                    range: NSRange(location: start, length: end - start),
                    priority: priority,
                    category: category,
                    color: category.color
                )
            )
        }
    }

    private func appendSpecialTanweenPaintOps(
        text: String,
        range: NSRange,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let clusters = characterClusters(in: text)
        var paintedTanween = false
        for cluster in clusters {
            guard utf16RangesOverlap(cluster.utf16Range, range) else { continue }
            guard let tanweenRange = tanweenScalarRange(in: cluster) else { continue }
            ops.append(PaintOp(range: tanweenRange, priority: priority, category: category, color: category.color))
            paintedTanween = true
        }

        if !paintedTanween {
            ops.append(PaintOp(range: range, priority: priority, category: category, color: category.color))
        }
    }

    private func tanweenScalarRange(in cluster: CharacterClusterInfo) -> NSRange? {
        var offset = cluster.utf16Range.lowerBound
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if scalar == Self.fathatayn || scalar == Self.dammatayn || scalar == Self.kasratayn {
                return NSRange(location: offset, length: length)
            }
            offset += length
        }
        return nil
    }

    private func appendSpecialMaddPaintOps(
        text: String,
        range: NSRange,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let clusters = characterClusters(in: text)
        var paintedSpecialMark = false

        for cluster in clusters {
            guard utf16RangesOverlap(cluster.utf16Range, range) else { continue }
            let specialRanges = specialMaddScalarRanges(in: cluster)
            if specialRanges.isEmpty { continue }
            paintedSpecialMark = true
            for specialRange in specialRanges {
                ops.append(PaintOp(range: specialRange, priority: priority, category: category, color: category.color))
            }
        }

        if !paintedSpecialMark {
            ops.append(PaintOp(range: range, priority: priority, category: category, color: category.color))
        }
    }

    private func utf16RangesOverlap(_ lhs: Range<Int>, _ rhs: NSRange) -> Bool {
        let rhsLower = rhs.location
        let rhsUpper = rhs.location + rhs.length
        return lhs.lowerBound < rhsUpper && lhs.upperBound > rhsLower
    }

    private func specialMaddScalarRanges(in cluster: CharacterClusterInfo) -> [NSRange] {
        var offset = cluster.utf16Range.lowerBound
        var ranges: [NSRange] = []
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if scalar == Self.daggerAlif || scalar == Self.maddah || scalar == Self.smallWaw || scalar == Self.smallYeh {
                ranges.append(NSRange(location: offset, length: length))
            }
            offset += length
        }
        return ranges
    }

    private func appendNuunMeemGhunnahHeuristicPaintOps(text: String, into ops: inout [PaintOp]) {
        let clusters = characterClusters(in: text)
        for cluster in clusters {
            guard let base = cluster.primaryArabicLetter else { continue }
            guard base == "ن" || base == "م" else { continue }
            guard hasShadda(cluster) else { continue }
            let category: TajweedLegendCategory = .idghamBiGhunnah
            guard settings.isTajweedCategoryVisible(category) else { continue }
            ops.append(PaintOp(range: nsRange(for: cluster), priority: PaintPriority.idghamBiGhunnah, category: category, color: category.color))
        }
    }

    private func isAlifLike(_ c: Character?) -> Bool {
        guard let c else { return false }
        return c == "ا" || c == "أ" || c == "إ" || c == "ئ" || c == "ؤ" || c == "آ" || c == "\u{671}"
    }

    private func isLamInAllahWord(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        let isFirstLam =
            index >= 1 &&
            isAlifLike(clusters[index - 1].primaryArabicLetter) &&
            index + 2 < clusters.count &&
            clusters[index + 1].primaryArabicLetter == "ل" &&
            clusters[index + 2].primaryArabicLetter == "ه"
        let isSecondLam =
            index >= 2 &&
            isAlifLike(clusters[index - 2].primaryArabicLetter) &&
            clusters[index - 1].primaryArabicLetter == "ل" &&
            index + 1 < clusters.count &&
            clusters[index + 1].primaryArabicLetter == "ه"
        return isFirstLam || isSecondLam
    }

    private func isLamShamsiyah(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].primaryArabicLetter == "ل" else { return false }
        // Uthmani typesetting often leaves this lam bare (no vowel/sukun on the ل itself); ٱ + ل + sun letter is still lam shamsiyyah.
        if hasShadda(clusters[index]) { return false }
        if isLamInAllahWord(clusters: clusters, index: index) { return false }
        guard index >= 1, isAlifLike(clusters[index - 1].primaryArabicLetter) else { return false }
        guard index + 1 < clusters.count, let next = clusters[index + 1].primaryArabicLetter, Self.sunLetters.contains(next) else {
            return false
        }
        return true
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
        cluster.contains(Self.kasra) || cluster.contains(Self.kasratayn)
    }

    private func hasSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoon) || cluster.contains(Self.sukoonUthmani)
    }

    private func hasDaggerAlif(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.daggerAlif)
    }

    private func shouldUseHeavyColor(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let base = clusters[index].primaryArabicLetter else { return false }

        // Seven istila letters: always tafkhim in coloring; vowels on the letter are ignored (sukun still gets its own higher-priority color).
        if Self.heavyBaseLetters.contains(base) {
            return true
        }

        if base == "ر" {
            return isHeavyRaa(clusters: clusters, index: index)
        }

        if Self.alifFollowerLetters.contains(base), index > 0 {
            return isHeavyCarrier(clusters: clusters, index: index - 1)
        }

        return false
    }

    private func isHeavyCarrier(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let base = clusters[index].primaryArabicLetter else { return false }
        if Self.heavyBaseLetters.contains(base) {
            return true
        }
        if base == "ر" {
            return isHeavyRaa(clusters: clusters, index: index)
        }
        return false
    }

    /// Heavy ra: kasrah/kasratayn -> light; fathah/dammah/tanwin open vowel on the ra -> heavy; Uthmani sukun -> light here; shaddah -> heavy; else heavy if preceding cluster has kasrah or madd ya.
    private func isHeavyRaa(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].primaryArabicLetter == "ر" else { return false }
        let current = clusters[index]
        if hasKasraFamily(current) { return false }
        if hasHeavyOpenVowel(current) { return true }
        if hasUthmaniSukoon(current) { return false }
        if hasShadda(current) { return true }
        guard let prev = previousCluster(in: clusters, before: index) else { return false }
        if hasKasraFamily(prev) { return true }
        if isYaaMaddLetterCluster(clusters: clusters, yaIndex: index - 1) { return true }
        return false
    }

}
final class QuranData: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loadingCore
        case buildingIndexes
        case ready
        case failed
    }

    private enum RevelationSearchMode {
        case makkan
        case madinan
    }

    private static let makkanAliases: Set<String> = [
        "makkah", "makkan", "makki"
    ]

    private static let madinanAliases: Set<String> = [
        "madinah", "madinan", "madina", "madani"
    ]

    /// Surahs that should always display as less than one page in UI metadata.
    private static let forcedLessThanOnePageSurahIDs: Set<Int> = Set([82, 86, 87]).union(Set(90...114))

    struct SurahSearchIndexEntry: Identifiable {
        let surahID: Int
        let nameEnglishUpper: String
        let nameTransliterationUpper: String
        let searchableBlob: String
        let compactSearchableBlob: String

        var id: Int { surahID }
    }

    struct JuzSearchIndexEntry: Identifiable {
        let juzID: Int
        let searchableBlob: String
        let compactSearchableBlob: String

        var id: Int { juzID }
    }

    enum CountOperator {
        case equal
        case lessThan
        case lessThanOrEqual
        case greaterThan
        case greaterThanOrEqual
    }

    struct CountFilter {
        let op: CountOperator
        let value: Int
    }

    struct PageSectionData: Identifiable {
        let page: Int
        let surahIDs: [Int]

        var id: Int { page }
    }

    struct JuzSectionData: Identifiable {
        struct Row: Identifiable {
            enum Kind {
                case plain
                case start(ayah: Int)
                case end(ayah: Int)
            }

            let surahID: Int
            let kind: Kind

            var id: String {
                switch kind {
                case .plain:
                    return "\(surahID)-plain"
                case .start(let ayah):
                    return "\(surahID)-start-\(ayah)"
                case .end(let ayah):
                    return "\(surahID)-end-\(ayah)"
                }
            }
        }

        let juz: Juz
        let surahIDs: [Int]
        let rows: [Row]

        var id: Int { juz.id }
    }

    static let shared: QuranData = {
        let q = QuranData()
        q.startLoading()
        return q
    }()

    private let settings = Settings.shared

    @Published private(set) var quran: [Surah] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var pageSections: [PageSectionData] = []
    @Published private(set) var juzSections: [JuzSectionData] = []
    @Published private(set) var revelationOrderSurahIDs: [Int] = []
    @Published private(set) var surahSearchIndex: [SurahSearchIndexEntry] = []
    private(set) var verseIndex: [VerseIndexEntry] = []

    private var surahIndex = [Int:Int]()
    private var ayahIndex = [[Int:Int]]()
    /// Qiraah key the verse index was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedVerseIndexQiraah: String? = nil
    /// Qiraah key the boundary model was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedBoundaryQiraah: String? = nil
    /// Qiraah key for first page/juz ayah lookup tables ("" = Hafs).
    private var cachedFirstAyahLookupQiraah: String? = nil
    private var surahBoundaryModels = [Int: SurahBoundaryModel]()
    private var firstAyahByPage = [Int: (surah: Int, ayah: Int)]()
    private var firstAyahByJuz = [Int: (surah: Int, ayah: Int)]()
    /// Preprocessed Arabic indexes to reduce scoring to a small candidate set.
    private var arabicTokenIndex = [String: [Int]]()
    private var arabicPrefix2Index = [String: [Int]]()
    /// Preprocessed English indexes to reduce scoring to a small candidate set.
    private var englishTokenIndex = [String: [Int]]()
    private var englishPrefix3Index = [String: [Int]]()
    /// Cached contiguous index list to avoid reallocating Array(verseIndex.indices) on every query.
    private var allVerseIndices: [Int] = []
    private var surahIDsByAyahCount = [Int: [Int]]()
    private var surahIDsByPageCount = [Int: [Int]]()
    private var surahIDsByJuz = [Int: [Int]]()
    private var juzSearchIndex: [JuzSearchIndexEntry] = []

    private var loadTask: Task<Void, Never>?
    private var loadErrorDescription: String? = nil

    private init() {}

    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()

    private func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        Self.arFormatter.number(from: arabicNumber)?.intValue
    }

    private func startLoading() {
        guard loadTask == nil else { return }
        loadTask = Task(priority: .userInitiated) { [weak self] in
            await self?.load()
        }
    }

    private func searchTokens(from cleanedText: String) -> [String] {
        cleanedText
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static let arabicTashkeelCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{0610}"..."\u{061A}")
        set.insert(charactersIn: "\u{064B}"..."\u{065F}")
        set.insert(charactersIn: "\u{0670}"..."\u{0670}")
        set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
        return set
    }()

    private func arabicTashkeelBlob(_ text: String) -> String {
        String(text.unicodeScalars.filter { Self.arabicTashkeelCharacterSet.contains($0) })
    }

    private func exactPhraseBlob(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func makeVerseIndexEntry(
        surahID: Int,
        ayahID: Int,
        rawArabic: String,
        cleanArabic: String,
        englishSaheeh: String,
        englishMustafa: String,
        transliteration: String
    ) -> VerseIndexEntry {
        let arabicBlob = [rawArabic, cleanArabic]
            .map { settings.cleanSearch($0) }
            .joined(separator: " ")
        let englishBlob = [englishSaheeh, englishMustafa, transliteration]
            .map { settings.cleanSearch($0) }
            .joined(separator: " ")
        let arabicTokens = searchTokens(from: arabicBlob)
        let englishTokens = searchTokens(from: englishBlob)

        return VerseIndexEntry(
            id: "\(surahID):\(ayahID)",
            surah: surahID,
            ayah: ayahID,
            arabicTashkeelBlob: arabicTashkeelBlob(rawArabic),
            englishExactBlob: exactPhraseBlob([englishSaheeh, englishMustafa, transliteration].joined(separator: " ")),
            arabicBlob: arabicBlob,
            englishBlob: englishBlob,
            arabicTokens: arabicTokens,
            englishTokens: englishTokens
        )
    }

    private func buildEnglishSearchIndexes(for entries: [VerseIndexEntry]) -> (
        token: [String: [Int]],
        prefix3: [String: [Int]]
    ) {
        var tokenIndex = [String: [Int]]()
        var prefix3Index = [String: [Int]]()
        tokenIndex.reserveCapacity(12000)
        prefix3Index.reserveCapacity(4000)

        for (idx, entry) in entries.enumerated() {
            let uniqueTokens = Set(entry.englishTokens)
            for token in uniqueTokens {
                guard !token.isEmpty else { continue }
                tokenIndex[token, default: []].append(idx)
            }

            var uniquePrefixes = Set<String>()
            uniquePrefixes.reserveCapacity(uniqueTokens.count)
            for token in uniqueTokens where token.count >= 3 {
                uniquePrefixes.insert(String(token.prefix(3)))
            }
            for prefix in uniquePrefixes {
                prefix3Index[prefix, default: []].append(idx)
            }
        }

        return (token: tokenIndex, prefix3: prefix3Index)
    }

    private func buildArabicSearchIndexes(for entries: [VerseIndexEntry]) -> (
        token: [String: [Int]],
        prefix2: [String: [Int]]
    ) {
        var tokenIndex = [String: [Int]]()
        var prefix2Index = [String: [Int]]()
        tokenIndex.reserveCapacity(9000)
        prefix2Index.reserveCapacity(3000)

        for (idx, entry) in entries.enumerated() {
            let uniqueTokens = Set(entry.arabicTokens)
            for token in uniqueTokens {
                guard !token.isEmpty else { continue }
                tokenIndex[token, default: []].append(idx)
            }

            var uniquePrefixes = Set<String>()
            uniquePrefixes.reserveCapacity(uniqueTokens.count)
            for token in uniqueTokens where token.count >= 2 {
                uniquePrefixes.insert(String(token.prefix(2)))
            }
            for prefix in uniquePrefixes {
                prefix2Index[prefix, default: []].append(idx)
            }
        }

        return (token: tokenIndex, prefix2: prefix2Index)
    }

    func waitUntilLoaded() async {
        while true {
            let state = await MainActor.run { self.loadState }
            if state == .ready || state == .failed {
                return
            }
            if loadTask == nil {
                return
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    var isReadyForUI: Bool {
        loadState == .ready
    }

    var hasLoadFailed: Bool {
        loadState == .failed
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
        await MainActor.run {
            self.loadState = .loadingCore
            self.loadErrorDescription = nil
        }

        defer {
            Task { @MainActor in
                self.loadTask = nil
            }
        }

        let maxAttempts = 2
        for attempt in 1...maxAttempts {
            do {
                try await loadAttempt()
                await MainActor.run {
                    self.loadState = .ready
                }
                return
            } catch {
                let message = "Failed to load Quran attempt \(attempt)/\(maxAttempts): \(error.localizedDescription)"
                logger.error("\(message)")
                await MainActor.run {
                    self.loadErrorDescription = message
                }

                if attempt < maxAttempts {
                    // Small backoff avoids repeated pressure spikes on slower devices.
                    try? await Task.sleep(nanoseconds: 180_000_000)
                    continue
                }
            }
        }

        await MainActor.run {
            self.loadState = .failed
        }
    }

    private func loadAttempt() async throws {
        guard let url = Bundle.main.url(forResource: "Quran", withExtension: "json") else {
            throw NSError(domain: "QuranData", code: 1, userInfo: [NSLocalizedDescriptionKey: "Quran.json missing"])
        }

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

                return Surah(
                    id: surah.id,
                    idArabic: surah.idArabic,
                    nameArabic: surah.nameArabic,
                    nameTransliteration: surah.nameTransliteration,
                    nameEnglish: surah.nameEnglish,
                    similarNames: surah.similarNames,
                    type: surah.type,
                    numberOfAyahs: surah.numberOfAyahs,
                    revelationOrder: surah.revelationOrder,
                    revelationExceptions: surah.revelationExceptions,
                    pageStart: surah.pageStart,
                    pageEnd: surah.pageEnd,
                    numberOfPages: surah.numberOfPages,
                    isLessThanOnePage: surah.isLessThanOnePage,
                    firstJuz: surah.firstJuz,
                    lastJuz: surah.lastJuz,
                    juzs: surah.juzs,
                    ayahs: ayahs
                )
            }
        }

        surahs = applyDerivedSurahMetadata(to: surahs, displayQiraah: nil)

        let (sIndex, aIndex) = buildIndexes(for: surahs)
        let surahsToPublish = surahs
        let preprocessedSections = buildPreprocessedSections(for: surahsToPublish)
        let surahSearchIndex = buildSurahSearchIndex(for: surahsToPublish)
        let countIndexes = buildSurahCountIndexes(for: surahsToPublish)
        let surahIDsByJuz = Dictionary(uniqueKeysWithValues: preprocessedSections.juzSections.map { ($0.juz.id, $0.surahIDs) })
        let juzSearchIndex = buildJuzSearchIndex()

        await MainActor.run {
            self.surahIndex = sIndex
            self.ayahIndex = aIndex
            self.quran = surahsToPublish
            self.pageSections = preprocessedSections.pageSections
            self.juzSections = preprocessedSections.juzSections
            self.revelationOrderSurahIDs = preprocessedSections.revelationOrderSurahIDs
            self.surahSearchIndex = surahSearchIndex
            self.surahIDsByAyahCount = countIndexes.ayah
            self.surahIDsByPageCount = countIndexes.page
            self.surahIDsByJuz = surahIDsByJuz
            self.juzSearchIndex = juzSearchIndex
            self.loadState = .buildingIndexes

            // Expensive structures are built right after core publish.
            self.verseIndex = []
            self.arabicTokenIndex = [:]
            self.arabicPrefix2Index = [:]
            self.englishTokenIndex = [:]
            self.englishPrefix3Index = [:]
            self.allVerseIndices = []
            self.cachedVerseIndexQiraah = nil
            self.surahBoundaryModels = [:]
            self.cachedBoundaryQiraah = nil
            self.firstAyahByPage = [:]
            self.firstAyahByJuz = [:]
            self.cachedFirstAyahLookupQiraah = nil
        }

        let displayQiraah = await MainActor.run { settings.displayQiraahForArabic }

        var vIndex: [VerseIndexEntry] = []
        let estimatedVerseCount = surahsToPublish.reduce(0) { $0 + $1.ayahs.count }
        vIndex.reserveCapacity(estimatedVerseCount)
        for surah in surahsToPublish {
            for ayah in surah.ayahs {
                let raw = ayah.textArabic(for: displayQiraah)
                let clean = ayah.textCleanArabic(for: displayQiraah)
                vIndex.append(
                    makeVerseIndexEntry(
                        surahID: surah.id,
                        ayahID: ayah.id,
                        rawArabic: raw,
                        cleanArabic: clean,
                        englishSaheeh: ayah.textEnglishSaheeh,
                        englishMustafa: ayah.textEnglishMustafa,
                        transliteration: ayah.textTransliteration
                    )
                )
            }
        }

        let arabicIndexes = buildArabicSearchIndexes(for: vIndex)
        let englishIndexes = buildEnglishSearchIndexes(for: vIndex)
        let boundaryModels = buildBoundaryModels(for: surahsToPublish, displayQiraah: displayQiraah)
        let firstAyahLookups = buildFirstAyahLookups(for: surahsToPublish, displayQiraah: displayQiraah)
        let finalizedVerseIndex = vIndex
        let finalizedAllVerseIndices = Array(finalizedVerseIndex.indices)
        let finalizedQiraahKey = displayQiraah ?? ""

        await MainActor.run {
            self.verseIndex = finalizedVerseIndex
            self.arabicTokenIndex = arabicIndexes.token
            self.arabicPrefix2Index = arabicIndexes.prefix2
            self.englishTokenIndex = englishIndexes.token
            self.englishPrefix3Index = englishIndexes.prefix3
            self.allVerseIndices = finalizedAllVerseIndices
            self.cachedVerseIndexQiraah = finalizedQiraahKey
            self.surahBoundaryModels = boundaryModels
            self.cachedBoundaryQiraah = finalizedQiraahKey
            self.firstAyahByPage = firstAyahLookups.page
            self.firstAyahByJuz = firstAyahLookups.juz
            self.cachedFirstAyahLookupQiraah = finalizedQiraahKey
        }
    }

    private func applyDerivedSurahMetadata(to surahs: [Surah], displayQiraah: String?) -> [Surah] {
        guard !surahs.isEmpty else { return surahs }

        return surahs.enumerated().map { index, surah in
            let derivedLessThanOnePage: Bool = {
                if Self.forcedLessThanOnePageSurahIDs.contains(surah.id) { return true }
                if let explicit = surah.isLessThanOnePage { return explicit }
                guard surah.pageCount == 1 else { return false }
                guard index + 1 < surahs.count else { return false }

                let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(displayQiraah) }
                guard let currentLastAyah = ayahsForQiraah.last,
                      let currentLastPage = currentLastAyah.page else {
                    return false
                }

                let nextSurah = surahs[index + 1]
                guard let nextFirstAyah = nextSurah.ayahs.first(where: { $0.existsInQiraah(displayQiraah) }),
                      let nextFirstPage = nextFirstAyah.page else {
                    return false
                }

                return currentLastPage == nextFirstPage
            }()

            return Surah(
                id: surah.id,
                idArabic: surah.idArabic,
                nameArabic: surah.nameArabic,
                nameTransliteration: surah.nameTransliteration,
                nameEnglish: surah.nameEnglish,
                type: surah.type,
                numberOfAyahs: surah.numberOfAyahs,
                revelationOrder: surah.revelationOrder,
                revelationExceptions: surah.revelationExceptions,
                pageStart: surah.pageStart,
                pageEnd: surah.pageEnd,
                numberOfPages: surah.numberOfPages,
                isLessThanOnePage: derivedLessThanOnePage,
                firstJuz: surah.firstJuz,
                lastJuz: surah.lastJuz,
                juzs: surah.juzs,
                ayahs: surah.ayahs
            )
        }
    }

    private func rebuildVerseIndex() {
        let displayQiraah = settings.displayQiraahForArabic
        verseIndex = quran.flatMap { surah in
            surah.ayahs.map { ayah in
                let raw = ayah.textArabic(for: displayQiraah)
                let clean = ayah.textCleanArabic(for: displayQiraah)
                return makeVerseIndexEntry(
                    surahID: surah.id,
                    ayahID: ayah.id,
                    rawArabic: raw,
                    cleanArabic: clean,
                    englishSaheeh: ayah.textEnglishSaheeh,
                    englishMustafa: ayah.textEnglishMustafa,
                    transliteration: ayah.textTransliteration
                )
            }
        }
        let arabicIndexes = buildArabicSearchIndexes(for: verseIndex)
        let englishIndexes = buildEnglishSearchIndexes(for: verseIndex)
        arabicTokenIndex = arabicIndexes.token
        arabicPrefix2Index = arabicIndexes.prefix2
        englishTokenIndex = englishIndexes.token
        englishPrefix3Index = englishIndexes.prefix3
        allVerseIndices = Array(verseIndex.indices)
    }

    private func rebuildBoundaryModels() {
        let displayQiraah = settings.displayQiraahForArabic
        surahBoundaryModels = buildBoundaryModels(for: quran, displayQiraah: displayQiraah)
        cachedBoundaryQiraah = displayQiraah ?? ""
    }

    private func rebuildFirstAyahLookups() {
        let displayQiraah = settings.displayQiraahForArabic
        let lookups = buildFirstAyahLookups(for: quran, displayQiraah: displayQiraah)
        firstAyahByPage = lookups.page
        firstAyahByJuz = lookups.juz
        cachedFirstAyahLookupQiraah = displayQiraah ?? ""
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

    private func buildSurahSearchIndex(for surahs: [Surah]) -> [SurahSearchIndexEntry] {
        surahs.map { surah in
            let searchableBlob = [
                settings.cleanSearch(surah.nameArabic),
                settings.cleanSearch(surah.nameTransliteration),
                settings.cleanSearch(surah.nameEnglish),
                surah.similarNames.map { settings.cleanSearch($0) }.joined(separator: " "),
                settings.cleanSearch(String(surah.id)),
                settings.cleanSearch(surah.idArabic)
            ].joined(separator: " ")
            let compactSearchableBlob = searchableBlob.replacingOccurrences(of: " ", with: "")

            return SurahSearchIndexEntry(
                surahID: surah.id,
                nameEnglishUpper: surah.nameEnglish.uppercased(),
                nameTransliterationUpper: surah.nameTransliteration.uppercased(),
                searchableBlob: searchableBlob,
                compactSearchableBlob: compactSearchableBlob
            )
        }
    }

    private func buildSurahCountIndexes(for surahs: [Surah]) -> (ayah: [Int: [Int]], page: [Int: [Int]]) {
        var ayah = [Int: [Int]]()
        var page = [Int: [Int]]()

        for surah in surahs {
            ayah[surah.numberOfAyahs, default: []].append(surah.id)
            page[surah.pageCount, default: []].append(surah.id)
        }

        return (ayah: ayah, page: page)
    }

    private func buildJuzSearchIndex() -> [JuzSearchIndexEntry] {
        Self.juzList.map { juz in
            let searchableBlob = [
                settings.cleanSearch(juz.nameArabic),
                settings.cleanSearch(juz.nameTransliteration),
                settings.cleanSearch("juz \(juz.id)"),
                settings.cleanSearch("juz\(juz.id)"),
                settings.cleanSearch("para \(juz.id)")
            ].joined(separator: " ")

            return JuzSearchIndexEntry(
                juzID: juz.id,
                searchableBlob: searchableBlob,
                compactSearchableBlob: searchableBlob.replacingOccurrences(of: " ", with: "")
            )
        }
    }

    private func buildFirstAyahLookups(
        for surahs: [Surah],
        displayQiraah: String?
    ) -> (
        page: [Int: (surah: Int, ayah: Int)],
        juz: [Int: (surah: Int, ayah: Int)]
    ) {
        var pageLookup = [Int: (surah: Int, ayah: Int)]()
        var juzLookup = [Int: (surah: Int, ayah: Int)]()

        for surah in surahs {
            for ayah in surah.ayahs where ayah.existsInQiraah(displayQiraah) {
                if let page = ayah.page, pageLookup[page] == nil {
                    pageLookup[page] = (surah: surah.id, ayah: ayah.id)
                }
                if let juz = ayah.juz, juzLookup[juz] == nil {
                    juzLookup[juz] = (surah: surah.id, ayah: ayah.id)
                }
            }
        }

        return (page: pageLookup, juz: juzLookup)
    }

    private func buildPreprocessedSections(for surahs: [Surah]) -> (
        pageSections: [PageSectionData],
        juzSections: [JuzSectionData],
        revelationOrderSurahIDs: [Int]
    ) {
        let pageSections: [PageSectionData] = {
            let pairs = surahs.compactMap { surah -> (Int, Int)? in
                guard let page = surah.pageStart ?? surah.ayahs.compactMap(\.page).min() else { return nil }
                return (page, surah.id)
            }
            let grouped = Dictionary(grouping: pairs, by: { $0.0 })
            return grouped.keys.sorted().map { page in
                let surahIDs = (grouped[page] ?? []).map(\.1).sorted()
                return PageSectionData(page: page, surahIDs: surahIDs)
            }
        }()

        let juzSections: [JuzSectionData] = Self.juzList.sorted(by: { $0.id < $1.id }).map { juz in
            let surahIDs = surahs
                .filter { $0.id >= juz.startSurah && $0.id <= juz.endSurah }
                .map(\.id)
            let rows = buildPreprocessedJuzRows(juz: juz, surahs: surahs)
            return JuzSectionData(juz: juz, surahIDs: surahIDs, rows: rows)
        }

        let revelationOrderSurahIDs = surahs
            .sorted {
                let left = $0.revelationOrder ?? Int.max
                let right = $1.revelationOrder ?? Int.max
                if left == right {
                    return $0.id < $1.id
                }
                return left < right
            }
            .map(\.id)

        return (pageSections, juzSections, revelationOrderSurahIDs)
    }

    private func buildPreprocessedJuzRows(juz: Juz, surahs: [Surah]) -> [JuzSectionData.Row] {
        let surahByID = Dictionary(uniqueKeysWithValues: surahs.map { ($0.id, $0) })
        var rows: [JuzSectionData.Row] = []

        for surahID in juz.startSurah...juz.endSurah {
            guard let surah = surahByID[surahID] else { continue }
            let totalAyahs = surah.numberOfAyahs

            if surahID == juz.startSurah && surahID == juz.endSurah {
                rows.append(.init(surahID: surahID, kind: .start(ayah: juz.startAyah)))
                if juz.endAyah < totalAyahs {
                    rows.append(.init(surahID: surahID, kind: .end(ayah: juz.endAyah)))
                }
                continue
            }

            if surahID == juz.startSurah {
                rows.append(.init(surahID: surahID, kind: .start(ayah: juz.startAyah)))
                continue
            }

            if surahID == juz.endSurah {
                // Keep one plain surah entry first so this surah is not shown only as an "end" row.
                rows.append(.init(surahID: surahID, kind: .plain))
                if juz.endAyah < totalAyahs {
                    rows.append(.init(surahID: surahID, kind: .end(ayah: juz.endAyah)))
                }
                continue
            }

            rows.append(.init(surahID: surahID, kind: .plain))
        }

        return rows
    }
    
    func surah(_ number: Int) -> Surah? {
        surahIndex[number].map { quran[$0] }
    }

    func ayah(surah: Int, ayah: Int) -> Ayah? {
        guard let sIdx = surahIndex[surah], let aIdx = ayahIndex[sIdx][ayah] else { return nil }
        return quran[sIdx].ayahs[aIdx]
    }

    func resolveSurahIdentifier(_ raw: String) -> Surah? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = Int(trimmed) ?? arabicToEnglishNumber(trimmed), (1...114).contains(number) {
            return surah(number)
        }

        let cleaned = settings.cleanSearch(trimmed)
        let compactCleaned = cleaned.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        if let exact = quran.first(where: { surah in
            let exactNames = [
                settings.cleanSearch(surah.nameArabic),
                settings.cleanSearch(surah.nameTransliteration),
                settings.cleanSearch(surah.nameEnglish)
            ] + surah.similarNames.map { settings.cleanSearch($0) }
            let compactExactNames = exactNames.map { $0.replacingOccurrences(of: " ", with: "") }
            return exactNames.contains(cleaned) || compactExactNames.contains(compactCleaned)
        }) {
            return exact
        }

        return surahSearchIndex.first(where: {
            $0.searchableBlob.contains(cleaned) || $0.compactSearchableBlob.contains(compactCleaned)
        })
            .flatMap { surah($0.surahID) }
    }

    func resolveJuzIdentifier(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = Int(trimmed) ?? arabicToEnglishNumber(trimmed), (1...30).contains(number) {
            return number
        }

        let cleaned = settings.cleanSearch(trimmed)
        let compactCleaned = cleaned.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        if let exact = juzSearchIndex.first(where: {
            $0.searchableBlob.split(separator: " ").map(String.init).contains(cleaned)
                || $0.compactSearchableBlob.split(separator: " ").map(String.init).contains(compactCleaned)
        }) {
            return exact.juzID
        }

        return juzSearchIndex.first(where: {
            $0.searchableBlob.contains(cleaned) || $0.compactSearchableBlob.contains(compactCleaned)
        })?.juzID
    }

    func surahs(inJuz juzID: Int?) -> [Surah] {
        guard let juzID else { return [] }
        return (surahIDsByJuz[juzID] ?? []).compactMap { surah($0) }
    }

    func surahsMatchingCount(ayahFilter: CountFilter?, pageFilter: CountFilter?) -> [Surah] {
        func matchingIDs(from index: [Int: [Int]], filter: CountFilter?) -> Set<Int>? {
            guard let filter else { return nil }

            if filter.value < 1 { return [] }
            switch filter.op {
            case .equal:
                return Set(index[filter.value] ?? [])
            case .lessThan:
                return Set(index.filter { $0.key < filter.value }.flatMap { $0.value })
            case .lessThanOrEqual:
                return Set(index.filter { $0.key <= filter.value }.flatMap { $0.value })
            case .greaterThan:
                return Set(index.filter { $0.key > filter.value }.flatMap { $0.value })
            case .greaterThanOrEqual:
                return Set(index.filter { $0.key >= filter.value }.flatMap { $0.value })
            }
        }

        let ayahIDs = matchingIDs(from: surahIDsByAyahCount, filter: ayahFilter)
        let pageIDs = matchingIDs(from: surahIDsByPageCount, filter: pageFilter)

        let selectedIDs: Set<Int>
        switch (ayahIDs, pageIDs) {
        case let (a?, p?): selectedIDs = a.intersection(p)
        case let (a?, nil): selectedIDs = a
        case let (nil, p?): selectedIDs = p
        case (nil, nil):
            return quran
        }

        return quran.filter { selectedIDs.contains($0.id) }
    }

    func filteredSurahs(query rawQuery: String) -> [Surah] {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return quran }

        let cleanedQuery = settings.cleanSearch(trimmed.replacingOccurrences(of: ":", with: ""))
        let upperQuery = trimmed.uppercased()
        let normalizedQuery = cleanedQuery.replacingOccurrences(of: " ", with: "")
        let surahAyahPair = trimmed.split(separator: ":").map(String.init)
        let numericQuery: Int? = {
            if surahAyahPair.count == 2 {
                if let resolved = resolveSurahIdentifier(surahAyahPair[0]) {
                    return resolved.id
                }
                return Int(surahAyahPair[0]) ?? arabicToEnglishNumber(surahAyahPair[0])
            }
            return Int(cleanedQuery) ?? arabicToEnglishNumber(cleanedQuery)
        }()

        let revelationSearchMode: RevelationSearchMode? = {
            guard !normalizedQuery.isEmpty else { return nil }

            let makkanHit = Self.makkanAliases.contains { alias in
                alias.hasPrefix(normalizedQuery) || normalizedQuery.hasPrefix(alias)
            }
            if makkanHit { return .makkan }

            let madinanHit = Self.madinanAliases.contains { alias in
                alias.hasPrefix(normalizedQuery) || normalizedQuery.hasPrefix(alias)
            }
            if madinanHit { return .madinan }

            return nil
        }()

        let matches: [Surah] = surahSearchIndex.compactMap { entry -> Surah? in
            if let revelationSearchMode {
                guard let s = surah(entry.surahID) else { return nil }
                switch revelationSearchMode {
                case .makkan:
                    return s.type == "makkan" ? s : nil
                case .madinan:
                    return s.type == "madinan" ? s : nil
                }
            }

            if let numericQuery, entry.surahID == numericQuery {
                return surah(entry.surahID)
            }
            if upperQuery.contains(entry.nameEnglishUpper)
                || upperQuery.contains(entry.nameTransliterationUpper)
                || entry.searchableBlob.contains(cleanedQuery)
                || entry.compactSearchableBlob.contains(normalizedQuery) {
                return surah(entry.surahID)
            }
            return nil
        }

        guard settings.quranSortMode == .revelation else {
            return matches
        }

        return matches.sorted {
            let left = $0.revelationOrder ?? Int.max
            let right = $1.revelationOrder ?? Int.max
            if left == right {
                return $0.id < $1.id
            }
            return left < right
        }
    }

    func firstAyahResult(page: Int? = nil, juz: Int? = nil) -> (surah: Surah, ayah: Ayah)? {
        guard page != nil || juz != nil else { return nil }

        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedFirstAyahLookupQiraah != currentKey {
            rebuildFirstAyahLookups()
        }

        if let page, let hit = firstAyahByPage[page], let s = surah(hit.surah), let a = ayah(surah: hit.surah, ayah: hit.ayah) {
            return (surah: s, ayah: a)
        }

        if let juz, let hit = firstAyahByJuz[juz], let s = surah(hit.surah), let a = ayah(surah: hit.surah, ayah: hit.ayah) {
            return (surah: s, ayah: a)
        }

        return nil
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
        let booleanGroups = booleanAyahSearchGroups(from: raw)
        if let booleanGroups, booleanGroups.isEmpty { return [] }

        let useArabic = raw.containsArabicLetters

        if let booleanGroups {
            var filtered: [VerseIndexEntry] = []
            filtered.reserveCapacity(limit == .max ? 64 : min(limit, 64))

            var skipped = 0
            for entry in verseIndex {
                guard matchesBooleanAyahSearch(entry: entry, useArabic: useArabic, groups: booleanGroups) else { continue }
                if skipped < offset { skipped += 1; continue }
                filtered.append(entry)
                if limit != .max, filtered.count >= limit { break }
            }
            return filtered
        }

        var results: [VerseIndexEntry] = []
        results.reserveCapacity(limit == .max ? 64 : min(limit, 64))

        var skipped = 0
        for entry in verseIndex {
            let haystack = useArabic ? entry.arabicBlob : entry.englishBlob
            guard haystack.contains(q) else { continue }
            if skipped < offset { skipped += 1; continue }
            results.append(entry)
            if limit != .max, results.count >= limit { break }
        }

        return results
    }

    private struct BooleanAyahTerm {
        enum MatchMode {
            case contains
            case startsWith
            case endsWith
            case exact
        }

        let value: String
        let isNegated: Bool
        let matchMode: MatchMode
        let requiresTashkeelMatch: Bool
        let tashkeelPattern: String
        let requiresExactEnglishMatch: Bool
        let exactEnglishPhrase: String
    }

    func boundaryModel(forSurah surahID: Int) -> SurahBoundaryModel? {
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedBoundaryQiraah != currentKey {
            rebuildBoundaryModels()
        }
        return surahBoundaryModels[surahID]
    }

    private func booleanAyahSearchGroups(from rawQuery: String) -> [[BooleanAyahTerm]]? {
        let normalized = rawQuery
            .replacingOccurrences(of: "&&", with: "&")
            .replacingOccurrences(of: "||", with: "|")

        guard normalized.contains("&") || normalized.contains("|") || normalized.contains("!") || normalized.contains("#") || normalized.contains("^") || normalized.contains("%") || normalized.contains("$") else {
            return nil
        }

        return normalized
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { part in
                part
                    .split(separator: "&", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap(booleanAyahSearchTerm(from:))
            }
            .filter { !$0.isEmpty }
    }

    private func booleanAyahSearchTerm(from rawTerm: String) -> BooleanAyahTerm? {
        var term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }

        var isNegated = false
        while term.hasPrefix("!") {
            isNegated.toggle()
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var requiresTashkeelMatch = false
        while term.hasPrefix("#") {
            requiresTashkeelMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var startsWithMatch = false
        if term.hasPrefix("^") {
            startsWithMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var endsWithMatch = false
        if term.hasSuffix("%") || term.hasSuffix("$") {
            endsWithMatch = true
            term.removeLast()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !term.isEmpty else { return nil }
        let cleaned = settings.cleanSearch(term, whitespace: true)
        guard !cleaned.isEmpty else { return nil }

        let matchMode: BooleanAyahTerm.MatchMode
        if startsWithMatch && endsWithMatch {
            matchMode = .exact
        } else if startsWithMatch {
            matchMode = .startsWith
        } else if endsWithMatch {
            matchMode = .endsWith
        } else {
            matchMode = .contains
        }

        return BooleanAyahTerm(
            value: cleaned,
            isNegated: isNegated,
            matchMode: matchMode,
            requiresTashkeelMatch: requiresTashkeelMatch && term.containsArabicLetters,
            tashkeelPattern: arabicTashkeelBlob(term),
            requiresExactEnglishMatch: requiresTashkeelMatch && !term.containsArabicLetters,
            exactEnglishPhrase: exactPhraseBlob(term)
        )
    }

    private func ayahTermMatch(haystack: String, tokens: [String], term: String, mode: BooleanAyahTerm.MatchMode) -> Bool {
        switch mode {
        case .contains:
            return haystack.contains(term)
        case .startsWith:
            return haystack.hasPrefix(term) || tokens.contains(where: { $0.hasPrefix(term) })
        case .endsWith:
            return haystack.hasSuffix(term) || tokens.contains(where: { $0.hasSuffix(term) })
        case .exact:
            return haystack == term || tokens.contains(term)
        }
    }

    private func matchesBooleanAyahSearch(entry: VerseIndexEntry, useArabic: Bool, groups: [[BooleanAyahTerm]]) -> Bool {
        groups.contains { andTerms in
            andTerms.allSatisfy { term in
                let containsTerm: Bool
                if useArabic, term.requiresTashkeelMatch {
                    let lettersMatch = ayahTermMatch(
                        haystack: entry.arabicBlob,
                        tokens: entry.arabicTokens,
                        term: term.value,
                        mode: term.matchMode
                    )
                    let tashkeelMatch = term.tashkeelPattern.isEmpty || entry.arabicTashkeelBlob.contains(term.tashkeelPattern)
                    containsTerm = lettersMatch && tashkeelMatch
                } else if !useArabic, term.requiresExactEnglishMatch {
                    let exactTokens = searchTokens(from: term.exactEnglishPhrase)
                    containsTerm = !term.exactEnglishPhrase.isEmpty && ayahTermMatch(
                        haystack: entry.englishExactBlob,
                        tokens: exactTokens,
                        term: term.exactEnglishPhrase,
                        mode: term.matchMode
                    )
                } else {
                    let haystack = useArabic ? entry.arabicBlob : entry.englishBlob
                    let tokens = useArabic ? entry.arabicTokens : entry.englishTokens
                    containsTerm = ayahTermMatch(haystack: haystack, tokens: tokens, term: term.value, mode: term.matchMode)
                }
                return term.isNegated ? !containsTerm : containsTerm
            }
        }
    }
    
    func searchVersesAll(term raw: String) -> [VerseIndexEntry] {
        withAnimation {
            searchVerses(term: raw, limit: .max, offset: 0)
        }
    }
    
    static let juzList: [Juz] = [
        Juz(id: 1,
            nameArabic: "الم",
            nameTransliteration: "Alif Lam Meem",
            startSurah: 1, startAyah: 1,
            endSurah: 2, endAyah: 141
        ),

        Juz(id: 2,
            nameArabic: "سَيَقُول",
            nameTransliteration: "Sayaqoolu",
            startSurah: 2, startAyah: 142,
            endSurah: 2, endAyah: 252
        ),

        Juz(id: 3,
            nameArabic: "تِلكَ ٱلرُّسُل",
            nameTransliteration: "Tilka Ar-Rusul",
            startSurah: 2, startAyah: 253,
            endSurah: 3, endAyah: 92
        ),

        Juz(id: 4,
            nameArabic: "كُلُّ ٱلطَّعَامِ",
            nameTransliteration: "Kullu At-Ta'am",
            startSurah: 3, startAyah: 93,
            endSurah: 4, endAyah: 23
        ),

        Juz(id: 5,
            nameArabic: "وَٱلمُحصَنَات",
            nameTransliteration: "Wal-Muhsanat",
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
            nameArabic: "لَتَجِدَنَّ أَشَدّ",
            nameTransliteration: "Latajidanna Ashadd",
            startSurah: 5, startAyah: 82,
            endSurah: 6, endAyah: 110
        ),

        Juz(id: 8,
            nameArabic: "وَلَو أَنَّنَا",
            nameTransliteration: "Walaw Annana",
            startSurah: 6, startAyah: 111,
            endSurah: 7, endAyah: 87
        ),

        Juz(id: 9,
            nameArabic: "قَالَ ٱلمَلَأُ",
            nameTransliteration: "Qala Al-Mala'u",
            startSurah: 7, startAyah: 88,
            endSurah: 8, endAyah: 40
        ),

        Juz(id: 10,
            nameArabic: "وَٱعلَمُوا",
            nameTransliteration: "Wa'alamoo",
            startSurah: 8, startAyah: 41,
            endSurah: 9, endAyah: 92
        ),

        Juz(id: 11,
            nameArabic: "إِنَّمَا ٱلسَّبِيلُ",
            nameTransliteration: "Innama As-Sabeel",
            startSurah: 9, startAyah: 93,
            endSurah: 11, endAyah: 5
        ),

        Juz(id: 12,
            nameArabic: "وَمَا مِن دَآبَّة",
            nameTransliteration: "Wamaa Min Daabbah",
            startSurah: 11, startAyah: 6,
            endSurah: 12, endAyah: 52
        ),

        Juz(id: 13,
            nameArabic: "وَمَا أُبَرِّئُ",
            nameTransliteration: "Wamaa Ubarri'u",
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
            nameTransliteration: "Subhaana Al-Ladhee",
            startSurah: 17, startAyah: 1,
            endSurah: 18, endAyah: 74
        ),

        Juz(id: 16,
            nameArabic: "قَالَ أَلَم",
            nameTransliteration: "Qala Alam",
            startSurah: 18, startAyah: 75,
            endSurah: 20, endAyah: 135
        ),

        Juz(id: 17,
            nameArabic: "ٱقتَرَبَ لِلنَّاسِ",
            nameTransliteration: "Iqtaraba Lin-Naas",
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
            nameTransliteration: "Waqaala Al-Ladheena",
            startSurah: 25, startAyah: 21,
            endSurah: 27, endAyah: 55
        ),

        Juz(id: 20,
            nameArabic: "فَمَا كَانَ جَوَاب",
            nameTransliteration: "Fama Kaana Jawaab",
            startSurah: 27, startAyah: 56,
            endSurah: 29, endAyah: 45
        ),

        Juz(id: 21,
            nameArabic: "وَلَا تُجَٰدِلُوٓاْ",
            nameTransliteration: "Walaa Tujadiloo",
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
            nameTransliteration: "Wammaa Anzalnaa",
            startSurah: 36, startAyah: 28,
            endSurah: 39, endAyah: 31
        ),

        Juz(id: 24,
            nameArabic: "فَمَن أَظلَم",
            nameTransliteration: "Faman Adhlam",
            startSurah: 39, startAyah: 32,
            endSurah: 41, endAyah: 46
        ),

        Juz(id: 25,
            nameArabic: "إِلَيهِ يُرَدّ",
            nameTransliteration: "Ilayhi Yuradd",
            startSurah: 41, startAyah: 47,
            endSurah: 45, endAyah: 37
        ),

        Juz(id: 26,
            nameArabic: "حم",
            nameTransliteration: "Ha Meem",
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
            nameArabic: "قَد سَمِعَ",
            nameTransliteration: "Qad Sami'a",
            startSurah: 58, startAyah: 1,
            endSurah: 66, endAyah: 12
        ),

        Juz(id: 29,
            nameArabic: "تَبَارَك",
            nameTransliteration: "Tabaarak",
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
