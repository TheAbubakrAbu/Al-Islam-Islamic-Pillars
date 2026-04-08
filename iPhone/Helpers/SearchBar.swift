#if os(iOS)
import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    init(
        text: Binding<String>,
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        _text = text
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                SearchBarUIKit(
                    text: $text,
                    onSearchButtonClicked: onSearchButtonClicked,
                    onFocusChanged: onFocusChanged
                )
            } else {
                SearchBarUIKit(
                    text: $text,
                    onSearchButtonClicked: onSearchButtonClicked,
                    onFocusChanged: onFocusChanged
                )
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)
                }
                .padding(.horizontal, 5)
            }
        }
    }
}

struct SearchBarUIKit: UIViewRepresentable {
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

        uiView.searchTextField.rightViewMode = .always
        ClearButtonContainer.updateVisibility(
            in: uiView.searchTextField.rightView,
            isVisible: !text.isEmpty
        )
        context.coordinator.onSearchButtonClicked = onSearchButtonClicked
        context.coordinator.onFocusChanged = onFocusChanged
    }

    private func configure(searchTextField: UITextField, coordinator: Coordinator) {
        searchTextField.backgroundColor = .clear
        searchTextField.layer.cornerRadius = 24
        searchTextField.layer.masksToBounds = true
        searchTextField.font = .systemFont(ofSize: 16)
        searchTextField.clearButtonMode = .never
        searchTextField.rightView = ClearButtonContainer.make(for: coordinator)
        searchTextField.rightViewMode = .always
        ClearButtonContainer.updateVisibility(in: searchTextField.rightView, isVisible: false)

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
    
    private enum ClearButtonContainer {
        static func make(for coordinator: SearchBarUIKit.Coordinator) -> UIView {
            let leadingInset: CGFloat = 4
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24 + leadingInset, height: 20))

            let button = UIButton(type: .system)
            button.frame = CGRect(x: leadingInset, y: 0, width: 20, height: 20)
            button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            button.tintColor = .secondaryLabel
            button.addTarget(coordinator, action: #selector(SearchBarUIKit.Coordinator.clearSearchText(_:)), for: .touchUpInside)
            button.tag = 999

            container.addSubview(button)
            return container
        }

        static func updateVisibility(in rightView: UIView?, isVisible: Bool) {
            guard let button = rightView?.viewWithTag(999) as? UIButton else { return }
            button.isHidden = !isVisible
            button.isUserInteractionEnabled = isVisible
        }
    }
}

#Preview {
    SearchBar(text: .constant(""))
}
#endif
