import SwiftUI

struct ArabicLetterView: View {
    @EnvironmentObject var settings: Settings
    
    let letterData: LetterData
        
    var body: some View {
        VStack {
            List {
                Section(header: LetterSectionHeader(letterData: letterData)) {
                    VStack {
                        HStack(alignment: .center) {
                            Spacer()
                            
                            Text(letterData.transliteration)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(letterData.name)
                                .font(settings.useFontArabic ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize) : .title)
                            
                            Spacer()
                        }
                    }
                    #if !os(watchOS)
                    .listRowSeparator(.hidden, edges: .bottom)
                    #endif
                    .padding(.vertical, settings.useFontArabic ? 0 : 2)
                }
                
                Section(header: Text("DIFFERENT FORMS")) {
                    VStack {
                        HStack(alignment: .center) {
                            ForEach(0..<3, id: \.self) { index in
                                Spacer()
                                Text(letterData.forms[index])
                                    .font(settings.useFontArabic ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize) : .title)
                                Spacer()
                            }
                        }
                    }
                    #if !os(watchOS)
                    .listRowSeparator(.hidden, edges: .bottom)
                    #endif
                    .padding(.vertical, settings.useFontArabic ? 0 : 2)
                }
                
                if letterData.transliteration == "alif" || letterData.transliteration == "waw" || letterData.transliteration == "yaa" {
                    Section(header: Text("SPECIAL ROLE OF VOWEL LETTERS")) {
                        Text("In Arabic, three letters (Alif, Waw, and Yaa) have a special dual role:")
                            .font(.body)
                        
                        if letterData.transliteration == "alif" {
                            Text("- **Alif (ا)**: Functions as a long vowel 'aa' when used after a letter with a fatha. For example, كِتَاب (kitaab - book). Alif never carries tashkeel unless it represents Hamza.")
                                .font(.body)
                        }
                        
                        if letterData.transliteration == "waw" {
                            Text("- **Waw (و)**: Functions as a long vowel 'uu' when used after a letter with a damma, like in رَسُول (rasool - messenger). As a consonant, it makes the 'w' sound, like in وَقَفَ (waqafa - stood).")
                                .font(.body)
                        }
                        
                        if letterData.transliteration == "yaa" {
                            Text("- **Yaa (ي): Functions as a long vowel 'ii' when used after a letter with a kasra, like in كِتَابِي (kitaabi - my book). As a consonant, it makes the 'y' sound, like in يَد (yad - hand).")
                                .font(.body)
                        }
                        
                        Text("These letters serve as vowels when they follow specific diacritics, and as consonants when they begin a word or are preceded by a sukoon.")
                            .font(.body)
                    }
                }
                
                if letterData.showTashkeel {
                    Section(header: Text("DIFFERENT HARAKAAT (VOWELS)")) {
                        let chunks = tashkeels.chunked(into: 3)
                        ForEach(0..<chunks.count, id: \.self) { index in
                            VStack {
                                #if !os(watchOS)
                                if index > 0 {
                                    Divider()
                                        .padding(.trailing, -100)
                                }
                                #endif
                                
                                TashkeelRow(
                                    letterData: letterData,
                                    tashkeels: chunks[index]
                                )
                                .padding(.top, 14)
                                .padding(.bottom, index == chunks.count - 1 ? 14 : 0)
                            }
                            #if !os(watchOS)
                            .listRowSeparator(.hidden, edges: .bottom)
                            #endif
                        }
                    }
                }
                if (!letterData.showTashkeel && letterData.transliteration != "alif") || letterData.transliteration == "yaa" {
                    Section(header: Text("PURPOSE")) {
                        if letterData.transliteration == "yaa" {
                            Text("In the Uthmani script of the Quran, when 'yaa' is written at the end of a word (or by itself), it is usually written without the two dots underneath.")
                                .font(.body)
                        } else if letterData.transliteration == "taa marbuuTa" {
                            Text("\"Taa marbuuTa\" means \"tied taa\" and is used to indicate the feminine gender in Arabic.")
                                .font(.body)
                            Text("It is typically added to the end of a noun to show that the noun is feminine. For example, the Arabic word for teacher is \"معلم\" (mu'allim) for a male and \"معلمة\" (mu'allima) for a female.")
                                .font(.body)
                            Text("Taa marbuuTa is pronounced as a \"t\" sound in certain cases, such as when the word is in the construct state or has a suffix. Otherwise, it is often silent but affects the preceding vowel, usually creating a short \"ah\" sound, similar to 'ه' (as in \"mu'allimah\").")
                                .font(.body)
                        } else if letterData.transliteration == "hamzatul waSl" {
                            Text("The term \"hamzatul waSl\" translates to \"connecting hamza\" or \"hamza of connection.\"")
                                .font(.body)
                            Text("Hamzatul waSl is always written as an Alif (ا) and is pronounced only if it begins a word at the start of speech. When the word follows another in a sentence, the hamzatul waSl is not pronounced, creating a smooth connection between words.")
                                .font(.body)
                            Text("If a word starts with hamzatul waSl, its pronunciation depends on the third letter of the word. For verbs: if the third letter has a damma, pronounce it with a damma (أُ); if it has a kasra or fatha, pronounce it with a kasra (إِ).")
                                .font(.body)
                            Text("In the Quran, there are seven nouns that start with hamzatul waSl. These nouns always begin with a kasra when pronounced in isolation.")
                                .font(.body)
                            Text("Hamzatul waSl is usually not written with diacritics, but in learner texts or the Quran, it may be marked with a small ص above the Alif, indicating waSl.")
                                .font(.body)
                        } else if letterData.transliteration.contains("hamza") {
                            Text("The letter Hamza has multiple forms, depending on its position and the surrounding vowels or diacritics (tashkeel):")
                                .font(.body)
                            Text("Hamza on its own (ء): Used when Hamza appears in the middle or end of a word without a preceding vowel.")
                                .font(.body)
                            Text("Hamza on an Alif (أ or إ): When Hamza begins a word, it is written on an Alif. A fatha or damma places it above (أ), while a kasra places it below (إ).")
                                .font(.body)
                            Text("Hamza on a Waw (ؤ): Appears after a damma or following a Waw.")
                                .font(.body)
                            Text("Hamza on a Yaa (ئ): Appears after a kasra or following a Yaa.")
                                .font(.body)
                            Text("Although Hamza takes different forms, it represents the same sound ('ah'). These forms are based on Arabic orthography (spelling conventions) rather than phonetics.")
                                .font(.body)
                        } else if letterData.transliteration.contains("mad") {
                            Text("The wavy line above a vowel letter is called a 'mad'. It elongates the vowel sound, typically lasting 4 counts.")
                                .font(.body)
                            
                            if letterData.transliteration.contains("alif") {
                                Text("If an Alif Mad is followed by a letter with a shaddah, the elongation extends to 6 counts.")
                                    .font(.body)
                            }
                        } else if letterData.transliteration == "alif maqSoorah" {
                            Text("Alif maqSoorah resembles a Yaa without dots and usually replaces a regular Alif at the end of a word. It is used in certain cases, including some Quranic words and non-Arabic proper nouns. It is the exact same and sounds the same as alif.")
                                .font(.body)
                        } else if letterData.transliteration == "laa" {
                            Text("The combination of ل and ا forms a unique shape: لا.")
                                .font(.body)
                        }
                    }
                }
            }
            
            #if !os(watchOS)
            Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
                Text("Quranic Font").tag(true)
                Text("Basic Font").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 12)
            #endif
        }
        #if !os(watchOS)
        .applyConditionalListStyle(defaultView: true)
        .dismissKeyboardOnScroll()
        #endif
        .navigationTitle(letterData.letter)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct TashkeelRow: View {
    @EnvironmentObject var settings: Settings
    let letterData: LetterData
    let tashkeels: [Tashkeel]

    var body: some View {
        HStack(spacing: 20) {
            ForEach(tashkeels, id: \.english) { tashkeel in
                VStack(alignment: .center) {
                    if !tashkeel.transliteration.isEmpty {
                        Text(letterData.sound + tashkeel.transliteration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if tashkeel.english == "Shaddah" {
                        Text(letterData.sound + letterData.sound)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if tashkeel.english == "Sukoon" {
                        Text(letterData.sound)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(letterData.letter + tashkeel.tashkeelMark)
                        .font(settings.useFontArabic ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize) : .title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, settings.useFontArabic ? 0 : 8)
                    
                    #if !os(watchOS)
                    Text(tashkeel.english)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    #endif
                }
            }
        }
    }
}
