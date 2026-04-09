import SwiftUI

struct SurahContextMenu: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    let surahID: Int
    let surahName: String

    let favoriteSurahs: Set<Int>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var lastListened: Bool?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surahID)
    }

    var body: some View {
        Button(role: isFavorite ? .destructive : .cancel) {
            settings.hapticFeedback()
            settings.toggleSurahFavorite(surah: surahID)
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button {
            settings.hapticFeedback()

            if let surah = quranData.surah(surahID) {
                if let randomAyah = surah.ayahs.randomElement() {
                    quranPlayer.playAyah(
                        surahNumber: surahID,
                        ayahNumber: randomAyah.id,
                        continueRecitation: true
                    )
                }
            }
        } label: {
            Label("Play Random Ayah", systemImage: "shuffle.circle")
        }

        if lastListened == nil {
            Button {
                settings.hapticFeedback()

                quranPlayer.playSurah(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Play Surah", systemImage: "play.fill")
            }
        }

        Button {
            settings.hapticFeedback()

            withAnimation {
                searchText = ""
                scrollToSurahID = surahID
                self.endEditing()
            }
        } label: {
            Text("Scroll To Surah")
            Image(systemName: "arrow.down.circle")
        }
    }
}

#if os(iOS)
private enum TafsirAuthor: String, CaseIterable, Identifiable {
    case ibnKathir = "Ibn Kathir"
    case maarifUlQuran = "Maarif Ul Quran"
    case tazkirulQuran = "Tazkirul Quran"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .ibnKathir:
            return "Ibn Kathir"
        case .maarifUlQuran:
            return "Maarif"
        case .tazkirulQuran:
            return "Tazkirul"
        }
    }

    func matches(_ author: String) -> Bool {
        normalized(author) == normalized(rawValue)
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct AyahTafsirResponse: Decodable {
    let surahName: String
    let surahNo: Int
    let ayahNo: Int
    let tafsirs: [AyahTafsirEntry]
}

private struct AyahTafsirEntry: Decodable, Identifiable {
    let author: String
    let groupVerse: String?
    let content: String

    var id: String { author }
}

@MainActor
private final class AyahTafsirViewModel: ObservableObject {
    @Published private(set) var tafsirs: [AyahTafsirEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var loadedKey: String?

    func load(surah: Int, ayah: Int) async {
        let key = "\(surah)-\(ayah)"
        if loadedKey == key, !tafsirs.isEmpty { return }

        isLoading = true
        errorMessage = nil

        do {
            let endpoint = "https://quranapi.pages.dev/api/tafsir/\(surah)_\(ayah).json"
            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AyahTafsirResponse.self, from: data)
            tafsirs = decoded.tafsirs
            loadedKey = key
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct AyahTafsirSheet: View {
    let surahName: String
    let surahNumber: Int
    let ayahNumber: Int

    @StateObject private var viewModel: AyahTafsirViewModel
    @AppStorage("quran.tafsir.author") private var selectedAuthorRawValue = TafsirAuthor.ibnKathir.rawValue

    init(surahName: String, surahNumber: Int, ayahNumber: Int) {
        self.surahName = surahName
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _viewModel = StateObject(wrappedValue: AyahTafsirViewModel())
    }

    private var selectedAuthor: TafsirAuthor {
        get { TafsirAuthor(rawValue: selectedAuthorRawValue) ?? .ibnKathir }
        nonmutating set { selectedAuthorRawValue = newValue.rawValue }
    }

    private var selectedAuthorBinding: Binding<TafsirAuthor> {
        Binding(
            get: { selectedAuthor },
            set: { selectedAuthor = $0 }
        )
    }

    private var selectedTafsirText: String? {
        viewModel.tafsirs.first(where: { selectedAuthor.matches($0.author) })?.content ?? viewModel.tafsirs.first?.content
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.tafsirs.isEmpty {
                    tafsirLoadingView
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            noticeCard

                            Picker("Tafsir", selection: selectedAuthorBinding.animation(.easeInOut)) {
                                ForEach(TafsirAuthor.allCases) { author in
                                    Text(author.shortTitle).tag(author)
                                }
                            }
                            .pickerStyle(.segmented)
                            .animation(.easeInOut, value: selectedAuthor)

                            if let tafsirText = selectedTafsirText {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(selectedAuthor.rawValue)
                                        .font(.headline)

                                    tafsirContentView(for: tafsirText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(selectedAuthor.rawValue)
                                .textSelection(.enabled)
                            } else if let errorMessage = viewModel.errorMessage {
                                tafsirPlaceholder(
                                    title: "Couldn't Load Tafsir",
                                    systemImage: "wifi.exclamationmark",
                                    message: errorMessage
                                )
                            } else {
                                tafsirPlaceholder(
                                    title: "No Tafsir Found",
                                    systemImage: "text.book.closed",
                                    message: "No tafsir was returned for this ayah."
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("\(surahName) \(surahNumber):\(ayahNumber)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: "\(surahNumber)-\(ayahNumber)") {
            await viewModel.load(surah: surahNumber, ayah: ayahNumber)
        }
        .modifier(TafsirSheetPresentationModifier())
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loaded from the Internet", systemImage: "icloud.and.arrow.down")
                .font(.subheadline.weight(.semibold))

            Text("Tafsir is fetched online for this ayah only. The app loads all 3 available tafsirs together, then you can switch between them with the picker. Full tafsir downloads are not available.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    @ViewBuilder
    private func tafsirContentView(for content: String) -> some View {
        TafsirMarkdownView(markdown: content)
    }

    private var tafsirLoadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                noticeCard

                ProgressView("Loading tafsir...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 32)
                    .overlay {
                        HStack(spacing: 8) {
                            Capsule().fill(Color.secondary.opacity(0.18))
                            Capsule().fill(Color.secondary.opacity(0.12))
                            Capsule().fill(Color.secondary.opacity(0.1))
                        }
                        .padding(4)
                    }

                ForEach(0..<4, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.16))
                            .frame(width: index == 0 ? 180 : 240, height: index == 0 ? 24 : 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.09))
                            .frame(width: index.isMultiple(of: 2) ? 260 : 220, height: 16)
                    }
                    .redacted(reason: .placeholder)
                }
            }
            .padding()
        }
    }

    private func tafsirPlaceholder(title: String, systemImage: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct TafsirMarkdownView: View {
    let markdown: String

    private var blocks: [TafsirMarkdownBlock] {
        normalizedMarkdown
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(TafsirMarkdownBlock.init(raw:))
    }

    private var normalizedMarkdown: String {
        markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(
                of: #"(?m)^\\-\s+"#,
                with: "- ",
                options: .regularExpression
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block.kind {
                case .heading:
                    Text(block.displayText)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .body:
                    if let attributed = block.attributedText {
                        Text(attributed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .lineSpacing(5)
                    } else {
                        Text(block.displayText)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .lineSpacing(5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }
}

private struct TafsirMarkdownBlock {
    enum Kind {
        case heading
        case body
    }

    let kind: Kind
    let rawText: String

    init(raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("## ") {
            kind = .heading
            rawText = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if trimmed.hasPrefix("# ") {
            kind = .heading
            rawText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            kind = .body
            rawText = trimmed
        }
    }

    var displayText: String {
        rawText.replacingOccurrences(of: #"\\-"#, with: "-", options: .regularExpression)
    }

    var attributedText: AttributedString? {
        guard kind == .body else { return nil }
        guard var attributed = try? AttributedString(markdown: displayText) else { return nil }
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.code) {
                attributed[run.range].inlinePresentationIntent = nil
            }
        }
        return attributed
    }
}

private struct TafsirSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
#endif

struct AyahContextMenuModifier: ViewModifier {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    let surah: Int
    let ayah: Int
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    
    let lastRead: Bool
    
    @State var showAyahSheet = false
    
    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showRespectAlert = false
    @State private var showCustomRangeSheet = false
    @State private var showTafsirSheet = false

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }
    
    func containsProfanity(_ text: String) -> Bool {
        let t = text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current).lowercased()
        return profanityFilter.contains { !$0.isEmpty && t.contains($0) }
    }
    
    private func isNoteAllowed(_ text: String) -> Bool {
        !containsProfanity(text)
    }
    
    private var bookmarkIndex: Int? {
        settings.bookmarkedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }
    
    private var bookmark: BookmarkedAyah? {
        bookmarkIndex.flatMap { settings.bookmarkedAyahs[$0] }
    }
    
    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    private var currentNote: String {
        (bookmark?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func setNote(_ text: String?) {
        withAnimation {
            let normalized = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let idx = bookmarkIndex {
                var b = settings.bookmarkedAyahs[idx]
                b.note = (normalized?.isEmpty == true) ? nil : normalized
                settings.bookmarkedAyahs[idx] = b
            } else {
                let new = BookmarkedAyah(surah: surah, ayah: ayah, note: (normalized?.isEmpty == true ? nil : normalized))
                settings.bookmarkedAyahs.append(new)
            }
        }
    }

    private func removeNote() {
        guard let idx = bookmarkIndex else { return }
        withAnimation {
            var b = settings.bookmarkedAyahs[idx]
            b.note = nil
            settings.bookmarkedAyahs[idx] = b
        }
    }
    
    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard() {
        if isBookmarkedHere, !currentNote.isEmpty {
            confirmRemoveNote = true
        } else {
            settings.hapticFeedback()
            settings.toggleBookmark(surah: surah, ayah: ayah)
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        let surahObj = quranData.quran.first { $0.id == surah }
        
        #if os(iOS)
        content
            .contextMenu {
                if lastRead {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                        }
                    } label: { Label("Remove", systemImage: "trash") }
                    
                    Divider()
                }
                
                Button(role: isBookmarked ? .destructive : .cancel) {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                } label: {
                    Label(
                        isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }
                
                Button {
                    settings.hapticFeedback()
                    if !isBookmarked {
                        settings.toggleBookmark(surah: surah, ayah: ayah)
                    }
                    draftNote = currentNote
                    showingNoteSheet = true
                } label: {
                    Label(currentNote.isEmpty ? "Add Note" : "Edit Note", systemImage: "note.text")
                }

                if !currentNote.isEmpty {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        removeNote()
                    } label: {
                        Label("Remove Note", systemImage: "trash")
                    }
                }

                if settings.isHafsDisplay {
                    Button {
                        settings.hapticFeedback()
                        showTafsirSheet = true
                    } label: {
                        Label("See Tafsir", systemImage: "text.book.closed")
                    }
                }
                
                if settings.isHafsDisplay {
                    Menu {
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(surahNumber: surah, ayahNumber: ayah)
                        } label: {
                            Label("Play This Ayah", systemImage: "play.circle")
                        }
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(
                                surahNumber: surah,
                                ayahNumber: ayah,
                                continueRecitation: true
                            )
                        } label: {
                            Label("Play From Ayah", systemImage: "play.circle.fill")
                        }
                        Button {
                            settings.hapticFeedback()
                            showCustomRangeSheet = true
                        } label: {
                            Label("Play Custom Range", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Label("Play Ayah", systemImage: "play.circle")
                    }
                }
                
                Button {
                    settings.hapticFeedback()
                    ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah, ayahNumber: ayah, settings: settings, quranData: quranData)
                } label: {
                    Label("Copy Ayah", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    showAyahSheet = true
                } label: {
                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                }

                Divider()

                if let surah = surahObj {
                    SurahContextMenu(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        favoriteSurahs: favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
            }
            .sheet(isPresented: $showAyahSheet) {
                ShareAyahSheet(
                    surahNumber: surah,
                    ayahNumber: ayah
                )
                .smallMediumSheetPresentation()
            }
            .sheet(isPresented: $showTafsirSheet) {
                if let surahObj = surahObj {
                    if #available(iOS 16.0, *) {
                        AyahTafsirSheet(
                            surahName: surahObj.nameTransliteration,
                            surahNumber: surahObj.id,
                            ayahNumber: ayah
                        )
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    } else {
                        AyahTafsirSheet(
                            surahName: surahObj.nameTransliteration,
                            surahNumber: surahObj.id,
                            ayahNumber: ayah
                        )
                    }
                }
            }
            .sheet(isPresented: $showCustomRangeSheet) {
                if let surahObj = surahObj {
                    PlayCustomRangeSheet(
                        surah: surahObj,
                        initialStartAyah: ayah,
                        initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                            startAyah: ayah,
                            surah: surahObj,
                            displayQiraah: settings.displayQiraahForArabic
                        ),
                        onPlay: { start, end, repAyah, repSec in
                            quranPlayer.playCustomRange(
                                surahNumber: surahObj.id,
                                surahName: surahObj.nameTransliteration,
                                startAyah: start,
                                endAyah: end,
                                repeatPerAyah: repAyah,
                                repeatSection: repSec
                            )
                        },
                        onCancel: { showCustomRangeSheet = false }
                    )
                    .environmentObject(settings)
                    .fullScreenSheetPresentation()
                }
            }
            .sheet(isPresented: $showingNoteSheet) {
                if let surah = surahObj {
                    NoteEditorSheet(
                        title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah)",
                        text: $draftNote,
                        onAttemptSave: { text in
                            if isNoteAllowed(text) {
                                setNote(text)
                                return true
                            } else {
                                showRespectAlert = true
                                return false
                            }
                        },
                        onCancel: {},
                        onSave: { setNote(draftNote) }
                    )
                }
            }
            .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
                Button("OK") { }
            } message: {
                Text("Please keep notes Islamic and respectful.")
            }
            .confirmationDialog("Remove bookmark and delete note?", isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: surah, ayah: ayah)
                }
                Button("Cancel") {}
            } message: {
                Text("This ayah has a note. Unbookmarking will delete the note.")
            }
        #else
        content
        #endif
    }
}

extension View {
    func ayahContextMenuModifier(
        surah: Int,
        ayah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>,
        lastRead: Bool = false
    ) -> some View {
        self.modifier(AyahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID,
            lastRead: lastRead
        ))
    }
}

struct LeftSwipeActions: ViewModifier {
    @EnvironmentObject private var settings: Settings

    let surah: Int
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>?
    let bookmarkedSurah: Int?
    let bookmarkedAyah: Int?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surah)
    }

    private var isBookmarked: Bool {
        if let bookmarkedAyahs, let s = bookmarkedSurah, let a = bookmarkedAyah {
            return bookmarkedAyahs.contains("\(s)-\(a)")
        }
        return false
    }
    
    private var bookmarkIndex: Int? {
        let surah = bookmarkedSurah ?? 1
        let ayah = bookmarkedAyah ?? 1
        
        return settings.bookmarkedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }
    
    private var bookmark: BookmarkedAyah? {
        bookmarkIndex.flatMap { settings.bookmarkedAyahs[$0] }
    }
    
    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    
    private var currentNote: String {
        (bookmark?.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard(_ surah: Int, _ ayah: Int) {
        if isBookmarkedHere, !currentNote.isEmpty {
            confirmRemoveNote = true
        } else {
            settings.hapticFeedback()
            settings.toggleBookmark(surah: surah, ayah: ayah)
        }
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .leading) {
                Button {
                    settings.hapticFeedback()
                    settings.toggleSurahFavorite(surah: surah)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(settings.accentColor.color)

                if let s = bookmarkedSurah, let a = bookmarkedAyah {
                    Button {
                        settings.hapticFeedback()
                        toggleBookmarkWithNoteGuard(s, a)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .tint(settings.accentColor.color)
                }
            }
            #endif
            .confirmationDialog("Remove bookmark and delete note?", isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
                }
                Button("Cancel") {}
            } message: {
                Text("This ayah has a note. Unbookmarking will delete the note.")
            }
    }
}

public extension View {
    func leftSwipeActions(
        surah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>? = nil,
        bookmarkedSurah: Int? = nil,
        bookmarkedAyah: Int? = nil
    ) -> some View {
        modifier(LeftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: bookmarkedSurah,
            bookmarkedAyah: bookmarkedAyah
        ))
    }
}

struct RightSwipeActions: ViewModifier {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let surahID: Int
    let surahName: String
    let ayahID: Int?
    let certainReciter: Bool

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private func endEditing() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .trailing) {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: surahID,
                        surahName: surahName,
                        certainReciter: certainReciter
                    )
                } label: {
                    Image(systemName: "play.fill")
                }
                .tint(settings.accentColor.color)

                if let ayah = ayahID {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surahID, ayahNumber: ayah)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        searchText = ""
                        scrollToSurahID = surahID
                        endEditing()
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            #endif
    }
}

public extension View {
    func rightSwipeActions(
        surahID: Int,
        surahName: String,
        ayahID: Int? = nil,
        certainReciter: Bool = false,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>
    ) -> some View {
        modifier(RightSwipeActions(
            surahID: surahID,
            surahName: surahName,
            ayahID: ayahID,
            certainReciter: certainReciter,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID
        ))
    }
}

#if os(iOS)
import SwiftUI

struct NoteEditorSheet: View {
    let title: String
    @Binding var text: String
    var onAttemptSave: (String) -> Bool
    var onCancel: () -> Void
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    private let maxChars: Int = 300

    private var characterCount: Int { text.count }
    private var remaining: Int { max(0, maxChars - characterCount) }
    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                let cardFill   = Color(UIColor.secondarySystemBackground)
                let cardStroke = Color.primary.opacity(0.12)

                TextEditor(text: $text)
                    .padding(12)
                    .background(Color.clear)
                    .frame(minHeight: 220)
                    .modifier(HideEditorScrollBackground())
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .onChange(of: text) { newValue in
                        if newValue.count > maxChars {
                            text = String(newValue.prefix(maxChars))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(cardStroke, lineWidth: 1)
                    )

                Text("\(remaining) characters left")
                    .font(.footnote.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Character limit")
                    .accessibilityValue("\(maxChars) limit, \(remaining) remaining")

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.sparkles")
                            .imageScale(.large)
                        Text("A respectful reminder")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)

                    Text("Your note will appear next to the Quran, the Words of Allah ﷻ. Please keep it dignified and beneficial.")
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Avoid profanity or insults", systemImage: "checkmark.seal")
                        Label("No mockery, slurs, or indecency", systemImage: "checkmark.seal")
                        Label("Keep remarks relevant and respectful", systemImage: "checkmark.seal")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)

                    Text("May Allah ﷻ reward you, protect you, and keep us all firm upon the truth.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .accessibilityElement(children: .combine)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(cardStroke, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onAttemptSave(text) {
                            dismiss()
                        }
                    }
                    .disabled(isEmpty)
                }
            }
        }
    }
}

private struct HideEditorScrollBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
        }
    }
}

private struct SurahContextMenuPreviewContent: View {
    @State private var searchText = ""
    @State private var scrollToSurahID = 0

    var body: some View {
        Menu("Open Surah Actions") {
            SurahContextMenu(
                surahID: AlIslamPreviewData.surah.id,
                surahName: AlIslamPreviewData.surah.nameTransliteration,
                favoriteSurahs: [],
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        .padding()
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SurahContextMenuPreviewContent()
    }
}
#endif
