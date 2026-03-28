import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSearchButtonClicked: onSearchButtonClicked,
            onFocusChanged: onFocusChanged
        )
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search"
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal

        configure(searchTextField: searchBar.searchTextField, coordinator: context.coordinator)
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        uiView.searchTextField.rightViewMode = text.isEmpty ? .never : .always
        context.coordinator.onSearchButtonClicked = onSearchButtonClicked
        context.coordinator.onFocusChanged = onFocusChanged
    }

    private func configure(searchTextField: UITextField, coordinator: Coordinator) {
        searchTextField.backgroundColor = .clear
        searchTextField.layer.cornerRadius = 12
        searchTextField.layer.masksToBounds = true
        searchTextField.font = .systemFont(ofSize: 16)
        searchTextField.clearButtonMode = .never
        searchTextField.rightView = ClearButtonContainer.make(for: coordinator)
        searchTextField.rightViewMode = .never

        let heightConstraint = searchTextField.heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = .required
        heightConstraint.isActive = true
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        var onSearchButtonClicked: (() -> Void)?
        var onFocusChanged: ((Bool) -> Void)?

        init(
            text: Binding<String>,
            onSearchButtonClicked: (() -> Void)?,
            onFocusChanged: ((Bool) -> Void)?
        ) {
            _text = text
            self.onSearchButtonClicked = onSearchButtonClicked
            self.onFocusChanged = onFocusChanged
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
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

            text = ""
            onFocusChanged?(false)
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            text = searchBar.text ?? ""
            onSearchButtonClicked?()
        }

        @objc func clearSearchText(_ sender: UIButton) {
            guard let textField = resolvedTextField(from: sender) else {
                text = ""
                return
            }

            textField.text = ""
            text = ""
            textField.sendActions(for: .editingChanged)
        }

        private func resolvedTextField(from sender: UIButton) -> UITextField? {
            sender.superview?.superview as? UITextField ?? sender.superview as? UITextField
        }
    }
}

private enum ClearButtonContainer {
    static func make(for coordinator: SearchBar.Coordinator) -> UIView {
        let leadingInset: CGFloat = 4
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 24 + leadingInset, height: 20))

        let button = UIButton(type: .system)
        button.frame = CGRect(x: leadingInset, y: 0, width: 20, height: 20)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(coordinator, action: #selector(SearchBar.Coordinator.clearSearchText(_:)), for: .touchUpInside)

        container.addSubview(button)
        return container
    }
}

#Preview {
    SearchBar(text: .constant(""))
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
        _searchText = searchText
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    init(
        text: Binding<String>,
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        _searchText = text
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.primary)

            searchField

            if !searchText.isEmpty {
                clearButton
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

    private var searchField: some View {
        TextField("Search", text: $searchText.animation(.easeInOut))
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($isFocused)
            .onSubmit {
                onSearchButtonClicked?()
                isFocused = false
            }
    }

    private var clearButton: some View {
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
