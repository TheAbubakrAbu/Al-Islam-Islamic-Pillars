import SwiftUI
#if os(iOS)
import UIKit
#endif

struct GlassSearchBar: View {
    @Binding var searchText: String

    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    @FocusState private var isFocused: Bool

    init(
        searchText: Binding<String>,
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        self._searchText = searchText
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    init(
        text: Binding<String>,
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        self._searchText = text
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.primary)

            TextField("Search", text: $searchText.animation(.easeInOut))
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit {
                    onSearchButtonClicked?()
                    isFocused = false
                }

            if !searchText.isEmpty {
                Button {
                    withAnimation {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .clipShape(Rectangle())
            }

            if isFocused {
                keyboardDismissButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding()
        .conditionalGlassEffect(clear: false)
        .onChange(of: isFocused) { focused in
            onFocusChanged?(focused)
        }
    }

    private var keyboardDismissButton: some View {
        Button {
            dismissKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(.tint.opacity(0.14))
                )
                .overlay(
                    Circle()
                        .stroke(.tint.opacity(0.28), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .clipShape(Rectangle())
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
        isFocused = false
        onFocusChanged?(false)
    }
}

struct SearchBar: View {
    @Binding var text: String

    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.primary)

            TextField("Search", text: $text.animation(.easeInOut))
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit {
                    onSearchButtonClicked?()
                    isFocused = false
                }

            if !text.isEmpty {
                Button {
                    withAnimation {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .clipShape(Rectangle())
            }

            if isFocused {
                keyboardDismissButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding()
        .conditionalGlassEffect(clear: false)
        .onChange(of: isFocused) { focused in
            onFocusChanged?(focused)
        }
    }

    private var keyboardDismissButton: some View {
        Button {
            dismissKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .clipShape(Rectangle())
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
        isFocused = false
        onFocusChanged?(false)
    }
}

#Preview {
    SearchBar(text: .constant(""))
}
