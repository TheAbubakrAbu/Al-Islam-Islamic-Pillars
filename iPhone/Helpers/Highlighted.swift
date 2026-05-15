import SwiftUI

struct HighlightedSnippet: View {
    @EnvironmentObject var settings: Settings

    let source: String
    let term: String
    let font: Font
    let accent: Color
    let fg: Color
    var preStyledSource: AttributedString? = nil
    var beginnerMode: Bool = false
    var trailingSuffix: String = ""
    var trailingSuffixFont: Font? = nil
    var trailingSuffixColor: Color? = nil
    var lineLimit: Int? = nil
    var highlightAllahNames: Bool = false

    var body: some View {
        let resolvedSearchTerm = searchTerm
        let needsSearchHighlight = !resolvedSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let needsAttributedWork = needsSearchHighlight || highlightAllahNames || preStyledSource != nil
        let suffixText = Text(trailingSuffix)
            .font(trailingSuffixFont ?? font)
            .foregroundColor(trailingSuffixColor ?? fg)

        if needsAttributedWork {
            let highlightedText = highlightAllahIfNeeded(
                source: source,
                baseAttributed: highlight(
                    source: source,
                    baseAttributed: baseAttributedText(),
                    term: resolvedSearchTerm
                )
            )

            (Text(highlightedText) + suffixText)
                .font(font)
                .lineLimit(lineLimit)
        } else {
            (Text(source).foregroundColor(fg) + suffixText)
                .font(font)
                .lineLimit(lineLimit)
        }
    }

    private var searchTerm: String {
        beginnerMode ? term.map(String.init).joined(separator: " ") : term
    }

    private static let englishHighlightStripSet: CharacterSet = {
        CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
    }()

    // MARK: - Caches

    private final class SourceNormEntry: NSObject {
        let normalizedSource: String
        let indexMap: [String.Index]
        init(_ n: String, _ i: [String.Index]) { normalizedSource = n; indexMap = i }
    }

    private final class RangeEntry: NSObject {
        let ranges: [Range<String.Index>]
        init(_ r: [Range<String.Index>]) { ranges = r }
    }

    /// source → (normalizedSource, indexMap): amortises the O(n×k) per-character normalization.
    private static let sourceNormCache: NSCache<NSString, SourceNormEntry> = {
        let c = NSCache<NSString, SourceNormEntry>()
        c.countLimit = 7_000
        return c
    }()

    /// "source\0normalizedTerm" → matched ranges in original source: amortises the range search.
    private static let matchRangeCache: NSCache<NSString, RangeEntry> = {
        let c = NSCache<NSString, RangeEntry>()
        c.countLimit = 10_000
        return c
    }()

    /// source → Allah highlight ranges: amortises the O(n) per-render Allah scan.
    private static let allahRangeCache: NSCache<NSString, RangeEntry> = {
        let c = NSCache<NSString, RangeEntry>()
        c.countLimit = 7_000
        return c
    }()

