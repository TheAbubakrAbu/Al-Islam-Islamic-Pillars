import SwiftUI
import Foundation

struct AyahRow: View, Equatable {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var ayahBeginnerMode = false
    
    #if os(iOS)
    @State private var showingAyahSheet = false
    @State private var showTafsirSheet = false
    
    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showCustomRangeSheet = false
    #endif
    #if os(watchOS)
    @State private var showWatchPlaybackDialog = false
    #endif
    
    let surah: Surah
    let ayah: Ayah
    /// When non-nil (e.g. comparison mode), use this qiraah for Arabic instead of global setting.
    var comparisonQiraahOverride: String? = nil

    @Binding var scrollDown: Int?
    @Binding var searchText: String
    
    @State private var showRespectAlert = false

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.surah == rhs.surah &&
        lhs.ayah == rhs.ayah &&
        lhs.comparisonQiraahOverride == rhs.comparisonQiraahOverride &&
        lhs.scrollDown == rhs.scrollDown &&
        lhs.searchText == rhs.searchText
    }

    private static let arabicDisplayCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 5000
        return cache
    }()
    
    func containsProfanity(_ text: String) -> Bool {
        let t = text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current).lowercased()
        return profanityFilter.contains { !$0.isEmpty && t.contains($0) }
    }
    
    private func isNoteAllowed(_ text: String) -> Bool {
        !containsProfanity(text)
    }
    
    private var bookmarkIndex: Int? {
        settings.bookmarkedAyahs.firstIndex { $0.surah == surah.id && $0.ayah == ayah.id }
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
                let new = BookmarkedAyah(surah: surah.id, ayah: ayah.id,
                                         note: (normalized?.isEmpty == true ? nil : normalized))
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
    
    private func spacedArabic(_ text: String) -> String {
        (settings.beginnerMode || ayahBeginnerMode) ? text.map { "\($0) " }.joined() : text
    }

    private func arabicDisplayText() -> String {
        // Tajweed needs full diacritics; when colors are on, show unclean Arabic even if "clean" is enabled elsewhere.
        let clean = settings.cleanArabicText && !shouldShowTajweedColors
        let qiraahKey = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "Hafs")
        let key = "\(surah.id):\(ayah.id)|\(clean ? 1 : 0)|\((settings.beginnerMode || ayahBeginnerMode) ? 1 : 0)|\(qiraahKey)"

        if let cached = Self.arabicDisplayCache.object(forKey: key as NSString) {
            return cached as String
        }

        let baseText = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: comparisonQiraahOverride)
        let spaced = spacedArabic(baseText)
        Self.arabicDisplayCache.setObject(spaced as NSString, forKey: key as NSString)
        return spaced
    }

    private func queryForInlineHighlight(_ query: String) -> String {
        let stripped = query
            .replacingOccurrences(of: "&&", with: " ")
            .replacingOccurrences(of: "||", with: " ")
            .replacingOccurrences(of: "&", with: " ")
            .replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            .replacingOccurrences(of: "#", with: " ")
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowTajweedColors: Bool {
        let usingHafs: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }

        return settings.showTajweedColors
            && settings.showArabicText
            && usingHafs
            && !settings.cleanArabicText
            && !(settings.beginnerMode || ayahBeginnerMode)
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: comparisonQiraahOverride)
        return TajweedStore.shared.attributedText(surah: surah.id, ayah: ayah.id, text: text)
    }

    private var tajweedAnimationKey: String {
        let categorySignature = TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined()
        let qiraahKey = comparisonQiraahOverride ?? settings.displayQiraah
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            (settings.beginnerMode || ayahBeginnerMode) ? "1" : "0",
            qiraahKey,
            categorySignature
        ].joined(separator: "|")
    }

    private var ayahHighlightBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return -11
        }
        return -2
    }

    var body: some View {
        let isBookmarked = isBookmarkedHere
        let hafsOnly: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }
        let normalizedQuery = settings.cleanSearch(searchText, whitespace: true).removingArabicDiacriticsAndSigns
        let arabicSourceForMatch = settings.cleanSearch(
            ayah.textArabic(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
            whitespace: false
        ).removingArabicDiacriticsAndSigns
        let translitSourceForMatch = settings.cleanSearch(ayah.textTransliteration, whitespace: false).removingArabicDiacriticsAndSigns
        let saheehSourceForMatch = settings.cleanSearch(ayah.textEnglishSaheeh, whitespace: false).removingArabicDiacriticsAndSigns
        let mustafaSourceForMatch = settings.cleanSearch(ayah.textEnglishMustafa, whitespace: false).removingArabicDiacriticsAndSigns

        let mArabic = !normalizedQuery.isEmpty && arabicSourceForMatch.contains(normalizedQuery)
        let mTranslit = !normalizedQuery.isEmpty && translitSourceForMatch.contains(normalizedQuery)
        let mSaheeh = !normalizedQuery.isEmpty && saheehSourceForMatch.contains(normalizedQuery)
        let mMustafa = !normalizedQuery.isEmpty && mustafaSourceForMatch.contains(normalizedQuery)

        let showArabic = settings.showArabicText || mArabic
        let showTranslit = hafsOnly && (settings.showTransliteration || mTranslit)
        let showEnglishSaheeh = hafsOnly && (settings.showEnglishSaheeh || mSaheeh)
        let showEnglishMustafa = hafsOnly && (settings.showEnglishMustafa || mMustafa)
        let highlightQuery = queryForInlineHighlight(searchText)
        let fontSizeEN = settings.englishFontSize
        
        ZStack {
            if let currentSurah = quranPlayer.currentSurahNumber, let currentAyah = quranPlayer.currentAyahNumber, currentSurah == surah.id {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        currentAyah == ayah.id
                        ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                        : .clear
                    )
                    .padding(.horizontal, -12)
                    .padding(.vertical, ayahHighlightBackgroundVerticalPadding)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Text("\(surah.id):\(ayah.id)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                            .padding(5)
                            .frame(width: 60, height: 28)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .conditionalGlassEffect(
                                useColor: isBookmarked ? 0.3 : nil,
                                customTint: isBookmarked ? settings.accentColor.color : nil,
                                interactive: false
                            )
                            .onTapGesture {
                                settings.hapticFeedback()
                                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                            }

                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundStyle(settings.accentColor.color)
                                .padding(4)
                                .offset(x: 8, y: -6)
                        }
                    }
                    
                    Spacer()
                    
                    #if os(iOS)
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .foregroundColor(settings.accentColor.color)
                            .transition(.opacity)
                    }

                    if settings.isHafsDisplay {
                        Menu {
                            playbackMenuBlock()
                        } label: {
                            Image(systemName: "play.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(settings.accentColor.color)
                                .conditionalGlassEffect()
                                .frame(width: 28, height: 28)
                        }
                    }
                    
                    Menu {
                        menuBlock(isBookmarked: isBookmarked, includePlaybackOptions: false)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(settings.accentColor.color)
                            .conditionalGlassEffect()
                            .frame(width: 28, height: 28)
                    }
                    .sheet(isPresented: $showingAyahSheet) {
                        ShareAyahSheet(
                            surahNumber: surah.id,
                            ayahNumber: ayah.id
                        )
                        .smallMediumSheetPresentation()
                    }
                    .sheet(isPresented: $showTafsirSheet) {
                        if #available(iOS 16.0, *) {
                            AyahTafsirSheet(
                                surahName: surah.nameTransliteration,
                                surahNumber: surah.id,
                                ayahNumber: ayah.id
                            )
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                        } else {
                            AyahTafsirSheet(
                                surahName: surah.nameTransliteration,
                                surahNumber: surah.id,
                                ayahNumber: ayah.id
                            )
                        }
                    }
                    .sheet(isPresented: $showingNoteSheet) {
                        NoteEditorSheet(
                            title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah.id)",
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
                    #else
                    HStack(spacing: 8) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .foregroundColor(settings.accentColor.color)

                        if settings.isHafsDisplay {
                            Image(systemName: "play.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    showWatchPlaybackDialog = true
                                }
                        }
                    }
                    #endif
                }
                .padding(.bottom, settings.showArabicText ? 8 : 2)
                .padding(.trailing, 1)
                
                Group {
                    #if os(iOS)
                    Button {
                        if !searchText.isEmpty {
                            settings.hapticFeedback()
                            scrollDown = ayah.id
                        }
                    } label: {
                        ayahTextBlock(
                            showArabic: showArabic,
                            showTranslit: showTranslit,
                            showEnglishSaheeh: showEnglishSaheeh,
                            showEnglishMustafa: showEnglishMustafa,
                            fontSizeEN: fontSizeEN,
                            highlightQuery: highlightQuery
                        )
                    }
                    .disabled(searchText.isEmpty)
                    #else
                    ayahTextBlock(
                        showArabic: showArabic,
                        showTranslit: showTranslit,
                        showEnglishSaheeh: showEnglishSaheeh,
                        showEnglishMustafa: showEnglishMustafa,
                        fontSizeEN: fontSizeEN,
                        highlightQuery: highlightQuery
                    )
                    #endif
                }
                .padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(Rectangle())
        .lineLimit(nil)
        #if os(iOS)
        .contextMenu {
            menuBlock(isBookmarked: isBookmarked, includePlaybackOptions: true)
        }
        #endif
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK") { }
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
        .confirmationDialog("Remove bookmark and delete note?", isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            }
            Button("Cancel") {}
        } message: {
            Text("This ayah has a note. Unbookmarking will delete the note.")
        }
        #if os(watchOS)
        .confirmationDialog("Play Ayah", isPresented: $showWatchPlaybackDialog, titleVisibility: .visible) {
            Button("Play Ayah") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            }

            Button("Play From Ayah") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            }

            Button("Repeat Ayah 2×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 2)
            }

            Button("Repeat Ayah 3×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 3)
            }

            Button("Repeat Ayah 5×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 5)
            }

            Button("Repeat Ayah 10×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 10)
            }

            Button("Repeat Ayah 15×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 15)
            }

            Button("Repeat Ayah 20×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 20)
            }
        } message: {
            Text("Choose how you want to start playback for this ayah.")
        }
        #endif
        #if os(iOS)
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: ayah.id,
                initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                    startAyah: ayah.id,
                    surah: surah,
                    displayQiraah: settings.displayQiraahForArabic
                ),
                onPlay: { start, end, repAyah, repSec in
                    quranPlayer.playCustomRange(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration,
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
        #endif
    }
    
    @ViewBuilder
    private func ayahTextBlock(
        showArabic: Bool,
        showTranslit: Bool,
        showEnglishSaheeh: Bool,
        showEnglishMustafa: Bool,
        fontSizeEN: CGFloat,
        highlightQuery: String
    ) -> some View {
        let groupHasEnglishOrTranslit = showTranslit || showEnglishSaheeh || showEnglishMustafa
        let prefixOnTranslit  = groupHasEnglishOrTranslit && showTranslit
        let prefixOnSaheeh    = groupHasEnglishOrTranslit && !showTranslit && showEnglishSaheeh
        let prefixOnMustafa   = groupHasEnglishOrTranslit && !showTranslit && !showEnglishSaheeh && showEnglishMustafa

        VStack(alignment: .leading, spacing: 14) {
            if !currentNote.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(settings.accentColor.color)
                    
                    Text(currentNote)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(settings.accentColor.color.opacity(0.25), lineWidth: 1)
                )
                .conditionalGlassEffect()
                .frame(maxWidth: .infinity, alignment: .center)
                #if os(iOS)
                .onTapGesture {
                    settings.hapticFeedback()
                    draftNote = currentNote
                    showingNoteSheet = true
                }
                #endif
            }

            if showArabic {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: highlightQuery,
                    font: .custom(settings.fontArabic, size: settings.fontArabicSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: (settings.beginnerMode || ayahBeginnerMode),
                    trailingSuffix: " \(ayah.idArabic)",
                    trailingSuffixFont: .custom("KFGQPCQUMBULUthmanicScript-Regu", size: settings.fontArabicSize),
                    trailingSuffixColor: settings.accentColor.color
                )
                .animation(.easeInOut, value: tajweedAnimationKey)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(nil)
            }

            if showTranslit {
                let txt = prefixOnTranslit ? "\(ayah.id). \(ayah.textTransliteration)" : ayah.textTransliteration
                HighlightedSnippet(
                    source: txt,
                    term: highlightQuery,
                    font: .system(size: fontSizeEN),
                    accent: settings.accentColor.color,
                    fg: .primary
                )
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }

            if showEnglishSaheeh {
                let txt = prefixOnSaheeh ? "\(ayah.id). \(ayah.textEnglishSaheeh)" : ayah.textEnglishSaheeh
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )
                    Text("— Saheeh International")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }

            if showEnglishMustafa {
                let txt = prefixOnMustafa ? "\(ayah.id). \(ayah.textEnglishMustafa)" : ayah.textEnglishMustafa
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )
                    Text("— Clear Quran (Mustafa Khattab)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard() {
        if isBookmarkedHere, !currentNote.isEmpty {
            confirmRemoveNote = true
        } else {
            settings.hapticFeedback()
            settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
        }
    }

    #if os(iOS)
    @ViewBuilder
    private func playbackMenuBlock() -> some View {
        let repeatOptions = [2, 3, 5, 10, 15, 20]

        Group {
            Menu {
                ForEach(repeatOptions, id: \.self) { count in
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                    } label: {
                        Label("Repeat \(count)×", systemImage: "\(count).circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    showCustomRangeSheet = true
                } label: {
                    Label("Play Custom Range", systemImage: "slider.horizontal.3")
                }
            } label: {
                Label("Repeat Ayah", systemImage: "repeat")
            }
            
            Button {
                settings.hapticFeedback()
                showCustomRangeSheet = true
            } label: {
                Label("Play Custom Range", systemImage: "slider.horizontal.3")
            }

            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            } label: {
                Label("Play From Ayah", systemImage: "play.circle.fill")
            }
            
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            } label: {
                Label("Play This Ayah", systemImage: "play.circle")
            }
        }
    }

    @ViewBuilder
    private func contextPlaybackMenuBlock() -> some View {
        let repeatOptions = [2, 3, 5, 10, 15, 20]

        Menu {
            ForEach(repeatOptions, id: \.self) { count in
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                } label: {
                    Label("Repeat \(count)×", systemImage: "\(count).circle")
                }
            }

            Button {
                settings.hapticFeedback()
                showCustomRangeSheet = true
            } label: {
                Label("Play Custom Range", systemImage: "slider.horizontal.3")
            }
        } label: {
            Label("Repeat Ayah", systemImage: "repeat")
        }

        Menu {
            Button {
                settings.hapticFeedback()
                showCustomRangeSheet = true
            } label: {
                Label("Play Custom Range", systemImage: "slider.horizontal.3")
            }

            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            } label: {
                Label("Play From Ayah", systemImage: "play.circle.fill")
            }
            
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            } label: {
                Label("Play This Ayah", systemImage: "play.circle")
            }
        } label: {
            Label("Play Ayah", systemImage: "play.circle")
        }
    }
    #endif

    @ViewBuilder
    private func menuBlock(isBookmarked: Bool, includePlaybackOptions: Bool) -> some View {
        #if os(iOS)
        let canShowTafsir: Bool = {
            if let override = comparisonQiraahOverride {
                return override.isEmpty || override == "Hafs"
            }
            return settings.isHafsDisplay
        }()

        VStack(alignment: .leading) {
            Button(role: isBookmarked ? .destructive : nil) {
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
                    settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
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
                    Label("Remove Note", systemImage: "minus.circle")
                }
            }

            if canShowTafsir {
                Button {
                    settings.hapticFeedback()
                    showTafsirSheet = true
                } label: {
                    Label("See Tafsir", systemImage: "text.book.closed")
                }
            }
            
            if settings.showArabicText && !settings.beginnerMode {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                } label: {
                    Label("Beginner Mode",
                          systemImage: ayahBeginnerMode
                          ? "textformat.size.larger.ar"
                          : "textformat.size.ar")
                }
            }
            
            Divider()
            
            if includePlaybackOptions && settings.isHafsDisplay {
                contextPlaybackMenuBlock()
                Divider()
            }

            Button {
                settings.hapticFeedback()
                ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id, settings: settings, quranData: quranData)
            } label: {
                Label("Copy Ayah", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                showingAyahSheet = true
            } label: {
                Label("Share Ayah", systemImage: "square.and.arrow.up")
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
        #endif
    }
}

private struct AyahRowPreviewContent: View {
    @State private var scrollDown: Int? = nil
    @State private var searchText = ""

    var body: some View {
        List {
            AyahRow(
                surah: AlIslamPreviewData.surah,
                ayah: AlIslamPreviewData.ayah,
                scrollDown: $scrollDown,
                searchText: $searchText
            )
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        AyahRowPreviewContent()
    }
}
