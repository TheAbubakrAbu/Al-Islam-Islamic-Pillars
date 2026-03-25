import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    @EnvironmentObject var settings: Settings
    
    var clear: Bool = false
    var rectangle: Bool = false
    var useColor: Double? = nil

    func body(content: Content) -> some View {
        let tintColor = useColor.map { settings.accentColor.color.opacity($0) }

        if #available(iOS 26.0, watchOS 26.0, *) {
            if rectangle {
                if clear {
                    if let tintColor {
                        content.glassEffect(
                            .clear.tint(tintColor).interactive(),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                    } else {
                        content.glassEffect(
                            .clear.interactive(),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                    }
                } else {
                    if let tintColor {
                        content.glassEffect(
                            .regular.tint(tintColor).interactive(),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                    } else {
                        content.glassEffect(
                            .regular.interactive(),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                    }
                }
            } else {
                if clear {
                    if let tintColor {
                        content.glassEffect(
                            .clear.tint(tintColor).interactive(),
                            in: .capsule
                        )
                    } else {
                        content.glassEffect(
                            .clear.interactive(),
                            in: .capsule
                        )
                    }
                } else {
                    if let tintColor {
                        content.glassEffect(
                            .regular.tint(tintColor).interactive(),
                            in: .capsule
                        )
                    } else {
                        content.glassEffect(
                            .regular.interactive(),
                            in: .capsule
                        )
                    }
                }
            }
        } else {
            let fallbackBaseFill: Color = {
                #if os(watchOS)
                return Color.gray.opacity(clear ? 0.12 : 0.18)
                #else
                return Color(UIColor.secondarySystemBackground).opacity(clear ? 0.7 : 1.0)
                #endif
            }()

            let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
            let fallbackOverlayColor = tintColor ?? .clear
            let fallbackBackground: AnyView = {
                if #available(iOS 15.0, watchOS 10.0, *) {
                    return AnyView(shape.fill(.ultraThinMaterial))
                } else {
                    return AnyView(shape.fill(fallbackBaseFill))
                }
            }()

            content
                .background(fallbackBackground)
                .overlay(
                    shape.fill(fallbackOverlayColor)
                )
                .overlay(
                    shape.stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

extension View {
    func conditionalGlassEffect(clear: Bool = false, rectangle: Bool = false, useColor: Double? = nil) -> some View {
        modifier(ConditionalGlassEffect(clear: clear, rectangle: rectangle, useColor: useColor))
    }
}
