import SwiftUI

struct TasbihView: View {
    @EnvironmentObject var settings: Settings

    @State private var counters: [Int: Int] = [:]
    @State private var selectedDhikrIndex: Int = 0

    let tasbihData: [(arabic: String, english: String, translation: String)] = [
        (arabic: "سُبحَانَ اللّٰه", english: "Subhanallah", translation: "Glory be to Allah"),
        (arabic: "الحَمدُ لِلّٰه", english: "Alhamdullilah", translation: "Praise be to Allah"),
        (arabic: "اللّٰهُ أَكبَر", english: "Allahu Akbar", translation: "Allah is the Greatest"),
        (arabic: "أَستَغفِرُ اللّٰه", english: "Astaghfirullah", translation: "I seek Allah's forgiveness")
    ]

    private func binding(for index: Int) -> Binding<Int> {
        Binding(
            get: { counters[index, default: 0] },
            set: { counters[index] = $0 }
        )
    }

    var body: some View {
        List {
            dhikrSelectionSection
            activeTasbihSection
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

    private var dhikrSelectionSection: some View {
        Section(header: Text("GLORIFICATIONS OF ALLAH‎")) {
            ForEach(tasbihData.indices, id: \.self) { index in
                tasbihSelectionButton(for: index)
            }
        }
    }

    private func tasbihSelectionButton(for index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(selectedDhikrIndex == index ? settings.accentColor.color.opacity(0.15) : .clear)
                #if os(iOS)
                .padding(.horizontal, -12)
                .padding(.vertical, tasbihSelectionBackgroundVerticalPadding)
                #else
                .padding(-7)
                #endif

            TasbihRow(tasbih: tasbihData[index], counter: binding(for: index))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if index != selectedDhikrIndex {
                withAnimation {
                    settings.hapticFeedback()
                    selectedDhikrIndex = index
                }
            }
        }
        #if os(watchOS)
        .padding(.vertical, 12)
        #endif
    }

    #if os(iOS)
    private var tasbihSelectionBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    private var activeTasbihSection: some View {
        let selectedDhikr = tasbihData[selectedDhikrIndex]
        let counterBinding = binding(for: selectedDhikrIndex)

        return Section {
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
                        .foregroundColor(.primary)

                    CounterView(counter: counterBinding)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
            .contentShape(Rectangle())
        }
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                counters[selectedDhikrIndex, default: 0] += 1
            }
        }
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
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundColor(.primary)
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
            textColumn
            
            Spacer()
            
            counterControls
        }
        .contentShape(Rectangle())
        #if os(iOS)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = tasbih.arabic
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = tasbih.english
            } label: {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = tasbih.translation
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }

    private var textColumn: some View {
        VStack(alignment: .leading) {
            Text(tasbih.arabic)
                .font(.headline)
                .foregroundColor(settings.accentColor.color)

            Text(tasbih.english)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(tasbih.translation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var counterControls: some View {
        VStack {
            HStack {
                Image(systemName: "minus.circle")
                    .foregroundColor(counter == 0 ? .secondary : settings.accentColor.color)
                    .padding(6)
                    .conditionalGlassEffect()
                    .onTapGesture {
                        if counter > 0 {
                            settings.hapticFeedback()
                            withAnimation { counter -= 1 }
                        }
                    }
                    .disabled(counter <= 0)

                Text("\(counter)")
                    .font(.subheadline)
                    .monospacedDigit()

                Image(systemName: "plus.circle")
                    .foregroundColor(settings.accentColor.color)
                    .padding(6)
                    .conditionalGlassEffect()
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation { counter += 1 }
                    }
            }

            Text("Reset")
                .font(.subheadline)
                .padding(6)
                .conditionalGlassEffect()
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { counter = 0 }
                }
                .disabled(counter <= 0)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        TasbihView()
    }
}
