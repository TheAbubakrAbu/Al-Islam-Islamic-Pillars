import SwiftUI

struct DismissKeyboardOnScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            #if !os(watchOS)
            if #available(iOS 16.0, *) {
                content
                    .scrollDismissesKeyboard(.immediately)
            } else {
                content
                    .gesture(
                        DragGesture().onChanged { _ in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    )
            }
            #else
            content
            #endif
        }
    }
}
