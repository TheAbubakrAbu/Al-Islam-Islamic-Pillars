#if os(iOS)
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var settings: Settings

    @State private var nearestEventId = ""
    @State private var hijriYear = 1445
    @State private var hijriMonth = 1
    @State private var didAutoScrollToNearest = false
    @State private var eventRows: [HijriEventRowModel] = []
    @State private var nearestEventRow: HijriEventRowModel?

    private static let monthSymbols = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
    ]

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section(header: Text("WHAT IS HIJRI?")) {
                    Text("The Hijri calendar is the Islamic lunar calendar. It tracks months by moon cycles, so dates shift through the solar year and are primarily used for Islamic worship and sacred days.")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("Islamic events are calculated using the Umm al-Qura Hijri method selected in app settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    NavigationLink {
                        HijriCalendarView()
                    } label: {
                        Label("Learn About the Hijri Calendar", systemImage: "book.pages")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                    
                    NavigationLink {
                        DateView()
                    } label: {
                        Label("Open Hijri Date Converter", systemImage: "calendar.badge.clock")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                }

                Section(header: Text("IMPORTANT ISLAMIC DATES")) {
                    ForEach(eventRows, id: \.id) { row in
                        HijriEventRow(row: row, isPast: isPastEvent(row))
                            .id(row.id)
                    }
                }
            }
            .onAppear {
                updateInformation()
                guard !didAutoScrollToNearest else { return }
                nearestEventId = nearestEventRow?.id ?? ""
                didAutoScrollToNearest = true

                if !nearestEventId.isEmpty {
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(nearestEventId, anchor: .top)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                dateOverlayHeader
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .navigationTitle("Hijri Calendar")
        }
        .navigationViewStyle(.stack)
    }

    private func buildEventRows() -> [HijriEventRowModel] {
        settings.specialEvents.map { event in
            let date = settings.hijriCalendar.date(from: event.1)!
            let components = event.1
            let monthName = Self.monthSymbols[(components.month ?? 1) - 1]

            return HijriEventRowModel(
                id: event.0,
                title: event.0,
                subtitle: event.2,
                description: event.3,
                hijriDateText: "\(components.day ?? 1) \(monthName), \(String(components.year ?? hijriYear)) AH",
                gregorianDateText: Self.formatter.string(from: date),
                date: date
            )
        }
    }

    private func nearestEventRow(in rows: [HijriEventRowModel]) -> HijriEventRowModel? {
        let now = Date()
        return rows.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(now)) < abs(rhs.date.timeIntervalSince(now))
        }
    }

    private func isPastEvent(_ row: HijriEventRowModel) -> Bool {
        row.date < Calendar.current.startOfDay(for: Date())
    }

    @ViewBuilder
    private var dateOverlayHeader: some View {
        if let hijriDate = settings.hijriDate {
            VStack(spacing: 2) {
                Text(hijriDate.english)
                    .foregroundColor(settings.accentColor.color)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(hijriDate.arabic)
                    .foregroundColor(settings.accentColor.color)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .conditionalGlassEffect()
            .padding(.horizontal, 22)
            .padding(.top, 2)
        }
    }

    private func updateInformation() {
        let currentDate = settings.effectiveHijriReferenceDate()
        let components = settings.hijriCalendar.dateComponents([.year, .month], from: currentDate)
        hijriYear = components.year ?? 1445
        hijriMonth = components.month ?? 1
        eventRows = buildEventRows()
        nearestEventRow = nearestEventRow(in: eventRows)
        settings.updateDates()
    }
}

private struct HijriEventRowModel {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let hijriDateText: String
    let gregorianDateText: String
    let date: Date
}

private struct HijriEventRow: View {
    @EnvironmentObject private var settings: Settings

    let row: HijriEventRowModel
    let isPast: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.headline)
                    .foregroundColor(isPast ? settings.accentColor.color.opacity(0.55) : settings.accentColor.color)

                Text(row.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isPast ? .primary.opacity(0.75) : .primary)

                Text(row.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(row.hijriDateText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isPast ? .secondary : .primary)
                    .padding(.vertical, 2)

                Text(row.gregorianDateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
        }
        .padding(.vertical, 4)
        .opacity(isPast ? 0.55 : 1)
        .contextMenu {
            Text("Event Actions")
                .foregroundStyle(.secondary)

            copyButton("Copy Event Name", value: row.title)
            copyButton("Copy Event Subtitle", value: row.subtitle)
            copyButton("Copy Event Description", value: row.description)
            copyButton("Copy Hijri Date", value: row.hijriDateText)
            copyButton("Copy Gregorian Date", value: row.gregorianDateText)
        }
    }

    private func copyButton(_ title: String, value: String) -> some View {
        Button {
            UIPasteboard.general.string = value
        } label: {
            Label(title, systemImage: "doc.on.doc")
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        CalendarView()
    }
}
#endif
