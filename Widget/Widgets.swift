import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        PrayersWidget()
        #if os(iOS)
        if #available(iOS 16.1, *) {
            LockScreen1Widget()
            LockScreen2Widget()
        }
        #endif
    }
}
