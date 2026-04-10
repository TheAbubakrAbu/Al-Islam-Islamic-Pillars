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
        VStack(alignment: .leading, spacing: 10) {
            Text(arabicText)
                .font(useQuranicFont ? .custom(settings.fontArabic, size: 30) : .title2)
                .foregroundColor(settings.accentColor.color)
                .multilineTextAlignment(alignArabicTrailing ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: alignArabicTrailing ? .trailing : .leading)
                .padding(.vertical, -10)

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
            etymologySection
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
        Section(header: Text("REMEMBRANCES OF ALLAH")) {
             Text("Short remembrances to keep your heart connected to Allah throughout the day.")
                 .font(.subheadline)
                 .foregroundColor(.primary)
                  
             Text("\"Unquestionably, by the remembrance of Allah hearts are assured.\" (Quran 13:28)")
                 .font(.caption)
                 .foregroundColor(.secondary)
        }
    }

    private var etymologySection: some View {
        Section(header: Text("ETYMOLOGY")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Arabic root: ذ ك ر (dh-k-r)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)

                Text("Core meaning: to remember, to mention, to be mindful")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("Dhikr literally means remembrance or mentioning. It includes saying SubhanAllah, Alhamdulillah, Allahu Akbar, reciting the Quran, and keeping Allah always present in the heart and tongue.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
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
        filteredAdhkarRow(arabicText: "ٱلحَمدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah")
        filteredAdhkarRow(arabicText: "اللَّهُ أَكبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest")
        filteredAdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illallah", translation: "There is no deity worthy of worship except Allah")
        filteredAdhkarRow(arabicText: "أَستَغفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah")
        filteredAdhkarRow(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah")
        filteredAdhkarRow(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ سُبحَانَ اللَّهِ العَظِيمِ", transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great")
        filteredAdhkarRow(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family")
        filteredAdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ ٱلمُلكُ وَلَهُ ٱلحَمدُ وَهُوَ عَلَىٰ كُلِّ شَيءٍ قَدِيرٌ", transliteration: "La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things")
    }

    private var virtuesSection: some View {
        Section(header: Text("VIRTUES OF DHIKR")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dhikr is a continuous awareness of Allah. It revives the heart, protects the soul, and keeps a believer steady in trials.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            ReflectionCard(
                title: "Quranic Reminders",
                lines: [
                    "So remember Me; I will remember you. And be grateful to Me and do not deny Me. (Quran 2:152)",
                    "Unquestionably, by the remembrance of Allah hearts are assured. (Quran 13:28)",
                    "O you who have believed, remember Allah with much remembrance. (Quran 33:41)",
                    "Indeed, the Muslim men and Muslim women, the believing men and believing women, the obedient men and obedient women, the truthful men and truthful women, the patient men and patient women, the humble men and humble women, the charitable men and charitable women, the fasting men and fasting women, the men who guard their private parts and the women who do so, and the men who remember Allah often and the women who do so - for them Allah has prepared forgiveness and a great reward. (Quran 33:35)"
                ],
                accent: settings.accentColor.color
            )

            ReflectionCard(
                title: "Prophetic Encouragement",
                lines: [
                    "The best of deeds is the remembrance of Allah.",
                    "Two phrases are light on the tongue and heavy on the scale: SubhanAllahi wa bihamdihi, SubhanAllahil Adheem.",
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
        .padding()
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
