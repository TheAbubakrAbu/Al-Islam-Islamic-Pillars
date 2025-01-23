import SwiftUI

extension View {
    func applyConditionalListStyle(defaultView: Bool) -> some View {
        self.modifier(ConditionalListStyle(defaultView: defaultView))
    }
    
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            if defaultView {
                content
                    .accentColor(settings.accentColor.color)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                content
                    .listStyle(PlainListStyle())
                    .accentColor(settings.accentColor.color)
                    .background(currentColorScheme == .dark ? Color.black : Color.white)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
