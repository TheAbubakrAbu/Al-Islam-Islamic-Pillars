import SwiftUI

extension Settings {
    // MARK: - Quran types and constants

    static let randomReciterName = "Random Reciter"

    enum QuranSortMode: String, CaseIterable, Identifiable {
        case surah
        case juz
        case page
        case revelation

        var id: String { rawValue }
    }

    enum Riwayah {
        static let hafsTag = ""
        static let hafsLabel = "Hafs an Asim (default)"

        static let shubah = "Shubah an Asim"
        static let khalaf = "Khalaf an Hamzah"
        static let buzzi = "al-Bazzi an Ibn Kathir"
        static let qunbul = "Qunbul an Ibn Kathir"
        static let warsh = "Warsh an Nafi"
        static let qaloon = "Qalun an Nafi"
        static let duri = "ad-Duri an Abi Amr"
        static let susi = "as-Susi an Abi Amr"

        static let warshArabic = "ورش عن نافع"
        static let qaloonArabic = "قالون عن نافع"
        static let duriArabic = "الدوري عن أبي عمرو"
        static let susiArabic = "السوسي عن أبي عمرو"
        static let buzziArabic = "البزي عن ابن كثير"
        static let qunbulArabic = "قنبل عن ابن كثير"
        static let shubahArabic = "شعبة عن عاصم"
        static let khalafArabic = "خلف عن حمزة"

        static let menuOptions: [(label: String, tag: String)] = [
            (hafsLabel, hafsTag),
            (shubah, shubah),
            (buzzi, buzzi),
            (qunbul, qunbul),
            (warsh, warsh),
            (qaloon, qaloon),
            (duri, duri),
            (susi, susi),
        ]

        static let arabicCaptionByTag: [String: String] = [
            hafsTag: "حفص عن عاصم",
            warsh: warshArabic,
            qaloon: qaloonArabic,
            duri: duriArabic,
            susi: susiArabic,
            buzzi: buzziArabic,
            qunbul: qunbulArabic,
            shubah: shubahArabic,
            khalaf: khalafArabic,
        ]

        static func canonicalTag(_ stored: String) -> String {
            let raw = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            switch raw {
            case "", "Hafs", "Hafs an Asim", hafsLabel: return hafsTag
            case warsh, "Warsh An Nafi": return warsh
            case qaloon, "Qaloon an Nafi", "Qaloon An Nafi": return qaloon
            case duri, "Ad-Duri an Abi Amr": return duri
            case susi, "As-Susi an Abi Amr": return susi
            case buzzi, "Al-Buzzi an Ibn Kathir": return buzzi
            case qunbul, "Qumbul an Ibn Kathir": return qunbul
            case shubah, "Shu'bah an Asim", "Shu'bah an Aasim", "Shouba an Asim": return shubah
            case khalaf: return khalaf
            default: return raw
            }
        }
    }

    // MARK: - Quran migrations and reciter selection

    /// Consolidated startup migrations for Quran sort mode and reciter persistence.
    func runQuranStartupMigrations() {
        let defaults = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

        if defaults?.object(forKey: "quranSortMode") == nil,
           let legacyGroupBySurah = defaults?.object(forKey: "groupBySurah") as? Bool {
            quranSortModeRaw = legacyGroupBySurah ? QuranSortMode.surah.rawValue : QuranSortMode.juz.rawValue
        }

        if reciter == Self.randomReciterName {
            // Keep the saved random-reciter preference as-is.
        } else if reciter.starts(with: "ar") {
            if let match = reciters.first(where: { $0.ayahIdentifier == reciter }) {
                reciter = match.name
            } else {
                reciter = "Muhammad Al-Minshawi (Murattal)"
            }
        } else if reciter.isEmpty {
            reciter = "Muhammad Al-Minshawi (Murattal)"
        }

        migrateLegacyReciterIdIfNeeded()
        if reciter != Self.randomReciterName,
           let resolved = resolvedSelectedReciterIgnoringRandom(),
           reciterId != resolved.id {
            reciterId = resolved.id
        }
    }

    /// If the user has a legacy name-only save, attach a stable id. When several rows share the same display name (e.g. Ahmad Deban in multiple riwayat), prefer the Hafs / default surah feed (`qiraah == nil`).
    func migrateLegacyReciterIdIfNeeded() {
        guard reciter != Self.randomReciterName else { return }
        guard reciterId.isEmpty else { return }
        let matches = reciters.filter { $0.name == reciter }
        guard let r = Self.disambiguateReciters(sharingDisplayName: matches) else { return }
        reciterId = r.id
    }

