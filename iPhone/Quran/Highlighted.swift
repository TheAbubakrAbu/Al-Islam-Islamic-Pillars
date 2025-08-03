import SwiftUI

struct HighlightedSnippet: View {
    @EnvironmentObject var settings: Settings

    let source: String
    let term: String
    let font: Font
    let accent: Color
    let fg: Color
    var beginnerMode: Bool = false
    var selectable: Bool = true

    var body: some View {
        let result = highlight(source: source, term: spacedQueryIfNeeded)
        Text(result)
            .font(font)
            #if !os(watchOS)
            .textSelection(.enabled)
            #endif
    }

    private var spacedQueryIfNeeded: String {
        if beginnerMode {
            return term.map { String($0) }.joined(separator: " ")
        }
        return term
    }

    private func highlight(source: String, term: String) -> AttributedString {
        var attributed = AttributedString(source)
        attributed.foregroundColor = fg

        let normalizedSource = settings.cleanSearch(source).removingArabicDiacriticsAndSigns
        let normalizedTerm   = settings.cleanSearch(term, whitespace: true).removingArabicDiacriticsAndSigns

        guard !normalizedTerm.isEmpty,
              let matchRange = normalizedSource.range(of: normalizedTerm)
        else {
            return attributed
        }

        var originalStart: String.Index? = nil
        var originalEnd: String.Index? = nil
        var normIndex = normalizedSource.startIndex
        var origIndex = source.startIndex

        while normIndex < matchRange.lowerBound && origIndex < source.endIndex {
            let foldedOrig = settings.cleanSearch(String(source[origIndex]))
            normIndex = normalizedSource.index(normIndex, offsetBy: foldedOrig.count)
            origIndex = source.index(after: origIndex)
        }

        originalStart = origIndex

        var lengthLeft = normalizedTerm.count
        while lengthLeft > 0 && origIndex < source.endIndex {
            let foldedOrig = settings.cleanSearch(String(source[origIndex]))
            lengthLeft -= foldedOrig.count
            origIndex = source.index(after: origIndex)
        }

        originalEnd = origIndex

        if let start = originalStart, let end = originalEnd,
           let rangeInAttr = attributed.range(of: String(source[start..<end])) {
            attributed[rangeInAttr].foregroundColor = accent
        }

        return attributed
    }
}

