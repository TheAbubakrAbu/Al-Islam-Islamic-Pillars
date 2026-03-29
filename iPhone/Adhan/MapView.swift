import SwiftUI
import MapKit
import CoreLocation
#if os(iOS)
import UIKit
#endif

struct MapView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme

    @State private var searchText = ""
    @State private var cityItems: [MKMapItem] = []
    @State private var selectedItem: MKMapItem?
    @State private var showAlert = false
    @State private var searchTask: Task<Void, Never>?
    @State private var choosingPrayerTimes: Bool
    @State private var region: MKCoordinateRegion

    private let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.422445, longitude: 39.826388)

    init(choosingPrayerTimes: Bool) {
        _choosingPrayerTimes = State(initialValue: choosingPrayerTimes)

        let coordinate: CLLocationCoordinate2D = {
            let settings = Settings.shared
            if let home = settings.homeLocation {
                return home.coordinate
            }
            if let current = settings.currentLocation, current.latitude != 1000, current.longitude != 1000 {
                return current.coordinate
            }
            return CLLocationCoordinate2D(latitude: 21.422445, longitude: 39.826388)
        }()

        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ))
    }

    private var scheme: ColorScheme {
        settings.colorScheme ?? systemScheme
    }

    private var markers: [MarkerItem] {
        var items: [MarkerItem] = []

        if let current = settings.currentLocation,
           current.latitude != 1000,
           current.longitude != 1000 {
            items.append(
                MarkerItem(
                    id: "current",
                    coordinate: CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude),
                    tint: .cyan,
                    systemImage: "location.fill"
                )
            )
        }

        if let selectedItem {
            items.append(
                MarkerItem(
                    id: "selected",
                    coordinate: selectedItem.placemark.coordinate,
                    tint: .green,
                    systemImage: "mappin.circle.fill"
                )
            )
            return items
        }

        if let home = settings.homeLocation {
            items.append(
                MarkerItem(
                    id: "home",
                    coordinate: home.coordinate,
                    tint: settings.accentColor.color,
                    systemImage: "house.fill"
                )
            )
        }

        return items
    }

    private var distanceString: String? {
        guard
            let current = settings.currentLocation,
            let home = settings.homeLocation,
            current.latitude != 1000,
            current.longitude != 1000
        else { return nil }

        let here = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let there = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let meters = here.distance(from: there)
        let kilometers = meters / 1_000
        let miles = meters / 1_609.344

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1

        guard
            let kmText = formatter.string(from: kilometers as NSNumber),
            let mileText = formatter.string(from: miles as NSNumber)
        else { return nil }

        return "\(mileText) mi / \(kmText) km"
    }

    var body: some View {
        NavigationView {
            interactiveMap
                .edgesIgnoringSafeArea(.all)
                .overlay(alignment: .top) {
                    SearchOverlay(
                        searchText: $searchText,
                        cityItems: cityItems,
                        onSelect: select(_:),
                        primaryLocationName: primaryLocationName(for:),
                        secondaryLocationName: secondaryLocationName(for:),
                        cityIconName: cityIconName(for:)
                    )
                }
                .safeAreaInset(edge: .bottom) {
                    bottomInsetContent
                }
                .navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Done") {
                    settings.hapticFeedback()
                    dismiss()
                })
                .dismissKeyboardOnScroll()
                .confirmationDialog("Location Access Denied", isPresented: $showAlert) {
                    Button("Open Settings") { openSettings() }
                    Button("Never Ask Again", role: .destructive) { settings.locationNeverAskAgain = true }
                    Button("Ignore", role: .cancel) { }
                } message: {
                    Text("Please enable location services to accurately determine prayer times.")
                }
                .onChange(of: searchText) { newText in
                    scheduleSearch(for: newText)
                }
                .onAppear {
                    configureInitialRegion()
                }
                .preferredColorScheme(scheme)
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }

    private var interactiveMap: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { marker in
            MapAnnotation(coordinate: marker.coordinate) {
                AnimatedMarkerBubble(tint: marker.tint, systemImage: marker.systemImage)
            }
        }
    }

    @ViewBuilder
    private var bottomInsetContent: some View {
        if !choosingPrayerTimes, let home = settings.homeLocation {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                HomeLocationSummaryCard(home: home, distanceString: distanceString)
                useCurrentButton
            }
            .padding(.bottom, 26)
            .padding(.horizontal)
        }
    }

    private var useCurrentButton: some View {
        Button {
            settings.hapticFeedback()
            guard let current = settings.currentLocation else { return }

            withAnimation {
                let coordinate = CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude)
                updateRegion(to: coordinate)
                selectedItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                settings.homeLocation = Location(city: current.city, latitude: current.latitude, longitude: current.longitude)
            }

            settings.fetchPrayerTimes {
                if !settings.locationNeverAskAgain && settings.showLocationAlert {
                    showAlert = true
                }
            }
        } label: {
            Text("Automatically Use Current Location")
                .foregroundColor(.primary)
                .buttonStyle(.plain)
                .clipShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.headline)
        .foregroundColor(settings.accentColor.color)
        .padding(18)
        .conditionalGlassEffect(useColor: 0.25)
    }

    private func select(_ item: MKMapItem) {
        settings.hapticFeedback()

        let city = item.placemark.locality ?? item.placemark.name ?? "Unknown"
        let state = item.placemark.administrativeArea ?? ""
        let fullName = state.isEmpty ? city : "\(city), \(state)"

        withAnimation {
            selectedItem = item
            settings.homeLocation = Location(
                city: fullName,
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            )
            updateRegion(to: item.placemark.coordinate)
            searchText = ""
        }
    }

    private func formattedName(for item: MKMapItem) -> String {
        let city = item.placemark.locality ?? item.placemark.name ?? ""
        let state = item.placemark.administrativeArea ?? ""
        let name = state.isEmpty ? city : "\(city), \(state)"
        return name + ", " + (item.placemark.country ?? "")
    }

    private func primaryLocationName(for item: MKMapItem) -> String {
        item.placemark.locality ?? item.placemark.name ?? "Unknown"
    }

    private func secondaryLocationName(for item: MKMapItem) -> String {
        let state = item.placemark.administrativeArea ?? ""
        let country = item.placemark.country ?? ""
        let parts = [state, country].filter { !$0.isEmpty }
        return parts.isEmpty ? formattedName(for: item) : parts.joined(separator: ", ")
    }

    private func cityIconName(for item: MKMapItem) -> String {
        guard let home = settings.homeLocation else { return "location" }
        let coordinate = item.placemark.coordinate
        let latitudeMatches = abs(coordinate.latitude - home.latitude) < 0.0001
        let longitudeMatches = abs(coordinate.longitude - home.longitude) < 0.0001
        return (latitudeMatches && longitudeMatches) ? "house.fill" : "location"
    }

    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }

    private func configureInitialRegion() {
        if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        } else if let current = settings.currentLocation {
            updateRegion(to: CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude))
        } else {
            updateRegion(to: kaabaCoordinate)
        }
    }

    private func search(for text: String) async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            await MainActor.run { cityItems = [] }
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        request.region = region

        let response = try? await MKLocalSearch(request: request).start()
        let items = response?.mapItems ?? []

        var seen = Set<String>()
        let uniqueItems = items.filter {
            let key = formattedName(for: $0)
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        await MainActor.run {
            cityItems = Array(uniqueItems.prefix(10))
        }
    }

    private func scheduleSearch(for text: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await search(for: text)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct MarkerItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let tint: Color
    let systemImage: String
}

