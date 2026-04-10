import SwiftUI

struct IslamView: View {
    @EnvironmentObject var settings: Settings
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
        //.navigationTitle("Tools")
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

            #if os(iOS)
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
    @State private var isCardVisible = false
    @State private var animateBadge = false

    private let quoteText = "“O people, your Lord is one and your father Adam is one. There is no superiority of an Arab over a non-Arab, nor a non-Arab over an Arab, and neither a white over a black, nor a black over a white, except by righteousness.“"
    private let attributionText1 = "Farewell Sermon\nMusnad Ahmad 22978"
    private let attributionText2 = "Jumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"

    var body: some View {
        Section(header: Text("PROPHET MUHAMMAD ﷺ QUOTE")) {
            ZStack {
                quoteCardBackground

                VStack(alignment: .center, spacing: 12) {
                    quoteBadge
                    quoteBody
                    attribution
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .conditionalGlassEffect(rectangle: true, useColor: 0.16)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 2)
            .scaleEffect(isCardVisible ? 1 : 0.97)
            .opacity(isCardVisible ? 1 : 0.75)
            .offset(y: isCardVisible ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isCardVisible)
            .onAppear {
                isCardVisible = true
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    animateBadge = true
                }
            }
            .onDisappear {
                withAnimation {
                    isCardVisible = false
                    animateBadge = false
                }
            }
        }
        #if os(iOS)
        .contextMenu {
            Button {
                UIPasteboard.general.string = "O people, your Lord is one and your father Adam is one. There is no superiority of an Arab over a non-Arab, nor a non-Arab over an Arab, and neither a white over a black, nor a black over a white, except by righteousness.\n\n– Farewell Sermon\nMusnad Ahmad 22978\n\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        }
        #endif
    }

    private var quoteCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        settings.accentColor.color.opacity(0.18),
                        Color.secondary.opacity(0.08),
                        settings.accentColor.color.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(settings.accentColor.color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: settings.accentColor.color.opacity(0.12), radius: 10, x: 0, y: 3)
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
                .clipShape(Circle())
        }
        .conditionalGlassEffect(circle: true)
        .scaleEffect(animateBadge ? 1.04 : 0.98)
        .padding(4)
    }

    private var quoteBody: some View {
        Text(quoteText)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundColor(settings.accentColor.color)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 2)
    }

    private var attribution: some View {
        VStack(spacing: 10) {
            Text(attributionText1)
                .foregroundColor(.primary)
                .font(.caption)
            
            Text(attributionText2)
                .foregroundColor(.secondary)
                .font(.caption2)
        }
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }
}

struct AlIslamAppsSection: View {
    @EnvironmentObject var settings: Settings
    #if os(iOS)
    @State private var showLearnMoreSheet = false
    #endif
    @State private var popLeft = false
    @State private var popCenter = false
    @State private var popRight = false

    #if os(iOS)
    let spacing: CGFloat = 20
    #else
    let spacing: CGFloat = 10
    #endif

    var body: some View {
        Section(header: Text("AL-ISLAMIC APPS")) {
            ZStack {
                cardBackground
                
                VStack(spacing: 10) {
                    appCardsRow
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    #if os(iOS)
                    Button {
                        settings.hapticFeedback()
                        showLearnMoreSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles.rectangle.stack")
                            Text("Learn More")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .contentShape(Rectangle())
                    .conditionalGlassEffect()
                    .padding([.horizontal, .bottom], 8)
                    #endif
                }
            }
            .conditionalGlassEffect(rectangle: true)
            .onAppear(perform: runAppCardsPopAnimation)
            .onDisappear {
                withAnimation {
                    popLeft = false
                    popCenter = false
                    popRight = false
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showLearnMoreSheet) {
                SplashScreen()
            }
            #endif
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
    }

    #if os(iOS)
    private var alIslamAppsCardBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    private var appCardsRow: some View {
        HStack(spacing: spacing) {
            if let url = URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493?platform=iphone") {
                Card(title: "Al-Adhan", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popLeft ? 1 : 0.2)
                    .offset(y: popLeft ? 0 : 80)
                    .opacity(popLeft ? 1 : 0.35)
                    .rotationEffect(.degrees(-6))
            }

            if let url = URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone") {
                Card(title: "Al-Islam", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popCenter ? 1.02 : 0.24)
                    .offset(y: popCenter ? 0 : 86)
                    .opacity(popCenter ? 1 : 0.4)
            }

            if let url = URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373?platform=iphone") {
                Card(title: "Al-Quran", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popRight ? 1 : 0.2)
                    .offset(y: popRight ? 0 : 80)
                    .opacity(popRight ? 1 : 0.35)
                    .rotationEffect(.degrees(6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .padding(.horizontal)
    }

    private var popSpring: Animation {
        .spring(response: 0.52, dampingFraction: 0.62, blendDuration: 0)
    }

    private func runAppCardsPopAnimation() {
        popLeft = false
        popCenter = false
        popRight = false

        withAnimation(popSpring) {
            popCenter = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(popSpring) {
                popLeft = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(popSpring) {
                popRight = true
            }
        }
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
        VStack {
            Image(title)
                .resizable()
                .scaledToFit()
                .cornerRadius(18)
                .shadow(radius: 4)

            #if os(iOS)
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
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                settings.hapticFeedback()
                openURL(url)
            }
        }
        #if os(iOS)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                settings.hapticFeedback()
                showActions = true
            }
        )
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

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        IslamView()
    }
}
