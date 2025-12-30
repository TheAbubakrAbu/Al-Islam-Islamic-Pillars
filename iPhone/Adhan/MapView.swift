import SwiftUI
import MapKit
import CryptoKit
import ObjectiveC.runtime

struct MapView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var sysScheme
    @Environment(\.customColorScheme) private var customScheme

    @State private var searchText = ""
    @State private var cityItems = [MKMapItem]()
    @State private var selectedItem: MKMapItem?
    @State private var showAlert = false
    @State var choosingPrayerTimes: Bool

    @State private var region = MKCoordinateRegion(
        // Kaaba
        center: .init(latitude: 21.4225, longitude: 39.8262),
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
            return .init(latitude: 21.4225, longitude: 39.8262)   // Kaaba fallback
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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                resultsList
                    .animation(.easeInOut, value: cityItems)

                let markers: [MKMapItem] = {
                    if let sel = selectedItem {
                        return [sel]
                    }
                    if let home = settings.homeLocation {
                        let pm = MKPlacemark(coordinate: home.coordinate)
                        return [MKMapItem(placemark: pm)]
                    }
                    if let cur = settings.currentLocation,
                       cur.latitude != 1000, cur.longitude != 1000 {
                        let pm = MKPlacemark(coordinate: .init(latitude: cur.latitude, longitude: cur.longitude))
                        return [MKMapItem(placemark: pm)]
                    }
                    return []
                }()

                Map(coordinateRegion: $region, annotationItems: markers) {
                    MapMarker(coordinate: $0.placemark.coordinate)
                }
                .edgesIgnoringSafeArea(.bottom)

                if !choosingPrayerTimes, let home = settings.homeLocation {
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
                    .padding(.vertical)
                }

                useCurrentButton
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
            .task(id: searchText) { await search(for: searchText) }   // debounce built‑in
            .onAppear { configureInitialRegion() }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .preferredColorScheme(scheme)
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }

    private var resultsList: some View {
        Group {
            if !searchText.isEmpty {
                if cityItems.isEmpty {
                    Text("No matches found")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .font(.subheadline)
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
                    .frame(height: min(CGFloat(cityItems.count) * 48, 300))
                }
            }
        }
    }

    private var useCurrentButton: some View {
        Button("Automatically Use Current Location") {
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
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(settings.accentColor.color)
        .foregroundColor(.white)
        .cornerRadius(24)
        .padding(.horizontal, 16)
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
        region = .init(center: coord, span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5))
    }

    private func configureInitialRegion() {
        if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        } else if let cur = settings.currentLocation {
            updateRegion(to: .init(latitude: cur.latitude, longitude: cur.longitude))
        }
    }

    private func search(for text: String) async {
        guard !text.isEmpty else { cityItems = []; return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        
        request.resultTypes = .address
        request.region = region

        let response = try? await MKLocalSearch(request: request).start()
        await MainActor.run { cityItems = response?.mapItems ?? [] }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private var placemarkUUIDKey: UInt8 = 0

private extension CLPlacemark {
    var uuid: UUID {
        if let existing = objc_getAssociatedObject(self, &placemarkUUIDKey) as? UUID {
            return existing
        }

        let key = "\(location?.coordinate.latitude ?? 0),\(location?.coordinate.longitude ?? 0)-" +
                  "\(name ?? "")-\(locality ?? "")-\(administrativeArea ?? "")-\(isoCountryCode ?? "")"

        let digest = Insecure.MD5.hash(data: Data(key.utf8))
        let uuid: UUID = digest.withUnsafeBytes { rawBuffer in
            let bytes = rawBuffer.bindMemory(to: UInt8.self)
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        }

        objc_setAssociatedObject(self, &placemarkUUIDKey, uuid, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return uuid
    }
}

extension MKMapItem: @retroactive Identifiable {
    public var id: UUID { placemark.uuid }
}

#Preview {
    MapView(choosingPrayerTimes: false)
        .environmentObject(Settings.shared)
}
