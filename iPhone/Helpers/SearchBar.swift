import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        let onSearchButtonClicked: (() -> Void)?
        let onFocusChanged: ((Bool) -> Void)?

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
            onFocusChanged?(false)
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(
            text: $text,
            onSearchButtonClicked: onSearchButtonClicked,
            onFocusChanged: onFocusChanged
        )
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search"
        searchBar.autocorrectionType = .no
        
        searchBar.backgroundImage = UIImage()
        
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        DispatchQueue.main.async {
            self.text = searchBar.text ?? ""
        }
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
        }
        .padding()
        .conditionalGlassEffect()
        .onChange(of: isFocused) { focused in
            onFocusChanged?(focused)
        }
    }
}

#Preview {
    SearchBar(text: .constant("Search"))
}
