import SwiftUI
#if os(iOS)
import UIKit
import QuartzCore
#endif

struct QiblaView: View {
    @EnvironmentObject var settings: Settings
    var size: CGFloat = 50

    private var direction: Double { settings.qiblaDirection } // 0 means aligned
    private var distToQibla: Double { angularDistance(direction, 0) }

    private var arrowColour: Color { distToQibla <=  5 ? settings.accentColor.color : .primary }
    private var ringColour:  Color { distToQibla <= 20 ? settings.accentColor.color : .primary }

    #if os(iOS)
    @State private var lastAngle: Double = 0
    @State private var lastHapticTime: CFTimeInterval = 0
    @State private var impact = UIImpactFeedbackGenerator(style: .light)
    private let notify = UINotificationFeedbackGenerator()
    #endif
    
    // Smallest absolute angle between two headings (degrees), always 0…180
    private func angularDistance(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d < -180 { d += 360 }
        if d >  180 { d -= 360 }
        return abs(d)
    }

    var body: some View {
        let arrowW = max(10, size * 0.18)
        let arrowH = max(30, size * 0.55)
        let kaaba  = max(20, size * 0.40)
        let stroke = max(1,  size * 0.04)

        VStack(spacing: -(size * 0.40)) {
            Image(systemName: "arrow.up")
                .resizable()
                .frame(width: arrowW, height: arrowH)
                .foregroundColor(arrowColour)

            Text("🕋")
                .font(.system(size: kaaba))
        }
        .padding(.vertical, size * 0.16)
        .background(
            Circle()
                .stroke(ringColour, lineWidth: stroke)
                .frame(width: size, height: size)
        )
        .rotationEffect(.degrees(direction))
        #if os(iOS)
        .onAppear {
            lastAngle = direction
            impact.prepare()
            notify.prepare()
        }
        .onChange(of: direction) { newAngle in
            // Only do haptics for expanded compass
            guard size > 50 else { return }

            let now = CACurrentMediaTime()
            // Throttle (avoid spam)
            guard now - lastHapticTime >= 0.08 else { return }

            // Shortest signed delta in degrees (handles wraparound)
            let delta = shortestDelta(from: lastAngle, to: newAngle)
            let absDelta = abs(delta)

            // Distance from Qibla (0 is perfect)
            let dist = angularDistance(newAngle, 0)

            // Adaptive step: bigger movements required when far; more sensitive near target
            let step = max(3.0, min(12.0, dist / 2.0)) // 3°…12°

            if absDelta >= step {
                // Intensity grows as you get closer (within 30° ramps to max)
                let proximity = max(0.0, min(1.0, (30.0 - dist) / 30.0)) // 0…1
                let intensity = CGFloat(0.3 + 0.7 * proximity)          // 0.3…1.0

                if dist <= 5 {
                    // Strong success haptic when you're basically aligned
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

    #if os(iOS)
    /// Returns the shortest signed angular difference in degrees (-180...180)
    private func shortestDelta(from a: Double, to b: Double) -> Double {
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
    #endif
}
