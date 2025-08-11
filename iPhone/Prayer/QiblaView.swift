import SwiftUI
#if os(iOS)
import UIKit
import QuartzCore
#endif

struct QiblaView: View {
    @EnvironmentObject var settings: Settings
    var size: CGFloat = 50

    private var direction: Double { settings.qiblaDirection } // degrees: target at 0
    private var accent: Color  { settings.accentColor.color }
    private var arrowColour: Color { abs(direction) <=  5 ? accent : .primary }
    private var ringColour:  Color { abs(direction) <= 20 ? accent : .primary }

    #if os(iOS)
    @State private var lastAngle: Double = 0
    @State private var lastHapticTime: CFTimeInterval = 0
    @State private var impact = UIImpactFeedbackGenerator(style: .light)
    private let notify = UINotificationFeedbackGenerator()
    #endif

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
            let dist = min(180.0, abs(newAngle))

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
