import SwiftUI

struct QiblaView: View {
    @EnvironmentObject var settings: Settings

    private var direction: Double { settings.qiblaDirection }
    private var accent: Color  { settings.accentColor.color }

    private var arrowColour: Color { abs(direction) <=  5 ? accent : .primary }
    private var ringColour: Color { abs(direction) <= 20 ? accent : .primary }

    var body: some View {
        VStack(spacing: -20) {
            Image(systemName: "arrow.up")
                .resizable()
                .frame(width: 10, height: 30)
                .foregroundColor(arrowColour)

            Text("🕋")
                .font(.system(size: 20))
        }
        .padding(.vertical, 8)
        .background(
            Circle()
                .stroke(ringColour, lineWidth: 1)
                .frame(width: 50, height: 50)
        )
        .rotationEffect(.degrees(direction))
    }
}
