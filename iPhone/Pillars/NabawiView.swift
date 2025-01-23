//
//  NabawiView.swift
//  Al-Islam
//
//  Created by Abubakr Elmallah on 1/3/25.
//


struct NabawiView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Masjid An-Nabawi (المسجد النبوي), or 'The Prophet’s Mosque,' is located in Medina, Saudi Arabia. Originally known as Yathrib, the city was later renamed **Medina Al-Nabi (مدينة النبي)**, meaning 'The City of the Prophet,' or **Medina Al-Munawwara (المدينة المنورة)**, 'The Enlightened City,' after the migration (Hijrah) of Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)

                Text("This mosque, built by the Prophet (peace and blessings be upon him) in 622 CE, is the second holiest site in Islam after Masjid Al-Haram. The Prophet (peace and blessings be upon him) made it a center of worship, governance, and community life.")
                    .font(.body)

                Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                Text("“One prayer in my mosque is better than a thousand prayers in any other mosque except Al-Masjid Al-Haram.” (Bukhari 1190, Muslim)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("SIGNIFICANCE")) {
                Text("Masjid An-Nabawi is home to the **Rawdah (الروضة)**, an area between the Prophet's pulpit and his house, which he described as a garden from the gardens of Paradise. The Prophet (peace and blessings be upon him) said:")
                    .font(.body)
                Text("“What is between my house and my pulpit is one of the gardens of Paradise.” (Bukhari, Muslim)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("The mosque also contains the tomb of the Prophet Muhammad (peace and blessings be upon him) and his companions Abu Bakr As-Siddiq and Umar ibn Al-Khattab (may Allah be pleased with them). Visiting the Prophet’s grave is a recommended act of devotion when in Medina.")
                    .font(.body)
            }

            Section(header: Text("HISTORICAL FEATURES")) {
                Text("1. **Minbar (Pulpit)**: The Prophet (peace and blessings be upon him) introduced the use of a pulpit in Masjid An-Nabawi to deliver sermons.")
                    .font(.body)
                Text("2. **Qiblah Change**: Originally, the Qiblah (direction of prayer) was toward Jerusalem, but it was later changed to the Ka'bah in Makkah. Allah says in the Quran:")
                    .font(.body)
                Text("“So turn your face toward Al-Masjid Al-Haram. And wherever you [believers] are, turn your faces toward it.” (Quran 2:144)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("3. **Expansion**: Over the centuries, Masjid An-Nabawi has undergone several expansions to accommodate the growing number of worshippers. It now features an expansive courtyard with retractable umbrellas.")
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
                Text("“A mosque founded on righteousness from the first day is more worthy for you to stand in...” (Quran 9:108)")
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
