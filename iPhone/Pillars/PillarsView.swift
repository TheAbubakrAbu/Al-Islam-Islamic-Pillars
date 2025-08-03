import SwiftUI

struct PillarsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var namesData: NamesViewModel
    
    var body: some View {
        NavigationView {
            List {
                ToolsView()
                
                Section(header: Text("THE BASICS")) {
                    NavigationLink(destination: GodPillarView()) {
                        Text("Does God Exist?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink(destination: IslamPillarView()) {
                        Text("What is Islam?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink(destination: AllahPillarView()) {
                        Text("Who is Allah?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink(destination: QuranPillarView()) {
                        Text("What is the Quran?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink(destination: ProphetPillarView()) {
                        Text("Who is Prophet Muhammad?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink(destination: SunnahPillarView()) {
                        Text("What is the Sunnah?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink(destination: HadithPillarView()) {
                        Text("What are Hadiths?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
                
                IslamicPillarsView()
                
                ImanPillarsView()
                                    
                MosquesView()
                
                PillarsOtherView()
                
                ProphetQuote()
                
                AlIslamAppsSection()
            }
            .applyConditionalListStyle(defaultView: true)
            .navigationTitle("Al-Islam")
            
            TasbihView()
        }
    }
}

struct ProphetQuote: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        Section(header: Text("PROPHET MUHAMMAD ﷺ QUOTE")) {
            VStack(alignment: .center) {
                ZStack {
                    Circle()
                        .strokeBorder(settings.accentColor.color, lineWidth: 1)
                        .frame(width: 60, height: 60)

                    Text("ﷺ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(settings.accentColor.color)
                        .padding()
                }
                .padding(4)
                
                Text("“All mankind is from Adam and Eve, an Arab has no superiority over a non-Arab nor a non-Arab has any superiority over an Arab; also a white has no superiority over a black, nor a black has any superiority over a white except by piety and good action.“")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Farewell Sermon\nJummuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 1)
            }
        }
        #if !os(watchOS)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = "All mankind is from Adam and Eve, an Arab has no superiority over a non-Arab nor a non-Arab has any superiority over an Arab; also a white has no superiority over a black, nor a black has any superiority over a white except by piety and good action."
            }) {
                Text("Copy Text")
                Image(systemName: "doc.on.doc")
            }
        }
        #endif
    }
}

struct AlIslamAppsSection: View {
    @EnvironmentObject var settings: Settings
    
    #if !os(watchOS)
    let spacing: CGFloat = 20
    #else
    let spacing: CGFloat = 10
    #endif

    var body: some View {
        Section(header: Text("AL-ISLAMIC APPS")) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow.opacity(0.25), .green.opacity(0.25)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .primary.opacity(0.25), radius: 5, x: 0, y: 1)
                    .padding(.horizontal, -12)
                
                HStack(spacing: spacing) {
                    Card(
                        title: "Al-Adhan",
                        url: URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493")!
                    )
                    
                    Card(
                        title: "Al-Islam",
                        url: URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655")!
                    )
                    
                    Card(
                        title: "Al-Quran",
                        url: URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373")!
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .scaledToFit()
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
        }
    }
}

private struct Card: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.openURL) private var openURL
    
    let title: String
    let url: URL

    var body: some View {
        Button(action: {
            settings.hapticFeedback()
            
            openURL(url)
        }) {
            VStack {
                Image(title)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .shadow(radius: 4)

                #if !os(watchOS)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                #endif
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GodPillarView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("DOES GOD EXIST?")) {
                Text("The question of God's existence is the most important inquiry a person can make. It is the foundation of all meaning, morality, purpose, and accountability. If God exists, then life has objective direction and responsibility. If He does not, then everything—good and evil, justice and injustice, purpose and identity—becomes subjective and ultimately meaningless. Therefore, it is essential to examine this question through reason, evidence, and rational thought.")
                    .font(.body)
            }

            Section(header: Text("THE DOMINO EFFECT FRAMEWORK")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The most honest way to approach truth is through a step-by-step method—what can be called the Domino Effect. Each answer leads logically to the next:")
                        .font(.body)
                    Group {
                        Text("• Does God exist?")
                        Text("• If yes, is He still involved with creation (theism), or did He create and withdraw (deism)?")
                        Text("• If He is involved, did He send revelation to guide humanity?")
                        Text("• If revelation exists, then one religion must be objectively true.")
                        Text("• If there is one true religion, is it monotheistic or polytheistic?")
                        Text("• If monotheistic, is it exclusive to a specific ethnicity, or universal for all people?")
                        Text("• If universal and monotheistic, only Islam and Christianity remain as candidates.")
                    }
                    .font(.body)
                }
            }

            Section(header: Text("CHRISTIANITY VS. ISLAM")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("While Christianity asserts universality, it contains internal contradictions and historical issues:")
                        .font(.body)
                    Group {
                        Text("• The Trinity violates pure monotheism by making God three persons in one essence—an idea that even many Christian scholars admit is a mystery, not a rational doctrine.")
                        Text("• The Bible is not preserved in its original language or form. It is a compilation of human writings over centuries with known alterations.")
                        Text("• Christianity does not offer a consistent position on salvation, works, and belief.")
                    }
                    Text("Islam, on the other hand:")
                        .font(.body)
                    Group {
                        Text("• Affirms absolute monotheism (tawḥīd), with no partners, no intermediaries, and no confusion.")
                        Text("• Preserves the Qur’an exactly as it was revealed—verbatim, letter for letter, sound for sound, in its original Arabic.")
                        Text("• Welcomes all of humanity, regardless of ethnicity, race, gender, or background.")
                        Text("• Is the only universal, unambiguous, monotheistic religion with an intellectually sound and preserved foundation.")
                    }
                }
            }

            Section(header: Text("THE COSMOLOGICAL ARGUMENT")) {
                Text("Every effect has a cause. The universe began to exist, so it must have had a cause. The Big Bang Theory itself confirms this beginning, but where did the energy come from? What caused it to expand? Who set the laws of physics in motion? The Qur’an said long ago:")
                    .font(.body)
                Text("“Have those who disbelieved not considered that the heavens and the earth were a joined entity, and We split them apart…?” (Qur’an 21:30)")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                Text("“And the heaven We constructed with strength, and indeed, We are its expander” (Qur’an 51:47).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
                Text("The existence of anything—matter, time, space—requires an uncaused, necessary being beyond the system: Allah (Glorified and Exalted be He).")
                    .font(.body)
            }

            Section(header: Text("ABIOGENESIS – LIFE FROM NON-LIFE?")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Modern science teaches that the first life (a prokaryotic cell) emerged from non-living chemicals. But this raises serious questions:")
                        .font(.body)
                    Group {
                        Text("• How did non-living matter suddenly become alive?")
                        Text("• How did a cell, containing instructions (DNA), copy itself?")
                        Text("• A single strand of DNA contains more information than any supercomputer—where did this information come from?")
                    }
                    Text("Scientists admit: “We don’t know.” But nothing in our experience tells us that complex, coded systems arise without a mind. The most rational explanation is that life was created intentionally, not randomly.")
                        .font(.body)
                }
            }

            Section(header: Text("HUMAN INTELLIGENCE – BEYOND EVOLUTION")) {
                Text("Human beings are orders of magnitude more intelligent than any other creature. Humans build cities, fly planes, write poetry, and explore the universe. They possess self-awareness, language, morality, free will, and the capacity for worship. If evolution alone explains the human brain, why don't other species come close? Why the quantum leap in ability? Human exceptionalism points to a Creator who endowed humanity with reason, or ʿaql—a faculty Allah (Glorified and Exalted be He) gave only to humans.")
                    .font(.body)
                Text("“Indeed, We have certainly created man in the best of stature” (Qur’an 95:4).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
            }

            Section(header: Text("THE FINE-TUNING OF THE UNIVERSE")) {
                Text("Gravity, electromagnetism, the strong and weak nuclear forces—all must be precisely balanced. If any were off by even a tiny fraction, life could not exist. This is not randomness. It is deliberate fine-tuning. Even atheists like Stephen Hawking acknowledge this astonishing precision. The question is: Who fine-tuned it?")
                    .font(.body)
            }

            Section(header: Text("THE MORAL ARGUMENT")) {
                Text("Every human being knows certain things are wrong—murder, rape, lying, oppression. But if humans are just chemical accidents, who decides what's right or wrong? Evolution can explain instincts, not moral obligations. The existence of objective morality points to a Moral Lawgiver—someone who defines justice, goodness, and evil: Allah (Glorified and Exalted be He).")
                    .font(.body)
            }

            Section(header: Text("ARGUMENT FROM BEAUTY, ORDER, AND DESIGN")) {
                Text("Look at the trees, stars, animals, oceans. Look at the symmetry of flowers and the precision of ecosystems. Human creation—skyscrapers, smartphones, aircraft—demonstrates purposeful design. Just as buildings imply builders, the cosmos implies a Creator.")
                    .font(.body)
                Text("“Or were they created by nothing, or were they the creators of themselves? Or did they create the heavens and the earth? Rather, they are not certain” (Qur’an 52:35–36).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
            }

            Section(header: Text("WHAT MAKES A RELIGION TRUE?")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("When choosing a religion, one must not follow emotions, culture, or dreams. The correct belief system should be based on logic, objective evidence, and sound reasoning.")
                        .font(.body)
                    Group {
                        Text("• Subjective experiences—such as dreams, visions, or personal feelings—may be meaningful, but they are not reliable indicators of truth.")
                        Text("• Anyone from any religion can claim such experiences.")
                        Text("• Truth must be verifiable, logical, and universally applicable.")
                    }
                    Text("Islam aligns with these criteria.")
                        .font(.body)
                }
                Text("“Have you seen the one who takes his own desires as his god…?” (Qur’an 45:23)")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
            }

            Section(header: Text("FINAL REFLECTION")) {
                Text("Belief in God is not blind faith—it is the most rational and coherent explanation for existence, morality, consciousness, and design. Every human is born on the fitrah—the natural disposition to believe in one Creator. However, ego, society, and culture often obscure this truth. Islam calls humanity back to this original clarity.")
                    .font(.body)
                Text("“And do not follow what you have no knowledge of. Indeed, the hearing, the sight, and the heart—about all those one will be questioned” (Qur’an 17:36).")
                    .foregroundColor(settings.accentColor.color)
                    .font(.body)
            }

            Section(header: Text("ADVICE TO THE SINCERE SEEKER")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seek truth with sincerity. Study deeply. Question critically. Do not follow inherited beliefs without examination.")
                        .font(.body)
                    Group {
                        Text("• The Qur’an criticizes blind following of ancestors without knowledge (Qur’an 43:23).")
                        Text("• Instead, use the God-given faculty of reason (ʿaql) and return to the fitrah.")
                        Text("• Islam stands as the only worldview that fully harmonizes with reason, morality, and objective reality.")
                    }
                }
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Does God Exist?")
    }
}

struct IslamPillarView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("INTRODUCTION")) {
                Text("Islam, derived from the Arabic word “إِسْلَام“ (Islam), meaning “submission” and “peace,” is a complete way of life rooted in the worship of Allah (Glorified and Exalted be He). Muslims believe that the Quran, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years through the angel Jibreel (Gabriel), is the divine word of Allah. It serves as a comprehensive guide encompassing theology, morality, and legal principles.")
                    .font(.body)
                
