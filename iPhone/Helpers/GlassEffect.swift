import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    @EnvironmentObject var settings: Settings
    
    var tint: Color? = nil
    var clear: Bool = false
    var regular: Bool = false

    func body(content: Content) -> some View {
        let effectiveTint: Color = tint ?? settings.accentColor.color

        if #available(iOS 26.0, watchOS 26.0, visionOS 26.0, macOS 26.0, *) {
            if regular {
                if clear {
                    content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
                } else {
                    content.glassEffect(.regular.tint(effectiveTint.opacity(0.25)).interactive(), in: .rect(cornerRadius: 24))
                }
            } else {
                if clear {
                    content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
                } else {
                    content.glassEffect(.regular.tint(effectiveTint.opacity(0.25)).interactive(), in: .rect(cornerRadius: 24))
                }
            }
        }
    }
}

extension View {
    func conditionalGlassEffect(tint: Color? = nil, clear: Bool = false, regular: Bool = false) -> some View {
        modifier(ConditionalGlassEffect(tint: tint, clear: clear, regular: regular))
    }
}