    /// Picks one row when several share the same `name` (e.g. multiple qiraat). Prefers Hafs surah URL (`qiraah == nil`).
    static func disambiguateReciters(sharingDisplayName matches: [Reciter]) -> Reciter? {
        guard !matches.isEmpty else { return nil }
        if matches.count == 1 { return matches.first }
        return matches.first(where: { $0.qiraah == nil }) ?? matches.first
    }

    func setSelectedReciter(_ r: Reciter) {
        reciterId = r.id
        reciter = r.name
    }

    func setRandomReciterMode() {
        reciterId = ""
        reciter = Self.randomReciterName
    }

    func applyDefaultReciterSelection() {
        let defaultName = "Muhammad Al-Minshawi (Murattal)"
        if let r = reciters.first(where: { $0.name == defaultName }) {
            setSelectedReciter(r)
        } else {
            reciterId = ""
            reciter = defaultName
        }
    }

    /// When not using Random Reciter: resolve by stored id first, then by legacy display name (disambiguated when multiple rows share a name).
    func resolvedSelectedReciterIgnoringRandom() -> Reciter? {
        guard reciter != Self.randomReciterName else { return nil }
        if !reciterId.isEmpty, let match = reciters.first(where: { $0.id == reciterId }) {
            return match
        }
        let matches = reciters.filter { $0.name == reciter }
        return Self.disambiguateReciters(sharingDisplayName: matches)
    }

    /// Normalizes older saved `displayQiraah` tags to canonical Unicode transliteration (matches on-screen riwayah names).
    static func normalizeLegacyRiwayahTag(_ stored: String) -> String {
        Riwayah.canonicalTag(stored)
    }

    func toggleSurahFavorite(surah: Int) {
        withAnimation {
            if isSurahFavorite(surah: surah) {
                favoriteSurahs.removeAll(where: { $0 == surah })
            } else {
                favoriteSurahs.append(surah)
            }
        }
    }

    func isSurahFavorite(surah: Int) -> Bool {
        return favoriteSurahs.contains(surah)
    }

    static let bookmarkNoteRemovalDialogTitle = "Remove bookmark and delete note?"
    static let bookmarkNoteRemovalDialogMessage = "This ayah has a note. Unbookmarking will delete the note."

    func bookmarkIndex(surah: Int, ayah: Int) -> Int? {
        bookmarkedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }

    func bookmarkedAyah(surah: Int, ayah: Int) -> BookmarkedAyah? {
        bookmarkIndex(surah: surah, ayah: ayah).map { bookmarkedAyahs[$0] }
    }

    func bookmarkHasNote(surah: Int, ayah: Int) -> Bool {
        bookmarkedAyah(surah: surah, ayah: ayah)?.hasNote ?? false
    }

