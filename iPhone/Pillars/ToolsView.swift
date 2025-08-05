import SwiftUI
#if !os(watchOS)
import Photos
#endif

struct ToolsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var namesData: NamesViewModel
            
    var body: some View {
        Section(header: Text("ISLAMIC RESOURCES")) {
            NavigationLink(destination: ArabicView()) {
                Label(
                    title: { Text("Arabic Alphabet") },
                    icon: { Image(systemName: "textformat.size.ar") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }
            
            NavigationLink(destination: AdhkarView()) {
                Label(
                    title: { Text("Common Adhkar") },
                    icon: { Image(systemName: "book.closed") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }

            NavigationLink(destination: DuaView()) {
                Label(
                    title: { Text("Common Duas") },
                    icon: { Image(systemName: "text.book.closed") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }

            NavigationLink(destination: TasbihView()) {
                Label(
                    title: { Text("Tasbih Counter") },
                    icon: { Image(systemName: "circles.hexagonpath.fill") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }

            NavigationLink(destination: NamesView()) {
                Label(
                    title: { Text("99 Names of Allah") },
                    icon: { Image(systemName: "signature") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }
            
            #if !os(watchOS)
            NavigationLink(destination: DateView()) {
                Label(
                    title: { Text("Hijri Calendar Converter") },
                    icon: { Image(systemName: "calendar") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }
            #endif

            NavigationLink(destination: WallpaperView()) {
                Label(
                    title: { Text("Islamic Wallpapers") },
                    icon: { Image(systemName: "photo.on.rectangle") }
                )
                .padding(.vertical, 4)
                .accentColor(settings.accentColor.color)
            }
        }
    }
}

struct AdhkarRow: View {
    @EnvironmentObject var settings: Settings
    
    let arabicText: String
    let transliteration: String
    let translation: String
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Spacer()
                    
                    Text(arabicText)
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                }
                
                Text(transliteration)
                    .font(.subheadline)
                
                Text(translation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            #if !os(watchOS)
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = arabicText
                    settings.hapticFeedback()
                }) {
                    Label("Copy Arabic", systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    UIPasteboard.general.string = transliteration
                    settings.hapticFeedback()
                }) {
                    Label("Copy Transliteration", systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    UIPasteboard.general.string = translation
                    settings.hapticFeedback()
                }) {
                    Label("Copy Translation", systemImage: "doc.on.doc")
                }
            }
            #endif
        }
    }
}

struct AdhkarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("REMEMBRANCES OF ALLAH ﷻ‎")) {
                Text("Adhkar (plural of Dhikr) are short phrases of remembrance taught by Prophet Muhammad ﷺ. They bring peace, purify the heart, and draw one closer to Allah.\n\nAllah ﷻ says: “Unquestionably, by the remembrance of Allah hearts are assured” (Quran 13:28).\nProphet Muhammad ﷺ said: “Keep your tongue moist with the remembrance of Allah” (Tirmidhi 3375).")
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            
            AdhkarRow(arabicText: "سُبْحَانَ اللَّهِ", transliteration: "SubhanAllah", translation: "Glory be to Allah")
            
            AdhkarRow(arabicText: "ٱلْـحَمْدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah")
            
            AdhkarRow(arabicText: "اللَّهُ أَكْبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest")
            
            AdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illallah", translation: "There is no deity worthy of worship except Allah")
            
            AdhkarRow(arabicText: "أَسْتَغْفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah")
            
            AdhkarRow(arabicText: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah")
            
            AdhkarRow(arabicText: "ٱلْـحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ", transliteration: "Alhamdulillahi rabbil 'alamin", translation: "Praise be to Allah, the Lord of all the worlds")
            
            AdhkarRow(arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ", transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great")
            
            AdhkarRow(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family")
            
            AdhkarRow(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْـحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ", transliteration: "La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things")
            
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
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Common Adhkar")
    }
}

struct DuaView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("SUPPLICATIONS TO ALLAH ﷻ‎")) {
                Text("Dua (supplication) is the heart of worship and a direct line to Allah ﷻ. It allows us to speak directly to Him, anytime, anywhere, in any language. It reflects our dependence, humility, and hope. Prophet Muhammad ﷺ taught countless duas for every moment, guiding us to turn to Allah ﷻ‎ in all circumstances.\n\nAllah ﷻ‎ says: “Call upon Me; I will respond to you” (Quran 40:60).\nProphet Muhammad ﷺ said: “Dua is worship” (Tirmidhi 2969).")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ زَوَالِ نِعْمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ وَفُجَاءَةِ نِقْمَتِكَ وَجَمِيعِ سَخَطِكَ", transliteration: "Allahumma inni a'udhu bika min zawali ni'matika wa tahawwuli 'afiyatika wa fuja'ati niqmatika wa jamee' sakhatika", translation: "O Allah, I seek refuge in You from the removal of Your blessings, changing of Your protection, sudden wrath, and all of Your displeasure")
            
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ", transliteration: "Allahumma inni as'aluka al-'afwa wal-'afiyah fi ad-dunya wal-akhirah", translation: "O Allah, I ask You for forgiveness and well-being in this life and the hereafter")
            
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى", transliteration: "Allahumma inni as'aluka al-huda wa at-tuqaa wal-'afaafa wal-ghina", translation: "O Allah, I ask You for guidance, righteousness, chastity, and sufficiency")
            
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ", transliteration: "Allahumma inni a'udhu bika min al-kufr wal-faqr wa a'udhu bika min 'adhab al-qabr", translation: "O Allah, I seek refuge in You from disbelief, poverty, and the punishment of the grave")
            
            AdhkarRow(arabicText: "اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ", transliteration: "Allahumma ma asbaha bi min ni'matin, aw bi ahadin min khalqika, faminka wahdaka la sharika laka, falaka alhamdu wa laka ash-shukr", translation: "O Allah, whatever blessings I or any of Your creatures rose up with, is from You alone, without partner, so for You is all praise and unto You all thanks.")
            
            AdhkarRow(arabicText: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "O my Lord, expand for me my chest, and ease for me my task.")
            
            AdhkarRow(arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", transliteration: "Allahumma a'innee ala dhikrika wa shukrika wa husni ibadatika", translation: "O Allah, assist me in remembering You, in thanking You, and in worshipping You in the best manner.")
            
            AdhkarRow(arabicText: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", transliteration: "Rabbanaa atinaa fid-dunya hasanatan wa fil aakhirati hasanatan wa qinaa 'adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.")
            
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَجْزِ وَالْكَسَلِ وَالْجُبْنِ وَالْهَرَمِ وَالْبُخْلِ وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ", transliteration: "Allahumma inni a'udhu bika min al-'ajzi wal-kasali wal-jubni wal-harami wal-bukhli, wa a'udhu bika min 'adhab al-qabr, wa min fitnat al-mahya wal-mamat", translation: "O Allah, I seek refuge in You from weakness and laziness, miserliness and cowardice, the burden of debts and from being overpowered by men. I seek refuge in You from the punishment of the grave and from the trials and tribulations of life and death.")
            
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted.")
            
            AdhkarRow(
                arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ",
                transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta’khudhuhu sinatun wa la nawm. Lahu ma fi as-samawati wa ma fi al-ard. Man dha allathee yashfa'u 'indahu illa bi-idhnihi? Ya’lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay’in min ‘ilmihi illa bima sha’. Wasi’a kursiyyuhu as-samawati wal-ard, wa la ya’uduhu hifzuhuma, wa Huwal ‘Aliyyul-‘Azim (2:255).",
                translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great (2:255)."
            )
            
            Section(header: Text("VIRTUES OF DUA")) {
                Text("Dua is the essence of worship and the strongest connection between a servant and their Lord. It reflects humility, faith, and hope in Allah ﷻ. It is a source of relief, mercy, and countless blessings. Every sincere call to Allah ﷻ is heard, and no dua is ever lost.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Group {
                    Text("❖ “Call upon Me; I will respond to you” (Quran 40:60).")
                    Text("❖ “So ask forgiveness of Him and then repent to Him. Indeed, my Lord is near and responsive” (Quran 11:61).")
                    Text("❖ “When My servants ask you, [O Muḥammad], concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. So let them respond to Me [by obedience] and believe in Me that they may be [rightly] guided” (Quran 2:186).")
                    Text("❖ “Say, 'What would my Lord care for you if not for your supplication?'” (Quran 25:77).")
                    Text("❖ “Is He [not best] who responds to the desperate one when he calls upon Him and removes evil and makes you inheritors of the earth? Is there a deity with Allah? Little do you remember” (Quran 27:62).")
                }
                .font(.footnote)
                .foregroundColor(settings.accentColor.color)
                
                Group {
                    Text("❖ Prophet Muhammad ﷺ said: “Dua is worship” (Tirmidhi 2969).")
                    Text("❖ Prophet Muhammad ﷺ said: “There is nothing more noble in the sight of Allah ﷻ than dua” (Tirmidhi 3370).")
                    Text("❖ Prophet Muhammad ﷺ said: “Whoever does not ask Allah ﷻ, He becomes angry with him” (Tirmidhi 3373).")
                    Text("❖ Prophet Muhammad ﷺ said: “There is no Muslim who calls upon Allah with a supplication in which there is no sin or severing of family ties, except that Allah will give him one of three things: He will hasten it, store it for him in the Hereafter, or avert from him a similar harm.” They said: “Then we will increase (in supplication).” He ﷺ said: “Allah is more” (Tirmidhi 3573).")
                }
                .font(.footnote)
                .foregroundColor(settings.accentColor.color)
                
                Text("Dua is a gift from Allah ﷻ, accepted in different forms: a direct response, a protection from harm, or stored reward in the Hereafter. So never despair, keep calling upon the One who is always near.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Common Duas")
    }
}

struct TasbihView: View {
    @EnvironmentObject var settings: Settings
    
    @State private var counters: [Int: Int] = [:]
    @State private var selectedDhikrIndex: Int = 0
    
    let tasbihData: [(arabic: String, english: String, translation: String)] = [
        (arabic: "سُبْحَانَ اللّٰه", english: "Subhanallah", translation: "Glory be to Allah"),
        (arabic: "الْحَمْدُ لِلّٰه", english: "Alhamdullilah", translation: "Praise be to Allah"),
        (arabic: "اللّٰهُ أَكْبَر", english: "Allahu Akbar", translation: "Allah is the Greatest"),
        (arabic: "أَسْتَغْفِرُ اللّٰه", english: "Astaghfirullah", translation: "I seek Allah's forgiveness"),
    ]
    
    private func binding(for index: Int) -> Binding<Int> {
        Binding<Int>(
            get: { self.counters[index, default: 0] },
            set: { self.counters[index] = $0 }
        )
    }
    
    var body: some View {
        List {
            Section(header: Text("GLORIFICATIONS OF ALLAH ﷻ‎")) {
                ForEach(tasbihData.indices, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedDhikrIndex == index ? settings.accentColor.color.opacity(0.15) : .white.opacity(0.0001))
                            #if !os(watchOS)
                            .padding(.horizontal, -12)
                            #else
                            .padding(.horizontal, -6)
                            .padding(.vertical, -7)
                            #endif
                        
                        TasbihRow(tasbih: tasbihData[index], counter: binding(for: index))
                    }
                    #if os(watchOS)
                    .padding(.vertical, 12)
                    #endif
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation {
                            self.selectedDhikrIndex = index
                        }
                    }
                }
            }
                
            let selectedDhikr = tasbihData[selectedDhikrIndex]
            let counterBinding = binding(for: selectedDhikrIndex)
                
            Section {
                ZStack {
                    ProgressCircleView(progress: counterBinding.wrappedValue)
                        .scaledToFit()
                        .frame(maxWidth: 185, maxHeight: 185)
                    
                    VStack(alignment: .center, spacing: 5) {
                        Text(selectedDhikr.arabic)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(settings.accentColor.color)
                        
                        Text(selectedDhikr.english)
                            .font(.subheadline)
                        
                        CounterView(counter: counterBinding)
                    }
                }
                .padding()
                .cornerRadius(15)
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    settings.hapticFeedback()
                    counters[selectedDhikrIndex, default: 0] += 1
                }
            }
        }
        .onAppear {
            for index in tasbihData.indices {
                counters[index] = counters[index] ?? 0
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Tasbih Counter")
    }
}

struct ProgressCircleView: View {
    var progress: Int
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        let progressFraction = CGFloat(progress % 33) / 33
        return ZStack {
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(settings.accentColor.color)

            Circle()
                .trim(from: 0.0, to: progressFraction)
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                .foregroundColor(settings.accentColor.color)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progressFraction)
        }
    }
}

struct CounterView: View {
    @EnvironmentObject var settings: Settings
    
    @Binding var counter: Int

    var body: some View {
        VStack(alignment: .center) {
            Text("\(counter)")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.horizontal, 2)

            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

struct TasbihRow: View {
    @EnvironmentObject var settings: Settings
    
    let tasbih: (arabic: String, english: String, translation: String)
    
    @Binding var counter: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(tasbih.arabic)
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
                
                Text(tasbih.english)
                    .font(.subheadline)
                
                Text(tasbih.translation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                HStack {
                    Image(systemName: "minus.circle")
                        .foregroundColor(counter == 0 ? .secondary : settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()
                            
                            if counter > 0 {
                                counter -= 1
                            }
                        }
                    
                    Text("\(counter)")
                    
                    Image(systemName: "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()
                            
                            counter += 1
                        }
                }
                
                Text("Reset")
                    .font(.subheadline)
                    .onTapGesture {
                        settings.hapticFeedback()
                        counter = 0
                    }
            }
        }
        #if !os(watchOS)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = tasbih.arabic
                settings.hapticFeedback()
            }) {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                UIPasteboard.general.string = tasbih.english
                settings.hapticFeedback()
            }) {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                UIPasteboard.general.string = tasbih.translation
                settings.hapticFeedback()
            }) {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }
}

struct Root: Codable {
    let code: Int
    let status: String
    let data: [NameOfAllah]
}

struct NameTranslation: Codable {
    let meaning: String
    let desc: String
}

struct NameOfAllah: Codable, Identifiable {
    var id: String { "\(number)" }

    let name: String
    let transliteration: String
    let number: Int
    let found: String
    let en: NameTranslation

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s.filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped)
               .lowercased()
    }

    var searchTokens: [String] {
        [
            Self.clean(name),
            Self.clean(transliteration),
            Self.clean(en.meaning),
            Self.clean(en.desc),
            Self.clean(found),
            "\(number)",
            arabicNumberString(from: number)
        ]
    }
}

