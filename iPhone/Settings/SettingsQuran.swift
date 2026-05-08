import SwiftUI

extension Settings {
    // MARK: - Quran types and constants

    static let randomReciterName = "Random Reciter"

    enum QuranSortMode: String, CaseIterable, Identifiable {
        case surah
        case juz
        case page
        case revelation
        case khatm

        var id: String { rawValue }
    }

    enum Riwayah {
        struct Option: Identifiable, Hashable {
            let label: String
            let tag: String
            let arabic: String
            let teacher: String
            let teacherArabic: String
            let order: Int

            var id: String { tag.isEmpty ? "Hafs" : tag }
        }

        struct Group: Identifiable, Hashable {
            let teacher: String
            let teacherArabic: String
            let options: [Option]

            var id: String { teacher }
        }

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

        static let asimTeacher = "Asim"
        static let nafiTeacher = "Nafi"
        static let ibnKathirTeacher = "Ibn Kathir"
        static let abiAmrTeacher = "Abu Amr"
        static let hamzahTeacher = "Hamzah"

        static let asimTeacherArabic = "عَاصِم"
        static let nafiTeacherArabic = "نَافِع"
        static let ibnKathirTeacherArabic = "ابنِ كَثِير"
        static let abiAmrTeacherArabic = "أَبِي عَمرٍو"
        static let hamzahTeacherArabic = "حَمزَة"

        static let hafsArabic = "حَفص عَن عَاصِم"
        static let warshArabic = "وَرش عَن نَافِع"
        static let qaloonArabic = "قَالُون عَن نَافِع"
        static let duriArabic = "الدُّورِي عَن أَبِي عَمرٍو"
        static let susiArabic = "السُّوسِي عَن أَبِي عَمرٍو"
        static let buzziArabic = "البَزِّي عَن ابنِ كَثِير"
        static let qunbulArabic = "قُنبُل عَن ابنِ كَثِير"
        static let shubahArabic = "شُعبَة عَن عَاصِم"
        static let khalafArabic = "خَلَف عَن حَمزَة"

        static let options: [Option] = [
            Option(label: hafsLabel, tag: hafsTag, arabic: hafsArabic, teacher: asimTeacher, teacherArabic: asimTeacherArabic, order: 0),
            Option(label: shubah, tag: shubah, arabic: shubahArabic, teacher: asimTeacher, teacherArabic: asimTeacherArabic, order: 1),
            Option(label: warsh, tag: warsh, arabic: warshArabic, teacher: nafiTeacher, teacherArabic: nafiTeacherArabic, order: 2),
            Option(label: qaloon, tag: qaloon, arabic: qaloonArabic, teacher: nafiTeacher, teacherArabic: nafiTeacherArabic, order: 3),
            Option(label: buzzi, tag: buzzi, arabic: buzziArabic, teacher: ibnKathirTeacher, teacherArabic: ibnKathirTeacherArabic, order: 4),
            Option(label: qunbul, tag: qunbul, arabic: qunbulArabic, teacher: ibnKathirTeacher, teacherArabic: ibnKathirTeacherArabic, order: 5),
            Option(label: duri, tag: duri, arabic: duriArabic, teacher: abiAmrTeacher, teacherArabic: abiAmrTeacherArabic, order: 6),
            Option(label: susi, tag: susi, arabic: susiArabic, teacher: abiAmrTeacher, teacherArabic: abiAmrTeacherArabic, order: 7),
        ]

        static let groups: [Group] = [
            Group(teacher: asimTeacher, teacherArabic: asimTeacherArabic, options: options.filter { $0.teacher == asimTeacher }),
            Group(teacher: nafiTeacher, teacherArabic: nafiTeacherArabic, options: options.filter { $0.teacher == nafiTeacher }),
            Group(teacher: ibnKathirTeacher, teacherArabic: ibnKathirTeacherArabic, options: options.filter { $0.teacher == ibnKathirTeacher }),
            Group(teacher: abiAmrTeacher, teacherArabic: abiAmrTeacherArabic, options: options.filter { $0.teacher == abiAmrTeacher }),
        ]

        static let menuOptions: [(label: String, tag: String)] = [
            (options[0].label, options[0].tag),
            (options[1].label, options[1].tag),
            (options[2].label, options[2].tag),
            (options[3].label, options[3].tag),
            (options[4].label, options[4].tag),
            (options[5].label, options[5].tag),
            (options[6].label, options[6].tag),
            (options[7].label, options[7].tag),
        ]

        static let arabicCaptionByTag: [String: String] = [
            hafsTag: hafsArabic,
            warsh: warshArabic,
            qaloon: qaloonArabic,
            duri: duriArabic,
            susi: susiArabic,
            buzzi: buzziArabic,
            qunbul: qunbulArabic,
            shubah: shubahArabic,
            khalaf: khalafArabic,
        ]

        static let optionByTag: [String: Option] = Dictionary(uniqueKeysWithValues: options.map { ($0.tag, $0) })

        static func option(for tag: String) -> Option {
            let key = canonicalTag(tag)
            return optionByTag[key] ?? options[0]
        }

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

    func toggleQiraahFavorite(tag: String) {
        let normalizedTag = Self.normalizeLegacyRiwayahTag(tag)
        withAnimation {
            if isQiraahFavorite(tag: normalizedTag) {
                favoriteQiraahTags.removeAll { Self.normalizeLegacyRiwayahTag($0) == normalizedTag }
            } else {
                favoriteQiraahTags.append(normalizedTag)
            }
        }
    }

