import SwiftUI
import CoreLocation

struct AdhanView: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSettingsSheet = false
    @State private var showBigQibla = false
    @State private var showAlert: AlertType?

    enum AlertType: Identifiable {
        case travelTurnOnAutomatic
        case travelTurnOffAutomatic
        case calculationAutomaticChanged
        case locationAlert
        case notificationAlert

        var id: Int {
            switch self {
            case .travelTurnOnAutomatic: return 1
            case .travelTurnOffAutomatic: return 2
            case .calculationAutomaticChanged: return 3
            case .locationAlert: return 4
            case .notificationAlert: return 5
            }
        }
    }

    var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    adhanContent
                }
            } else {
                NavigationView {
                    adhanContent
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                adhanContent
            }
            #endif
        }
        .confirmationDialog(
            dialogTitle,
            isPresented: Binding(
                get: { showAlert != nil },
                set: { if !$0 { showAlert = nil } }
            ),
            titleVisibility: .visible
        ) {
            alertActions
        } message: {
            alertMessage
        }
    }

    private var adhanContent: some View {
        List {
            Section(header: settings.defaultView ? Text("DATE AND LOCATION") : nil) {
                DateAndLocationSection(showBigQibla: $showBigQibla)
            }

            prayersSection

            #if os(iOS)
            Section(header: Text("LOCATION AND CALCULATION")) {
                LocationCalculationCard()
            }
            #endif
        }
        .refreshable {
            prayerTimeRefresh(force: true)
        }
        .onAppear {
            prayerTimeRefresh(force: false)
        }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .active {
                prayerTimeRefresh(force: false)
            }
        }
        .navigationTitle("Al-Adhan")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView {
                SettingsAdhanView(showNotifications: true, presentedAsSheet: true)
            }
        }
        #endif
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }

    @ViewBuilder
    private var prayersSection: some View {
        #if os(iOS)
        if settings.prayers != nil && settings.currentLocation != nil {
            PrayerCountdown()
            PrayerList()
        }
        #else
        if settings.prayers != nil {
            PrayerCountdown()
            PrayerList()
        }
        #endif
    }

    private func prayerTimeRefresh(force: Bool) {
        settings.requestNotificationAuthorization {
            settings.fetchPrayerTimes(force: force) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showAlert = nextAlertToPresent
                }
            }
        }
    }

    // Keep alert selection in one place so refresh behavior is easy to follow.
    private var nextAlertToPresent: AlertType? {
        if settings.travelTurnOnAutomatic {
            return .travelTurnOnAutomatic
        }
        if settings.travelTurnOffAutomatic {
            return .travelTurnOffAutomatic
        }
        if settings.calculationAutoChanged {
            return .calculationAutomaticChanged
        }
        if !settings.locationNeverAskAgain && settings.showLocationAlert {
            return .locationAlert
        }
        if !settings.notificationNeverAskAgain && settings.showNotificationAlert {
            return .notificationAlert
        }
        return nil
    }

    private var dialogTitle: String {
        switch showAlert {
        case .travelTurnOnAutomatic:
            return "Traveling Mode Detected"
        case .travelTurnOffAutomatic:
            return "Traveling Mode Updated"
        case .calculationAutomaticChanged:
            return "Calculation Method Changed"
        case .locationAlert:
            return "Location Access Needed"
        case .notificationAlert:
            return "Notifications Off"
        case .none:
            return ""
        }
    }

    @ViewBuilder
    private var alertActions: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Button("Override: Turn Off", role: .destructive) {
                settings.overrideTravelingMode(keepOn: false)
            }

            Button("Confirm: Keep On", role: .cancel) {
                settings.confirmTravelAutomaticChange()
            }

        case .travelTurnOffAutomatic:
            Button("Override: Keep On", role: .destructive) {
                settings.overrideTravelingMode(keepOn: true)
            }

            Button("Confirm: Turn Off", role: .cancel) {
                settings.confirmTravelAutomaticChange()
            }

        case .calculationAutomaticChanged:
            Button("Override: Keep \(settings.calculationAutoPreviousMethod)", role: .destructive) {
                settings.overrideAutomaticCalculationKeepingPrevious()
            }

            Button("Confirm: Use \(settings.calculationAutoDetectedMethod)", role: .cancel) {
                settings.confirmAutomaticCalculationChange()
            }

        case .locationAlert:
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Never Ask Again", role: .destructive) {
                settings.locationNeverAskAgain = true
            }
            Button("Ignore", role: .cancel) { }

        case .notificationAlert:
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Never Ask Again", role: .destructive) {
                settings.notificationNeverAskAgain = true
            }
            Button("Ignore", role: .cancel) { }

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var alertMessage: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Text(settings.automaticTravelMessage(turnOn: true))
        case .travelTurnOffAutomatic:
            Text(settings.automaticTravelMessage(turnOn: false))
        case .calculationAutomaticChanged:
            Text(settings.automaticCalculationMessage)
        case .locationAlert:
            Text("Please go to Settings and enable location services to accurately determine prayer times.")
        case .notificationAlert:
            Text("Please go to Settings and enable notifications to be notified of prayer times.")
        case .none:
            EmptyView()
        }
    }

    private func openAppSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
}