final class NamesViewModel: ObservableObject {
    static let shared = NamesViewModel()
    
    @Published var namesOfAllah: [NameOfAllah] = []
    
    private init() { loadJSON() }
    
    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "99_Names_Of_Allah", withExtension: "json") else {
            logger.debug("❌ 99 Names JSON not found."); return
        }
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let root = try JSONDecoder().decode(Root.self, from: data)
                DispatchQueue.main.async { self.namesOfAllah = root.data }
            } catch {
                logger.debug("❌ JSON decode error: \(error)")
            }
        }
    }
}

struct NamesView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var namesData: NamesViewModel
    
    @AppStorage("showDescription") private var showDescription = false
    @State private var searchText = ""
    
    private var cleanedSearch: String { Self.clean(searchText) }
    
    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s.filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }
    
    private func matches(_ name: NameOfAllah) -> Bool {
        guard !cleanedSearch.isEmpty else { return true }
        return name.searchTokens.contains { $0.contains(cleanedSearch) } ||
               Int(cleanedSearch) == name.number
    }
    
    var body: some View {
        VStack {
            List {
                Section("DESCRIPTION") {
                    Text("Prophet Muhammad ﷺ said, “Allah has 99 names, and whoever believes in their meanings and acts accordingly, will enter Paradise” (Bukhari 6410).")
                    .font(.body)
                    
                    Toggle("Show Description", isOn: $showDescription.animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                }
                
                Section("99 NAMES") {
                    ForEach(namesData.namesOfAllah.filter(matches)) { name in
                        NameRow(name: name, showDescription: showDescription)
                    }
                }
            }
            #if os(watchOS)
            .searchable(text: $searchText)
            #endif
            .applyConditionalListStyle(defaultView: true)
            .dismissKeyboardOnScroll()
            
            #if !os(watchOS)
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding(.horizontal, 8)
            #endif
        }
        .navigationTitle("99 Names of Allah")
    }
}

