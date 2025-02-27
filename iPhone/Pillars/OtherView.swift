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
            
            NavigationLink(destination: JummuahView()) {
                Text("Jummuah (Friday) Prayer")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: AdhanView()) {
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
            NavigationLink(destination: TajweedView()) {
                Text("Tajweed")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: JuzView()) {
                Text("30 Juz of the Quran")
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
                Text("“O you who have believed, when you rise to [perform] prayer, wash your faces and your forearms to the elbows and wipe over your heads and [wash] your feet to the ankles.” (Quran 5:6)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                Text("Wudhu ensures physical cleanliness and also prepares one spiritually to stand before Allah (Glorified and Exalted be He).")
                    .font(.body)
                Text("It is recommended to perform Wudhu before sleeping as well, following the Sunnah of the Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
                Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)
                Text("“When a Muslim or a believer washes his face (in wudhu/ablution), every sin he contemplated with his eyes, will be washed away from his face along with water, or with the last drop of water; when he washes his hands, every sin they wrought will be effaced from his hands with the water, or with the last drop of water; and when he washes his feet, every sin towards which his feet have walked will be washed away with the water or with the last drop of water with the result that he comes out pure from all sins.” (Sahih Muslim 244)")
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
                Text("It is also recommended before attending Jummuah (Friday) prayer, entering Ihram for Hajj or Umrah, and after washing a deceased person.")
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
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Wudhu and Ghusl")
    }
}

struct JummuahView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Jummuah (جُمُعَة) comes from the Arabic word meaning “congregation” or “Friday.” It refers to the Friday congregational prayer that replaces Dhuhr.")
                    .font(.body)

                Text("Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)

                Text("“O you who have believed, when [the adhan] is called for the prayer on the day of Jumu’ah [Friday], then proceed to the remembrance of Allah and leave trade. That is better for you, if you only knew.” (Quran 62:9)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Jummuah prayer consists of a sermon (**Khutbah - خُطْبَة**) followed by a two-rak’ah Salah led by the Imam. It is obligatory for Muslim men who can attend, though it is not obligatory for women.")
                    .font(.body)

                Text("If Jummuah is missed at the mosque, one performs the full Dhuhr prayer (4 rak’ahs).")
                    .font(.body)
            }

            Section(header: Text("IMPORTANCE")) {
                Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“The best day on which the sun has risen is Friday; on it Adam was created, on it he was admitted to Paradise, and on it he was expelled therefrom.” (Sahih Muslim 854)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Friday is considered the best day of the week in Islam. It unites the community, strengthens social bonds, and serves as a weekly reminder of our responsibilities toward Allah (Glorified and Exalted be He) and humanity.")
                    .font(.body)
            }

            Section(header: Text("RECOMMENDED PRACTICES")) {
                Text("Muslims are encouraged to engage in specific acts of worship on Jummuah:")
                    .font(.body)

                Text("1. **Reciting Surah Al-Kahf (سُورَة ٱلْكَهْف):** The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“Whoever reads Surah Al-Kahf on Friday will have a light between this Friday and the next.” (Mishkat al-Masabih 2175)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("2. **Sending Salawat on the Prophet (peace and blessings be upon him):**")
                    .font(.body)

                Text("Increase your supplications for me on the day and night of Friday. Whoever blesses me once, Allah will bless him ten times.” (al-Sunan al-Kubra lil-Bayhaqi 5994)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("3. **Making Dua (Supplication)**: There is a special hour on Friday during which all supplications are accepted. The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)

                Text("“Friday is twelve hours in which there is no Muslim slave who asks Allah for something but He will give it to him, so seek it in the last hour after Asr.” (Sunan an-Nasa'i 1389)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("ETIQUETTE")) {
                Text("Observing proper etiquette during Jummuah is essential:")
                    .font(.body)

                Text("1. Arrive early to the mosque and sit attentively during the Khutbah.")
                    .font(.body)

                Text("2. Wear clean and modest clothing as Friday is a day of significance.")
                    .font(.body)

                Text("3. Avoid distractions, such as using phones, during the sermon.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Jummuah")
    }
}

struct AdhanView: View {
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
        .applyConditionalListStyle(defaultView: true)
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
        .applyConditionalListStyle(defaultView: true)
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
                
                Text("“And [He wants] for you to complete the period and to glorify Allah for that [to] which He has guided you; and perhaps you will be grateful.” (Quran 2:185)")
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
        .applyConditionalListStyle(defaultView: true)
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
                
                Text("“Indeed, the number of months with Allah is twelve [lunar] months in the register of Allah [from] the day He created the heavens and the earth; of these, four are sacred.” (Quran 9:36)")
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
                
                Text("“Indeed, the number of months with Allah is twelve... of these, four are sacred. That is the correct religion, so do not wrong yourselves during them.” (Quran 9:36)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .navigationTitle("Hijri Calendar")
        .applyConditionalListStyle(defaultView: true)
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

                Text("“And recite the Quran with measured recitation.” (Quran 73:4)")
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
        .applyConditionalListStyle(defaultView: true)
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

                Text("“So when the Quran is recited, then listen to it and pay attention that you may receive mercy.” (Quran 7:204)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("HISTORICAL NOTES")) {
                Text("While the Quran's content remained unchanged since its revelation, the formal division into 30 Juz was standardized later to facilitate ease of recitation.")
                    .font(.body)

                Text("This structure fosters a daily relationship with the Quran and encourages reflection on its meanings.")
                    .font(.body)

                Text("The Prophet Muhammad (peace and blessings be upon him) emphasized balanced recitation, saying:")
                    .font(.body)

                Text("“He who recites the Quran in less than three days does not grasp its meaning.” (Sunan Abu Dawud 1394)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .navigationTitle("Juz")
        .applyConditionalListStyle(defaultView: true)
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
                     “This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as your religion.” (Quran 5:3)
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
        .applyConditionalListStyle(defaultView: true)
    }
}

struct SahabahView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Sahabah (الصَّحَابَة) are the companions of Prophet Muhammad (peace be upon him).")
                    .font(.body)

                Text("They were pivotal in supporting him and spreading Islam. These individuals witnessed the revelation of the Quran and helped preserve the teachings of Islam for future generations.")
                    .font(.body)
            }

            Section(header: Text("FAITH & SACRIFICE")) {
                Text("Many Sahabah embraced Islam in its earliest days, enduring severe persecution and hardships.")
                    .font(.body)

                Text("Their unwavering faith and sacrifices helped establish Islam. Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)

                Text("“And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him.” (Quran 9:100)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("PROMISE OF PARADISE")) {
                Text("Some Sahabah were given glad tidings of Paradise during their lifetimes, such as Abu Bakr, Umar ibn Al-Khattab, Uthman ibn Affan, and Ali ibn Abi Talib (may Allah be pleased with them).")
                    .font(.body)

                Text("They exemplified courage, leadership, and devotion to Islam.")
                    .font(.body)
            }

            Section(header: Text("LEGACY")) {
                Text("The Sahabah's dedication and sacrifice preserved the Quran and Hadith, shaping Islamic beliefs and practices.")
                    .font(.body)

                Text("Their lives inspire Muslims to strive for righteousness and steadfastness.")
                    .font(.body)
            }
        }
        .navigationTitle("The Sahabah")
        .applyConditionalListStyle(defaultView: true)
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

                Text("“The Prophet is more worthy of the believers than themselves, and his wives are [in the position of] their mothers.” (Quran 33:6)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("SUPPORT & CONTRIBUTION")) {
                Text("These women supported the Prophet (peace be upon him) in his mission.")
                    .font(.body)

                Text("They played vital roles in educating the Muslim community, transmitting Hadith, and exemplifying piety and devotion.")
                    .font(.body)
            }

            Section(header: Text("EXAMPLES")) {
                Text("• **Khadijah bint Khuwaylid:** The Prophet’s first wife and staunch supporter, she was the first to believe in his prophethood.")
                    .font(.body)

                Text("• **Aisha bint Abu Bakr:** Known for her knowledge of the Quran and Hadith, she became one of the most important scholars in Islamic history.")
                    .font(.body)
            }

            Section(header: Text("LEGACY")) {
                Text("The lives of the Prophet’s wives highlight the essential role of women in Islamic scholarship and community-building.")
                    .font(.body)

                Text("They are role models for Muslims, inspiring faith, resilience, and devotion.")
                    .font(.body)
            }
        }
        .navigationTitle("The Wives")
        .applyConditionalListStyle(defaultView: true)
    }
}

struct CaliphatesView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The caliphate (الخلافة) represents the leadership of the Muslim community after Prophet Muhammad (peace be upon him).")
                    .font(.body)

                Text("The caliph (خليفة) is responsible for upholding Islamic teachings and governance.")
                    .font(.body)
            }

            Section(header: Text("ABUBAKR & UMAR")) {
                Text("Following the Prophet’s passing, Abu Bakr (may Allah be pleased with him) was chosen as the first caliph.")
                    .font(.body)

                Text("He unified the Muslim community and preserved the Quran. Umar ibn Al-Khattab (may Allah be pleased with him) succeeded him, expanding Islamic territories and establishing governance systems.")
                    .font(.body)
            }

            Section(header: Text("UTHMAN & ALI")) {
                Text("Uthman ibn Affan (may Allah be pleased with him) standardized the Quran’s written form.")
                    .font(.body)

                Text("Ali ibn Abi Talib (may Allah be pleased with him) became the fourth caliph, striving to maintain unity amidst internal challenges.")
                    .font(.body)
            }

            Section(header: Text("RIGHTLY GUIDED CALIPHS")) {
                Text("The Rashidun Caliphs (الخلفاء الراشدون)—Abu Bakr, Umar, Uthman, and Ali (may Allah be pleased with them)—are revered for their piety and adherence to the Quran and Sunnah.")
                    .font(.body)

                Text("The Prophet (peace be upon him) said:")
                    .font(.body)

                Text("“I urge you to follow my Sunnah and the way of the rightly guided caliphs after me.” (Sunan Abi Dawud 4607)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .navigationTitle("The Caliphates")
        .applyConditionalListStyle(defaultView: true)
    }
}
