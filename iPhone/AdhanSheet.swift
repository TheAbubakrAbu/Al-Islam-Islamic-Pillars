import SwiftUI

struct AdhanSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: Settings

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Make sure your prayer times are correct")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prayer times depend on the calculation method, and choosing the wrong one can make Fajr and Isha noticeably off.")
                        
                        Text("""
                            • You should probably choose the method used in your region (for example, North America, Egypt, etc.).
                            • If your country isn’t listed or you’re unsure, a global method like Muslim World League is a safe choice.
                            • It’s best to check with your local mosque to see which method they follow.
                            """
                        )
                        .foregroundColor(.secondary)
                    }
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    
                    Text("After this, take a moment to review the rest of the settings to customize notifications, traveling mode, offsets, and other preferences (including Quran settings).")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                }

                Section(header: Text("PRAYER CALCULATION")) {
                    VStack(alignment: .leading) {
                        Picker("Calculation", selection: $settings.prayerCalculation.animation(.easeInOut)) {
                            ForEach(calculationOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }

                        Text("Fajr and Isha can vary significantly by method, especially at higher latitudes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }

                    VStack(alignment: .leading) {
                        Toggle("Use Hanafi Calculation for Asr", isOn: $settings.hanafiMadhab.animation(.easeInOut))
                            .font(.subheadline)
                            .tint(settings.accentColor.color)

                        Text("The Hanafi madhab sets Asr later than other schools of thought. Enable this only if you follow the Hanafi method.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Adhan Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        settings.hapticFeedback()
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    AdhanSetupSheet()
        .environmentObject(Settings.shared)
}