private struct NameRow: View {
    @EnvironmentObject var settings: Settings
    let name: NameOfAllah
    let showDescription: Bool
    
    var body: some View {
        #if !os(watchOS)
        content.contextMenu { copyMenu }
        #else
        content
        #endif
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("First Found: \(String(name.found.prefix(through: name.found.firstIndex(of: ")") ?? name.found.endIndex)))")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text(name.en.meaning).font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(name.name.removeDiacriticsFromLastLetter()) ‑ \(arabicNumberString(from: name.number))")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)
                    Text("\(name.transliteration) ‑ \(name.number)")
                        .font(.subheadline)
                }
            }
            .lineLimit(1).minimumScaleFactor(0.5)
            
            if showDescription {
                Text(name.en.desc)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
    
    #if !os(watchOS)
    private var copyMenu: some View {
        Group {
            menuItem("Copy Arabic", text: name.name.removeDiacriticsFromLastLetter())
            menuItem("Copy Transliteration", text: name.transliteration)
            menuItem("Copy Translation", text: name.en.meaning)
            menuItem("Copy Description", text: name.en.desc)
        }
    }
    
    private func menuItem(_ label: String, text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            settings.hapticFeedback()
        } label: {
            Label(label, systemImage: "doc.on.doc")
        }
    }
    #endif
}

