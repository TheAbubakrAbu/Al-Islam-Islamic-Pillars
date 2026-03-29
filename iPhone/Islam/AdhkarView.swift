import SwiftUI

struct AdhkarRow: View {
    @EnvironmentObject var settings: Settings

    let arabicText: String
    let transliteration: String
    let translation: String

    var body: some View {
        Section {
            rowContent
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading) {
            Text(arabicText)
                .font(.title2)
                .foregroundColor(settings.accentColor.color)

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

    var body: some View {
        List {
            introductionSection
            adhkarRows
            virtuesSection
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .navigationTitle("Common Adhkar")
    }

    private var introductionSection: some View {
        Section(header: Text("REMEMBRANCES OF ALLAH ﷻ‎")) {
            Text("Adhkar (plural of Dhikr) are short phrases of remembrance taught by Prophet Muhammad ﷺ. They bring peace, purify the heart, and draw one closer to Allah.\n\nAllah ﷻ says: “Unquestionably, by the remembrance of Allah hearts are assured” (Quran 13:28).\nProphet Muhammad ﷺ said: “Keep your tongue moist with the remembrance of Allah” (Tirmidhi 3375).")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var adhkarRows: some View {
        AdhkarRow(arabicText: "سُبحَانَ اللَّهِ", transliteration: "SubhanAllah", translation: "Glory be to Allah")
        AdhkarRow(arabicText: "ٱلـحَمدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah")
        AdhkarRow(arabicText: "اللَّهُ أَكبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest")
        AdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illallah", translation: "There is no deity worthy of worship except Allah")
        AdhkarRow(arabicText: "أَستَغفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah")
        AdhkarRow(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah")
        AdhkarRow(arabicText: "ٱلـحَمدُ لِلَّهِ رَبِّ ٱلعَٰلَمِينَ", transliteration: "Alhamdulillahi rabbil 'alamin", translation: "Praise be to Allah, the Lord of all the worlds")
        AdhkarRow(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ، سُبحَانَ اللَّهِ العَظِيمِ", transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great")
        AdhkarRow(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family")
        AdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلمُلكُ وَلَهُ ٱلـحَمدُ، وَهُوَ عَلَىٰ كُلِّ شَيءٍ قَدِيرٌ", transliteration: "La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things")
    }

    private var virtuesSection: some View {
        Section(header: Text("VIRTUES OF DHIKR")) {
            Text("Dhikr (ذِكر) is a powerful spiritual act that nurtures the soul, polishes the heart, and brings one into divine presence. It is a means of drawing near to Allah ﷻ, increasing one’s reward, and protecting oneself from the whispers of Shaytaan. Dhikr revives the heart and is beloved to the Most Merciful.")
                .font(.subheadline)
                .foregroundColor(.primary)

            Group {
                Text("❖ “So remember Me; I will remember you. And be grateful to Me and do not deny Me” (Quran 2:152).")
                Text("❖ “Those who have believed and whose hearts are assured by the remembrance of Allah. Unquestionably, by the remembrance of Allah hearts are assured” (Quran 13:28).")
                Text("❖ “O you who have believed, remember Allah with much remembrance” (Quran 33:41).")
                Text("❖ “And remember your Lord much and exalt [Him with praise] in the evening and the morning” (Quran 3:41).")
                Text("❖ “The men who remember Allah often and the women who do so - for them Allah has prepared forgiveness and a great reward” (Quran 33:35).")
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)

            Group {
                Text("❖ Prophet Muhammad ﷺ said: “Shall I not tell you of the best of your deeds, which is the purest to your King, which raises you among your ranks, which is better for you than spending gold and money in charity...? It is the remembrance of Allah Almighty” (Tirmidhi 3377).")
                Text("❖ Prophet Muhammad ﷺ said: “There are two phrases which are light on the tongue, heavy in the balance, and beloved to the Most Merciful: *SubhanAllahi wa bihamdihi, SubhanAllahil Adheem* (Glory is to Allah and praise is to Him. Glory is to Allah, the Most Great)” (Bukhari 6406).")
                Text("❖ Prophet Muhammad ﷺ said: “Whoever says: *La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir* (None has the right to be worshipped but Allah, the Alone Who has no partner. His is the Dominion and His is the Praise, and He is over all things All-Powerful) one hundred times in a day will have the reward of freeing ten slaves, one hundred good deeds will be recorded for him, one hundred sins will be erased, and he will be protected from Satan until evening. No one will surpass him except someone who has done more” (Bukhari 3293).")
                Text("❖ Prophet Muhammad ﷺ said: “The example of the one who celebrates the Praises of his Lord and the one who does not celebrate His Praises is like the living and the dead” (Bukhari 6407).")
                Text("❖ Prophet Muhammad ﷺ said: “No people gather to remember Allah Almighty but that the angels surround them, mercy covers them, tranquility descends upon them, and Allah mentions them to those near Him” (Muslim 2700).")
                Text("❖ Prophet Muhammad ﷺ said: “Keep your tongue moist with the remembrance of Allah” (Tirmidhi 3375).")
                Text("❖ Prophet Muhammad ﷺ said: “Shall I not tell you something better than a servant? When you go to bed, say: *SubhanAllah* 33 times (Glory be to Allah), *Alhamdulillah* 33 times (Praise be to Allah), and *Allahu Akbar* 34 times (Allah is the Greatest)” (Bukhari 6318).")
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)

            Text("Dhikr is the heartbeat of the believer. It brings light to the face, peace to the soul, and strength to endure trials. It is a shield in times of hardship and a ladder to the nearness of Allah ﷻ.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        AdhkarView()
    }
}
