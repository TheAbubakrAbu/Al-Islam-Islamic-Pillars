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
                .font(.subheadline)
                .onTapGesture {
                    settings.hapticFeedback()
                    settings.toggleLetterFavorite(letterData: letterData)
                }
        }
    }
}

struct ArabicView: View {
    @EnvironmentObject var settings: Settings
    
    @State private var searchText = ""
    @AppStorage("groupingType") private var groupingType: String = "normal"
    
    let similarityGroups: [[String]] = [
        ["ا", "و", "ي"],
        ["ب", "ت", "ث"],
        ["ج", "ح", "خ"],
        ["د", "ذ"],
        ["ر", "ز"],
        ["س", "ش"],
        ["ص", "ض"],
        ["ط", "ظ"],
        ["ع", "غ"],
        ["ف", "ق"],
        ["ك", "ل"],
        ["م", "ن"],
        ["ه", "ة"]
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if searchText.isEmpty {
                        if !settings.favoriteLetters.isEmpty {
                            Section(header: Text("FAVORITE LETTERS")) {
                                ForEach(settings.favoriteLetters.sorted(), id: \.id) { favorite in
                                    ArabicLetterRow(letterData: favorite)
                                }
                            }
                        }
                        
                        if groupingType == "normal" {
                            Section(header: Text("STANDARD ARABIC LETTERS")) {
                                ForEach(standardArabicLetters, id: \.letter) { letterData in
                                    ArabicLetterRow(letterData: letterData)
                                }
                            }
                        } else {
                            ForEach(similarityGroups.indices, id: \.self) { index in
                                let group = similarityGroups[index]
                                let groupLettersString = group.joined(separator: " AND ")
                                
                                Section(header: Text(index == 0 ? "VOWEL LETTERS" : groupLettersString)) {
                                    ForEach(group, id: \.self) { letter in
                                        if let letterData = standardArabicLetters.first(where: { $0.letter == letter }) {
                                            ArabicLetterRow(letterData: letterData)
                                        } else if let letterData = otherArabicLetters.first(where: { $0.letter == letter }) {
                                            ArabicLetterRow(letterData: letterData)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("SPECIAL ARABIC LETTERS")) {
                            ForEach(otherArabicLetters, id: \.letter) { letterData in
                                ArabicLetterRow(letterData: letterData)
                            }
                        }
                        
                        Section(header: Text("ARABIC NUMBERS")) {
                            ForEach(numbers, id: \.number) { numberData in
                                ArabicNumberRow(numberData: numberData)
                            }
                        }
                        
                        Section(header: Text("QURAN SIGNS")) {
                            StopInfoRow(title: "Make Sujood (Prostration)", symbol: "۩", color: settings.accentColor.color)
                            StopInfoRow(title: "The Mandatory Stop", symbol: "مـ", color: settings.accentColor.color)
                            StopInfoRow(title: "The Preferred Stop", symbol: "قلى", color: settings.accentColor.color)
                            StopInfoRow(title: "The Permissible Stop", symbol: "ج", color: settings.accentColor.color)
                            StopInfoRow(title: "The Short Pause", symbol: "س", color: settings.accentColor.color)
                            StopInfoRow(title: "Stop at One", symbol: "∴ ∴", color: settings.accentColor.color)
                            StopInfoRow(title: "The Preferred Continuation", symbol: "صلى", color: settings.accentColor.color)
                            StopInfoRow(title: "The Mandatory Continuation", symbol: "لا", color: settings.accentColor.color)
                            
                            Link("View More: Tajweed Rules & Stopping/Pausing Signs",
                                 destination: URL(string: "https://studioarabiya.com/blog/tajweed-rules-stopping-pausing-signs/")!)
                                .font(.subheadline)
                                .foregroundColor(settings.accentColor.color)
                        }
                    } else {
                        Section(header: Text("SEARCH RESULTS")) {
                            ForEach(standardArabicLetters.filter { letterData in
                                let st = searchText.lowercased()
                                return st.isEmpty ||
                                letterData.letter.lowercased().contains(st) ||
                                letterData.name.lowercased().contains(st) ||
                                letterData.transliteration.lowercased().contains(st)
                            }) { letterData in
                                ArabicLetterRow(letterData: letterData)
                            }
                            
                            ForEach(otherArabicLetters.filter { letterData in
                                let st = searchText.lowercased()
                                return st.isEmpty ||
                                letterData.letter.lowercased().contains(st) ||
                                letterData.name.lowercased().contains(st) ||
                                letterData.transliteration.lowercased().contains(st)
                            }) { letterData in
                                ArabicLetterRow(letterData: letterData)
                            }
                        }
                    }
                }
                #if os(watchOS)
                .searchable(text: $searchText)
                #else
                .applyConditionalListStyle(defaultView: true)
                .dismissKeyboardOnScroll()
                #endif
                
                #if !os(watchOS)
                Picker("Grouping", selection: $groupingType.animation(.easeInOut)) {
                    Text("Normal Grouping").tag("normal")
                    Text("Group by Similarity").tag("similarity")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                SearchBar(text: $searchText.animation(.easeInOut))
                    .padding(.horizontal, 8)
                #endif
            }
            .navigationTitle("Arabic Alphabet")
            
            if !settings.favoriteLetters.isEmpty {
                let sortedFavorites = settings.favoriteLetters.sorted()
                let letter = sortedFavorites[0]
                ArabicLetterView(letterData: letter)
            } else {
                ArabicLetterView(letterData: standardArabicLetters[0])
            }
        }
    }
}

struct ArabicLetterRow: View {
    @EnvironmentObject var settings: Settings
    let letterData: LetterData
    
    var body: some View {
        VStack {
            NavigationLink(destination: ArabicLetterView(letterData: letterData)) {
                HStack {
                    Text(letterData.transliteration)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(letterData.letter)
                        .font(settings.useFontArabic ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize) : .title2)
                        .foregroundColor(settings.accentColor.color)
                }
                .padding(.vertical, -2)
                #if !os(watchOS)
                .swipeActions(edge: .leading) {
                    Button(action: {
                        settings.hapticFeedback()
                        
                        settings.toggleLetterFavorite(letterData: letterData)
                    }) {
                        Image(systemName: settings.isLetterFavorite(letterData: letterData) ? "star.fill" : "star")
                    }
                    .tint(settings.accentColor.color)
                }
                .swipeActions(edge: .trailing) {
                    Button(action: {
                        settings.hapticFeedback()
                        
                        settings.toggleLetterFavorite(letterData: letterData)
                    }) {
                        Image(systemName: settings.isLetterFavorite(letterData: letterData) ? "star.fill" : "star")
                    }
                    .tint(settings.accentColor.color)
                }

                .contextMenu {
                    Button(role: settings.isLetterFavorite(letterData: letterData) ? .destructive : nil, action: {
                        settings.hapticFeedback()
                        settings.toggleLetterFavorite(letterData: letterData)
                    }) {
                        Label(settings.isLetterFavorite(letterData: letterData) ? "Unfavorite Letter" : "Favorite Letter", systemImage: settings.isLetterFavorite(letterData: letterData) ? "star.fill" : "star")
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = letterData.letter
                        settings.hapticFeedback()
                    }) {
                        Label("Copy Letter", systemImage: "doc.on.doc")
                    }
                        
                    Button(action: {
                        UIPasteboard.general.string = letterData.transliteration
                        settings.hapticFeedback()
                    }) {
                        Label("Copy Transliteration", systemImage: "doc.on.doc")
                    }
                }
                #endif
            }
        }
    }
}

struct ArabicNumberRow: View {
    @EnvironmentObject var settings: Settings
    let numberData: (number: String, name: String, transliteration: String, englishNumber: String)
    
    var body: some View {
        HStack {
            Text(numberData.englishNumber)
                .font(.title3)
            
            Spacer()
            
            VStack(alignment: .center) {
                Text(numberData.name)
                    .font(settings.useFontArabic ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize) : .subheadline)
                    .foregroundColor(settings.accentColor.color)
                
                Text(numberData.transliteration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(numberData.number)
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

struct StopInfoRow: View {
    let title: String
    let symbol: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(symbol)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}
