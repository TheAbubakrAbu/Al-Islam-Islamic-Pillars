import SwiftUI

struct DuaView: View {
    @EnvironmentObject var settings: Settings
    @State private var searchText = ""

    var body: some View {
        List {
            introductionSection
            duaRows
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
        #else
        .searchable(text: $searchText)
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .navigationTitle("Common Duas")
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
    private func filteredDuaRow(arabicText: String, transliteration: String, translation: String, alignArabicTrailing: Bool = true) -> some View {
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
        Section(header: Text("SUPPLICATIONS TO ALLAH")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Short, daily supplications that keep your heart connected to Allah in every situation.")
                    .font(.caption)
                    .foregroundColor(.primary)

                Text("“Call upon Me (Dua); I will respond to you.” (Quran 40:60)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }

    @ViewBuilder
    private var duaRows: some View {
        filteredDuaRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن زَوَالِ نِعمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ وَفُجَاءَةِ نِقمَتِكَ وَجَمِيعِ سَخَطِكَ", transliteration: "Allahumma inni a'udhu bika min zawali ni'matika wa tahawwuli 'afiyatika wa fuja'ati niqmatika wa jamee' sakhatika", translation: "O Allah, I seek refuge in You from the removal of Your blessings, changing of Your protection, sudden wrath, and all of Your displeasure")
        filteredDuaRow(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ العَفوَ وَالعَافِيَةَ فِي الدُّنيَا وَالآخِرَةِ", transliteration: "Allahumma inni as'aluka al-'afwa wal-'afiyah fi ad-dunya wal-akhirah", translation: "O Allah, I ask You for forgiveness and well-being in this life and the hereafter")
        filteredDuaRow(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ الهُدَى وَالتُّقَى وَالعَفَافَ وَالغِنَى", transliteration: "Allahumma inni as'aluka al-huda wa at-tuqaa wal-'afaafa wal-ghina", translation: "O Allah, I ask You for guidance, righteousness, chastity, and sufficiency")
        filteredDuaRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الكُفرِ وَالفَقرِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ", transliteration: "Allahumma inni a'udhu bika min al-kufr wal-faqr wa a'udhu bika min 'adhab al-qabr", translation: "O Allah, I seek refuge in You from disbelief, poverty, and the punishment of the grave")
        filteredDuaRow(arabicText: "اللَّهُمَّ مَا أَصبَحَ بِي مِن نِعمَةٍ أَو بِأَحَدٍ مِن خَلقِكَ فَمِنكَ وَحدَكَ لَا شَرِيكَ لَكَ فَلَكَ الحَمدُ وَلَكَ الشُّكرُ", transliteration: "Allahumma ma asbaha bi min ni'matin, aw bi ahadin min khalqika, faminka wahdaka la sharika laka, falaka alhamdu wa laka ash-shukr", translation: "O Allah, whatever blessings I or any of Your creatures rose up with, is from You alone, without partner, so for You is all praise and unto You all thanks.")
        filteredDuaRow(arabicText: "رَبِّ اشرَح لِي صَدرِي وَيَسِّر لِي أَمرِي", transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "O my Lord, expand for me my chest, and ease for me my task.")
        filteredDuaRow(arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكرِكَ وَشُكرِكَ وَحُسنِ عِبَادَتِكَ", transliteration: "Allahumma a'innee ala dhikrika wa shukrika wa husni ibadatika", translation: "O Allah, assist me in remembering You, in thanking You, and in worshipping You in the best manner.")
        filteredDuaRow(arabicText: "رَبَّنَا آتِنَا فِي الدُّنيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", transliteration: "Rabbanaa atinaa fid-dunya hasanatan wa fil aakhirati hasanatan wa qinaa 'adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.")
        filteredDuaRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن عَجزِ وَالكَسَلِ وَالجُبنِ وَالهَرَمِ وَالبُخلِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ وَمِن فِتنَةِ المَحيَا وَالمَمَاتِ", transliteration: "Allahumma inni a'udhu bika min al-'ajzi wal-kasali wal-jubni wal-harami wal-bukhli, wa a'udhu bika min 'adhab al-qabr, wa min fitnat al-mahya wal-mamat", translation: "O Allah, I seek refuge in You from weakness and laziness, miserliness and cowardice, the burden of debts and from being overpowered by men. I seek refuge in You from the punishment of the grave and from the trials and tribulations of life and death.")
        filteredDuaRow(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ عِلمًا نَافِعًا وَرِزقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted.")
        filteredDuaRow(
            arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الحَيُّ القَيُّومُ ۚ لَا تَأخُذُهُ سِنَةٌ وَلَا نَومٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الأَرضِ ۗ مَن ذَا الَّذِي يَشفَعُ عِندَهُ إِلَّا بِإِذنِهِ ۚ يَعلَمُ مَا بَينَ أَيدِيهِم وَمَا خَلفَهُم ۖ وَلَا يُحِيطُونَ بِشَيءٍ مِّن عِلمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرسِيُّهُ السَّمَاوَاتِ وَالأَرضَ ۖ وَلَا يَئُودُهُ حِفظُهُمَا ۚ وَهُوَ العَلِيُّ العَظِيمُ",
            transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta’khudhuhu sinatun wa la nawm. Lahu ma fi as-samawati wa ma fi al-ard. Man dha allathee yashfa'u 'indahu illa bi-idhnihi? Ya’lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay’in min ‘ilmihi illa bima sha’. Wasi’a kursiyyuhu as-samawati wal-ard, wa la ya’uduhu hifzuhuma, wa Huwal ‘Aliyyul-‘Azim (2:255).",
            translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great (2:255)."
        )
    }

    private var virtuesSection: some View {
        Section(header: Text("ENDING REFLECTION")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("The Virtues of Dua")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Dua is a direct connection with Allah. No sincere call is lost: it is answered now, delayed for wisdom, or stored as reward.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            DuaReflectionCard(
                title: "Quranic Promise",
                lines: [
                    "Call upon Me; I will respond to you. (Quran 40:60)",
                    "I am near and I respond to the caller when he calls upon Me. (Quran 2:186)",
                    "Who responds to the desperate one when he calls? (Quran 27:62)"
                ],
                accent: settings.accentColor.color
            )

            DuaReflectionCard(
                title: "Prophetic Guidance",
                lines: [
                    "Dua is worship.",
                    "Nothing is more noble to Allah than dua.",
                    "A sincere dua is never wasted: immediate answer, deferred reward, or harm removed."
                ],
                accent: settings.accentColor.color
            )

            Text("Keep making dua in ease and hardship, in private and public, with certainty and patience. The One you call is always near.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

private struct DuaReflectionCard: View {
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
    }
}

#Preview {
    AlIslamPreviewContainer {
        DuaView()
    }
}
