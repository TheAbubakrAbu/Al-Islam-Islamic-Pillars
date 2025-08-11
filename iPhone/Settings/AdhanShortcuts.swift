import AppIntents

@available(iOS 16.0, watchOS 9.0, *)
enum PrayerKind: String, AppEnum, CaseIterable {
    case fajr = "Fajr", sunrise = "Sunrise", dhuhr = "Dhuhr", asr = "Asr", maghrib = "Maghrib", isha = "Isha"
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Prayer")
    static var caseDisplayRepresentations: [PrayerKind: DisplayRepresentation] = [
        .fajr: "Fajr", .sunrise: "Sunrise", .dhuhr: "Dhuhr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"
    ]
}

@available(iOS 16.0, watchOS 9.0, *)
struct WhenIsPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "When is Prayer"
    static var description = IntentDescription("Ask for today's time of a specific prayer.")
    static var openAppWhenRun: Bool = false
    static var parameterSummary: some ParameterSummary { Summary("When is \(\.$prayer)") }

    @Parameter(title: "Prayer") var prayer: PrayerKind

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let list = Settings.shared.getPrayerTimes(for: Date(), fullPrayers: true), !list.isEmpty else {
            let msg = "Prayer times aren’t available yet. Open Al-Islam to refresh."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }

        let keys: [String]
        switch prayer {
        case .fajr:    keys = ["Fajr"]
        case .sunrise: keys = ["Shurooq", "Sunrise"]
        case .dhuhr:   keys = ["Dhuhr", "Jummuah"]
        case .asr:     keys = ["Asr"]
        case .maghrib: keys = ["Maghrib"]
        case .isha:    keys = ["Isha"]
        }

        if let p = list.first(where: { keys.contains($0.nameTransliteration) || keys.contains($0.nameEnglish) }) {
            let time = Settings.shared.formatDate(p.time)
            let name = (p.nameTransliteration == "Jummuah") ? "Jummuah (Dhuhr)" : p.nameTransliteration
            let msg = "\(name) is at \(time)."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }

        let msg = "Couldn’t find today’s time for \(prayer.rawValue)."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CurrentPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Current Prayer"
    static var description = IntentDescription("Tell me the current prayer (name and time).")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        Settings.shared.fetchPrayerTimes()

        if let cur = Settings.shared.currentPrayer {
            let msg = "Current prayer: \(cur.nameTransliteration) (\(Settings.shared.formatDate(cur.time)))."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }

        if let list = Settings.shared.getPrayerTimes(for: Date(), fullPrayers: true) {
            let now = Date()
            if let idx = list.lastIndex(where: { $0.time <= now }) {
                let p = list[idx]
                let msg = "Current prayer: \(p.nameTransliteration) at \(Settings.shared.formatDate(p.time))."
                return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
            }
        }

        let msg = "No current prayer determined yet. Open Al-Islam to refresh prayer times."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct NextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Prayer"
    static var description = IntentDescription("Tell me the next prayer (name and time).")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        Settings.shared.fetchPrayerTimes()
        if let next = Settings.shared.nextPrayer {
            let msg = "Next prayer: \(next.nameTransliteration) at \(Settings.shared.formatDate(next.time))."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }

        if let list = Settings.shared.getPrayerTimes(for: Date(), fullPrayers: true) {
            if let p = list.first(where: { $0.time > Date() }) {
                let msg = "Next prayer: \(p.nameTransliteration) at \(Settings.shared.formatDate(p.time))."
                return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
            }
        }

        let msg = "No upcoming prayer found. Open Al-Islam to refresh prayer times."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}
