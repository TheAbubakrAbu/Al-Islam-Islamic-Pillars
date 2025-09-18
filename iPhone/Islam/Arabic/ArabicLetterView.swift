import SwiftUI

struct LetterSectionHeader: View {
    @EnvironmentObject var settings: Settings
    let letterData: LetterData
    
    var body: some View {
        HStack {
            Text("LETTER")
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: settings.isLetterFavorite(letterData: letterData) ? "star.fill" : "star")
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    settings.toggleLetterFavorite(letterData: letterData)
                }
        }
    }
}

struct ArabicLetterView: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase
    
    let letterData: LetterData
    
    @State private var tempArabicFont = false
        
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
                                .font(
                                    tempArabicFont
                                    ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                    : .title2
                                )
                            
                            Spacer()
                        }
                    }
                    #if !os(watchOS)
                    .listRowSeparator(.hidden, edges: .bottom)
                    #endif
                    .padding(.vertical, tempArabicFont ? 0 : 2)
                }
                
                Section(header: Text("DIFFERENT FORMS")) {
                    VStack {
                        HStack(alignment: .center) {
                            ForEach(0..<3, id: \.self) { index in
                                Spacer()
                                Text(letterData.forms[index])
                                    .font(
                                        tempArabicFont
                                        ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                        : .title2
                                    )
                                Spacer()
                            }
                        }
                    }
                    #if !os(watchOS)
                    .listRowSeparator(.hidden, edges: .bottom)
                    #endif
                    .padding(.vertical, tempArabicFont ? 0 : 2)
                }
                
                if ["alif", "waw", "yaa"].contains(letterData.transliteration) {
                    Section(header: Text("SPECIAL ROLE OF VOWEL LETTERS")) {
                        Text("In Arabic, three letters (Alif, Waw, and Yaa) have a special dual role:")
                            .font(.body)
                        
                        if letterData.transliteration == "alif" {
                            Text("- **Alif (ا)**: Functions as a long vowel 'aa' when used after a letter with a fatha. For example, كِتَاب (kitaab - book). Alif never carries tashkeel unless it represents Hamza.")
                                .font(.body)
                        }
                        
                        if letterData.transliteration == "waw" {
                            Text("- **Waw (و)**: Functions as a long vowel 'uu' when used after a letter with a damma, like in رَسُول (rasool - messenger). As a consonant, it makes the 'w' sound, like in وَقَفَ (waqafa - stood).")
                                .font(.body)
                        }
                        
                        if letterData.transliteration == "yaa" {
                            Text("- **Yaa (ي)**: Functions as a long vowel 'ii' when used after a letter with a kasra, like in كِتَابِي (kitaabi - my book). As a consonant, it makes the 'y' sound, like in يَد (yad - hand).")
                                .font(.body)
                        }
                        
                        Text("These letters serve as vowels when they follow specific diacritics, and as consonants when they begin a word or are preceded by a sukoon.")
                            .font(.body)
                    }
                }
                
                if letterData.showTashkeel {
                    Section(header: Text("DIFFERENT HARAKAAT (VOWELS)")) {
                        let chunks = tashkeels.chunked(into: 3)
                        ForEach(chunks.indices, id: \.self) { idx in
                            VStack {
                                #if !os(watchOS)
                                if idx > 0 {
                                    Divider().padding(.trailing, -100)
                                }
                                #endif
                                
                                TashkeelRow(letterData: letterData, tashkeels: chunks[idx], tempArabicFont: tempArabicFont)
                                    .padding(.top, 14)
                                    .padding(.bottom, idx == chunks.count - 1 ? 14 : 0)
                            }
                            #if !os(watchOS)
                            .listRowSeparator(.hidden, edges: .bottom)
                            #endif
                        }
                    }
                }
                
                if (!letterData.showTashkeel && letterData.transliteration != "alif")
                    || letterData.transliteration == "yaa" {
                    
                    Section(header: Text("PURPOSE")) {
                        purposeSection(for: letterData)
                    }
                }
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .dismissKeyboardOnScroll()
            
            #if !os(watchOS)
            Picker("Arabic Font", selection: $tempArabicFont.animation(.easeInOut)) {
                Text("Quranic Font").tag(true)
                Text("Basic Font").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal, .bottom], 12)
            #endif
        }
        .navigationTitle(letterData.letter)
        .onAppear {
            withAnimation {
                tempArabicFont = settings.useFontArabic
            }
        }
        .onDisappear { settings.useFontArabic = tempArabicFont }
        .onChange(of: scenePhase) { _ in
            settings.useFontArabic = tempArabicFont
        }
    }
    
    @ViewBuilder
    private func purposeSection(for data: LetterData) -> some View {
        switch data.transliteration {
        case "yaa":
            Text("In the Uthmani script of the Quran, when 'yaa' is written at the end of a word (or by itself), it is usually written without the two dots underneath.")
                .font(.body)
        case "taa marbuuTa":
            Group {
                Text("\"Taa marbuuTa\" means \"tied taa\" and is used to indicate the feminine gender in Arabic.")
                Text("It is typically added to the end of a noun to show that the noun is feminine. For example, the Arabic word for teacher is \"معلم\" (mu'allim) for a male and \"معلمة\" (mu'allima) for a female.")
                Text("Taa marbuuTa is pronounced as a \"t\" sound in certain cases, such as when the word is in the construct state or has a suffix. Otherwise, it is often silent but affects the preceding vowel, usually creating a short \"ah\" sound, similar to 'ه' (as in \"mu'allimah\").")
            }
            .font(.body)
        case "hamzatul waSl":
            Group {
                Text("The term \"hamzatul waSl\" translates to \"connecting hamza\" or \"hamza of connection.\"")
                Text("Hamzatul waSl is always written as an Alif (ا) and is pronounced only if it begins a word at the start of speech. When the word follows another in a sentence, the hamzatul waSl is not pronounced, creating a smooth connection between words.")
                Text("If a word starts with hamzatul waSl, its pronunciation depends on the third letter of the word. For verbs: if the third letter has a damma, pronounce it with a damma (أُ); if it has a kasra or fatha, pronounce it with a kasra (إِ).")
                Text("In the Quran, there are seven nouns that start with hamzatul waSl. These nouns always begin with a kasra when pronounced in isolation.")
                Text("Hamzatul waSl is usually not written with diacritics, but in learner texts or the Quran, it may be marked with a small ص above the Alif, indicating waSl.")
            }
            .font(.body)
        default:
            if data.transliteration.contains("hamza") {
                Group {
                    Text("The letter Hamza has multiple forms, depending on its position and the surrounding vowels or diacritics (tashkeel):")
                    Text("Hamza on its own (ء): Used when Hamza appears in the middle or end of a word without a preceding vowel.")
                    Text("Hamza on an Alif (أ or إ): When Hamza begins a word, it is written on an Alif. A fatha or damma places it above (أ), while a kasra places it below (إ).")
                    Text("Hamza on a Waw (ؤ): Appears after a damma or following a Waw.")
                    Text("Hamza on a Yaa (ئ): Appears after a kasra or following a Yaa.")
                    Text("Although Hamza takes different forms, it represents the same sound ('ah'). These forms are based on Arabic orthography (spelling conventions) rather than phonetics.")
                }
                .font(.body)
            } else if data.transliteration.contains("mad") {
                Group {
                    Text("The wavy line above a vowel letter is called a 'mad'. It elongates the vowel sound, typically lasting 4 counts.")
                    + (
                        data.transliteration.contains("alif")
                        ? Text("\nIf an Alif Mad is followed by a letter with a shaddah, the elongation extends to 6 counts.")
                        : Text("")
                    )
                }
                    .font(.body)
            } else if data.transliteration == "alif maqSoorah" {
                Text("Alif maqSoorah resembles a Yaa without dots and usually replaces a regular Alif at the end of a word. It is used in certain cases, including some Quranic words and non-Arabic proper nouns. It is the exact same and sounds the same as alif.")
                    .font(.body)
            } else if data.transliteration == "laa" {
                Text("The combination of ل and ا forms a unique shape: لا.")
                    .font(.body)
            }
        }
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
    let tempArabicFont: Bool

    var body: some View {
        HStack(spacing: 20) {
            ForEach(tashkeels, id: \.english) { tk in
                VStack {
                    if !tk.transliteration.isEmpty {
                        Text(letterData.sound + tk.transliteration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if tk.english == "Shaddah" {
                        Text(letterData.sound + letterData.sound)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if tk.english == "Sukoon" {
                        Text(letterData.sound)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(letterData.letter + tk.tashkeelMark)
                        .font(
                            tempArabicFont
                            ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                            : .title
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, tempArabicFont ? 0 : 8)
                    
                    #if !os(watchOS)
                    Text(tk.english)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    #endif
                }
            }
        }
    }
}
