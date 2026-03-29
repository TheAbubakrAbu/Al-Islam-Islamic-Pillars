import SwiftUI

struct TajweedFoundationsView: View {
    @EnvironmentObject var settings: Settings

    private let topics: [String] = [
        "Improving Your Recitation",
        "Foundations",
        "Tajweed in the Mushaf",
        "Makharij (Articulation)",
        "Heavy and Light",
        "Shams and Qamar - Al",
        "Madd (Elongation)",
        "Qalqalah (Echo)",
        "Nuun and Tanween",
        "Waqf (Stopping)"
    ]

    var body: some View {
        List {
            Section("OVERVIEW") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Tajweed, Makharij, and Pronunciation")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Foundations of Quranic Recitation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("This guide applies specifically to Riwayat Hafs an Asim, which is the most widely recited qiraah in the world today and the standard riwayah used in the majority of printed mushafs.")

                    Text("Tajweed (تجويد) refers to the science and practice of reciting the Quran correctly and beautifully, by giving each letter its proper articulation and characteristics. Linguistically, the word tajweed comes from the Arabic root ج-و-د (j-w-d), meaning \"to improve,\" \"to make excellent,\" or \"to perfect.\" In the context of the Quran, it means reciting the words of Allah as they were revealed precisely, clearly, and with care.")

                    Text("Recitation (قراءة qiraah or تلاوة tilawah) refers to the act of reading the Quran. While qiraah simply means \"reading,\" tilawah carries a deeper meaning of reciting with attentiveness, reflection, and adherence to proper method. Quranic recitation is not just reading text; it is the transmission of a preserved oral tradition passed down from the Prophet ﷺ through generations.")

                    Text("Pronunciation in Quranic recitation is governed by two key components: makharij (مخارج الحروف) and sifat (صفات الحروف). Makharij are the points of articulation, where each letter originates in the mouth or throat, while sifat are the characteristics of those letters, such as heaviness (tafkhim), lightness (tarqiq), or echoing (qalqalah). Together, they ensure that each letter is pronounced distinctly and correctly.")

                    Text("These elements are essential because even slight changes in pronunciation can alter meanings. Tajweed preserves not only the beauty of the Quran, but also its accuracy and integrity. The Quran was revealed to be recited, and Allah commands:")

                    Text("And recite the Quran with measured recitation (tartil).")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("(73:4)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("For this reason, learning and applying tajweed is a means of preserving the exact words of the Quran as they were revealed and recited by the Prophet ﷺ, ensuring that its message remains unchanged across generations.")

                    Divider()

                    Text("Applicability to Qiraat")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Other riwayat, such as Warsh, Khalaf, and others, may differ slightly in their application of tajweed rules, including elongations (madd), treatment of hamzah, and certain pronunciation details. These differences stem from authentic variations rooted in classical Arabic dialects and were transmitted through reliable chains of recitation.")

                    Text("As a result, some rules explained in this guide may not apply identically to other riwayat. These variations in tajweed application and pronunciation reflect the diversity of classical Arabic dialects that were all correctly recited and approved by the Prophet ﷺ, and have been preserved exactly through continuous transmission. They highlight the richness, flexibility, and authenticity of the Quranic recitation tradition.")

                }
                .font(.body)

                Text("Learn More About Qiraat, Riwayat, and Ahruf")
                    .font(.subheadline.weight(.semibold))

                Text("See below and in Al-Islam View > Islamic Pillars and Basics.")
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
        }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .navigationTitle("Tajweed Foundations")
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
        } else if topic == "Nuun and Tanween" {
            TajweedNuunTanweenView()
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
                VStack(alignment: .leading, spacing: 14) {
                    Text("This guide on its own is not enough to fully develop strong tajweed and pronunciation. While it can introduce the rules and concepts, real improvement in Quranic recitation requires consistent practice, listening, and guidance from knowledgeable teachers.")

                    Text("Ideally, this guide should be used alongside a teacher who can listen to your recitation and correct your mistakes. Tajweed is refined through feedback and repetition, and many pronunciation errors are difficult to notice on your own. To truly benefit from this guide, approach the Quran with sincerity, humility, and love. Put your trust in Allah and be willing to learn.")

                    Text("You must also set aside arrogance and ego. Even if you believe your tajweed, voice, or makharij are good, there is always room to improve. The greatest reciters spent years refining their recitation. Below are three consistent practices that will help maximize both this guide and your learning of tajweed.")

                    Divider()

                    Text("Three Practices for Improving Tajweed")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("1. Practice Reciting on Your Own")
                        .font(.headline)

                    Text("Reading the Quran regularly on your own is essential. This type of practice helps with:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Increasing reading fluency and speed")
                        Text("Improving familiarity with words and verses")
                        Text("Experimenting with voice control and tone")
                        Text("Applying corrections you have learned")
                    }
                    .foregroundColor(.secondary)

                    Text("However, it is important to understand something: the phrase \"practice makes perfect\" is not true. Rather, perfect practice makes perfect. If someone repeatedly practices incorrect pronunciation or recites carelessly, they may reinforce mistakes instead of correcting them.")

                    Text("For this reason, solo practice should focus on:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading consistently")
                        Text("Reciting carefully with proper tajweed")
                        Text("Applying corrections learned from teachers or study")
                    }
                    .foregroundColor(.secondary)

