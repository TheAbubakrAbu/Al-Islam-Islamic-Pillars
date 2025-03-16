import SwiftUI
import MapKit

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let item: MKMapItem
}

struct MapView: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var choosingPrayerTimes: Bool
    
    @State private var showAlert = false
    @State private var searchText = ""
    @State private var cityItems = [MKMapItem]()
    @State private var selectedCityItem: IdentifiableMapItem?
    @State private var selectedCityPlacemark: MKPlacemark?
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262), // Center coordinates of the Kaaba
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    @Environment(\.colorScheme) var systemColorScheme
    @Environment(\.customColorScheme) var customColorScheme

    var currentColorScheme: ColorScheme {
        if let colorScheme = settings.colorScheme {
            return colorScheme
        } else {
            return systemColorScheme
        }
    }

    var backgroundColor: Color {
        switch currentColorScheme {
        case .light:
            return Color.white
        case .dark:
            return Color.black
        @unknown default:
            return Color.white
        }
    }

    private func fetchCities(searchText: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.cityItems = response.mapItems
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText.animation(.easeInOut))
                    .onChange(of: searchText, perform: { value in
                        fetchCities(searchText: value)
                    })
                
                if !searchText.isEmpty && !cityItems.isEmpty {
                    ScrollView {
                        ForEach(cityItems, id: \.placemark.name) { cityItem in
                            let city = (cityItem.placemark.locality ?? cityItem.placemark.name ?? "")
                            let state = cityItem.placemark.administrativeArea ?? ""
                            let fullCityName = !state.isEmpty ? "\(city), \(state)" : city
                            
                            Button(action: {
                                settings.hapticFeedback()
                                withAnimation {
                                    selectedCityItem = IdentifiableMapItem(item: cityItem)
                                    settings.homeLocation = Location(city: fullCityName, latitude: cityItem.placemark.coordinate.latitude, longitude: cityItem.placemark.coordinate.longitude)
                                    updateRegion(to: settings.homeLocation!.coordinate)
                                    searchText = ""
                                    self.endEditing()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                    
                                    Text((fullCityName) + ", " + (cityItem.placemark.country ?? ""))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(settings.accentColor.color)
                                .font(.subheadline)
                                .padding()
                            }
                        }
                        if !searchText.isEmpty && cityItems.isEmpty {
                            Text("No matches found")
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxHeight: min(CGFloat(cityItems.count) * 50, 132))
                }
                
                Map(coordinateRegion: $region, annotationItems: [selectedCityItem].compactMap { $0 }) { identifiableMapItem in
                    MapMarker(coordinate: identifiableMapItem.item.placemark.coordinate)
                }
                .edgesIgnoringSafeArea(.bottom)
                
                Spacer()
                
                if !choosingPrayerTimes, let homeLocation = settings.homeLocation {
                    HStack {
                        Spacer()
                        
                        Text("Home City: \(homeLocation.city)")
                            .font(.headline)
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                
                Button(action: {
                    settings.hapticFeedback()
                    if let currentLoc = settings.currentLocation {
                        let currentLocation = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
                        withAnimation {
                            updateRegion(to: currentLocation.coordinate)
                            selectedCityItem = IdentifiableMapItem(item: MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate)))
                            settings.homeLocation = Location(city: currentLoc.city, latitude: currentLoc.latitude, longitude: currentLoc.longitude)
                        }
                        settings.fetchPrayerTimes()
                    }
                    if (!settings.locationNeverAskAgain && settings.showLocationAlert) {
                        showAlert = true
                    }
                }) {
                    Text("Automatically Use Current Location")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(settings.accentColor.color)
                .foregroundColor(Color.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
            }
            .navigationBarTitle("Select Location", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                settings.hapticFeedback()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .foregroundColor(settings.accentColor.color)
            })
            .confirmationDialog("Location Access Denied", isPresented: $showAlert, titleVisibility: .visible) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                Button("Never Ask Again", role: .destructive) {
                    settings.locationNeverAskAgain = true
                }
                Button("Ignore", role: .cancel) { }
            } message: {
                Text("Please go to Settings and enable location services to accurately determine prayer times.")
            }
            .onAppear {
                DispatchQueue.main.async {
                    if let homeLocation = settings.homeLocation {
                        updateRegion(to: homeLocation.coordinate)
                        selectedCityPlacemark = MKPlacemark(coordinate: homeLocation.coordinate)
                        print("Home location set: \(homeLocation.city)")
                    } else if let currentLoc = settings.currentLocation {
                        let currentLocation = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
                        updateRegion(to: currentLocation.coordinate)
                        selectedCityPlacemark = MKPlacemark(coordinate: currentLocation.coordinate)
                        print("Current location set: \(currentLoc.city)")
                    } else {
                        print("Defaulting to Mecca")
                    }
                }
            }
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }
    
    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    }
}
