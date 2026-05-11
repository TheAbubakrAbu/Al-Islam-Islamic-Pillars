import SwiftUI

struct KhatmExtraSheet: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss

    // Precomputed totals are injected by the caller. If `totals` is nil
    // the view shows a loading state or an empty placeholder.
    let totals: (words: Int, letters: Int, totalWords: Int, totalLetters: Int)?
    let isLoading: Bool

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Khatm Extra")) {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Spacer()
                            Text("Calculating…")
                                .foregroundStyle(.secondary)
                        }
                    } else if let totals {
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
                    } else {
                        HStack {
                            Text("No data")
                            Spacer()
                        }
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
    KhatmExtraSheet(totals: (words: 123, letters: 456, totalWords: 623, totalLetters: 789), isLoading: false)
        .environmentObject(Settings.shared)
}