                    Text("At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself. But it cannot fully replace proper guidance.")

                    Text("This is similar to practicing a sport alone. Individual practice builds skill and stamina, but without proper technique, it will only take you so far. At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself.")

                    Divider()

                    Text("2. Listen to Skilled Reciters and Actively Engage")
                        .font(.headline)

                    Text("Listening to skilled reciters is one of the most powerful ways to improve pronunciation and rhythm. Many students benefit from listening to classical Egyptian reciters such as Sheikh Muhammad Siddiq Al-Minshawi and Sheikh Mahmoud Khalil Al-Hussary.")

                    Text("Both reciters are widely respected for their clarity, precision, and strong tajweed.")

                    Text("Their recordings typically come in two styles:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Murattal - a steady, clear recitation ideal for learning")
                        Text("Mujawwad - a slower, melodic recitation that emphasizes precision and beauty")
                    }
                    .foregroundColor(.secondary)

                    Text("Try to find a reciter whose voice you genuinely enjoy listening to. Developing a connection with a reciter often deepens your love for the Quran and increases your motivation to recite. However, do not listen passively. Instead, actively engage with the recitation:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Follow along in the mushaf while listening")
                        Text("Read aloud with the reciter")
                        Text("Attempt to mimic his tajweed and pronunciation")
                        Text("Pay attention to letter articulation, elongation, and pauses")
                    }
                    .foregroundColor(.secondary)

                    Text("This is similar to studying expert athletes, learning from masters by carefully observing how they perform. You may also benefit from educational tajweed resources such as Learn Arabic 101 or other structured lessons.")

                    Divider()

                    Text("3. Practice With a Teacher or Knowledgeable Partner")
                        .font(.headline)

                    Text("Practicing with someone knowledgeable in tajweed is one of the most effective ways to improve your recitation. A teacher or experienced student can hear mistakes that you will not notice yourself, including:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Incorrect makharij (points of articulation)")
                        Text("Subtle pronunciation errors")
                        Text("Improper elongation (madd)")
                        Text("Weak ghunnah or nasalization")
                        Text("Mistakes in stopping or continuation")
                    }
                    .foregroundColor(.secondary)

                    Text("Corrections may sometimes feel repetitive or strict, but they are extremely valuable.")

                    Text("Even small refinements can significantly improve your recitation. The best tajweed is the recitation that is correct and refined in all aspects, both major and subtle.")

                    Text("Learning with a teacher is similar to training with a coach in sports. A coach observes your technique and gives personalized corrections that accelerate your improvement.")

                    Text("If a formal teacher is not available, try to practice with someone knowledgeable who has strong tajweed and is willing to listen to your recitation and offer corrections.")
                }
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
            Section("FOUNDATIONS") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Foundations of Natural Quranic Recitation")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Avoiding Overemphasis in Quranic Recitation | Correct Mouth and Lip Usage in Recitation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("One of the most common mistakes in Quranic recitation is overemphasis: exaggerating mouth movements, stretching the lips sideways, or forcing sounds in a way that is unnatural to Arabic speech. Correct tajweed is meant to preserve clarity and authenticity.")

                    Divider()

                    Text("General Mouth and Lip Rule")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lips move up and down only")
                        Text("Avoid side stretching or exaggerated shaping")
                        Text("The tongue and throat do most of the work")
                    }
                    .foregroundColor(.secondary)

                    Text("When recited correctly, Quranic Arabic should sound smooth, balanced, and natural, similar to careful classical Arabic speech.")

                    Divider()

                    Text("The Only Two Exceptions")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("1. Dammah-Related Sounds (ُ ٌ و)")
                        .font(.headline)

                    Text("For all sounds related to dammah, the lips must round and project slightly forward to produce a true \"u\" sound.")

                    Text("This is the only time the lips clearly point outward.")

                    Text("Applies To: Dammah (ـُ), Dammatayn (ـٌ), Waw sakinah preceded by dammah (ـُو)")
                        .foregroundColor(.secondary)

                    Divider()

                    Text("2. Mim (م) - Lip Closure")
                        .font(.headline)

                    Text("The letter mim (م) is a bilabial letter, meaning it is produced using both lips.")

                    Text("Think of the lips as folding together, not squeezing.")
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Foundations")
    }
}

private struct TajweedInMushafView: View {
    @EnvironmentObject var settings: Settings

