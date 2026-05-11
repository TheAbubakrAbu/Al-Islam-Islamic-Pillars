import SwiftUI
import MapKit
import CoreLocation

struct PrayerTimesMapView: View {
    @EnvironmentObject private var settings: Settings
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedLocation: Location?
    @State private var selectedDate = Date()
    @State private var prayers: [Prayer] = []
    @State private var position: MapCameraPosition = .automatic
    @State private var newCityName = ""
    @State private var geocoder = CLGeocoder()
    @State private var isLoadingPrayers = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            mapSection
            
            // Prayer times and controls overlay
            VStack(spacing: 0) {
                // Top - Prayer times info
                if let selected = selectedLocation {
                    prayerTimesPanel(for: selected)
                        .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
                
                // Bottom controls
                bottomControlsPanel
            }
            .padding()
        }
        .navigationTitle("Prayer Times Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedLocation = settings.currentLocation
            updatePrayerTimes()
            if let location = selectedLocation {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
                ))
            }
        }
        .onChange(of: selectedDate) { _ in
            updatePrayerTimes()
        }
        .onChange(of: selectedLocation) { _ in
            updatePrayerTimes()
        }
    }
    
    @ViewBuilder
    private var mapSection: some View {
        Map(position: $position) {
            // Current location marker (blue)
            if let current = settings.currentLocation {
                Annotation("Current", coordinate: current.coordinate) {
                    Image(systemName: "location.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            // Favorite locations (red)
            ForEach(settings.favoriteLocations, id: \.city) { location in
                Annotation(location.city, coordinate: location.coordinate) {
                    Image(systemName: "star.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
            
            // Selected location highlight
            if let selected = selectedLocation {
                Annotation("Selected", coordinate: selected.coordinate) {
                    Circle()
                        .stroke(settings.accentColor.color, lineWidth: 3)
                        .frame(width: 50, height: 50)
                }
            }
        }
        .mapStyle(.standard)
        .onMapCameraChange { context in
            position = context.camera
        }
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
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bottomControlsPanel: some View {
        VStack(spacing: 12) {
            // Favorite locations quick access
            if !settings.favoriteLocations.isEmpty || (settings.currentLocation != nil) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Current location button
                        if let current = settings.currentLocation {
                            favoriteButton(
                                location: current,
                                label: "Current",
                                isSelected: selectedLocation?.city == current.city
                            )
                        }
                        
                        // Favorite locations
                        ForEach(settings.favoriteLocations, id: \.city) { location in
                            favoriteButton(
                                location: location,
                                label: location.city,
                                isSelected: selectedLocation?.city == location.city
                            )
                        }
                    }
                }
            }
            
            // Manual location entry
            HStack(spacing: 8) {
                TextField("Enter city name", text: $newCityName)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                
                Button(action: addNewLocation) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }
                .disabled(newCityName.isEmpty)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func favoriteButton(location: Location, label: String, isSelected: Bool) -> some View {
        Button(action: {
            settings.hapticFeedback()
            selectedLocation = location
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            ))
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
        
        // Use geocoder to convert city name to coordinates
        geocoder.geocodeAddressString(newCityName) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let placemark = placemarks?.first,
                   let coordinate = placemark.location?.coordinate {
                    let location = Location(
                        city: self.newCityName,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    self.selectedLocation = location
                    self.position = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                    ))
                    self.newCityName = ""
                } else {
                    // If geocoding fails, create a placeholder
                    let location = Location(city: self.newCityName, latitude: 21.4225, longitude: 39.8262)
                    self.selectedLocation = location
                    self.newCityName = ""
                }
                
                self.isLoadingPrayers = false
            }
        }
    }
    
    private func updatePrayerTimes() {
        guard let location = selectedLocation else {
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
