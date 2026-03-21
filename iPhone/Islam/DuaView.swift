import SwiftUI

struct DuaView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        List {
            Section(header: Text("SUPPLICATIONS TO ALLAH ﷻ‎")) {
                Text("Dua (supplication) is the heart of worship and a direct line to Allah ﷻ. It allows us to speak directly to Him, anytime, anywhere, in any language. It reflects our dependence, humility, and hope. Prophet Muhammad ﷺ taught countless duas for every moment, guiding us to turn to Allah ﷻ‎ in all circumstances.\n\nAllah ﷻ‎ says: “Call upon Me; I will respond to you” (Quran 40:60).\nProphet Muhammad ﷺ said: “Dua is worship” (Tirmidhi 2969).")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن زَوَالِ نِعمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ وَفُجَاءَةِ نِقمَتِكَ وَجَمِيعِ سَخَطِكَ", transliteration: "Allahumma inni a'udhu bika min zawali ni'matika wa tahawwuli 'afiyatika wa fuja'ati niqmatika wa jamee' sakhatika", translation: "O Allah, I seek refuge in You from the removal of Your blessings, changing of Your protection, sudden wrath, and all of Your displeasure")
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ العَفوَ وَالعَافِيَةَ فِي الدُّنيَا وَالآخِرَةِ", transliteration: "Allahumma inni as'aluka al-'afwa wal-'afiyah fi ad-dunya wal-akhirah", translation: "O Allah, I ask You for forgiveness and well-being in this life and the hereafter")
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ الهُدَى وَالتُّقَى وَالعَفَافَ وَالغِنَى", transliteration: "Allahumma inni as'aluka al-huda wa at-tuqaa wal-'afaafa wal-ghina", translation: "O Allah, I ask You for guidance, righteousness, chastity, and sufficiency")
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الكُفرِ وَالفَقرِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ", transliteration: "Allahumma inni a'udhu bika min al-kufr wal-faqr wa a'udhu bika min 'adhab al-qabr", translation: "O Allah, I seek refuge in You from disbelief, poverty, and the punishment of the grave")
            AdhkarRow(arabicText: "اللَّهُمَّ مَا أَصبَحَ بِي مِن نِعمَةٍ أَو بِأَحَدٍ مِن خَلقِكَ فَمِنكَ وَحدَكَ لَا شَرِيكَ لَكَ فَلَكَ الحَمدُ وَلَكَ الشُّكرُ", transliteration: "Allahumma ma asbaha bi min ni'matin, aw bi ahadin min khalqika, faminka wahdaka la sharika laka, falaka alhamdu wa laka ash-shukr", translation: "O Allah, whatever blessings I or any of Your creatures rose up with, is from You alone, without partner, so for You is all praise and unto You all thanks.")
            AdhkarRow(arabicText: "رَبِّ اشرَح لِي صَدرِي وَيَسِّر لِي أَمرِي", transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "O my Lord, expand for me my chest, and ease for me my task.")
            AdhkarRow(arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكرِكَ وَشُكرِكَ وَحُسنِ عِبَادَتِكَ", transliteration: "Allahumma a'innee ala dhikrika wa shukrika wa husni ibadatika", translation: "O Allah, assist me in remembering You, in thanking You, and in worshipping You in the best manner.")
            AdhkarRow(arabicText: "رَبَّنَا آتِنَا فِي الدُّنيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", transliteration: "Rabbanaa atinaa fid-dunya hasanatan wa fil aakhirati hasanatan wa qinaa 'adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.")
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن عَجزِ وَالكَسَلِ وَالجُبنِ وَالهَرَمِ وَالبُخلِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ وَمِن فِتنَةِ المَحيَا وَالمَمَاتِ", transliteration: "Allahumma inni a'udhu bika min al-'ajzi wal-kasali wal-jubni wal-harami wal-bukhli, wa a'udhu bika min 'adhab al-qabr, wa min fitnat al-mahya wal-mamat", translation: "O Allah, I seek refuge in You from weakness and laziness, miserliness and cowardice, the burden of debts and from being overpowered by men. I seek refuge in You from the punishment of the grave and from the trials and tribulations of life and death.")
            AdhkarRow(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ عِلمًا نَافِعًا، وَرِزقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted.")
            AdhkarRow(
                arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الحَيُّ القَيُّومُ ۚ لَا تَأخُذُهُ سِنَةٌ وَلَا نَومٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الأَرضِ ۗ مَن ذَا الَّذِي يَشفَعُ عِندَهُ إِلَّا بِإِذنِهِ ۚ يَعلَمُ مَا بَينَ أَيدِيهِم وَمَا خَلفَهُم ۖ وَلَا يُحِيطُونَ بِشَيءٍ مِّن عِلمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرسِيُّهُ السَّمَاوَاتِ وَالأَرضَ ۖ وَلَا يَئُودُهُ حِفظُهُمَا ۚ وَهُوَ العَلِيُّ العَظِيمُ",
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
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .navigationTitle("Common Duas")
    }
}
