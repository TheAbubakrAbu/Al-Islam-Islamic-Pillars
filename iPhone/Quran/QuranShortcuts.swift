import AppIntents

@available(iOS 16.0, watchOS 9.0, *)
struct PlaySurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Surah"
    static var description = IntentDescription("Play a specific surah by name or number.")
    static var openAppWhenRun = true
    static var parameterSummary: some ParameterSummary { Summary("Play \(\.$query)") }

    @Parameter(
        title: "Surah",
        requestValueDialog: IntentDialog("Which surah would you like to play? You can say a name or a number.")
    )
    var query: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let normalizedQuery = query.normalizedSurahIntentQuery

        guard !normalizedQuery.isEmpty else {
            return .result(dialog: "Please provide a surah name or number.")
        }

        if let surah = QuranPlaybackRouter.matchedSurah(for: normalizedQuery) {
            let didStart = await QuranPlaybackRouter.play(surahID: surah.id, name: surah.nameTransliteration)
            return .result(dialog: didStart
                ? IntentDialog("Playing Surah \(surah.id): \(surah.nameTransliteration).")
                : IntentDialog("Sorry, there was a problem starting playback."))
        }

        return .result(dialog: "Sorry, I couldn't find a match for “\(query)”.")
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct PlayRandomSurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Random Surah"
    static var description = IntentDescription("Play a random surah.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let result = await QuranPlaybackRouter.playRandom() else {
            return .result(dialog: "Sorry, I couldn’t choose a surah right now.")
        }

        return .result(dialog: result.ok
            ? IntentDialog("Playing Surah \(result.id): \(result.name).")
            : IntentDialog("Sorry, there was a problem starting playback."))
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct PlayLastListenedSurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Last Listened Surah"
    static var description = IntentDescription("Play the last surah you listened to.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let result = await QuranPlaybackRouter.playLast() else {
            return .result(dialog: "Sorry, I don’t have a last listened surah yet.")
        }

        return .result(dialog: result.ok
            ? IntentDialog("Playing Surah \(result.id): \(result.name).")
            : IntentDialog("Sorry, there was a problem starting playback."))
    }
}

enum QuranPlaybackRouter {
    private static let data = QuranData.shared
    private static let player = QuranPlayer.shared
    private static let settings = Settings.shared

    @MainActor
    private static func confirmStart(
        surahID: Int,
        timeout: UInt64 = 2_000_000_000,
        interval: UInt64 = 100_000_000
    ) async -> Bool {
        if player.isPlaying, player.currentSurahNumber == surahID {
            return true
        }

        var waited: UInt64 = 0
        while waited < timeout {
            try? await Task.sleep(nanoseconds: interval)
            waited += interval

            if player.isPlaying, player.currentSurahNumber == surahID {
                return true
            }

            if (player.player?.rate ?? 0) > 0, player.currentSurahNumber == surahID {
                return true
            }
        }

        return false
    }

    @MainActor
    static func play(surahID: Int, name: String) async -> Bool {
        player.playSurah(surahNumber: surahID, surahName: name)
        return await confirmStart(surahID: surahID)
    }

    @MainActor
    static func playLast() async -> (id: Int, name: String, ok: Bool)? {
        guard
            let last = settings.lastListenedSurah,
            let surah = data.quran.first(where: { $0.id == last.surahNumber })
        else {
            return nil
        }

        player.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration,
            certainReciter: true
        )

        let didStart = await confirmStart(surahID: surah.id)
        return (surah.id, surah.nameTransliteration, didStart)
    }

    @MainActor
    static func playRandom() async -> (id: Int, name: String, ok: Bool)? {
        guard let surah = data.quran.randomElement() else {
            return nil
        }

        player.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
        let didStart = await confirmStart(surahID: surah.id)
        return (surah.id, surah.nameTransliteration, didStart)
    }

    static func matchedSurah(for normalizedQuery: String) -> Surah? {
        if let number = Int(normalizedQuery), (1...114).contains(number) {
            return data.quran.first(where: { $0.id == number })
        }

        return data.quran.first(where: { surah in
            surah.normalizedSearchNames.contains { $0.contains(normalizedQuery) }
        })
    }
}

private extension Surah {
    var normalizedSearchNames: [String] {
        [
            nameTransliteration,
            nameEnglish,
            nameArabic.removingArabicMarks()
        ].map { $0.normalizedForSurahQuery }
    }
}

extension String {
    func removingArabicMarks() -> String {
        let filtered = unicodeScalars.filter {
            $0.value != 0x0640 &&
            !(0x0610...0x061A).contains($0.value) &&
            !(0x064B...0x065F).contains($0.value) &&
            !(0x06D6...0x06ED).contains($0.value)
        }
        return String(String.UnicodeScalarView(filtered))
    }

    func arabicDigitsToWestern() -> String {
        let digitMap: [Character: Character] = [
            "٠":"0","١":"1","٢":"2","٣":"3","٤":"4",
            "٥":"5","٦":"6","٧":"7","٨":"8","٩":"9",
            "۰":"0","۱":"1","۲":"2","۳":"3","۴":"4",
            "۵":"5","۶":"6","۷":"7","۸":"8","۹":"9"
        ]
        return String(map { digitMap[$0] ?? $0 })
    }

    var normalizedForSurahQuery: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .removingArabicMarks()
            .arabicDigitsToWestern()
            .lowercased()
    }

    var normalizedSurahIntentQuery: String {
        normalizedForSurahQuery.replacingOccurrences(
            of: #"^\s*(surah|surat|sura|chapter|سورة|سوره)\s+"#,
            with: "",
            options: .regularExpression
        )
    }
}
