import SwiftUI
import MapKit
import CoreLocation
import UIKit

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
                    coordinate: cur.coordinate,
                    tint: .cyan,
                    systemImage: "location.fill"
                )
            )
        }

        items += results.enumerated().map { index, item in
            MarkerItem(
                id: "result-\(index)-\(item.placemark.coordinate.latitude)-\(item.placemark.coordinate.longitude)",
                coordinate: item.placemark.coordinate,
                tint: settings.accentColor.color,
                systemImage: "mappin.circle.fill"
            )
        }

        if let selectedItem {
            items.insert(
                MarkerItem(
                    id: "selected",
                    coordinate: selectedItem.placemark.coordinate,
                    tint: .green,
                    systemImage: "mappin.circle.fill"
                ),
                at: 0
            )
        }

        return items
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { item in
            MapAnnotation(coordinate: item.coordinate) {
                markerBubble(for: item)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    SearchBar(text: $searchText.animation(.easeInOut))

                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching || !results.isEmpty {
                        HStack {
                            if isSearching {
                                Text("Searching nearby masajid…")
                            } else {
                                Text("\(results.count) match\(results.count == 1 ? "" : "es") found")
                            }

                            Spacer()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .padding(.horizontal, 6)
                    }
                }
                .padding(8)

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
                    .foregroundColor(settings.accentColor.color)
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
                    .foregroundColor(settings.accentColor.color)
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
                    .conditionalGlassEffect(useColor: 0.25)
                    .padding(.horizontal, 20)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.bottom, 26)
        }
        .navigationTitle("Masjid Locator")
        .navigationBarTitleDisplayMode(.inline)
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

    private func markerBubble(for item: MarkerItem) -> some View {
        AnimatedMarkerBubble(tint: item.tint, systemImage: item.systemImage)
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
                            HStack(alignment: .top, spacing: 10) {
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

                                        if let distance = distanceFromCurrentLocation(to: item) {
                                            Label(distance, systemImage: "location")
                                                .font(.caption2)
                                                .foregroundColor(settings.accentColor.color)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    select(item)
                                }

                                Button {
                                    settings.hapticFeedback()
                                    openInMaps(item)
                                } label: {
                                    Image(systemName: "map.fill")
                                        .font(.headline)
                                        .foregroundColor(settings.accentColor.color)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .contextMenu {
                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = item.name ?? "Masjid"
                                } label: {
                                    Label("Copy Name", systemImage: "doc.on.doc")
                                }

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = formattedAddress(for: item)
                                } label: {
                                    Label("Copy Address", systemImage: "doc.on.doc")
                                }

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = fullAddress(for: item)
                                } label: {
                                    Label("Copy Full Address", systemImage: "doc.on.doc")
                                }
                            }
                        }
                    }
                }
                .frame(height: min(CGFloat(results.count) * 76, 150))
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

    private func openInMaps(_ item: MKMapItem) {
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func formattedAddress(for item: MKMapItem) -> String {
        let streetParts = [
            item.placemark.subThoroughfare,
            item.placemark.thoroughfare
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let street = streetParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = [
            street.isEmpty ? nil : street,
            item.placemark.locality,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return "Address unavailable"
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func fullAddress(for item: MKMapItem) -> String {
        let streetParts = [
            item.placemark.subThoroughfare,
            item.placemark.thoroughfare
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let street = streetParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = [
            street.isEmpty ? nil : street,
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.postalCode,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return formattedAddress(for: item)
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func distanceFromCurrentLocation(to item: MKMapItem) -> String? {
        guard let cur = settings.currentLocation,
              cur.latitude != 1000,
              cur.longitude != 1000 else { return nil }

        let here = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
        let there = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )

        let miles = here.distance(from: there) / 1_609.344
        return String(format: "%.1f miles away", miles)
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
        let queries: [String] = {
            if trimmed.isEmpty {
                return ["mosque", "masjid", "islamic center", "muslim", "rahma"]
            } else {
                return Array(NSOrderedSet(array: [
                    trimmed,
                    "\(trimmed) mosque",
                    "\(trimmed) masjid",
                    "\(trimmed) islamic",
                    "\(trimmed) islamic center",
                    "\(trimmed) muslim",
                    "\(trimmed) rahma"
                ])).compactMap { $0 as? String }
            }
        }()

        var combinedItems: [MKMapItem] = []

        for query in queries {
            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = .pointOfInterest
            request.region = region

            let response = try? await MKLocalSearch(request: request).start()
            combinedItems.append(contentsOf: response?.mapItems ?? [])
        }

        let items = combinedItems.filter { item in
            let name = (item.name ?? "").lowercased()
            let title = (item.placemark.title ?? "").lowercased()
            let keywords = ["masjid", "mosque", "islam", "islamic", "muslim", "rahma"]
            return keywords.contains { keyword in
                name.contains(keyword) || title.contains(keyword)
            }
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
