import UIKit
import BackgroundTasks
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let taskID  = "com.Quran.Elmallah.Islamic-Pillars.fetchPrayerTimes"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        scheduleAppRefresh()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = nextRunDate()
        
        if let date = request.earliestBeginDate {
                logger.debug("🔧 Scheduling BGAppRefresh – earliestBeginDate: \(date.formatted())")
            }

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("✅ BGAppRefresh submitted")
        } catch {
            logger.error("❌ BG submit failed: \(error.localizedDescription)")
        }
    }

    private func nextRunDate(offsetMins: Double = 35) -> Date {
        guard
            let fajr = Settings.shared.prayers?
                .prayers.sorted(by: { $0.time < $1.time })
                .first?.time
        else {
            return Date().addingTimeInterval(24*60*60)
        }

        let timeParts = Calendar.current.dateComponents([.hour, .minute, .second], from: fajr)
        var tomorrow  = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        tomorrow      = Calendar.current.date(bySettingHour: timeParts.hour!,
                                              minute:        timeParts.minute!,
                                              second:        timeParts.second!,
                                              of:            tomorrow)!

        let target  = tomorrow.addingTimeInterval(-offsetMins*60)
        let minimum = Date().addingTimeInterval(15*60)
        return max(target, minimum)
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        logger.debug("🚀 BGAppRefresh fired")
        scheduleAppRefresh()

        task.expirationHandler = {
            logger.error("⏰ BG task expired before finishing")
            task.setTaskCompleted(success: false)
        }

        Settings.shared.fetchPrayerTimes {
            logger.debug("🎉 BG task completed – prayer times refreshed")
            task.setTaskCompleted(success: true)
        }
    }

    // Foreground Notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
