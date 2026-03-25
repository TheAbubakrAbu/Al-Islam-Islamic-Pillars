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

    var body: some View {
        let result = highlight(
            source: source,
            baseAttributed: baseAttributedText(),
            term: spacedQueryIfNeeded
        )
        let combined = Text(result) + Text(trailingSuffix)
            .font(trailingSuffixFont ?? font)
            .foregroundColor(trailingSuffixColor ?? fg)
        combined
            .font(font)
            .lineLimit(nil)
            #if !os(watchOS)
            .textSelection(.enabled)
            #endif
    }

    private var spacedQueryIfNeeded: String {
        beginnerMode ? term.map { String($0) }.joined(separator: " ") : term
    }

    private func normalizeForSearch(_ s: String, trimWhitespace: Bool) -> String {
        settings.cleanSearch(s, whitespace: trimWhitespace)
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
        let normalizedTerm   = normalizeForSearch(term,   trimWhitespace: true)

        guard !normalizedTerm.isEmpty,
              let matchRange = normalizedSource.range(of: normalizedTerm)
        else { return attributed }

        var originalStart: String.Index? = nil
        var originalEnd:   String.Index? = nil

        var normIndex = normalizedSource.startIndex
        var origIndex = source.startIndex

        while normIndex < matchRange.lowerBound && origIndex < source.endIndex {
            let folded = normalizeForSearch(String(source[origIndex]), trimWhitespace: false)
            normIndex = normalizedSource.index(normIndex, offsetBy: folded.count)
            origIndex = source.index(after: origIndex)
        }
        originalStart = origIndex

        var lengthLeft = normalizedTerm.count
        while lengthLeft > 0 && origIndex < source.endIndex {
            let folded = normalizeForSearch(String(source[origIndex]), trimWhitespace: false)
            lengthLeft -= folded.count
            origIndex = source.index(after: origIndex)
        }
        originalEnd = origIndex

        if let s = originalStart, let e = originalEnd,
           let aStart = AttributedString.Index(s, within: attributed),
           let aEnd = AttributedString.Index(e, within: attributed) {
            attributed[aStart..<aEnd].foregroundColor = accent
        }

        return attributed
    }
}