    private var arabicFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
    }

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("TAJWEED IN THE MUSHAF") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Reading Tajweed Directly from the Mushaf")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Learning to See Tajweed in the Mushaf Itself")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Even without a color-coded mushaf, tajweed rules are visible directly in the text. The Quran is written in a way that signals when a sound should be held, merged, hidden, or pronounced clearly, if you know what to look for.")

                    Text("This section teaches you how to recognize tajweed visually, before memorizing specific rules.")

                    Divider()

                    Text("1. Letters Without Sukun (Excluding Madd Letters)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("If a letter:")
                        Text("has no sukun")
                        Text("and is not a madd letter (ا و ي)")
                        Text("then that letter must be held, and some tajweed rule applies.")
                    }

                    Text("This usually means:")
                    Text("Ghunnah, Ikhfaa, Idghaam, Iqlaab, and similar rules.")
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
                            arabic: "عَلِيمٌۢ",
                            middle: "Tanwin + no visible sukun",
                            trailing: "Apply rule",
                            arabicFont: arabicFont
                        )
                    }

                    Text("If there is no sukun, the sound does not pass quickly.")

                    Divider()

                    Text("2. Tanwin Shape = Rule Indicator")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Tanwin always ends in a hidden nun sakinah, which is why its shape matters.")

                    Text("A. Parallel Tanwin -> Idhaar (Clear Nun)")
                        .font(.headline)

                    Text("When the two tanwin strokes are parallel, the nun is pronounced clearly.")

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "بًا", english: "ban", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "بٌ", english: "bun", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "بٍ", english: "bin", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "كِتَابًا عَرَبِيًّا", english: "kitaban arabiyyan", arabicFont: arabicHeadlineFont)
                    }

                    Text("You hear a full, clear \"n\" sound.")

                    Text("B. Staggered / Connected Tanwin -> Apply a Rule")
                        .font(.headline)

                    Text("When tanwin marks appear staggered, connected, or visually altered, this usually indicates Idghaam, Ikhfaa, or Iqlaab.")

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedRuleRow(
                            arabic: "غِشَاوَةٌ وَلَهُمْ",
                            pronunciation: "ghishawat-wa lahum",
                            rule: "Idghaam with ghunnah",
                            arabicFont: arabicFont
                        )

                        TajweedRuleRow(
                            arabic: "مَرَضٌ وَلَهُمْ",
                            pronunciation: "marad-wa lahum",
                            rule: "Idghaam with ghunnah",
                            arabicFont: arabicFont
                        )

                        TajweedRuleRow(
                            arabic: "كَصَيِّبٍ مِّن",
                            pronunciation: "ka-sayyib-min",
                            rule: "Idghaam with ghunnah",
                            arabicFont: arabicFont
                        )
                    }

                    Text("The mushaf is telling you: do not pronounce the nun normally here.")
                        .foregroundColor(settings.accentColor.color)

                    Text("Important clarification: not every mushaf shows tanwin shapes identically, but the principle remains the same. If the tanwin does not look standard, slow down and apply a rule.")

                    Divider()

                    Text("3. The Laam of \"Al-\" (ٱلـ)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("The definite article \"al-\" also signals pronunciation through markings.")

                    Text("A. Sukun on Laam -> Pronounce the Laam (Qamariyyah)")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 10) {
                        TajweedPairRow(arabic: "ٱلْقَمَر", english: "al-qamar", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "ٱلْكِتَاب", english: "al-kitab", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "ٱلْهُدَى", english: "al-huda", arabicFont: arabicHeadlineFont)
                    }

                    Text("B. No Sukun on Laam -> Do Not Pronounce the Laam (Shamsiyyah)")
                        .font(.headline)

                    Text("The laam merges into the next letter.")

                    VStack(alignment: .leading, spacing: 10) {
                        TajweedPairRow(arabic: "ٱلشَّمْس", english: "ash-shams", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "ٱلنَّاس", english: "an-nas", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "ٱلرَّحْمَٰن", english: "ar-rahman", arabicFont: arabicHeadlineFont)
                    }

                    Text("If you do not see a sukun, the laam is not read.")
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Tajweed in the Mushaf")
    }
}

private struct TajweedMakharijView: View {
    @EnvironmentObject var settings: Settings

