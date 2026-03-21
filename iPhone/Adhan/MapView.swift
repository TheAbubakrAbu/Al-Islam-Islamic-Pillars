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
    }

    private var markers: [MarkerItem] {
        if let sel = selectedItem {
            return [MarkerItem(id: "selected", coordinate: sel.placemark.coordinate)]
        }
        if let home = settings.homeLocation {
            return [MarkerItem(id: "home", coordinate: home.coordinate)]
        }
        if let cur = settings.currentLocation,
           cur.latitude != 1000,
           cur.longitude != 1000 {
            return [MarkerItem(id: "current", coordinate: .init(latitude: cur.latitude, longitude: cur.longitude))]
        }
        return []
    }

    var body: some View {
        NavigationView {
            interactiveMap
            .edgesIgnoringSafeArea(.all)
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    //SearchBar(text: $searchText)
                    GlassSearchBar(searchText: $searchText.animation(.easeInOut))
                    
                    resultsList
                }
                .conditionalGlassEffect()
                .padding(.horizontal)
            }
            .safeAreaInset(edge: .bottom) {
                if !choosingPrayerTimes, let home = settings.homeLocation {
                    VStack(alignment: .leading, spacing: 8) {
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
                        .padding(8)
                        
                        useCurrentButton
                    }
                    .padding(8)
                    .conditionalGlassEffect()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { settings.hapticFeedback(); dismiss() })
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
        Map(coordinateRegion: $region, annotationItems: markers) {
            MapMarker(coordinate: $0.coordinate)
        }
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
                                Button { select(item) } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                        Text(formattedName(for: item))
                                        Spacer()
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                    .padding()
                                }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(cityItems.count) * 55, 300))
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
        .background(buttonBackground)
    }
    
    private var buttonBackground: some View {
        if #available(iOS 26.0, *) {
            AnyView(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.clear)
                    .glassEffect(.regular.tint(settings.accentColor.color.opacity(0.15)).interactive(), in: .rect(cornerRadius: 24))
            )
        } else {
            AnyView(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(settings.accentColor.color.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
                    )
            )
        }
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