extension String {
    func removeDiacriticsFromLastLetter() -> String {
        guard let last = last else { return self }
        let cleaned = String(last).removingArabicDiacriticsAndSigns
        return cleaned == String(last) ? self : dropLast() + cleaned
    }
}

struct DateView: View {
    @EnvironmentObject private var settings: Settings
    
    @State private var sourceDate = Date()
    @State private var selectedTab: ConversionTab = .hijriToGregorian

    private let hijriCalendar: Calendar = {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "ar")
        return cal
    }()
    private let gregorianCalendar = Calendar(identifier: .gregorian)

    enum ConversionTab { case hijriToGregorian, gregorianToHijri }

    private static let hijriFormatterEn: DateFormatter = {
        let fmt = DateFormatter()
        var hijriCal = Calendar(identifier: .islamicUmmAlQura)
        hijriCal.locale = Locale(identifier: "ar")
        fmt.calendar = hijriCal
        fmt.locale = Locale(identifier: "en")
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        return fmt
    }()
    private static let gregFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        return fmt
    }()
    
    private var convertedDate: Date {
        switch selectedTab {
        case .hijriToGregorian:
            return convert(sourceDate, from: hijriCalendar, to: gregorianCalendar)
        case .gregorianToHijri:
            return convert(sourceDate, from: gregorianCalendar, to: hijriCalendar)
        }
    }

    var body: some View {
        VStack {
            #if !os(watchOS)
            List {
                Section("SELECT DATE") {
                    datePickerSection
                    conversionPicker
                }
                
                Section("CONVERTED DATE") {
                    Text(formatted(convertedDate, using: selectedTab == .hijriToGregorian ? gregorianCalendar : hijriCalendar))
                        .bold()
                        .foregroundColor(settings.accentColor.color)
                }
            }
            #endif
        }
        .navigationTitle("Hijri Converter")
        .applyConditionalListStyle(defaultView: true)
    }
        
    @ViewBuilder
    private var datePickerSection: some View {
        let calendar = selectedTab == .hijriToGregorian ? hijriCalendar : gregorianCalendar
        let title = selectedTab == .hijriToGregorian ? "Select Hijri Date" : "Select Gregorian Date"
        VStack(alignment: .leading) {
            #if !os(watchOS)
            DatePicker(title, selection: $sourceDate.animation(.easeInOut), displayedComponents: .date)
                .environment(\.calendar, calendar)
                .datePickerStyle(.graphical)
                .frame(maxHeight: 400)
            #endif
        }
    }
    
    @ViewBuilder
    private var conversionPicker: some View {
        Picker("Conversion Type", selection: $selectedTab.animation(.easeInOut)) {
            Text("Hijri to Gregorian").tag(ConversionTab.hijriToGregorian)
            Text("Gregorian to Hijri").tag(ConversionTab.gregorianToHijri)
        }
        #if !os(watchOS)
        .pickerStyle(.segmented)
        #endif
    }
    
    private func convert(_ date: Date, from src: Calendar, to dst: Calendar) -> Date {
        dst.date(from: src.dateComponents([.year, .month, .day], from: date)) ?? Date()
    }
    
    private func formatted(_ date: Date, using calendar: Calendar) -> String {
        if calendar.identifier == .islamicUmmAlQura {
            return Self.hijriFormatterEn.string(from: date)
        } else {
            return Self.gregFormatter.string(from: date)
        }
    }
}

