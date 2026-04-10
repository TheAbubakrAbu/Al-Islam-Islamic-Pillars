#if os(iOS)
import SwiftUI

struct HijriCalendarView: View {
    @EnvironmentObject private var settings: Settings

    @State private var nearestEventId = ""
    @State private var hijriYear = 1445
    @State private var hijriMonth = 1

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
                Section(header: Text("IMPORTANT ISLAMIC DATES")) {
                    ForEach(eventRows, id: \.id) { row in
                        HijriEventRow(row: row)
                            .id(row.id)
                    }
                }
            }
            .onAppear {
                updateInformation()
                nearestEventId = nearestEventRow?.id ?? ""

                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo(nearestEventId, anchor: .top)
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

    private var eventRows: [HijriEventRowModel] {
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

    private var nearestEventRow: HijriEventRowModel? {
        let now = Date()
        return eventRows.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(now)) < abs(rhs.date.timeIntervalSince(now))
        }
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

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(row.title)
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text(row.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(row.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing) {
                Text(row.hijriDateText)
                    .font(.caption)
                    .padding(.vertical, 2)

                Text(row.gregorianDateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
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
        HijriCalendarView()
    }
}
#endif
