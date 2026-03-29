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

    private func normalizeForSearch(_ text: String, trimWhitespace: Bool) -> String {
        settings.cleanSearch(text, whitespace: trimWhitespace)
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
        var normalizedIndex = normalizedSource.startIndex
        var sourceIndex = source.startIndex

        while normalizedIndex < matchRange.lowerBound, sourceIndex < source.endIndex {
            let foldedCharacter = normalizeForSearch(String(source[sourceIndex]), trimWhitespace: false)
            normalizedIndex = normalizedSource.index(normalizedIndex, offsetBy: foldedCharacter.count)
            sourceIndex = source.index(after: sourceIndex)
        }

        let start = sourceIndex
        var remainingLength = normalizedTerm.count

        while remainingLength > 0, sourceIndex < source.endIndex {
            let foldedCharacter = normalizeForSearch(String(source[sourceIndex]), trimWhitespace: false)
            remainingLength -= foldedCharacter.count
            sourceIndex = source.index(after: sourceIndex)
        }

        return start..<sourceIndex
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
