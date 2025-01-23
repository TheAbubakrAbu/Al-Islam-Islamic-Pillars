import SwiftUI

struct IslamicPillarsView: View {
    @EnvironmentObject var settings: Settings
        
    var body: some View {
        Section(header: Text("THE 5 PILLARS OF ISLAM")) {
            NavigationLink(destination: ShahaadahView()) {
                Text("Shahaadah (Testimony of Faith)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: SalahView()) {
                Text("Salah (Five Daily Prayers)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: SawmView()) {
                Text("Sawm (Fasting in Ramadan)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: ZakahView()) {
                Text("Zakah (Annual Charity)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: HajjView()) {
                Text("Hajj (Pilgrimate to Mecca)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct ShahaadahView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("The Shahaadah, derived from the Arabic word 'الشَّهَادَة' (Ash-Shahaadah), meaning 'testimony' or 'witnessing,' is the first and most fundamental pillar of Islam. By uttering it with sincerity, a person declares belief in the Oneness of Allah (Glorified and Exalted be He) and acknowledges Muhammad (peace and blessings be upon him) as His final Prophet.")
                    .font(.body)
                
                Text("This simple yet profound statement encapsulates the essence of Islam: the worship of Allah alone and adherence to the teachings of His messenger. Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                Text("“And We sent not before you any messenger except that We revealed to him that, 'There is no deity except Me, so worship Me.'” (Quran 21:25)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("VERSIONS")) {
                Text("There are two common versions of the Shahaadah. Both affirm the fundamental tenets of Islam, but the second version emphasizes the servanthood of Prophet Muhammad (peace and blessings be upon him) to ensure that he is not viewed as divine.")
                    .font(.body)
            }
            
            Section(header: Text("FIRST VERSION")) {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Text("أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ ٱللّٰهِ")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                            .multilineTextAlignment(.trailing)
                            .padding(.vertical, 2)
                    }
                    
                    Text("Ashhadu an la ilaha illa Allah, wa ashhadu anna Muhammad rasul Allah.")
                        .font(.body)
                        .padding(.vertical, 2)
                    
                    Text("“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is the messenger of Allah.”")
                        .font(.body)
                        .padding(.vertical, 2)
                }
            }
            
            Section(header: Text("SECOND VERSION")) {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Text("أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                            .multilineTextAlignment(.trailing)
                            .padding(.vertical, 2)
                    }
                    
                    Text("Ashhadu an la ilaha illa Allah, wa ashhadu anna Muhammad abduhu wa rasuluhu.")
                        .font(.body)
                        .padding(.vertical, 2)
                    
                    Text("“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is His servant and messenger.”")
                        .font(.body)
                        .padding(.vertical, 2)
                }
            }
            
            Section(header: Text("SIGNIFICANCE")) {
                Text("Pronouncing the Shahaadah with sincere faith confirms Tawheed (absolute monotheism) and the acceptance of Muhammad (peace and blessings be upon him) as the final Prophet. Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                Text("“So know [O Muhammad], that there is no deity except Allah.” (Quran 47:19)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Shahaadah is a lifelong declaration of faith and is recited during the daily prayers, serving as a constant reminder of a Muslim's commitment to Allah and His messenger.")
                    .font(.body)
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Shahaadah")
    }
}

struct SalahView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Salah, derived from the Arabic word 'صَلَاة' (Salah), meaning 'prayer' or 'connection,' is the second pillar of Islam. It is an act of worship that establishes a direct link between a Muslim and Allah (Glorified and Exalted be He). Salah is performed five times daily at prescribed times, serving as a constant reminder of a Muslim’s submission and gratitude to Allah.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Indeed, I am Allah. There is no deity except Me, so worship Me and establish prayer for My remembrance.” (Quran 20:14)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("TIMINGS")) {
                Text("The five daily prayers are:").font(.body)
                Text("1. **Fajr (Dawn):** Performed before sunrise.").font(.body)
                Text("2. **Dhuhr (Noon):** Performed after the sun passes its zenith.").font(.body)
                Text("3. **Asr (Afternoon):** Performed in the late afternoon.").font(.body)
                Text("4. **Maghrib (Evening):** Performed just after sunset.").font(.body)
                Text("5. **Isha (Night):** Performed in the late evening.").font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Indeed, prayer has been decreed upon the believers a decree of specified times.” (Quran 4:103)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("METHOD")) {
                Text("Salah involves a sequence of physical movements—standing, bowing, prostrating, and sitting—accompanied by Quranic recitations and supplications.").font(.body)
                Text("It begins with **Takbir** ('Allahu Akbar' – Allah is the Greatest) and ends with **Taslim** ('Assalamu Alaikum wa Rahmatullah' – Peace be upon you and the mercy of Allah).").font(.body)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) instructed:").font(.body)
                Text("“Pray as you have seen me praying.” (Sahih al-Bukhari 631)")
                    .font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("BENEFITS")) {
                Text("Salah purifies the soul, instills discipline, and strengthens a Muslim's relationship with Allah (Glorified and Exalted be He). It keeps one mindful of their Creator throughout the day, offering spiritual peace and balance.")
                    .font(.body)
                
                Text("Salah also serves as a means of expiation for minor sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“The five daily prayers and Friday to Friday are an expiation for what is between them, so long as major sins are avoided.” (Sahih Muslim 233c)").font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("IMPORTANCE OF SALAH")) {
                Text("Salah is the first deed for which a person will be held accountable on the Day of Judgment. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“The first action for which a servant of Allah will be held accountable on the Day of Resurrection will be his prayers. If they are in order, he will have prospered and succeeded. If they are lacking, he will have failed and lost. If there is something defective in his obligatory prayers, then the Almighty Lord will say: See if My servant has any voluntary prayers that can complete what is insufficient in his obligatory prayers. The rest of his deeds will be judged the same way.” (Sunan al-Tirmidhi 413)").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("It is also a key to success in this life and the Hereafter. Allah (Glorified and Exalted be He) says:").font(.body)
                Text("“Successful indeed are the believers. Those who humble themselves in their prayer.” (Quran 23:1-2)").font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("LEARN MORE")) {
                Text("Learn how to perform Salah and its detailed steps here: https://learnsalah.com/")
                    .font(.caption)
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Salah")
    }
}

struct SawmView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Sawm, derived from the Arabic word 'صَوْم' (Sawm), meaning 'abstention' or 'refraining,' is the next pillar of Islam. It refers to fasting, during which Muslims abstain from food, drink, and marital relations from dawn (Fajr) until sunset (Maghrib) with the intention of seeking Allah’s pleasure.")
                    .font(.body)
                
                Text("Fasting during the sacred month of Ramadan is obligatory for all adult Muslims who are physically and mentally capable. Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                Text("“The month of Ramadan [is that] in which was revealed the Quran, a guidance for the people and clear proofs of guidance and criterion.” (Quran 2:185)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("PURPOSE")) {
                Text("Fasting is not merely abstaining from physical needs but also involves refraining from sinful speech, actions, and thoughts. Its purpose is to develop Taqwa (God-consciousness) and purify the soul.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“O you who have believed, decreed upon you is fasting as it was decreed upon those before you that you may become righteous.” (Quran 2:183)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("METHOD")) {
                Text("The fasting day begins before dawn with a recommended Sunnah meal called **Suhoor** (سُحُور) and ends at sunset with **Iftar** (إِفْطَار), traditionally breaking the fast with dates and water as Prophet Muhammad did (peace and blessings be upon him).")
                    .font(.body)
                
                Text("During the fasting hours, Muslims engage in acts of worship such as prayer, Quran recitation, and charity.").font(.body)
            }
            
            Section(header: Text("EXEMPTIONS")) {
                Text("Fasting is mandatory for all capable Muslims, but there are exemptions for:")
                    .font(.body)
                Text("1. The sick.").font(.body)
                Text("2. Travelers.").font(.body)
                Text("3. Pregnant or nursing women.").font(.body)
                Text("4. Women during menstruation.").font(.body)
                Text("Those exempted are required to make up the missed fasts later or pay fidya (compensation) if they cannot fast.")
                    .font(.body)
            }
            
            Section(header: Text("SPIRITUAL BENEFITS")) {
                Text("Sawm is a means of spiritual growth and self-discipline. It helps Muslims focus on worship, gratitude, and reliance on Allah (Glorified and Exalted be He). It also fosters empathy for the less fortunate and strengthens the sense of community. Prophet Muhammad (peace and blessings be upon him) said: ")
                    .font(.body)
                
                Text("\"Verily, the smell of the mouth of a fasting person is better to Allah than the smell of musk.\" (Sahih al-Bukhari 5927)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("REWARDS OF FASTING")) {
                Text("The Prophet Muhammad (peace and blessings be upon him) also said:").font(.body)
                Text("“Whoever observes fasts during the month of Ramadan out of sincere faith, and hoping to attain Allah's rewards, then all his past sins will be forgiven.” (Sahih al-Bukhari 38)").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("Fasting is an act of worship that purifies the heart and brings immense spiritual rewards from Allah.")
                    .font(.body)
            }
            
            Section(header: Text("SIGNIFICANCE OF RAMADAN")) {
                Text("Ramadan is not only the month of fasting but also the month in which the Quran was revealed. It is a time of intense worship and reflection, culminating in Laylat al-Qadr (the Night of Decree), which is better than a thousand months.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Indeed, We sent the Quran down during the Night of Decree. And what can make you know what is the Night of Decree? The Night of Decree is better than a thousand months.” (Quran 97:1-3)").font(.body).foregroundColor(settings.accentColor.color)
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Sawm")
    }
}

struct ZakahView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Zakah, derived from the Arabic word 'زَكَاة' (Zakah), meaning 'purification' or 'growth,' is another pillar of Islam. It is an obligatory form of charity prescribed by Allah (Glorified and Exalted be He) to purify wealth and foster compassion. By giving Zakah, Muslims purify their wealth, acknowledge Allah’s blessings, and help build a more just and equitable society.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Take, [O Muhammad], from their wealth a charity by which you purify them and cause them to increase, and invoke [Allah’s blessings] upon them. Indeed, your invocations are reassurance for them. And Allah is Hearing and Knowing.” (Quran 9:103)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("PURPOSE")) {
                Text("The purpose of Zakah is threefold:").font(.body)
                Text("1. **Spiritual Purification**: Cleanses the soul from greed and materialism, fostering gratitude to Allah (Glorified and Exalted be He).").font(.body)
                Text("2. **Economic Justice**: Redistributes wealth to support those in need, reducing poverty and inequality.").font(.body)
                Text("3. **Community Strengthening**: Strengthens ties within the Muslim community by helping the less fortunate.").font(.body)
            }
            
            Section(header: Text("OBLIGATIONS AND ELIGIBILITY")) {
                Text("Zakah is obligatory for every Muslim who possesses wealth above the **Nisab** (minimum threshold of wealth) for a full lunar year. The Nisab is calculated based on the value of 85 grams of gold or 595 grams of silver.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) specifies eight categories of Zakah recipients in the Quran:").font(.body)
                Text("“Zakah expenditures are only for the poor, the needy, those employed to collect it, for bringing hearts together, for freeing captives [or slaves], for those in debt, for the cause of Allah, and for the traveler [in need].” (Quran 9:60)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("CALCULATION")) {
                Text("Zakah is calculated at a standard rate of **2.5%** of one’s total savings and assets that meet the Nisab threshold. This includes cash, gold, silver, investments, and business assets.")
                    .font(.body)
                Text("Muslims are encouraged to calculate and distribute their Zakah during Ramadan, although it can be paid at any time of the year.")
                    .font(.body)
            }
            
            Section(header: Text("REWARDS OF ZAKAH")) {
                Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“Charity does not decrease wealth, no one forgives another except that Allah increases his honor, and no one humbles himself for the sake of Allah except that Allah raises his status.” (Sahih Muslim 2588)").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("He also said:").font(.body)
                Text("“Protect yourself from Hellfire even with half a date [in charity].” (Sahih al-Bukhari 1417)").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("Fulfilling the obligation of Zakah not only earns Allah’s pleasure but also protects one’s soul and wealth from harm.")
                    .font(.body)
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Zakah")
    }
}

struct HajjView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Hajj, derived from the Arabic word 'حَجّ' (Hajj), meaning 'to intend a journey' or to 'to make a pilgrimage,' is the fifth and final pillar of Islam. It is an obligatory pilgrimage to the Kaaba in Mecca, the Qibla (direction of prayer) for Muslims worldwide. Hajj takes place annually in the last and twelfth Islamic month of Dhul-Hijjah and serves as a profound act of worship and submission to Allah (Glorified and Exalted be He).")
                    .font(.body)
                
                Text("Hajj is a journey of spiritual renewal, forgiveness, and unity among Muslims, symbolizing submission to Allah and the equality of all believers.")
                    .font(.body)
            }
            
            Section(header: Text("OBLIGATION")) {
                Text("Hajj is mandatory for every Muslim who is physically and financially capable at least once in their lifetime. Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                Text("“And [due] to Allah from the people is a pilgrimage to the House – for whoever is able to find thereto a way. But whoever disbelieves – then indeed, Allah is free from need of the worlds.” (Quran 3:97)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Hajj is both a personal and communal act of worship, emphasizing the importance of fulfilling one's obligations to Allah and the global Muslim community.")
                    .font(.body)
            }
            
            Section(header: Text("HISTORICAL ROOTS")) {
                Text("Hajj commemorates the unwavering faith and sacrifices of Prophet Ibrahim (Abraham, peace be upon him), his wife Hajar (may Allah be pleased with her), and their son Prophet Ismail (Ishmael, peace be upon him).")
                    .font(.body)
                
                Text("Prophet Ibrahim (peace be upon him) and Prophet Ismail (peace be upon him) were commanded by Allah to build the Kaaba, the sacred House of Allah. Allah says in the Quran:")
                    .font(.body)
                Text("“And [mention] when Ibrahim was raising the foundations of the House and [with him] Ismail, [saying], 'Our Lord, accept [this] from us. Indeed You are the Hearing, the Knowing.'” (Quran 2:127)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The rituals of Hajj also commemorate Hajar's (may Allah be pleased with her) trust in Allah as she searched for water for her infant son, Ismail. Her desperate search between the hills of Safa and Marwah is reenacted during Hajj as the Sa’i.")
                    .font(.body)
            }
            
            Section(header: Text("RITUALS OF HAJJ")) {
                Text("The key rituals of Hajj include:").font(.body)
                Text("1. **Ihram**: Entering a state of purity and wearing special garments.").font(.body)
                Text("2. **Tawaf**: Circling the Kaaba seven times in reverence.").font(.body)
                Text("3. **Sa’i**: Walking between the hills of Safa and Marwah, commemorating Hajar’s (may Allah be pleased with her) search for water.").font(.body)
                Text("4. **Arafat**: Standing in prayer and supplication at the Plain of Arafat, seeking Allah’s forgiveness.").font(.body)
                Text("5. **Ramy al-Jamarat**: Throwing pebbles at the pillars in Mina, symbolizing rejection of the devil’s temptations.").font(.body)
                Text("6. **Qurbani**: Sacrificing an animal to commemorate Prophet Ibrahim’s (peace be upon him) willingness to sacrifice his son for Allah’s command.").font(.body)
                Text("7. **Tawaf al-Ifadah**: A final circumambulation of the Kaaba to complete the pilgrimage.").font(.body)
            }
            
            Section(header: Text("SPIRITUAL PURPOSE")) {
                Text("Hajj represents submission to Allah and a renewal of faith. It unites Muslims from diverse backgrounds in worship, showcasing the universal brotherhood of Islam.")
                    .font(.body)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“Whoever performs Hajj (pilgrimage) and does not have sexual relations (with his wife), nor commits sin, nor disputes unjustly (during Hajj), then he returns from Hajj as pure and free from sins as on the day on which his mother gave birth to him.” (Riyad as-Salihin 1274)").font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("CONCLUSION")) {
                Text("Hajj is a profound spiritual journey that strengthens a Muslim’s connection with Allah (Glorified and Exalted be He). By performing Hajj, Muslims fulfill one of the greatest acts of worship, seeking Allah’s mercy, forgiveness, and eternal reward.")
                    .font(.body)
                
                Text("Allah says in the Quran:").font(.body)
                Text("“And proclaim to the people the Hajj [pilgrimage]; they will come to you on foot and on every lean camel; they will come from every distant pass.” (Quran 22:27)").font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("LEARN MORE")) {
                Text("Learn how to perform Hajj here: https://www.islamic-relief.ie/hajj-guide/")
                    .font(.caption)
                
                Text("Malcolm X's letter about Hajj: https://www.icit-digital.org/articles/malcolm-x-s-letter-from-mecca-april-20-1964")
                    .font(.caption)
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Hajj")
    }
}
