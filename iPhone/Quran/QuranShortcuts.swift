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
        var q = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .removingArabicMarks()
            .arabicDigitsToWestern()
            .lowercased()
        q = q.replacingOccurrences(
            of: #"^\s*(surah|surat|sura|chapter|سورة|سوره)\s+"#,
            with: "",
            options: .regularExpression
        )

        guard !q.isEmpty else {
            return .result(dialog: "Please provide a surah name or number.")
        }

        // Numbered query
        if let n = Int(q), (1...114).contains(n),
           let s = QuranData.shared.quran.first(where: { $0.id == n }) {
            let ok = await QuranPlaybackRouter.play(surahID: s.id, name: s.nameTransliteration)
            return .result(dialog: ok
                ? IntentDialog("Playing Surah \(s.id): \(s.nameTransliteration).")
                : IntentDialog("Sorry, there was a problem starting playback."))
        }

        // Name-based query (fuzzy)
        if let s = QuranData.shared.quran.first(where: { surah in
            let names = [
                surah.nameTransliteration,
                surah.nameEnglish,
                surah.nameArabic.removingArabicMarks()
            ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines)
                     .removingArabicMarks()
                     .lowercased() }
            return names.contains(where: { $0.contains(q) })
        }) {
            let ok = await QuranPlaybackRouter.play(surahID: s.id, name: s.nameTransliteration)
            return .result(dialog: ok
                ? IntentDialog("Playing Surah \(s.id): \(s.nameTransliteration).")
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
        guard let res = await QuranPlaybackRouter.playRandom() else {
            return .result(dialog: "Sorry, I couldn’t choose a surah right now.")
        }
        return .result(dialog: res.ok
            ? IntentDialog("Playing Surah \(res.id): \(res.name).")
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
        guard let res = await QuranPlaybackRouter.playLast() else {
            return .result(dialog: "Sorry, I don’t have a last listened surah yet.")
        }
        return .result(dialog: res.ok
            ? IntentDialog("Playing Surah \(res.id): \(res.name).")
            : IntentDialog("Sorry, there was a problem starting playback."))
    }
}

enum QuranPlaybackRouter {
    private static let data = QuranData.shared
    private static let player = QuranPlayer.shared
    private static let settings = Settings.shared
    
    @MainActor
    private static func confirmStart(surahID: Int, timeout: UInt64 = 600_000_000) async -> Bool {
        try? await Task.sleep(nanoseconds: timeout / 3)
        if player.isPlaying, player.currentSurahNumber == surahID { return true }
        try? await Task.sleep(nanoseconds: timeout / 3)
        return player.isPlaying && player.currentSurahNumber == surahID
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
        else { return nil }

        player.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration,
            certainReciter: true
        )
        let ok = await confirmStart(surahID: surah.id)
        return (surah.id, surah.nameTransliteration, ok)
    }

    @MainActor
    static func playRandom() async -> (id: Int, name: String, ok: Bool)? {
        guard let s = data.quran.randomElement() else { return nil }
        player.playSurah(surahNumber: s.id, surahName: s.nameTransliteration)
        let ok = await confirmStart(surahID: s.id)
        return (s.id, s.nameTransliteration, ok)
    }
}

extension String {
    // Remove Arabic diacritics + tatweel
    func removingArabicMarks() -> String {
        let filtered = unicodeScalars.filter {
            // Tatweel U+0640 and Arabic combining marks
            $0.value != 0x0640 &&
            !(0x0610...0x061A).contains($0.value) &&
            !(0x064B...0x065F).contains($0.value) &&
            !(0x06D6...0x06ED).contains($0.value)
        }
        return String(String.UnicodeScalarView(filtered))
    }

    // Convert Arabic-Indic & Persian digits to Western digits
    func arabicDigitsToWestern() -> String {
        let digitMap: [Character: Character] = [
            // Arabic-Indic
            "٠":"0","١":"1","٢":"2","٣":"3","٤":"4",
            "٥":"5","٦":"6","٧":"7","٨":"8","٩":"9",
            // Eastern Arabic (Persian)
            "۰":"0","۱":"1","۲":"2","۳":"3","۴":"4",
            "۵":"5","۶":"6","۷":"7","۸":"8","۹":"9"
        ]
        return String(self.map { digitMap[$0] ?? $0 })
    }

    var normalizedForSurahQuery: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .removingArabicMarks()
            .arabicDigitsToWestern()
            .lowercased()
    }
}