    private func normalizeEnglishForHighlight(_ text: String, trimWhitespace: Bool) -> String {
        var cleaned = String(text.unicodeScalars
            .filter { !Self.englishHighlightStripSet.contains($0) }
        ).lowercased()

        if trimWhitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    private func normalizeForSearch(_ text: String, trimWhitespace: Bool) -> String {
        if !text.containsArabicLetters {
            return normalizeEnglishForHighlight(text, trimWhitespace: trimWhitespace)
        }
        return settings.cleanSearch(text, whitespace: trimWhitespace)
            .removingArabicDiacriticsAndSigns
    }

    private func normalizeForAllahHighlight(_ text: String) -> String {
        settings.cleanSearch(text.removingArabicDiacriticsAndSigns, whitespace: false)
    }

    private func baseAttributedText() -> AttributedString {
        if let preStyledSource {
            return preStyledSource
        }

        var attributed = AttributedString(source)
        attributed.foregroundColor = fg
        return attributed
    }

    private func highlight(source: String, baseAttributed: AttributedString, term: String) -> AttributedString {
        var attributed = baseAttributed

        let normalizedTerm = normalizeForSearch(term, trimWhitespace: true)
        guard !normalizedTerm.isEmpty else { return attributed }

        // --- Step 1: normalizedSource + indexMap, cached per source string ---
        let sourceKey = source as NSString
        let normEntry: SourceNormEntry
        if let cached = Self.sourceNormCache.object(forKey: sourceKey) {
            normEntry = cached
        } else {
            let ns = normalizeForSearch(source, trimWhitespace: false)
            let im = normalizedIndexMap(in: source, normalizedSource: ns)
            normEntry = SourceNormEntry(ns, im)
            Self.sourceNormCache.setObject(normEntry, forKey: sourceKey)
        }

        // --- Step 2: matched ranges in original source, cached per (source, normalizedTerm) ---
        let matchKey = "\(source)\u{0000}\(normalizedTerm)" as NSString
        let matchedRanges: [Range<String.Index>]
        if let cached = Self.matchRangeCache.object(forKey: matchKey) {
            matchedRanges = cached.ranges
        } else {
            var ranges: [Range<String.Index>] = []
            var searchStart = normEntry.normalizedSource.startIndex
            while searchStart < normEntry.normalizedSource.endIndex,
                  let matchRange = normEntry.normalizedSource.range(of: normalizedTerm, range: searchStart..<normEntry.normalizedSource.endIndex) {
                if let orig = originalRange(
                    in: source,
                    normalizedSource: normEntry.normalizedSource,
                    matchRange: matchRange,
                    indexMap: normEntry.indexMap
                ) {
                    ranges.append(orig)
                }
                searchStart = matchRange.upperBound
            }
            if ranges.isEmpty, source.containsArabicLetters {
                ranges = arabicPhrasePrefixRanges(
                    in: source,
                    normalizedSource: normEntry.normalizedSource,
                    normalizedTerm: normalizedTerm,
                    indexMap: normEntry.indexMap
                )
            }
            Self.matchRangeCache.setObject(RangeEntry(ranges), forKey: matchKey)
            matchedRanges = ranges
        }

        // --- Step 3: apply accent colour to each matched range ---
        for range in matchedRanges {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = accent
            }
        }

        return attributed
    }

    private func arabicPhrasePrefixRanges(
        in source: String,
        normalizedSource: String,
        normalizedTerm: String,
        indexMap: [String.Index]
    ) -> [Range<String.Index>] {
        let queryTokens = normalizedTerm
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !queryTokens.isEmpty else { return [] }

        let sourceTokens = normalizedTokenRanges(in: normalizedSource)
        guard sourceTokens.count >= queryTokens.count else { return [] }

        var ranges: [Range<String.Index>] = []
        for start in 0...(sourceTokens.count - queryTokens.count) {
            var matched = true

            for offset in queryTokens.indices {
                let tokenRange = sourceTokens[start + offset]
                let sourceToken = String(normalizedSource[tokenRange])
                let queryToken = queryTokens[offset]

                if offset == queryTokens.count - 1 {
                    if !sourceToken.hasPrefix(queryToken) {
                        matched = false
                        break
                    }
                } else if sourceToken != queryToken {
                    matched = false
                    break
                }
            }

            guard matched else { continue }

            let lower = sourceTokens[start].lowerBound
            let lastTokenRange = sourceTokens[start + queryTokens.count - 1]
            let lastToken = String(normalizedSource[lastTokenRange])
            let upper: String.Index
            if lastToken == queryTokens.last {
                upper = lastTokenRange.upperBound
            } else {
                upper = normalizedSource.index(lastTokenRange.lowerBound, offsetBy: queryTokens.last?.count ?? 0)
            }

            if let orig = originalRange(
                in: source,
                normalizedSource: normalizedSource,
                matchRange: lower..<upper,
                indexMap: indexMap
            ) {
                ranges.append(orig)
            }
        }

        return ranges
    }

    private func normalizedTokenRanges(in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var cursor = text.startIndex

        while cursor < text.endIndex {
            while cursor < text.endIndex, text[cursor].isWhitespace {
                cursor = text.index(after: cursor)
            }
            guard cursor < text.endIndex else { break }

            let start = cursor
            while cursor < text.endIndex, !text[cursor].isWhitespace {
                cursor = text.index(after: cursor)
            }
            ranges.append(start..<cursor)
        }

        return ranges
    }

    private func highlightAllahIfNeeded(source: String, baseAttributed: AttributedString) -> AttributedString {
        guard highlightAllahNames else { return baseAttributed }

        var attributed = baseAttributed

        if !source.containsArabicLetters {
            highlightEnglishAllah(source: source, attributed: &attributed)
            return attributed
        }

        highlightArabicAllah(source: source, attributed: &attributed)

        return attributed
    }

    private func highlightEnglishAllah(source: String, attributed: inout AttributedString) {
        var searchStart = source.startIndex
        while searchStart < source.endIndex,
              let matchRange = source.range(
                of: "Allah",
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<source.endIndex
              ) {
            if let start = AttributedString.Index(matchRange.lowerBound, within: attributed),
               let end = AttributedString.Index(matchRange.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = .red
            }

            searchStart = matchRange.upperBound
        }
    }