private struct DateAndLocationSection: View {
    @EnvironmentObject private var settings: Settings

    @Binding var showBigQibla: Bool

    var body: some View {
        if let hijriDate = settings.hijriDate {
            HijriDateRow(hijriDate: hijriDate)
        }

        CurrentLocationRow(showBigQibla: showBigQibla)
            .animation(.easeInOut, value: showBigQibla)
            #if os(iOS)
            .onTapGesture {
                withAnimation {
                    settings.hapticFeedback()
                    showBigQibla.toggle()
                }
            }
            #endif
    }
}

private struct HijriDateRow: View {
    @EnvironmentObject private var settings: Settings

    let hijriDate: HijriDate

    var body: some View {
        #if os(iOS)
        NavigationLink(destination: HijriCalendarView()) {
            HStack {
                Text(hijriDate.english)
                    .multilineTextAlignment(.center)

                Spacer()

                Text(hijriDate.arabic)
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
            .contextMenu {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = hijriDate.english
                } label: {
                    Label("Copy English Date", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = hijriDate.arabic
                } label: {
                    Label("Copy Arabic Date", systemImage: "doc.on.doc")
                }
            }
        }
        #else
        Text(hijriDate.english)
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
        #endif
    }
}

private struct CurrentLocationRow: View {
    @EnvironmentObject private var settings: Settings

    let showBigQibla: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                locationLabel

                Spacer()

                QiblaView(size: showBigQibla ? 100 : 50)
                    .padding(.leading)
                    .padding(.trailing, 4)
            }
            .foregroundColor(.primary)
            .font(.subheadline)
            .contentShape(Rectangle())
            
            #if os(watchOS)
            Text("Compass may not be accurate on Apple Watch")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            #endif
        }
    }

    @ViewBuilder
    private var locationLabel: some View {
        #if os(iOS)
        if let currentLoc = settings.currentLocation {
            let currentCity = currentLoc.city

            HStack(spacing: 0) {
                Image(systemName: "location.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(settings.accentColor.color)
                    .padding(.trailing, 8)

                Text(currentCity)
                    .font(.subheadline)
                    .lineLimit(nil)
                    .contextMenu {
                        Button {
                            settings.hapticFeedback()
                            UIPasteboard.general.string = currentCity
                        } label: {
                            Label("Copy City Name", systemImage: "doc.on.doc")
                        }
                    }
            }
        } else {
            HStack(spacing: 0) {
                Image(systemName: "location.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(settings.accentColor.color)
                    .padding(.trailing, 8)

                Text("No location")
                    .font(.subheadline)
                    .lineLimit(nil)
            }
        }
        #else
        Group {
            if settings.prayers != nil, let currentLoc = settings.currentLocation {
                Text(currentLoc.city)
            } else {
                Text("No location")
            }
        }
        .font(.subheadline)
        .lineLimit(2)
        #endif
    }
}

private struct LocationCalculationCard: View {
    @EnvironmentObject private var settings: Settings

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(Array(summaryItems.enumerated()), id: \.offset) { _, item in
                    SummaryTile(title: item.title, value: item.value)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var summaryItems: [(title: String, value: String)] {
        var items: [(String, String)] = [
            ("Current Location", currentLocationSummary),
            ("Prayer Calculation", prayerCalculationSummary)
        ]

        if let home = settings.homeLocation {
            items.append(("Home Location", home.city))
            items.append(("Travel Distance", distanceFromHomeText ?? "Unavailable"))
        }

        return items
    }

    private var currentLocationSummary: String {
        settings.currentLocation?.city ?? "Unavailable"
    }

    private var prayerCalculationSummary: String {
        settings.hanafiMadhab ? "\(settings.prayerCalculation)\nHanafi Asr" : settings.prayerCalculation
    }

    private var distanceFromHomeText: String? {
        guard
            let current = settings.currentLocation,
            let home = settings.homeLocation,
            current.latitude != 1000,
            current.longitude != 1000
        else { return nil }

        let here = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let there = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let meters = here.distance(from: there)
        let miles = meters / 1609.34
        let kilometers = meters / 1000

        if miles >= 10 {
            return String(format: "%.0f mi (%.0f km)", miles, kilometers)
        }

        return String(format: "%.1f mi (%.1f km)", miles, kilometers)
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if #available(iOS 16.0, *) {
                Text(value)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            } else {
                Text(value)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .conditionalGlassEffect(rectangle: true, useColor: 0.15)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        AdhanView()
    }
}
