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

        if let n = Int(q), (1...114).contains(n),
           let s = QuranData.shared.quran.first(where: { $0.id == n }) {
            QuranPlaybackRouter.play(surahID: s.id, name: s.nameTransliteration)
            return .result(dialog: "Playing \(s.nameTransliteration).")
        }

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
            QuranPlaybackRouter.play(surahID: s.id, name: s.nameTransliteration)
            return .result(dialog: "Playing \(s.nameTransliteration).")
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
    func perform() async throws -> some IntentResult {
        QuranPlaybackRouter.playRandom()
        return .result()
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct PlayLastListenedSurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Last Listened Surah"
    static var description = IntentDescription("Play the last surah you listened to.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuranPlaybackRouter.playLast()
        return .result()
    }
}

enum QuranPlaybackRouter {
    private static let data = QuranData.shared
    private static let player = QuranPlayer.shared
    private static let settings = Settings.shared

    static func play(surahID: Int, name: String) {
        player.playSurah(surahNumber: surahID, surahName: name)
    }

    static func playLast() {
        guard
            let last = settings.lastListenedSurah,
            let surah = data.quran.first(where: { $0.id == last.surahNumber })
        else { return }

        player.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration,
            certainReciter: true
        )
    }

    static func playRandom() {
        guard let s = data.quran.randomElement() else { return }
        player.playSurah(surahNumber: s.id, surahName: s.nameTransliteration)
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
