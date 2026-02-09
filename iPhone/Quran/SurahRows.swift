import SwiftUI

struct SurahRow: View {
    @EnvironmentObject var settings: Settings
    
    let surah: Surah
    var ayah: Int?
    var end: Bool?
    
    var body: some View {
        #if !os(watchOS)
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        if let ayah = ayah {
                            if end != nil {
                                Text("Ends at \(surah.id):\(ayah)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Starts at \(surah.id):\(ayah)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("\(surah.numberOfAyahs) Ayahs")
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.secondary)
                            
                            Text(surah.type == "meccan" ? "🕋" : "🕌")
                                .font(.caption2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(settings.accentColor.color)
                        }
                    }
                    
                    Text(surah.nameEnglish)
                        .foregroundColor(.primary)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(surah.nameArabic) - \(surah.idArabic)")
                        .font(.headline)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(settings.accentColor.color)
                    
                    Text("\(surah.nameTransliteration) - \(surah.id)")
                        .foregroundColor(.primary)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 8)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        #else
        VStack {
            HStack {
                Spacer()
                
                Text("\(surah.nameArabic) - \(surah.idArabic)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
            }
            
            HStack {
                Text("\(surah.id) - \(surah.nameTransliteration)")
                    .font(.subheadline)
                
                Spacer()
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        #endif
    }
}

struct SurahAyahRow: View {
    @EnvironmentObject var settings: Settings
    
    var surah: Surah
    var ayah: Ayah
    var note: String? = nil

    private var visibleLineCount: Int {
        var lines = 0
        if settings.showArabicText { lines += 1 }
        if settings.showTransliteration { lines += 1 }
        if settings.showEnglishSaheeh || settings.showEnglishMustafa { lines += 1 }
        return max(lines, 1)
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("\(surah.id):\(ayah.id)")
                    .font(.headline)
                
                Text(surah.nameTransliteration)
                    .font(.caption)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #if !os(watchOS)
            .frame(width: 65, alignment: .center)
            #else
            .frame(width: 40, alignment: .center)
            #endif
            .foregroundColor(settings.accentColor.color)
            .padding(.trailing, 8)
            
            if let note = note {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(visibleLineCount)
            } else {
                VStack {
                    if settings.showArabicText {
                        let text = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)

                        Text(settings.beginnerMode ? text.map { "\($0) " }.joined() : text)
                            .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if settings.showTransliteration, settings.isHafsDisplay {
                        Text(ayah.textTransliteration)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if settings.showEnglishSaheeh, settings.isHafsDisplay {
                        Text(ayah.textEnglishSaheeh)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if settings.showEnglishMustafa, settings.isHafsDisplay {
                        Text(ayah.textEnglishMustafa)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .foregroundColor(.primary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

private enum _FmtCache {
    static let mmss: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()
}

@inline(__always)
func formatMMSS(_ seconds: Double) -> String {
    _FmtCache.mmss.string(from: seconds) ?? "00:00"
}

#if !os(watchOS)
struct LastListenedSurahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let lastListenedSurah: LastListenedSurah
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var body: some View {
        guard let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber })
        else { return AnyView(EmptyView()) }

        return AnyView(
            Section(header: Text("LAST LISTENED TO SURAH")) {
                VStack {
                    NavigationLink(destination:
                        AyahsView(surah: surah)
                            .transition(.opacity)
                            .animation(.easeInOut, value: lastListenedSurah.surahName)
                    ) {
                        HStack {
                            Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
                                .font(.title2.bold())
                                .foregroundColor(settings.accentColor.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            Spacer()

                            Menu {
                                Button {
                                    settings.hapticFeedback()
                                    quranPlayer.playSurah(
                                        surahNumber: lastListenedSurah.surahNumber,
                                        surahName: lastListenedSurah.surahName,
                                        certainReciter: true)
                                } label: {
                                    Label("Play Last Listened", systemImage: "play.fill")
                                }

                                Button {
                                    settings.hapticFeedback()
                                    quranPlayer.playSurah(
                                        surahNumber: lastListenedSurah.surahNumber,
                                        surahName: surah.nameTransliteration)
                                } label: {
                                    Label("Play from Beginning", systemImage: "memories")
                                }
                            } label: {
                                Image(systemName: "play.fill")
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(settings.accentColor.color)
                                    .minimumScaleFactor(0.75)
                                    .transition(.opacity)
                                    .opacity(!quranPlayer.isPlaying && !quranPlayer.isPaused ? 1 : 0)
                                    .animation(.easeInOut, value: quranPlayer.isPlaying)
                                    .animation(.easeInOut, value: quranPlayer.isPaused)
                            }
                            .disabled(quranPlayer.isPlaying || quranPlayer.isPaused)
                        }
                    }
                    .padding(.bottom, 1)

                    HStack {
                        Text(lastListenedSurah.reciter.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer()

                        Text("\(formatMMSS(lastListenedSurah.currentDuration)) / \(formatMMSS(lastListenedSurah.fullDuration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(.vertical, 8)
            }
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                certainReciter: true,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
            #if !os(watchOS)
            .contextMenu {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedSurah = nil
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                }

                Divider()

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: lastListenedSurah.surahName,
                        certainReciter: true
                    )
                } label: {
                    Label("Play Last Listened", systemImage: "play.fill")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }

                Divider()

                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    lastListened: true
                )
            }
            #endif
            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        )
    }
}
#endif

struct LastReadAyahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }
    
    private var noteToShow: String? {
        guard let idx = settings.bookmarkedAyahs.firstIndex(where: { $0.surah == surah.id && $0.ayah == ayah.id }) else {
            return nil
        }
        let t = settings.bookmarkedAyahs[idx].note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t?.isEmpty == false) ? t : nil
    }

    var body: some View {
        Section(header: Text("LAST READ AYAH")) {
            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
            }
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                ayahID: ayah.id,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(
                surah: surah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                bookmarkedSurah: surah.id,
                bookmarkedAyah: ayah.id
            )
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                lastRead: true
            )
        }
    }
}

struct AyahSearchResultRow: View {
    @EnvironmentObject private var settings: Settings

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }

    var body: some View {
        NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
            SurahAyahRow(surah: surah, ayah: ayah)
        }
        .rightSwipeActions(
            surahID: surah.id,
            surahName: surah.nameTransliteration,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(
            surah: surah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: surah.id,
            bookmarkedAyah: ayah.id,
        )
        .ayahContextMenuModifier(
            surah: surah.id,
            ayah: ayah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }
}

struct AyahSearchRow: View, Equatable {
    @EnvironmentObject private var settings: Settings
    
    let surahName: String
    let surah: Int
    let ayah:  Int
    let query: String
    
    let arabic: String
    let transliteration: String
    let englishSaheeh: String
    let englishMustafa: String
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    
    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }
    
    var body: some View {
        let normalizedQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns

        // Precompute cleaned sources ONCE per render
        let srcArabic  = settings.cleanSearch(arabic,          whitespace: false).removingArabicDiacriticsAndSigns
        let srcTr      = settings.cleanSearch(transliteration, whitespace: false).removingArabicDiacriticsAndSigns
        let srcSaheeh  = settings.cleanSearch(englishSaheeh,   whitespace: false).removingArabicDiacriticsAndSigns
        let srcMustafa = settings.cleanSearch(englishMustafa,  whitespace: false).removingArabicDiacriticsAndSigns

        // Matches
        let mArabic  = !normalizedQuery.isEmpty && srcArabic.contains(normalizedQuery)
        let mTr      = !normalizedQuery.isEmpty && srcTr.contains(normalizedQuery)
        let mSaheeh  = !normalizedQuery.isEmpty && srcSaheeh.contains(normalizedQuery)
        let mMustafa = !normalizedQuery.isEmpty && srcMustafa.contains(normalizedQuery)

        // Arabic + Transliteration: show if ON or matched. When non-Hafs qiraah, only Arabic.
        let showArabicLine  = settings.showArabicText      || mArabic
        let showTrLine      = settings.isHafsDisplay && (settings.showTransliteration || mTr)

        // --- English selection logic (only one unless both match). Hidden when non-Hafs. ---
        let (showSaheehLine, showMustafaLine): (Bool, Bool) = {
            guard settings.isHafsDisplay else { return (false, false) }
            let userSaheehOn  = settings.showEnglishSaheeh
            let userMustafaOn = settings.showEnglishMustafa

            if mSaheeh && mMustafa {
                // both matched -> show both
                return (true, true)
            } else if mSaheeh || mMustafa {
                // only the one that matched
                return (mSaheeh, mMustafa)
            } else {
                // no matches -> respect toggles but cap to ONE line
                if userSaheehOn && !userMustafaOn {
                    return (true, false)
                } else if userMustafaOn && !userSaheehOn {
                    return (false, true)
                } else if userSaheehOn && userMustafaOn {
                    // both ON, no match -> pick default single
                    // default = Saheeh; switch to (false, true) if you prefer Mustafa
                    return (true, false)
                } else {
                    // neither ON -> none
                    return (false, false)
                }
            }
        }()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(surahName) \(surah):\(ayah)")
                
                if isBookmarked {
                    Spacer()
                    
                    Image(systemName: "bookmark.fill")
                }
            }
            .font(.caption)
            .foregroundColor(settings.accentColor.color)
            .transition(.opacity)

            if showArabicLine {
                HighlightedSnippet(
                    source: arabic,
                    term: query,
                    font: .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
            }

            if showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }
        }
        .padding(.vertical, 2)
        .rightSwipeActions(
            surahID: surah,
            surahName: surahName,
            ayahID: ayah,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: surah,
            bookmarkedAyah: ayah
        )
        .ayahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }
    
    static func == (l: Self, r: Self) -> Bool {
        l.surah == r.surah && l.ayah == r.ayah &&
        l.query == r.query &&
        l.favoriteSurahs == r.favoriteSurahs &&
        l.bookmarkedAyahs == r.bookmarkedAyahs
    }
}

#Preview {
    QuranView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
