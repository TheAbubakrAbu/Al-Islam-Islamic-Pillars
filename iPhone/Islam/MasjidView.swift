import SwiftUI
import MapKit
import CoreLocation

struct MasjidLocatorView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var sysScheme

    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State private var selectedItem: MKMapItem?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    @State private var region = MKCoordinateRegion(
        center: .init(latitude: 21.422445, longitude: 39.826388),
        span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    private var scheme: ColorScheme { settings.colorScheme ?? sysScheme }

    init() {
        let coord: CLLocationCoordinate2D = {
            let s = Settings.shared
            if let cur = s.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
                return cur.coordinate
            }
            if let home = s.homeLocation {
                return home.coordinate
            }
            return .init(latitude: 21.422445, longitude: 39.826388)
        }()

        _region = State(initialValue: MKCoordinateRegion(
            center: coord,
            span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
        ))
    }

    private struct MarkerItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let tint: Color
    }

    private var markers: [MarkerItem] {
        var items: [MarkerItem] = []

        if let cur = settings.currentLocation,
           cur.latitude != 1000,
           cur.longitude != 1000 {
            items.append(
                MarkerItem(
                    id: "current",
                    coordinate: cur.coordinate,
                    tint: .blue
                )
            )
        }

        items += results.enumerated().map { index, item in
            MarkerItem(
                id: "result-\(index)-\(item.placemark.coordinate.latitude)-\(item.placemark.coordinate.longitude)",
                coordinate: item.placemark.coordinate,
                tint: settings.accentColor.color
            )
        }

        if let selectedItem {
            items.insert(
                MarkerItem(
                    id: "selected",
                    coordinate: selectedItem.placemark.coordinate,
                    tint: .green
                ),
                at: 0
            )
        }

        return items
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { item in
            MapMarker(coordinate: item.coordinate, tint: item.tint)
        }
        .edgesIgnoringSafeArea(.all)
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                GlassSearchBar(searchText: $searchText.animation(.easeInOut))

                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching || !results.isEmpty {
                    resultsPanel
                }
            }
            .conditionalGlassEffect(rectangle: true)
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        settings.hapticFeedback()
                        scheduleSearch(for: searchText, force: true)
                    } label: {
                        Label("Search This Area", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(18)
                    .conditionalGlassEffect()

                    Button {
                        settings.hapticFeedback()
                        centerOnCurrentLocation()
                        scheduleSearch(for: searchText, force: true)
                    } label: {
                        Label("Near Me", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(18)
                    .conditionalGlassEffect()
                }
                .padding(.horizontal, 20)

                if let selectedItem {
                    Button {
                        settings.hapticFeedback()
                        selectedItem.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                        ])
                    } label: {
                        Label("Open Directions to \(selectedItem.name ?? "Masjid")", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(18)
                    .conditionalGlassEffect()
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Masjid Locator")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Done") { settings.hapticFeedback(); dismiss() })
        .onAppear {
            configureInitialRegion()
            scheduleSearch(for: "", force: true)
        }
        .onChange(of: searchText) { newValue in
            scheduleSearch(for: newValue, force: false)
        }
        .preferredColorScheme(scheme)
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }

    private var resultsPanel: some View {
        Group {
            if isSearching {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Searching nearby masajid…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if results.isEmpty {
                Text("No masajid found in this area")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                            Button {
                                select(item)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(settings.accentColor.color)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name ?? "Masjid")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)

                                        Text(formattedAddress(for: item))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                }
                                .padding()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: min(CGFloat(results.count) * 76, 320))
            }
        }
    }

    private func centerOnCurrentLocation() {
        if let cur = settings.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
            updateRegion(to: cur.coordinate)
        } else if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        }
    }

    private func select(_ item: MKMapItem) {
        settings.hapticFeedback()
        withAnimation {
            selectedItem = item
            updateRegion(to: item.placemark.coordinate)
        }
    }

    private func formattedAddress(for item: MKMapItem) -> String {
        let parts = [
            item.placemark.title,
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return "Address unavailable"
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func updateRegion(to coord: CLLocationCoordinate2D) {
        region = .init(center: coord, span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08))
    }

    private func configureInitialRegion() {
        centerOnCurrentLocation()
    }

    private func search(for text: String) async {
        await MainActor.run { isSearching = true }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = trimmed.isEmpty ? "mosque" : "\(trimmed) mosque"

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = region

        let response = try? await MKLocalSearch(request: request).start()
        let items = (response?.mapItems ?? []).filter { item in
            let name = (item.name ?? "").lowercased()
            let title = (item.placemark.title ?? "").lowercased()
            return name.contains("masjid") || name.contains("mosque") || title.contains("masjid") || title.contains("mosque")
        }

        var seen = Set<String>()
        let unique = items.filter { item in
            let key = "\(item.name ?? "")|\(item.placemark.coordinate.latitude)|\(item.placemark.coordinate.longitude)"
            return seen.insert(key).inserted
        }

        await MainActor.run {
            results = Array(unique.prefix(12))
            isSearching = false
            if selectedItem == nil {
                selectedItem = results.first
            }
        }
    }

    private func scheduleSearch(for text: String, force: Bool) {
        searchTask?.cancel()
        searchTask = Task {
            if !force {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard !Task.isCancelled else { return }
            await search(for: text)
        }
    }
}

#Preview {
    MasjidLocatorView()
        .environmentObject(Settings.shared)
}
