import SwiftUI

struct PlayCustomRangeSheet: View {
    @EnvironmentObject var settings: Settings

    let surah: Surah
    let initialStartAyah: Int
    let initialEndAyah: Int
    let onPlay: (Int, Int, Int, Int) -> Void
    let onCancel: () -> Void

    @State private var startAyah: Int
    @State private var endAyah: Int
    @State private var startAyahText: String
    @State private var endAyahText: String
    @State private var repeatPerAyah: Int
    @State private var repeatSection: Int
    @State private var repeatPerAyahText: String
    @State private var repeatSectionText: String

    private static let repeatMin = 1
    private static let repeatMax = 20
    private static let repeatOptions = [1, 2, 3, 5, 10, 20]

    init(
        surah: Surah,
        initialStartAyah: Int,
        initialEndAyah: Int,
        onPlay: @escaping (Int, Int, Int, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.surah = surah
        self.initialStartAyah = initialStartAyah
        self.initialEndAyah = initialEndAyah
        self.onPlay = onPlay
        self.onCancel = onCancel
        _startAyah = State(initialValue: initialStartAyah)
        _endAyah = State(initialValue: initialEndAyah)
        _startAyahText = State(initialValue: "\(initialStartAyah)")
        _endAyahText = State(initialValue: "\(initialEndAyah)")
        _repeatPerAyah = State(initialValue: 1)
        _repeatSection = State(initialValue: 1)
        _repeatPerAyahText = State(initialValue: "1")
        _repeatSectionText = State(initialValue: "1")
    }

    private var canPlay: Bool {
        startAyah >= 1 && endAyah <= surah.numberOfAyahs && startAyah <= endAyah
    }

    private var ayahCount: Int {
        max(0, endAyah - startAyah + 1)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    surahHeaderCard
                    rangeCard
                    repeatsCard
                    arabicVersesCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .dismissKeyboardOnScroll()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        settings.hapticFeedback()
                        onCancel()
                    }
                    .foregroundColor(settings.accentColor.color)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                playButtonBar
            }
        }
        .id("\(initialStartAyah)-\(initialEndAyah)")
    }

    private var surahHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundStyle(settings.accentColor.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliteration)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Surah \(surah.id) · \(surah.numberOfAyahs) ayahs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ayah range", systemImage: "number")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                rangeField(title: "From", value: $startAyah, text: $startAyahText, max: surah.numberOfAyahs) { new in
                    if new > endAyah { endAyah = new; endAyahText = "\(endAyah)" }
                }
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))
                rangeField(title: "To", value: $endAyah, text: $endAyahText, max: surah.numberOfAyahs) { new in
                    if new < startAyah { startAyah = new; startAyahText = "\(startAyah)" }
                }
            }
            .onChange(of: startAyah) { ayah in
                startAyahText = "\(ayah)"
            }
            .onChange(of: endAyah) { ayah in
                endAyahText = "\(endAyah)"
            }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.2)) {
                    startAyah = 1
                    endAyah = surah.numberOfAyahs
                    startAyahText = "1"
                    endAyahText = "\(surah.numberOfAyahs)"
                }
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Whole surah (1–\(surah.numberOfAyahs))")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(settings.accentColor.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("\(ayahCount) ayah\(ayahCount == 1 ? "" : "s") in range")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func rangeField(title: String, value: Binding<Int>, text: Binding<String>, max: Int, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 0) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        let new = value.wrappedValue > 1 ? value.wrappedValue - 1 : 1
                        value.wrappedValue = new
                        text.wrappedValue = "\(new)"
                        onChange(new)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue > 1 ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(value.wrappedValue <= 1)

                Spacer()
                TextField("", text: text)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 44, alignment: .center)
                    .onSubmit {
                        commitAyahInput(value: value, text: text, max: max, onChange: onChange)
                    }
                Spacer()

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        let new = value.wrappedValue < max ? value.wrappedValue + 1 : max
                        value.wrappedValue = new
                        text.wrappedValue = "\(new)"
                        onChange(new)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue < max ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(value.wrappedValue >= max)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private func commitAyahInput(value: Binding<Int>, text: Binding<String>, max: Int, onChange: @escaping (Int) -> Void) {
        let parsed = Int(text.wrappedValue.trimmingCharacters(in: .whitespaces)) ?? value.wrappedValue
        let clamped = min(Swift.max(1, parsed), max)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
        onChange(clamped)
    }

    private func commitBothAyahFields() {
        let maxAyah = surah.numberOfAyahs
        let s = min(Swift.max(1, Int(startAyahText.trimmingCharacters(in: .whitespaces)) ?? startAyah), maxAyah)
        let e = min(Swift.max(1, Int(endAyahText.trimmingCharacters(in: .whitespaces)) ?? endAyah), maxAyah)
        let from = min(s, e)
        let to = Swift.max(s, e)
        startAyah = from
        endAyah = to
        startAyahText = "\(from)"
        endAyahText = "\(to)"
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private var repeatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Repeats", systemImage: "repeat")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            repeatRow(title: "Each ayah", value: $repeatPerAyah, text: $repeatPerAyahText)
            repeatRow(title: "Whole section", value: $repeatSection, text: $repeatSectionText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var arabicVersesCard: some View {
        Group {
            if let first = surah.ayahs.first(where: { $0.id == startAyah }),
               let last = surah.ayahs.first(where: { $0.id == endAyah }) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("First & last ayah", systemImage: "text.quote.rtl")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ayah \(startAyah)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        Text(first.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                            .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(nil)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if startAyah != endAyah {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ayah \(endAyah)")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Color(.tertiaryLabel))
                            
                            Text(last.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                                .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize))
                                .multilineTextAlignment(.trailing)
                                .lineLimit(nil)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func repeatRow(title: String, value: Binding<Int>, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.repeatOptions, id: \.self) { n in
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    value.wrappedValue = n
                                    text.wrappedValue = "\(n)"
                                }
                            } label: {
                                Text("\(n)×")
                                    .font(.subheadline.weight(value.wrappedValue == n ? .semibold : .regular))
                                    .foregroundColor(value.wrappedValue == n ? .white : .primary)
                                    .padding(8)
                                    .background(
                                        value.wrappedValue == n
                                            ? settings.accentColor.color
                                            : Color(UIColor.tertiarySystemFill)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)

                repeatStepper(value: value, text: text)
            }
        }
        .onChange(of: value.wrappedValue) { newValue in
            text.wrappedValue = "\(newValue)"
        }
    }

    private func repeatStepper(value: Binding<Int>, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.15)) {
                    let new = value.wrappedValue > Self.repeatMin ? value.wrappedValue - 1 : Self.repeatMin
                    value.wrappedValue = new
                    text.wrappedValue = "\(new)"
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.body)
                    .foregroundStyle(value.wrappedValue > Self.repeatMin ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue <= Self.repeatMin)

            TextField("", text: text)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 32, alignment: .center)
                .onSubmit { commitRepeatInput(value: value, text: text) }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.15)) {
                    let new = value.wrappedValue < Self.repeatMax ? value.wrappedValue + 1 : Self.repeatMax
                    value.wrappedValue = new
                    text.wrappedValue = "\(new)"
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                    .foregroundStyle(value.wrappedValue < Self.repeatMax ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue >= Self.repeatMax)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func commitRepeatInput(value: Binding<Int>, text: Binding<String>) {
        let parsed = Int(text.wrappedValue.trimmingCharacters(in: .whitespaces)) ?? value.wrappedValue
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    private func commitAllRepeatFields() {
        commitRepeatInput(value: $repeatPerAyah, text: $repeatPerAyahText)
        commitRepeatInput(value: $repeatSection, text: $repeatSectionText)
    }

    private var playButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                settings.hapticFeedback()
                commitBothAyahFields()
                commitAllRepeatFields()
                onPlay(startAyah, endAyah, repeatPerAyah, repeatSection)
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Play range")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .background(canPlay ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canPlay)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

#Preview {
    QuranView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
