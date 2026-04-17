import SwiftUI

struct TajweedFoundationsView: View {
    @EnvironmentObject var settings: Settings
    @State private var showTajweedLegend = false

    private let topics: [String] = [
        "Improving Your Recitation",
        "Foundations",
        "Tajweed in the Mushaf",
        "Makharij (Articulation)",
        "Heavy and Light",
        "Shams and Qamar - Al",
        "Madd (Elongation)",
        "Qalqalah (Echo)",
        "Idgham / Ikhfaa",
        "Waqf (Stopping)"
    ]

    var body: some View {
        List {
            Section("TAJWEED LEGEND") {
                #if os(iOS)
                Button {
                    settings.hapticFeedback()
                    showTajweedLegend = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Reference Guide")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                        Text("Simple way to view basic Hafs An Assim Tajweed rules with colors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                #endif
            }

            Section("OVERVIEW") {
                Text("Tajweed, Makharij, and Pronunciation")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("This guide applies specifically to riwayat Hafs an Asim, which is the most widely recited qiraah in the world today and the standard riwayah used in the majority of printed mushafs.")
                    .font(.body)

                Text("Tajweed (تجويد) refers to the science and practice of reciting the Quran correctly and beautifully, by giving each letter its proper articulation and characteristics. Linguistically, the word tajweed comes from the Arabic root ج-و-د (j-w-d), meaning \"to improve,\" \"to make excellent,\" or \"to perfect.\" In the context of the Quran, it means reciting the words of Allah as they were revealed precisely, clearly, and with care.")
                    .font(.body)

                Text("Recitation (قراءة qiraah or تلاوة tilawah) refers to the act of reading the Quran. While qiraah simply means \"reading,\" tilawah carries a deeper meaning of reciting with attentiveness, reflection, and adherence to proper method. Quranic recitation is not just reading text; it is the transmission of a preserved oral tradition passed down from the Prophet ﷺ through generations.")
                    .font(.body)

                Text("Pronunciation in Quranic recitation is governed by two key components: makharij (مخارج الحروف) and sifat (صفات الحروف). Makharij are the points of articulation, where each letter originates in the mouth or throat, while sifat are the characteristics of those letters, such as heaviness (tafkhim), lightness (tarqiq), or echoing (qalqalah). Together, they ensure that each letter is pronounced distinctly and correctly.")
                    .font(.body)

                Text("These elements are essential because even slight changes in pronunciation can alter meanings. Tajweed preserves not only the beauty of the Quran, but also its accuracy and integrity. The Quran was revealed to be recited, and Allah commands:")
                    .font(.body)

                VStack(alignment: .leading) {
                    Text("And recite the Quran with measured recitation (tartil).")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)
                    
                    Text("(73:4)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("For this reason, learning and applying tajweed is a means of preserving the exact words of the Quran as they were revealed and recited by the Prophet ﷺ, ensuring that its message remains unchanged across generations.")
                    .font(.body)
            }

            Section("WHY LEARN TAJWEED?") {
                Text("Honoring the Quran: The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text. By learning Tajweed, you follow the Prophet ﷺ who recited with the utmost clarity and eloquence.")
                    .font(.body)

                Text("Preventing Misunderstandings: By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. In some cases, even changing a single sound or stretching a vowel can result in an entirely different meaning.")
                    .font(.body)

                Text("Enhancing Spiritual Connection: Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required encourages mindfulness and deeper reflection on the meaning of the verses, making your recitation more immersive and meaningful.")
                    .font(.body)

                Text("Following the Sunnah: The Prophet Muhammad ﷺ emphasized the importance of reciting the Quran correctly, saying: \"Whoever does not recite the Quran in a pleasant manner is not of us.\" By learning Tajweed, you honor his teachings and example.")
                    .font(.body)
            }

            Section("HOW TO START LEARNING") {
                Text("Learning Tajweed might seem challenging at first, but there are many resources available today to make the process easier. Traditionally, learning Tajweed was done with a teacher who could guide you through the articulation points and characteristics of each letter.")
                    .font(.body)

                Text("Now, in addition to teachers, there are online platforms, videos, and books that provide step-by-step lessons. For those starting out, focus on mastering the basic rules first and gradually build your skills over time. Practicing consistently is key—recording your recitation can help you catch mistakes and improve pronunciation.")
                    .font(.body)

                Text("Many learners find benefit in joining Tajweed classes or study groups, where they can receive feedback and support from others on the same journey.")
                    .font(.body)
            }

            Section("APPLICABILITY TO QIRAAT") {
                Text("Other riwayat, such as Warsh an Nafi, Khalaf an Hamzah, and others, may differ slightly in their application of tajweed rules, including elongations (madd), treatment of hamzah, and certain pronunciation details. These differences stem from authentic variations rooted in classical Arabic dialects and were transmitted through reliable chains of recitation.")
                    .font(.body)

                Text("As a result, some rules explained in this guide may not apply identically to other riwayat. These variations in tajweed application and pronunciation reflect the diversity of classical Arabic dialects that were all correctly recited and approved by the Prophet ﷺ, and have been preserved exactly through continuous transmission. They highlight the richness, flexibility, and authenticity of the Quranic recitation tradition.")
                    .font(.body)
            }

            Section("LEARN MORE") {
                Text("Learn More About Qiraat, Riwayat, and Ahruf")
                    .font(.subheadline.weight(.semibold))

                Text("See below and in \(AppIdentifiers.toolsView) View > Islamic Pillars and Basics.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                NavigationLink(destination: QuranPillarView()) {
                    Text("What is the Quran?")
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: TajweedView()) {
                    Text("What is Tajweed?")
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: AhrufView()) {
                    Text("What are the 7 Ahruf?")
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: QiraatView()) {
                    Text("What are the 10 Qiraat?")
                        .foregroundColor(settings.accentColor.color)
                }
            }

            Section("TAJWEED TOPICS") {
                ForEach(topics, id: \.self) { topic in
                    NavigationLink(destination: destinationView(for: topic)) {
                        Text(topic)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("NOTE") {
                Text("This guide teaches Tajweed rules for Hafs An Assim recitation, the most widely used qiraah. Other qiraat (such as Warsh, Khalaf, etc.) may apply these rules slightly differently.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .navigationTitle("Tajweed Foundations")
            #if os(iOS)
            .sheet(isPresented: $showTajweedLegend) {
                NavigationView {
                    TajweedLegendView()
                }
            }
            #endif
    }

    @ViewBuilder
    private func destinationView(for topic: String) -> some View {
        if topic == "Improving Your Recitation" {
            TajweedImprovingRecitationView()
        } else if topic == "Foundations" {
            TajweedFoundationsTopicView()
        } else if topic == "Tajweed in the Mushaf" {
            TajweedInMushafView()
        } else if topic == "Makharij (Articulation)" {
            TajweedMakharijView()
        } else if topic == "Heavy and Light" {
            TajweedHeavyLightView()
        } else if topic == "Shams and Qamar - Al" {
            TajweedShamsQamarView()
        } else if topic == "Madd (Elongation)" {
            TajweedMaddView()
        } else if topic == "Qalqalah (Echo)" {
            TajweedQalqalahView()
        } else if topic == "Idgham / Ikhfaa" {
            TajweedIdghamIkhfaView()
        } else if topic == "Waqf (Stopping)" {
            TajweedWaqfView()
        } else {
            TajweedTopicPlaceholderView(title: topic)
        }
    }
}

private struct TajweedImprovingRecitationView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section("IMPROVING YOUR RECITATION") {
                Text("This guide on its own is not enough to fully develop strong tajweed and pronunciation. While it can introduce the rules and concepts, real improvement in Quranic recitation requires consistent practice, listening, and guidance from knowledgeable teachers.")
                    .font(.body)

                Text("Ideally, this guide should be used alongside a teacher who can listen to your recitation and correct your mistakes. Tajweed is refined through feedback and repetition, and many pronunciation errors are difficult to notice on your own. To truly benefit from this guide, approach the Quran with sincerity, humility, and love. Put your trust in Allah and be willing to learn.")
                    .font(.body)

                Text("You must also set aside arrogance and ego. Even if you believe your tajweed, voice, or makharij are good, there is always room to improve. The greatest reciters spent years refining their recitation. Below are three consistent practices that will help maximize both this guide and your learning of tajweed.")
                    .font(.body)
            }

            Section("THREE PRACTICES FOR IMPROVING TAJWEED") {
                Text("Three Practices for Improving Tajweed")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("1. PRACTICE RECITING ON YOUR OWN") {
                Text("Reading the Quran regularly on your own is essential. This type of practice helps with:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Increasing reading fluency and speed")
                    Text("Improving familiarity with words and verses")
                    Text("Experimenting with voice control and tone")
                    Text("Applying corrections you have learned")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("However, it is important to understand something: the phrase \"practice makes perfect\" is not true. Rather, perfect practice makes perfect. If someone repeatedly practices incorrect pronunciation or recites carelessly, they may reinforce mistakes instead of correcting them.")
                    .font(.body)

                Text("For this reason, solo practice should focus on:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading consistently")
                    Text("Reciting carefully with proper tajweed")
                    Text("Applying corrections learned from teachers or study")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself. But it cannot fully replace proper guidance.")
                    .font(.body)

                Text("This is similar to practicing a sport alone. Individual practice builds skill and stamina, but without proper technique, it will only take you so far. At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself.")
                    .font(.body)
            }

            Section("2. LISTEN TO SKILLED RECITERS") {
                Text("Listening to skilled reciters is one of the most powerful ways to improve pronunciation and rhythm. Many students benefit from listening to classical Egyptian reciters such as Sheikh Muhammad Siddiq Al-Minshawi and Sheikh Mahmoud Khalil Al-Hussary.")
                    .font(.body)

                Text("Both reciters are widely respected for their clarity, precision, and strong tajweed.")
                    .font(.body)

                Text("Their recordings typically come in two styles:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Murattal - a steady, clear recitation ideal for learning")
                    Text("Mujawwad - a slower, melodic recitation that emphasizes precision and beauty")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Try to find a reciter whose voice you genuinely enjoy listening to. Developing a connection with a reciter often deepens your love for the Quran and increases your motivation to recite. However, do not listen passively. Instead, actively engage with the recitation:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Follow along in the mushaf while listening")
                    Text("Read aloud with the reciter")
                    Text("Attempt to mimic his tajweed and pronunciation")
                    Text("Pay attention to letter articulation, elongation, and pauses")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This is similar to studying expert athletes, learning from masters by carefully observing how they perform. You may also benefit from educational tajweed resources such as Learn Arabic 101 or other structured lessons.")
                    .font(.body)
            }

            Section("3. PRACTICE WITH A TEACHER OR PARTNER") {
                Text("Practicing with someone knowledgeable in tajweed is one of the most effective ways to improve your recitation. A teacher or experienced student can hear mistakes that you will not notice yourself, including:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Incorrect makharij (points of articulation)")
                    Text("Subtle pronunciation errors")
                    Text("Improper elongation (madd)")
                    Text("Weak ghunnah or nasalization")
                    Text("Mistakes in stopping or continuation")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Corrections may sometimes feel repetitive or strict, but they are extremely valuable.")
                    .font(.body)

                Text("Even small refinements can significantly improve your recitation. The best tajweed is the recitation that is correct and refined in all aspects, both major and subtle.")
                    .font(.body)

                Text("Learning with a teacher is similar to training with a coach in sports. A coach observes your technique and gives personalized corrections that accelerate your improvement.")
                    .font(.body)

                Text("If a formal teacher is not available, try to practice with someone knowledgeable who has strong tajweed and is willing to listen to your recitation and offer corrections.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Improving Your Recitation")
    }
}

private struct TajweedFoundationsTopicView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section("NATURAL QURANIC RECITATION") {
                Text("Foundations of Natural Quranic Recitation")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Avoiding Overemphasis in Quranic Recitation | Correct Mouth and Lip Usage in Recitation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("One of the most common mistakes in Quranic recitation is overemphasis: exaggerating mouth movements, stretching the lips sideways, or forcing sounds in a way that is unnatural to Arabic speech. Correct tajweed is meant to preserve clarity and authenticity.")
                    .font(.body)
            }

            Section("GENERAL MOUTH AND LIP RULE") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lips move up and down only")
                    Text("Avoid side stretching or exaggerated shaping")
                    Text("The tongue and throat do most of the work")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("When recited correctly, Quranic Arabic should sound smooth, balanced, and natural, similar to careful classical Arabic speech.")
                    .font(.body)
            }

            Section("1. DAMMAH-RELATED SOUNDS (ُ ٌ و)") {
                Text("For all sounds related to dammah, the lips must round and project slightly forward to produce a true \"u\" sound.")
                    .font(.body)

                Text("This is the only time the lips clearly point outward.")
                    .font(.body)

                Text("Applies To: Dammah (ـُ), Dammatayn (ـٌ), Waw sakinah preceded by dammah (ـُو)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. MIM (م) — LIP CLOSURE") {
                Text("The letter mim (م) is a bilabial letter, meaning it is produced using both lips.")
                    .font(.body)

                Text("Think of the lips as folding together, not squeezing.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Foundations")
    }
}

private struct TajweedInMushafView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }
    
    private var arabicFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("TAJWEED IN THE MUSHAF") {
                Text("Reading Tajweed Directly from the Mushaf")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Learning to See Tajweed in the Mushaf Itself")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Even without a color-coded mushaf, tajweed rules are visible directly in the text. The Quran is written in a way that signals when a sound should be held, merged, hidden, or pronounced clearly, if you know what to look for.")
                    .font(.body)

                Text("This section teaches you how to recognize tajweed visually, before memorizing specific rules.")
                    .font(.body)
            }

            Section("1. LETTERS WITHOUT SUKUN (EXCLUDING MADD)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If a letter:")
                    Text("has no sukun")
                    Text("and is not a madd letter (ا و ي)")
                    Text("then that letter must be held, and some tajweed rule applies.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This usually means:")
                    .font(.body)
                Text("Ghunnah, Ikhfaa, Idghaam, Iqlaab, and similar rules.")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedExampleRow(
                        arabic: "مِنْ",
                        middle: "Nun has sukun",
                        trailing: "Pronounce clearly",
                        arabicFont: arabicFont
                    )

                    TajweedExampleRow(
                        arabic: "مَن يَقُول",
                        middle: "No sukun on ن",
                        trailing: "Merge (idghaam)",
                        arabicFont: arabicFont
                    )

                    TajweedExampleRow(
                        arabic: "عَلِيمٌ",
                        middle: "Tanwin + no visible sukun",
                        trailing: "Apply rule",
                        arabicFont: arabicFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If there is no sukun, the sound does not pass quickly.")
                    .font(.body)
            }

            Section("2. TANWIN SHAPE") {
                Text("Tanwin always ends in a hidden nun sakinah, which is why its shape matters.")
                    .font(.body)
            }

            Section("A. PARALLEL TANWIN → IDHAAR") {
                Text("When the two tanwin strokes are parallel, the nun is pronounced clearly.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بًا", english: "ban", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "بٌ", english: "bun", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "بٍ", english: "bin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "كِتَابًا عَرَبِيًّا", english: "kitaban arabiyyan", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("You hear a full, clear \"n\" sound.")
                    .font(.body)
            }

            Section("B. STAGGERED / CONNECTED TANWIN") {
                Text("When tanwin marks appear staggered, connected, or visually altered, this usually indicates Idghaam, Ikhfaa, or Iqlaab.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "أُمَّةٞ قَدۡ",
                        pronunciation: "ummatun qad",
                        rule: "Special Dammatayn",
                        arabicFont: arabicFont
                    )

                    TajweedRuleRow(
                        arabic: "صِرَٰطٖ مُّسۡتَقِيمٖا",
                        pronunciation: "siraatim mustaqeemaa",
                        rule: "Special Kasratayn",
                        arabicFont: arabicFont
                    )

                    TajweedRuleRow(
                        arabic: "أُمَّةٗ وَسَطٗا",
                        pronunciation: "ummatan wasatan",
                        rule: "Special Fathatayn",
                        arabicFont: arabicFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("The mushaf is telling you: do not pronounce the nun normally here.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Important clarification: not every mushaf shows tanwin shapes identically, but the principle remains the same. If the tanwin does not look standard, slow down and apply a rule.")
                    .font(.body)
            }

            Section("3. THE LAAM OF \"AL-\" (ٱلـ)") {
                Text("The definite article \"al-\" also signals pronunciation through markings.")
                    .font(.body)
            }

            Section("A. SUKUN ON LAAM (QAMARIYYAH)") {
                VStack(alignment: .leading, spacing: 10) {
                    TajweedPairRow(arabic: "ٱلْقَمَر", english: "al-qamar", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْكِتَاب", english: "al-kitab", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْهُدَى", english: "al-huda", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("B. NO SUKUN ON LAAM (SHAMSIYYAH)") {
                Text("The laam merges into the next letter.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 10) {
                    TajweedPairRow(arabic: "ٱلشَّمْس", english: "ash-shams", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلنَّاس", english: "an-nas", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلرَّحْمَٰن", english: "ar-rahman", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If you do not see a sukun, the laam is not read.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Tajweed in the Mushaf")
    }
}

private struct TajweedMakharijView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }
    
    private var arabicFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("MAKHARIJ") {
                Text("Makharij al-Huruf (Articulation of Letters)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Makharij are the physical points of articulation from which Arabic letters are pronounced. Correct makharij are the foundation of tajweed. If the letter does not come from its proper place, no amount of rules will fix the sound.")
                    .font(.body)

                Text("This section focuses on awareness, not memorization. The goal is to know where a sound comes from and what moves to produce it.")
                    .font(.body)

                Image("Makharij1")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(24)

                Image("Makharij2")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(24)

                Text("Use these diagrams as references, not something to stare at while reciting. Over time, correct makharij become muscle memory.")
                    .font(.body)
            }

            Section("RECOMMENDED PLAYLIST") {
                Text("Use a clear, slow pronunciation playlist such as Learn Arabic 101 (Makharij series). Focus on:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Isolated letter sounds")
                    Text("Minimal exaggeration")
                    Text("Clear mouth positioning")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Listen -> imitate -> repeat aloud. Silent learning does not work for makharij.")
                    .font(.body)

                if let url = URL(string: "https://www.youtube.com/watch?v=-YrfRpwFMe8&list=PL6TlMIZ5ylgpmlnN3EpkOec0tJ8OJZ5re") {
                    Link("Open Makharij Playlist", destination: url)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }

            Section("PRIMARY AREAS OF ARTICULATION") {
                Text("For learning purposes, we group makharij into three main zones.")
                    .font(.body)
            }

            Section("1. THROAT LETTERS (الحروف الحلقية)") {
                Text("These letters originate from the throat, not the tongue.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ء هـ ع ح غ خ")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Sub-Zones (for awareness)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deep throat: ء هـ")
                    Text("Middle throat: ع ح")
                    Text("Upper throat: غ خ")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Key Notes")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("These letters are clear and open")
                    Text("No nasalization")
                    Text("Do not squeeze the throat")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أَحَد", english: "ahad", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَعْبُدُ", english: "naabudu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "غَفُور", english: "ghafur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "خَالِد", english: "khalid", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Common mistake: replacing ع with أ")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: clear throat engagement")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("2. TONGUE LETTERS (أغلب الحروف)") {
                Text("Most Arabic letters come from the tongue, but different parts of the tongue.")
                    .font(.body)

                Text("Tongue Zones (Simplified)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Back of tongue: ق ك")
                    Text("Middle of tongue: ج ش ي")
                    Text("Sides of tongue: ض")
                    Text("Tip of tongue: ت د ط ن ل ر س ز ص ث ذ ظ")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Key Notes")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Small shifts in tongue position matter")
                    Text("Do not force pressure")
                    Text("Accuracy > strength")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قُلْ", english: "qul", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سِرَاط", english: "sirat", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رَبِّ", english: "rabbi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Common mistake: collapsing multiple letters into one sound")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: distinct articulation for each letter")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("3. LIP LETTERS (الحروف الشفوية)") {
                Text("These letters are produced using the lips.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ب م ف")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("How They Work")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ب: full lip closure")
                    Text("م: lip closure + nasal sound")
                    Text("ف: upper teeth lightly touch lower lip")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بَصِير", english: "basir", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "أَمْر", english: "amr", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fihi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Common mistake: weak or lazy lip contact")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: gentle, controlled movement")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("IMPORTANT PRACTICE ADVICE") {
                Text("Makharij are learned by sound, not sight.")
                    .font(.body)

                Text("If you cannot hear the difference, slow down and exaggerate slightly during practice, then return to natural recitation.")
                    .font(.body)

                Text("Correct makharij preserve the Quran exactly as it was revealed.")
                    .font(.body)

                Text("Tajweed rules refine the sound. Makharij create it.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Makharij")
    }
}

private struct TajweedHeavyLightView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Section("HEAVY AND LIGHT") {
                Text("Heavy and Light Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Arabic letters differ in weight (heavy tafkhim vs light tarqiq). Some letters are always heavy, some are always light, and some are conditional, meaning the weight changes based on context.")
                    .font(.body)

                Text("Correct letter weight is essential for accurate pronunciation and natural recitation.")
                    .font(.body)
            }

            Section("1. HEAVY LETTERS (تفخيم)") {
                Text("These letters are always heavy, regardless of the vowel.")
                    .font(.body)

                Text("Always Heavy Letters")
                    .font(.subheadline.weight(.semibold))

                Text("خ ص ض غ ط ق ظ")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("They are pronounced with:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("The back of the tongue raised")
                    Text("A full, deep sound")
                    Text("No thinning, even with kasrah")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قَالَ", english: "qala", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "صِرَاط", english: "sirat", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "طَبَعَ", english: "tabaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "غَفُور", english: "ghafur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "خَالِد", english: "khalid", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("2. LIGHT LETTERS (ترقيق)") {
                Text("These letters are always light and never pronounced heavy.")
                    .font(.body)

                Text("Always Light Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ب ت ث ج ح د ذ ز س ش ف ك ل م ن هـ و ي")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("They are pronounced with:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A relaxed tongue")
                    Text("No back-tongue elevation")
                    Text("Clear, sharp articulation")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بِسْم", english: "bism", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَعِيم", english: "naim", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سَبِيل", english: "sabil", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَوْم", english: "yawm", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fihi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Note: Laam (ل) and waw (و) are light by default, but laam becomes conditional in one specific case: Allah.")
                    .font(.body)
            }

            Section("3. CONDITIONAL LETTERS") {
                Text("These letters change weight depending on vowels or surrounding letters.")
                    .font(.body)
            }

            Section("A. RAA (ر)") {
                Text("The weight of raa depends on the vowel on the raa itself.")
                    .font(.body)

                Text("Heavy Raa")
                    .font(.subheadline.weight(.semibold))

                Text("With fathah (ـَ) or dammah (ـُ)")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "رَبِّ", english: "rabbi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رُزِقُوا", english: "ruziqu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَرَأَ", english: "qaraa", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Light Raa")
                    .font(.subheadline.weight(.semibold))

                Text("With kasrah (ـِ)")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "فِرْعَوْن", english: "firawn", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رِجَال", english: "rijal", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "شِرْعَة", english: "shirah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Rule of thumb: look at the vowel on the raa, not the surrounding letters.")
                    .font(.body)
            }

            Section("B. LAAM (ل)") {
                Text("The letter laam is always light, except in the word Allah (ٱللَّه).")
                    .font(.body)

                Text("Heavy Laam (Only in \"Allah\")")
                    .font(.subheadline.weight(.semibold))

                Text("When preceded by fathah or dammah:")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱللَّهُ", english: "Allahu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَالَ ٱللَّهُ", english: "qala Allahu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَصْرُ ٱللَّهِ", english: "nasru Allahi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Light Laam (After Kasrah)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بِٱللَّهِ", english: "billahi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "لِلَّهِ", english: "lillahi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("C. ALIF (ا)") {
                Text("Alif itself has no sound; it inherits the weight of the letter before it.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("After a heavy letter -> alif sounds heavy")
                    Text("After a light letter -> alif sounds light")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedWhyRow(arabic: "قَالَ", english: "qala", why: "Heavy letter (ق)", arabicFont: arabicHeadlineFont)
                    TajweedWhyRow(arabic: "صَادِق", english: "sadiq", why: "Heavy letter (ص)", arabicFont: arabicHeadlineFont)
                    TajweedWhyRow(arabic: "كَانَ", english: "kana", why: "Light letter (ك)", arabicFont: arabicHeadlineFont)
                    TajweedWhyRow(arabic: "نَاس", english: "nas", why: "Light letter (ن)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Wrong: making alif heavy by itself")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: alif follows, never leads")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Heavy and Light")
    }
}

private struct TajweedShamsQamarView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Section("SHAMS AND QAMAR") {
                Text("Shamsiyyah and Qamariyyah Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("The Definite Article \"Al-\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("When the definite article ٱلـ (al-) appears before a noun, the pronunciation of the laam (ل) depends on the first letter of the word that follows.")
                    .font(.body)

                Text("The mushaf clearly indicates this through shaddah or sukun.")
                    .font(.body)
            }

            Section("1. QAMARIYYAH (MOON LETTERS)") {
                Text("With qamariyyah letters, the laam is pronounced clearly.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("The laam has a sukun (ٱلْ)")
                    Text("The sound is al-")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qamariyyah Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ا ب ج ح خ ع غ ف ق ك م هـ و ي")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلْقَمَر", english: "al-qamar", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْكِتَاب", english: "al-kitab", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْحَقّ", english: "al-haqq", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْغَفُور", english: "al-ghafur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْيَوْم", english: "al-yawm", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Incorrect: dropping the laam")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: pronouncing al-")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("2. SHAMSIYYAH (SUN LETTERS)") {
                Text("With shamsiyyah letters, the laam is not pronounced. Instead, it merges into the following letter, which is doubled (shown by a shaddah).")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("No sukun on the laam")
                    Text("The next letter has a shaddah")
                    Text("Pronounce the word as if it begins with the doubled letter")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Shamsiyyah Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ت ث د ذ ر ز س ش ص ض ط ظ ل ن")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلشَّمْس", english: "ash-shams", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلنَّاس", english: "an-nas", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلرَّحْمَٰن", english: "ar-rahman", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلصِّرَاط", english: "as-sirat", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلتَّوْبَة", english: "at-tawbah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Incorrect: al-shams")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: ash-shams")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("IMPORTANT NOTES") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This rule applies only to the definite article ٱلـ, not to every laam.")
                    Text("The shaddah is your visual cue: if you see it, the laam is not read.")
                    Text("This is idghaam of the laam, not deletion.")
                    Text("If you see a shaddah, the laam is gone.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Shams and Qamar")
    }
}

private struct TajweedMaddView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Section("MADD") {
                Text("Madd (Elongation) Rules")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Madd means to lengthen a sound. In Quranic recitation, this lengthening is measured, consistent, and rule-based, not stylistic.")
                    .font(.body)

                Text("Madd is counted in harakat (counts).")
                    .font(.body)
            }

            Section("1. MADD TABII (NATURAL)") {
                Text("This is the default madd. If no special condition follows, this is what you apply.")
                    .font(.body)

                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alif (ا) preceded by fathah")
                    Text("Waw (و) preceded by dammah")
                    Text("Yaa (ي) preceded by kasrah")
                    Text("No hamzah or sukun after")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2 counts")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قَالَ", english: "qa-la", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَقُولُ", english: "ya-qu-lu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fi-hi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If nothing special comes after, 2 counts, no more, no less.")
                    .font(.body)
            }

            Section("2. MADD WAJIB MUTTASIL") {
                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter")
                    Text("Followed by a hamzah")
                    Text("In the same word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 4 or 5 counts (be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "جَاءَ", english: "jaaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "السَّمَاءِ", english: "as-samaaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سُوءَ", english: "suuu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "شَيْءٌ", english: "shay (with extended yaa sound)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("It is called wajib because the lengthening is mandatory.")
                    .font(.body)
            }

            Section("3. MADD JAIZ MUNFASIL") {
                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter at the end of a word")
                    Text("Followed by a hamzah")
                    Text("In the next word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 5 counts (be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Choose one and stay consistent.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "فِي أَنفُسِكُمْ", english: "fi an-fu-si-kum", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَالُوا إِنَّا", english: "qalu in-na", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "إِنَّا أَعْطَيْنَاكَ", english: "inna aa-tay-na-ka", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If you lengthen it, always lengthen it. If you keep it short, always keep it short.")
                    .font(.body)
            }

            Section("4. MADD LAZIM") {
                Text("This is the strongest and longest madd.")
                    .font(.body)

                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter")
                    Text("Followed by a permanent sukun")
                    Text("Either in a word or a letter name")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 6 counts (always)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("A. MADD LAZIM HARFI") {
                Text("Occurs in the disconnected letters at the start of some surahs.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "الم", english: "Alif Laaaam Miiim", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "كهيعص", english: "Kaaaf Haaa Yaaa Ayyyn Saaaad", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "حم", english: "Haaa Miiim", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If the letter name itself contains a madd followed by sukun, it is 6 counts.")
                    .font(.body)
            }

            Section("B. MADD LAZIM KALIMI") {
                Text("Less common, but very important.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "الضَّالِّينَ", english: "ad-daaallin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "الطَّامَّة", english: "at-taaammah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("OPENING LETTERS (MUQATTA’AT)") {
                Text("Some opening letters do not contain madd.")
                    .font(.body)

                Text("Read Normally (No Madd)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ألف (alone)")
                    Text("لام (when not followed by sukun internally)")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Have Madd")
                    .font(.subheadline.weight(.semibold))

                Text("م س ص ن ق ك ي ع ط ه ر")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Not every opening letter is lengthened. Read the letter name.")
                    .font(.body)
            }

            Section("KEY TEACHING RULES") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Madd is measured, not emotional. Do not stretch because it sounds nice.")
                    Text("Consistency matters more than length. 4 everywhere is better than random 2-6.")
                    Text("Never add a jump or break mid-madd. One smooth airflow from start to finish.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Madd")
    }
}

private struct TajweedQalqalahView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Section("QALQALAH") {
                Text("Qalqalah (Echo) Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Qalqalah is a natural bouncing sound that occurs when certain letters are in a sukun state. It is not a vowel and not silence.")
                    .font(.body)

                Text("Its purpose is to prevent the sound from becoming cut off or broken.")
                    .font(.body)
            }

            Section("THE FIVE LETTERS") {
                Text("The qalqalah letters are:")
                    .font(.body)

                Text("ق ط ب ج د")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Section("WHAT QALQALAH IS (AND IS NOT)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A slight echo")
                    Text("Natural and effortless")
                    Text("Not a fathah")
                    Text("Not an added vowel")
                    Text("Not exaggerated")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Think of it as releasing the letter, not opening the mouth.")
                    .font(.body)
            }

            Section("WHEN QALQALAH OCCURS") {
                Text("Qalqalah occurs when one of the five letters:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Has a sukun, or")
                    Text("Is stopped on (waqf)")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أَحَدْ", english: "aha(d)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَجْعَل", english: "yaj'a(l)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "أَجْر", english: "a(j)r", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَقْطَع", english: "ya(q)ta'", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَبْتَغُون", english: "ya(b)taghun", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Notice: the sound is heard, but no vowel is added.")
                    .font(.body)
            }

            Section("WHY QALQALAH EXISTS") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Without qalqalah, the letter would sound cut off.")
                    Text("Without qalqalah, words would sound unnatural or unclear.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qalqalah preserves:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Clarity")
                    Text("Letter identity")
                    Text("Flow of speech")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qalqalah exists because Arabic does not allow these letters to die silently.")
                    .font(.body)
            }

            Section("IMPORTANT REMINDER") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Qalqalah is a sound, not a vowel.")
                    Text("If it sounds like \"a\", it is wrong.")
                    Text("If it disappears, it is also wrong.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Qalqalah")
    }
}

private struct TajweedIdghamIkhfaView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Section("IDGHAAM / IKHFAA") {
                Text("Idgham / Ikhfaa and Related Noon/Tanween Rules")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Tanween and noon saakinah are closely related, so this section groups the merge and hidden-sound rules together.")
                    .font(.body)
            }

            Section("TANWEEN PRONUNCIATION") {
                Text("Although tanween appears as vowel marks, it is pronounced as a hidden noon sound (نْ) at the end of the word.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "بًا",
                        pronunciation: "بَنْ (ban)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بٌ",
                        pronunciation: "بُنْ (bun)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بٍ",
                        pronunciation: "بِنْ (bin)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("What happens to this hidden sound depends entirely on the letter that follows.")
                    .font(.body)
            }

            Section("1. IDHAAR (CLEAR)") {
                Text("The noon sound is pronounced clearly and fully, with no ghunnah merge.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ء ه ع ح غ خ")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedPairRow(arabic: "مِنْ هَادٍ", english: "min hadin", arabicFont: arabicHeadlineFont)

                Text("The throat letters prevent merging, so the sound must remain clear.")
                    .font(.body)
            }

            Section("2. IDGHAAM (MERGING)") {
                Text("The noon sound merges into the following letter.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ي ر م ل و ن")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("With Ghunnah")
                    .font(.subheadline.weight(.semibold))

                Text("ي ن م و")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Without Ghunnah")
                    .font(.subheadline.weight(.semibold))

                Text("ل ر")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "مَن يَقُول",
                        pronunciation: "may-yaqul",
                        rule: "Idghaam with ghunnah",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "مِن رَبِّهِم",
                        pronunciation: "mir-rabbihim",
                        rule: "Idghaam without ghunnah",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("With ghunnah: nasal sound. Without ghunnah: clean merge, no nasalization.")
                    .font(.body)
            }

            Section("3. IQLAAB (CONVERSION)") {
                Text("The noon sound changes into a miim with ghunnah.")
                    .font(.body)

                Text("Letter")
                    .font(.subheadline.weight(.semibold))

                Text("ب")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedRuleRow(
                    arabic: "سَمِيعٌۢ بَصِير",
                    pronunciation: "samium-basir",
                    rule: "",
                    arabicFont: arabicHeadlineFont
                )

                Text("The noon is not pronounced. It becomes a hidden miim.")
                    .font(.body)
            }

            Section("4. IKHFAA (HIDDEN)") {
                Text("The noon is hidden, pronounced with ghunnah, without full clarity or full merging.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("The remaining 15 letters (all except idhaar, idghaam, and iqlaab letters)")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedRuleRow(
                    arabic: "مِن شَرِّ",
                    pronunciation: "min-sharri (nasal)",
                    rule: "",
                    arabicFont: arabicHeadlineFont
                )

                Text("The tongue does not fully touch the articulation point.")
                    .font(.body)
            }

            Section("GHUNNAH STRENGTH") {
                Text("Not all ghunnah is the same strength.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Strongest")
                        .font(.subheadline.weight(.semibold))
                    Text("Ikhfaa, Idghaam with ghunnah")
                        .foregroundColor(.secondary)

                    Text("Medium")
                        .font(.subheadline.weight(.semibold))
                    Text("Noon or Miim with shaddah")
                        .foregroundColor(.secondary)

                    Text("None")
                        .font(.subheadline.weight(.semibold))
                    Text("Idghaam without ghunnah")
                        .foregroundColor(.secondary)
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("KEY TEACHING LINE") {
                Text("Tanween is not a vowel. It is a hidden noon sound in disguise. The rule is determined by the next letter, not the vowel mark.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Idgham / Ikhfaa")
    }
}

private struct TajweedWaqfView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Section("WAQF") {
                Text("Waqf (Stopping in the Quran)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("What Is Waqf?")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Waqf (وَقْف) means to stop or pause while reciting the Quran, with the intention of resuming the recitation correctly afterward.")
                    .font(.body)

                Text("The word comes from the Arabic root و ق ف, meaning to stop, stand, or halt. In tajweed, it refers specifically to stopping at the end of a word while preserving the meaning, pronunciation, and beauty of the Quran.")
                    .font(.body)

                Text("Waqf is not random breathing. It is a deliberate, rule-based pause guided by the Mushaf and the meaning of the ayah.")
                    .font(.body)
            }

            Section("WHY WAQF MATTERS") {
                Text("Stopping incorrectly can:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Change the meaning of an ayah")
                    Text("Create theological errors")
                    Text("Break the grammatical structure")
                    Text("Distort the listener's understanding")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Correct waqf:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preserves meaning")
                    Text("Maintains clarity")
                    Text("Reflects proper understanding")
                    Text("Shows respect for the words of Allah")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Some scholars said: \"Knowing where to stop is half of recitation.\"")
                    .font(.body)
            }

            Section("WAQF IN THE MUSHAF") {
                Text("Even without colors, the Mushaf signals where to stop or continue using:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Special symbols")
                    Text("Word endings")
                    Text("Sentence structure")
                    Text("Completion of meaning")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("A reader trained in waqf reads with understanding, not just sound.")
                    .font(.body)
            }

            Section("LAST LETTER WHEN YOU STOP") {
                Text("When stopping, the ending of the word almost always changes.")
                    .font(.body)

                Text("The Golden Rule of Waqf")
                    .font(.subheadline.weight(.semibold))

                Text("Every vowel at the end of a word becomes a sukun when stopping, except special cases.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("1. FINAL DAMMAH, FATHAH, OR KASRAH") {
                Text("When stopping, the vowel is dropped, and the letter becomes saakin.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "الْعَالَمِينَ -> الْعَالَمِينْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "نَسْتَعِينُ -> نَسْتَعِينْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "الْكِتَابِ -> الْكِتَابْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("The sound is cut cleanly, without adding extra vowels.")
                    .font(.body)
            }

            Section("2. STOPPING ON TANWEEN") {
                Text("Tanween is never pronounced when stopping.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "بَصِيرٌ -> بَصِيرْ",
                        pronunciation: "Dammatayn",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "عَلِيمٍ -> عَلِيمْ",
                        pronunciation: "Kasratayn",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "رَحْمَةً -> رَحْمَةْ",
                        pronunciation: "Fathatayn (no alif)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "كِتَابًا -> كِتَابَا",
                        pronunciation: "Fathatayn + alif",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Important: the tanween itself is dropped completely when stopping. There is no nuun sound and no vowel.")
                    .font(.body)

                Text("Exception: when fathatayn is followed by an alif (ا), the tanween is dropped but the alif is still pronounced, producing a long a sound.")
                    .font(.body)

                Text("This is because the alif is a written long vowel, not part of the tanween itself.")
                    .font(.body)

                Text("Rule to remember: fathatayn disappears when stopping, but a written alif remains pronounced.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("3. TAA MARBUTAH (ة)") {
                Text("When stopping, taa marbutah is pronounced as haa saakinah (ـهْ).")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "رَحْمَةٌ -> رَحْمَهْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "جَنَّةٍ -> جَنَّهْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This rule is consistent everywhere in the Quran.")
                    .font(.body)
            }

            Section("4. LONG VOWELS (ا، و، ي)") {
                Text("Long vowels remain unchanged when stopping.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "هُدَى -> هُدَى",
                        pronunciation: "Unchanged",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "يَقُولُ -> يَقُولْ",
                        pronunciation: "Final vowel drops, long sound remains",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "فِي -> فِي",
                        pronunciation: "Unchanged",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("No shortening occurs.")
                    .font(.body)
            }

            Section("WAQF TAM (COMPLETE)") {
                Text("The meaning is complete and independent.")
                    .font(.body)
                Text("Best place to stop.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF KAFI (SUFFICIENT)") {
                Text("The meaning is complete, but connected to what follows.")
                    .font(.body)
                Text("Permissible to stop.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF HASAN (GOOD)") {
                Text("The wording makes sense, but the meaning is incomplete.")
                    .font(.body)
                Text("Allowed only for breath, not preferred.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF QABIH (BAD)") {
                Text("Stopping breaks the meaning or creates error.")
                    .font(.body)
                Text("Not allowed.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("DANGEROUS STOP EXAMPLE") {
                Text("Example of a dangerous stop:")
                    .font(.subheadline.weight(.semibold))

                Text("لَا تَقْرَبُوا الصَّلَاةَ")
                    .font(arabicHeadlineFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Stopping here implies \"Do not approach prayer,\" which is incorrect.")
                    .font(.body)

                Text("The ayah continues: وَأَنتُمْ سُكَارَى")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("WAQF SYMBOLS") {
                QuranSignsSectionContent(accentColor: settings.accentColor.color)

                Text("These symbols guide meaning, not breathing convenience.")
                    .font(.body)
            }

            Section("REMEMBER") {
                Text("Waqf is not about breath. It is about meaning.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("You stop where the meaning stops, not where the lungs give up.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Waqf")
    }
}

private struct TajweedExampleRow: View {
    let arabic: String
    let middle: String
    let trailing: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(middle)
                .font(.subheadline)
            Text(trailing)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct TajweedPairRow: View {
    let arabic: String
    let english: String
    let arabicFont: Font

    var body: some View {
        HStack {
            Text(english)
                .font(.subheadline)
            
            Spacer()
            
            Text(arabic)
                .font(arabicFont)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

private struct TajweedRuleRow: View {
    let arabic: String
    let pronunciation: String
    let rule: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(pronunciation)
                .font(.subheadline)
            Text(rule)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct TajweedWhyRow: View {
    let arabic: String
    let english: String
    let why: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(english)
                .font(.subheadline)
            Text(why)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct TajweedTopicPlaceholderView: View {
    @EnvironmentObject var settings: Settings

    let title: String

    var body: some View {
        List { }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .navigationTitle(title)
    }
}

#Preview {
    AlIslamPreviewContainer {
        TajweedFoundationsView()
    }
}
