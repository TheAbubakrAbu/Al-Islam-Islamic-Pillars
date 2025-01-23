import SwiftUI

struct QiblaView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        HStack {
            VStack(spacing: -20) {
                Image(systemName: "arrow.up")
                    .resizable()
                    .frame(width: 10, height: 30)
                    .foregroundColor(abs(settings.qiblaDirection) <= 5 ? settings.accentColor.color : .primary)
                Text("🕋")
                    .font(.system(size: 20))
            }
            .padding(.vertical, 8)
            .background(
                Circle()
                    .stroke(abs(settings.qiblaDirection) <= 20 ? settings.accentColor.color : .primary, lineWidth: 1)
                    .frame(width: 50, height: 50)
            )
            .rotationEffect(.degrees(settings.qiblaDirection))
        }
    }
}
