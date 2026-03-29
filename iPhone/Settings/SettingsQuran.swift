import SwiftUI

extension Settings {
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
    
    private static let unwantedCharSet: CharacterSet = {
        CharacterSet(charactersIn: "-[]()'\"").union(.nonBaseCharacters)
    }()

    func cleanSearch(_ text: String, whitespace: Bool = false) -> String {
        var cleaned = String(text.unicodeScalars
            .filter { !Self.unwantedCharSet.contains($0) }
        ).lowercased()

        if whitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    func isTajweedCategoryVisible(_ category: TajweedLegendCategory) -> Bool {
        switch category {
        case .tafkhim: return showTajweedTafkhim
        case .qalqalah: return showTajweedQalqalah
        case .ikhfaGhunnah: return showTajweedIkhfaGhunnah
        case .idghaamSilent: return showTajweedIdghaamSilent
        case .madd246: return showTajweedMadd246
        case .madd2: return showTajweedMadd2
        case .madd6: return showTajweedMadd6
        case .madd45: return showTajweedMadd45
        }
    }

    func setTajweedCategory(_ category: TajweedLegendCategory, visible: Bool) {
        switch category {
        case .tafkhim: showTajweedTafkhim = visible
        case .qalqalah: showTajweedQalqalah = visible
        case .ikhfaGhunnah: showTajweedIkhfaGhunnah = visible
        case .idghaamSilent: showTajweedIdghaamSilent = visible
        case .madd246: showTajweedMadd246 = visible
        case .madd2: showTajweedMadd2 = visible
        case .madd6: showTajweedMadd6 = visible
        case .madd45: showTajweedMadd45 = visible
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
}
