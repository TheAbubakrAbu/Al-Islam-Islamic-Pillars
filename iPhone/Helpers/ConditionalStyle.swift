import SwiftUI

extension View {
    func applyConditionalListStyle(defaultView: Bool) -> some View {
        self.modifier(ConditionalListStyle(defaultView: defaultView))
    }
    
    func endEditing() {
        #if !os(watchOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    func dismissKeyboardOnScroll() -> some View {
        self.modifier(DismissKeyboardOnScrollModifier())
    }
}

struct ConditionalListStyle: ViewModifier {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.colorScheme) var systemColorScheme
    @Environment(\.customColorScheme) var customColorScheme
    
    var defaultView: Bool
    
    var currentColorScheme: ColorScheme {
        if let colorScheme = settings.colorScheme {
            return colorScheme
        } else {
            return systemColorScheme
        }
    }

    func body(content: Content) -> some View {
        Group {
            #if !os(watchOS)
            Group {
                if defaultView {
                    content
                        .apply {
                            if #available(iOS 17.0, *) {
                                $0.listSectionSpacing(.compact)
                            }
                        }
                } else {
                    content
                        .listStyle(.plain)
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            #else
            content
            #endif
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }
}

extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
