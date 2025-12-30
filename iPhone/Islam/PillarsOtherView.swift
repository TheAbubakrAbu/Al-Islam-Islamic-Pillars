import SwiftUI

struct PillarsOtherView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        Section(header: Text("PURIFICATION & PRAYER")) {
            NavigationLink(destination: WudhuView()) {
                Text("Wudhu and Ghusl")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: JumuahView()) {
                Text("Jumuah (Friday) Prayer")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: AdhanOtherView()) {
                Text("Adhan (1st Call to Prayer)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: IqamahView()) {
                Text("Iqamah (2nd Call to Prayer)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
        
        Section(header: Text("ISLAMIC OCCASIONS")) {
            NavigationLink(destination: TakbiratView()) {
                Text("Takbirat Al-Eid")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: CalendarView()) {
                Text("Hijri Calendar")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
        
        Section(header: Text("QURAN & TAFSIR")) {
            NavigationLink(destination: CompileView()) {
                Text("Compilation of the Quran")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: TajweedView()) {
                Text("Tajweed")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: JuzView()) {
                Text("The 30 Juz (Parts)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: AhrufView()) {
                Text("The 7 Ahruf (Modes)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: QiraatView()) {
                Text("The 10 Qiraat (Recitations)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
        
        Section(header: Text("HISTORICAL & BIOGRAPHICAL")) {
            NavigationLink(destination: FarewellView()) {
                Text("The Farewell (Final) Sermon")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: SahabahView()) {
                Text("The Sahabah (Companions)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: WivesView()) {
                Text("The Wives of the Prophet")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: CaliphatesView()) {
                Text("The Caliphates")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: MadhabView()) {
                Text("The 4 Madhabs")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct WudhuView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("WUDHU (MINOR ABLUTION)")) {
                Text("Wudhu (وُضُوء) is the ritual purification Muslims perform before Salah (prayer), touching the Quran, or circumambulating the Ka'bah (طَوَاف).")
                    .font(.body)
                Text("It involves washing specific body parts: hands, mouth, nostrils, face, arms, wiping the head, and washing the feet.")
                    .font(.body)
                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                Text("“O you who have believed, when you rise to [perform] prayer, wash your faces and your forearms to the elbows and wipe over your heads and [wash] your feet to the ankles” (Quran 5:6).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                Text("Wudhu ensures physical cleanliness and also prepares one spiritually to stand before Allah (Glorified and Exalted be He).")
                    .font(.body)
                Text("It is recommended to perform Wudhu before sleeping as well, following the Sunnah of the Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
                Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)
                Text("“When a Muslim or a believer washes his face (in wudhu/ablution), every sin he contemplated with his eyes, will be washed away from his face along with water, or with the last drop of water; when he washes his hands, every sin they wrought will be effaced from his hands with the water, or with the last drop of water; and when he washes his feet, every sin towards which his feet have walked will be washed away with the water or with the last drop of water with the result that he comes out pure from all sins” (Sahih Muslim 244).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("GHUSL (MAJOR ABLUTION)")) {
                Text("Ghusl (غُسْل) is a full-body ritual wash performed in specific circumstances, such as after marital relations, menstruation, or postpartum bleeding.")
                    .font(.body)
                Text("It involves washing the entire body thoroughly.")
                    .font(.body)
                Text("Ghusl becomes obligatory to remove major ritual impurity (**Janabah - جَنَابَة**).")
                    .font(.body)
                Text("It is also recommended before attending Jumuah (Friday) prayer, entering Ihram for Hajj or Umrah, and after washing a deceased person.")
                    .font(.body)
            }

            Section(header: Text("SPIRITUAL SIGNIFICANCE")) {
                Text("Both Wudhu and Ghusl signify not only physical cleanliness but also spiritual purification.")
                    .font(.body)
                Text("Performing them with the right intention (niyyah - نِيَّة) draws one closer to Allah and prepares the soul for acts of worship.")
                    .font(.body)
            }

            Section(header: Text("USEFUL LINKS")) {
                Text("How to perform Wudhu: https://www.wikihow.com/Perform-Wudu")
                    .font(.caption)
                Text("How to perform Ghusl: https://zamzam.com/blog/purification-bath-in-islam/")
                    .font(.caption)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Wudhu and Ghusl")
    }
}

struct JumuahView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Jumuah (جُمُعَة) comes from the Arabic word meaning “congregation” or “Friday.” It refers to the Friday congregational prayer that replaces Dhuhr.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)

                Text("“O you who have believed, when [the adhan] is called for the prayer on the day of Jumu’ah [Friday], then proceed to the remembrance of Allah and leave trade. That is better for you, if you only knew” (Quran 62:9).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Jumuah prayer consists of a sermon (**Khutbah - خُطْبَة**) followed by a two-rak’ah Salah led by the Imam. It is obligatory for Muslim men who can attend, though it is not obligatory for women.")
                    .font(.body)

                Text("If Jumuah is missed at the mosque, one performs the full Dhuhr prayer (4 rak’ahs).")
                    .font(.body)
            }

            Section(header: Text("IMPORTANCE")) {
                Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“The best day on which the sun has risen is Friday; on it Adam was created, on it he was admitted to Paradise, and on it he was expelled therefrom” (Sahih Muslim 854).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Friday is considered the best day of the week in Islam. It unites the community, strengthens social bonds, and serves as a weekly reminder of our responsibilities toward Allah (Glorified and Exalted be He) and humanity.")
                    .font(.body)
            }

            Section(header: Text("RECOMMENDED PRACTICES")) {
                Text("Muslims are encouraged to engage in specific acts of worship on Jumuah:")
                    .font(.body)

                Text("1. **Reciting Surah Al-Kahf (سُورَة ٱلْكَهْف):** The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“Whoever reads Surah Al-Kahf on Friday will have a light between this Friday and the next” (Mishkat al-Masabih 2175).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("2. **Sending Salawat on the Prophet (peace and blessings be upon him):**")
                    .font(.body)

                Text("Increase your supplications for me on the day and night of Friday. Whoever blesses me once, Allah will bless him ten times” (al-Sunan al-Kubra lil-Bayhaqi 5994).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("3. **Making Dua (Supplication)**: There is a special hour on Friday during which all supplications are accepted. The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“Friday is twelve hours in which there is no Muslim slave who asks Allah for something but He will give it to him, so seek it in the last hour after Asr” (Sunan an-Nasa'i 1389).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("ETIQUETTE")) {
                Text("Observing proper etiquette during Jumuah is essential:")
                    .font(.body)

                Text("1. Arrive early to the mosque and sit attentively during the Khutbah.")
                    .font(.body)

                Text("2. Wear clean and modest clothing as Friday is a day of significance.")
                    .font(.body)

                Text("3. Avoid distractions, such as using phones, during the sermon.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Jumuah")
    }
}

struct AdhanOtherView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("HISTORY")) {
                Text("The Adhan (أَذَان) is the Islamic call to prayer.")
                    .font(.body)

                Text("It is recited in Arabic to announce the time for each of the five daily prayers.")
                    .font(.body)

                Text("The Adhan originated during the time of Prophet Muhammad (peace and blessings be upon him) in Medina.")
                    .font(.body)

                Text("The method of calling to prayer was revealed through the dream of Abdullah ibn Zaid (may Allah be pleased with him), and the Prophet (peace and blessings be upon him) chose Bilal ibn Rabah (may Allah be pleased with him) to deliver it because of his melodious and powerful voice.")
                    .font(.body)
            }

            Section(header: Text("WORDS OF THE ADHAN")) {
                HStack {
                    Spacer()
                    Text("""
                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ
                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ

                    أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ
                    أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ
                    أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الصَّلَاةِ
                    حَيَّ عَلَى الْفَلَاحِ، حَيَّ عَلَى الْفَلَاحِ

                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ
                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(settings.accentColor.color)
                }

                Text("""
                Allahu Akbar, Allahu Akbar
                Allahu Akbar, Allahu Akbar

                Ashhadu an la ilaha illa Allah
                Ashhadu an la ilaha illa Allah

                Ashhadu anna Muhammadan rasool Allah
                Ashhadu anna Muhammadan rasool Allah

                Hayya 'ala as-salah, Hayya 'ala as-salah
                Hayya 'ala al-falah, Hayya 'ala al-falah

                Allahu Akbar, Allahu Akbar
                La ilaha illa Allah
                """)
                .font(.body)

                Text("""
                Allah is the greatest, Allah is the greatest
                Allah is the greatest, Allah is the greatest

                I bear witness that there is no deity but Allah
                I bear witness that there is no deity but Allah

                I bear witness that Muhammad is the Messenger of Allah
                I bear witness that Muhammad is the Messenger of Allah

                Come to prayer, Come to prayer
                Come to success, Come to success

                Allah is the greatest, Allah is the greatest
                There is no deity but Allah
                """)
                .font(.body)
            }

            Section(header: Text("FAJR ADHAN")) {
                Text("In the Fajr (dawn) Adhan, an additional line is added:")
                    .font(.body)

                Text("الصَّلَاةُ خَيْرٌ مِنَ النَّوْمِ")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.trailing)

                Text("As-salatu khayrun mina-nawm\n(Prayer is better than sleep)")
                    .font(.body)

                Text("This line is repeated twice before concluding the Adhan.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Adhan")
    }
}

struct IqamahView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Iqamah (إِقَامَة) is the second call to prayer, given right before the congregational Salah begins.")
                    .font(.body)

                Text("It is generally shorter than the Adhan and serves as a prompt for the congregation to stand and line up for prayer.")
                    .font(.body)

                Text("Often, the same Mu'adhin (caller) who delivered the Adhan will also deliver the Iqamah, but it can be done by someone else.")
                    .font(.body)
            }

            Section(header: Text("WORDS OF THE IQAMAH")) {
                HStack {
                    Spacer()
                    Text("""
                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ

                    أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الْفَلَاحِ

                    قَدْ قَامَتِ الصَّلَاةُ
                    قَدْ قَامَتِ الصَّلَاةُ

                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ

                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(settings.accentColor.color)
                }

                Text("""
                Allahu Akbar, Allahu Akbar

                Ashhadu an la ilaha illa Allah

                Ashhadu anna Muhammadan rasool Allah

                Hayya 'ala as-salah, Hayya 'ala al-falah

                Qad qamatis-Salah
                Qad qamatis-Salah

                Allahu Akbar, Allahu Akbar

                La ilaha illa Allah
                """)
                .font(.body)

                Text("""
                Allah is the greatest, Allah is the greatest

                I bear witness that there is no deity but Allah

                I bear witness that Muhammad is the Messenger of Allah

                Come to prayer, Come to success

                Prayer has begun
                Prayer has begun

                Allah is the greatest, Allah is the greatest

                There is no deity but Allah
                """)
                .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Iqamah")
    }
}

struct TakbiratView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("EID OCCASIONS")) {
                Text("In Islam, there are two major annual celebrations known as Eid:")
                    .font(.body)
                
                Text("1. **Eid al-Fitr (عيد الفطر):** Celebrated at the end of Ramadan (the month of fasting). It is a time of joy, gratitude to Allah (Glorified and Exalted be He), and giving to the needy (Zakat al-Fitr).")
                    .font(.body)
                
                Text("2. **Eid al-Adha (عيد الأضحى):** Celebrated on the 10th day of Dhu al-Hijjah. It commemorates the willingness of Prophet Ibrahim (peace be upon him) to sacrifice his son Isma'il (peace be upon him). Muslims who are able to do so perform the sacrifice (Qurbani) and distribute the meat to the poor. This Eid coincides with Hajj, the annual pilgrimage to Mecca.")
                    .font(.body)
            }

            Section(header: Text("TAKBIRAT AL-EID")) {
                Text("The Takbirat al-Eid is a special proclamation of Allah’s greatness, recited during the days of Eid.")
                    .font(.body)
                
                Text("For Eid al-Fitr, it begins after the new moon confirming the end of Ramadan and continues until the Eid prayer. For Eid al-Adha, it begins after Arafah Day (9th of Dhu al-Hijjah) and continues until the Eid prayer.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                
                Text("“And [He wants] for you to complete the period and to glorify Allah for that [to] which He has guided you; and perhaps you will be grateful” (Quran 2:185).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("SHORT TAKBIRAT")) {
                Text("This is the short version of the Takbir:")
                    .font(.body)

                HStack {
                    Spacer()
                    Text("الله أكبر الله أكبر لا إله إلا الله، والله أكبر الله أكبر ولله الحمد")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                }

                Text("Allahu Akbar, Allahu Akbar, La Ilaha Illa Allah, Allahu Akbar, Allahu Akbar, wa lillahil hamd")
                    .font(.body)

                Text("Allah is the Greatest, Allah is the Greatest. There is no deity but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.")
                    .font(.body)
            }

            Section(header: Text("LONGER TAKBIRAT")) {
                HStack {
                    Spacer()
                    Text("""
                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللَّهُ

                    اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ

                    اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا

                    لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ، صَدَقَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَأَعَزَّ جُنْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ

                    لَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ

                    اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ، وَعَلَى آلِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَصْحَابِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَنْصَارِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَزْوَاجِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى ذُرِّيَّةِ سَيِّدِنَا مُحَمَّدٍ، وَسَلِّمْ تَسْلِيمًا كَثِيرًا
                    """)
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.trailing)
                }

                Text("""
                Allahu Akbar, Allahu Akbar, Allahu Akbar, La ilaha illa Allah

                Allahu Akbar, Allahu Akbar, wa Lillahil Hamd

                Allahu Akbar Kabira, wal Hamdu Lillahi Kathira, wa Subhan Allahi bukratan wa asila

                La ilaha illa Allahu Wahdah, sadaqa wa’dah, wa nasara abdah, wa a’azza jundahu wa hazama al-Ahzaba wahdah

                La ilaha illa Allah, wa la na’budu illa iyyah, mukhliseena lahud-deen, walaw karihal kafirun

                Allahumma salli ‘ala Sayyidina Muhammad, wa ‘ala ali Sayyidina Muhammad, wa ‘ala ashabi Sayyidina Muhammad, wa ‘ala ansari Sayyidina Muhammad, wa ‘ala azwaji Sayyidina Muhammad, wa ‘ala dhurriyyati Sayyidina Muhammad, wa sallim tasliman kathira
                """)
                .font(.body)

                Text("""
                “Allah is the Greatest, Allah is the Greatest, Allah is the Greatest; There is no deity but Allah.
                
                Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.

                Allah is the Greatest in greatness; much praise be to Allah; and Glory be to Allah in the morning and evening.
                
                There is no deity but Allah alone. He fulfilled His promise, granted victory to His servant, and honored His army, and He alone defeated the confederates.

                There is no deity but Allah; we do not worship anyone but Him, being sincere in faith and devotion to Him, even if the disbelievers dislike it.
                
                O Allah, send Your blessings on our master Muhammad, and on the family of our master Muhammad, on the companions of our master Muhammad, on the supporters of our master Muhammad, on the wives of our master Muhammad, and on the descendants of our master Muhammad, and bestow upon them abundant peace.”
                """)
                .font(.body)
            }
        }
        .navigationTitle("Takbirat Al-Eid")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct CalendarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Hijri calendar, also known as the Islamic or Lunar Hijri calendar, consists of 12 lunar months in a year of 354 or 355 days.")
                    .font(.body)
                
                Text("It is used to determine key Islamic dates such as Ramadan, Hajj, and the two Eid festivals. The reference point (epoch) of the calendar is the Hijrah—the migration of Prophet Muhammad (peace and blessings be upon him) from Mecca to Medina in 622 CE.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                
                Text("“Indeed, the number of months with Allah is twelve [lunar] months in the register of Allah [from] the day He created the heavens and the earth; of these, four are sacred” (Quran 9:36).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("DETAILS")) {
                Text("""
                     Each Hijri month begins with the sighting of the new moon. The 12 months are as follows:
                     
                     1. **Muharram (مُحَرَّم)** – One of the sacred months
                     2. **Safar (صَفَر)** 
                     3. **Rabi al-Awwal (رَبِيع ٱلْأَوَّل)**
                     4. **Rabi al-Thani (رَبِيع ٱلثَّانِي)** 
                     5. **Jumada al-Awwal (جُمَادَىٰ ٱلْأَوَّل)** 
                     6. **Jumada al-Thani (جُمَادَىٰ ٱلثَّانِي)** 
                     7. **Rajab (رَجَب)** – A sacred month
                     8. **Shaaban (شَعْبَان)** – The month preceding Ramadan
                     9. **Ramadan (رَمَضَان)** – The month of fasting
                     10. **Shawwal (شَوَّال)** – The month following Ramadan
                     11. **Dhul-Qadah (ذُو ٱلْقَعْدَة)** – A sacred month
                     12. **Dhul-Hijjah (ذُو ٱلْحِجَّة)** – A sacred month, the month of Hajj and Eid al-Adha
                     """)
                .font(.body)
                
                Text("A Hijri year is approximately 11 days shorter than a Gregorian year, causing Islamic events to shift earlier each Gregorian year. Muslims worldwide use this calendar for religious observances, including fasting in Ramadan, undertaking Hajj, and celebrating Eid al-Fitr and Eid al-Adha.")
                    .font(.body)
            }
            
            Section(header: Text("SACRED MONTHS")) {
                Text("Four of the Hijri months are considered sacred: **Muharram**, **Rajab**, **Dhul-Qadah**, and **Dhul-Hijjah**.")
                    .font(.body)
                
                Text("These months are distinguished by their sanctity and prohibition of warfare, emphasizing peace and reflection.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                
                Text("“Indeed, the number of months with Allah is twelve... of these, four are sacred. That is the correct religion, so do not wrong yourselves during them” (Quran 9:36).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .navigationTitle("Hijri Calendar")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct CompileView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("From the first revelation, the Quran was preserved by the Companions through precise memorization (hifdh) and careful writing on parchments, leather, bones, and leaves. Prophet Muhammad (peace and blessings be upon him) had official scribes (including Zayd ibn Thabit) who wrote verses as they were revealed.")
                    .font(.body)

                Text("Every year in Ramadan, Jibril (Gabriel) reviewed the Quran with Prophet Muhammad (peace and blessings be upon him); in the final year this review occurred twice (al-Ardah al-Akhirah). Prophet Muhammad (peace and blessings be upon him) taught the Companions the exact wording, pronunciation, and the order in which the surahs and ayat should be recited.")
                    .font(.body)
            }

            Section(header: Text("ALLAH’S PROMISE OF PRESERVATION")) {
                Text("“Indeed, We have sent down the Reminder, and indeed, We will be its Guardian.” (Quran 15:9)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("“Move not your tongue with it to hasten it. Indeed, upon Us is its collection and its recitation. So when We have recited it, then follow its recitation. Then upon Us is its clarification.” (Quran 75:16–19)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("“And recite the Quran with measured recitation.” (Quran 73:4)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("“[It is] a Quran which We have divided (by intervals) so that you might recite it to the people over a prolonged period, and We have sent it down progressively.” (Quran 17:106)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("DURING THE PROPHET’S LIFETIME ﷺ")) {
                Text("• Memorization first: Many Companions memorized the Quran word-for-word and reviewed it with Prophet Muhammad (peace and blessings be upon him) in prayer and lessons.")
                    .font(.body)
                Text("• Official scribes: Verses were dictated to scribes such as Zayd ibn Thabit, Ubayy ibn Ka‘b, and others, and kept as written fragments verified by Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
                Text("• Annual review: Jibril reviewed the entire Quran with Prophet Muhammad (peace and blessings be upon him) yearly in Ramadan; in the final year, the review occurred twice, confirming wording and order.")
                    .font(.body)
            }

            Section(header: Text("FIRST COMPILATION UNDER ABU BAKR")) {
                Text("After the Battle of Yamamah, many memorizers were martyred. At the counsel of Umar ibn al-Khattab, Caliph Abu Bakr commissioned Zayd ibn Thabit to collect the Quran into one compiled manuscript.")
                    .font(.body)

                Text("Zayd gathered the Quran from written materials and from those who had memorized it, accepting verses only when corroborated by multiple reliable witnesses and his own memorization, all according to what had been reviewed with Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)

                Text("This compiled mushaf was kept with Abu Bakr, then with Umar, and after Umar with Hafsah bint Umar (may Allah be pleased with them).")
                    .font(.body)
            }

            Section(header: Text("STANDARDIZATION UNDER UTHMAN")) {
                Text("As Islam spread, differences in regional reading threatened dispute. Caliph Uthman ibn Affan formed a committee led by Zayd ibn Thabit with senior Qurayshi scholars to produce standardized copies based on the Abu Bakr compilation and the established Uthmanic rasm (consonantal skeleton) that could accommodate the revealed modes.")
                    .font(.body)

                Text("Uthman sent official copies to major centers (e.g., Kufa, Basra, Sham) and asked that non-verified personal materials be retired to prevent confusion between private notes/duas and the Quranic text. The Companions agreed with this measure, preserving unity upon the authenticated text.")
                    .font(.body)

                Text("This standardization did not remove revelation; rather, it unified the community upon the verified mushaf that preserved what remained from the seven Ahruf in the Uthmanic rasm and ensured consistent public recitation.")
                    .font(.body)
            }

            Section(header: Text("CONSENSUS OF THE COMPANIONS")) {
                Text("The Companions — foremost memorizers and teachers — were unanimous in accepting the compilation and the Uthmanic copies. It is widely reported that Abu Bakr, Umar, Uthman, and Ali were among the foremost memorizers and teachers of the Quran, and none objected to the standardized mushaf.")
                    .font(.body)

                Text("Zayd ibn Thabit led the technical work in both Abu Bakr’s and Uthman’s projects, bringing rigorous verification. Senior scholars, including Quraysh experts, reviewed and approved the copies.")
                    .font(.body)
            }

            Section(header: Text("THE FOUR MASTERS & LEADING TRANSMITTERS")) {
                Text("Prophet Muhammad (peace and blessings be upon him) said: “Take the Quran from four: Abdullah ibn Masud, Salim (the freed slave of Abu Hudhayfah), Ubayy ibn Ka‘b, and Mu‘adh ibn Jabal.” (Sahih al-Bukhari)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("These masters, together with others like Zayd ibn Thabit, were key references for wording, recitation, and teaching, anchoring transmission among the Companions and their students.")
                    .font(.body)
            }

            Section(header: Text("AHRUF, QIRAAT, AND THE UTHMANIC RASM")) {
                Text("Prophet Muhammad (peace and blessings be upon him) taught that the Quran was revealed in seven Ahruf (modes) for ease. The Uthmanic rasm allowed what remained of those modes to be read and transmitted through canonical Qiraat verified by chains. The Ten Qiraat (with their twenty riwayaat) are mutawatir and reflect how the prophetic recitation was preserved in writing and oral teaching.")
                    .font(.body)

                Text("Thus, standardization did not limit revelation; it safeguarded it — preventing private notes and unverified materials from being mistaken for the Quran — while preserving the legitimate readings taught by Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
            }

            Section(header: Text("KEY REPORTS (BRIEF)")) {
                Text("• Seven Ahruf: “The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.” (Sahih al-Bukhari; Sahih Muslim)")
                    .font(.body)
                Text("• Double review in final Ramadan (al-Ardah al-Akhirah): reported in authentic narrations.")
                    .font(.body)
                Text("• Abu Bakr’s compilation via Zayd after Yamamah: authentic reports in Sahih collections.")
                    .font(.body)
                Text("• Uthman’s committee (with Zayd) and distribution of official copies: authentic reports in Sahih collections.")
                    .font(.body)
            }

            Section(header: Text("MANUSCRIPT EVIDENCE (HISTORICAL NOTES)")) {
                Text("Early Quranic manuscripts discovered in different regions (e.g., Hijaz, Yemen, Syria, North Africa, Anatolia) reflect the early Uthmanic rasm and align with the text recited today.")
                    .font(.body)

                Text("Examples often cited by historians include: the Birmingham fragments (radiocarbon dated to the earliest period of Islam), folios from Sana’a (including palimpsests showing early layers of writing), and early codices associated with major centers and later libraries (e.g., Topkapi).")
                    .font(.body)

                Text("While scholarly studies analyze paleography, orthography, and dating techniques, the consonantal text aligns with the standardized Uthmanic tradition, and the Quran remains read globally in the same wording preserved by the Ummah.")
                    .font(.body)
            }

            Section(header: Text("WHY WERE PRIVATE MATERIALS RETIRED?")) {
                Text("Some Companions wrote personal notes — duas, explanations, or hadith — near Quranic passages. To prevent confusion between private annotations and the Quran, and to avoid unchecked variants, Uthman ordered that only the verified official copies be used for public recitation and that other materials be retired.")
                    .font(.body)

                Text("No Companion rejected the standardized mushaf. The community recited, taught, and transmitted the same Quran by memorization and writing through every generation.")
                    .font(.body)
            }

            Section(header: Text("CONTINUITY UNTIL TODAY")) {
                Text("The Quran we hold today is the same revelation taught by Prophet Muhammad (peace and blessings be upon him), preserved through the consensus of the Companions, the Uthmanic rasm, the living tradition of memorization, and the mutawatir Qiraat. Around the world, millions memorize the entire Quran — letter for letter — continuing an unbroken chain of transmission.")
                    .font(.body)

                Text("Public recitation, prayer, and education remain bound to the verified text. The Ummah’s practice fulfills Allah's (Glorified and Exalted be He) promise: its preservation is both textual and living.")
                    .font(.body)
            }

            Section(header: Text("SELECT VERSES & REMINDERS")) {
                Text("“And when the Quran is recited, then listen to it and pay attention that you may receive mercy.” (Quran 7:204)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("“Do they not reflect upon the Quran? If it had been from other than Allah (Glorified and Exalted be He), they would have found within it much contradiction.” (Quran 4:82)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("“Falsehood cannot approach it from before it or from behind it; [it is] a revelation from One All-Wise, Praiseworthy.” (Quran 41:42)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("USEFUL LINKS")) {
                Text("Learn More about the Compilation of the Quran: https://www.youtube.com/watch?v=n281Zyywyn4&t=343s")
                    .font(.caption)
            }
        }
        .navigationTitle("Compilation of the Quran")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct TajweedView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("DEFINITION")) {
                Text("Tajweed (تَجْوِيد) means “to beautify or improve.” In the context of the Quran, it refers to the set of rules for proper pronunciation during Quran recitation, ensuring each letter is articulated with precision.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)

                Text("“And recite the Quran with measured recitation” (Quran 73:4).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("IMPORTANCE")) {
                Text("Tajweed is an essential science in Islam. It preserves the authenticity of Allah's words as revealed to Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)

                Text("By learning Tajweed, Muslims can recite the Quran accurately, reflecting its divine beauty and following the Sunnah of the Prophet (peace and blessings be upon him).")
                    .font(.body)
            }

            Section(header: Text("BENEFITS")) {
                Text("• Ensures proper articulation and pronunciation of Arabic letters.")
                    .font(.body)

                Text("• Enhances the spiritual experience of reciting the Quran.")
                    .font(.body)

                Text("• Avoids errors that might change the meaning of the text.")
                    .font(.body)

                Text("• Fulfills the prophetic tradition of reciting the Quran as it was revealed.")
                    .font(.body)
            }

            Section(header: Text("USEFUL LINKS")) {
                Text("Watch Learn Arabic 101: https://www.youtube.com/@Arabic101")
                    .font(.caption)
            }
        }
        .navigationTitle("Tajweed")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct JuzView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Quran is divided into 114 Surahs (chapters), but it is also split into thirty roughly equal parts, called Juz (plural: Ajza).")
                    .font(.body)

                Text("This division helps Muslims complete the Quran’s recitation systematically, often one Juz per day, especially during Ramadan.")
                    .font(.body)
            }

            Section(header: Text("PURPOSE")) {
                Text("The division into Juz is primarily for convenience rather than thematic arrangement. It enables systematic daily recitation.")
                    .font(.body)

                Text("Many Muslims strive to complete the Quran in Ramadan, reciting one Juz per night in Taraweeh prayers. Each Juz is further divided into two Hizbs, making a total of 60 Hizbs.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)

                Text("“So when the Quran is recited, then listen to it and pay attention that you may receive mercy” (Quran 7:204).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("HISTORICAL NOTES")) {
                Text("While the Quran's content remained unchanged since its revelation, the formal division into 30 Juz was standardized later to facilitate ease of recitation.")
                    .font(.body)

                Text("This structure fosters a daily relationship with the Quran and encourages reflection on its meanings.")
                    .font(.body)

                Text("Prophet Muhammad (peace and blessings be upon him) emphasized balanced recitation, saying:")
                    .font(.body)

                Text("“He who recites the Quran in less than three days does not grasp its meaning” (Sunan Abu Dawud 1394).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .navigationTitle("Thirty Juz")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct AhrufView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحْرُف) — the plural of Harf (حَرْف). The word Harf comes from the Arabic root H–r–f (ح ر ف), meaning “edge, border, side, or angle,” referring to a particular “way” or “mode.” Islamically and Quranically, Ahruf refers to the divinely revealed modes of recitation.")
                    .font(.body)

                Text("A Harf (حَرْف) — literally meaning “edge/side/aspect,” and in this context “a mode/way of reciting” — refers to a divinely revealed manner of recitation that includes slight differences in pronunciation, vowel patterns, pausing/connection, or permitted word-forms, while preserving the exact same meaning and guidance.")
                    .font(.body)

                Text("All seven Ahruf are revelation from Allah (Glorified and Exalted be He). They are not scholarly opinions nor later inventions — they are part of the Quran that Allah (Glorified and Exalted be He) sent down to Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
            }

            Section(header: Text("WHY SEVEN AHRUF?")) {
                Text("The Arabs at the time of revelation had many dialects (Quraysh, Hudhayl, Tamim, Hawazin, etc.). Allah (Glorified and Exalted be He), in His mercy, revealed the Quran in seven modes so that every tribe could recite the Quran easily without difficulty or burden.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) did not reveal seven different Qurans — rather, one Quran with divinely allowed flexibility, making memorization and recitation easier.")
                    .font(.body)
            }

            Section(header: Text("PROPHETIC HADITH ON THE SEVEN AHRUF")) {
                Text("Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.”\n— Sahih al-Bukhari • Sahih Muslim")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Another narration explains how Jibril kept requesting ease for the Ummah:")
                    .font(.body)

                Text("“Jibril recited to me in one harf. I asked him to increase it… until he ended with seven Ahruf.”\n— Sahih Muslim")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("In the famous incident of Umar and Hisham ibn Hakim — both of them recited differently, and Prophet Muhammad (peace and blessings be upon him) said that both were revealed, proving that the variations are not mistakes but revelation.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("DO THE AHRUF AFFECT PRESERVATION?")) {
                Text("No. The Quran remains perfectly preserved — letter for letter, word for word, in every revealed mode. The Ahruf are part of that preservation, not a contradiction to it.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) promised:")
                    .font(.body)

                Text("“Indeed, We have sent down the Reminder, and indeed, We will be its Guardian.” (Quran 15:9)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("The variations in Ahruf do not alter meanings, beliefs, or rulings. Rather, they highlight precision and perfection — the Ummah memorized and transmitted every letter exactly as revealed.")
                    .font(.body)

                Text("Each harf is revealed, preserved, and protected by Allah (Glorified and Exalted be He). Muslims do not choose or invent a harf — we only recite what Allah (Glorified and Exalted be He) revealed through His Messenger, Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
            }

            Section(header: Text("HOW AHRUF WERE PRESERVED")) {
                Text("• Prophet Muhammad (peace and blessings be upon him) taught the Companions each harf personally.\n• Jibril reviewed the Quran with Prophet Muhammad (peace and blessings be upon him) every year in Ramadan.\n• In the year Prophet Muhammad (peace and blessings be upon him) passed away, Jibril reviewed it twice (al-Ardah al-Akhirah).")
                    .font(.body)

                Text("During the caliphate of Uthman (may Allah be pleased with him), the Ummah was unified upon the written Uthmanic mushaf, which preserved what the Ummah recited — containing what remained from the seven Ahruf in the Uthmanic rasm.")
                    .font(.body)

                Text("The Ahruf are preserved through oral transmission, ijazahs, and chains of narration (isnad).")
                    .font(.body)
            }

            Section(header: Text("WHAT ABOUT THE TEN QIRAAT?")) {
                Text("The Ten Qiraat are the mass-transmitted (mutawatir) methods that show how the Ahruf were preserved through the Uthmanic mushaf and teaching traditions.")
                    .font(.body)

                Text("Each Qiraah has an unbroken chain (isnad) from the reciter → to his teacher → back to Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)

                Text("Learn more in the next section: 10 Qiraat (Canonical Recitations).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("USEFUL LINKS")) {
                Text("Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                    .font(.caption)
            }

        }
        .navigationTitle("Seven Ahruf (Modes)")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct QiraatView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Ten Qiraat (قِرَاءَات) — from the root q–r–a (قرأ) meaning “to read/recite” — literally means “readings/recitations.” Islamically and Quranically, a Qiraah (قِرَاءَة) is a specific, verified method of reciting the Quran. The Ten Qiraat are the preserved, mass-transmitted (mutawatir - مُتَوَاتِر) recitations of the Quran — each a precise method taught by Prophet Muhammad (peace and blessings be upon him) and transmitted through authentic chains of narrators (isnad إِسْنَاد). They do not represent different Qurans, but different prophetic ways of reciting the same revelation.")
                    .font(.body)

                Text("As covered in the previous section, the Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحْرُف) — modes of recitation for ease. Jibril (Gabriel) brought these modes to Prophet Muhammad (peace and blessings be upon him), who taught them to the Ummah. The Qiraat show how those Ahruf were preserved in practice through the Uthmanic rasm (الرَّسْم العُثْمَانِي) — the consonantal skeleton of the mushaf (مُصْحَف).")
                    .font(.body)
            }

            Section(header: Text("WHAT IS A QIRAAH?")) {
                Text("A Qiraah (قراءة) is a canonical, authenticated way of reciting the Quran that meets three criteria: (1) agreement with the Uthmanic rasm (الرسم العثماني), (2) sound Arabic language, and (3) authentic, widespread transmission (tawatur تواتر).")
                    .font(.body)

                Text("All Ten Qiraat return to Prophet Muhammad (peace and blessings be upon him). Every reciter has an unbroken chain of students → teachers → Companions → Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Most differences are within established rules of tajwid (تجويد), allowable word-forms and vowels, elongation (madd مد), assimilation (idgham إدغام), imalah (إمالة), and stopping/continuation — while preserving the same meanings and guidance.")
                    .font(.body)

                Text("Important: The Qiraat are not arbitrary. They reflect how the seven Ahruf were preserved through both writing and oral transmission — essentially a “mix and preserve” of the revealed modes into rigorously taught, verifiable recitational methods.")
                    .font(.body)
            }

            Section(header: Text("QIRAAH (قراءة) VS RIWAYAH (رواية)")) {
                Text("• Qiraah: the recitation method attributed to an Imam of recitation (e.g., Nafi, Asim).")
                    .font(.body)
                Text("• Riwayah: the narration/transmission of that Qiraah by a primary rawi (narrator). Each Qiraah has two principal riwayaat (plural of riwayah).")
                    .font(.body)

                Text("Example: “Hafs ‘an Asim” means the riwayah (narration) of Hafs (حفص) from the Qiraah (recitation) of Asim (عاصم). “Warsh ‘an Nafi” means the riwayah of Warsh (ورش) from the Qiraah of Nafi (نافع).")
                    .font(.body)

                Text("Hafs ‘an Asim is the most widespread globally today; that does not mean it is the only right one. All Ten Qiraat (and their 20 riwayaat) are valid, mutawatir, and from Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("AUTHENTICITY & PRESERVATION")) {
                Text("The Ten Qiraat are mutawatir — mass attested by many independent chains. They are part of the precise preservation Allah (Glorified and Exalted be He) promised for His Book.")
                    .font(.body)

                Text("“Indeed, We have sent down the Reminder, and indeed, We will be its Guardian.” (Quran 15:9)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("They do not affect preservation; rather, they manifest it: letter for letter, word for word — in all the ways Prophet Muhammad (peace and blessings be upon him) taught.")
                    .font(.body)
            }

            Section(header: Text("THE FOUR MASTERS OF THE QURAN")) {
                Text("Prophet Muhammad (peace and blessings be upon him) said: “Take the Quran from four: Abdullah ibn Masud, Salim (the freed slave of Abu Hudhayfah), Ubayy ibn Ka‘b, and Mu‘adh ibn Jabal.” (Sahih al-Bukhari)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("These four masters were among the foremost teachers of the Quran among the Companions, and their recitation and teaching shaped subsequent generations of transmitters.")
                    .font(.body)
            }

            Section(header: Text("THE 20 RIWAYAAT (روايات)")) {
                Text("Each Qiraah (recitation method) has two primary riwayaat (narrations). These are the 20 canonical transmissions used in teaching and ijazah (chain certification).")
                    .font(.body)

                Group {
                    Text("• Warsh an Nafi (وَرْش عَنْ نَافِع)").font(.body)
                    Text("• Qalun an Nafi (قَالُون عَنْ نَافِع)").font(.body)

                    Text("• Al-Bazzi an Ibn Kathir (البَزِّي عَنْ ابْنِ كَثِير)").font(.body)
                    Text("• Qunbul an Ibn Kathir (قُنْبُل عَنْ ابْنِ كَثِير)").font(.body)

                    Text("• Ad-Duri an Abu Amr (الدُّورِي عَنْ أَبِي عَمْرٍو)").font(.body)
                    Text("• As-Susi an Abu Amr (السُّوسِي عَنْ أَبِي عَمْرٍو)").font(.body)

                    Text("• Hisham an Ibn Amir (هِشَام عَنْ ابْنِ عَامِر)").font(.body)
                    Text("• Ibn Dhakwan an Ibn Amir (ابْنُ ذَكْوَان عَنْ ابْنِ عَامِر)").font(.body)

                    Text("• Hafs an Asim (حَفْص عَنْ عَاصِم)").font(.body)
                    Text("• Shu'bah an Asim (شُعْبَة عَنْ عَاصِم)").font(.body)
                }

                Group {
                    Text("• Khalaf an Hamzah (خَلَف عَنْ حَمْزَة)").font(.body)
                    Text("• Khallad an Hamzah (خَلَّاد عَنْ حَمْزَة)").font(.body)

                    Text("• Abu al-Harith an Al-Kisai (أَبُو الحَارِث عَنْ الكِسَائِي)").font(.body)
                    Text("• Ad-Duri an Al-Kisai (الدُّورِي عَنْ الكِسَائِي)").font(.body)

                    Text("• Ibn Wardān an Abu Ja'far (ابْنُ وَرْدَان عَنْ أَبِي جَعْفَر)").font(.body)
                    Text("• Ibn Jammaz an Abu Ja'far (ابْنُ جَمَّاز عَنْ أَبِي جَعْفَر)").font(.body)

                    Text("• Ruways an Ya'qub (رُوَيْس عَنْ يَعْقُوب)").font(.body)
                    Text("• Rawh an Ya'qub (رَوْح عَنْ يَعْقُوب)").font(.body)

                    Text("• Ishaq an Khalaf al-Ashir (إِسْحَاق عَنْ خَلَف العَاشِر)").font(.body)
                    Text("• Idris an Khalaf al-Ashir (إِدْرِيس عَنْ خَلَف العَاشِر)").font(.body)
                }
            }

            Section(header: Text("OTHER REPORTED QIRAAT")) {
                Text("There are other reported qiraat besides these Ten. Unlike the Ten Qiraat, which are mutawatir and mass attested, those others do not reach mutawatir status. That does not automatically make them inauthentic — some have isnad to Prophet Muhammad (peace and blessings be upon him) — but because they are not mass attested, we avoid them in public recitation and worship.")
                    .font(.body)

                Text("We recite what is known with certainty (yaqin يقين) to be from Prophet Muhammad (peace and blessings be upon him) — the Ten Qiraat and their 20 riwayaat. This unites the Ummah upon what is rigorously established.")
                    .font(.body)
            }

            Section(header: Text("PRACTICAL STUDY & ADVICE")) {
                Text("• Learn with a qualified teacher who has ijazah (إجازة) and isnad (إسناد). Do not self-invent pronunciations or rely only on apps without verification.")
                    .font(.body)
                Text("• Begin with one riwayah (commonly Hafs ‘an Asim), then explore others (e.g., Warsh ‘an Nafi) as you progress.")
                    .font(.body)
                Text("• Remember: differences are a mercy, not a contradiction. They illuminate the Quran’s depth and precision.")
                    .font(.body)
            }

            Section(header: Text("IN-APP AUDIO")) {
                Text("In this app, you can listen to multiple Qiraat/riwayaat (not all twenty are available). Availability varies by full-surah vs. ayah-by-ayah playback.")
                    .font(.body)
            }

            Section(header: Text("RECAP")) {
                Text("“The Ten Qiraat are the preserved, mass-transmitted (mutawatir) recitations taught by Prophet Muhammad (peace and blessings be upon him), passed down through authentic chains. Each Qiraah is a specific, verified method of reciting the Quran — not a different text. They reflect how the Ahruf were preserved in writing and oral transmission. All Ten Qiraat — and their 20 riwayaat — return to Prophet Muhammad (peace and blessings be upon him).”")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("USEFUL LINKS")) {
                Text("Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                    .font(.caption)

                Text("Learn about the other Qiraat: https://www.youtube.com/watch?v=CeV6w0rCilQ&t=80s")
                    .font(.caption)
            }
        }
        .navigationTitle("Ten Qiraat & 20 Riwayaat")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}


struct FarewellView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("""
                     The Farewell Sermon (خُطْبَةُ ٱلْوَدَاعِ), delivered by Prophet Muhammad (peace be upon him), took place on the 9th of Dhu al-Hijjah in the 10th year of Hijrah (632 CE) in the Uranah Valley near Mount Arafat. This sermon is one of the most significant moments in Islamic history, as it encapsulates key teachings and guidance for Muslims.
                     """)
                .font(.body)

                Text("""
                     During this momentous occasion, Allah (Glorified and Exalted be He) revealed:
                     “This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as your religion” (Quran 5:3).
                     """)
                .font(.body)
                .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("FINAL DAYS OF THE PROPHET")) {
                Text("""
                     After delivering this sermon, the Prophet (peace be upon him) continued to guide the Muslim Ummah until his passing on 12th Rabi’ al-Awwal, 11 AH (632 CE). His final words were, “O Allah, with the highest companions,” expressing his longing to meet Allah. He passed away in the home of Aisha (may Allah be pleased with her), leaving behind a legacy of faith and compassion.
                     """)
                .font(.body)
            }

            Section(header: Text("TEXT OF THE SERMON")) {
                Text("""
                     O People,

                     Listen attentively, for I do not know whether I will be with you again after this year. Convey my words to those who are absent. Just as you regard this day, this month, and this city as sacred, so regard the life and property of every Muslim as a sacred trust. Return goods entrusted to you to their rightful owners. Do not harm one another, for you will meet your Lord, and He will hold you accountable.

                     Allah has forbidden interest; all interest obligations are canceled, starting with those owed to my uncle, Abbas ibn Abd al-Muttalib. Beware of Satan, for he has lost hope of leading you astray in big matters but will try in small ones.

                     O People,

                     You have rights over your women, and they have rights over you. Treat them with kindness, for they are your partners. Provide for them with goodness. Worship Allah, pray your five daily prayers, fast during Ramadan, give Zakat, and perform Hajj if able. 

                     All mankind is from Adam and Eve. No Arab is superior to a non-Arab, nor is a non-Arab superior to an Arab; no white is superior to a black, nor is a black superior to a white—except in piety and good deeds. Every Muslim is a brother to every other Muslim. Do not commit injustices.

                     After me, no prophet will come, and no new religion will be born. I leave behind the Quran and the Sunnah; if you adhere to them, you will never go astray. Be my witness, O Allah, that I have conveyed Your message.
                     """)
                .font(.body)
            }

            Section(header: Text("KEY MESSAGES OF THE SERMON")) {
                Text("""
                     - Sanctity of life, property, and trust.
                     - Abolition of interest (Riba) and unfair practices.
                     - Rights and responsibilities within marriage.
                     - Unity and equality of all humans.
                     - Adherence to the Quran and Sunnah as guidance.
                     """)
                .font(.body)
            }
        }
        .navigationTitle("Farewell Sermon")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct SahabahView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Sahabah (الصَّحَابَة) are the companions of Prophet Muhammad (peace be upon him).")
                    .font(.body)

                Text("They supported him in his mission, witnessed the revelation of the Quran, and preserved the teachings of Islam through word and action.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) praised them in the Quran: “And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct – Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("ABU BAKR AS-SIDDIQ")) {
                Text("Abu Bakr (may Allah be pleased with him) was the Prophet’s (peace be upon him) closest friend and the first adult male to embrace Islam.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “If I were to take a Khalil (close friend) other than my Lord, I would take Abu Bakr” (Sahih al-Bukhari 3656).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("He was known as As-Siddiq (the Truthful) for immediately affirming the Prophet’s Night Journey (Isra’ and Mi’raj). He was chosen as the first Caliph after the Prophet’s death and led the Muslim Ummah with wisdom and justice.")
                    .font(.body)
            }

            Section(header: Text("UMAR IBN AL-KHATTAB")) {
                Text("Umar (may Allah be pleased with him) was known for his strength, justice, and piety. He was the second Caliph and expanded the Islamic state significantly.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “If there were to be a Prophet after me, it would be Umar ibn Al-Khattab” (Sunan al-Tirmidhi 3686).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Allah (Glorified and Exalted be He) revealed verses confirming Umar’s opinions, including the ruling of hijab and the prohibition of alcohol.")
                    .font(.body)
            }

            Section(header: Text("UTHMAN IBN AFFAN")) {
                Text("Uthman (may Allah be pleased with him) was known for his generosity, modesty, and devotion. He compiled the Quran into a single standardized text.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “Every Prophet has a companion in Paradise, and my companion in Paradise is Uthman” (Sunan al-Tirmidhi 3707).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("He funded the expansion of Al-Masjid an-Nabawi and financed the army during the Battle of Tabuk. His contributions earned him repeated praise from the Prophet (peace be upon him).")
                    .font(.body)
            }

            Section(header: Text("ALI IBN ABI TALIB")) {
                Text("Ali (may Allah be pleased with him) was the cousin and son-in-law of the Prophet (peace be upon him). He was a scholar, warrior, and deeply spiritual leader.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “You are to me what Harun was to Musa, except there is no prophet after me” (Sahih Muslim 2404).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("He was the gate of knowledge, and many schools of Islamic thought trace their scholarly roots back to him. He was known for his eloquence, bravery, and deep understanding of Islam.")
                    .font(.body)
            }

            Section(header: Text("MUHAJIREEN & ANSAR")) {
                Text("The Muhajireen were those who emigrated with the Prophet (peace be upon him) from Makkah to Madinah, leaving behind their wealth and homes for the sake of Allah.")
                    .font(.body)

                Text("The Ansar were the residents of Madinah who welcomed the Prophet (peace be upon him) and his followers with open hearts and supported them in every way.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) praised them both: “And [also for] those who were settled in al-Madinah and [adopted] the faith before them. They love those who emigrated to them and find not any want in their breasts of what the emigrants were given but give [them] preference over themselves...” (Quran 59:9).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("LEGACY")) {
                Text("The Sahabah preserved the Quran and Hadith, established justice and governance, and exemplified the moral and ethical teachings of Islam.")
                    .font(.body)

                Text("Their legacy continues to inspire faith, sacrifice, knowledge, and courage in Muslims to this day.")
                    .font(.body)
            }
        }
        .navigationTitle("The Sahabah")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct WivesView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The wives of Prophet Muhammad (peace be upon him) are honored in Islam as the “Mothers of the Believers” (أُمَّهَاتُ الْمُؤْمِنِين).")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)

                Text("“The Prophet is more worthy of the believers than themselves, and his wives are [in the position of] their mothers” (Quran 33:6).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Prophet Muhammad (peace be upon him) married a total of **11 women** throughout his lifetime. At one time, he was married to a maximum of **9 wives** simultaneously—an exception granted to him as a Prophet. This exception was not unique to him; it was also granted to previous prophets due to their elevated responsibilities and status. For example, Prophet Solomon (peace be upon him) is known to have had a large number of wives, traditionally said to be 100 or more.")
                    .font(.body)
            }

            Section(header: Text("SUPPORT & CONTRIBUTION")) {
                Text("These women supported the Prophet (peace be upon him) in his mission.")
                    .font(.body)

                Text("They played vital roles in educating the Muslim community, transmitting Hadith, and exemplifying piety and devotion.")
                    .font(.body)

                Text("Most of his wives were **widows or divorcees**, many of whom were around his age or older. These marriages were not driven by desire but by **wisdom, compassion, and community building**.")
                    .font(.body)

                Text("His marriage to **Khadijah bint Khuwaylid** (may Allah be pleased with her) was monogamous and lasted 24 years. She was about 15 years older than him, and he took no other wife during her lifetime.")
                    .font(.body)
            }

            Section(header: Text("KHADIJAH")) {
                Text("Khadijah bint Khuwaylid (may Allah be pleased with her) was the first person to believe in Prophet Muhammad (peace be upon him) and thus the **first Muslim**. After his first revelation in the cave of Hira, she comforted him, wrapped him in a cloak, and reassured him with her deep insight and love.")
                    .font(.body)

                Text("She said: “Never! By Allah, Allah will never disgrace you. You maintain family ties, speak the truth, support the needy, host guests, and assist those afflicted by calamity” (Sahih al-Bukhari 3).")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) affirmed the beginning of the Prophet’s (peace be upon him) mission in **Surah Al-Muzzammil (73:1)** and **Surah Al-Muddaththir (74:1)**—moments when Khadijah (may Allah be pleased with her) lovingly wrapped and comforted him.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("The Prophet (peace be upon him) said, “She believed in me when no one else did… and Allah granted me children through her and not through any other wife.” He also said, “I was nourished by her love” (Sahih Muslim 2435).")
                    .font(.body)
            }

            Section(header: Text("AISHA")) {
                Text("Aisha bint Abi Bakr (may Allah be pleased with her) was the daughter of Abu Bakr as-Siddiq (may Allah be pleased with him), the closest companion of the Prophet (peace be upon him). She was the most knowledgeable among the people, especially in Hadith and Islamic jurisprudence.")
                    .font(.body)

                Text("She was falsely accused in the incident of al-Ifk, but Allah (Glorified and Exalted be He) revealed her innocence in **Surah An-Nur (24:11–26)**, establishing her purity and honor for all time.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("The Prophet (peace be upon him) was once asked, “Who do you love the most?” He replied, “Aisha.” They asked, “And among men?” He answered, “Her father” (Sahih al-Bukhari 3662).")
                    .font(.body)

                Text("He also said, “The superiority of Aisha to other women is like the superiority of Tharid to other foods” (Sahih Muslim 2446) and, “Take half of your religion from this Humayra (Aisha).”")
                    .font(.body)

                Text("After the Prophet’s (peace be upon him) death, she became one of the greatest scholars of Islam. She taught both men and women and was a source of religious rulings and interpretations.")
                    .font(.body)

                Text("She narrated **2,210 hadiths**, making her the **fourth-highest hadith narrator** of all time. Most of these relate to the Prophet’s private life, which only she had access to. Without Aisha (may Allah be pleased with her), much of the Prophet’s (peace be upon him) household life, worship, and character would not be known today.")
                    .font(.body)
            }

            Section(header: Text("HOW HE TREATED HIS WIVES")) {
                Text("The Prophet (peace be upon him) was the best example of kindness, patience, and love toward his wives. These hadiths reflect his character:")
                    .font(.body)

                Text("• “The best of you are those who are best to their wives, and I am the best of you to my wives” (Sunan al-Tirmidhi 3895).")
                    .font(.body)

                Text("• Aisha (may Allah be pleased with her) said: “The Messenger of Allah (peace be upon him) never struck anything with his hand, not a woman nor a servant” (Sahih Muslim 2328).")
                    .font(.body)

                Text("• “A believing man should not hate a believing woman. If he dislikes one of her characteristics, he will be pleased with another” (Sahih Muslim 1469).")
                    .font(.body)

                Text("• Aisha (may Allah be pleased with her) said: “He used to serve his family, and when the time for prayer came, he would go out to pray” (Sahih al-Bukhari 6039).")
                    .font(.body)
            }

            Section(header: Text("THE ELEVEN WIVES")) {
                Group {
                    Text("• Khadijah bint Khuwaylid (may Allah be pleased with her)")
                    Text("• Sawdah bint Zam’ah (may Allah be pleased with her)")
                    Text("• Aisha bint Abi Bakr (may Allah be pleased with her)")
                    Text("• Hafsah bint Umar (may Allah be pleased with her)")
                    Text("• Zaynab bint Khuzaymah (may Allah be pleased with her)")
                    Text("• Umm Salamah (Hind bint Abi Umayyah) (may Allah be pleased with her)")
                    Text("• Zaynab bint Jahsh (may Allah be pleased with her)")
                    Text("• Juwayriyah bint al-Harith (may Allah be pleased with her)")
                    Text("• Umm Habibah (Ramlah bint Abi Sufyan) (may Allah be pleased with her)")
                    Text("• Safiyyah bint Huyayy (may Allah be pleased with her)")
                    Text("• Maymunah bint al-Harith (may Allah be pleased with her)")
                }
                .font(.body)
            }

            Section(header: Text("WHY SO MANY MARRIAGES?")) {
                Text("These marriages fulfilled many noble purposes:")
                    .font(.body)

                Text("• **Supporting widows** who lost husbands in early battles.")
                    .font(.body)

                Text("• **Forming alliances** with key tribes to strengthen the Muslim community.")
                    .font(.body)

                Text("• **Spreading Islamic knowledge**, as many of his wives became teachers and Hadith narrators.")
                    .font(.body)

                Text("• **Setting legal and social precedents** for Muslim family law and ethics.")
                    .font(.body)
            }

            Section(header: Text("LEGACY")) {
                Text("The lives of the Prophet’s (peace be upon him) wives highlight the essential role of women in Islamic scholarship and community-building.")
                    .font(.body)

                Text("They are role models for Muslims, inspiring faith, resilience, and devotion.")
                    .font(.body)
            }
        }
        .navigationTitle("The Wives")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct CaliphatesView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Caliphate (ٱلْخِلَافَة) refers to the divinely guided system of governance established after the death of Prophet Muhammad (peace be upon him). It aimed to continue his mission of upholding justice, spreading Islam, and preserving the unity of the Ummah.")
                    .font(.body)

                Text("The Caliph (خَلِيفَة), literally “successor“—was entrusted with political, military, judicial, and spiritual leadership, guided by the Qur’an and Sunnah. The first four caliphs, known as the **Rightly Guided Caliphs (ٱلْخُلَفَاء ٱلرَّاشِدُون)**, are regarded as models of righteous rule.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “The Caliphate will remain among you for thirty years, then Allah will give the kingdom to whomever He wills” (Sunan Abi Dawud 4646).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("These thirty years—known as the **Rashidun Caliphate**—represented the ideal Islamic system. The caliphs were selected by **community consensus**, through **consultation (شُورَىٰ)** and even **house-to-house voting**. Men and women alike participated in voicing support, especially in the appointment of Abu Bakr and Uthman (may Allah be pleased with them). This model emphasized justice, humility, accountability, and service to the people.")
                    .font(.body)
            }

            Section(header: Text("ABU BAKR AS-SIDDIQ (632–634 CE)")) {
                Text("Abu Bakr (may Allah be pleased with him), the Prophet’s closest companion and the first adult male to accept Islam, was chosen as the **first caliph** immediately after the Prophet’s passing. He was selected through consensus at Saqifah.")
                    .font(.body)

                Text("He led decisively during a time of crisis, launching the **Riddah Wars** to bring back apostate tribes and false prophets. He initiated the first compilation of the Qur’an into a single manuscript.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “There is no one who has helped me more with his wealth and companionship than Abu Bakr” (Sahih al-Bukhari 3661).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)

                Text("His caliphate lasted just over two years but laid the foundation for unity and stability in the Ummah.")
                    .font(.body)
            }

            Section(header: Text("UMAR IBN AL-KHATTAB (634–644 CE)")) {
                Text("Umar (may Allah be pleased with him) was appointed by Abu Bakr before his death and accepted by the Muslims as the second caliph. He was renowned for justice, strength, and fear of Allah (Glorified and Exalted be He).")
                    .font(.body)

                Text("His 10-year reign witnessed the rapid expansion of Islam into the **Byzantine and Persian Empires**, including Jerusalem and Egypt. He established **public registers**, **courts**, **salaries for soldiers**, and the **Islamic calendar**.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “Indeed, Allah has placed the truth upon Umar’s tongue and heart” (Sunan al-Tirmidhi 3682).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)

                Text("He was assassinated while praying in the masjid and is buried beside the Prophet Muhammad (peace be upon him).")
                    .font(.body)
            }

            Section(header: Text("UTHMAN IBN AFFAN (644–656 CE)")) {
                Text("Uthman (may Allah be pleased with him) was chosen through a **council of six** appointed by Umar. Known for his generosity and modesty, he married two daughters of the Prophet Muhammad (peace be upon him) and was called **Dhu al-Nurayn** (ذُو ٱلنُّورَيْن – the Possessor of Two Lights).")
                    .font(.body)

                Text("He **standardized the Qur’an** to preserve it in one dialect, avoiding future disputes. He sent official copies to major cities and burned differing versions.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said: “Should I not feel shy of the one whom the angels are shy of?” (Sahih Muslim 2401).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)

                Text("Due to political unrest and false accusations, he was unjustly besieged and martyred while reciting the Qur’an.")
                    .font(.body)
            }

            Section(header: Text("ALI IBN ABI TALIB (656–661 CE)")) {
                Text("Ali (may Allah be pleased with him), the cousin and son-in-law of the Prophet Muhammad (peace be upon him), was chosen as the fourth caliph after Uthman’s martyrdom.")
                    .font(.body)

                Text("His caliphate was challenged by internal strife, including the **Battle of the Camel** and **Battle of Siffin**. Despite the trials, he remained committed to justice and truth.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said to him: “You are to me like Harun was to Musa, except that there is no prophet after me” (Sahih Muslim 2404).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)

                Text("Ali was assassinated in Kufah while leading the Fajr prayer. His legacy lives on in scholarship, courage, and moral leadership.")
                    .font(.body)
            }

            Section(header: Text("LEGACY OF THE RASHIDUN")) {
                Text("The Rashidun Caliphs (632–661 CE) ruled with unmatched integrity, transparency, and adherence to prophetic tradition. Their rule was guided by **shura (شُورَىٰ)**, justice, and humility.")
                    .font(.body)

                Text("Though later caliphates transitioned into **hereditary monarchy**, the Prophet Muhammad (peace be upon him) had foretold this change.")
                    .font(.body)

                Text("He said: “The Caliphate after me will last thirty years; then there will be kingship” (Sunan Abi Dawud 4646).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Despite this shift, many later caliphs still contributed greatly to Islamic knowledge, architecture, and global influence.")
                    .font(.body)
            }

            Section(header: Text("THE UMAYYAD CALIPHATE (661–750 CE)")) {
                Text("The Umayyads, beginning with Mu'awiyah ibn Abi Sufyan (may Allah be pleased with him), transitioned the caliphate into a **dynastic monarchy**. Their capital was **Damascus (دِمَشْق)**.")
                    .font(.body)

                Text("They expanded Islam into **al-Andalus (Spain)**, **North Africa**, and **Central Asia**, and made **Arabic** the official administrative language.")
                    .font(.body)

                Text("Though less spiritually exemplary than the Rashidun, the Umayyads left a profound legacy in governance, culture, and infrastructure.")
                    .font(.body)
            }

            Section(header: Text("THE ABBASID CALIPHATE (750–1258 CE)")) {
                Text("The Abbasids overthrew the Umayyads and moved the capital to **Baghdad (بَغْدَاد)**, initiating the **Golden Age of Islam**.")
                    .font(.body)

                Text("They supported **translation**, **science**, **mathematics**, **medicine**, and **philosophy**, and established the renowned **Bayt al-Hikmah (بَيْت ٱلْحِكْمَة – House of Wisdom)**.")
                    .font(.body)

                Text("Although internal divisions weakened the state, their intellectual contributions influenced both the Muslim world and Europe. The empire fell to the Mongols in 1258 CE.")
                    .font(.body)
            }

            Section(header: Text("THE OTTOMAN CALIPHATE (1517–1924 CE)")) {
                Text("The Ottomans, a Turkish dynasty, were the **first non-Arabs** to assume the Islamic Caliphate. After the fall of the Abbasids in Egypt, the caliphate passed to the Ottomans, whose capital was **Istanbul (إِسْطَنْبُول)**.")
                    .font(.body)

                Text("They ruled a vast empire across **Europe**, **Asia**, and **Africa**, preserved **Islamic law (ٱلشَّرِيعَة)**, and defended the **Two Holy Mosques** in **Makkah (مَكَّة)** and **Madinah (ٱلْمَدِينَة)**.")
                    .font(.body)

                Text("The Ottoman Caliphate was officially **abolished in 1924 CE** by Mustafa Kemal Atatürk, ending more than 1,300 years of continuous Islamic political leadership.")
                    .font(.body)
            }
        }
        .navigationTitle("The Caliphates")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}

struct MadhabView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("A **madhhab (مَذْهَب)** is a school of Islamic jurisprudence that provides structured guidance on how to derive and apply rulings from the Qur’an and Sunnah. The plural is **madhahib (مَذَاهِب)**.")
                    .font(.body)

                Text("Madhahib developed as scholars preserved and codified fiqh (فِقْه), or Islamic legal reasoning/jurisprudence, to help Muslims navigate daily life, worship, transactions, and society with clarity and consistency.")
                    .font(.body)

                Text("Following a madhhab ensures one is following a valid, peer-reviewed methodology developed by righteous scholars deeply rooted in the Qur’an, Sunnah, consensus (إِجْمَاع), and analogy (قِيَاس). It is not blind following—it is trust in generations of qualified scholarship.")
                    .font(.body)

                Text("The Prophet Muhammad (peace be upon him) said: “Scholars are the inheritors of the prophets” (Sunan Abi Dawud 3641).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("WHY FOLLOW A MADHHAB?")) {
                Text("Islamic rulings are not always black and white. Scholars developed principles to interpret revelation when texts appeared to conflict or were not explicit.")
                    .font(.body)

                Text("For example, rulings on prayer times, purification, zakah calculation, marriage, and contracts all require detailed interpretation. Madhahib systematize this process based on authentic sources and established rules.")
                    .font(.body)

                Text("Instead of picking rulings randomly or following desire, a madhhab offers **structured, principled, and scholarly guidance**. It helps prevent inconsistency and distortion in religious practice.")
                    .font(.body)
            }

            Section(header: Text("THE FOUR SUNNI MADHAHIB")) {
                Text("**1. Hanafi (حَنَفِي)** — Founded by Imam Abu Hanifah (d. 767 CE). This school is known for its logical rigor and wide use of analogy. It is the most followed madhhab today, especially in **South Asia, Turkey, Central Asia**, and parts of the Balkans.")
                    .font(.body)

                Text("**2. Maliki (مَالِكِي)** — Founded by Imam Malik ibn Anas (d. 795 CE). It heavily relies on the practice of the people of Madinah (عَمَل أَهْل الْمَدِينَة) and gives weight to communal actions. It is dominant in **North and West Africa**.")
                    .font(.body)

                Text("**3. Shafi‘i (شَافِعِي)** — Founded by Imam Muhammad ibn Idris al-Shafi‘i (d. 820 CE). Known for its precise legal methodology and systematic approach to usul al-fiqh (أُصُول الْفِقْه). Popular in **East Africa, Indonesia, Malaysia**, and parts of Egypt and Yemen.")
                    .font(.body)

                Text("**4. Hanbali (حَنْبَلِي)** — Founded by Imam Ahmad ibn Hanbal (d. 855 CE). This school emphasizes hadith and early generation reports, using analogy only when necessary. It is mainly followed in **Saudi Arabia** and parts of the **Gulf region**.")
                    .font(.body)
            }

            Section(header: Text("UNITY THROUGH DIVERSITY")) {
                Text("All four madhahib are valid and respected paths within Ahl al-Sunnah wa al-Jama‘ah (أَهْل السُّنَّة وَالْجَمَاعَة). Though they may differ in legal rulings, they are united in the same ‘aqeedah (عَقِيدَة)—the core beliefs regarding Allah, His names and attributes, prophethood, the Qur’an, the unseen, and the Afterlife.")
                    .font(.body)
                
                Text("This shared creed is why they are all considered part of Ahl al-Sunnah wa al-Jama‘ah. The differences among them are in jurisprudence (fiqh), not faith (‘aqeedah), and reflect the depth and mercy of Islamic legal tradition.")
                    .font(.body)
                
                Text("No single school is “more Islamic“—each preserved knowledge and served the Ummah according to its time and place. Following any of them keeps one on the path of the Prophet (peace be upon him) and his companions.")
                    .font(.body)

                Text("The great Imam Ibn Taymiyyah said: “Every scholar has statements that are accepted and statements that are rejected—only the Messenger of Allah (peace be upon him) is followed in everything” (Majmu‘ al-Fatawa).")
                    .font(.body)
            }

            Section(header: Text("CONCLUSION")) {
                Text("Following a madhhab gives structure to religious life and connects Muslims to a legacy of knowledge, discipline, and unity. While it is not obligatory to follow one, it is highly encouraged, especially for those without deep training in Islamic law.")
                    .font(.body)

                Text("If one is unsure which madhhab to follow, they may follow the trusted local scholars in their community, and Allah (Glorified and Exalted be He) will reward sincerity and effort.")
                    .font(.body)
            }
        }
        .navigationTitle("The 4 Madhabs")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }
}
