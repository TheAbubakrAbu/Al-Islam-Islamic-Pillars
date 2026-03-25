import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var sysScheme
    @Environment(\.customColorScheme) private var customScheme

    @State private var searchText = ""
    @State private var cityItems = [MKMapItem]()
    @State private var selectedItem: MKMapItem?
    @State private var showAlert = false
    @State private var searchTask: Task<Void, Never>?
    @State var choosingPrayerTimes: Bool

    @State private var region = MKCoordinateRegion(
        // Kaaba
        center: .init(latitude: 21.422445, longitude: 39.826388),
        span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    private var scheme: ColorScheme { settings.colorScheme ?? sysScheme }
    
    init(choosingPrayerTimes: Bool) {
        _choosingPrayerTimes = State(initialValue: choosingPrayerTimes)

        let coord: CLLocationCoordinate2D = {
            let s = Settings.shared
            if let home = s.homeLocation {
                return home.coordinate
            }
            if let cur  = s.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
                return cur.coordinate
            }
            return .init(latitude: 21.422445, longitude: 39.826388)   // Kaaba fallback
        }()

        _region = State(initialValue:
            MKCoordinateRegion(center: coord, span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5))
        )
    }
    
    private var distanceString: String? {
        guard
            let cur  = settings.currentLocation,
            let home = settings.homeLocation,
            cur.latitude  != 1000, cur.longitude  != 1000
        else { return nil }

        let here   = CLLocation(latitude: cur.latitude,  longitude: cur.longitude)
        let there  = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let meters = here.distance(from: there)

        let km    = meters / 1_000
        let miles = meters / 1_609.344

        let nf = NumberFormatter()
        nf.maximumFractionDigits = 1

        guard
            let kmStr   = nf.string(from: km as NSNumber),
            let miStr   = nf.string(from: miles as NSNumber)
        else { return nil }

        return "\(miStr) mi / \(kmStr) km"
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

    private var markers: [MarkerItem] {
        var items: [MarkerItem] = []

        if let cur = settings.currentLocation,
           cur.latitude != 1000,
           cur.longitude != 1000 {
            items.append(
                MarkerItem(
                    id: "current",
                    coordinate: .init(latitude: cur.latitude, longitude: cur.longitude),
                    tint: .cyan,
                    systemImage: "location.fill"
                )
            )
        }

        if let sel = selectedItem {
            items.append(
                MarkerItem(
                    id: "selected",
                    coordinate: sel.placemark.coordinate,
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

    var body: some View {
        NavigationView {
            interactiveMap
            .edgesIgnoringSafeArea(.all)
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        GlassSearchBar(text: $searchText.animation(.easeInOut))

                        if !searchText.isEmpty {
                            HStack {
                                Text("\(cityItems.count) match\(cityItems.count == 1 ? "" : "es") found")
                                Spacer()
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .padding(.horizontal, 6)
                        }
                    }
                    .padding(8)

                    resultsList
                }
                .conditionalGlassEffect(rectangle: true)
                .padding(.horizontal)
            }
            .safeAreaInset(edge: .bottom) {
                if !choosingPrayerTimes, let home = settings.homeLocation {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Home: \(home.city)", systemImage: "house.fill")
                                    .font(.headline)
                                    .foregroundColor(settings.accentColor.color)
                                
                                if let current = settings.currentLocation {
                                    Label("Current: \(current.city)", systemImage: "location.fill")
                                        .font(.headline)
                                        .foregroundColor(settings.accentColor.color)
                                    
                                    if let distance = distanceString {
                                        Label(distance, systemImage: "arrow.right.arrow.left")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
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
                        
                        useCurrentButton
                    }
                    .padding(.bottom, 26)
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { settings.hapticFeedback(); dismiss() })
            .dismissKeyboardOnScroll()
            .confirmationDialog(
                "Location Access Denied",
                isPresented: $showAlert
            ) {
                Button("Open Settings")  { openSettings() }
                Button("Never Ask Again", role: .destructive) { settings.locationNeverAskAgain = true }
                Button("Ignore", role: .cancel) { }
            } message: {
                Text("Please enable location services to accurately determine prayer times.")
            }
            .onChange(of: searchText) { newText in
                scheduleSearch(for: newText)
            }
            .onAppear { configureInitialRegion() }
            .preferredColorScheme(scheme)
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }

    @ViewBuilder
    private var interactiveMap: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { item in
            MapAnnotation(coordinate: item.coordinate) {
                markerBubble(for: item)
            }
        }
    }

    private func markerBubble(for item: MarkerItem) -> some View {
        AnimatedMarkerBubble(tint: item.tint, systemImage: item.systemImage)
    }

    private var resultsList: some View {
        Group {
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
                                HStack(alignment: .top, spacing: 10) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: cityIconName(for: item))
                                            .foregroundColor(settings.accentColor.color)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(primaryLocationName(for: item))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)

                                            Text(secondaryLocationName(for: item))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        select(item)
                                    }

                                    Button {
                                        settings.hapticFeedback()
                                        select(item)
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
                    }
                    .frame(height: min(CGFloat(cityItems.count) * 76, 150))
                }
            }
        }
    }

    private var useCurrentButton: some View {
        Button {
            settings.hapticFeedback()
            guard let cur = settings.currentLocation else { return }

            withAnimation {
                let coord = CLLocationCoordinate2D(latitude: cur.latitude, longitude: cur.longitude)
                updateRegion(to: coord)
                let placemark = MKPlacemark(coordinate: coord)
                let mapItem = MKMapItem(placemark: placemark)
                selectedItem = mapItem
                settings.homeLocation = Location(city: cur.city, latitude: cur.latitude, longitude: cur.longitude)
            }
            settings.fetchPrayerTimes() {
                if !settings.locationNeverAskAgain && settings.showLocationAlert { showAlert = true }
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
        let city  = item.placemark.locality ?? item.placemark.name ?? "Unknown"
        let state = item.placemark.administrativeArea ?? ""
        let full  = state.isEmpty ? city : "\(city), \(state)"

        withAnimation {
            selectedItem = item
            settings.homeLocation = Location(city: full, latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            updateRegion(to: item.placemark.coordinate)
            searchText = ""
        }
    }

    private func formattedName(for item: MKMapItem) -> String {
        let city  = item.placemark.locality ?? item.placemark.name ?? ""
        let state = item.placemark.administrativeArea ?? ""
        let name  = state.isEmpty ? city : "\(city), \(state)"
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
        let coord = item.placemark.coordinate
        let latMatches = abs(coord.latitude - home.latitude) < 0.0001
        let lonMatches = abs(coord.longitude - home.longitude) < 0.0001
        return (latMatches && lonMatches) ? "house.fill" : "location"
    }

    private func updateRegion(to coord: CLLocationCoordinate2D) {
        region = .init(center: coord, span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2))
    }

    private func configureInitialRegion() {
        if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        } else if let cur = settings.currentLocation {
            updateRegion(to: .init(latitude: cur.latitude, longitude: cur.longitude))
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
        let unique = items.filter {
            let key = formattedName(for: $0)
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
        await MainActor.run { cityItems = Array(unique.prefix(10)) }
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

#Preview {
    MapView(choosingPrayerTimes: false)
        .environmentObject(Settings.shared)
}
