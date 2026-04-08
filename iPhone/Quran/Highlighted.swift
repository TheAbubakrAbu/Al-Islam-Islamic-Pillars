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

    var body: some View {
        let highlightedText = highlight(
            source: source,
            baseAttributed: baseAttributedText(),
            term: searchTerm
        )

        let suffixText = Text(trailingSuffix)
            .font(trailingSuffixFont ?? font)
            .foregroundColor(trailingSuffixColor ?? fg)

        (Text(highlightedText) + suffixText)
            .font(font)
            .lineLimit(lineLimit)
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

        let normalizedSource = normalizeForSearch(source, trimWhitespace: false)
        let normalizedTerm = normalizeForSearch(term, trimWhitespace: true)

        guard
            !normalizedTerm.isEmpty,
            let matchRange = normalizedSource.range(of: normalizedTerm),
            let originalRange = originalRange(
                in: source,
                normalizedSource: normalizedSource,
                normalizedTerm: normalizedTerm,
                matchRange: matchRange
            ),
            let start = AttributedString.Index(originalRange.lowerBound, within: attributed),
            let end = AttributedString.Index(originalRange.upperBound, within: attributed)
        else {
            return attributed
        }

        attributed[start..<end].foregroundColor = accent

        return attributed
    }

    private func originalRange(
        in source: String,
        normalizedSource: String,
        normalizedTerm: String,
        matchRange: Range<String.Index>
    ) -> Range<String.Index>? {
        let indexMap = normalizedIndexMap(in: source, normalizedSource: normalizedSource)
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

    private func normalizedIndexMap(in source: String, normalizedSource: String) -> [String.Index] {
        var map: [String.Index] = []
        map.reserveCapacity(normalizedSource.count)

        var previousNormalizedCount = 0
        for idx in source.indices {
            let next = source.index(after: idx)
            let prefix = String(source[..<next])
            let normalizedPrefix = normalizeForSearch(prefix, trimWhitespace: false)
            let currentCount = normalizedPrefix.count
            let delta = currentCount - previousNormalizedCount

            if delta > 0 {
                for _ in 0..<delta {
                    map.append(idx)
                }
            }

            previousNormalizedCount = currentCount
        }

        return map
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        HighlightedSnippet(
            source: "Bismillahir Rahmanir Raheem",
            term: "rah",
            font: .body,
            accent: .green,
            fg: .primary
        )
        .padding()
    }
}
