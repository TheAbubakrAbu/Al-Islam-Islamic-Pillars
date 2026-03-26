import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SearchBar: UIViewRepresentable {
    @Binding var searchText: String

    var placeholder: String = "Search"
    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    init(
        searchText: Binding<String>,
        placeholder: String = "Search",
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        self._searchText = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var searchText: String
        var onSearchButtonClicked: (() -> Void)?
        var onFocusChanged: ((Bool) -> Void)?

        init(
            searchText: Binding<String>,
            onSearchButtonClicked: (() -> Void)? = nil,
            onFocusChanged: ((Bool) -> Void)? = nil
        ) {
            self._searchText = searchText
            self.onSearchButtonClicked = onSearchButtonClicked
            self.onFocusChanged = onFocusChanged
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.searchText = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = true
            onFocusChanged?(true)
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            onFocusChanged?(false)
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            searchBar.text = ""
            searchBar.resignFirstResponder()

            searchText = ""
            onFocusChanged?(false)
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            searchText = searchBar.text ?? ""
            onSearchButtonClicked?()
            onFocusChanged?(false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            searchText: $searchText,
            onSearchButtonClicked: onSearchButtonClicked,
            onFocusChanged: onFocusChanged
        )
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal

        let textField = searchBar.searchTextField
        textField.backgroundColor = .clear
        textField.layer.cornerRadius = 12
        textField.layer.masksToBounds = true
        textField.font = .systemFont(ofSize: 17)
        textField.clearButtonMode = .whileEditing

        let heightConstraint = textField.heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = .required
        heightConstraint.isActive = true

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        if uiView.text != searchText {
            uiView.text = searchText
        }

        uiView.placeholder = placeholder

        context.coordinator.onSearchButtonClicked = onSearchButtonClicked
        context.coordinator.onFocusChanged = onFocusChanged
    }
}

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
        .conditionalGlassEffect()
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

#Preview {
    SearchBar(text: .constant(""))
}
