import SwiftUI

extension View {
    func applyConditionalListStyle(defaultView: Bool) -> some View {
        modifier(ConditionalListStyle(defaultView: defaultView))
    }

    @ViewBuilder
    func compactListSectionSpacing() -> some View {
        #if os(watchOS)
        self
        #else
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *) {
            self.listSectionSpacing(.compact)
        } else {
            self
        }
        #endif
    }

    func endEditing() {
        #if !os(watchOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func dismissKeyboardOnScroll() -> some View {
        modifier(DismissKeyboardOnScrollModifier())
    }

    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }
}

struct ConditionalListStyle: ViewModifier {
    @EnvironmentObject private var settings: Settings
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.customColorScheme) private var customColorScheme

    let defaultView: Bool

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    func body(content: Content) -> some View {
        Group {
            #if !os(watchOS)
            styledContent(content)
                .navigationBarTitleDisplayMode(.inline)
            #else
            content
            #endif
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }

    @ViewBuilder
    private func styledContent(_ content: Content) -> some View {
        if defaultView {
            content
        } else {
            content
                .listStyle(.plain)
                .background(currentColorScheme == .dark ? Color.black : Color.white)
        }
    }
}
