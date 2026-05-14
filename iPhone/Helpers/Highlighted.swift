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
        CharacterSet.punctuationCharacters.union(.symbols)
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

        guard !normalizedTerm.isEmpty else {
            return attributed
        }

        let normalizedSource = normalizeForSearch(source, trimWhitespace: false)
        let indexMap = normalizedIndexMap(in: source, normalizedSource: normalizedSource)
        var searchStart = normalizedSource.startIndex

        while searchStart < normalizedSource.endIndex,
              let matchRange = normalizedSource.range(of: normalizedTerm, range: searchStart..<normalizedSource.endIndex) {
            if let originalRange = originalRange(
                in: source,
                normalizedSource: normalizedSource,
                matchRange: matchRange,
                indexMap: indexMap
            ),
               let start = AttributedString.Index(originalRange.lowerBound, within: attributed),
               let end = AttributedString.Index(originalRange.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = accent
            }

            searchStart = matchRange.upperBound
        }

        return attributed
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
        for start in source.indices {
            if let range = arabicAllahRange(startingAt: start, in: source),
               let attributedStart = AttributedString.Index(range.lowerBound, within: attributed),
               let attributedEnd = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[attributedStart..<attributedEnd].foregroundColor = .red
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
