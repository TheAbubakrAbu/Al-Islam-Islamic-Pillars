#if os(iOS)
import SwiftUI
import CoreLocation

// MARK: - PrayerTimesMapView

struct PrayerTimesMapView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss

    @AppStorage("prayerTimesMapAutomatic") private var isAutomatic: Bool = true
    @AppStorage("prayerTimesMapShowCityTime") private var showCityTime: Bool = true
    @State private var selectedLocation: Location?
    @State private var selectedDate = Date()
    @State private var prayers: [Prayer] = []
    @State private var automaticPrayers: [Prayer] = []
    @State private var showCityPicker = false
    @State private var compareAutomaticLocation = false
    @State private var timeZones: [String: TimeZone] = [:]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    private var effectiveLocation: Location? {
        selectedLocation ?? settings.currentLocation
    }

    private var canCompareAutomaticLocation: Bool {
        guard isAutomatic,
              let current = settings.currentLocation,
              let selected = selectedLocation else { return false }
        return !isSameLocation(current, selected)
    }

    var body: some View {
        List {
            locationModeSection
            citySection
            if !settings.favoriteLocations.isEmpty {
                favoriteCitiesSection
            }
            timeDisplaySection
            comparisonControlSection
            prayerTimesSection
            comparisonSection
        }
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { settings.hapticFeedback(); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .tint(settings.accentColor.color)
            }
        }
        .sheet(isPresented: $showCityPicker) {
            MapView(choosingPrayerTimes: true, onSelectCity: { location in
                selectedLocation = location
                showCityPicker = false
            })
            .environmentObject(settings)
        }
        .onAppear { refreshPrayers() }
        .onChange(of: selectedDate) { _ in refreshPrayers() }
        .onChange(of: selectedLocation) { _ in refreshPrayers() }
        .onChange(of: isAutomatic) { _ in refreshPrayers() }
        .onChange(of: showCityTime) { _ in refreshTimeZones() }
        .onChange(of: settings.currentLocation) { _ in
            refreshPrayers()
        }
    }

    // MARK: - Location Mode

    private var locationModeSection: some View {
        Section {
            Picker("Mode", selection: $isAutomatic.animation(.easeInOut)) {
                Label("Automatic", systemImage: "location.fill").tag(true)
                Label("Manual", systemImage: "hand.tap").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 2)

            if isAutomatic {
                if let city = settings.currentLocation?.city {
                    Label(city, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundStyle(settings.accentColor.color)
                } else {
                    Label("No location available", systemImage: "location.slash")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Location Mode")
        } footer: {
            Text(isAutomatic
                ? "Automatic stays tied to your GPS location, but you can still browse any selected city here."
                : "Choose any city to look up its prayer times.")
        }
    }

    // MARK: - Selected City

    @ViewBuilder
    private var citySection: some View {
        Section {
            if let location = selectedLocation {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.city)
                            .font(.subheadline.weight(.semibold))
                        Text(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        settings.hapticFeedback()
                        toggleFavorite(location)
                    } label: {
                        Image(systemName: isFavorite(location) ? "star.fill" : "star")
                            .foregroundStyle(settings.accentColor.color)
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Label("No city selected", systemImage: "mappin.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                settings.hapticFeedback()
                showCityPicker = true
            } label: {
                Label("Choose City on Map", systemImage: "map")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }
        } header: {
            Text("Selected City")
        } footer: {
            Text(selectedLocation == nil
                ? "If no city is selected, this view shows your current location."
                : "Selecting a city here does not change your automatic prayer-time location.")
        }
    }

    // MARK: - Favorite Cities

    private var favoriteCitiesSection: some View {
        Section {
            ForEach(settings.favoriteLocations, id: \.city) { location in
                Button {
                    settings.hapticFeedback()
                    withAnimation { selectedLocation = location }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(settings.accentColor.color)
                            .frame(width: 20)

                        Text(location.city)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedLocation?.city == location.city {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                        }
                    }
                }
            }
            .onDelete { indices in
                settings.favoriteLocations.remove(atOffsets: indices)
                if let sel = selectedLocation,
                   !settings.favoriteLocations.contains(where: { $0.city == sel.city }),
                   !isFavorite(sel) {
                    // keep selection, just removed from favorites
                }
            }
        } header: {
            Text("Favorite Cities")
        }
    }

    // MARK: - Time Display

    private var timeDisplaySection: some View {
        Section {
            Picker("Show Times In", selection: $showCityTime.animation(.easeInOut)) {
                Text("City Time").tag(true)
                Text("My Time").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 2)
        } header: {
            Text("Time Display")
        } footer: {
            Text(showCityTime
                ? "Times are shown in the viewed city's time zone when available."
                : "Times are shown in your device's current time zone.")
        }
    }

    // MARK: - Compare

    @ViewBuilder
    private var comparisonControlSection: some View {
        if isAutomatic, selectedLocation != nil {
            Section {
                Toggle(isOn: $compareAutomaticLocation.animation(.easeInOut)) {
                    Label("Compare with Automatic Location", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(settings.accentColor.color)
                .disabled(!canCompareAutomaticLocation)
            } header: {
                Text("Compare")
            } footer: {
                Text(canCompareAutomaticLocation
                    ? "Compare your GPS prayer times with the selected city."
                    : "Choose a different city to compare it with your automatic location.")
            }
        }
    }

    // MARK: - Prayer Times

    @ViewBuilder
    private var prayerTimesSection: some View {
        Section {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .tint(settings.accentColor.color)
        } header: {
            Text("Date")
        }

        if let location = effectiveLocation {
            Section {
                if prayers.isEmpty {
                    Label("No prayer times available", systemImage: "moon.zzz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                } else {
                    ForEach(prayers) { prayer in
                        HStack(spacing: 12) {
                            Image(systemName: prayer.image)
                                .font(.subheadline)
                                .foregroundStyle(settings.accentColor.color)
                                .frame(width: 22, alignment: .center)

                            Text(prayer.nameTransliteration)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Text(formattedTime(prayer.time, for: location))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Prayer Times")
                    Spacer()
                    Text(location.city)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                }
            }
        } else {
            Section {
                Label(isAutomatic ? "Enable location services to see prayer times." : "Select a city to see prayer times.",
                      systemImage: isAutomatic ? "location.slash" : "mappin.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Prayer Times")
            }
        }
    }

    @ViewBuilder
    private var comparisonSection: some View {
        if canCompareAutomaticLocation,
           compareAutomaticLocation,
           let current = settings.currentLocation,
           let selected = selectedLocation {
            Section {
                ForEach(comparisonRows(selected: prayers, automatic: automaticPrayers), id: \.name) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: row.image)
                                .font(.subheadline)
                                .foregroundStyle(settings.accentColor.color)
                                .frame(width: 22, alignment: .center)

                            Text(row.name)
                                .font(.subheadline.weight(.semibold))

                            Spacer()
                        }

                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(current.city)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(formattedTime(row.automatic.time, for: current))
                                    .font(.subheadline.monospacedDigit())
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(selected.city)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(formattedTime(row.selected.time, for: selected))
                                    .font(.subheadline.monospacedDigit())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Automatic vs Selected City")
            }
        }
    }

    // MARK: - Helpers

    private func refreshPrayers() {
        guard let location = effectiveLocation else {
            prayers = []
            automaticPrayers = []
            return
        }

        prayers = prayerTimes(for: location)
        if canCompareAutomaticLocation, let current = settings.currentLocation {
            automaticPrayers = prayerTimes(for: current)
        } else {
            automaticPrayers = []
            compareAutomaticLocation = false
        }

        refreshTimeZones()
    }

    private func prayerTimes(for location: Location) -> [Prayer] {
        let original = settings.currentLocation
        settings.currentLocation = location
        defer { settings.currentLocation = original }
        return settings.getPrayerTimes(for: selectedDate, fullPrayers: false) ?? []
    }

    private func formattedTime(_ date: Date, for location: Location) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = showCityTime ? (timeZones[timeZoneKey(for: location)] ?? .current) : .current
        return formatter.string(from: date)
    }

    private func refreshTimeZones() {
        guard showCityTime else { return }
        if let location = effectiveLocation {
            requestTimeZone(for: location)
        }
        if canCompareAutomaticLocation, let current = settings.currentLocation {
            requestTimeZone(for: current)
        }
    }

    private func requestTimeZone(for location: Location) {
        let key = timeZoneKey(for: location)
        guard timeZones[key] == nil else { return }

        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, _ in
            guard let timeZone = placemarks?.first?.timeZone else { return }
            DispatchQueue.main.async {
                timeZones[key] = timeZone
            }
        }
    }

    private func timeZoneKey(for location: Location) -> String {
        "\(location.latitude.stringRepresentation),\(location.longitude.stringRepresentation)"
    }

    private func comparisonRows(selected: [Prayer], automatic: [Prayer]) -> [(name: String, image: String, automatic: Prayer, selected: Prayer)] {
        selected.compactMap { selectedPrayer in
            guard let automaticPrayer = automatic.first(where: { $0.nameTransliteration == selectedPrayer.nameTransliteration }) else {
                return nil
            }
            return (selectedPrayer.nameTransliteration, selectedPrayer.image, automaticPrayer, selectedPrayer)
        }
    }

    private func isSameLocation(_ lhs: Location, _ rhs: Location) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.0001 && abs(lhs.longitude - rhs.longitude) < 0.0001
    }

    private func isFavorite(_ location: Location) -> Bool {
        settings.favoriteLocations.contains(where: { $0.city == location.city })
    }

    private func toggleFavorite(_ location: Location) {
        withAnimation {
            if isFavorite(location) {
                settings.favoriteLocations.removeAll { $0.city == location.city }
            } else {
                settings.favoriteLocations.append(location)
            }
        }
    }
}

#Preview {
    NavigationView {
        PrayerTimesMapView()
            .environmentObject(Settings.shared)
    }
}
#endif