    private var arabicFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
    }

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("MAKHARIJ") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Makharij al-Huruf (Articulation of Letters)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Makharij are the physical points of articulation from which Arabic letters are pronounced. Correct makharij are the foundation of tajweed. If the letter does not come from its proper place, no amount of rules will fix the sound.")

                    Text("This section focuses on awareness, not memorization. The goal is to know where a sound comes from and what moves to produce it.")

                    Image("Makharij1")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Image("Makharij2")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Text("Use these diagrams as references, not something to stare at while reciting. Over time, correct makharij become muscle memory.")

                    Divider()

                    Text("Recommended Playlist (Practice-Oriented)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Use a clear, slow pronunciation playlist such as Learn Arabic 101 (Makharij series). Focus on:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Isolated letter sounds")
                        Text("Minimal exaggeration")
                        Text("Clear mouth positioning")
                    }
                    .foregroundColor(.secondary)

                    Text("Listen -> imitate -> repeat aloud. Silent learning does not work for makharij.")

                    if let url = URL(string: "https://www.youtube.com/watch?v=-YrfRpwFMe8&list=PL6TlMIZ5ylgpmlnN3EpkOec0tJ8OJZ5re") {
                        Link("Open Makharij Playlist", destination: url)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }

                    Divider()

                    Text("Primary Areas of Articulation")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("For learning purposes, we group makharij into three main zones.")

                    Text("1. Throat Letters (الحروف الحلقية)")
                        .font(.headline)

                    Text("These letters originate from the throat, not the tongue.")

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
                    .foregroundColor(.secondary)

                    Text("Key Notes")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("These letters are clear and open")
                        Text("No nasalization")
                        Text("Do not squeeze the throat")
                    }
                    .foregroundColor(.secondary)

                    Text("Examples")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "أَحَد", english: "ahad", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "نَعْبُدُ", english: "naabudu", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "غَفُور", english: "ghafur", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "خَالِد", english: "khalid", arabicFont: arabicHeadlineFont)
                    }

                    Text("Common mistake: replacing ع with أ")
                        .foregroundColor(.secondary)

                    Text("Correct: clear throat engagement")
                        .foregroundColor(settings.accentColor.color)

                    Divider()

                    Text("2. Tongue Letters (أغلب الحروف)")
                        .font(.headline)

                    Text("Most Arabic letters come from the tongue, but different parts of the tongue.")

                    Text("Tongue Zones (Simplified)")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Back of tongue: ق ك")
                        Text("Middle of tongue: ج ش ي")
                        Text("Sides of tongue: ض")
                        Text("Tip of tongue: ت د ط ن ل ر س ز ص ث ذ ظ")
                    }
                    .foregroundColor(.secondary)

                    Text("Key Notes")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Small shifts in tongue position matter")
                        Text("Do not force pressure")
                        Text("Accuracy > strength")
                    }
                    .foregroundColor(.secondary)

                    Text("Examples")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "قُلْ", english: "qul", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "سِرَاط", english: "sirat", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "رَبِّ", english: "rabbi", arabicFont: arabicHeadlineFont)
                    }

                    Text("Common mistake: collapsing multiple letters into one sound")
                        .foregroundColor(.secondary)

                    Text("Correct: distinct articulation for each letter")
                        .foregroundColor(settings.accentColor.color)

                    Divider()

                    Text("3. Lip Letters (الحروف الشفوية)")
                        .font(.headline)

                    Text("These letters are produced using the lips.")

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
                    .foregroundColor(.secondary)

                    Text("Examples")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "بَصِير", english: "basir", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "أَمْر", english: "amr", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "فِيهِ", english: "fihi", arabicFont: arabicHeadlineFont)
                    }

                    Text("Common mistake: weak or lazy lip contact")
                        .foregroundColor(.secondary)

                    Text("Correct: gentle, controlled movement")
                        .foregroundColor(settings.accentColor.color)

                    Divider()

                    Text("Important Practice Advice")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Makharij are learned by sound, not sight.")

                    Text("If you cannot hear the difference, slow down and exaggerate slightly during practice, then return to natural recitation.")

                    Text("Correct makharij preserve the Quran exactly as it was revealed.")

                    Text("Tajweed rules refine the sound. Makharij create it.")
                        .foregroundColor(settings.accentColor.color)
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Makharij")
    }
}

