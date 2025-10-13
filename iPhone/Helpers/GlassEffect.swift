import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    @EnvironmentObject var settings: Settings
    
    var clear: Bool = false

    func body(content: Content) -> some View {
        let effectiveTint: Color = settings.accentColor.color

        if #available(iOS 26.0, watchOS 26.0, visionOS 26.0, macOS 26.0, *) {
            if clear {
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
            } else {
                content.glassEffect(.regular.tint(effectiveTint.opacity(0.25)).interactive(), in: .rect(cornerRadius: 24))
            }
        }
    }
}

extension View {
    func conditionalGlassEffect(clear: Bool = false) -> some View {
        modifier(ConditionalGlassEffect(clear: clear))
    }
}
