import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    
    @State private var showingCredits = false

    var body: some View {
        NavigationView {
            List {
                #if !os(watchOS)
                Section(header: Text("NOTIFICATIONS")) {
                    NavigationLink(destination: NotificationView()) {
                        Label("Notification Settings", systemImage: "bell.badge")
                    }
                    .accentColor(settings.accentColor.color)
                }
                
                Section(header: Text("MANUAL OFFSETS")) {
                    NavigationLink(destination: {
                        List {
                            Section(header: Text("HIJRI OFFSET")) {
                                Stepper("Hijri Offset: \(settings.hijriOffset) days", value: $settings.hijriOffset, in: -3...3)
                                    .font(.subheadline)
                                
                                if let hijriDate = settings.hijriDate {
                                    Text("English: \(hijriDate.english)")
                                        .foregroundColor(settings.accentColor.color)
                                        .font(.subheadline)
                                    
                                    Text("Arabic: \(hijriDate.arabic)")
                                        .foregroundColor(settings.accentColor.color)
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
                    }) {
                        Label("Manual Offset Settings", systemImage: "slider.horizontal.3")
                    }
                    .accentColor(settings.accentColor.color)
                }
                #endif
                
                Section(header: Text("AL-ADHAN")) {
                    NavigationLink(destination: SettingsPrayerView(showNotifications: false)) {
                        Label("Prayer Settings", systemImage: "safari")
                    }
                    .accentColor(settings.accentColor.color)
                }
                
                Section(header: Text("AL-QURAN")) {
                    NavigationLink(destination:
                        List {
                            SettingsQuranView(showEdits: true)
                                .environmentObject(quranData)
                                .environmentObject(settings)
                        }
                        .applyConditionalListStyle(defaultView: true)
                        .navigationTitle("Al-Quran Settings")
                    ) {
                        Label("Quran Settings", systemImage: "character.book.closed.ar")
                    }
                    .accentColor(settings.accentColor.color)
                }
                
                Section(header: Text("APPEARANCE")) {
                    SettingsAppearanceView()
                }
                
                Section(header: Text("CREDITS")) {
                    Text("Made by Abubakr Elmallah, who was a 17-year-old high school student when this app was made.\n\nSpecial thanks to my parents and to Mr. Joe Silvey, my English teacher and Muslim Student Association Advisor.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    #if !os(watchOS)
                    Button(action: {
                        settings.hapticFeedback()
                        
                        showingCredits = true
                    }) {
                        Label("View Credits", systemImage: "scroll.fill")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .sheet(isPresented: $showingCredits) {
                        CreditsView()
                    }
                    
                    Button(action: {
                        settings.hapticFeedback()
                        
                        withAnimation(.smooth()) {
                            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6449729655?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        Label("Leave a Review", systemImage: "star.bubble.fill")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .contextMenu {
                        Button(action: {
                            settings.hapticFeedback()
                            
                            UIPasteboard.general.string = "itms-apps://itunes.apple.com/app/id6449729655?action=write-review"
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Website")
                            }
                        }
                    }
                    
                    Button(action: {
                        settings.hapticFeedback()
                        
                        withAnimation(.smooth()) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }
                    }) {
                        Label("Open App Settings", systemImage: "gearshape.fill")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                    #endif
                    
                    HStack {
                        Text("Website: ")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .frame(width: glyphWidth)
                        
                        Link("abubakrelmallah.com", destination: URL(string: "https://abubakrelmallah.com/")!)
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, -4)
                    }
                    #if !os(watchOS)
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = "abubakrelmallah.com"
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Website")
                            }
                        }
                    }
                    #endif
                    
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
                    #if !os(watchOS)
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = "ammelmallah@icloud.com"
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Email")
                            }
                        }
                    }
                    #endif
                    
                    VersionNumber(width: glyphWidth)
                        .font(.subheadline)
                }
                
                AlIslamAppsSection()
            }
            .navigationTitle("Settings")
            .applyConditionalListStyle(defaultView: true)
        }
        .navigationViewStyle(.stack)
    }
    
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
        #if !os(watchOS)
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
            
            #if !os(watchOS)
            Text("Anas ibn Malik (may Allah be pleased with him) said, “The most beloved of colors to the Messenger of Allah (peace be upon him) was green.”")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            #endif
        }
        
        #if !os(watchOS)
        VStack(alignment: .leading) {
            Toggle("Default List View", isOn: $settings.defaultView.animation(.easeInOut))
                .font(.subheadline)
            
            Text("The default list view is the standard interface found in many of Apple's first party apps, including Notes. This setting only applies to Al-Adhan and Al-Quran.")
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
            
            Text("3.5.7")
                .foregroundColor(settings.accentColor.color)
                .padding(.leading, -4)
        }
        .foregroundColor(.primary)
    }
}