private struct TajweedHeavyLightView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("HEAVY AND LIGHT") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Heavy and Light Letters")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Arabic letters differ in weight (heavy tafkhim vs light tarqiq). Some letters are always heavy, some are always light, and some are conditional, meaning the weight changes based on context.")

                    Text("Correct letter weight is essential for accurate pronunciation and natural recitation.")

                    Divider()

                    Text("1. Heavy Letters (تفخيم)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("These letters are always heavy, regardless of the vowel.")

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
                    .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "قَالَ", english: "qala", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "صِرَاط", english: "sirat", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "طَبَعَ", english: "tabaa", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "غَفُور", english: "ghafur", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "خَالِد", english: "khalid", arabicFont: arabicHeadlineFont)
                    }

                    Divider()

                    Text("2. Light Letters (ترقيق)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("These letters are always light and never pronounced heavy.")

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
                    .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "بِسْم", english: "bism", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "نَعِيم", english: "naim", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "سَبِيل", english: "sabil", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "يَوْم", english: "yawm", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "فِيهِ", english: "fihi", arabicFont: arabicHeadlineFont)
                    }

                    Text("Note: Laam (ل) and waw (و) are light by default, but laam becomes conditional in one specific case: Allah.")

                    Divider()

                    Text("3. Conditional Letters")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("These letters change weight depending on vowels or surrounding letters.")

                    Text("A. Raa (ر)")
                        .font(.headline)

                    Text("The weight of raa depends on the vowel on the raa itself.")

                    Text("Heavy Raa")
                        .font(.subheadline.weight(.semibold))

                    Text("With fathah (ـَ) or dammah (ـُ)")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "رَبِّ", english: "rabbi", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "رُزِقُوا", english: "ruziqu", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "قَرَأَ", english: "qaraa", arabicFont: arabicHeadlineFont)
                    }

                    Text("Light Raa")
                        .font(.subheadline.weight(.semibold))

                    Text("With kasrah (ـِ)")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "فِرْعَوْن", english: "firawn", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "رِجَال", english: "rijal", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "شِرْعَة", english: "shirah", arabicFont: arabicHeadlineFont)
                    }

                    Text("Rule of thumb: look at the vowel on the raa, not the surrounding letters.")

                    Divider()

                    Text("B. Laam (ل)")
                        .font(.headline)

                    Text("The letter laam is always light, except in the word Allah (ٱللَّه).")

                    Text("Heavy Laam (Only in \"Allah\")")
                        .font(.subheadline.weight(.semibold))

                    Text("When preceded by fathah or dammah:")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "ٱللَّهُ", english: "Allahu", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "قَالَ ٱللَّهُ", english: "qala Allahu", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "نَصْرُ ٱللَّهِ", english: "nasru Allahi", arabicFont: arabicHeadlineFont)
                    }

                    Text("Light Laam (After Kasrah)")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "بِٱللَّهِ", english: "billahi", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "لِلَّهِ", english: "lillahi", arabicFont: arabicHeadlineFont)
                    }

                    Divider()

                    Text("C. Alif (ا) - Conditional by Following the Letter")
                        .font(.headline)

                    Text("Alif itself has no sound; it inherits the weight of the letter before it.")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("After a heavy letter -> alif sounds heavy")
                        Text("After a light letter -> alif sounds light")
                    }
                    .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedWhyRow(arabic: "قَالَ", english: "qala", why: "Heavy letter (ق)", arabicFont: arabicHeadlineFont)
                        TajweedWhyRow(arabic: "صَادِق", english: "sadiq", why: "Heavy letter (ص)", arabicFont: arabicHeadlineFont)
                        TajweedWhyRow(arabic: "كَانَ", english: "kana", why: "Light letter (ك)", arabicFont: arabicHeadlineFont)
                        TajweedWhyRow(arabic: "نَاس", english: "nas", why: "Light letter (ن)", arabicFont: arabicHeadlineFont)
                    }

                    Text("Wrong: making alif heavy by itself")
                        .foregroundColor(.secondary)

                    Text("Correct: alif follows, never leads")
                        .foregroundColor(settings.accentColor.color)
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Heavy and Light")
    }
}

private struct TajweedShamsQamarView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("SHAMS AND QAMAR") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Shamsiyyah and Qamariyyah Letters")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Definite Article \"Al-\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("When the definite article ٱلـ (al-) appears before a noun, the pronunciation of the laam (ل) depends on the first letter of the word that follows.")

                    Text("The mushaf clearly indicates this through shaddah or sukun.")

                    Divider()

                    Text("1. Qamariyyah Letters (Moon Letters)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("With qamariyyah letters, the laam is pronounced clearly.")

                    Text("Rule")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("The laam has a sukun (ٱلْ)")
                        Text("The sound is al-")
                    }
                    .foregroundColor(.secondary)

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

                    Text("Incorrect: dropping the laam")
                        .foregroundColor(.secondary)

                    Text("Correct: pronouncing al-")
                        .foregroundColor(settings.accentColor.color)

                    Divider()

                    Text("2. Shamsiyyah Letters (Sun Letters)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("With shamsiyyah letters, the laam is not pronounced. Instead, it merges into the following letter, which is doubled (shown by a shaddah).")

                    Text("Rule")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("No sukun on the laam")
                        Text("The next letter has a shaddah")
                        Text("Pronounce the word as if it begins with the doubled letter")
                    }
                    .foregroundColor(.secondary)

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

                    Text("Incorrect: al-shams")
                        .foregroundColor(.secondary)

                    Text("Correct: ash-shams")
                        .foregroundColor(settings.accentColor.color)

                    Divider()

                    Text("Important Notes")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("This rule applies only to the definite article ٱلـ, not to every laam.")
                        Text("The shaddah is your visual cue: if you see it, the laam is not read.")
                        Text("This is idghaam of the laam, not deletion.")
                        Text("If you see a shaddah, the laam is gone.")
                    }
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Shams and Qamar")
    }
}

