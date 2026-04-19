import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    
    @State private var showingCredits = false
    @State private var selectedDestination: SettingsDestination? = .quranSettings
    @State private var hasSetDefaultSelection = false

    private enum SettingsDestination: Hashable {
        case notification
        case manualOffsets
        case prayerSettings
        case quranSettings
    }

    var body: some View {
        navigationContainer
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NavigationSplitView {
                        settingsSplitList
                            .onAppear {
                                if !hasSetDefaultSelection {
                                    selectedDestination = .quranSettings
                                    hasSetDefaultSelection = true
                                }
                            }
                    } detail: {
                        settingsSplitDetail
                            .animation(.easeInOut(duration: 0.25), value: selectedDestination)
                    }
                } else {
                    NavigationStack {
                        settingsList
                    }
                }
            } else {
                NavigationView {
                    settingsList
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                settingsList
            }
            .navigationViewStyle(.stack)
            #endif
        }
    }

    private var settingsList: some View {
        List {
            notificationSection
            manualOffsetsSection
            adhanSection
            quranSection
            appearanceSection
            creditsSection
            
            AlIslamAppsSection()
        }
        .navigationTitle("Settings")
        .applyConditionalListStyle(defaultView: true)
    }

    #if os(iOS)
    @available(iOS 16.0, *)
    private var settingsSplitList: some View {
        List(selection: $selectedDestination) {
            notificationSectionSplit
            manualOffsetsSectionSplit
            adhanSectionSplit
            quranSectionSplit
            appearanceSection
            creditsSection
            AlIslamAppsSection()
        }
        .navigationTitle("Settings")
        .applyConditionalListStyle(defaultView: true)
    }

    @ViewBuilder
    private var settingsSplitDetail: some View {
        switch selectedDestination ?? .quranSettings {
        case .notification:
            NotificationView()
        case .manualOffsets:
            manualOffsetDestination
        case .prayerSettings:
            SettingsAdhanView(showNotifications: false)
        case .quranSettings:
            SettingsQuranView(showEdits: true)
        }
    }
    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            toolLabel(title, systemImage: systemImage)
        }
        .tint(settings.accentColor.color)
    }

    private func toolLabel(_ title: String, systemImage: String) -> some View {
        Label(
            title: {
                Text(title)
                    .foregroundColor(.primary)
            },
            icon: {
                Image(systemName: systemImage)
                    .foregroundColor(settings.accentColor.color)
            }
        )
        .padding(.vertical, 4)
    }

    @available(iOS 16.0, *)
    private func splitResourceLink(
        title: String,
        systemImage: String,
        value: SettingsDestination
    ) -> some View {
        NavigationLink(value: value) {
            toolLabel(title, systemImage: systemImage)
        }
        .tint(settings.accentColor.color)
    }

    @ViewBuilder
    private var notificationSection: some View {
        #if os(iOS)
        Section(header: Text("NOTIFICATIONS")) {
            resourceLink(title: "Notification Settings", systemImage: "bell.badge") {
                NotificationView()
            }
        }
        #endif
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private var notificationSectionSplit: some View {
        Section(header: Text("NOTIFICATIONS")) {
            splitResourceLink(title: "Notification Settings", systemImage: "bell.badge", value: .notification)
        }
    }

    @ViewBuilder
    private var manualOffsetsSection: some View {
        #if os(iOS)
        Section(header: Text("MANUAL OFFSETS")) {
            resourceLink(title: "Manual Offset Settings", systemImage: "slider.horizontal.3") {
                manualOffsetDestination
            }
        }
        #endif
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private var manualOffsetsSectionSplit: some View {
        Section(header: Text("MANUAL OFFSETS")) {
            splitResourceLink(title: "Manual Offset Settings", systemImage: "slider.horizontal.3", value: .manualOffsets)
        }
    }

    private var manualOffsetDestination: some View {
        List {
            Section(header: Text("HIJRI OFFSET")) {
                Stepper(value: $settings.hijriOffset, in: -3...3) {
                    HStack {
                        Text("Hijri Offset:")
                            .foregroundColor(.primary)
                        
                        Text("\(settings.hijriOffset) days")
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .font(.subheadline)

                if let hijriDate = settings.hijriDate {
                    HStack {
                        Text("English:")
                            .foregroundColor(.primary)
                        
                        Text(hijriDate.english)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .font(.subheadline)

                    HStack {
                        Text("Arabic: ")
                            .foregroundColor(.primary)
                        
                        Text(hijriDate.arabic)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .font(.subheadline)
                }
            }
            .onAppear {
                settings.fetchPrayerTimes()
            }

            PrayerOffsetsView()
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Manual Offset Settings")
    }

    private var adhanSection: some View {
        Section(header: Text("AL-ADHAN")) {
            resourceLink(title: "Prayer Settings", systemImage: "safari") {
                SettingsAdhanView(showNotifications: false)
            }
        }
    }

    @available(iOS 16.0, *)
    private var adhanSectionSplit: some View {
        Section(header: Text("AL-ADHAN")) {
            splitResourceLink(title: "Prayer Settings", systemImage: "safari", value: .prayerSettings)
        }
    }

    private var quranSection: some View {
        Section(header: Text("AL-QURAN")) {
            resourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar") {
                SettingsQuranView(showEdits: true)
            }
        }
    }

    @available(iOS 16.0, *)
    private var quranSectionSplit: some View {
        Section(header: Text("AL-QURAN")) {
            splitResourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar", value: .quranSettings)
        }
    }

    private var appearanceSection: some View {
        Section(header: Text("APPEARANCE")) {
            SettingsAppearanceView()
        }
    }

    private var creditsSection: some View {
        Section(header: Text("CREDITS")) {
            creditsIntro
            viewCreditsButton
            leaveReviewButton
            openAppSettingsButton
            websiteRow
            contactRow
            VersionNumber(width: glyphWidth)
                .font(.subheadline)
        }
    }

    private var creditsIntro: some View {
        Text("Made by Abubakr Elmallah, who was a 17-year-old high school student when this app was made.\n\nSpecial thanks to my parents and to Mr. Joe Silvey, my English teacher and Muslim Student Association Advisor.")
            .font(.footnote)
            .foregroundColor(.primary)
    }

    @ViewBuilder
    private var viewCreditsButton: some View {
        #if os(iOS)
        Button {
            settings.hapticFeedback()
            showingCredits = true
        } label: {
            Label("View Credits", systemImage: "scroll.fill")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
        }
        .sheet(isPresented: $showingCredits) {
            CreditsView()
        }
        #endif
    }

    @ViewBuilder
    private var leaveReviewButton: some View {
        #if os(iOS)
        Button {
            leaveReview()
        } label: {
            Label("Leave a Review", systemImage: "star.bubble.fill")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
        }
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = "itms-apps://itunes.apple.com/app/id6449729655?action=write-review"
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Website")
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private var openAppSettingsButton: some View {
        #if os(iOS)
        Button {
            settings.hapticFeedback()
            openAppSettings()
        } label: {
            Label("Open App Settings", systemImage: "gearshape.fill")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
        }
        #endif
    }

    private var websiteRow: some View {
        HStack {
            Text("Website: ")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(width: glyphWidth)

            if let url = URL(string: "https://abubakrelmallah.com/") {
                Link("abubakrelmallah.com", destination: url)
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, -4)
            }
        }
        #if os(iOS)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = "abubakrelmallah.com"
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Website")
                }
            }
        }
        #endif
    }

    private var contactRow: some View {
        HStack {
            Text("Contact: ")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(width: glyphWidth)

            Text("ammelmallah@icloud.com")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
                .multilineTextAlignment(.leading)
                .padding(.leading, -4)
        }
        #if os(iOS)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = "ammelmallah@icloud.com"
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Email")
                }
            }
        }
        #endif
    }

    #if os(iOS)
    private func leaveReview() {
        settings.hapticFeedback()

        withAnimation(.smooth()) {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6449729655?action=write-review") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func openAppSettings() {
        settings.hapticFeedback()

        withAnimation(.smooth()) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    #endif

    private func columnWidth(for textStyle: UIFont.TextStyle, extra: CGFloat = 4, sample: String? = nil, fontName: String? = nil) -> CGFloat {
        let sampleString = (sample ?? "M") as NSString
        let font: UIFont

        if let fontName = fontName, let customFont = UIFont(name: fontName, size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) {
            font = customFont
        } else {
            font = UIFont.preferredFont(forTextStyle: textStyle)
        }

        return ceil(sampleString.size(withAttributes: [.font: font]).width) + extra
    }

    private var glyphWidth: CGFloat {
        columnWidth(for: .subheadline, extra: 0, sample: "Contact: ")
    }
}

struct SettingsAppearanceView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        #if os(iOS)
        Picker("Color Theme", selection: $settings.colorSchemeString.animation(.easeInOut)) {
            Text("System").tag("system")
            Text("Light").tag("light")
            Text("Dark").tag("dark")
        }
        .font(.subheadline)
        .pickerStyle(SegmentedPickerStyle())
        #endif
        
        VStack(alignment: .leading) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(accentColors, id: \.self) { accentColor in
                    Circle()
                        .fill(accentColor.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(settings.accentColor == accentColor ? Color.primary : Color.clear, lineWidth: 1)
                        )
                        .onTapGesture {
                            settings.hapticFeedback()
                            
                            withAnimation {
                                settings.accentColor = accentColor
                            }
                        }
                }
            }
            .padding(.vertical)
            
            #if os(iOS)
            Text("Anas ibn Malik (may Allah be pleased with him) said, “The most beloved of colors to the Messenger of Allah (peace be upon him) was green.”")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            #endif
        }
        
        #if os(iOS)
        VStack(alignment: .leading) {
            Toggle("Default List View", isOn: $settings.defaultView.animation(.easeInOut))
                .font(.subheadline)
            
            Text("The default list view is the standard interface found in many of Apple's first party apps, including Notes. This setting applies everywhere in the app except here in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
        #endif
        
        VStack(alignment: .leading) {
            Toggle("Haptic Feedback", isOn: $settings.hapticOn.animation(.easeInOut))
                .font(.subheadline)
        }
    }
}

struct VersionNumber: View {
    @EnvironmentObject var settings: Settings
    
    var width: CGFloat?
    
    var body: some View {
        HStack {
            if let width = width {
                Text("Version:")
                    .frame(width: width)
            } else {
                Text("Version")
            }
            
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                .foregroundColor(settings.accentColor.color)
                .padding(.leading, -4)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SettingsView()
    }
}
