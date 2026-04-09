import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    @EnvironmentObject private var settings: Settings

    var clear: Bool = false
    var rectangle: Bool = false
    var circle: Bool = false
    var useColor: Double? = nil
    /// When set, tints glass with this color (opacity from `useColor`, default 0.35) instead of the app accent.
    var customTint: Color? = nil

    func body(content: Content) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
            modernGlass(content: content)
        } else {
            fallbackGlass(content: content)
        }
    }

    @available(iOS 26.0, watchOS 26.0, *)
    private func modernGlass(content: Content) -> some View {
        Group {
            if circle {
                if clear {
                    if let tintColor {
                        content.glassEffect(
                            .clear.tint(tintColor).interactive(),
                            in: Circle()
                        )
                    } else {
                        content.glassEffect(
                            .clear.interactive(),
                            in: Circle()
                        )
                    }
                } else if let tintColor {
                    content.glassEffect(
                        .regular.tint(tintColor).interactive(),
                        in: Circle()
                    )
                } else {
                    content.glassEffect(
                        .regular.interactive(),
                        in: Circle()
                    )
                }
            } else if rectangle {
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
                } else if let tintColor {
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
            } else if clear {
                if let tintColor {
                    content.glassEffect(.clear.tint(tintColor).interactive())
                } else {
                    content.glassEffect(.clear.interactive())
                }
            } else if let tintColor {
                content.glassEffect(.regular.tint(tintColor).interactive())
            } else {
                content.glassEffect(.regular.interactive())
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func fallbackGlass(content: Content) -> some View {
        if circle {
            fallbackGlassShape(content: content, shape: Circle())
        } else if rectangle {
            fallbackGlassShape(content: content, shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            fallbackGlassShape(content: content, shape: Capsule())
        }
    }

    private func fallbackGlassShape<S: Shape>(content: Content, shape: S) -> some View {
        let fallbackBaseFill: Color = {
            #if os(iOS)
            return Color(UIColor.secondarySystemBackground).opacity(clear ? 0.7 : 1.0)
            #else
            return Color.gray.opacity(clear ? 0.12 : 0.18)
            #endif
        }()

        let fallbackOverlayColor = tintColor ?? .clear

        return content
            .background {
                if #available(iOS 15.0, watchOS 10.0, *) {
                    shape.fill(.ultraThinMaterial)
                } else {
                    shape.fill(fallbackBaseFill)
                }
            }
            // Overlays must not intercept taps — otherwise buttons/menus underneath never receive touches.
            .overlay(shape.fill(fallbackOverlayColor).allowsHitTesting(false))
            .overlay(shape.stroke(Color.primary.opacity(0.12), lineWidth: 1).allowsHitTesting(false))
    }

    private var tintColor: Color? {
        if let customTint {
            return customTint.opacity(useColor ?? 0.35)
        }
        return useColor.map { settings.accentColor.color.opacity($0) }
    }
}

#if os(iOS)
struct SmallMediumSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

struct FullScreenSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
#endif

extension View {
    func conditionalGlassEffect(
        clear: Bool = false,
        rectangle: Bool = false,
        circle: Bool = false,
        useColor: Double? = nil,
        customTint: Color? = nil
    ) -> some View {
        modifier(ConditionalGlassEffect(clear: clear, rectangle: rectangle, circle: circle, useColor: useColor, customTint: customTint))
    }

    #if os(iOS)
    func smallMediumSheetPresentation() -> some View {
        modifier(SmallMediumSheetPresentationModifier())
    }

    func fullScreenSheetPresentation() -> some View {
        modifier(FullScreenSheetPresentationModifier())
    }
    #endif
}
