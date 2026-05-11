import SwiftUI

struct KhatmExtraSheet: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @Environment(\.dismiss) private var dismiss

    private var totals: (words: Int, letters: Int, totalWords: Int, totalLetters: Int) {
        var wordsCompleted = 0
        var lettersCompleted = 0
        var totalWords = 0
        var totalLetters = 0

        for surah in quranData.quran {
            for ayah in surah.ayahs {
                let text = ayah.textCleanArabic(for: settings.displayQiraahForArabic)
                let cleaned = text.replacingOccurrences(of: "\u{200F}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let wordCount = cleaned.split{ $0.isWhitespace }.count
                let letterCount = cleaned.filter { !$0.isWhitespace }.count

                totalWords += wordCount
                totalLetters += letterCount

                if settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id) {
                    wordsCompleted += wordCount
                    lettersCompleted += letterCount
                }
            }
        }
        return (wordsCompleted, lettersCompleted, totalWords, totalLetters)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Khatm Extra")) {
                    HStack {
                        Text("Words completed")
                        Spacer()
                        Text("\(totals.words)/\(totals.totalWords)")
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Letters completed")
                        Spacer()
                        Text("\(totals.letters)/\(totals.totalLetters)")
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Words %")
                        Spacer()
                        Text("\(Int((Double(totals.words)/Double(max(totals.totalWords,1))*100)).description)%")
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Letters %")
                        Spacer()
                        Text("\(Int((Double(totals.letters)/Double(max(totals.totalLetters,1))*100)).description)%")
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Extra")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    KhatmExtraSheet()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
}
