import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        SimpleWidget()
        CountdownWidget()
        Prayers2Widget()
        PrayersWidget()
        #if os(iOS)
        if #available(iOS 16.1, *) {
            LockScreen1Widget()
            LockScreen2Widget()
            LockScreen3Widget()
            LockScreen4Widget()
        }
        #endif
    }
}
