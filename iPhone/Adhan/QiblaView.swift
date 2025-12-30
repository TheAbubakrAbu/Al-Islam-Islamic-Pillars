import SwiftUI
import CoreLocation
import Combine
import Adhan
#if os(iOS)
import UIKit
#endif

struct QiblaView: View {
    @EnvironmentObject var settings: Settings
    var size: CGFloat = 50

    @StateObject private var compass: LocalQiblaCompass

    #if os(iOS)
    @State private var lastAngle: Double = 0
    @State private var lastHapticTime: TimeInterval = 0
    @State private var impact = UIImpactFeedbackGenerator(style: .light)
    private let notify = UINotificationFeedbackGenerator()
    #endif

    init(size: CGFloat = 50) {
        self.size = size
        _compass = StateObject(wrappedValue: LocalQiblaCompass {
            Settings.shared.currentLocation
        })
    }

    private func angularDistance(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d < -180 { d += 360 }
        if d >  180 { d -= 360 }
        return abs(d)
    }
    private func shortestDelta(from a: Double, to b: Double) -> Double {
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    private var distToQibla: Double { angularDistance(compass.direction, 0) }
    private var arrowColour: Color { distToQibla <=  5 ? settings.accentColor.color : .primary }
    private var ringColour:  Color { distToQibla <= 20 ? settings.accentColor.color : .primary }

    var body: some View {
        let arrowW = max(10, size * 0.18)
        let arrowH = max(30, size * 0.55)
        let kaaba  = max(20, size * 0.40)

        let score = 1.0 - (min(20.0, distToQibla) / 20.0)

        ZStack {
            GlassyQiblaRing(size: size, tint: ringColour, alignmentScore: score)

            VStack(spacing: -(size * 0.40)) {
                QiblaArrow(width: arrowW, height: arrowH, tint: arrowColour)
                Text("🕋")
                    .font(.system(size: kaaba))
                    .shadow(color: .black.opacity(0.25),
                            radius: max(0.6, kaaba * 0.08), x: 0, y: 0)
            }
            .padding(.vertical, size * 0.16)
        }
        .padding(.trailing, -12)
        .rotationEffect(.degrees(compass.direction))
        .animation(nil, value: compass.direction)
        .onAppear {
            compass.start()
            #if os(iOS)
            lastAngle = compass.direction
            lastHapticTime = ProcessInfo.processInfo.systemUptime
            impact.prepare()
            notify.prepare()
            #endif
        }
        .onDisappear { compass.stop() }
        #if os(iOS)
        .onChange(of: compass.direction) { newAngle in
            guard size > 50 else { return }

            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastHapticTime >= 0.08 else { return }

            let delta = shortestDelta(from: lastAngle, to: newAngle)
            let absDelta = abs(delta)

            let dist = angularDistance(newAngle, 0)

            let step = max(3.0, min(12.0, dist / 2.0))

            if absDelta >= step {
                let proximity = max(0.0, min(1.0, (30.0 - dist) / 30.0))
                let intensity = CGFloat(0.3 + 0.7 * proximity)

                if dist <= 5 {
                    notify.notificationOccurred(.success)
                    notify.prepare()
                } else {
                    impact.impactOccurred(intensity: intensity)
                    impact.prepare()
                }

                lastHapticTime = now
                lastAngle = newAngle
            }
        }
        #endif
    }
}

struct GlassyQiblaRing: View {
    let size: CGFloat
    let tint: Color
    let alignmentScore: Double

    @ViewBuilder
    private var glassFill: some View {
        #if os(watchOS)
        Circle().fill(Color.white.opacity(0.18))
        #else
        Circle().fill(.ultraThinMaterial)
        #endif
    }

    var body: some View {
        let ringWidth   = max(1, size * 0.045)
        let glossWidth  = size * 0.16
        let outerGlowW  = size * 0.085
        let shadowR     = max(1, size * 0.10)
        let innerLine   = max(1, size * 0.06)
        let innerBlur   = max(0.5, size * 0.04)

        ZStack {
            glassFill
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.14), lineWidth: innerLine)
                        .blur(radius: innerBlur)
                        .mask(Circle().stroke(lineWidth: innerLine))
                )
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55),
                                         Color.white.opacity(0.12),
                                         .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .blur(radius: max(0.5, size * 0.06))
                        .scaleEffect(0.98)
                        .mask(
                            Circle()
                                .inset(by: glossWidth * 0.35)
                                .trim(from: 0, to: 0.58)
                                .stroke(style: .init(lineWidth: glossWidth, lineCap: .round))
                        )
                )
                .shadow(color: Color.black.opacity(0.18), radius: shadowR, x: 0, y: max(0.5, size * 0.04))

            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            tint.opacity(0.95),
                            Color.white.opacity(0.75),
                            tint.opacity(0.95)
                        ]),
                        center: .center
                    ),
                    lineWidth: ringWidth
                )

            Circle()
                .stroke(tint.opacity(0.25 + 0.45 * alignmentScore), lineWidth: outerGlowW)
                .blur(radius: max(0.6, size * 0.05))
                .mask(Circle().stroke(lineWidth: outerGlowW))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .compositingGroup()
        .scaleEffect(1.0 + 0.03 * alignmentScore)
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: alignmentScore)
    }
}

struct QiblaArrow: View {
    let width: CGFloat
    let height: CGFloat
    let tint: Color

    var body: some View {
        Image(systemName: "arrow.up")
            .resizable()
            .frame(width: width, height: height)
            .foregroundStyle(
                LinearGradient(
                    colors: [tint.opacity(0.95), tint.opacity(0.55), tint.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: tint.opacity(0.35), radius: max(0.6, width * 0.18), x: 0, y: 0)
    }
}

final class LocalQiblaCompassHolder: ObservableObject {
    @Published private(set) var inner: LocalQiblaCompass?
    @Published var direction: Double = 0

    private var cancellable: AnyCancellable?

    func startIfNeeded() {
        if let inner = inner {
            inner.start()
            return
        }
        let mgr = LocalQiblaCompass(locationProvider: {
            Settings.shared.currentLocation
        })
        self.inner = mgr
        cancellable = mgr.$direction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.direction = v }
        mgr.start()
    }

    func stop() { inner?.stop() }
}

final class LocalQiblaCompass: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var direction: Double = 0
    private let lm = CLLocationManager()
    private let locationProvider: () -> Location?
    private let minStep: Double = 1.0
    private var started = false

    init(locationProvider: @escaping () -> Location?) {
        self.locationProvider = locationProvider
        super.init()
        lm.delegate = self
        lm.headingFilter = 1
    }

    func start() {
        guard !started, CLLocationManager.headingAvailable() else { return }
        started = true
        lm.startUpdatingHeading()
    }

    func stop() {
        guard started else { return }
        started = false
        lm.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading h: CLHeading) {
        guard h.headingAccuracy >= 0, let cur = locationProvider() else { return }
        let qibla = Qibla(coordinates: Coordinates(latitude: cur.latitude, longitude: cur.longitude)).direction
        let heading = (h.trueHeading >= 0 ? h.trueHeading : h.magneticHeading)

        var delta = qibla - heading
        delta.formTruncatingRemainder(dividingBy: 360)
        if delta < 0 { delta += 360 }

        if abs(delta - direction) >= minStep {
            direction = delta
        }
    }

    deinit { stop() }
}

#Preview {
    AdhanView()
        .environmentObject(Settings.shared)
}
