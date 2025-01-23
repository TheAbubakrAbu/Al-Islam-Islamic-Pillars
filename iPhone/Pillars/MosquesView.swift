import SwiftUI

struct MosquesView: View {
    @EnvironmentObject var settings: Settings
            
    var body: some View {
        Section(header: Text("THE THREE HOLY MOSQUES")) {
            
            NavigationLink(destination: HaramView()) {
                Text("Masjid Al-Haram (The Holy Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: NabawiView()) {
                Text("Masjid An-Nabawi (The Prophet’s Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: AqsaView()) {
                Text("Masjid Al-Aqsa (The Farthest Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct HaramView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Masjid Al-Haram (ٱلْمَسْجِدُ ٱلْحَرَام), or 'The Sacred Mosque,' is located in **Mecca**, Saudi Arabia. It is the largest mosque in the world and surrounds the **Ka'bah** (ٱلْكَعْبَة), the holiest site in Islam. The Ka'bah is also known as 'The House of Allah' (بَيْتُ ٱللَّه).")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“And [mention] when We made the House (the Ka'bah) a frequent place for people and [a place of] security.” (Quran 2:125)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Masjid Al-Haram is the destination for **Hajj** and **Umrah**, two pivotal acts of worship in Islam. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“One prayer in the Sacred Mosque is better than one hundred thousand prayers elsewhere.” (Sunan Ibn Majah 1406)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("SIGNIFICANCE OF THE KA'BAH")) {
                Text("The **Ka'bah** (ٱلْكَعْبَة), meaning 'The Cube,' is the symbolic House of Allah. It serves as the **Qiblah** (قِبْلَةٌ) (direction of prayer) for Muslims worldwide. Every prayer offered by a Muslim is directed toward the Ka'bah.")
                    .font(.body)
                
                Text("The Ka'bah was built by **Prophet Ibrahim** (Abraham, peace be upon him) and his son **Prophet Isma'il** (Ishmael, peace be upon him) as a place of monotheistic worship. Allah says in the Quran:")
                    .font(.body)
                Text("“And [mention] when Ibrahim was raising the foundations of the House and [with him] Isma'il, [saying], ‘Our Lord, accept [this] from us. Indeed, You are the Hearing, the Knowing.’” (Quran 2:127)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The **Black Stone** (ٱلْحَجَرُ ٱلْأَسْوَد, Hajar Al-Aswad), embedded in one corner of the Ka'bah, is a sacred relic dating back to the time of Prophet Ibrahim (peace be upon him). Touching or kissing it during **Tawaf** is a Sunnah, but not obligatory.")
                    .font(.body)
            }
            
            Section(header: Text("THE WELL OF ZAMZAM")) {
                Text("The **Well of Zamzam** (بِئْرُ زَمْزَم) is located within Masjid Al-Haram. This miraculous water source was provided by Allah for **Hajar** (may Allah be pleased with her) and her son **Isma'il** (peace be upon him) when they were left in the barren desert. The well continues to flow abundantly to this day.")
                    .font(.body)
                
                Text("Drinking Zamzam water is an act of worship and holds immense spiritual blessings.").font(.body)
            }
            
            Section(header: Text("SPIRITUAL REWARDS AND IMPORTANCE")) {
                Text("1. **Multiplied Rewards**: Praying in Masjid Al-Haram is rewarded 100,000 times more than praying elsewhere.")
                    .font(.body)
                Text("2. **Forgiveness of Sins**: Performing Hajj or Umrah with sincerity cleanses one’s sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“Whoever performs Hajj (pilgrimage) and does not have sexual relations (with his wife), nor commits sin, nor disputes unjustly (during Hajj), then he returns from Hajj as pure and free from sins as on the day on which his mother gave birth to him.” (Riyad as-Salihin 1274)").font(.body).foregroundColor(settings.accentColor.color)
                Text("3. **Unity of the Ummah**: Millions of Muslims from diverse cultures and backgrounds gather in Masjid Al-Haram, symbolizing the unity and equality of the Muslim Ummah under the worship of Allah.")
                    .font(.body)
            }
            
            Section(header: Text("QURANIC VERSES ABOUT MECCA")) {
                Text("Allah mentions the sanctity of Mecca and Masjid Al-Haram in several verses:").font(.body)
                Text("“Indeed, the first House [of worship] established for mankind was that at Mecca—blessed and a guidance for the worlds.” (Quran 3:96)").font(.body).foregroundColor(settings.accentColor.color)
                Text("“And [mention] when We made the House (the Ka'bah) a place of return for the people and [a place of] security.” (Quran 2:125)").font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("DRAWING")) {
                VStack {
                    Text("Masjid Al-Haram (Ka’bah) Drawing")
                        .font(.body)
                    
                    Image("Al Haram")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                }
                #if !os(watchOS)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.image = UIImage(named: "Al Haram")
                    }) {
                        Text("Copy Image")
                        Image(systemName: "photo")
                    }
                }
                #endif
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Masjid Al-Haram")
    }
}

struct NabawiView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Masjid An-Nabawi (ٱلْمَسْجِد ٱلنَّبَوِي), or 'The Prophet’s Mosque,' is located in Medina, Saudi Arabia. Originally known as Yathrib, the city was later renamed **Medina Al-Nabi (مَدِينَة ٱلنَّبِي)**, meaning 'The City of the Prophet,' or **Medina Al-Munawwara (ٱلْمَدِينَة ٱلْمُنَوَّرَة)**, 'The Enlightened City,' after the migration (Hijrah) of Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)

