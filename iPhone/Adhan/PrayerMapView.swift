#if os(iOS)
import SwiftUI
import CoreLocation

// MARK: - PrayerTimesMapView

struct PrayerTimesMapView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss

    @AppStorage("prayerTimesMapAutomatic") private var isAutomatic: Bool = true
    @State private var selectedLocation: Location?
    @State private var selectedDate = Date()
    @State private var prayers: [Prayer] = []
    @State private var showCityPicker = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    private var effectiveLocation: Location? {
        isAutomatic ? settings.currentLocation : (selectedLocation ?? settings.currentLocation)
    }

    var body: some View {
        List {
            locationModeSection
            if !isAutomatic {
                citySection
                if !settings.favoriteLocations.isEmpty {
                    favoriteCitiesSection
                }
            }
            prayerTimesSection
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
        .onChange(of: settings.currentLocation) { _ in
            if isAutomatic { refreshPrayers() }
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
                ? "Prayer times are calculated from your current GPS location."
                : "Choose any city to look up its prayer times.")
        }
    }

    // MARK: - City (Manual Mode)

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

                            VStack(alignment: .leading, spacing: 1) {
                                Text(prayer.nameTransliteration)
                                    .font(.subheadline.weight(.semibold))
                                Text(prayer.nameArabic)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(prayer.time, style: .time)
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

    // MARK: - Helpers

    private func refreshPrayers() {
        guard let location = effectiveLocation else { prayers = []; return }
        let original = settings.currentLocation
        settings.currentLocation = location
        prayers = settings.getPrayerTimes(for: selectedDate, fullPrayers: false) ?? []
        if let original { settings.currentLocation = original }
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
