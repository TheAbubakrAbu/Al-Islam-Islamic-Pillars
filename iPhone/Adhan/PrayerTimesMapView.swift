#if os(iOS)
import SwiftUI
import MapKit
import CoreLocation

struct PrayerTimesMapView: View {
    @EnvironmentObject private var settings: Settings
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedLocation: Location?
    @State private var prayerLocationMode: PrayerLocationMode = .automatic
    @State private var selectedDate = Date()
    @State private var prayers: [Prayer] = []
    @State private var region: MKCoordinateRegion
    @State private var newCityName = ""
    @State private var geocoder = CLGeocoder()
    @State private var isLoadingPrayers = false
    @State private var showingLocationChoiceDialog = false
    @State private var showMap = false
    
    init() {
        let coordinate = CLLocationCoordinate2D(latitude: 21.422445, longitude: 39.826388)
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        ))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                locationSummaryCard

                if prayerLocationMode == .manual {
                    manualLocationCard
                }

                favoriteCitiesCard

                mapToggleCard

                if showMap {
                    mapSection
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .conditionalGlassEffect(rectangle: true, useColor: 0.14)
                }

                if let location = effectiveLocation {
                    prayerTimesPanel(for: location)
                } else {
                    emptyLocationCard
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [settings.accentColor.color.opacity(0.14), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Choose Prayer Location", isPresented: $showingLocationChoiceDialog, titleVisibility: .visible) {
            Button("Automatically from Phone Location") {
                useAutomaticLocation()
            }

            Button("Select Manually") {
                prayerLocationMode = .manual
                if selectedLocation == nil {
                    selectedLocation = settings.currentLocation
                }
                updatePrayerTimes()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Use your phone location or pick a city manually.")
        }
        .onAppear {
            useAutomaticLocation()
            updatePrayerTimes()
            if let location = effectiveLocation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
                )
            }
        }
        .onChange(of: selectedDate) { _ in
            updatePrayerTimes()
        }
        .onChange(of: selectedLocation) { _ in
            updatePrayerTimes()
            if let location = effectiveLocation {
                withAnimation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: region.span
                    )
                }
            }
        }
        .onChange(of: prayerLocationMode) { _ in
            updatePrayerTimes()
        }
        .onChange(of: settings.currentLocation) { _ in
            if prayerLocationMode == .automatic {
                useAutomaticLocation()
            }
        }
