import SwiftUI

struct SurahsHeader: View {
    @EnvironmentObject var quranData: QuranData

    @State private var randomSurah: Surah?

    var body: some View {
        HStack {
            Text("SURAHS")

            #if os(iOS)
            Spacer()
            
            randomSurahLink
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                randomSurah = quranData.quran.randomElement()
            }
        }
    }

    #if os(iOS)
    private var randomSurahLink: some View {
        NavigationLink {
            Group {
                if let randomSurah {
                    AyahsView(surah: randomSurah)
                } else {
                    Text("No surah found!")
                }
            }
            .onDisappear {
                randomSurah = quranData.quran.randomElement()
            }
        } label: {
            Image(systemName: "shuffle.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
    }
    #endif
}

struct JuzHeader: View {
    @EnvironmentObject var quranData: QuranData

    let juz: Juz

    @State private var randomSurah: Surah?

    var body: some View {
        HStack {
            Text("JUZ \(juz.id)")
                .lineLimit(1)

            Text("- \(juz.nameTransliteration.uppercased()) - \(juz.nameArabic)")
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            #if os(iOS)
            Spacer()
            
            randomSurahLink
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                randomSurah = randomSurahInJuz
            }
        }
    }

    private var surahsInRange: [Surah] {
        quranData.quran.filter { $0.id >= juz.startSurah && $0.id <= juz.endSurah }
    }

    private var randomSurahInJuz: Surah? {
        surahsInRange.randomElement()
    }

    #if os(iOS)
    private var randomSurahLink: some View {
        NavigationLink {
            Group {
                if let randomSurah {
                    AyahsView(surah: randomSurah)
                } else {
                    Text("No surah found in Juz \(juz.id).")
                }
            }
            .onDisappear {
                randomSurah = randomSurahInJuz
            }
        } label: {
            Image(systemName: "shuffle.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
    }
    #endif
}

struct PageHeader: View {
    let page: Int

    var body: some View {
        HStack {
            Text("PAGE \(page)")
                .lineLimit(1)

            Spacer()
        }
    }
}

struct SurahSectionHeader: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer

    var surah: Surah
    var compact: Bool = false

    var body: some View {
        HStack {
            ayahSummary

            Spacer()

            #if os(watchOS)
            watchPlaybackButton
            #endif

            favoriteToggle
        }
    }

    private var ayahSummary: some View {
        Group {
            let revelationEmoji = surah.type == "meccan" ? "🕋" : "🕌"
            
            #if os(iOS)
            Text("\(surah.ayahCountLabel(for: settings.displayQiraahForArabic)) - \(surah.pageCountLabel) \(revelationEmoji)")
            #else
            Text("\(surah.ayahCountLabel(for: settings.displayQiraahForArabic)) - \(surah.pageCountLabel) \(revelationEmoji)")
            #endif
        }
        .textCase(.uppercase)
        .font(compact ? .caption.weight(.semibold) : .subheadline)
        .lineLimit(1)
        .minimumScaleFactor(compact ? 0.6 : 0.25)
    }
    #if os(watchOS)
    private var watchPlaybackButton: some View {
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
            } else if quranPlayer.isPlaying {
                quranPlayer.pause(saveInfo: false)
            } else {
                quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
            }
        }
    }
    #endif

    private var favoriteToggle: some View {
        Image(systemName: settings.isSurahFavorite(surah: surah.id) ? "star.fill" : "star")
            .foregroundColor(settings.accentColor.color)
            #if os(iOS)
            .font(compact ? .caption : .subheadline)
            #else
            .font(.title3)
            #endif
            .onTapGesture {
                settings.hapticFeedback()
                settings.toggleSurahFavorite(surah: surah.id)
            }
    }
}

struct HeaderRow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranPlayer: QuranPlayer

    let arabicText: String
    let englishTransliteration: String
    let englishTranslation: String

    @State private var ayahBeginnerMode = false

    var body: some View {
        VStack(alignment: .center) {
            Text(displayArabicText)
                .font(.custom(settings.fontArabic, size: settings.fontArabicSize))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)

            if settings.showTransliteration, settings.isHafsDisplay {
                Text(englishTransliteration)
                    .font(.system(size: settings.englishFontSize))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }

            if (settings.showEnglishSaheeh || settings.showEnglishMustafa), settings.isHafsDisplay {
                Text(englishTranslation)
                    .font(.system(size: settings.englishFontSize))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .foregroundColor(settings.accentColor.color)
        .padding(.top, -4)
        #if os(iOS)
        .contextMenu {
            if !settings.beginnerMode {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                } label: {
                    Label("Beginner Mode", systemImage: ayahBeginnerMode ? "textformat.size.larger.ar" : "textformat.size.ar")
                }
            }

            if englishTranslation.contains("name"), settings.isHafsDisplay {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playBismillah()
                } label: {
                    Label("Play Ayah", systemImage: "play.circle")
                }
            }
        }
        #endif
    }

    private var displayArabicText: String {
        let cleanedText = settings.cleanArabicText ? arabicText.removingArabicDiacriticsAndSigns : arabicText
        if settings.beginnerMode || ayahBeginnerMode {
            return cleanedText.map { "\($0) " }.joined()
        }
        return cleanedText
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            SurahSectionHeader(surah: AlIslamPreviewData.surah)
        }
    }
}