private struct TajweedMaddView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("MADD") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Madd (Elongation) Rules")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Madd means to lengthen a sound. In Quranic recitation, this lengthening is measured, consistent, and rule-based, not stylistic.")

                    Text("Madd is counted in harakat (counts).")

                    Divider()

                    Text("1. Madd Tabii (Natural Madd)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("This is the default madd. If no special condition follows, this is what you apply.")

                    Text("When It Occurs")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alif (ا) preceded by fathah")
                        Text("Waw (و) preceded by dammah")
                        Text("Yaa (ي) preceded by kasrah")
                        Text("No hamzah or sukun after")
                    }
                    .foregroundColor(.secondary)

                    Text("Length: 2 counts")
                        .foregroundColor(settings.accentColor.color)

                    Text("Examples")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "قَالَ", english: "qa-la", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "يَقُولُ", english: "ya-qu-lu", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "فِيهِ", english: "fi-hi", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                    }

                    Text("If nothing special comes after, 2 counts, no more, no less.")

                    Divider()

                    Text("2. Madd Wajib Muttasil (Connected Madd)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("When It Occurs")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A madd letter")
                        Text("Followed by a hamzah")
                        Text("In the same word")
                    }
                    .foregroundColor(.secondary)

                    Text("Length: 4-5 counts (be consistent)")
                        .foregroundColor(settings.accentColor.color)

                    Text("Examples")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "جَاءَ", english: "jaaa", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "السَّمَاءِ", english: "as-samaaa", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "سُوءَ", english: "suuu", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "شَيْءٌ", english: "shay (with extended yaa sound)", arabicFont: arabicHeadlineFont)
                    }

                    Text("It is called wajib because the lengthening is mandatory.")

                    Divider()

                    Text("3. Madd Jaiz Munfasil (Separated Madd)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("When It Occurs")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A madd letter at the end of a word")
                        Text("Followed by a hamzah")
                        Text("In the next word")
                    }
                    .foregroundColor(.secondary)

                    Text("Length: 2 or 4-5 counts")
                        .foregroundColor(settings.accentColor.color)

                    Text("Choose one and stay consistent.")
                        .foregroundColor(.secondary)

                    Text("Examples")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "فِي أَنفُسِكُمْ", english: "fi an-fu-si-kum", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "قَالُوا إِنَّا", english: "qalu in-na", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "إِنَّا أَعْطَيْنَاكَ", english: "inna aa-tay-na-ka", arabicFont: arabicHeadlineFont)
                    }

                    Text("If you lengthen it, always lengthen it. If you keep it short, always keep it short.")

                    Divider()

                    Text("4. Madd Lazim (Necessary Madd)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("This is the strongest and longest madd.")

                    Text("When It Occurs")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A madd letter")
                        Text("Followed by a permanent sukun")
                        Text("Either in a word or a letter name")
                    }
                    .foregroundColor(.secondary)

                    Text("Length: 6 counts (always)")
                        .foregroundColor(settings.accentColor.color)

                    Text("A. Madd Lazim Harfi (Beginning Letters)")
                        .font(.headline)

                    Text("Occurs in the disconnected letters at the start of some surahs.")

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "الم", english: "Alif Laaaam Miiim", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "كهيعص", english: "Kaaaf Haaa Yaaa Ayyyn Saaaad", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "حم", english: "Haaa Miiim", arabicFont: arabicHeadlineFont)
                    }

                    Text("If the letter name itself contains a madd followed by sukun, it is 6 counts.")

                    Text("B. Madd Lazim Kalimi (Within a Word)")
                        .font(.headline)

                    Text("Less common, but very important.")

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "الضَّالِّينَ", english: "ad-daaallin", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "الطَّامَّة", english: "at-taaammah", arabicFont: arabicHeadlineFont)
                    }

                    Divider()

                    Text("Important Rule About the Opening Letters")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Some opening letters do not contain madd.")

                    Text("Read Normally (No Madd)")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ألف (alone)")
                        Text("لام (when not followed by sukun internally)")
                    }
                    .foregroundColor(.secondary)

                    Text("Have Madd")
                        .font(.subheadline.weight(.semibold))

                    Text("م س ص ن ق ك ي ع ط ه ر")
                        .font(arabicHeadlineFont)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("Not every opening letter is lengthened. Read the letter name.")

                    Divider()

                    Text("Key Teaching Rules")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Madd is measured, not emotional. Do not stretch because it sounds nice.")
                        Text("Consistency matters more than length. 4 everywhere is better than random 2-6.")
                        Text("Never add a jump or break mid-madd. One smooth airflow from start to finish.")
                    }
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Madd")
    }
}

private struct TajweedQalqalahView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("QALQALAH") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Qalqalah (Echo) Letters")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Qalqalah is a natural bouncing sound that occurs when certain letters are in a sukun state. It is not a vowel and not silence.")

                    Text("Its purpose is to prevent the sound from becoming cut off or broken.")

                    Divider()

                    Text("Qalqalah Letters")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("The qalqalah letters are:")

                    Text("ق ط ب ج د")
                        .font(arabicHeadlineFont)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("A common mnemonic: قطب جد")
                        .font(arabicHeadlineFont)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Divider()

                    Text("What Qalqalah Is (and Is Not)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A slight echo")
                        Text("Natural and effortless")
                        Text("Not a fathah")
                        Text("Not an added vowel")
                        Text("Not exaggerated")
                    }
                    .foregroundColor(.secondary)

                    Text("Think of it as releasing the letter, not opening the mouth.")

                    Divider()

                    Text("When Qalqalah Occurs")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Qalqalah occurs when one of the five letters:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Has a sukun, or")
                        Text("Is stopped on (waqf)")
                    }
                    .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedPairRow(arabic: "أَحَدْ", english: "aha(d)", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "يَجْعَل", english: "yaj'a(l)", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "أَجْر", english: "a(j)r", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "يَقْطَع", english: "ya(q)ta'", arabicFont: arabicHeadlineFont)
                        TajweedPairRow(arabic: "يَبْتَغُون", english: "ya(b)taghun", arabicFont: arabicHeadlineFont)
                    }

                    Text("Notice: the sound is heard, but no vowel is added.")

                    Divider()

                    Text("Why Qalqalah Exists")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Without qalqalah, the letter would sound cut off.")
                        Text("Without qalqalah, words would sound unnatural or unclear.")
                    }

                    Text("Qalqalah preserves:")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Clarity")
                        Text("Letter identity")
                        Text("Flow of speech")
                    }
                    .foregroundColor(.secondary)

                    Text("Qalqalah exists because Arabic does not allow these letters to die silently.")

                    Divider()

                    Text("Important Reminder")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Qalqalah is a sound, not a vowel.")
                        Text("If it sounds like \"a\", it is wrong.")
                        Text("If it disappears, it is also wrong.")
                    }
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Qalqalah")
    }
}