    func isQiraahFavorite(tag: String) -> Bool {
        let normalizedTag = Self.normalizeLegacyRiwayahTag(tag)
        return favoriteQiraahTags.contains { Self.normalizeLegacyRiwayahTag($0) == normalizedTag }
    }

    func toggleEnglishTranslationFavorite(id: String) {
        withAnimation {
            if isEnglishTranslationFavorite(id: id) {
                favoriteEnglishTranslationIDs.removeAll { $0 == id }
            } else {
                favoriteEnglishTranslationIDs.append(id)
            }
        }
    }

    func isEnglishTranslationFavorite(id: String) -> Bool {
        favoriteEnglishTranslationIDs.contains(id)
    }

    private func khatmKey(surah: Int, ayah: Int) -> String {
        "\(surah):\(ayah)"
    }

    func loadKhatmProgressCacheFromStorage() {
        let savedKeys = (try? Self.decoder.decode([String].self, from: khatmCompletedAyahsData)) ?? []
        applyKhatmCompletedAyahKeys(savedKeys, persistImmediately: false)
    }

    func applyKhatmCompletedAyahKeys(_ keys: [String], persistImmediately: Bool) {
        khatmProgressSaveTask?.cancel()
        khatmCompletedAyahSetCache = Set(keys)
        khatmCompletedSurahCountsCache = Self.khatmSurahCounts(from: khatmCompletedAyahSetCache)

        if persistImmediately {
            persistKhatmProgressNow()
            objectWillChange.send()
        }
    }

    private static func khatmSurahCounts(from keys: Set<String>) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        counts.reserveCapacity(114)

        for key in keys {
            guard let separator = key.firstIndex(of: ":"),
                  let surah = Int(key[..<separator]) else { continue }
            counts[surah, default: 0] += 1
        }

        return counts
    }

    private func persistKhatmProgressNow() {
        let keys = Array(khatmCompletedAyahSetCache)
        khatmCompletedAyahsData = (try? Self.encoder.encode(keys)) ?? Data()
    }

    private func scheduleKhatmProgressSaveAndRefresh() {
        khatmProgressSaveTask?.cancel()
        khatmProgressSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard let self, !Task.isCancelled else { return }
            withAnimation {
                self.persistKhatmProgressNow()
                self.objectWillChange.send()
            }
        }
    }

    func isKhatmAyahComplete(surah: Int, ayah: Int) -> Bool {
        khatmCompletedAyahSetCache.contains(khatmKey(surah: surah, ayah: ayah))
    }

    func markKhatmAyahComplete(surah: Int, ayah: Int) {
        let key = khatmKey(surah: surah, ayah: ayah)
        guard khatmCompletedAyahSetCache.insert(key).inserted else { return }
        khatmCompletedSurahCountsCache[surah, default: 0] += 1
        scheduleKhatmProgressSaveAndRefresh()
    }

    func khatmCompletedCount(for surah: Surah) -> Int {
        min(khatmCompletedSurahCountsCache[surah.id, default: 0], surah.numberOfAyahs)
    }

    func resetKhatmProgress(for surah: Surah) {
        let keys = Set(surah.ayahs.map { khatmKey(surah: surah.id, ayah: $0.id) })
        khatmCompletedAyahSetCache.subtract(keys)
        khatmCompletedSurahCountsCache[surah.id] = nil
        persistKhatmProgressNow()
        objectWillChange.send()
    }

    func resetAllKhatmProgress() {
        khatmCompletedAyahSetCache.removeAll(keepingCapacity: true)
        khatmCompletedSurahCountsCache.removeAll(keepingCapacity: true)
        persistKhatmProgressNow()
        objectWillChange.send()
    }

    func khatmTotalCompleted(in surahs: [Surah]) -> Int {
        khatmCompletedAyahSetCache.count
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
        // Hamza family folds to plain carrier letters for forgiving search.
        "أ": "ا",
        "إ": "ا",
        "آ": "ا",
        "ٲ": "ا",
        "ٳ": "ا",
        "ٵ": "ا",
        "ؤ": "و",
        "ئ": "ي",
        "ء": "",
        "ٴ": "",
        "ٶ": "و",
        "ٷ": "و",
        "ٸ": "ي",
        // Waw variants
        "ۥ": "و",
        // Ya variants
        "ۦ": "ي",
        "ى": "ي", // alif maqsurah -> ya
        // Teh marbuta equivalence (broad)
        "ة": "ه"
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
        case .generalGhunnah: return showTajweedGeneralGhunnah
        case .ikhfaaLight: return showTajweedIdghamBiGhunnahLight
        case .ikhfaaHeavy: return showTajweedIkhfaa
        case .iqlaab: return showTajweedIqlab
        case .idghamBilaGhunnah: return showTajweedIdghamBilaGhunnah
        case .hamzatWaslSilent: return showTajweedHamzatWaslSilent
        case .maddNatural: return showTajweedMaddNatural2
        case .maddNaturalMiniature: return showTajweedMaddNaturalMiniature
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
        case .generalGhunnah: showTajweedGeneralGhunnah = visible
        case .ikhfaaLight: showTajweedIdghamBiGhunnahLight = visible
        case .ikhfaaHeavy: showTajweedIkhfaa = visible
        case .iqlaab: showTajweedIqlab = visible
        case .idghamBilaGhunnah: showTajweedIdghamBilaGhunnah = visible
        case .hamzatWaslSilent: showTajweedHamzatWaslSilent = visible
        case .maddNatural: showTajweedMaddNatural2 = visible
        case .maddNaturalMiniature: showTajweedMaddNaturalMiniature = visible
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
