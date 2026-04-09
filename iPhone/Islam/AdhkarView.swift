import SwiftUI

struct AdhkarRow: View {
    @EnvironmentObject var settings: Settings

    let arabicText: String
    let transliteration: String
    let translation: String
    var alignArabicTrailing: Bool = false
    var useQuranicFont: Bool = false

    var body: some View {
        Section {
            rowContent
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading) {
            Text(arabicText)
                .font(useQuranicFont ? .custom(settings.fontArabic, size: 30) : .title2)
                .foregroundColor(settings.accentColor.color)
                .multilineTextAlignment(alignArabicTrailing ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: alignArabicTrailing ? .trailing : .leading)

            Text(transliteration)
                .font(.subheadline)

            Text(translation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        #if os(iOS)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = arabicText
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = transliteration
            } label: {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = translation
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }
}

struct AdhkarView: View {
    @EnvironmentObject var settings: Settings
    @State private var searchText = ""

    var body: some View {
        List {
            introductionSection
            adhkarRows
            virtuesSection
        }
        #if os(iOS)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                Picker("Arabic Font", selection: $settings.useQuranicArabicFontForAdhkarDua.animation(.easeInOut)) {
                    Text("Quranic Font").tag(true)
                    Text("Basic Font").tag(false)
                }
                .pickerStyle(.segmented)
                .conditionalGlassEffect()
                
                SearchBar(text: $searchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: $searchText)
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .navigationTitle("Common Adhkar")
    }

    private func matchesSearch(arabicText: String, transliteration: String, translation: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let normalizedQuery = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let combined = [arabicText, transliteration, translation]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        return combined.contains(normalizedQuery)
    }

    @ViewBuilder
    private func filteredAdhkarRow(arabicText: String, transliteration: String, translation: String, alignArabicTrailing: Bool = false) -> some View {
        if matchesSearch(arabicText: arabicText, transliteration: transliteration, translation: translation) {
            AdhkarRow(
                arabicText: arabicText,
                transliteration: transliteration,
                translation: translation,
                alignArabicTrailing: alignArabicTrailing,
                useQuranicFont: settings.useQuranicArabicFontForAdhkarDua
            )
        }
    }

    private var introductionSection: some View {
        Section(header: Text("BEGINNING")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Common Adhkar")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Short remembrances to keep your heart connected to Allah throughout the day.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("“Unquestionably, by the remembrance of Allah hearts are assured.” (Quran 13:28)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.1))
            )
            .padding(-4)
        }
    }

    @ViewBuilder
    private var adhkarRows: some View {
        filteredAdhkarRow(arabicText: "سُبحَانَ اللَّهِ", transliteration: "SubhanAllah", translation: "Glory be to Allah")
        filteredAdhkarRow(arabicText: "ٱلـحَمدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah")
        filteredAdhkarRow(arabicText: "اللَّهُ أَكبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest")
        filteredAdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illallah", translation: "There is no deity worthy of worship except Allah")
        filteredAdhkarRow(arabicText: "أَستَغفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah")
        filteredAdhkarRow(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah")
        filteredAdhkarRow(arabicText: "ٱلـحَمدُ لِلَّهِ رَبِّ ٱلعَٰلَمِينَ", transliteration: "Alhamdulillahi rabbil 'alamin", translation: "Praise be to Allah, the Lord of all the worlds")
        filteredAdhkarRow(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ سُبحَانَ اللَّهِ العَظِيمِ", transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great")
        filteredAdhkarRow(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family")
        filteredAdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ ٱلمُلكُ وَلَهُ ٱلـحَمدُ وَهُوَ عَلَىٰ كُلِّ شَيءٍ قَدِيرٌ", transliteration: "La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things")
    }

    private var virtuesSection: some View {
        Section(header: Text("ENDING REFLECTION")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("The Virtues of Dhikr")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Dhikr revives the heart, protects the soul, and keeps a believer steady in trials. Every remembrance is light on the tongue and heavy on the scale.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            ReflectionCard(
                title: "Quranic Reminders",
                lines: [
                    "So remember Me; I will remember you. (Quran 2:152)",
                    "By the remembrance of Allah hearts are assured. (Quran 13:28)",
                    "Remember Allah with much remembrance. (Quran 33:41)"
                ],
                accent: settings.accentColor.color
            )

            ReflectionCard(
                title: "Prophetic Encouragement",
                lines: [
                    "Dua and Dhikr are among the most beloved deeds to Allah.",
                    "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem are beloved and weighty.",
                    "Keep your tongue moist with the remembrance of Allah."
                ],
                accent: settings.accentColor.color
            )

            Text("Make dhikr a daily rhythm: morning, evening, after salah, before sleep, and during ordinary moments. A heart that remembers Allah does not stay empty.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

private struct ReflectionCard: View {
    let title: String
    let lines: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(accent)

            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(-4)
    }
}

#Preview {
    AlIslamPreviewContainer {
        AdhkarView()
    }
}