    func bookmarkNoteText(surah: Int, ayah: Int) -> String {
        bookmarkedAyah(surah: surah, ayah: ayah)?
            .note?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func toggleBookmark(surah: Int, ayah: Int) {
        withAnimation {
            let bookmark = BookmarkedAyah(surah: surah, ayah: ayah)
            if let index = bookmarkedAyahs.firstIndex(where: {$0.id == bookmark.id}) {
                bookmarkedAyahs.remove(at: index)
            } else {
                bookmarkedAyahs.append(bookmark)
            }
        }
    }

    func isBookmarked(surah: Int, ayah: Int) -> Bool {
        let bookmark = BookmarkedAyah(surah: surah, ayah: ayah)
        return bookmarkedAyahs.contains(where: {$0.id == bookmark.id})
    }

    @discardableResult
    func toggleBookmarkIfNoNoteLoss(surah: Int, ayah: Int) -> Bool {
        guard !(isBookmarked(surah: surah, ayah: ayah) && bookmarkHasNote(surah: surah, ayah: ayah)) else {
            return false
        }

        toggleBookmark(surah: surah, ayah: ayah)
        return true
    }

    func ensureBookmarkExists(surah: Int, ayah: Int) {
        guard !isBookmarked(surah: surah, ayah: ayah) else { return }
        toggleBookmark(surah: surah, ayah: ayah)
    }

    func setBookmarkNote(surah: Int, ayah: Int, note: String?) {
        withAnimation {
            let normalized = note?.trimmingCharacters(in: .whitespacesAndNewlines)
            let storedNote = (normalized?.isEmpty == true) ? nil : normalized

            if let index = bookmarkIndex(surah: surah, ayah: ayah) {
                var bookmark = bookmarkedAyahs[index]
                bookmark.note = storedNote
                bookmarkedAyahs[index] = bookmark
            } else {
                bookmarkedAyahs.append(BookmarkedAyah(surah: surah, ayah: ayah, note: storedNote))
            }
        }
    }

    func removeBookmarkNote(surah: Int, ayah: Int) {
        guard let index = bookmarkIndex(surah: surah, ayah: ayah) else { return }

        withAnimation {
            var bookmark = bookmarkedAyahs[index]
            bookmark.note = nil
            bookmarkedAyahs[index] = bookmark
        }
    }
    
    private static let unwantedCharSet: CharacterSet = {
        var set = CharacterSet.punctuationCharacters
            .union(.symbols)
            .union(.nonBaseCharacters)
        // Keep boolean-search operators in the normalized query.
        set.remove(charactersIn: "&|!#")
        return set
    }()

    private static let canonicalArabicSearchMap: [String: String] = [
        // Alif family
        "\u{0670}": "ا", // dagger alif
        "ٱ": "ا",
        "أ": "ا",
        "إ": "ا",
        "آ": "ا",
        "ٲ": "ا",
        "ٳ": "ا",
        "ٵ": "ا",
        // Waw variants
        "ۥ": "و",
        // Ya variants
        "ۦ": "ي",
        "ى": "ي", // alif maqsurah -> ya
        // Teh marbuta equivalence (broad)
        "ة": "ه",
        // Hamza unification on carriers
        "ؤ": "و",
        "ئ": "ي",
        "ء": ""
    ]

    private func normalizedArabicForSearch(_ text: String) -> String {
        Self.canonicalArabicSearchMap.reduce(text) { partial, pair in
            partial.replacingOccurrences(of: pair.key, with: pair.value)
        }
    }

    private func collapsingWhitespace(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func cleanSearch(_ text: String, whitespace: Bool = false) -> String {
        let normalized = normalizedArabicForSearch(text)
        var cleaned = String(normalized.unicodeScalars
            .filter { !Self.unwantedCharSet.contains($0) }
        ).lowercased()
        cleaned = collapsingWhitespace(cleaned)

        if whitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    func isTajweedCategoryVisible(_ category: TajweedLegendCategory) -> Bool {
        switch category {
        case .tafkhim: return showTajweedTafkhim
        case .qalqalah: return showTajweedQalqalah
        case .lamShamsiyah: return showTajweedLamShamsiyah
        case .droppedLetter: return showTajweedDroppedLetter
        case .idghamGhunnah: return showTajweedIdghamBiGhunnahHeavy
        case .ikhfaaLight: return showTajweedIdghamBiGhunnahLight
        case .ikhfaaHeavy: return showTajweedIkhfaa
        case .iqlaab: return showTajweedIqlab
        case .idghamBilaGhunnah: return showTajweedIdghamBilaGhunnah
        case .hamzatWaslSilent: return showTajweedHamzatWaslSilent
        case .maddNatural: return showTajweedMaddNatural2
        case .maddSukoon: return showTajweedMaddAaridLisSukoon
        case .maddNecessary: return showTajweedMaddNecessary6
        case .maddSeparated: return showTajweedMaddSeparated
        case .maddConnected: return showTajweedMaddConnected
        }
    }

    func setTajweedCategory(_ category: TajweedLegendCategory, visible: Bool) {
        switch category {
        case .tafkhim: showTajweedTafkhim = visible
        case .qalqalah: showTajweedQalqalah = visible
        case .lamShamsiyah: showTajweedLamShamsiyah = visible
        case .droppedLetter: showTajweedDroppedLetter = visible
        case .idghamGhunnah: showTajweedIdghamBiGhunnahHeavy = visible
        case .ikhfaaLight: showTajweedIdghamBiGhunnahLight = visible
        case .ikhfaaHeavy: showTajweedIkhfaa = visible
        case .iqlaab: showTajweedIqlab = visible
        case .idghamBilaGhunnah: showTajweedIdghamBilaGhunnah = visible
        case .hamzatWaslSilent: showTajweedHamzatWaslSilent = visible
        case .maddNatural: showTajweedMaddNatural2 = visible
        case .maddSukoon: showTajweedMaddAaridLisSukoon = visible
        case .maddNecessary: showTajweedMaddNecessary6 = visible
        case .maddSeparated: showTajweedMaddSeparated = visible
        case .maddConnected: showTajweedMaddConnected = visible
        }
    }

    func addQuranSearchHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var history = quranSearchHistory.filter {
            $0.caseInsensitiveCompare(trimmed) != .orderedSame
        }
        history.insert(trimmed, at: 0)
        quranSearchHistory = Array(history.prefix(10))
    }

    func removeQuranSearchHistory(_ query: String) {
        quranSearchHistory.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
    }

    // MARK: - Quran favorites

    func toggleReciterFavorite(reciterID: String) {
        let trimmed = reciterID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            if isReciterFavorite(reciterID: trimmed) {
                favoriteReciterIDs.removeAll(where: { $0 == trimmed })
            } else {
                favoriteReciterIDs.append(trimmed)
            }
        }
    }

    func isReciterFavorite(reciterID: String) -> Bool {
        let trimmed = reciterID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return favoriteReciterIDs.contains(trimmed)
    }
}
