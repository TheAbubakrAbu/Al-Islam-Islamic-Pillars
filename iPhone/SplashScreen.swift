import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var settings: Settings
            
    var body: some View {
        NavigationView {
            VStack {
                Text("Al-Islam is an all in one Muslim companion app that includes prayer times, qibla direction, Quran, basic knowledge and tools about Islam, the Arabic alphabet, and much more, all being completely customizable!\n\nThis app is completely privacy-focused, and absolutely no data leaves the device. There are no ads, subscriptions, or fees to use this app.")
                    .font(.title)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
                    .padding()
                
                Spacer()
                
                Image("Al-Islam")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .cornerRadius(10)
                
                Spacer()
                
                NavigationLink(destination: Splash2View()) {
                    Text("Next")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(settings.accentColor.color)
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Assalamu Alaikum")
        }
        .navigationViewStyle(.stack)
    }
}

struct Splash2View: View {
    @EnvironmentObject var settings: Settings
    
    @State var showAlert = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "location.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Getting your location")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Using your location will allow the app to accurately determine prayer times without any data leaving your device")
                .font(.title3)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .padding()
            
            Spacer()
            
            VStack(spacing: -20) {
                Image(systemName: "mappin")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 100, height: 100)
                    .padding(.horizontal)
                    .padding(.top)
                
                Text("🕋")
                    .foregroundColor(settings.accentColor.color)
                    .font(.system(size: 100))
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .padding(.top)
            
            Spacer()
            
            HStack {
                if settings.currentLocation != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .foregroundColor(settings.accentColor.color)
                    
                    Text("Location access succesfully granted")
                } else if settings.showLocationAlert {
                    Image(systemName: "location.slash.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .foregroundColor(settings.accentColor.color)
                    
                    Text("Location access denied")
                }
            }
            .padding()
            .transition(.opacity)
            
            Button(action: {
                settings.hapticFeedback()
                
                settings.requestLocationAuthorization()
                settings.fetchPrayerTimes()
                
                if !settings.locationNeverAskAgain && settings.showLocationAlert {
                    showAlert = true
                }
            }) {
                Text("Current Location")
            }
            .padding()
            .background(settings.accentColor.color)
            .foregroundColor(.primary)
            .cornerRadius(10)
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
        
            NavigationLink(destination: Splash3View()) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Location")
    }
}

struct Splash3View: View {
    @EnvironmentObject var settings: Settings
    
    @State private var showingMap = false
        
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Choose your home city")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Your home city is used to automatically determine whether or not you're traveling to shorten your prayers and use Qasr. If you are traveling more than 48 mi (77.25 km), then it is obligatory to pray Qasr, where you combine Dhuhr and Asr (2 rakahs each) and Maghrib and Isha (3 and 2 rakahs)")
                .font(.title3)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
            
            List {
                if let home = settings.homeLocation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(settings.accentColor.color)
                        
                        Text(home.city)
                            .font(.headline)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .transition(.opacity)
                }
                
                Toggle("Traveling Mode Turns on Automatically", isOn: $settings.travelAutomatic.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                
                Toggle("Traveling Mode", isOn: $settings.travelingMode.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
            }
            .applyConditionalListStyle(defaultView: true)
            
            Button(action: {
                settings.hapticFeedback()
                
                showingMap = true
            }) {
                Text("Choose Location")
            }
            .padding()
            .background(settings.accentColor.color)
            .foregroundColor(.primary)
            .cornerRadius(10)
            .sheet(isPresented: $showingMap) {
                MapView(showingMap: $showingMap)
                    .environmentObject(settings)
            }
            
            Spacer()
            
            NavigationLink(destination: Splash4View()) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .onAppear {
            if let currentLoc = settings.currentLocation {
                let currentCity = currentLoc.city
                print("Home location set to current location")
                settings.homeLocation = Location(city: currentCity, latitude: currentLoc.latitude, longitude: currentLoc.longitude)
            }
        }
        .navigationTitle("Home City")
    }
}

