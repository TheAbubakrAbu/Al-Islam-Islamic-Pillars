#if os(iOS)
import SwiftUI
import CoreLocation

// MARK: - PrayerTimesMapView

struct PrayerTimesMapView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss

    @AppStorage("prayerTimesMapShowCityTime") private var showCityTime: Bool = true
    @State private var selectedLocation: Location?
    @State private var selectedDate = Date()
    @State private var prayers: [Prayer] = []
    @State private var currentLocationPrayers: [Prayer] = []
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
        guard let current = settings.currentLocation,
              let selected = selectedLocation else { return false }
        return !isSameLocation(current, selected)
    }

    var body: some View {
        List {
            previewNoticeSection
            citySection
            if !settings.favoriteLocations.isEmpty {
                favoriteCitiesSection
            }
            timeDisplaySection
            comparisonControlSection
            prayerTimesSection
            dateFooterSection
        }
        .navigationTitle("View City Prayer Times")
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
        .onChange(of: showCityTime) { _ in settings.hapticFeedback(); refreshTimeZones() }
        .onChange(of: settings.currentLocation) { _ in
            refreshPrayers()
        }
    }

    private var previewNoticeSection: some View {
        Section {
            Label {
                Text("This map is only for viewing prayer times in other cities. It does not change your actual prayer-time location, calculation method, notifications, or widgets.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "eye")
                    .foregroundStyle(settings.accentColor.color)
            }
        }
    }

    // MARK: - Selected City

    @ViewBuilder
    private var citySection: some View {
        Section {
            if let location = effectiveLocation {
                HStack(spacing: 12) {
                    Image(systemName: selectedLocation == nil ? "location.fill" : "mappin.circle.fill")
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

                    if selectedLocation != nil {
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
                }
            } else {
                Label("No location available", systemImage: "location.slash")
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

            if selectedLocation != nil {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        selectedLocation = nil
                        compareAutomaticLocation = false
                    }
                } label: {
                    Label("Show Current Location", systemImage: "location.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                }
            }
        } header: {
            Text("City")
        } footer: {
            Text(selectedLocation == nil
                ? "Choose a city to view its prayer times. Until then, this shows your current location."
                : "Viewing another city's prayer times does not change your current prayer-time location.")
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
        if selectedLocation != nil {
            Section {
                Toggle(isOn: $compareAutomaticLocation.animation(.easeInOut)) {
                    Label("Compare With Current Location", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(settings.accentColor.color)
                .disabled(!canCompareAutomaticLocation)
                .onChange(of: compareAutomaticLocation) { _ in settings.hapticFeedback() }
            } header: {
                Text("Compare")
            } footer: {
                Text(canCompareAutomaticLocation
                    ? "When comparison is on, only the comparison list is shown."
                    : "Choose a different city to compare it with your current location.")
            }
        }
    }

    // MARK: - Prayer Times

    @ViewBuilder
    private var prayerTimesSection: some View {
        if let location = effectiveLocation {
            Section {
                if compareAutomaticLocation, canCompareAutomaticLocation, let current = settings.currentLocation, let selected = selectedLocation {
                    comparisonRowsView(current: current, selected: selected)
                } else if prayers.isEmpty {
                    Label("No prayer times available", systemImage: "moon.zzz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                } else {
                    ForEach(prayers) { prayer in
                        cityPrayerListRow(prayer: prayer, location: location)
                    }
                }
            } header: {
                HStack {
                    Text("Prayer Times")
                    Spacer()
                    Text(compareAutomaticLocation && canCompareAutomaticLocation ? "COMPARISON" : location.city)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                }
            }
        } else {
            Section {
                Label("Choose a city to see prayer times.", systemImage: "mappin.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Prayer Times")
            }
        }
    }

    @ViewBuilder
    private func comparisonRowsView(current: Location, selected: Location) -> some View {
        let rows = comparisonRows(selected: prayers, current: currentLocationPrayers)
        if rows.isEmpty {
            Label("No comparison available", systemImage: "arrow.left.arrow.right")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
        } else {
            ForEach(rows, id: \.name) { row in
                comparisonListRow(row: row, current: current, selected: selected)
            }
        }
    }

    private func cityPrayerListRow(prayer: Prayer, location: Location) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
                .padding(.vertical, backgroundVerticalPadding)
                .padding(.horizontal, -12)

            HStack {
                Image(systemName: prayer.image)
                    .font(.title3)
                    .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
                    .frame(width: 32, alignment: .center)
                    .padding(.trailing, 2)

                Text(prayer.nameTransliteration)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(formattedTime(prayer.time, for: location))
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.primary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    private func comparisonListRow(
        row: (name: String, image: String, current: Prayer, selected: Prayer),
        current: Location,
        selected: Location
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
                .padding(.vertical, backgroundVerticalPadding)
                .padding(.horizontal, -12)

            HStack(spacing: 10) {
                Image(systemName: row.image)
                    .font(.title3)
                    .foregroundColor(row.name == "Shurooq" ? .primary : settings.accentColor.color)
                    .frame(width: 32, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Selected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(selected.city)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 70, alignment: .trailing)

                        Text(formattedTime(row.selected.time, for: selected))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(current.city)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 70, alignment: .trailing)

                        Text(formattedTime(row.current.time, for: current))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    private var dateFooterSection: some View {
        Section {
            DatePicker("Showing prayers for", selection: $selectedDate.animation(.easeInOut), displayedComponents: .date)
                .datePickerStyle(DefaultDatePickerStyle())
                .tint(settings.accentColor.color)
                .padding(4)
        }
    }

    private var backgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -10
        }
        return -4
    }

    // MARK: - Helpers

    private func refreshPrayers() {
        guard let location = effectiveLocation else {
            prayers = []
            currentLocationPrayers = []
            return
        }

        prayers = prayerTimes(for: location)
        if canCompareAutomaticLocation, let current = settings.currentLocation {
            currentLocationPrayers = prayerTimes(for: current)
        } else {
            currentLocationPrayers = []
            compareAutomaticLocation = false
        }

        refreshTimeZones()
    }

    private func prayerTimes(for location: Location) -> [Prayer] {
        settings.getPrayerTimes(for: selectedDate, at: location, fullPrayers: true) ?? []
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

    private func comparisonRows(selected: [Prayer], current: [Prayer]) -> [(name: String, image: String, current: Prayer, selected: Prayer)] {
        selected.compactMap { selectedPrayer in
            guard let currentPrayer = current.first(where: { $0.nameTransliteration == selectedPrayer.nameTransliteration }) else {
                return nil
            }
            return (selectedPrayer.nameTransliteration, selectedPrayer.image, currentPrayer, selectedPrayer)
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
