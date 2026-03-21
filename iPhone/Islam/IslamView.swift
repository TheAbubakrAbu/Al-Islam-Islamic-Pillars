import SwiftUI

struct IslamView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var namesData: NamesViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("ISLAMIC RESOURCES")) {
                    NavigationLink(destination: ArabicView()) {
                        toolLabel("Arabic Alphabet", systemImage: "textformat.size.ar")
                    }

                    NavigationLink(destination: TajweedFoundationsView()) {
                        toolLabel("Tajweed Foundations", systemImage: "waveform")
                    }

                    NavigationLink(destination: AdhkarView()) {
                        toolLabel("Common Adhkar", systemImage: "book.closed")
                    }

                    NavigationLink(destination: DuaView()) {
                        toolLabel("Common Duas", systemImage: "text.book.closed")
                    }

                    NavigationLink(destination: TasbihView()) {
                        toolLabel("Tasbih Counter", systemImage: "circles.hexagonpath.fill")
                    }

                    NavigationLink(destination: NamesView()) {
                        toolLabel("99 Names of Allah", systemImage: "signature")
                    }

                    #if !os(watchOS)
                    NavigationLink(destination: DateView()) {
                        toolLabel("Hijri Calendar Converter", systemImage: "calendar")
                    }

                    NavigationLink(destination: MasjidLocatorView()) {
                        toolLabel("Masjid Locator", systemImage: "mappin.and.ellipse")
                    }
                    #endif

                    NavigationLink(destination: WallpaperView()) {
                        toolLabel("Islamic Wallpapers", systemImage: "photo.on.rectangle")
                    }

                    NavigationLink(destination: PillarsView()) {
                        toolLabel("Islamic Pillars and Basics", systemImage: "moon.stars")
                    }
                }
                
                ProphetQuote()
                
                AlIslamAppsSection()
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .navigationTitle("Al-Islam")
            
            ArabicView()
        }
    }
    
    private func toolLabel(_ title: String, systemImage: String) -> some View {
        Label(
            title: { Text(title) },
            icon: {
                Image(systemName: systemImage)
                    .foregroundColor(settings.accentColor.color)
            }
        )
        .padding(.vertical, 4)
        .accentColor(settings.accentColor.color)
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
                
                Text("Farewell Sermon\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 1)
            }
        }
        #if !os(watchOS)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = "All mankind is from Adam and Eve, an Arab has no superiority over a non-Arab nor a non-Arab has any superiority over an Arab; also a white has no superiority over a black, nor a black has any superiority over a white except by piety and good action.\n\n– Farewell Sermon\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"
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
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow.opacity(0.25), .green.opacity(0.25)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .primary.opacity(0.25), radius: 5, x: 0, y: 1)
                    .padding(.horizontal, -12)
                    #if !os(watchOS)
                    .padding(.vertical, -11)
                    #endif
                
                HStack(spacing: spacing) {
                    if let url = URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493") {
                        Card(title: "Al-Adhan", url: url)
                            .frame(maxWidth: .infinity)
                    }
                    
                    if let url = URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655") {
                        Card(title: "Al-Islam", url: url)
                            .frame(maxWidth: .infinity)
                    }
                    
                    if let url = URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373") {
                        Card(title: "Al-Quran", url: url)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
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

    private var iconImage: UIImage? {
        UIImage(named: title)
    }

    private func saveIconToPhotos() {
        guard let iconImage else { return }

        #if !os(watchOS)
        UIImageWriteToSavedPhotosAlbum(iconImage, nil, nil, nil)
        #endif
    }

    var body: some View {
        VStack {
            Image(title)
                .resizable()
                .scaledToFit()
                .cornerRadius(18)
                .shadow(radius: 4)

            #if !os(watchOS)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 4)
            #endif
        }
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            settings.hapticFeedback()
            openURL(url)
        }
        #if !os(watchOS)
        .contextMenu {
            Button {
                UIPasteboard.general.string = url.absoluteString
                settings.hapticFeedback()
            } label: {
                Label("Copy Link", systemImage: "link")
            }

            if iconImage != nil {
                Button {
                    saveIconToPhotos()
                    settings.hapticFeedback()
                } label: {
                    Label("Download App Icon", systemImage: "square.and.arrow.down")
                }
            }
        }
        #endif
    }
}

#Preview {
    IslamView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