private struct AnimatedMarkerBubble: View {
    let tint: Color
    let systemImage: String

    @State private var isVisible = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(9)
            .background(Circle().fill(tint))
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
            .scaleEffect(isVisible ? 1 : 0.72)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    isVisible = true
                }
            }
    }
}

private struct SearchOverlay: View {
    @EnvironmentObject private var settings: Settings

    @Binding var searchText: String
    let cityItems: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    let primaryLocationName: (MKMapItem) -> String
    let secondaryLocationName: (MKMapItem) -> String
    let cityIconName: (MKMapItem) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchHeader
            resultsList
        }
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal)
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding(-8)

            if !searchText.isEmpty {
                HStack {
                    Text("\(cityItems.count) match\(cityItems.count == 1 ? "" : "es") found")
                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 6)
                .padding(.bottom, -8)
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private var resultsList: some View {
        if !searchText.isEmpty {
            if cityItems.isEmpty {
                Text("No matches found")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(cityItems.enumerated()), id: \.offset) { _, item in
                            SearchResultRow(
                                item: item,
                                primaryTitle: primaryLocationName(item),
                                secondaryTitle: secondaryLocationName(item),
                                iconName: cityIconName(item),
                                onSelect: { onSelect(item) }
                            )
                        }
                    }
                }
                .frame(height: min(CGFloat(cityItems.count) * 76, 150))
            }
        }
    }
}

private struct SearchResultRow: View {
    @EnvironmentObject private var settings: Settings

    let item: MKMapItem
    let primaryTitle: String
    let secondaryTitle: String
    let iconName: String
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .foregroundColor(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(primaryTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(secondaryTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            Button {
                settings.hapticFeedback()
                onSelect()
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

private struct HomeLocationSummaryCard: View {
    @EnvironmentObject private var settings: Settings

    let home: Location
    let distanceString: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                locationInfoRow("Home", value: home.city, systemImage: "house.fill", accent: true)

                if let current = settings.currentLocation {
                    locationInfoRow("Current", value: current.city, systemImage: "location.fill", accent: true)

                    if let distanceString {
                        locationInfoRow("Distance", value: distanceString, systemImage: "arrow.right.arrow.left")
                            .font(.subheadline)
                    }
                }

                Text("• Must be at least 48 miles (≈ 77 km) from home to be considered traveling")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .multilineTextAlignment(.leading)
            }
            .padding()

            Spacer()
        }
        .conditionalGlassEffect(rectangle: true)
    }

    private func locationInfoRow(_ title: String, value: String, systemImage: String, accent: Bool = false) -> some View {
        Label {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(value)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .frame(width: 18)
        }
        .font(.headline)
        .foregroundColor(accent ? settings.accentColor.color : .primary)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        MapView(choosingPrayerTimes: false)
    }
}