//        .onChange(of: locationManager.location) { _ in
//            if prayerLocationMode == .automatic, settings.currentLocation == nil {
//                useAutomaticLocation()
//            }
//        }
    }

    private enum PrayerLocationMode {
        case automatic
        case manual
    }

    private var effectiveLocation: Location? {
        switch prayerLocationMode {
        case .automatic:
            if let current = settings.currentLocation {
                return current
            }
            if let location = locationManager.location {
                return Location(city: "Current Location", latitude: location.latitude, longitude: location.longitude)
            }
            return selectedLocation
        case .manual:
            return selectedLocation ?? settings.currentLocation
        }
    }

    @ViewBuilder
    private var locationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(effectiveLocation?.city ?? "No location selected")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(prayerLocationMode == .automatic ? "Using phone location" : "Manual city selection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    settings.hapticFeedback()
                    showingLocationChoiceDialog = true
                } label: {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundStyle(settings.accentColor.color)
                }
            }

            HStack {
                Label(dateFormatter.string(from: selectedDate), systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    showingLocationChoiceDialog = true
                } label: {
                    Text("Choose Prayer Location")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(settings.accentColor.color)
            }
        }
        .padding(16)
        .conditionalGlassEffect(rectangle: true, useColor: 0.14)
    }

    @ViewBuilder
    private var manualLocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a City")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("Enter city name", text: $newCityName)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)

                Button(action: addNewLocation) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(settings.accentColor.color)
                }
                .disabled(newCityName.isEmpty)
            }

            Text("You can also tap a favorite city below.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .conditionalGlassEffect(rectangle: true, useColor: 0.14)
    }

    @ViewBuilder
    private var favoriteCitiesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite Cities")
                .font(.headline)

            if !settings.favoriteLocations.isEmpty || settings.currentLocation != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let current = settings.currentLocation {
                            favoriteButton(
                                location: current,
                                label: "Current",
                                isSelected: effectiveLocation?.city == current.city
                            )
                        }

                        ForEach(settings.favoriteLocations, id: \.city) { location in
                            favoriteButton(
                                location: location,
                                label: location.city,
                                isSelected: effectiveLocation?.city == location.city
                            )
                        }
                    }
                }
            } else {
                Text("Save cities from the map or add one manually to see them here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .conditionalGlassEffect(rectangle: true, useColor: 0.14)
    }

    @ViewBuilder
    private var mapToggleCard: some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                showMap.toggle()
            }
        } label: {
            HStack {
                Label(showMap ? "Hide Map" : "Open Map", systemImage: showMap ? "map.fill" : "map")
                    .font(.headline)
                Spacer()
                Image(systemName: showMap ? "chevron.up" : "chevron.down")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(settings.accentColor.color)
            .padding(16)
        }
        .buttonStyle(.plain)
        .conditionalGlassEffect(rectangle: true, useColor: 0.14)
    }

    @ViewBuilder
    private var emptyLocationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No prayer location available")
                .font(.headline)
            Text("Choose automatic location or enter a city manually.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .conditionalGlassEffect(rectangle: true, useColor: 0.14)
    }
    
    @ViewBuilder
    private var mapSection: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack(spacing: 4) {
                    Image(systemName: item.imageName)
                        .font(.title)
                        .foregroundColor(item.color)
                    
                    if item.title == "Selected" {
                        Circle()
                            .stroke(settings.accentColor.color, lineWidth: 3)
                            .frame(width: 50, height: 50)
                    }
                }
            }
        }
    }
    
    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        
        // Current location
        if let current = settings.currentLocation {
            items.append(MapAnnotationItem(coordinate: current.coordinate, title: "Current", imageName: "location.circle.fill", color: .blue))
        }
        
        // Favorite locations
        for location in settings.favoriteLocations {
            items.append(MapAnnotationItem(coordinate: location.coordinate, title: location.city, imageName: "star.circle.fill", color: .red))
        }
        
        // Selected location
        if let selected = selectedLocation {
            items.append(MapAnnotationItem(coordinate: selected.coordinate, title: "Selected", imageName: "mappin.circle.fill", color: settings.accentColor.color))
        }
        
        return items
    }
    
    private struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let title: String
        let imageName: String
        let color: Color
    }
    
    @ViewBuilder
    private func prayerTimesPanel(for location: Location) -> some View {
        VStack(spacing: 12) {
            // Header with city name and favorite button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.city)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    settings.hapticFeedback()
                    toggleFavorite(location)
                } label: {
                    Image(systemName: isFavorite(location) ? "star.fill" : "star")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }
            }
            .padding(.bottom, 4)
            
            // Date picker
            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .foregroundColor(settings.accentColor.color)
            
            Divider()
            
            // Prayer times list or loading state
            if isLoadingPrayers {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if prayers.isEmpty {
                Text("Unable to load prayer times for this location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(prayers, id: \.id) { prayer in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prayer.nameEnglish)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(prayer.nameArabic)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(timeFormatter.string(from: prayer.time))
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundColor(settings.accentColor.color)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(12)
        .conditionalGlassEffect(rectangle: true, useColor: 0.16)
    }
    
    @ViewBuilder
    private func favoriteButton(location: Location, label: String, isSelected: Bool) -> some View {
        Button(action: {
            settings.hapticFeedback()
            prayerLocationMode = .manual
            selectedLocation = location
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                )
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? settings.accentColor.color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
    }
    
    private func toggleFavorite(_ location: Location) {
        if isFavorite(location) {
            settings.favoriteLocations.removeAll { $0.city == location.city }
        } else {
            settings.favoriteLocations.append(location)
        }
    }
    
    private func isFavorite(_ location: Location) -> Bool {
        settings.favoriteLocations.contains(where: { $0.city == location.city })
    }
    
    private func addNewLocation() {
        guard !newCityName.isEmpty else { return }
        
        isLoadingPrayers = true
        prayerLocationMode = .manual
        
        // Use geocoder to convert city name to coordinates
        let cityName = newCityName
        geocoder.geocodeAddressString(cityName) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first,
                   let coordinate = placemark.location?.coordinate {
                    let location = Location(
                        city: cityName,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    self.selectedLocation = location
                    withAnimation {
                        self.region = MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                        )
                    }
                    self.newCityName = ""
                } else {
                    // If geocoding fails, create a placeholder
                    let location = Location(city: cityName, latitude: 21.4225, longitude: 39.8262)
                    self.selectedLocation = location
                    self.newCityName = ""
                }
                
                self.isLoadingPrayers = false
            }
        }
    }

    private func useAutomaticLocation() {
        prayerLocationMode = .automatic

        if let current = settings.currentLocation {
            selectedLocation = current
        } else if let location = locationManager.location {
            selectedLocation = Location(city: "Current Location", latitude: location.latitude, longitude: location.longitude)
        }

        if let location = effectiveLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
                )
            }
        }
        updatePrayerTimes()
    }
    
    private func updatePrayerTimes() {
        guard let location = effectiveLocation else {
            prayers = []
            return
        }
        
        isLoadingPrayers = true
        
        // Temporarily swap the location to get prayer times for the selected city
        let originalLocation = settings.currentLocation
        settings.currentLocation = location
        
        // Get prayer times for the selected date
        if let times = settings.getPrayerTimes(for: selectedDate, fullPrayers: false) {
            prayers = times
        } else {
            prayers = []
        }
        
        // Restore the original location
        if let original = originalLocation {
            settings.currentLocation = original
        }
        
        isLoadingPrayers = false
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// Helper class for location management
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location.coordinate
    }
}

#Preview {
    PrayerTimesMapView()
        .environmentObject(Settings.shared)
}
#endif