private struct Wallpaper: Identifiable {
    let id = UUID()
    let imageName: String
    let description: String
}

private let wallpapers: [Wallpaper] = [
    Wallpaper(imageName: "Palestine Wallpaper", description: "FREE PALESTINE PHONE WALLPAPER"),
    Wallpaper(imageName: "Phone Wallpaper", description: "AL‑ISLAM PHONE WALLPAPER"),
    Wallpaper(imageName: "Laptop Wallpaper", description: "LAPTOP (16:9) WALLPAPER"),
    Wallpaper(imageName: "Desktop Wallpaper", description: "DESKTOP (21:9) WALLPAPER"),
]

struct WallpaperView: View {
    @EnvironmentObject private var settings: Settings
    
    var body: some View {
        List {
            ForEach(wallpapers) { WallpaperCell(wallpaper: $0) }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Wallpapers")
    }
}

private struct WallpaperCell: View {
    let wallpaper: Wallpaper
    
    var body: some View {
        Section(header: Text(wallpaper.description)) {
            Image(wallpaper.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                #if !os(watchOS)
                .contextMenu {
                    Button {
                        if let uiImg = UIImage(named: wallpaper.imageName) {
                            UIPasteboard.general.image = uiImg
                        }
                    } label: {
                        Label("Copy Image", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        guard let uiImg = UIImage(named: wallpaper.imageName) else { return }
                        
                        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                            guard status == .authorized || status == .limited else { return }
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAsset(from: uiImg)
                            })
                        }
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                }
                #endif
        }
    }
}
