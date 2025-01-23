import SwiftUI
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register your task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.Quran.Elmallah.Islamic-Pillars.fetchPrayerTimes", using: nil) { task in
            // This block is called when your task is run
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        // Schedule the task for the first time
        scheduleAppRefresh()

        // Set this object as the delegate for the user notification center.
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.Quran.Elmallah.Islamic-Pillars.fetchPrayerTimes")
        
        if let nextPrayerTime = Settings.shared.prayers?.prayers.first?.time {
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
            let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: nextPrayerTime)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            dateComponents.second = timeComponents.second
            dateComponents.day! += 1
            
            if let tomorrowPrayerTime = Calendar.current.date(from: dateComponents) {
                let timeInterval = tomorrowPrayerTime.timeIntervalSince(Date())
                
                if timeInterval > 0 {
                    print("Scheduled during Fajr")
                    request.earliestBeginDate = Date(timeIntervalSinceNow: timeInterval - 2100)
                } else {
                    print("Scheduled 24 hours later 1")
                    request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
                }
            } else {
                print("Scheduled 24 hours later 2")
                request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
            }
        } else {
            print("Scheduled 24 hours later 3")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled background app refresh")
        } catch {
            print("Could not schedule background app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()
        
        // Perform the data fetch and notification scheduling
        Settings.shared.fetchPrayerTimes()

        // Mark the task as complete when done
        task.setTaskCompleted(success: true)
    }
    
    // Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification alert (and play the sound) even if the app is in the foreground
        completionHandler([.banner, .sound])
    }
}
