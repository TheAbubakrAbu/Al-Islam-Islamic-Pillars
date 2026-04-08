import SwiftUI
import CoreLocation
import Combine
import Adhan
#if os(iOS)
import UIKit
#endif

struct QiblaView: View {
    @EnvironmentObject private var settings: Settings

    let size: CGFloat

    private static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

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

    private var layout: QiblaLayoutMetrics {
        QiblaLayoutMetrics(size: size)
    }

    private var distanceToQibla: Double {
        angularDistance(compass.direction, 0)
    }

    private var qiblaTurnText: String? {
        guard distanceToQibla > 1 else { return "You are facing the Kaaba" }

        let delta = shortestDelta(from: 0, to: compass.direction)
        let direction = delta < 0 ? "left" : "right"
        let degrees = Int(abs(delta).rounded())
        return "Turn \(direction) \(degrees)°"
    }

    private var distanceToKaabaMiles: Double? {
        guard let currentLocation = settings.currentLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000 else { return nil }

        let here = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let kaaba = CLLocation(latitude: Self.kaabaCoordinate.latitude, longitude: Self.kaabaCoordinate.longitude)
        return here.distance(from: kaaba) / 1_609.344
    }

    private var alignmentScore: Double {
        1.0 - (min(20.0, distanceToQibla) / 20.0)
    }

    private var arrowColor: Color {
        distanceToQibla <= 5 ? settings.accentColor.color : .primary
    }

    private var ringColor: Color {
        distanceToQibla <= 20 ? settings.accentColor.color : .primary
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                GlassyQiblaRing(size: size, tint: ringColor, alignmentScore: alignmentScore)
                    .animation(.easeInOut(duration: 0.2), value: ringColor)

                pointerStack
                    .rotationEffect(.degrees(compass.direction))
            }

            if size >= 70 {
                qiblaInfoCard
            }
        }
        .animation(nil, value: compass.direction)
        .onAppear {
            compass.start()
            prepareHaptics()
        }
        .onDisappear {
            compass.stop()
        }
        #if os(iOS)
        .onChange(of: compass.direction) { newAngle in
            handleDirectionChange(newAngle)
        }
        #endif
    }

    private var pointerStack: some View {
        VStack(spacing: -(size * 0.40)) {
            QiblaArrow(width: layout.arrowWidth, height: layout.arrowHeight, tint: arrowColor)
                .animation(.easeInOut(duration: 0.2), value: arrowColor)
            Text("🕋")
                .font(.system(size: layout.kaabaSize))
                .shadow(
                    color: .black.opacity(0.25),
                    radius: max(0.6, layout.kaabaSize * 0.08),
                    x: 0,
                    y: 0
                )
        }
        .padding(.vertical, size * 0.16)
    }

    private var qiblaInfoCard: some View {
        VStack(spacing: 3) {
            if let qiblaTurnText {
                Text(qiblaTurnText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(distanceToQibla <= 20 ? settings.accentColor.color : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let distanceToKaabaMiles {
                Text(String(format: "%.1f miles from the Kaaba", distanceToKaabaMiles))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .conditionalGlassEffect()
        .shadow(color: .primary.opacity(0.08), radius: 8, y: 2)
    }

    private func angularDistance(_ lhs: Double, _ rhs: Double) -> Double {
        var delta = (lhs - rhs).truncatingRemainder(dividingBy: 360)
        if delta < -180 { delta += 360 }
        if delta > 180 { delta -= 360 }
        return abs(delta)
    }

    private func shortestDelta(from lhs: Double, to rhs: Double) -> Double {
        var delta = (rhs - lhs).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return delta
    }

    private func prepareHaptics() {
        #if os(iOS)
        lastAngle = compass.direction
        lastHapticTime = ProcessInfo.processInfo.systemUptime
        impact.prepare()
        notify.prepare()
        #endif
    }

    #if os(iOS)
    private func handleDirectionChange(_ newAngle: Double) {
        guard size > 50 else { return }

        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastHapticTime >= 0.08 else { return }

        let delta = shortestDelta(from: lastAngle, to: newAngle)
        let absoluteDelta = abs(delta)
        let distance = angularDistance(newAngle, 0)
        let threshold = max(2.0, min(8.0, distance / 3.0))

        guard absoluteDelta >= threshold else { return }

        if distance <= 5 {
            notify.notificationOccurred(.success)
            notify.prepare()
        } else {
            let intensity = CGFloat(distance <= 20 ? 0.25 : 0.15)
            impact.impactOccurred(intensity: intensity)
            impact.prepare()
        }

        lastHapticTime = now
        lastAngle = newAngle
    }
    #endif
}

private struct QiblaLayoutMetrics {
    let size: CGFloat

    var arrowWidth: CGFloat { max(10, size * 0.18) }
    var arrowHeight: CGFloat { max(30, size * 0.55) }
    var kaabaSize: CGFloat { max(20, size * 0.40) }
}

struct GlassyQiblaRing: View {
    let size: CGFloat
    let tint: Color
    let alignmentScore: Double

    @ViewBuilder
    private var glassFill: some View {
        #if os(iOS)
        Circle().fill(.ultraThinMaterial)
        #else
        Circle().fill(Color.white.opacity(0.18))
        #endif
    }

    var body: some View {
        let ringWidth = max(1, size * 0.045)
        let glossWidth = size * 0.16
        let outerGlowWidth = size * 0.085
        let shadowRadius = max(1, size * 0.10)
        let innerLineWidth = max(1, size * 0.06)
        let innerBlur = max(0.5, size * 0.04)

        ZStack {
            glassFill
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.14), lineWidth: innerLineWidth)
                        .blur(radius: innerBlur)
                        .mask(Circle().stroke(lineWidth: innerLineWidth))
                )
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0.12), .clear],
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
                .shadow(color: .black.opacity(0.18), radius: shadowRadius, x: 0, y: max(0.5, size * 0.04))

            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [tint.opacity(0.95), Color.white.opacity(0.75), tint.opacity(0.95)]),
                        center: .center
                    ),
                    lineWidth: ringWidth
                )

            Circle()
                .stroke(tint.opacity(0.25 + 0.45 * alignmentScore), lineWidth: outerGlowWidth)
                .blur(radius: max(0.6, size * 0.05))
                .mask(Circle().stroke(lineWidth: outerGlowWidth))
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .compositingGroup()
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
        if let inner {
            inner.start()
            return
        }

        let compass = LocalQiblaCompass(locationProvider: {
            Settings.shared.currentLocation
        })

        inner = compass
        cancellable = compass.$direction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.direction = value
            }
        compass.start()
    }

    func stop() {
        inner?.stop()
    }
}

final class LocalQiblaCompass: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var direction: Double = 0

    private let locationManager = CLLocationManager()
    private let locationProvider: () -> Location?
    private let minStep: Double = 1.0
    private var started = false

    init(locationProvider: @escaping () -> Location?) {
        self.locationProvider = locationProvider
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1
    }

    func start() {
        guard !started, CLLocationManager.headingAvailable() else { return }
        started = true
        locationManager.startUpdatingHeading()
    }

    func stop() {
        guard started else { return }
        started = false
        locationManager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0, let currentLocation = locationProvider() else { return }

        let qiblaDirection = Qibla(
            coordinates: Coordinates(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        ).direction
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

        var delta = qiblaDirection - heading
        delta.formTruncatingRemainder(dividingBy: 360)
        if delta < 0 { delta += 360 }

        if abs(delta - direction) >= minStep {
            direction = delta
        }
    }

    deinit {
        stop()
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            QiblaView(size: 160)
                .padding()
        }
    }
}