struct Splash4View: View {
    @EnvironmentObject var settings: Settings
    
    let calculationOptions: [(String, String)] = [
        ("Muslim World League", "Muslim World League"),
        ("Moonsight Committee", "Moonsight Committee"),
        ("Umm Al-Qura", "Umm Al-Qura"),
        ("Egypt", "Egypt"),
        ("Dubai", "Dubai"),
        ("Kuwait", "Kuwait"),
        ("Qatar", "Qatar"),
        ("Turkey", "Turkey"),
        ("Tehran", "Tehran"),
        ("Karachi", "Karachi"),
        ("Singapore", "Singapore"),
        ("North America", "North America")
    ]
            
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Choose a prayer calculation")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            
            List {
                VStack(alignment: .leading) {
                    Picker("Calculation", selection: $settings.prayerCalculation.animation(.easeInOut)) {
                        ForEach(calculationOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    
                    Text("The different calculation methods calculate Fajr and Isha differently.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                }
                
                VStack(alignment: .leading) {
                    Toggle("Use Hanafi Calculation for Asr", isOn: $settings.hanafiMadhab.animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                    
                    Text("The Hanafi madhab uses later calculations for Asr.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                }
            }
            .applyConditionalListStyle(defaultView: true)
            
            NavigationLink(destination: Splash5View()) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Prayer Calculation")
    }
}

struct Splash5View: View {
    @EnvironmentObject var settings: Settings
    
    @State var showAlert = false
    @State var clicked = false
        
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "bell.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Allow notifications to know when to pray")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                if clicked {
                    if !settings.showNotificationAlert {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(settings.accentColor.color)
                        
                        Text("Notification access succesfully granted")
                    } else if settings.showNotificationAlert {
                        Image(systemName: "location.slash.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(settings.accentColor.color)
                        
                        Text("Notification access denied")
                    }
                }
            }
            .padding()
            .transition(.opacity)
            
            Button(action: {
                settings.hapticFeedback()
                
                settings.requestNotificationAuthorization {
                    settings.fetchPrayerTimes()
                    if !settings.notificationNeverAskAgain && settings.showNotificationAlert {
                        showAlert = true
                    }
                    withAnimation {
                        clicked = true
                    }
                }
            }) {
                Text("Allow Notifications")
            }
            .padding()
            .background(settings.accentColor.color)
            .foregroundColor(.primary)
            .cornerRadius(10)
            .confirmationDialog("Notifications Denied", isPresented: $showAlert, titleVisibility: .visible) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                Button("Never Ask Again", role: .destructive) {
                    settings.notificationNeverAskAgain = true
                }
                Button("Ignore", role: .cancel) { }
            } message: {
                Text("Please go to Settings and enable notifications to be notified of prayer times.")
            }
            
            NavigationLink(destination: (settings.prayers == nil ? AnyView(Splash7View()) : AnyView(Splash6View()))) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct Splash6View: View {
    @EnvironmentObject var settings: Settings
        
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "bell")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Choose notifications to know when it is time to pray")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                settings.fetchPrayerTimes()
            }
            
            List {
                Text("Tap the bell icon or long-press on a specific prayer to adjust its notification settings. You can further change this in settings.")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                
                PrayerList()
            }
            .applyConditionalListStyle(defaultView: true)
            
            NavigationLink(destination: Splash7View()) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Prayer Times")
    }
}

struct Splash7View: View {
    @EnvironmentObject var settings: Settings
        
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Customize different settings")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            
            SettingsView()
            
            NavigationLink(destination: Splash8View()) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Settings")
    }
}

struct Splash8View: View {
    @EnvironmentObject var settings: Settings
        
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 30, height: 30)
                
                Text("Credits and Special Thanks")
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding(.horizontal)
            
            CreditsView()
            
            Button(action: {
                settings.hapticFeedback()
                
                settings.fetchPrayerTimes()
                
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation {
                        settings.firstLaunch = false
                    }
                }
            }) {
                Text("Done")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(settings.accentColor.color)
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Credits")
    }
}
