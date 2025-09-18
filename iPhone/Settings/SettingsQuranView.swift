import SwiftUI

struct SettingsQuranView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    
    @State private var showEdits: Bool

    init(showEdits: Bool = false) {
        _showEdits = State(initialValue: showEdits)
    }
    
    var body: some View {
        List {
            Section(header: Text("RECITATION")) {
                VStack(spacing: 10) {
                    NavigationLink(destination: ReciterListView().environmentObject(settings)) {
                        Label("Choose Reciter", systemImage: "headphones")
                    }
                    
                    HStack {
                        Text(settings.reciter)
                            .foregroundColor(settings.accentColor.color)
                        
                        Spacer()
                    }
                }
                .accentColor(settings.accentColor.color)
                
                Picker("After Surah Recitation Ends", selection: $settings.reciteType.animation(.easeInOut)) {
                    Text("Continue to Next").tag("Continue to Next")
                    Text("Continue to Previous").tag("Continue to Previous")
                    Text("End Recitation").tag("End Recitation")
                }
                .font(.subheadline)
                
                Text("The Quran recitations are streamed online and not downloaded, which may consume a lot of data if used frequently, especially when using cellular data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("ARABIC TEXT")) {
                Toggle("Show Arabic Quran Text", isOn: $settings.showArabicText.animation(.easeInOut))
                    .font(.subheadline)
                    .disabled(!settings.showTransliteration && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
                
                if settings.showArabicText {
                    VStack(alignment: .leading) {
                        Toggle("Remove Arabic Tashkeel (Vowel Diacritics) and Signs", isOn: $settings.cleanArabicText.animation(.easeInOut))
                            .font(.subheadline)
                            .disabled(!settings.showArabicText)
                        
                        #if !os(watchOS)
                        Text("This option removes Tashkeel, which are vowel diacretic marks such as Fatha, Damma, Kasra, and others, while retaining essential vowels like Alif, Yaa, and Waw. It also adjusts \"Mad\" letters and the \"Hamzatul Wasl,\" and removes baby vowel letters, various textual annotations including stopping signs, chapter markers, and prayer indicators. This option is not recommended.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                        #else
                        Text("This option removes Tashkeel (vowel diacretics).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                        #endif
                    }
                    
                    Picker("Arabic Font", selection: $settings.fontArabic.animation(.easeInOut)) {
                        Text("Uthmani").tag("KFGQPCHafsEx1UthmanicScript-Reg")
                        Text("Indopak").tag("Al_Mushaf")
                    }
                    #if !os(watchOS)
                    .pickerStyle(SegmentedPickerStyle())
                    #endif
                    .disabled(!settings.showArabicText)
                    
                    Stepper(value: $settings.fontArabicSize.animation(.easeInOut), in: 15...50, step: 2) {
                        Text("Arabic Font Size: \(Int(settings.fontArabicSize))")
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Enable Arabic Beginner Mode", isOn: $settings.beginnerMode.animation(.easeInOut))
                            .font(.subheadline)
                            .disabled(!settings.showArabicText)
                        
                        Text("Puts a space between each Arabic letter to make it easier for beginners to read the Quran.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }
                }
            }
            
            Section(header: Text("ENGLISH TEXT")) {
                Toggle("Show Transliteration", isOn: $settings.showTransliteration.animation(.easeInOut))
                    .font(.subheadline)
                    .disabled(!settings.showArabicText && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
                
                Toggle("Show English Translation\nSaheeh International", isOn: $settings.showEnglishSaheeh.animation(.easeInOut))
                    .font(.subheadline)
                    .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishMustafa)
                
                Toggle("Show English Translation\nClear Quran (Mustafa Khattab)", isOn: $settings.showEnglishMustafa.animation(.easeInOut))
                    .font(.subheadline)
                    .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishSaheeh)
                
                if settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa {
                    Stepper(value: $settings.englishFontSize.animation(.easeInOut), in: 13...20, step: 1) {
                        Text("English Font Size: \(Int(settings.englishFontSize))")
                            .font(.subheadline)
                    }
                }
                
                Toggle("Use System Font Size", isOn: Binding(
                    get: {
                        let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                        var usesSystemSizes = true
                        
                        if settings.showArabicText {
                            usesSystemSizes = usesSystemSizes && (settings.fontArabicSize == systemBodySize + 10)
                        }
                        
                        if settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa {
                            usesSystemSizes = usesSystemSizes && (settings.englishFontSize == systemBodySize)
                        }
                        return usesSystemSizes
                    },
                    set: { newValue in
                        let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                        withAnimation {
                            if newValue {
                                settings.fontArabicSize = systemBodySize + 10
                                settings.englishFontSize = systemBodySize
                            } else {
                                settings.fontArabicSize = systemBodySize + 11
                                settings.englishFontSize = systemBodySize + 1
                            }
                        }
                    }
                ))
                .font(.subheadline)
            }
            
            #if !os(watchOS)
            if showEdits {
                Section(header: Text("FAVORITES AND BOOKMARKS")) {
                    NavigationLink(destination: FavoritesView(type: .surah).environmentObject(quranData).accentColor(settings.accentColor.color)) {
                        Text("Edit Favorite Surahs")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                    
                    NavigationLink(destination: FavoritesView(type: .ayah).environmentObject(quranData).accentColor(settings.accentColor.color)) {
                        Text("Edit Bookmarked Ayahs")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                    
                    NavigationLink(destination: FavoritesView(type: .letter).environmentObject(quranData).accentColor(settings.accentColor.color)) {
                        Text("Edit Favorite Letters")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }
            #endif
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Al-Quran Settings")
    }
}

struct ReciterListView: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        List {
            Section(header: Text("Reciters")) {
                ForEach(reciters, id: \.self) { reciter in
                    Button(action: {
                        settings.hapticFeedback()
                        
                        withAnimation {
                            settings.reciter = reciter.name
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(reciter.name)
                                    .font(.subheadline)
                                    .foregroundColor(reciter.name == settings.reciter ? settings.accentColor.color : .primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark")
                                    .foregroundColor(settings.accentColor.color)
                                    .opacity(reciter.name == settings.reciter ? 1 : 0)
                            }
                            
                            if reciter.ayahIdentifier.contains("minshawi") && !reciter.name.contains("Minshawi") {
                                Text("This reciter is only available for surah recitation. Defaults to Minshawi (Murattal) for ayahs.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Select Reciter")
        .applyConditionalListStyle(defaultView: true)
    }
}

#if !os(watchOS)
enum FavoriteType {
    case surah, ayah, letter
}

struct FavoritesView: View {
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var settings: Settings
    
    @State private var editMode: EditMode = .inactive

    let type: FavoriteType

    var body: some View {
        List {
            switch type {
            case .surah:
                if settings.favoriteSurahs.isEmpty {
                    Text("No favorite surahs here, long tap a surah to favorite it.")
                } else {
                    ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahId in
                        if let surah = quranData.quran.first(where: { $0.id == surahId }) {
                            SurahRow(surah: surah)
                        }
                    }
                    .onDelete(perform: removeSurahs)
                }
            case .ayah:
                if settings.bookmarkedAyahs.isEmpty {
                    Text("No bookmarked ayahs here, long tap an ayah to bookmark it.")
                } else {
                    ForEach(settings.bookmarkedAyahs.sorted {
                        $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                    }, id: \.id) { bookmarkedAyah in
                        if let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah }), let ayah = surah.ayahs.first(where: { $0.id == bookmarkedAyah.ayah }) {
                                SurahAyahRow(surah: surah, ayah: ayah)
                            }
                    }
                    .onDelete(perform: removeAyahs)
                }
            case .letter:
                if settings.favoriteLetters.isEmpty {
                    Text("No favorite letters here, long tap a letter to favorite it.")
                } else {
                    ForEach(settings.favoriteLetters.sorted(), id: \.id) { favorite in
                        ArabicLetterRow(letterData: favorite)
                    }
                    .onDelete(perform: removeLetters)
                }
            }
            
            Section {
                if !isListEmpty {
                    Button("Delete All") {
                        deleteAll()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle(titleForFavoriteType(type))
        .toolbar {
            EditButton()
        }
        .environment(\.editMode, $editMode)
    }

    private var isListEmpty: Bool {
        switch type {
        case .surah: return settings.favoriteSurahs.isEmpty
        case .ayah: return settings.bookmarkedAyahs.isEmpty
        case .letter: return settings.favoriteLetters.isEmpty
        }
    }

    private func deleteAll() {
        switch type {
        case .surah:
            settings.favoriteSurahs.removeAll()
        case .ayah:
            settings.bookmarkedAyahs.removeAll()
        case .letter:
            settings.favoriteLetters.removeAll()
        }
    }
    
    private func removeSurahs(at offsets: IndexSet) {
        settings.favoriteSurahs.remove(atOffsets: offsets)
    }

    private func removeAyahs(at offsets: IndexSet) {
        settings.bookmarkedAyahs.remove(atOffsets: offsets)
    }

    private func removeLetters(at offsets: IndexSet) {
        settings.favoriteLetters.remove(atOffsets: offsets)
    }
    
    private func titleForFavoriteType(_ type: FavoriteType) -> String {
        switch type {
        case .surah:
            return "Favorite Surahs"
        case .ayah:
            return "Bookmarked Ayahs"
        case .letter:
            return "Favorite Letters"
        }
    }
}
#endif
