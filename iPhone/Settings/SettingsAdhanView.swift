import SwiftUI
import UserNotifications

struct SettingsAdhanView: View {
    @EnvironmentObject var settings: Settings
    
    @State private var showingMap = false
    
    @State private var showAlert: AlertType?
    enum AlertType: Identifiable {
        case travelTurnOnAutomatic, travelTurnOffAutomatic

        var id: Int {
            switch self {
            case .travelTurnOnAutomatic: return 1
            case .travelTurnOffAutomatic: return 2
            }
        }
    }
    
    @State var showNotifications: Bool
    
    var body: some View {
        List {
            #if !os(watchOS)
            if showNotifications {
                Section(header: Text("NOTIFICATIONS")) {
                    NavigationLink(destination: NotificationView()) {
                        Label("Notification Settings", systemImage: "bell.badge")
                    }
                }
            }
            #endif
            
            Section(header: Text("PRAYER CALCULATION")) {
                VStack(alignment: .leading) {
                    Picker("Calculation", selection: $settings.prayerCalculation.animation(.easeInOut)) {
                        ForEach(calculationOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Text("Fajr and Isha timings vary by calculation method. If available, use location-based calculations; for example, in North America, the North America method is recommended. Otherwise, choose the Muslim World League or another global option.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                }
                
                VStack(alignment: .leading) {
                    Toggle("Use Hanafi Calculation for Asr", isOn: $settings.hanafiMadhab.animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                    
                    Text("The Hanafi madhab sets Asr later than other schools of thought. Enable this only if you follow the Hanafi method.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                }
            }
            
            Section(header: Text("TRAVELING MODE")) {
                #if !os(watchOS)
                Button(action: {
                    settings.hapticFeedback()
                    
                    showingMap = true
                }) {
                    HStack {
                        Text("Set Home City")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                        if !(settings.homeLocation?.city.isEmpty ?? true) {
                            Spacer()
                            Text(settings.homeLocation?.city ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .sheet(isPresented: $showingMap) {
                    MapView(choosingPrayerTimes: false)
                        .environmentObject(settings)
                }
                
                Toggle("Traveling Mode Turns on Automatically", isOn: $settings.travelAutomatic.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                #endif
                
                VStack(alignment: .leading) {
                    #if !os(watchOS)
                    Toggle("Traveling Mode", isOn: Binding(
                        get: { settings.travelingMode },
                        set: { settings.travelingModeManuallyToggled = true; settings.travelingMode = $0 }
                    ).animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                        .disabled(settings.travelAutomatic)
                    
                    Text("If you are traveling more than 48 mi (77.25 km), then it is obligatory to pray Qasr, where you combine Dhuhr and Asr (2 rakahs each) and Maghrib and Isha (3 and 2 rakahs). Allah said in the Quran, “And when you (Muslims) travel in the land, there is no sin on you if you shorten As-Salah (the prayer)” [Quran, An-Nisa, 4:101]. \(settings.travelAutomatic ? "This feature turns on and off automatically, but you can also control it manually here." : "You can control traveling mode manually here.")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                    #else
                    Toggle("Traveling Mode", isOn: Binding(
                        get: { settings.travelingMode },
                        set: { settings.travelingModeManuallyToggled = true; settings.travelingMode = $0 }
                    ).animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                    #endif
                }
            }
            
            #if !os(watchOS)
            PrayerOffsetsView()
            #endif
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Al-Adhan Settings")
        .onChange(of: settings.homeLocation) { _ in
            settings.fetchPrayerTimes() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if settings.travelTurnOnAutomatic {
                        showAlert = .travelTurnOnAutomatic
                    } else if settings.travelTurnOffAutomatic {
                        showAlert = .travelTurnOffAutomatic
                    }
                }
            }
        }
        .onChange(of: settings.travelAutomatic) { newValue in
            if newValue {
                settings.fetchPrayerTimes() {
                    if settings.homeLocation == nil {
                        withAnimation {
                            settings.travelingMode = false
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if settings.travelTurnOnAutomatic {
                                showAlert = .travelTurnOnAutomatic
                            } else if settings.travelTurnOffAutomatic {
                                showAlert = .travelTurnOffAutomatic
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog("", isPresented: Binding(
            get: { showAlert != nil },
            set: { if !$0 { showAlert = nil } }
        ), titleVisibility: .visible) {
            switch showAlert {
            case .travelTurnOnAutomatic:
                Button("Override: Turn Off", role: .destructive) {
                    settings.travelingModeManuallyToggled = true
                    withAnimation {
                        settings.travelingMode = false
                    }
                    settings.travelAutomatic = false
                    settings.travelTurnOnAutomatic = false
                    settings.travelTurnOffAutomatic = false
                    settings.fetchPrayerTimes(force: true)
                }
                
                Button("Confirm: Keep On", role: .cancel) {
                    settings.travelTurnOnAutomatic = false
                    settings.travelTurnOffAutomatic = false
                }
                
            case .travelTurnOffAutomatic:
                Button("Override: Keep On", role: .destructive) {
                    settings.travelingModeManuallyToggled = true
                    withAnimation {
                        settings.travelingMode = true
                    }
                    settings.travelAutomatic = false
                    settings.travelTurnOnAutomatic = false
                    settings.travelTurnOffAutomatic = false
                    settings.fetchPrayerTimes(force: true)
                }
                
                Button("Confirm: Turn Off", role: .cancel) {
                    settings.travelTurnOnAutomatic = false
                    settings.travelTurnOffAutomatic = false
                }
                
            case .none:
                EmptyView()
            }
        } message: {
            switch showAlert {
            case .travelTurnOnAutomatic:
                Text("Al-Adhan has automatically detected that you are traveling, so your prayers will be shortened.")
            case .travelTurnOffAutomatic:
                Text("Al-Adhan has automatically detected that you are no longer traveling, so your prayers will not be shortened.")
            case .none:
                EmptyView()
            }
        }
    }
}

let calculationOptions: [String] = [
    "Muslim World League",
    "Moonsight Committee",
    "Umm Al-Qura",
    "Egypt",
    "Dubai",
    "Kuwait",
    "Qatar",
    "Turkey",
    "Tehran",
    "Karachi",
    "Singapore",
    "North America"
]

struct PrayerOffsetsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        Section(header: Text("PRAYER OFFSETS")) {
            Stepper(value: $settings.offsetFajr, in: -10...10) {
                HStack {
                    Text("Fajr")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetFajr) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetSunrise, in: -10...10) {
                HStack {
                    Text("Sunrise")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetSunrise) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetDhuhr, in: -10...10) {
                HStack {
                    Text("Dhuhr")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetDhuhr) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetAsr, in: -10...10) {
                HStack {
                    Text("Asr")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetAsr) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetMaghrib, in: -10...10) {
                HStack {
                    Text("Maghrib")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetMaghrib) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetIsha, in: -10...10) {
                HStack {
                    Text("Isha")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetIsha) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetDhurhAsr, in: -10...10) {
                HStack {
                    Text("Combined Traveling\nDhuhr and Asr")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetDhurhAsr) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Stepper(value: $settings.offsetMaghribIsha, in: -10...10) {
                HStack {
                    Text("Combined Traveling\nMaghrib and Isha")
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Text("\(settings.offsetMaghribIsha) min")
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            
            Text("Use these offsets to shift the calculated prayer times earlier or later. Negative values move the time earlier, positive values move it later.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }
}

struct NotificationView: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showAlert: Bool = false
    @State private var notifSettings: UNNotificationSettings?
    @State private var requestAccessAlertMessage: String?
    
    var body: some View {
        List {
            #if !os(watchOS)
            Section {
                permissionCard
            }
            #endif
            
            Section(header: Text("HIJRI CALENDAR")) {
                Toggle("Islamic Calendar Notifications", isOn: $settings.dateNotifications.animation(.easeInOut))
                    .font(.subheadline)
            }
            
            Section(header: Text("PRAYER REMINDERS")) {
                NavigationLink(destination: MoreNotificationView()) {
                    Label("Prayer Notifications", systemImage: "bell.fill")
                        .font(.subheadline)
                }
            }
        }
        .task { await refresh() }
        .onAppear { requestAuthorizationAndFetchPrayerTimes() }
        .onChange(of: scenePhase) { _ in requestAuthorizationAndFetchPrayerTimes() }
        .confirmationDialog("", isPresented: $showAlert, titleVisibility: .visible) {
            Button("Open Settings") { openSystemSettings() }
            Button("Ignore", role: .cancel) { }
        } message: {
            Text("Please go to Settings and enable notifications to be notified of prayer times.")
        }
        .confirmationDialog("Notifications", isPresented: Binding(
            get: { requestAccessAlertMessage != nil },
            set: { if !$0 { requestAccessAlertMessage = nil } }
        ), titleVisibility: .visible) {
            Button("OK", role: .cancel) { requestAccessAlertMessage = nil }
            Button("Open Settings") {
                requestAccessAlertMessage = nil
                openSystemSettings()
            }
        } message: {
            if let msg = requestAccessAlertMessage {
                Text(msg)
            }
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Notification Settings")
    }
    
    #if !os(watchOS)
    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Permission", systemImage: "bell.badge")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Spacer()

                Text(permissionPillText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(permissionPillColor))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    .padding(.trailing, -6)
            }
            .animation(.easeInOut(duration: 0.25), value: permissionPillText)

            if let s = notifSettings {
                VStack(spacing: 8) {
                    infoRow("Status", statusText(s.authorizationStatus))
                    infoRow("Alerts", notificationSettingText(s.alertSetting))
                    infoRow("Sounds", notificationSettingText(s.soundSetting))
                }
                .font(.footnote)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            HStack(spacing: 10) {
                Button {
                    settings.hapticFeedback()
                    Task { @MainActor in await onRequestAccessTapped() }
                } label: {
                    smallButton("Request Access", systemImage: "checkmark.seal")
                }
                .buttonStyle(.plain)

                Button {
                    settings.hapticFeedback()
                    openSystemSettings()
                } label: {
                    smallButton("Open Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: notifSettings?.authorizationStatus.rawValue)
    }
    #endif
    
    private var permissionPillText: String {
        statusText(notifSettings?.authorizationStatus ?? .notDetermined)
    }
    
    private var permissionPillColor: Color {
        guard let status = notifSettings?.authorizationStatus else { return .secondary }
        switch status {
        case .authorized, .provisional, .ephemeral:
            return settings.accentColor.color
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }
    
    private func infoRow(_ left: String, _ right: String) -> some View {
        HStack {
            Text(left).foregroundColor(.secondary)
            Spacer()
            Text(right).foregroundColor(.primary)
        }
    }
    
    private func statusText(_ s: UNAuthorizationStatus) -> String {
        switch s {
        case .notDetermined: return "Not asked"
        case .denied: return "Denied"
        case .authorized: return "Allowed"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func notificationSettingText(_ s: UNNotificationSetting) -> String {
        switch s {
        case .enabled: return "On"
        case .disabled: return "Off"
        case .notSupported: return "N/A"
        @unknown default: return "Unknown"
        }
    }
    
    private func smallButton(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            
            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(settings.accentColor.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.35), lineWidth: 1)
        )
    }
    
    private func openSystemSettings() {
        #if !os(watchOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
    
    @MainActor
    private func refresh() async {
        let center = UNUserNotificationCenter.current()
        notifSettings = await center.notificationSettings()
    }
    
    private func requestAuthorizationAndFetchPrayerTimes() {
        settings.requestNotificationAuthorization {
            settings.fetchPrayerTimes {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if settings.showNotificationAlert {
                        showAlert = true
                    }
                }
            }
        }
    }
    
    @MainActor
    private func onRequestAccessTapped() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        switch current.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            requestAccessAlertMessage = "Notifications are already turned on."
        case .denied:
            requestAccessAlertMessage = "Notifications are turned off. Open Settings to enable them."
        case .notDetermined:
            _ = await settings.requestNotificationAuthorization()
            await refresh()
        @unknown default:
            requestAccessAlertMessage = "Unable to change notification settings."
        }
    }
}

struct MoreNotificationView: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showAlert: Bool = false
    
    private func turnOffNaggingModeIfAllOff() {
        if !settings.naggingFajr &&
           !settings.naggingSunrise &&
           !settings.naggingDhuhr &&
           !settings.naggingAsr &&
           !settings.naggingMaghrib &&
           !settings.naggingIsha {
            
            withAnimation {
                settings.naggingMode = false
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("NAGGING MODE")) {
                Text("Nagging mode helps those who struggle to pray on time. Once enabled, you'll get a notification at the chosen start time before each prayer, then another every 15 minutes, plus final reminders at 10 and 5 minutes remaining.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Turn on Nagging Mode", isOn: Binding(
                    get: { settings.naggingMode },
                    set: { newValue in
                        withAnimation {
                            settings.naggingMode = newValue
                            
                            if newValue {
                                settings.notificationFajr = true
                                settings.notificationSunrise = true
                                settings.notificationDhuhr = true
                                settings.notificationAsr = true
                                settings.notificationMaghrib = true
                                settings.notificationIsha = true
                                
                                settings.naggingFajr = true
                                settings.naggingSunrise = true
                                settings.naggingDhuhr = true
                                settings.naggingAsr = true
                                settings.naggingMaghrib = true
                                settings.naggingIsha = true
                            } else {
                                settings.naggingFajr = false
                                settings.naggingSunrise = false
                                settings.naggingDhuhr = false
                                settings.naggingAsr = false
                                settings.naggingMaghrib = false
                                settings.naggingIsha = false
                            }
                        }
                    }
                ).animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
                
                if settings.naggingMode {
                    Picker("Starting Time", selection: $settings.naggingStartOffset.animation(.easeInOut)) {
                        Text("45 mins").tag(45)
                        Text("30 mins").tag(30)
                        Text("15 mins").tag(15)
                        Text("10 mins").tag(10)
                    }
                    #if !os(watchOS)
                    .pickerStyle(.segmented)
                    #endif
                    
                    Group {
                        Toggle("Nagging before Fajr", isOn: Binding(
                            get: { settings.naggingFajr },
                            set: { newValue in
                                settings.naggingFajr = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        
                        Toggle("Nagging before Sunrise", isOn: Binding(
                            get: { settings.naggingSunrise },
                            set: { newValue in
                                settings.naggingSunrise = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        
                        Toggle("Nagging before Dhuhr", isOn: Binding(
                            get: { settings.naggingDhuhr },
                            set: { newValue in
                                settings.naggingDhuhr = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        
                        Toggle("Nagging before Asr", isOn: Binding(
                            get: { settings.naggingAsr },
                            set: { newValue in
                                settings.naggingAsr = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        
                        Toggle("Nagging before Maghrib", isOn: Binding(
                            get: { settings.naggingMaghrib },
                            set: { newValue in
                                settings.naggingMaghrib = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        
                        Toggle("Nagging before Isha", isOn: Binding(
                            get: { settings.naggingIsha },
                            set: { newValue in
                                settings.naggingIsha = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                    }
                    .tint(settings.accentColor.color)
                }
            }
            
            if !settings.naggingMode {
                Section(header: Text("ALL PRAYER NOTIFICATIONS")) {
                    Toggle("Turn On All Prayer Notifications", isOn: Binding(
                        get: {
                            settings.notificationFajr &&
                            settings.notificationSunrise &&
                            settings.notificationDhuhr &&
                            settings.notificationAsr &&
                            settings.notificationMaghrib &&
                            settings.notificationIsha
                        },
                        set: { newValue in
                            withAnimation {
                                settings.notificationFajr = newValue
                                settings.notificationSunrise = newValue
                                settings.notificationDhuhr = newValue
                                settings.notificationAsr = newValue
                                settings.notificationMaghrib = newValue
                                settings.notificationIsha = newValue
                            }
                        }
                    ).animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    
                    Stepper(value: Binding(
                        get: { settings.preNotificationFajr },
                        set: { newValue in
                            withAnimation {
                                settings.preNotificationFajr = newValue
                                settings.preNotificationSunrise = newValue
                                settings.preNotificationDhuhr = newValue
                                settings.preNotificationAsr = newValue
                                settings.preNotificationMaghrib = newValue
                                settings.preNotificationIsha = newValue
                            }
                        }
                    ), in: 0...30, step: 5) {
                        Text("All Prayer Prenotifications:")
                            .font(.subheadline)
                        Text("\(settings.preNotificationFajr) minute\(settings.preNotificationFajr != 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }
            
            if !settings.naggingMode {
                NotificationSettingsSection(prayerName: "Fajr", preNotificationTime: $settings.preNotificationFajr, isNotificationOn: $settings.notificationFajr)
                NotificationSettingsSection(prayerName: "Shurooq", preNotificationTime: $settings.preNotificationSunrise, isNotificationOn: $settings.notificationSunrise)
                NotificationSettingsSection(prayerName: "Dhuhr", preNotificationTime: $settings.preNotificationDhuhr, isNotificationOn: $settings.notificationDhuhr)
                NotificationSettingsSection(prayerName: "Asr", preNotificationTime: $settings.preNotificationAsr, isNotificationOn: $settings.notificationAsr)
                NotificationSettingsSection(prayerName: "Maghrib", preNotificationTime: $settings.preNotificationMaghrib, isNotificationOn: $settings.notificationMaghrib)
                NotificationSettingsSection(prayerName: "Isha", preNotificationTime: $settings.preNotificationIsha, isNotificationOn: $settings.notificationIsha)
            } else {
                if !settings.naggingFajr {
                    NotificationSettingsSection(prayerName: "Fajr", preNotificationTime: $settings.preNotificationFajr, isNotificationOn: $settings.notificationFajr)
                }
                if !settings.naggingSunrise {
                    NotificationSettingsSection(prayerName: "Shurooq", preNotificationTime: $settings.preNotificationSunrise, isNotificationOn: $settings.notificationSunrise)
                }
                if !settings.naggingDhuhr {
                    NotificationSettingsSection(prayerName: "Dhuhr", preNotificationTime: $settings.preNotificationDhuhr, isNotificationOn: $settings.notificationDhuhr)
                }
                if !settings.naggingAsr {
                    NotificationSettingsSection(prayerName: "Asr", preNotificationTime: $settings.preNotificationAsr, isNotificationOn: $settings.notificationAsr)
                }
                if !settings.naggingMaghrib {
                    NotificationSettingsSection(prayerName: "Maghrib", preNotificationTime: $settings.preNotificationMaghrib, isNotificationOn: $settings.notificationMaghrib)
                }
                if !settings.naggingIsha {
                    NotificationSettingsSection(prayerName: "Isha", preNotificationTime: $settings.preNotificationIsha, isNotificationOn: $settings.notificationIsha)
                }
            }
        }
        .onAppear {
            settings.requestNotificationAuthorization {
                settings.fetchPrayerTimes() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if settings.showNotificationAlert {
                            showAlert = true
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _ in
            settings.requestNotificationAuthorization {
                settings.fetchPrayerTimes() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if settings.showNotificationAlert {
                            showAlert = true
                        }
                    }
                }
            }
        }
        .onDisappear {
            settings.fetchPrayerTimes(notification: true)
        }
        .confirmationDialog("", isPresented: $showAlert, titleVisibility: .visible) {
            Button("Open Settings") {
                #if !os(watchOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                #endif
            }
            Button("Ignore", role: .cancel) { }
        } message: {
            Text("Please go to Settings and enable notifications to be notified of prayer times.")
        }
        .applyConditionalListStyle(defaultView: true)
        .navigationTitle("Prayer Notifications")
    }
}

struct NotificationSettingsSection: View {
    @EnvironmentObject var settings: Settings
    
    let prayerName: String
    
    @Binding var preNotificationTime: Int
    @Binding var isNotificationOn: Bool

    var body: some View {
        Section(header: Text(prayerName.uppercased())) {
            Toggle("Notification", isOn: $isNotificationOn.animation(.easeInOut))
                .font(.subheadline)
            
            if isNotificationOn {
                Stepper(value: $preNotificationTime.animation(.easeInOut), in: 0...30, step: 5) {
                    Text("Prenotification Time:")
                        .font(.subheadline)
                    
                    Text("\(preNotificationTime) minute\(preNotificationTime != 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)
                }
            }
        }
    }
}

#Preview {
    SettingsAdhanView(showNotifications: true)
        .environmentObject(Settings.shared)
}