                Text("This mosque, built by the Prophet (peace and blessings be upon him) in 622 CE, is the second holiest site in Islam after Masjid Al-Haram. The Prophet (peace and blessings be upon him) made it a center of worship, governance, and community life.")
                    .font(.body)

                Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                Text("“One prayer in my mosque is better than a thousand prayers in any other mosque except Al-Masjid Al-Haram.” (Sahih Bukhari 1190)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("SIGNIFICANCE")) {
                Text("Masjid An-Nabawi is home to the **Rawdah (ٱلرَّوْضَة)**, an area between the Prophet's pulpit and his house, which he described as a garden from the gardens of Paradise. The Prophet (peace and blessings be upon him) said:")
                    .font(.body)
                Text("“Between my house and my pulpit there is a garden of the gardens of Paradise.” (Sahih al-Bukhari 1196)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("The mosque also contains the tomb of the Prophet Muhammad (peace and blessings be upon him) and his companions Abu Bakr As-Siddiq and Umar ibn Al-Khattab (may Allah be pleased with them). Visiting the Prophet’s grave is a recommended act of devotion when in Medina.")
                    .font(.body)
            }

            Section(header: Text("SPIRITUAL BENEFITS")) {
                Text("1. **Multiplied Rewards**: Prayers in Masjid An-Nabawi are rewarded 1,000 times more than prayers in other mosques (except Masjid Al-Haram).")
                    .font(.body)
                Text("2. **Connection to the Prophet**: Standing in a place where the Prophet Muhammad (peace and blessings be upon him) worshipped and led his companions strengthens one’s faith and love for him.")
                    .font(.body)
                Text("3. **Rawdah Visit**: Visiting the Rawdah and praying there is considered highly virtuous.")
                    .font(.body)
            }

            Section(header: Text("QURANIC VERSES ABOUT THE MOSQUE")) {
                Text("Allah emphasizes the sanctity of mosques, particularly those established on righteousness. He says in the Quran:")
                    .font(.body)
                Text("“A mosque founded on righteousness from the first day is more worthy for you to stand in.” (Quran 9:108)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("DRAWING")) {
                VStack {
                    Text("Masjid An-Nabawi Drawing")
                        .font(.body)

                    Image("An Nabawi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                }
                #if !os(watchOS)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.image = UIImage(named: "An Nabawi")
                    }) {
                        Text("Copy Image")
                        Image(systemName: "photo")
                    }
                }
                #endif
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Masjid An-Nabawi")
    }
}

struct AqsaView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Masjid Al-Aqsa (ٱلْمَسْجِد ٱلْأَقْصَىٰ), meaning 'The Farthest Mosque,' is located in Jerusalem, Palestine, within a compound known as **Al-Haram Ash-Sharif (ٱلْحَرَم ٱلشَّرِيف)**, or 'The Noble Sanctuary.' It is the third holiest mosque in Islam after Masjid Al-Haram in Mecca and Masjid An-Nabawi in Medina.")
                    .font(.body)
                
