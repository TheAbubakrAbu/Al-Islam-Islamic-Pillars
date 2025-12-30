import SwiftUI

enum AccentColor: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case red, orange, yellow, green, blue, indigo, cyan, teal, mint, purple, pink, brown

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .cyan: return .cyan
        case .teal: return .teal
        case .mint: return .mint
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        }
    }
}

let accentColors: [AccentColor] = AccentColor.allCases

struct CustomColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    var customColorScheme: ColorScheme? {
        get { self[CustomColorSchemeKey.self] }
        set { self[CustomColorSchemeKey.self] = newValue }
    }
}

func arabicNumberString(from number: Int) -> String {
    let arabicNumbers = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
    return String(number).map { arabicNumbers[Int(String($0))!] }.joined()
}

private let quranStripScalars: Set<UnicodeScalar> = {
    var s = Set<UnicodeScalar>()

    // Tashkeel  U+064B…U+065F
    for v in 0x064B...0x065F { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Quranic annotation signs  U+06D6…U+06ED
    for v in 0x06D6...0x06ED { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Extras: short alif, madda, open ta-marbuta, dagger alif
    [0x0670, 0x0657, 0x0674, 0x0656].forEach { v in
        if let u = UnicodeScalar(v) { s.insert(u) }
    }

    return s
}()

extension String {
    var removingArabicDiacriticsAndSigns: String {
        var out = String.UnicodeScalarView()
        out.reserveCapacity(unicodeScalars.count)

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0671: // ٱ  hamzatul-wasl
                out.append(UnicodeScalar(0x0627)!)
            default:
                if !quranStripScalars.contains(scalar) { out.append(scalar) }
            }
        }
        return String(out)
    }
    
    func removeDiacriticsFromLastLetter() -> String {
        guard let last = last else { return self }
        let cleaned = String(last).removingArabicDiacriticsAndSigns
        return cleaned == String(last) ? self : dropLast() + cleaned
    }

    subscript(_ r: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return self[start..<end]
    }
}
