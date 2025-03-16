import SwiftUI
import Intents

var quranData = QuranData.shared
var quranPlayer = QuranPlayer.shared
var settings = Settings.shared

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        if intent is PlaySurahIntent {
            return PlaySurahIntentHandler()
        }
        
        if intent is PlayLastListenedSurahIntent {
            return PlayLastListenedSurahIntentHandler()
        }
        
        if intent is PlayRandomSurahIntent {
            return PlayRandomSurahIntentHandler()
        }
        
        return self
    }
}

class PlaySurahIntentHandler: NSObject, PlaySurahIntentHandling {
    func handle(
        intent: PlaySurahIntent,
        completion: @escaping (PlaySurahIntentResponse) -> Void
    ) {
        guard let surahIdentifier = intent.surah?.trimmingCharacters(in: .whitespacesAndNewlines),
              !surahIdentifier.isEmpty else {
            completion(PlaySurahIntentResponse.failure(surah: "Unknown"))
            return
        }

        var foundSurah: Surah?

        if let surahNumber = Int(surahIdentifier) {
            foundSurah = quranData.quran.first(where: { $0.id == surahNumber })
        }

        if foundSurah == nil {
            foundSurah = quranData.quran.first(where: { $0.nameEnglish.lowercased() == surahIdentifier.lowercased() })
        }

        if foundSurah == nil {
            foundSurah = quranData.quran.first(where: { $0.nameTransliteration.lowercased() == surahIdentifier.lowercased() })
        }

        if let surah = foundSurah {
            print("✅ Found Surah: \(surah.nameTransliteration)")
            
            completion(
                PlaySurahIntentResponse.success(surah: "Surah \(surah.id): \(surah.nameTransliteration)")
            )
            
            DispatchQueue.main.async {
                quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                settings.toggleSurahFavorite(surah: surah)
            }
        } else {
            print("⚠️ Surah not found")
            completion(PlaySurahIntentResponse.failure(surah: "Unknown"))
        }
    }
    
    func resolveSurah(
        for intent: PlaySurahIntent,
        with completion: @escaping (INStringResolutionResult) -> Void
    ) {
        if let name = intent.surah {
            completion(.success(with: name))
        } else {
            completion(.needsValue())
        }
    }
}

class PlayLastListenedSurahIntentHandler: NSObject, PlayLastListenedSurahIntentHandling {
    func handle(
        intent: PlayLastListenedSurahIntent,
        completion: @escaping (PlayLastListenedSurahIntentResponse) -> Void
    ) {
        if let lastListenedSurah = settings.lastListenedSurah, let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber }) {
            
            print("✅ Found Surah: \(surah.nameTransliteration)")
            
            completion(
                PlayLastListenedSurahIntentResponse.success(surah: "Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
            )
            
            DispatchQueue.main.async {
                quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber, surahName: lastListenedSurah.surahName, certainReciter: true)
                settings.toggleSurahFavorite(surah: surah)
            }
        } else {
            print("⚠️ Surah not found")
            completion(PlayLastListenedSurahIntentResponse.failure(surah: "Unknown"))
        }
    }
}

class PlayRandomSurahIntentHandler: NSObject, PlayRandomSurahIntentHandling {
    func handle(
        intent: PlayRandomSurahIntent,
        completion: @escaping (PlayRandomSurahIntentResponse) -> Void
    ) {
        if let randomSurah = quranData.quran.randomElement() {
            print("✅ Found Surah: \(randomSurah.nameTransliteration)")
            
            completion(
                PlayRandomSurahIntentResponse.success(surah: "Surah \(randomSurah.id): \(randomSurah.nameTransliteration)")
            )
            
            DispatchQueue.main.async {
                quranPlayer.playSurah(surahNumber: randomSurah.id, surahName: randomSurah.nameTransliteration)
                settings.toggleSurahFavorite(surah: randomSurah)
            }
        } else {
            print("⚠️ Surah not found")
            completion(PlayRandomSurahIntentResponse.failure(surah: "Unknown"))
        }
    }
}
