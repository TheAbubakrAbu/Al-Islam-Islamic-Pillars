import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    @EnvironmentObject var settings: Settings
    
    var clear: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, watchOS 26.0, visionOS 26.0, macOS 26.0, *) {
            if clear {
                content.glassEffect(.clear.interactive(), in: .rect(cornerRadius: 24))
            } else {
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
            }
        } else {
            let fallbackBaseFill: Color = {
                #if os(watchOS)
                return Color.gray.opacity(clear ? 0.12 : 0.18)
                #else
                return Color(UIColor.secondarySystemBackground).opacity(clear ? 0.7 : 1.0)
                #endif
            }()

            content
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(fallbackBaseFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

extension View {
    func conditionalGlassEffect(clear: Bool = false) -> some View {
        modifier(ConditionalGlassEffect(clear: clear))
    }
}
