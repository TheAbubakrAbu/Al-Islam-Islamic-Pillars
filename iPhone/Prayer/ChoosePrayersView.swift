import SwiftUI

struct ChoosePrayerView: View {
    @EnvironmentObject var settings: Settings
    
    @State private var showingMapSheet = false
    
    @AppStorage("currentPrayerCity") var currentPrayerCity: String?
    
    var body: some View {
        List {
            if let prayersObject = settings.prayers, !prayersObject.prayers.isEmpty {
                let currentPrayers = prayersObject.prayers
                List(currentPrayers) { prayer in
                    VStack(alignment: .leading) {
                        Text("\(prayer.nameEnglish) (\(prayer.nameTransliteration))")
                            .font(.headline)
                        Text(prayer.time, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .listStyle(.plain)
            } else {
                Text("No prayer times available.")
                    .padding()
            }
        }
        .navigationTitle("Choose Prayer Times")
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    settings.hapticFeedback()
                    showingMapSheet = true
                }) {
                    Label("Pick Location", systemImage: "mappin.circle")
                }
            }
        }
        .sheet(isPresented: $showingMapSheet) {
            MapView(choosingPrayerTimes: true)
        }
        .onAppear {
            if currentPrayerCity == nil, let currentLocation = settings.currentLocation {
                currentPrayerCity = currentLocation.city
            }
        }
    }
}