    private func highlightArabicAllah(source: String, attributed: inout AttributedString) {
        let cacheKey = source as NSString
        let ranges: [Range<String.Index>]
        if let cached = Self.allahRangeCache.object(forKey: cacheKey) {
            ranges = cached.ranges
        } else {
            var found: [Range<String.Index>] = []
            for start in source.indices {
                if let range = arabicAllahRange(startingAt: start, in: source) {
                    found.append(range)
                }
            }
            Self.allahRangeCache.setObject(RangeEntry(found), forKey: cacheKey)
            ranges = found
        }

        for range in ranges {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = .red
            }
        }
    }

    private func arabicAllahRange(startingAt start: String.Index, in source: String) -> Range<String.Index>? {
        if source[start].allahBase?.isAllahAlif == true,
           let afterAlif = nextNonMarkIndex(after: start, in: source),
           source[afterAlif].allahBase == "ل",
           let secondLam = nextNonMarkIndex(after: afterAlif, in: source),
           source[secondLam].allahBase == "ل",
           let heh = nextNonMarkIndex(after: secondLam, in: source),
           source[heh].allahBase == "ه" {
            return start..<rangeUpperBound(afterBaseAt: heh, in: source)
        }

        if source[start].allahBase == "ل",
           let secondLam = nextNonMarkIndex(after: start, in: source),
           source[secondLam].allahBase == "ل",
           let heh = nextNonMarkIndex(after: secondLam, in: source),
           source[heh].allahBase == "ه" {
            return start..<rangeUpperBound(afterBaseAt: heh, in: source)
        }

        return nil
    }

    private func nextNonMarkIndex(after index: String.Index, in source: String) -> String.Index? {
        var cursor = source.index(after: index)
        while cursor < source.endIndex {
            if !source[cursor].isArabicMark {
                return cursor
            }
            cursor = source.index(after: cursor)
        }
        return nil
    }

    private func rangeUpperBound(afterBaseAt index: String.Index, in source: String) -> String.Index {
        var cursor = source.index(after: index)
        while cursor < source.endIndex, source[cursor].isArabicAllahHighlightMark {
            cursor = source.index(after: cursor)
        }
        return cursor
    }

    private func normalizedIndexMap(in source: String, normalizedSource: String) -> [String.Index] {
        var map: [String.Index] = []
        map.reserveCapacity(normalizedSource.count)

        for idx in source.indices {
            let next = source.index(after: idx)
            let normalizedCharacter = normalizeForSearch(String(source[idx..<next]), trimWhitespace: false)
            for _ in normalizedCharacter {
                map.append(idx)
            }
        }

        return map
    }

    private func originalRange(
        in source: String,
        normalizedSource: String,
        matchRange: Range<String.Index>,
        indexMap: [String.Index]
    ) -> Range<String.Index>? {
        guard indexMap.count == normalizedSource.count else { return nil }

        let lowerOffset = normalizedSource.distance(from: normalizedSource.startIndex, to: matchRange.lowerBound)
        let upperOffset = normalizedSource.distance(from: normalizedSource.startIndex, to: matchRange.upperBound)

        guard lowerOffset >= 0,
              upperOffset > lowerOffset,
              lowerOffset < indexMap.count,
              upperOffset - 1 < indexMap.count else {
            return nil
        }

        let start = indexMap[lowerOffset]
        let lastMatched = indexMap[upperOffset - 1]
        let end = source.index(after: lastMatched)
        return start..<end
    }

}

private extension Character {
    var allahBase: Character? {
        for scalar in unicodeScalars where !scalar.isArabicMarkScalar {
            switch scalar.value {
            case 0x0627, 0x0671:
                return "ا"
            case 0x0644:
                return "ل"
            case 0x0647:
                return "ه"
            default:
                continue
            }
        }

        return nil
    }

    var isAllahAlif: Bool {
        self == "ا"
    }

    var isArabicMark: Bool {
        unicodeScalars.allSatisfy(\.isArabicMarkScalar)
    }

    var isArabicAllahHighlightMark: Bool {
        unicodeScalars.allSatisfy(\.isArabicAllahHighlightMarkScalar)
    }
}

private extension UnicodeScalar {
    var isArabicMarkScalar: Bool {
        switch value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670,
             0x06D6...0x06ED:
            return true
        default:
            return false
        }
    }

    var isArabicAllahHighlightMarkScalar: Bool {
        switch value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670:
            return true
        default:
            return false
        }
    }
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