private struct TajweedNuunTanweenView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("NUUN AND TANWEEN") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Nuun Saakinah and Tanween Rules")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Tanween always ends in a hidden nuun saakinah, which is why both topics are treated together.")

                    Divider()

                    Text("Tanween Pronunciation Reality")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Although tanween appears as vowel marks, it is pronounced as a nuun saakinah (نْ) at the end of the word.")

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

                    Text("What happens to this hidden nuun depends entirely on the letter that follows.")

                    Divider()

                    Text("The Four Rules of Nuun Saakinah and Tanween")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("1. Idhaar (Clear Pronunciation)")
                        .font(.headline)

                    Text("The nuun is pronounced clearly and fully, with no ghunnah merge.")

                    Text("Letters")
                        .font(.subheadline.weight(.semibold))

                    Text("ء ه ع ح غ خ")
                        .font(arabicHeadlineFont)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("Example")
                        .font(.subheadline.weight(.semibold))

                    TajweedPairRow(arabic: "مِنْ هَادٍ", english: "min hadin", arabicFont: arabicHeadlineFont)

                    Text("The throat letters prevent merging, so the nuun must remain clear.")

                    Divider()

                    Text("2. Idghaam (Merging)")
                        .font(.headline)

                    Text("The nuun merges into the following letter.")

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

                    Text("With ghunnah: nasal sound. Without ghunnah: clean merge, no nasalization.")

                    Divider()

                    Text("3. Iqlaab (Conversion)")
                        .font(.headline)

                    Text("The nuun sound changes into a miim with ghunnah.")

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

                    Text("The nuun is not pronounced. It becomes a hidden miim.")

                    Divider()

                    Text("4. Ikhfaa (Hidden Pronunciation)")
                        .font(.headline)

                    Text("The nuun is hidden, pronounced with ghunnah, without full clarity or full merging.")

                    Text("Letters")
                        .font(.subheadline.weight(.semibold))

                    Text("The remaining 15 letters (all except idhaar, idghaam, and iqlaab letters)")
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

                    Divider()

                    Text("Ghunnah Strength Levels")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Not all ghunnah is the same strength.")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Strongest")
                            .font(.subheadline.weight(.semibold))
                        Text("Ikhfaa, Idghaam with ghunnah")
                            .foregroundColor(.secondary)

                        Text("Medium")
                            .font(.subheadline.weight(.semibold))
                        Text("Nuun or Miim with shaddah")
                            .foregroundColor(.secondary)

                        Text("None")
                            .font(.subheadline.weight(.semibold))
                        Text("Idghaam without ghunnah")
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    Text("Key Teaching Line")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Tanween is not a vowel. It is a nuun saakinah in disguise. The rule is determined by the next letter, not the vowel mark.")
                }
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Nuun and Tanween")
    }
}

private struct TajweedWaqfView: View {
    @EnvironmentObject var settings: Settings

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Section("WAQF") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Waqf (Stopping in the Quran)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("What Is Waqf?")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Waqf (وَقْف) means to stop or pause while reciting the Quran, with the intention of resuming the recitation correctly afterward.")

                    Text("The word comes from the Arabic root و ق ف, meaning to stop, stand, or halt. In tajweed, it refers specifically to stopping at the end of a word while preserving the meaning, pronunciation, and beauty of the Quran.")

                    Text("Waqf is not random breathing. It is a deliberate, rule-based pause guided by the Mushaf and the meaning of the ayah.")

                    Divider()

