import SwiftUI

struct AyahRow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var ayahBeginnerMode = false
    
    #if !os(watchOS)
    @State private var showingAyahSheet = false
    @State private var showTafsirSheet = false
    
    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showCustomRangeSheet = false
    #endif
    
    let surah: Surah
    let ayah: Ayah
    /// When non-nil (e.g. comparison mode), use this qiraah for Arabic instead of global setting.
    var comparisonQiraahOverride: String? = nil

    @Binding var scrollDown: Int?
    @Binding var searchText: String
    
    @State private var showRespectAlert = false
    
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
        let baseText = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: comparisonQiraahOverride)
        return spacedArabic(baseText)
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
    
    var body: some View {
        let isBookmarked = isBookmarkedHere
        let showArabic = settings.showArabicText
        let hafsOnly: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }
        let showTranslit = settings.showTransliteration && hafsOnly
        let showEnglishSaheeh = settings.showEnglishSaheeh && hafsOnly
        let showEnglishMustafa = settings.showEnglishMustafa && hafsOnly
        let fontSizeEN = settings.englishFontSize
        
        ZStack {
            if let currentSurah = quranPlayer.currentSurahNumber, let currentAyah = quranPlayer.currentAyahNumber, currentSurah == surah.id {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        currentAyah == ayah.id
                        ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                        : .white.opacity(0.0001)
                    )
                    .padding(.horizontal, -12)
                    #if !os(watchOS)
                    .padding(.vertical, -11)
                    #endif
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .padding(5)
                        .frame(width: 60, height: 28)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .conditionalGlassEffect(useColor: 0.1)
                        #if !os(watchOS)
                        .onTapGesture {
                            settings.hapticFeedback()
                            showingAyahSheet = true
                        }
                        #endif
                    
                    Spacer()
                    
                    #if os(watchOS)
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                        .foregroundColor(settings.accentColor.color)
                        
                    #else
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
                    #endif
                }
                .padding(.bottom, settings.showArabicText ? 8 : 2)
                .padding(.trailing, 1)
                
                Group {
                    #if !os(watchOS)
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
                            fontSizeEN: fontSizeEN
                        )
                    }
                    .disabled(searchText.isEmpty)
                    #else
                    ayahTextBlock(
                        showArabic: showArabic,
                        showTranslit: showTranslit,
                        showEnglishSaheeh: showEnglishSaheeh,
                        showEnglishMustafa: showEnglishMustafa,
                        fontSizeEN: fontSizeEN
                    )
                    #endif
                }
                .padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .lineLimit(nil)
        #if !os(watchOS)
        .contextMenu {
            menuBlock(isBookmarked: isBookmarked, includePlaybackOptions: true)
        }
        #endif
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
        .confirmationDialog("Remove bookmark and delete note?", isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This ayah has a note. Unbookmarking will delete the note.")
        }
        #if !os(watchOS)
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: ayah.id,
                initialEndAyah: surah.numberOfAyahs(for: settings.displayQiraahForArabic),
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
        }
        #endif
    }
    
    @ViewBuilder
    private func ayahTextBlock(
        showArabic: Bool,
        showTranslit: Bool,
        showEnglishSaheeh: Bool,
        showEnglishMustafa: Bool,
        fontSizeEN: CGFloat
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(settings.accentColor.color.opacity(0.25), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
                #if !os(watchOS)
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
                    term: searchText,
                    font: .custom(settings.fontArabic, size: settings.fontArabicSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: (settings.beginnerMode || ayahBeginnerMode),
                    trailingSuffix: " \(ayah.idArabic)",
                    trailingSuffixFont: .custom("KFGQPCQUMBULUthmanicScript-Regu", size: settings.fontArabicSize),
                    trailingSuffixColor: settings.accentColor.color
                )
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(nil)
            }

            if showTranslit {
                let txt = prefixOnTranslit ? "\(ayah.id). \(ayah.textTransliteration)" : ayah.textTransliteration
                HighlightedSnippet(
                    source: txt,
                    term: searchText,
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
                        term: searchText,
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
                        term: searchText,
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

    #if !os(watchOS)
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
        #if !os(watchOS)
        let canShowTafsir: Bool = {
            if let override = comparisonQiraahOverride {
                return override.isEmpty || override == "Hafs"
            }
            return settings.isHafsDisplay
        }()

        VStack(alignment: .leading) {
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
                    Label("Remove Note", systemImage: "trash")
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

#Preview {
    QuranView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
