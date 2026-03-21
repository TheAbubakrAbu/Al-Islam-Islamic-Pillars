import SwiftUI

struct TasbihView: View {
    @EnvironmentObject var settings: Settings

    @State private var counters: [Int: Int] = [:]
    @State private var selectedDhikrIndex: Int = 0

    let tasbihData: [(arabic: String, english: String, translation: String)] = [
        (arabic: "سُبحَانَ اللّٰه", english: "Subhanallah", translation: "Glory be to Allah"),
        (arabic: "الحَمدُ لِلّٰه", english: "Alhamdullilah", translation: "Praise be to Allah"),
        (arabic: "اللّٰهُ أَكبَر", english: "Allahu Akbar", translation: "Allah is the Greatest"),
        (arabic: "أَستَغفِرُ اللّٰه", english: "Astaghfirullah", translation: "I seek Allah's forgiveness"),
    ]

    private func binding(for index: Int) -> Binding<Int> {
        Binding<Int>(
            get: { self.counters[index, default: 0] },
            set: { self.counters[index] = $0 }
        )
    }

    var body: some View {
        List {
            Section(header: Text("GLORIFICATIONS OF ALLAH ﷻ‎")) {
                ForEach(tasbihData.indices, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(selectedDhikrIndex == index ? settings.accentColor.color.opacity(0.15) : .white.opacity(0.0001))
                            #if !os(watchOS)
                            .padding(.horizontal, -12)
                            .padding(.vertical, -11)
                            #else
                            .padding(-7)
                            #endif

                        TasbihRow(tasbih: tasbihData[index], counter: binding(for: index))
                    }
                    #if os(watchOS)
                    .padding(.vertical, 12)
                    #endif
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation {
                            self.selectedDhikrIndex = index
                        }
                    }
                }
            }

            let selectedDhikr = tasbihData[selectedDhikrIndex]
            let counterBinding = binding(for: selectedDhikrIndex)

            Section {
                ZStack {
                    ProgressCircleView(progress: counterBinding.wrappedValue)
                        .scaledToFit()
                        .frame(maxWidth: 185, maxHeight: 185)

                    VStack(alignment: .center, spacing: 5) {
                        Text(selectedDhikr.arabic)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(settings.accentColor.color)

                        Text(selectedDhikr.english)
                            .font(.subheadline)

                        CounterView(counter: counterBinding)
                    }
                }
                .padding()
                .cornerRadius(24)
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    settings.hapticFeedback()
                    counters[selectedDhikrIndex, default: 0] += 1
                }
            }
        }
        .onAppear {
            for index in tasbihData.indices {
                counters[index] = counters[index] ?? 0
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .compactListSectionSpacing()
        .navigationTitle("Tasbih Counter")
    }
}

struct ProgressCircleView: View {
    var progress: Int
    @EnvironmentObject var settings: Settings

    var body: some View {
        let progressFraction = CGFloat(progress % 33) / 33
        return ZStack {
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(settings.accentColor.color)

            Circle()
                .trim(from: 0.0, to: progressFraction)
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                .foregroundColor(settings.accentColor.color)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progressFraction)
        }
    }
}

struct CounterView: View {
    @EnvironmentObject var settings: Settings

    @Binding var counter: Int

    var body: some View {
        VStack(alignment: .center) {
            Text("\(counter)")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.horizontal, 2)

            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

struct TasbihRow: View {
    @EnvironmentObject var settings: Settings

    let tasbih: (arabic: String, english: String, translation: String)

    @Binding var counter: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(tasbih.arabic)
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text(tasbih.english)
                    .font(.subheadline)

                Text(tasbih.translation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack {
                HStack {
                    Image(systemName: "minus.circle")
                        .foregroundColor(counter == 0 ? .secondary : settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()

                            if counter > 0 {
                                counter -= 1
                            }
                        }

                    Text("\(counter)")

                    Image(systemName: "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()
                            counter += 1
                        }
                }

                Text("Reset")
                    .font(.subheadline)
                    .onTapGesture {
                        settings.hapticFeedback()
                        counter = 0
                    }
            }
        }
        #if !os(watchOS)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = tasbih.arabic
                settings.hapticFeedback()
            }) {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button(action: {
                UIPasteboard.general.string = tasbih.english
                settings.hapticFeedback()
            }) {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button(action: {
                UIPasteboard.general.string = tasbih.translation
                settings.hapticFeedback()
            }) {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }
}
