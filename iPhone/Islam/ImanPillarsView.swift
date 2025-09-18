import SwiftUI

struct ImanPillarsView: View {
    @EnvironmentObject var settings: Settings
        
    var body: some View {
        Section(header: Text("THE 6 PILLARS OF IMAN (FAITH)")) {
            NavigationLink(destination: GodView()) {
                Text("Belief in One God")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: AngelsView()) {
                Text("Belief in His Angels")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: BooksView()) {
                Text("Belief in His Books (Revelations)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: ProphetsView()) {
                Text("Belief in His Prophets")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: DayView()) {
                Text("Belief in the Day of Judgement")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: QadrView()) {
                Text("Belief in His Qadr (Divine Will)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct GodView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Belief in Allah (Glorified and Exalted be He), the One and Only God, is the core of Islamic faith (Iman). He is the Creator and Sustainer of the entire universe. He is eternal, self-sustaining, and has no equal. Allah (Glorified and Exalted be He) says in the Quran:")
                    .font(.body)
                Text("“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, Nor is there to Him any equivalent.’” (Quran 112:1-4)")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                
                Text("This chapter (Surah Al-Ikhlas) summarizes Allah’s Oneness and clarifies that He does not share His divine attributes with any of His creation. Muslims affirm that He is All-Knowing, All-Merciful, and above all limitations.")
                    .font(.body)
            }
            
            Section(header: Text("MEANING OF BELIEF IN ALLAH")) {
                Text("Belief in Allah (الإِيمَانُ بِاللَّه) involves affirming His Oneness (Tawheed) and understanding His divine attributes. It consists of three core aspects:")
                    .font(.body)
                Text("1. **Tawheed al-Rububiyyah (Oneness of Lordship):** Believing that Allah alone is the Creator, Sustainer, and Manager of all that exists.")
                    .font(.body)
                Text("2. **Tawheed al-Uluhiyyah (Oneness of Worship):** Worshiping Allah alone without associating partners with Him.")
                    .font(.body)
                Text("3. **Tawheed al-Asma wa Sifat (Oneness of Names and Attributes):** Affirming Allah’s names and attributes as mentioned in the Quran and Sunnah, without distortion or anthropomorphism.")
                    .font(.body)
            }
            
            Section(header: Text("QURANIC EVIDENCE")) {
                Text("Allah (Glorified and Exalted be He) repeatedly emphasizes His Oneness and supremacy in the Quran. He says:")
                    .font(.body)
                Text("“Allah – there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth” (Quran 2:255, Ayah al-Kursi).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                
                Text("“And your god is one God. There is no deity [worthy of worship] except Him, the Most Compassionate, the Most Merciful” (Quran 2:163).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
            }
            
            Section(header: Text("HADITH ON BELIEF IN ALLAH")) {
                Text("The Prophet Muhammad (peace and blessings be upon him) explained the essence of belief in Allah. He said:")
                    .font(.body)
                Text("“[Iman is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadr) about good and evil” (Sahih Muslim 8a).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
            }
            
            Section(header: Text("IMPORTANCE OF BELIEF IN ALLAH")) {
                Text("Belief in Allah is the foundation of a Muslim’s faith and actions. It shapes a person’s worldview, guiding them to trust Allah, obey His commands, and rely on His mercy and justice.")
                    .font(.body)
                
                Text("This belief inspires Taqwa (God-consciousness), motivating Muslims to live righteously and strive for Allah’s pleasure in every aspect of their lives.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("One God")
    }
}

struct AngelsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Belief in angels (مَلَائِكَة, Malaa'ikah) is a fundamental pillar of Islamic faith (Iman). Angels are unseen beings created by Allah (Glorified and Exalted be He) from light. They are sinless, do not have free will, and continuously obey Allah’s commands. Their roles include delivering revelations, recording deeds, and carrying out Allah’s orders in the universe. Allah, however, does not need angels or anything else, as He is completely self-sufficient (Al-Ghaniyy) and sustains all existence (Al-Qayyum). The creation of angels reflects Allah’s wisdom and His divine plan.")
                    .font(.body)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“The angels were created from light” (Sahih Muslim 2996).").font(.body).foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("CHARACTERISTICS OF ANGELS")) {
                Text("Angels possess unique attributes that set them apart from other creations:")
                    .font(.body)
                
                Text("1. **Created from Light**: Unlike humans and jinn, angels are made of light.")
                    .font(.body)
                Text("2. **Infallible Obedience**: They never disobey Allah and do exactly as commanded. Allah says in the Quran:")
                    .font(.body)
                Text("“They do not disobey Allah in what He commands them but do whatever they are commanded” (Quran 66:6).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                Text("3. **Invisible to Humans**: Although normally unseen, they can appear in human form, as Angel Jibreel (Gabriel) did when he visited the Prophet Muhammad (peace and blessings be upon him).")
                    .font(.body)
                Text("4. **Lack of Free Will**: Angels exist solely to serve Allah and cannot deviate from their roles.")
                    .font(.body)
            }
            
            Section(header: Text("ROLES AND RESPONSIBILITIES")) {
                Text("Angels have distinct duties, demonstrating Allah’s meticulous organization of creation:")
                    .font(.body)
                
                Text("1. **Jibreel (Gabriel)**: The angel of revelation who conveyed Allah’s messages to the prophets, including the Quran to Prophet Muhammad (peace and blessings be upon him). Allah says:")
                    .font(.body)
                Text("“Say, [O Muhammad], ‘Whoever is an enemy to Gabriel – it is he who has brought it [the Quran] down upon your heart by permission of Allah.’” (Quran 2:97)")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                
                Text("2. **Mikail (Michael)**: Responsible for provisions, including rain and sustenance.")
                    .font(.body)
                
                Text("3. **Israfil**: The angel who will blow the trumpet to signal the Day of Judgment.")
                    .font(.body)
                
                Text("4. **Malik**: The guardian of Hellfire. Allah says:")
                    .font(.body)
                Text("“And they will call, ‘O Malik, let your Lord put an end to us!’ He will say, ‘Indeed, you will remain.’” (Quran 43:77)")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                
                Text("5. **Kiraman Katibin**: Angels who record every deed:")
                    .font(.body)
                Text("“Man does not utter any word except that with him is an observer prepared [to record]” (Quran 50:18).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                
                Text("6. **Munkar and Nakir**: Angels who question the deceased in their graves about their faith.")
                    .font(.body)
                
                Text("7. **Ridwan**: The angel who oversees Paradise.")
                    .font(.body)
            }
            
            Section(header: Text("IMPORTANCE OF BELIEF IN ANGELS")) {
                Text("Belief in angels is the second pillar of Iman and is crucial for a complete understanding of Islam. It has profound implications for a Muslim’s faith:")
                    .font(.body)
                
                Text("1. **Strengthens Taqwa**: Awareness of recording angels motivates Muslims to be mindful of their actions.")
                    .font(.body)
                Text("2. **Demonstrates Allah’s Sovereignty**: Angels fulfill Allah’s commands, showcasing His power and control over creation.")
                    .font(.body)
                Text("3. **Connection to Revelation**: Through Angel Jibreel, Allah’s guidance was conveyed to humanity.")
                    .font(.body)
            }
            
            Section(header: Text("HADITH ON ANGELS")) {
                Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“When Allah loves a servant, He calls Jibreel and says: ‘I love so-and-so; therefore, love him.’ So Jibreel loves him. Then Jibreel announces to the inhabitants of the heavens: ‘Allah loves so-and-so; therefore, love him.’ So the inhabitants of the heavens love him. Then he is granted acceptance among the people of the earth” (Sahih al-Bukhari 7485).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("CONCLUSION")) {
                Text("Angels are integral to the Islamic understanding of the unseen world. Their obedience, dedication, and specific roles serve as a reminder of Allah’s omnipotence and meticulous care in organizing creation. Belief in angels strengthens a Muslim’s faith, instilling awe and awareness of the divine presence in all aspects of life.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Angels")
    }
}

struct BooksView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Muslims believe in the divine scriptures revealed by Allah (Glorified and Exalted be He) to various prophets. These scriptures were sent to guide humanity to righteousness and worship of Allah alone. They include the Scrolls of Ibrahim (Abraham, peace be upon him), the Torah given to Musa (Moses, peace be upon him), the Psalms given to Dawud (David, peace be upon him), the Gospel given to Isa (Jesus, peace be upon him), and the Quran given to Muhammad (peace and blessings be upon him).")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Indeed, We sent down the Torah, in which was guidance and light” (Quran 5:44).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Each scripture served as a guide for its respective nation and time, culminating in the Quran, which is the final and universal revelation.")
                    .font(.body)
            }
            
            Section(header: Text("THE QURAN")) {
                Text("The Quran (الْقُرْآن), meaning “The Recitation,“ is the final and complete revelation from Allah, sent to all of humanity through the Prophet Muhammad (peace and blessings be upon him). It is preserved word for word, as Allah has promised:")
                    .font(.body)
                Text("“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Quran confirms and corrects previous scriptures while providing comprehensive guidance for all aspects of life. It remains unchanged since its revelation and is recited, memorized, and revered by Muslims worldwide.")
                    .font(.body)
            }
            
            Section(header: Text("PREVIOUS SCRIPTURES")) {
                Text("1. **The Torah (التَّوْرَاة, Tawrah):** Revealed to Musa (Moses, peace be upon him), it contained laws and guidance for the Children of Israel. Over time, the original text was altered, and its authenticity was compromised.")
                    .font(.body)
                
                Text("2. **The Psalms (الزَّبُور, Zabur):** Revealed to Dawud (David, peace be upon him), it was a collection of hymns and praises dedicated to Allah.")
                    .font(.body)
                
                Text("3. **The Gospel (الإِنْجِيل, Injil):** Revealed to Isa (Jesus, peace be upon him), it confirmed the Torah and brought new guidance. However, the original Gospel has been lost, and what exists today are interpretations and altered accounts.")
                    .font(.body)
                
                Text("4. **The Scrolls (صُحُف, Suhuf):** Revealed to Ibrahim (Abraham, peace be upon him) and Musa (Moses, peace be upon him), these contained foundational teachings and guidance. They are mentioned in the Quran but no longer exist.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says:").font(.body)
                Text("“Indeed, this is in the former scriptures, the scriptures of Abraham and Moses” (Quran 87:18-19).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("IMPORTANCE OF BELIEVING IN THE BOOKS")) {
                Text("Belief in Allah’s books is a fundamental pillar of Iman (faith). The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“[Iman is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadr) about good and evil” (Sahih Muslim 8a).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Each scripture taught monotheism (Tawheed) and righteousness, serving as a guide for the people of its time. The Quran, as the final revelation, is universal and timeless, applicable to all of humanity until the Day of Judgment.")
                    .font(.body)
            }
            
            Section(header: Text("DIFFERENCES BETWEEN SCRIPTURES")) {
                Text("1. **Preservation:** Unlike earlier scriptures, which were altered or lost, the Quran has been perfectly preserved as promised by Allah.")
                    .font(.body)
                
                Text("2. **Universality:** Previous scriptures were meant for specific nations and times, while the Quran is for all of humanity and all time.")
                    .font(.body)
                
                Text("3. **Completeness:** The Quran encompasses all necessary guidance, confirming and completing previous revelations.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Books")
    }
}

struct ProphetsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("""
                Muslims believe in all the prophets sent by Allah (Glorified and Exalted be He). Prophets were chosen by Allah to guide their communities to monotheism and righteous living. The Quran mentions 25 prophets by name, including:
                
                - Adam
                - Idris (Enoch)
                - Nuh (Noah)
                - Hud (Heber)
                - Saleh
                - Lut (Lot)
                - Ibrahim (Abraham)
                - Ismail (Ishmael)
                - Ishaq (Isaac)
                - Yaqub (Jacob)
                - Yusuf (Joseph)
                - Shu’aib (Jethro)
                - Ayyub (Job)
                - Dhulkifl (Ezekiel)
                - Musa (Moses)
                - Harun (Aaron)
                - Dawud (David)
                - Sulayman (Solomon)
                - Ilyas (Elias)
                - Alyasa (Elisha)
                - Yunus (Jonah)
                - Zakariya (Zachariah)
                - Yahya (John the Baptist)
                - Isa (Jesus)
                - Muhammad
                """)
                .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“And We gave to Abraham, Isaac and Jacob—all [of them] We guided. And Noah We guided before; and among his descendants, David and Solomon and Job and Joseph and Moses and Aaron. Thus do We reward the doers of good. And Zechariah and John and Jesus and Elias—and all were of the righteous” (Quran 6:84-85).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Muslims believe that each prophet conveyed Allah’s guidance and served as role models for their people. While all prophets were sent to specific nations and times, Prophet Muhammad was sent as the final messenger for all of humanity. Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and the seal of the prophets” (Quran 33:40).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("PROPHETS AND MESSENGERS")) {
                Text("There is a distinction between a prophet (نَبِيّ, Nabi) and a messenger (رَسُول, Rasul):").font(.body)
                
                Text("1. **Prophet (Nabi):** A prophet is chosen to uphold and reinforce the laws of a previous messenger.").font(.body)
                Text("Example: Harun (Aaron) was a prophet who supported Musa (Moses) in spreading the Torah’s teachings.").font(.body)
                
                Text("2. **Messenger (Rasul):** A messenger is sent with a new scripture or divine law for their people.").font(.body)
                Text("Example: Muhammad was a messenger who brought the Quran, the final revelation.").font(.body)
                
                Text("All messengers are prophets, but not all prophets are messengers.").font(.body)
            }
            
            Section(header: Text("IMPORTANCE OF BELIEF IN PROPHETS")) {
                Text("Belief in the prophets is a pillar of Iman (Faith). The Prophet Muhammad said:").font(.body)
                Text("“[Iman is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadr) about good and evil” (Sahih Muslim 8a).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Muslims respect and honor all prophets equally, as they all conveyed the same message: to worship Allah alone. Allah (Glorified and Exalted be He) says:").font(.body)
                Text("“The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah, His angels, His books, His messengers” (Quran 2:285).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("LEGACY OF PROPHETS")) {
                Text("Prophets were sent to guide humanity and exemplify righteousness. Their lives demonstrate the highest moral and spiritual qualities. The Quran recounts their stories as lessons and reminders for believers.")
                    .font(.body)
                
                Text("The final prophet, Muhammad, delivered the Quran and established a comprehensive way of life, leaving an eternal legacy of guidance for all humanity.")
                    .font(.body)
            }
            
            Section(header: Text("RESOURCE")) {
                Text("For a detailed family tree of the prophets: https://madinahmedia.com/family-tree-of-prophets-in-islam/")
                    .font(.caption)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Prophets")
    }
}

struct DayView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Belief in the Day of Judgment (يَوْمُ الْقِيَامَة, Yawm al-Qiyamah) is a cornerstone of Islam and the fifth pillar of Iman (Faith). It is the day when Allah (Glorified and Exalted be He) will resurrect all of creation to hold them accountable for their deeds. This belief is essential for understanding the purpose of life and the consequences of human actions.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“So whoever does an atom’s weight of good will see it, And whoever does an atom’s weight of evil will see it” (Quran 99:7-8).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("EVENTS OF THE DAY")) {
                Text("The Day of Judgment will unfold in stages, including:").font(.body)
                
                Text("1. **The Blowing of the Trumpet**: The angel Israfil will blow the trumpet twice—first to end all life and then to resurrect everyone. Allah says:").font(.body)
                Text("“And the Horn will be blown, and whoever is in the heavens and whoever is on the earth will fall dead except whom Allah wills. Then it will be blown again, and at once they will be standing, looking on” (Quran 39:68).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("2. **Resurrection**: All people will rise from their graves to face their Lord. Allah says:").font(.body)
                Text("“And the Horn will be blown, and at once from the graves to their Lord they will hasten” (Quran 36:51).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("3. **The Reckoning (Hisab)**: Every individual’s deeds will be reviewed, and their record of actions will be presented to them. Those who receive their record in their right hand will rejoice, while those who receive it in their left will despair.").font(.body)
                
                Text("4. **The Scale (Mizan)**: Deeds will be weighed on a divine scale. Good deeds that outweigh bad deeds will lead to Paradise. Allah says:").font(.body)
                Text("“And the weighing [of deeds] that Day will be the truth. So those whose scales are heavy—it is they who will be successful” (Quran 7:8).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("5. **The Bridge (As-Sirat)**: A bridge over Hellfire that all people must cross. The righteous will cross safely, while others will fall.").font(.body)
            }
            
            Section(header: Text("IMPORTANCE OF BELIEF IN THE DAY OF JUDGMENT")) {
                Text("1. **Accountability**: Believing in the Day of Judgment instills a sense of accountability. Every action, no matter how small, will be rewarded or punished accordingly.").font(.body)
                
                Text("2. **Moral Uprightness**: Encourages Muslims to lead righteous lives, avoid sin, and fulfill their obligations to Allah and others.").font(.body)
                
                Text("3. **Justice and Fairness**: The Day of Judgment is the ultimate manifestation of Allah’s justice. Every wrong will be rectified, and no one will be wronged. Allah says:").font(.body)
                Text("“Indeed, Allah does not wrong the people at all, but it is the people who are wronging themselves” (Quran 10:44).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("4. **Hope and Fear**: Belief in the Day of Judgment inspires hope in Allah’s mercy and fear of His punishment, creating a balance in a Muslim’s spiritual life.").font(.body)
            }
            
            Section(header: Text("QURANIC EMPHASIS")) {
                Text("Allah (Glorified and Exalted be He) repeatedly emphasizes the Day of Judgment in the Quran as a reminder of the ultimate return to Him. He says:")
                    .font(.body)
                Text("“The Day they come forth, nothing concerning them will be concealed from Allah. To whom belongs [all] sovereignty this Day? To Allah, the One, the Prevailing” (Quran 40:16).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("In Surah Al-Qariah, Allah vividly describes the weighing of deeds:").font(.body)
                Text("“Then as for one whose scales are heavy [with good deeds], he will be in a pleasant life. But as for one whose scales are light, his refuge will be an abyss” (Quran 101:6-9).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) said about the Day of Judgment:").font(.body)
                Text("“The rights of justice will surely be restored to their people on the Day of Resurrection, even the hornless sheep will lay claim to the horned sheep” (Sahih Muslim 2582).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("This highlights Allah’s perfect justice, where no soul will be wronged, not even among animals.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Day of Judgment")
    }
}

struct QadrView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("OVERVIEW")) {
                Text("Belief in Qadr (قَدَر), or divine decree, is the sixth pillar of Iman (faith). It is the belief that everything occurs by the will, knowledge, and command of Allah (Glorified and Exalted be He). This includes both the good and the bad, as Allah’s wisdom is perfect, and His plans are flawless.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being—indeed that, for Allah, is easy” (Quran 57:22).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("This belief fosters patience during trials, gratitude in blessings, and complete trust in Allah’s wisdom. It also reminds Muslims that Allah’s knowledge encompasses all things and that nothing happens outside of His will.")
                    .font(.body)
            }
            
            Section(header: Text("COMPONENTS OF QADR")) {
                Text("Scholars identify four essential components of Qadr:").font(.body)
                
                Text("1. **Allah’s Knowledge (علم, `Ilm)**: Allah’s knowledge is infinite and perfect. He knows everything that has happened, is happening, and will happen. Allah says:").font(.body)
                Text("“And with Him are the keys of the unseen; none knows them except Him. And He knows what is on the land and in the sea. Not a leaf falls but that He knows it” (Quran 6:59).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("2. **Allah’s Writing (كتابة, Kitabah)**: All things are written in **Al-Lawh Al-Mahfuz** (The Preserved Tablet), where every event, action, and outcome is recorded. Allah says:").font(.body)
                Text("“Do you not know that Allah knows what is in the heaven and earth? Indeed, it is all in a record. Indeed that, for Allah, is easy” (Quran 22:70).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("3. **Allah’s Will (مشيئة, Mashi’ah)**: Whatever Allah wills happens, and whatever He does not will does not happen. Allah says:").font(.body)
                Text("“And they plan, and Allah plans. And Allah is the best of planners” (Quran 3:54).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("4. **Allah’s Creation (خلق, Khalq)**: Allah is the Creator of all things, including actions, circumstances, and outcomes. Allah says:").font(.body)
                Text("“Allah is the Creator of all things, and He is, over all things, Disposer of affairs” (Quran 39:62).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("BALANCE BETWEEN FREE WILL AND QADR")) {
                Text("Islam teaches a balance between divine decree and human free will. While Allah knows and decrees all things, humans are given the freedom to make choices and are held accountable for them. This accountability ensures justice and moral responsibility.")
                    .font(.body)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                Text("“Strive for that which will benefit you, seek help from Allah, and do not give up. If something befalls you, do not say, ‘If only I had done such and such,’ but say, ‘Allah decreed it, and what He willed has happened.’ For saying ‘if’ opens the door to Shaytaan’s (Satan’s) work” (Sunan Ibn Majah 79).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("PATIENT AND GRATEFUL")) {
                Text("Belief in Qadr teaches Muslims to face life’s trials and blessings with patience and gratitude. Allah says in the Quran:").font(.body)
                Text("“And We will surely test you with something of fear and hunger and a loss of wealth and lives and fruits, but give good tidings to the patient—those who, when disaster strikes them, say, ‘Indeed we belong to Allah, and indeed to Him we will return.’” (Quran 2:155-156)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Through this belief, Muslims trust that every hardship is a test and every blessing is a favor from Allah, leading them closer to Him.")
                    .font(.body)
            }
            
            Section(header: Text("CONCLUSION")) {
                Text("Belief in Qadr is a profound reminder of Allah’s ultimate authority, wisdom, and justice. It brings peace to the hearts of believers, knowing that everything happens for a reason, and Allah’s plans are always for the best. It encourages trust, patience, and gratitude in every aspect of life.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Qadr")
    }
}
