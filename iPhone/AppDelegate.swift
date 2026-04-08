#if os(iOS)
import BackgroundTasks
import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let taskID = AppIdentifiers.backgroundFetchPrayerTimesTaskIdentifier
    private let reciterDownloadsSessionID = AppIdentifiers.reciterDownloadsBackgroundSessionIdentifier

    // Performs startup setup: registers background refresh, schedules first refresh, and notification delegate.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerBackgroundRefreshTask()
        scheduleAppRefresh()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Re-schedules the background refresh whenever the app moves to background.
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }

    // Connects iOS background URL session wakeups to the reciter download manager.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == reciterDownloadsSessionID else {
            completionHandler()
            return
        }

        ReciterDownloadManager.shared.backgroundSessionCompletionHandler(completionHandler)
    }

    // Shows in-app notifications as banner + sound when a notification arrives in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Registers the BGTask handler that refreshes prayer times in the background.
    private func registerBackgroundRefreshTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    // Submits the next background refresh request using the computed target run date.
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

    // Calculates the next refresh time (before tomorrow's Fajr, with a minimum lead time).
    private func nextRunDate(offsetMins: Double = 35) -> Date {
        guard let fajr = nextFajrTime else {
            return Date().addingTimeInterval(24 * 60 * 60)
        }

        let timeParts = Calendar.current.dateComponents([.hour, .minute, .second], from: fajr)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduledTomorrow = Calendar.current.date(
            bySettingHour: timeParts.hour ?? 0,
            minute: timeParts.minute ?? 0,
            second: timeParts.second ?? 0,
            of: tomorrow
        ) ?? tomorrow

        let target = scheduledTomorrow.addingTimeInterval(-offsetMins * 60)
        let minimum = Date().addingTimeInterval(15 * 60)
        return max(target, minimum)
    }

    // Reads the earliest prayer time from saved prayer data (used as Fajr anchor).
    private var nextFajrTime: Date? {
        Settings.shared.prayers?
            .prayers
            .sorted(by: { $0.time < $1.time })
            .first?
            .time
    }

    // Executes when BG refresh fires: re-schedules, handles expiration, and refreshes prayer times.
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
}
#endif
