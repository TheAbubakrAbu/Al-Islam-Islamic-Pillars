import SwiftUI

struct IslamView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var namesData: NamesViewModel

    var body: some View {
        navigationContainer
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NavigationSplitView {
                        islamList
                    } detail: {
                        ArabicView()
                    }
                } else {
                    NavigationStack {
                        islamList
                    }
                }
            } else {
                NavigationView {
                    islamList
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                islamList
            }
            #endif
        }
    }

    private var islamList: some View {
        List {
            resourcesSection
            ProphetQuote()
            AlIslamAppsSection()
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Al-Islam")
    }

    private var resourcesSection: some View {
        Section(header: Text("ISLAMIC RESOURCES")) {
            resourceLink(title: "Arabic Alphabet", systemImage: "textformat.size.ar") {
                ArabicView()
            }

            resourceLink(title: "Tajweed Foundations", systemImage: "waveform") {
                TajweedFoundationsView()
            }

            resourceLink(title: "Common Adhkar", systemImage: "book.closed") {
                AdhkarView()
            }

            resourceLink(title: "Common Duas", systemImage: "text.book.closed") {
                DuaView()
            }

            resourceLink(title: "Tasbih Counter", systemImage: "circles.hexagonpath.fill") {
                TasbihView()
            }

            resourceLink(title: "99 Names of Allah", systemImage: "signature") {
                NamesView()
            }

            #if !os(watchOS)
            resourceLink(title: "Hijri Calendar Converter", systemImage: "calendar") {
                DateView()
            }

            resourceLink(title: "Masjid Locator", systemImage: "mappin.and.ellipse") {
                MasjidLocatorView()
            }
            #endif

            resourceLink(title: "Islamic Wallpapers", systemImage: "photo.on.rectangle") {
                WallpaperView()
            }

            resourceLink(title: "Islamic Pillars and Basics", systemImage: "moon.stars") {
                PillarsView()
            }
        }
    }

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            toolLabel(title, systemImage: systemImage)
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

    private let quoteText = "“All mankind is from Adam and Eve, an Arab has no superiority over a non-Arab nor a non-Arab has any superiority over an Arab; also a white has no superiority over a black, nor a black has any superiority over a white except by piety and good action.“"
    private let attributionText = "Farewell Sermon\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"

    var body: some View {
        Section(header: Text("PROPHET MUHAMMAD ﷺ QUOTE")) {
            VStack(alignment: .center) {
                quoteBadge
                quoteBody
                attribution
            }
        }
        #if !os(watchOS)
        .contextMenu {
            Button {
                UIPasteboard.general.string = "All mankind is from Adam and Eve, an Arab has no superiority over a non-Arab nor a non-Arab has any superiority over an Arab; also a white has no superiority over a black, nor a black has any superiority over a white except by piety and good action.\n\n– Farewell Sermon\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        }
        #endif
    }

    private var quoteBadge: some View {
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
    }

    private var quoteBody: some View {
        Text(quoteText)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundColor(settings.accentColor.color)
    }

    private var attribution: some View {
        Text(attributionText)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 1)
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
                cardBackground
                appCardsRow
            }
        }
    }

    private var cardBackground: some View {
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
            .padding(.vertical, alIslamAppsCardBackgroundVerticalPadding)
            #endif
    }

    #if !os(watchOS)
    private var alIslamAppsCardBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    private var appCardsRow: some View {
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

private struct Card: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.openURL) private var openURL
    @State private var showActions = false

    let title: String
    let url: URL

    private var iconImage: UIImage? {
        UIImage(named: title)
    }

    var body: some View {
        Button {
            settings.hapticFeedback()
            openURL(url)
        } label: {
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
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                settings.hapticFeedback()
                showActions = true
            }
        )
        #if !os(watchOS)
        .confirmationDialog(title, isPresented: $showActions, titleVisibility: .visible) {
            Button {
                UIPasteboard.general.string = url.absoluteString
                settings.hapticFeedback()
            } label: {
                Label("Copy Link", systemImage: "link")
            }

            if iconImage != nil {
                Button {
                    if let iconImage {
                        UIPasteboard.general.image = iconImage
                        settings.hapticFeedback()
                    }
                } label: {
                    Label("Copy Icon", systemImage: "doc.on.doc")
                }
            }

            Button("Cancel", role: .cancel) { }
        }
        #endif
    }
}