                Text("Masjid Al-Aqsa holds immense historical and spiritual significance in Islam. Allah (Glorified and Exalted be He) mentions it in the Quran:").font(.body)
                Text("“Exalted is He who took His Servant by night from Al-Masjid Al-Haram to Al-Masjid Al-Aqsa, whose surroundings We have blessed, to show him of Our signs. Indeed, He is the Hearing, the Seeing.” (Quran 17:1)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("It was the first Qiblah (direction of prayer) for Muslims before it was changed to the Ka'bah in Mecca, and it was the destination of the Prophet Muhammad’s (peace and blessings be upon him) Night Journey (Isra) before his Ascension (Mi'raj).")
                    .font(.body)
            }

            Section(header: Text("SPIRITUAL SIGNIFICANCE")) {
                Text("1. **First Qiblah**: Muslims initially faced Masjid Al-Aqsa during their prayers, highlighting its significance from the earliest days of Islam.").font(.body)
                Text("2. **Al-Isra wa Al-Mi'raj**: It was the destination of the miraculous Night Journey of the Prophet Muhammad (peace and blessings be upon him), during which he led all prophets in prayer before ascending to the heavens.").font(.body)
                Text("3. **Land of Blessings**: The Quran describes the surroundings of Masjid Al-Aqsa as a blessed land. Allah says:").font(.body)
                Text("“And We delivered him and Lot to the land which We had blessed for all people.” (Quran 21:71)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("HISTORICAL AND RELIGIOUS IMPORTANCE")) {
                Text("Masjid Al-Aqsa is a place of worship for many prophets, including Ibrahim (Abraham), Dawud (David), and Sulaiman (Solomon) (peace be upon them). It is believed that Prophet Muhammad (peace and blessings be upon him) led all the prophets in prayer here during the Night Journey.")
                    .font(.body)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“Do not undertake a journey to visit any mosque but three: Al-Masjid Al-Haram, Al-Masjid An-Nabawi, and Al-Masjid Al-Aqsa.” (Sahih al-Bukhari 1189)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("REWARDS OF PRAYING IN MASJID AL-AQSA")) {
                Text("Prayers offered in Masjid Al-Aqsa carry immense rewards. The Prophet Muhammad (peace and blessings be upon him) said (though this Hadith is weak):").font(.body)
                Text("“[A man's] prayer in Aqsa Mosque is equal to fifty thousand prayers; his prayer in my mosque (Masjid An-Nabawi) is equal to fifty thousand prayers; and his prayer in the Sacred Mosque (Masjid Al-Haram) is equal to one hundred thousand prayers.”” (Sunan Ibn Majah 1413)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("STRUCTURE AND FEATURES")) {
                Text("Masjid Al-Aqsa is part of a larger compound that includes the **Dome of the Rock (قُبَّة ٱلصَّخْرَة)**, the oldest Islamic architectural monument. The entire compound is considered sacred by Muslims, and the name 'Masjid Al-Aqsa' often refers to the entire Noble Sanctuary.")
                    .font(.body)
                
                Text("The mosque’s architecture and location reflect centuries of Islamic devotion and heritage.")
                    .font(.body)
            }

            Section(header: Text("DRAWING")) {
                VStack {
                    Text("Masjid Al-Aqsa Drawing")
                        .font(.body)

                    Image("Al Aqsa")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                }
                #if !os(watchOS)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.image = UIImage(named: "Al Aqsa")
                    }) {
                        Text("Copy Image")
                        Image(systemName: "photo")
                    }
                }
                #endif
            }
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        #endif
        .navigationTitle("Masjid Al-Aqsa")
    }
}
