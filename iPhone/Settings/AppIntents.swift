import AppIntents

@available(iOS 16.0, *)
struct AppShortcutsRoot: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlaySurahAppIntent(),
            phrases: [
                "Play a surah in \(.applicationName)",
                "Recite a surah in \(.applicationName)",
                "Play surah in \(.applicationName)",
                "Recite surah in \(.applicationName)",
                "\(.applicationName), play a surah",
                "\(.applicationName), recite a surah",
                "\(.applicationName), play surah",
                "\(.applicationName), recite surah",
                "شغّل سورة في \(.applicationName)",
                "اقرأ سورة في \(.applicationName)",

                "Play a surah",
                "Recite a surah",
                "Play surah",
                "Recite surah",
                "شغّل سورة",
                "اقرأ سورة"
            ],
            shortTitle: "Play Surah",
            systemImageName: "book"
        )

        AppShortcut(
            intent: PlayRandomSurahAppIntent(),
            phrases: [
                "Play random surah in \(.applicationName)",
                "Recite random surah in \(.applicationName)",
                "Play random in \(.applicationName)",
                "Recite random in \(.applicationName)",
                "\(.applicationName), play a random surah",
                "\(.applicationName), recite a random surah",
                "\(.applicationName), play random surah",
                "\(.applicationName), recite random surah",
                "\(.applicationName), play random",
                "\(.applicationName), recite random",
                "شغّل سورة عشوائية في \(.applicationName)",
                "اقرأ سورة عشوائية في \(.applicationName)",

                "Play a random surah",
                "Recite a random surah",
                "Play random surah",
                "Recite random surah",
                "Play random",
                "Recite random",
                "شغّل سورة عشوائية",
                "اقرأ سورة عشوائية"
            ],
            shortTitle: "Random Surah",
            systemImageName: "shuffle"
        )

        AppShortcut(
            intent: PlayLastListenedSurahAppIntent(),
            phrases: [
                "Play last listened surah in \(.applicationName)",
                "Recite last listened surah in \(.applicationName)",
                "Play last listened in \(.applicationName)",
                "Recite last listened in \(.applicationName)",
                "Play last in \(.applicationName)",
                "Recite last in \(.applicationName)",
                "Play last surah in \(.applicationName)",
                "Recite last surah in \(.applicationName)",
                "\(.applicationName), play last listened surah",
                "\(.applicationName), recite last listened surah",
                "\(.applicationName), play last listened",
                "\(.applicationName), recite last listened",
                "\(.applicationName), play last",
                "\(.applicationName), recite last",
                "\(.applicationName), play last surah",
                "\(.applicationName), recite last surah",
                "شغّل آخر سورة تم الاستماع إليها في \(.applicationName)",
                "اقرأ آخر سورة تم الاستماع إليها في \(.applicationName)",

                "Play last listened surah",
                "Recite last listened surah",
                "Play last listened",
                "Recite last listened",
                "Play last",
                "Recite last",
                "Play last surah",
                "Recite last surah",
                "شغّل آخر سورة تم الاستماع إليها",
                "اقرأ آخر سورة تم الاستماع إليها"
            ],
            shortTitle: "Last Listened Surah",
            systemImageName: "gobackward"
        )

        AppShortcut(
            intent: WhenIsPrayerIntent(),
            phrases: [
                "When is \(\.$prayer) in \(.applicationName)",
                "What time is \(\.$prayer) in \(.applicationName)",
                "What is the time for \(\.$prayer) in \(.applicationName)",
                "When does \(\.$prayer) start in \(.applicationName)",
                "Time for \(\.$prayer) in \(.applicationName)",
                "Prayer time for \(\.$prayer) in \(.applicationName)",
                "When is \(\.$prayer) prayer in \(.applicationName)",
                "What time is \(\.$prayer) prayer in \(.applicationName)",
                "وقت \(\.$prayer) في \(.applicationName)",
                "متى \(\.$prayer) في \(.applicationName)",
                "ما وقت \(\.$prayer) في \(.applicationName)",

                "When is \(\.$prayer)",
                "What time is \(\.$prayer)",
                "What is the time for \(\.$prayer)",
                "When does \(\.$prayer) start",
                "Time for \(\.$prayer)",
                "Prayer time for \(\.$prayer)",
                "When is \(\.$prayer) prayer",
                "What time is \(\.$prayer) prayer",
                "وقت \(\.$prayer)",
                "متى \(\.$prayer)",
                "ما وقت \(\.$prayer)"
            ],
            shortTitle: "When is Prayer",
            systemImageName: "clock"
        )

        AppShortcut(
            intent: CurrentPrayerIntent(),
            phrases: [
                "What is the current prayer in \(.applicationName)",
                "Current prayer in \(.applicationName)",
                "What prayer is it now in \(.applicationName)",
                "Which prayer is now in \(.applicationName)",
                "What prayer time is it in \(.applicationName)",
                "ما هي الصلاة الحالية في \(.applicationName)",
                "ما هي الصلاة الآن في \(.applicationName)",
                "ما الصلاة الآن في \(.applicationName)",

                "What is the current prayer",
                "Current prayer",
                "What prayer is it now",
                "Which prayer is now",
                "What prayer time is it",
                "ما هي الصلاة الحالية",
                "ما هي الصلاة الآن",
                "ما الصلاة الآن"
            ],
            shortTitle: "Current Prayer",
            systemImageName: "clock.badge.checkmark"
        )

        AppShortcut(
            intent: NextPrayerIntent(),
            phrases: [
                "What is the next prayer in \(.applicationName)",
                "When is the next prayer in \(.applicationName)",
                "What is the next prayer time in \(.applicationName)",
                "When is the next prayer time in \(.applicationName)",
                "Next prayer in \(.applicationName)",
                "Next prayer time in \(.applicationName)",
                "Time of the next prayer in \(.applicationName)",
                "Which prayer is next in \(.applicationName)",
                "ما هي الصلاة القادمة في \(.applicationName)",
                "متى الصلاة القادمة في \(.applicationName)",
                "ما وقت الصلاة القادمة في \(.applicationName)",
                "وقت الصلاة القادمة في \(.applicationName)",

                "What is the next prayer",
                "When is the next prayer",
                "What is the next prayer time",
                "When is the next prayer time",
                "Next prayer",
                "Next prayer time",
                "Time of the next prayer",
                "Which prayer is next",
                "ما هي الصلاة القادمة",
                "متى الصلاة القادمة",
                "ما وقت الصلاة القادمة",
                "وقت الصلاة القادمة"
            ],
            shortTitle: "Next Prayer",
            systemImageName: "forward.end"
        )
    }
}