                    Text("Why Waqf Is Important")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Stopping incorrectly can:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change the meaning of an ayah")
                        Text("Create theological errors")
                        Text("Break the grammatical structure")
                        Text("Distort the listener's understanding")
                    }
                    .foregroundColor(.secondary)

                    Text("Correct waqf:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preserves meaning")
                        Text("Maintains clarity")
                        Text("Reflects proper understanding")
                        Text("Shows respect for the words of Allah")
                    }
                    .foregroundColor(.secondary)

                    Text("Some scholars said: \"Knowing where to stop is half of recitation.\"")

                    Divider()

                    Text("Waqf Is Visible in the Mushaf")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("Even without colors, the Mushaf signals where to stop or continue using:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Special symbols")
                        Text("Word endings")
                        Text("Sentence structure")
                        Text("Completion of meaning")
                    }
                    .foregroundColor(.secondary)

                    Text("A reader trained in waqf reads with understanding, not just sound.")

                    Divider()

                    Text("What Happens to the Last Letter When You Stop")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("When stopping, the ending of the word almost always changes.")

                    Text("The Golden Rule of Waqf")
                        .font(.subheadline.weight(.semibold))

                    Text("Every vowel at the end of a word becomes a sukun when stopping, except special cases.")
                        .foregroundColor(settings.accentColor.color)

                    Text("1. Words Ending with Dammah, Fathah, or Kasrah")
                        .font(.headline)

                    Text("When stopping, the vowel is dropped, and the letter becomes saakin.")

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

                    Text("The sound is cut cleanly, without adding extra vowels.")

                    Divider()

                    Text("2. Words Ending with Tanween")
                        .font(.headline)

                    Text("Tanween is never pronounced when stopping.")

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

                    Text("Important: the tanween itself is dropped completely when stopping. There is no nuun sound and no vowel.")

                    Text("Exception: when fathatayn is followed by an alif (ا), the tanween is dropped but the alif is still pronounced, producing a long a sound.")

                    Text("This is because the alif is a written long vowel, not part of the tanween itself.")

                    Text("Rule to remember: fathatayn disappears when stopping, but a written alif remains pronounced.")
                        .foregroundColor(settings.accentColor.color)

                    Divider()

                    Text("3. Special Case: Taa Marbutah (ة)")
                        .font(.headline)

                    Text("When stopping, taa marbutah is pronounced as haa saakinah (ـهْ).")

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

                    Text("This rule is consistent everywhere in the Quran.")

                    Divider()

                    Text("4. Words Ending with Long Vowels (ا، و، ي)")
                        .font(.headline)

                    Text("Long vowels remain unchanged when stopping.")

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

                    Text("No shortening occurs.")

                    Divider()

                    Text("Types of Waqf (By Meaning)")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. Waqf Tam (Complete Stop)")
                            .font(.subheadline.weight(.semibold))
                        Text("The meaning is complete and independent.")
                        Text("Best place to stop.")
                            .foregroundColor(settings.accentColor.color)

                        Text("2. Waqf Kafi (Sufficient Stop)")
                            .font(.subheadline.weight(.semibold))
                        Text("The meaning is complete, but connected to what follows.")
                        Text("Permissible to stop.")
                            .foregroundColor(settings.accentColor.color)

                        Text("3. Waqf Hasan (Good Stop)")
                            .font(.subheadline.weight(.semibold))
                        Text("The wording makes sense, but the meaning is incomplete.")
                        Text("Allowed only for breath, not preferred.")
                            .foregroundColor(settings.accentColor.color)

                        Text("4. Waqf Qabih (Bad Stop)")
                            .font(.subheadline.weight(.semibold))
                        Text("Stopping breaks the meaning or creates error.")
                        Text("Not allowed.")
                            .foregroundColor(settings.accentColor.color)
                    }

                    Text("Example of a dangerous stop:")
                        .font(.subheadline.weight(.semibold))

                    Text("لَا تَقْرَبُوا الصَّلَاةَ")
                        .font(arabicHeadlineFont)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("Stopping here implies \"Do not approach prayer,\" which is incorrect.")

                    Text("The ayah continues: وَأَنتُمْ سُكَارَى")
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Waqf Symbols in the Mushaf")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 12) {
                        TajweedRuleRow(arabic: "م", pronunciation: "Mandatory stop", rule: "", arabicFont: arabicHeadlineFont)
                        TajweedRuleRow(arabic: "لا", pronunciation: "Do not stop", rule: "", arabicFont: arabicHeadlineFont)
                        TajweedRuleRow(arabic: "ج", pronunciation: "Permissible", rule: "", arabicFont: arabicHeadlineFont)
                        TajweedRuleRow(arabic: "قلى", pronunciation: "Stop is better", rule: "", arabicFont: arabicHeadlineFont)
                        TajweedRuleRow(arabic: "صلى", pronunciation: "Continue is better", rule: "", arabicFont: arabicHeadlineFont)
                        TajweedRuleRow(arabic: "∴", pronunciation: "Choose one stop, not both", rule: "", arabicFont: arabicHeadlineFont)
                    }

                    Text("These symbols guide meaning, not breathing convenience.")

                    Divider()

                    Text("Waqf is not about breath. It is about meaning.")
                        .foregroundColor(settings.accentColor.color)

                    Text("You stop where the meaning stops, not where the lungs give up.")
                }
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
        HStack(alignment: .firstTextBaseline) {
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
