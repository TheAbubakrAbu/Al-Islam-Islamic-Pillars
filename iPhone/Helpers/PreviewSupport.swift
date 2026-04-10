import SwiftUI

enum AlIslamPreviewData {
    static let settings: Settings = {
        let settings = Settings.shared
        configure(settings)
        return settings
    }()

    static let quranData = QuranData.shared
    static let quranPlayer = QuranPlayer.shared
    static let namesData = NamesViewModel.shared

    static var surah: Surah {
        quranData.quran.first ?? fallbackSurah
    }

    static var ayah: Ayah {
        surah.ayahs.first(where: { $0.existsInQiraah(settings.displayQiraahForArabic) })
            ?? surah.ayahs.first
            ?? fallbackAyah
    }

    static var juz: Juz {
        QuranData.juzList.first ?? fallbackJuz
    }

    private static func configure(_ settings: Settings) {
        if settings.currentLocation == nil {
            settings.currentLocation = Location(city: "Makkah", latitude: 21.4225, longitude: 39.8262)
        }

        settings.showPrayerInfo = true
        seedPrayerData(on: settings)
    }

    private static func seedPrayerData(on settings: Settings) {
        let prayers = samplePrayers
        let payload = Prayers(
            day: Date(),
            city: settings.currentLocation?.city ?? "Preview City",
            prayers: prayers,
            fullPrayers: prayers,
            setNotification: false
        )

        settings.prayers = payload
        settings.datePrayers = prayers
        settings.dateFullPrayers = prayers
        settings.changedDate = false
        settings.currentPrayer = prayers.first
        settings.nextPrayer = prayers.dropFirst().first
    }

    private static var samplePrayers: [Prayer] {
        let now = Date()
        let calendar = Calendar.current

        func todayAt(hour: Int, minute: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }

        return [
            Prayer(nameArabic: "الفجر", nameTransliteration: "Fajr", nameEnglish: "Dawn", time: todayAt(hour: 5, minute: 15), image: "sunrise.fill", rakah: "2", sunnahBefore: "2", sunnahAfter: "0"),
            Prayer(nameArabic: "الظهر", nameTransliteration: "Dhuhr", nameEnglish: "Noon", time: todayAt(hour: 12, minute: 30), image: "sun.max.fill", rakah: "4", sunnahBefore: "4", sunnahAfter: "2"),
            Prayer(nameArabic: "العصر", nameTransliteration: "Asr", nameEnglish: "Afternoon", time: todayAt(hour: 15, minute: 45), image: "sun.haze.fill", rakah: "4", sunnahBefore: "0", sunnahAfter: "0"),
            Prayer(nameArabic: "المغرب", nameTransliteration: "Maghrib", nameEnglish: "Sunset", time: todayAt(hour: 18, minute: 20), image: "sunset.fill", rakah: "3", sunnahBefore: "0", sunnahAfter: "2"),
            Prayer(nameArabic: "العشاء", nameTransliteration: "Isha", nameEnglish: "Night", time: todayAt(hour: 20, minute: 0), image: "moon.stars.fill", rakah: "4", sunnahBefore: "0", sunnahAfter: "2")
        ]
    }

    private static var fallbackAyah: Ayah {
        Ayah(
            id: 1,
            idArabic: "١",
            textHafs: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            textTransliteration: "Bismillahi ar-Rahmani ar-Raheem",
            textEnglishSaheeh: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            textEnglishMustafa: "In the Name of Allah, the Most Compassionate, the Most Merciful.",
            juz: 1,
            page: 1,
            textWarsh: nil,
            textQaloon: nil,
            textDuri: nil,
            textBuzzi: nil,
            textQunbul: nil,
            textShubah: nil,
            textSusi: nil
        )
    }

    private static var fallbackSurah: Surah {
        Surah(
            id: 1,
            idArabic: "١",
            nameArabic: "الفاتحة",
            nameTransliteration: "Al-Fatihah",
            nameEnglish: "The Opening",
            type: "makkan",
            numberOfAyahs: 7,
            ayahs: [fallbackAyah]
        )
    }

    private static var fallbackJuz: Juz {
        Juz(
            id: 1,
            nameArabic: "الم",
            nameTransliteration: "Alif Lam Mim",
            startSurah: 1,
            startAyah: 1,
            endSurah: 2,
            endAyah: 141
        )
    }
}

struct AlIslamPreviewContainer<Content: View>: View {
    private let embedInNavigation: Bool
    private let content: Content

    init(embedInNavigation: Bool = true, @ViewBuilder content: () -> Content) {
        self.embedInNavigation = embedInNavigation
        self.content = content()
    }

    var body: some View {
        previewContent
            .accentColor(AlIslamPreviewData.settings.accentColor.color)
            .tint(AlIslamPreviewData.settings.accentColor.color)
            .environmentObject(AlIslamPreviewData.settings)
            .environmentObject(AlIslamPreviewData.quranData)
            .environmentObject(AlIslamPreviewData.quranPlayer)
            .environmentObject(AlIslamPreviewData.namesData)
    }

    @ViewBuilder
    private var previewContent: some View {
        if embedInNavigation {
            NavigationView {
                content
            }
        } else {
            content
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        Text("Preview Support")
            .padding()
    }
}
