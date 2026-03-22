import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String

    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    @Environment(\.layoutDirection) private var layoutDirection
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $searchText.animation(.easeInOut))
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit {
                    onSearchButtonClicked?()
                    isFocused = false
                    dismissKeyboard()
                }

            if isFocused || !searchText.isEmpty {
                HStack(spacing: 4) {
                    if !searchText.isEmpty {
                        Button {
                            withAnimation(.easeInOut) {
                                searchText = ""
                            }
                            isFocused = false
                            dismissKeyboard()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .padding(.horizontal, 8)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }

                    if isFocused {
                        Button {
                            isFocused = false
                            dismissKeyboard()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .conditionalGlassEffect()
        .onChange(of: isFocused) { focused in
            onFocusChanged?(focused)
        }
    }

    private func dismissKeyboard() {
        #if !os(watchOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    SearchBar(searchText: .constant(""))
}
