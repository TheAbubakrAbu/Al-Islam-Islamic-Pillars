import SwiftUI

struct HighlightedSnippet: View {
    @EnvironmentObject var settings: Settings

    let source: String
    let term: String
    let font: Font
    let accent: Color
    let fg: Color
    var beginnerMode: Bool = false

    var body: some View {
        let result = highlight(source: source, term: spacedQueryIfNeeded)
        Text(result)
            .font(font)
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

    private func highlight(source: String, term: String) -> AttributedString {
        var attributed = AttributedString(source)
        attributed.foregroundColor = fg

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