                Text("The essence of Islam is the belief in Tawheed (absolute monotheism): “There is no deity worthy of worship except Allah.” Allah says in the Quran:").font(.body)
                Text("“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Prophet Muhammad (peace and blessings be upon him) is the final and last messenger of Allah, sent as a mercy to all of creation. Allah says in the Quran:").font(.body)
                Text("“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Islam has been the way of life for humanity since the creation of Adam (peace be upon him), who was the first prophet and the first Muslim. Every nation that correctly followed the teachings of its prophet was considered Muslim in submission to Allah (Glorified and Exalted be He). For example, the Israelites who followed Moses (peace be upon him) and the disciples who followed Jesus (peace be upon him) were considered Muslims of their time.")
                        .font(.body)
            }

            Section(header: Text("THE FIVE PILLARS")) {
                Text("Islam is built on five pillars, which are the fundamental acts of worship for every Muslim. The Prophet Muhammad (peace and blessings be upon him) said:")
                    .font(.body)
                Text("“Verily, Al-Islam is founded on five (pillars): testifying the fact that there is no god but Allah (Shahaadah), establishment of prayer (Salah), payment of charity (Zakah), fast of Ramadan, and Pilgrimage to the House (Hajj)” (Sahih Muslim 16d).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Five Pillars are:").font(.body)
                Text("1. **Shahaadah**: Declaring faith by saying, “There is no god but Allah, and Muhammad is His Messenger.“ This testimony is the foundation of a Muslim's faith.")
                Text("2. **Salah**: Praying five times a day at prescribed times, a direct link between the believer and Allah.")
                Text("3. **Zakah**: Giving a portion of wealth to the needy (typically 2.5% of savings), purifying wealth and fostering social justice.")
                Text("4. **Sawm**: Fasting during the month of Ramadan, abstaining from food, drink, and sinful behavior from dawn to sunset as a means of spiritual reflection and self-discipline.")
                Text("5. **Hajj**: Pilgrimage to Mecca, a once-in-a-lifetime obligation for those who are physically and financially able, symbolizing unity and submission to Allah.")
            }

            Section(header: Text("THE SIX PILLARS OF IMAN")) {
                Text("The Six Pillars of Iman (Faith) are the core beliefs every Muslim must hold. These are based on the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him). Allah says in the Quran:")
                    .font(.body)
                Text("“The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah, His angels, His books, His messengers, and the Last Day. And they say, ‘We hear and we obey. [We seek] Your forgiveness, our Lord, and to You is the [final] destination.’” (Quran 2:285)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) explained the pillars of Iman when he said:").font(.body)
                Text("“[It is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadr) about good and evil” (Sahih Muslim 8a).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Six Pillars of Iman are:").font(.body)
                Text("1. **Belief in Allah**: The oneness of Allah, who has no partners or equals.")
                Text("2. **Belief in the Angels**: Created beings who serve Allah and carry out His commands, such as Jibreel (Gabriel).")
                Text("3. **Belief in the Books**: The divine scriptures revealed by Allah, including the Torah, Gospel, Psalms, and the Quran, which is the final and unaltered revelation.")
                Text("4. **Belief in the Messengers**: Prophets sent to guide humanity, ending with Prophet Muhammad (peace and blessings be upon him).")
                Text("5. **Belief in the Last Day**: The Day of Judgment when all will be held accountable for their deeds.")
                Text("6. **Belief in Divine Decree (Qadr)**: That everything, good and bad, happens by Allah’s will and wisdom.")
            }

            Section(header: Text("PROPHETHOOD")) {
                Text("Muslims believe that Allah sent prophets to every nation to guide them to worship Him alone. These prophets include Adam, Noah, Abraham, Moses, David, Solomon, Jesus, and many others (peace be upon them all). Allah says in the Quran:")
                    .font(.body)
                Text("“We make no distinction between any of His messengers” (Quran 2:285).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("However, all previous prophets were sent for their specific people and times. Prophet Muhammad (peace and blessings be upon him) is unique as the final and universal messenger, sent for all of humanity until the end of time. Allah says in the Quran:")
                    .font(.body)
                Text("“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and the Seal of the Prophets. And ever is Allah, of all things, Knowing” (Quran 33:40).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Regarding Prophet Abraham (peace be upon him), Allah clarifies in the Quran:")
                    .font(.body)
                Text("“Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]. And he was not of the polytheists” (Quran 3:67).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("PREVIOUS SCRIPTURES")) {
                Text("Islam acknowledges earlier divine scriptures such as the Torah given to Moses (peace be upon him) and the Gospel given to Jesus (peace be upon him). However, Muslims believe that these scriptures were altered over time, and the current versions of the Bible and Torah are not the original revelations. Allah says in the Quran:")
                    .font(.body)
                Text("“So woe to those who write the Book with their own hands, then say, ‘This is from Allah,’ to exchange it for a small price. Woe to them for what their hands have written and woe to them for what they earn” (Quran 2:79).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Quran is the final, complete, and preserved revelation sent to all of mankind for all time. Allah says in the Quran:")
                    .font(.body)
                Text("“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Prophet Muhammad (peace and blessings be upon him) said about the Quran:").font(.body)
                Text("“The best among you (Muslims) are those who learn the Quran and teach it” (Sahih al-Bukhari 5027).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("ISLAMIC VALUES")) {
                Text("Islam emphasizes high moral conduct, urging Muslims to embody honesty, justice, compassion, and humility. It teaches that good character and kindness towards others are integral to faith. The concept of the Ummah (global Muslim community) fosters unity among believers regardless of ethnicity or background.")
                    .font(.body)
                
                Text("Allah commands Muslims to act justly and to do good:").font(.body)
                Text("“Indeed, Allah commands you to uphold justice and good conduct and to give to relatives and forbids immorality, bad conduct, and oppression. He admonishes you that perhaps you will be reminded” (Quran 16:90).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("True righteousness is not limited to mere belief or rituals but includes good deeds and moral conduct. Allah says in the Quran:").font(.body)
                Text("“Righteousness is not that you turn your faces toward the east or the west, but [true] righteousness is in one who believes in Allah, the Last Day, the angels, the Book, and the prophets and gives wealth, in spite of love for it, to relatives, orphans, the needy, the traveler, those who ask [for help], and for freeing slaves; [and who] establishes prayer and gives zakah; [those who] fulfill their promise when they promise; and [those who] are patient in poverty and hardship and during battle. Those are the ones who have been true, and it is they who are the righteous” (Quran 2:177).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Prophet Muhammad (peace and blessings be upon him) highlighted the importance of good manners and character. He said:").font(.body)
                Text("“The best among you are those who have the best manners and character” (Sahih al-Bukhari 6029)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("He also said:").font(.body)
                Text("“The most beloved people to Allah are those who are most beneficial to people. The most beloved deed to Allah is to make a Muslim happy, or remove one of his troubles, or forgive his debt, or feed his hunger” (al-Mu'jam al Awsat lil-Tabarani 6026).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("These teachings show that Islam is not only about fulfilling religious obligations but also about treating others with respect, kindness, and fairness. Upholding good character is considered a sign of true faith and devotion to Allah (Glorified and Exalted be He).")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("What is Islam?")
    }
}

struct AllahPillarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("INTRODUCTION")) {
                Text("“Allah” (اللَّهُ) comes from the Arabic word “ٱلْإِلَٰه“ (Al-Ilah), meaning “The God.“ In Islam, Allah (Glorified and Exalted be He) is the unique Creator, Sustainer, and Maintainer of all that exists. He is without partner, associate, or equal and is absolutely One.")
                    .font(.body)
                
                Text("The Quran mentions Allah's 99 Names (attributes), such as the Most Gracious, the Most Merciful, the All-Knowing, and the King. These Names describe His perfect qualities and emphasize His absolute transcendence. Allah is beyond human comprehension and far above any need, limitation, or resemblance to His creation.")
                    .font(.body)
            }

            Section(header: Text("ALLAH IN PRE-ISLAMIC TIMES")) {
                Text("Before Islam, the Arabs acknowledged a supreme God named Allah but associated partners with Him by worshipping idols and other deities. When Prophet Muhammad (peace and blessings be upon him) brought Islam, he reaffirmed the Oneness of Allah, rejecting all forms of idolatry and polytheism. Allah says in the Quran:")
                    .font(.body)
                Text("“And they were not commanded except to worship Allah, [being] sincere to Him in religion, inclining to truth, and to establish prayer and to give zakah. And that is the correct religion” (Quran 98:5).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("QURANIC REFERENCES")) {
                Text("Allah describes Himself in the Quran as the One and Only God, the source of all mercy and compassion. Allah says:")
                    .font(.body)
                Text("“And your God is One God. There is no deity [worthy of worship] except Him, the Most Compassionate, the Most Merciful” (Quran 2:163).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("He also says: “There is nothing like unto Him, and He is the All-Hearing, the All-Seeing” (Quran 42:11).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("ESSENCE OF WORSHIP")) {
                Text("Muslims believe that the primary purpose of life is to worship Allah (Glorified and Exalted be He). This worship is not limited to rituals but encompasses every sincere action done to seek Allah's pleasure. Allah says in the Quran:")
                    .font(.body)
                Text("“And I did not create the jinn and mankind except to worship Me” (Quran 51:56).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Worshiping Allah includes prayer, supplication, charity, good conduct, and obedience to His commands as revealed in the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him).").font(.body)
                
                Text("This life is also a test from Allah to determine who among His servants will strive to fulfill their purpose with sincerity and patience. Allah says in the Quran:")
                    .font(.body)
                Text("“Indeed, We have made that which is on the earth adornment for it that We may test them [as to] which of them is best in deed” (Quran 18:7).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Allah further reminds us:").font(.body)
                Text("“And We test you with evil and with good as trial; and to Us you will be returned” (Quran 21:35).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Through these tests, believers have the opportunity to demonstrate their devotion, patience, and trust in Allah. Success lies in worshiping Him sincerely and following the straight path outlined in the Quran and Sunnah.")
                    .font(.body)
            }

            Section(header: Text("SURAH AL-IKHLAS")) {
                Text("""
                “Say: He is Allah, the One and Only;
                Allah, the Eternal, Absolute;
                He begets not, nor was He begotten;
                And there is none like unto Him.”
                (Quran 112:1-4)
                """)
                .font(.body)
                .foregroundColor(settings.accentColor.color)
                
                Text("This short yet powerful chapter (Surah Al-Ikhlas) perfectly encapsulates the core of Islamic monotheism, affirming that Allah is eternal, without offspring or equal, and incomparable to any of His creation.")
                    .font(.body)
            }

            Section(header: Text("AYAH AL-KURSI")) {
                Text("""
                “Allah! There is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation does not tire Him. And He is the Most High, the Most Great.”
                (Quran 2:255)
                """)
                .font(.body)
                .foregroundColor(settings.accentColor.color)

                Text("Ayah Al-Kursi, also known as the Throne Verse, emphasizes Allah's supreme power, unmatched knowledge, and sovereignty over the universe. It is one of the most significant verses in the Quran and is often recited for protection and blessings.")
                    .font(.body)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Who is Allah?")
    }
}

struct QuranPillarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("DEFINITION")) {
                Text("The Quran, derived from the Arabic word “قُرْءان“ (Quran), meaning “recitation“ or “reading,“ is the holy book of Islam. Muslims believe that it is the literal word of Allah (Glorified and Exalted be He), revealed to Prophet Muhammad (peace and blessings be upon him) through the angel Jibreel (Gabriel) over 23 years. It is the ultimate source of guidance for humanity.")
                    .font(.body)
                
                Text("Unlike previous scriptures sent to specific nations and later altered, the Quran is a universal message for all people and all times. Allah says in the Quran:")
                    .font(.body)
                Text("“And We have not sent you [O Muhammad] except as a mercy to the worlds” (Quran 21:107).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("ELOQUENCE AND MIRACULOUS NATURE")) {
                Text("One of the most remarkable aspects of the Quran is its unmatched eloquence and literary beauty. It stands as the pinnacle of the Arabic language, setting the standard for vocabulary, syntax, and grammar. Formal Arabic today is even referred to as “Quranic Arabic“ due to the Quran's immense influence.")
                    .font(.body)
                
                Text("The Quran challenged the greatest poets and linguists of its time, many of whom were astounded by its profound imagery, rhythmic flow, and clarity. Allah says in the Quran:")
                    .font(.body)
                Text("“Say, 'If mankind and the jinn gathered in order to produce the like of this Quran, they could not produce the like of it, even if they were to each assist the other'” (Quran 17:88).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Despite its eloquence and poetic nature, the Quran remains simple and easy to understand, allowing millions of Muslims to memorize it entirely. This combination of literary perfection and accessibility is one of the Quran's miracles.")
                    .font(.body)
            }

            Section(header: Text("PRESERVATION")) {
                Text("The Quran is unique among religious scriptures in that it has been perfectly preserved word for word and letter for letter since its revelation. This preservation is due to its widespread memorization by Muslims and its meticulous recording in written form.")
                    .font(.body)
                
                Text("Allah promises in the Quran:").font(.body)
                Text("“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Millions of Muslims, from children to scholars, continue to memorize the Quran in its entirety, ensuring its unaltered transmission across generations. The Quran's preservation is a testament to its divine origin.")
                    .font(.body)
            }

            Section(header: Text("GUIDANCE AND MESSAGE")) {
                Text("The Quran is not merely a book of laws or stories; it provides a comprehensive guide for personal, spiritual, and social life. Allah says in the Quran:")
                    .font(.body)
                Text("“This is the Book about which there is no doubt, a guidance for those conscious of Allah” (Quran 2:2).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("It addresses themes such as the oneness of Allah, the purpose of life, moral conduct, and preparation for the Hereafter. The Quran calls for justice, compassion, and humility while offering hope and solace to those who reflect on its verses.")
                    .font(.body)
            }

            Section(header: Text("UNIVERSAL MESSAGE")) {
                Text("Unlike previous scriptures, which were sent to specific nations and for specific times, the Quran is meant for all of humanity, regardless of race, language, or geography. Allah says in the Quran:")
                    .font(.body)
                Text("“And We have certainly made the Quran easy for remembrance, so is there any who will remember?” (Quran 54:17)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Quran’s universality and timeless guidance make it relevant to every generation, providing solutions to contemporary issues and inspiring billions of people worldwide.")
                    .font(.body)
            }

            Section(header: Text("LEARN MORE")) {
                Text("To explore the miracles of the Quran in more detail, visit: http://www.miracles-of-quran.com")
                    .font(.caption)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("What is the Quran?")
    }
}

struct ProphetPillarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("BIOGRAPHY")) {
                Text("Prophet Muhammad (peace and blessings be upon him), whose name in Arabic is “مُحَمَّد“ (Muhammad), meaning “The Praised One,“ was born in Mecca (in present-day Saudi Arabia) around 570 CE into the noble tribe of Quraysh. Orphaned at a young age, he became known as “Al-Amin“ (The Trustworthy) due to his honesty and upright character.")
                    .font(.body)
                
                Text("At the age of 40, while meditating in the cave of Hira, he received his first revelation from Allah (Glorified and Exalted be He) through the angel Jibreel (Gabriel). This marked the beginning of his prophethood and the revelation of the Quran, the final divine guidance for humanity.")
                    .font(.body)
                
                Text("In Islamic tradition, Muhammad (peace and blessings be upon him) is referred to as “رَسُول“ (Rasul), meaning “Messenger,“ and “نَبِيّ“ (Nabi), meaning “Prophet.“ A Rasul is a prophet who brings a new scripture or law, while a Nabi may follow and uphold the teachings of a previous messenger.")
                    .font(.body)
                
                Text("He called people to worship Allah alone, rejecting idolatry and emphasizing justice, compassion, and respect for the marginalized. His teachings addressed all facets of life, including spiritual, social, economic, and political matters, as well as personal conduct and morality.")
                    .font(.body)
            }

            Section(header: Text("FINAL PROPHET")) {
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and the seal of the prophets. And ever is Allah, of all things, Knowing” (Quran 33:40).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Muslims believe Prophet Muhammad (peace and blessings be upon him) is the last and final prophet, completing the chain of messengers that began with Adam (peace be upon him). He delivered the final revelation, the Quran, and exemplified its teachings as the ultimate role model.")
                    .font(.body)
            }

            Section(header: Text("HIS CHARACTER")) {
                Text("Prophet Muhammad (peace and blessings be upon him) is described in the Quran as a man of exemplary character. Allah says in the Quran:").font(.body)
                Text("“And indeed, you are of a great moral character” (Quran 68:4).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("He was known for his compassion, humility, and justice. Even toward his enemies, he demonstrated forgiveness and kindness. Aisha (may Allah be pleased with her), his wife, described him by saying:").font(.body)
                Text("“Verily, the character of the Prophet of Allah was the Quran” (Sahih Muslim 746).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Allah also says in the Quran:").font(.body)
                Text("“There has certainly been for you in the Messenger of Allah an excellent example for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Obedience to the Prophet (peace and blessings be upon him) is also linked to obedience to Allah. Allah says in the Quran:").font(.body)
                Text("“Whoever obeys the Messenger has obeyed Allah; but those who turn away – We have not sent you over them as a guardian” (Quran 4:80).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("His humility is evident in many of his interactions. When a companion's voice trembled as he talked to the prophet, the prophet (peace and blessings be upon him) said:").font(.body)
                Text("Be calm, for I am not a king. Verily, I am only the son of a woman who ate jerky” (Sunan Ibn Majah 3312).").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("He also said:").font(.body)
                Text("“I eat as the servant eats, and I sit as the servant sits. Verily, I am only a servant” (Shu'ab al-Iman 5519).").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("Similarly, the Prophet (peace and blessings be upon him) warned against excessive praise, saying:").font(.body)
                Text("“Do not exaggerate in praising me as the Christians praised the son of Mary (Jesus), for I am only a Slave. So, call me the Slave of Allah and His Messenger” (Sahih al-Bukhari 3445).").font(.body).foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("HIS TEACHINGS")) {
                Text("The teachings and practices of Prophet Muhammad (peace and blessings be upon him) are called the Sunnah, which serve as a guide for Muslims to live a righteous and balanced life. He perfectly demonstrated how to implement the Quran in daily life.")
                    .font(.body)
                
                Text("While Muslims deeply love and revere him, worship is reserved for Allah (Glorified and Exalted be He) alone. He is honored as the finest example of humanity, yet never viewed as divine.")
                    .font(.body)
            }

            Section(header: Text("HIS IMPACT")) {
                Text("Prophet Muhammad (peace and blessings be upon him) is considered one of the most influential figures in history. Historian Michael H. Hart ranked him as the most influential person of all time, citing his unparalleled success both religiously and politically. With the will of Allah, he unified Arabia under Islam and established a faith that continues to inspire billions.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                Text("“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("HIS LEGACY")) {
                Text("Prophet Muhammad (peace and blessings be upon him) passed away at the age of 63 in Medina, leaving behind the Quran and Sunnah as guidance for humanity. In his Farewell Sermon, he emphasized the equality of all people, adherence to the Quran and Sunnah, and the importance of justice and righteousness.")
                    .font(.body)
                
                Text("He said:").font(.body)
                Text("“O People, there is no superiority of an Arab over a non-Arab, or of a non-Arab over an Arab; nor of a white person over a black person, or of a black person over a white person—except by piety and good action” (Musnad Ahmad 23489).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("LEARN MORE")) {
                Text("Famous quotes and Hadiths of Prophet Muhammad (peace be upon him): https://www.awakenthegreatnesswithin.com/35-inspirational-prophet-muhammad-pbuh-quotes/")
                    .font(.caption)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Who is the Prophet?")
    }
}

struct SunnahPillarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("DEFINITION")) {
                Text("The Sunnah, derived from the Arabic word “سُنَّة“ (Sunnah), meaning “a way,“ “path,“ or “tradition,“ refers to the teachings, actions, and approvals of Prophet Muhammad (peace and blessings be upon him). It includes his daily habits, moral conduct, and guidance on worship and interpersonal relations. The Sunnah complements the Quran and is the second most important source of Islamic knowledge.")
                    .font(.body)
                
                Text("Allah says in the Quran:").font(.body)
                Text("“And whatever the Messenger has given you – take; and what he has forbidden you – refrain from. And fear Allah; indeed, Allah is severe in penalty” (Quran 59:7).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("IMPORTANCE")) {
                Text("The Sunnah provides practical guidance on how to live according to the Quran. It clarifies general commands in the Quran and gives specific instructions. For instance, the Quran commands Muslims to pray, and the Sunnah demonstrates how to perform the prayer.")
                    .font(.body)
                
                Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                Text("“Pray as you have seen me praying” (Sahih al-Bukhari 631).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("The Sunnah also serves as an example for personal conduct and social interactions. Allah says in the Quran:").font(.body)
                Text("“There has certainly been for you in the Messenger of Allah an excellent example for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Obedience to the Sunnah is considered obedience to Allah. Allah says in the Quran:").font(.body)
                Text("“Whoever obeys the Messenger has obeyed Allah; but those who turn away – We have not sent you over them as a guardian” (Quran 4:80).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            
            Section(header: Text("HADITH LITERATURE")) {
                Text("The Sunnah is preserved through the Hadith, which are compilations of the recorded sayings, actions, and approvals of the Prophet Muhammad (peace and blessings be upon him). These narrations were meticulously verified by scholars to ensure their authenticity.")
                    .font(.body)
                
                Text("Major Hadith collections include:").font(.body)
                Text("1. Sahih al-Bukhari").font(.body)
                Text("2. Sahih Muslim").font(.body)
                Text("3. Sunan Abu Dawood").font(.body)
                Text("4. Jami' at-Tirmidhi").font(.body)
                Text("5. Sunan an-Nasa'i").font(.body)
                Text("6. Sunan Ibn Majah").font(.body)
                
                Text("These collections provide invaluable insights into the life and teachings of the Prophet (peace and blessings be upon him) and serve as a foundation for understanding and implementing the Sunnah.")
                    .font(.body)
            }
            
            Section(header: Text("EXAMPLES OF SUNNAH")) {
                Text("Examples of Sunnah practices include:").font(.body)
                Text("1. Greeting others with “As-Salamu Alaikum“ (peace be upon you).").font(.body)
                Text("2. Saying “Bismillah“ (in the name of Allah) before eating.").font(.body)
                Text("3. Performing acts of charity, such as smiling at others, which is considered a form of charity.").font(.body)
                Text("4. Maintaining cleanliness and grooming, such as trimming nails and keeping oneself tidy.").font(.body)
                Text("5. Showing kindness and mercy to others, including animals.").font(.body)
                Text("6. Praying certain optional prayers.").font(.body)
            }
            
            Section(header: Text("RESOURCES")) {
                Text("You can view Hadith collections here: https://sunnah.com/")
                    .font(.caption)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("What is the Sunnah?")
    }
}

struct HadithPillarView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        List {
            Section(header: Text("INTRODUCTION")) {
                Text("Hadiths, derived from the Arabic word “حَديث“ (Hadith), meaning “speech,“ “narration,“ or “report,“ are the recorded sayings, actions, and approvals of Prophet Muhammad (peace and blessings be upon him). They complement the Quran and serve as an essential source of Islamic knowledge, offering detailed guidance on faith, worship, and daily life. The Sunnah is preserved through Hadiths, which is why these narrations were meticulously verified by scholars to ensure their authenticity.")
                    .font(.body)
                
                Text("Allah (Glorified and Exalted be He) commands in the Quran:").font(.body)
                Text("“And whatever the Messenger has given you – take; and what he has forbidden you – refrain from. And fear Allah; indeed, Allah is severe in penalty” (Quran 59:7).")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                
                Text("Hadiths are indispensable for understanding and implementing the Quran’s teachings, as they provide practical examples of how Prophet Muhammad (peace and blessings be upon him) lived according to Allah’s commands.")
                    .font(.body)
            }
            
            Section(header: Text("RELATIONSHIP WITH THE QURAN")) {
                Text("Hadiths are essential for interpreting and contextualizing the Quran. Allah says in the Quran:").font(.body)
                Text("“It is He who has sent down to you, [O Muhammad], the Book; in it are verses [that are] precise... and others unspecific” (Quran 3:7).").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("While the Quran provides general principles, the Hadith clarifies how to implement these teachings. For example, the Quran commands Muslims to pray, and the Hadith describes how the Prophet (peace and blessings be upon him) performed Salah. He said:").font(.body)
                Text("“Pray as you have seen me praying” (Sahih al-Bukhari 631).").font(.body).foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("TYPES OF HADITHS")) {
                Text("There are two main types of Hadiths:").font(.body)
                
                Text("1. **Hadith Qudsi (Sacred Hadith):** These are sayings where the Prophet (peace and blessings be upon him) conveys meanings from Allah (Glorified and Exalted be He), but the wording is his own. Unlike the Quran, which is the exact verbatim word of Allah, Hadith Qudsi reflects divine inspiration shared through the Prophet’s speech. For example, the Prophet said:").font(.body)
                Text("“Allah the Almighty said: ‘I am as My servant thinks I am. I am with him when he remembers Me.’” (Sahih al-Bukhari 7405)").font(.body).foregroundColor(settings.accentColor.color)
                Text("While the Quran was revealed through the Angel Jibreel (Gabriel) and recited exactly as revealed, Hadith Qudsi might have been conveyed to the Prophet through a dream or inspiration. It holds a special status but is not part of the Quran.")
                    .font(.body)
                
                Text("2. **Hadith Nabawi (Prophetic Hadith):** These include the Prophet’s own words, actions, and approvals, reflecting his teachings and practices. For instance, he said:").font(.body)
                Text("“The best among you (Muslims) are those who learn the Quran and teach it” (Sahih al-Bukhari 5027).").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("Learn the difference here: https://www.youtube.com/watch?v=F7vfmGC-o-A")
                    .font(.caption)
            }

            Section(header: Text("AUTHENTICITY AND CLASSIFICATION")) {
                Text("Hadiths were meticulously preserved and classified by scholars based on their authenticity to ensure the teachings of Prophet Muhammad (peace and blessings be upon him) were transmitted accurately. A hadith consists of two critical components:").font(.body)
                Text("1. **Isnad (Chain of Transmission):** The sequence of narrators who transmitted the hadith. This ensures a direct link back to the Prophet (peace and blessings be upon him).").font(.body)
                Text("2. **Matn (Text):** The content of the hadith itself, which is examined for consistency with established Islamic teachings and linguistic accuracy.").font(.body)
                
                Text("The rigorous analysis of isnad and matn is crucial because some individuals attempted to fabricate sayings of the Prophet (peace and blessings be upon him). To safeguard against such corruption, scholars developed a meticulous science of hadith authentication. The Prophet (peace and blessings be upon him) warned:").font(.body)
                Text("“Whoever tells a lie against me intentionally, then (surely) let him occupy his seat in Hell-fire” (Sahih al-Bukhari 108).").font(.body).foregroundColor(settings.accentColor.color)
                
                Text("This rigorous methodology prevented the kind of corruption and fabrications found in other scriptures, such as the Bible, where authors are often anonymous, and transmission chains are unknown. In Islam, every hadith is traced back through a reliable chain of narrators to the Prophet (peace and blessings be upon him).").font(.body)
                
                Text("Scholars classified Hadiths into categories based on their reliability and authenticity:").font(.body)
                Text("- **Mutawatir (Mass-Transmitted):** Narrated by a large number of trustworthy narrators, ensuring its authenticity without any doubt.").font(.body)
                Text("- **Sahih (Authentic):** Reliable chain and text, meeting strict criteria of authenticity.").font(.body)
                Text("- **Hasan (Good):** Slightly weaker chain than Sahih but still reliable and acceptable for use in rulings.").font(.body)
                Text("- **Da'if (Weak):** Questionable reliability due to issues in the chain or content, generally avoided for rulings.").font(.body)
                
                Text("The highest rank of authentic hadith is known as **Muttafaqun Alayh**, meaning “agreed upon.“ These are hadiths narrated by both Imam Bukhari and Imam Muslim in their Sahih collections, indicating the highest level of authenticity.").font(.body)
                
                Text("This detailed grading system ensures that Muslims can confidently rely on the Hadiths as a source of guidance without the risk of fabricated or unreliable narrations.")
                    .font(.body)
            }

            Section(header: Text("IMPORTANCE OF HADITHS")) {
                Text("The Hadiths are indispensable for:").font(.body)
                Text("1. **Clarifying the Quran:** They explain Quranic commands, such as how to perform Salah and fast during Ramadan.").font(.body)
                Text("2. **Guiding Daily Life:** Hadiths provide moral and ethical lessons, teaching Muslims how to interact with others and live righteously.").font(.body)
                Text("3. **Strengthening Faith:** They contain spiritual guidance and wisdom that deepen a Muslim’s connection to Allah (Glorified and Exalted be He).").font(.body)
                
                Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                Text("“I have left you with two matters which will never lead you astray, as long as you hold to them: the Book of Allah and the Sunnah of his Prophet” (al-Muwatta' 1661).").font(.body).foregroundColor(settings.accentColor.color)
            }

            Section(header: Text("RESOURCES")) {
                Text("You can view Hadith collections here: https://sunnah.com/")
                    .font(.caption)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("What are Hadiths?")
    }
}
