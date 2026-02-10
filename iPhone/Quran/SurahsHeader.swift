import SwiftUI

struct SurahsHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    
    @State private var randomSurah: Surah?
        
    var body: some View {
        HStack {
            Text("SURAHS")
            
            #if !os(watchOS)
            Spacer()
            
            NavigationLink {
                Group {
                    if let randomS = randomSurah {
                        AyahsView(surah: randomS)
                    } else {
                        Text("No surah found!")
                    }
                }
                .onDisappear {
                    randomSurah = quranData.quran.randomElement()
                }
            } label: {
                Image(systemName: "shuffle")
            }
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                randomSurah = quranData.quran.randomElement()
            }
        }
    }
}

struct JuzHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    let juz: Juz
    
    @State private var randomSurah: Surah?

    private func getRandomSurah() -> Surah? {
        let surahsInRange = quranData.quran.filter {
            $0.id >= juz.startSurah && $0.id <= juz.endSurah
        }
        return surahsInRange.randomElement()
    }
    
    var body: some View {
        HStack {
            Text("JUZ \(juz.id) - \(juz.nameTransliteration.uppercased())")
            
            #if !os(watchOS)
            Spacer()
            
            NavigationLink {
                Group {
                    if let randomS = randomSurah {
                        AyahsView(surah: randomS)
                    } else {
                        Text("No surah found in Juz \(juz.id).")
                    }
                }
                .onDisappear {
                    if let randomS = getRandomSurah() {
                        randomSurah = randomS
                    }
                }
            } label: {
                Image(systemName: "shuffle")
            }
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                if let randomS = getRandomSurah() {
                    randomSurah = randomS
                }
            }
        }
    }
}

struct SurahSectionHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    var surah: Surah
    
    var body: some View {
        HStack {
            Group {
                #if !os(watchOS)
                Text("\(surah.numberOfAyahs(for: settings.displayQiraahForArabic)) Ayahs - \(surah.type) \(surah.type == "meccan" ? "🕋" : "🕌")")
                #else
                Text("\(surah.numberOfAyahs(for: settings.displayQiraahForArabic)) Ayahs - \(surah.type == "meccan" ? "🕋" : "🕌")")
                #endif
            }
            .textCase(.uppercase)
            .font(.subheadline)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            
            Spacer()
            
            #if os(watchOS)
            Group {
                if quranPlayer.isLoading {
                    RotatingGearView()
                        .transition(.opacity)
                } else if quranPlayer.isPlaying {
                    Image(systemName: "pause.fill")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                        .transition(.opacity)
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                        .transition(.opacity)
                }
            }
            .onTapGesture {
                settings.hapticFeedback()
                
                if quranPlayer.isLoading {
                    quranPlayer.isLoading = false
                    quranPlayer.player?.pause()
                } else {
                    if quranPlayer.isPlaying {
                        quranPlayer.pause(saveInfo: false)
                    } else {
                        quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                    }
                }
            }
            #endif
            
            Image(systemName: settings.isSurahFavorite(surah: surah.id) ? "star.fill" : "star")
                .foregroundColor(settings.accentColor.color)
                #if !os(watchOS)
                .font(.subheadline)
                #else
                .font(.title3)
                #endif
                .onTapGesture {
                    settings.hapticFeedback()

                    settings.toggleSurahFavorite(surah: surah.id)
                }
        }
    }
}

struct HeaderRow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer

    let arabicText: String
    let englishTransliteration: String
    let englishTranslation: String
    
    @State private var ayahBeginnerMode: Bool = false
    
    func arabicTextWithSpacesIfNeeded(_ text: String) -> String {
        if settings.beginnerMode || ayahBeginnerMode {
            return text.map { "\($0) " }.joined()
        }
        return text
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text(arabicTextWithSpacesIfNeeded(settings.cleanArabicText ? arabicText.removingArabicDiacriticsAndSigns : arabicText))
                .foregroundColor(settings.accentColor.color)
                .font(.custom(settings.fontArabic, size: settings.fontArabicSize))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)

            if settings.showTransliteration, settings.isHafsDisplay {
                Text(englishTransliteration)
                    .foregroundColor(settings.accentColor.color)
                    .font(.system(size: settings.englishFontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }

            if (settings.showEnglishSaheeh || settings.showEnglishMustafa), settings.isHafsDisplay {
                Text(englishTranslation)
                    .foregroundColor(settings.accentColor.color)
                    .font(.system(size: settings.englishFontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .padding(.top, -4)
        #if !os(watchOS)
        .contextMenu {
            if !settings.beginnerMode {
                Button(action: {
                    settings.hapticFeedback()
                    
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                }) {
                    Label("Beginner Mode", systemImage: ayahBeginnerMode ? "textformat.size.larger.ar" : "textformat.size.ar")
                }
            }
            
            if englishTranslation.contains("name"), settings.isHafsDisplay {
                Button(action: {
                    settings.hapticFeedback()
                    
                    quranPlayer.playBismillah()
                }) {
                    Label("Play Ayah", systemImage: "play.circle")
                }
            }
        }
        #endif
    }
}

#Preview {
    QuranView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
