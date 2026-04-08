#if os(iOS)
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
    
    @FocusState private var startAyahFocused: Bool
    @FocusState private var endAyahFocused: Bool
    @FocusState private var repeatPerAyahFocused: Bool
    @FocusState private var repeatSectionFocused: Bool

    private static let repeatMin = 1
    private static let repeatMax = 20
    private static let repeatOptions = [1, 2, 3, 5, 10, 15, 20]

    /// End ayah defaults to the ayah after `startAyah` (one-ayah range when possible); if `startAyah` is the last ayah, end matches start.
    static func defaultEndAyah(startAyah: Int, surah: Surah, displayQiraah: String?) -> Int {
        let maxA = surah.numberOfAyahs(for: displayQiraah)
        return min(max(startAyah + 1, 1), maxA)
    }

    private var maxAyah: Int { surah.numberOfAyahs(for: settings.displayQiraahForArabic) }

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
        startAyah >= 1 && endAyah <= maxAyah && startAyah <= endAyah
    }

    private func clampRangeToMaxAyah() {
        let m = maxAyah
        if endAyah > m { endAyah = m; endAyahText = "\(m)" }
        if startAyah > m { startAyah = m; startAyahText = "\(m)" }
        if startAyah < 1 { startAyah = 1; startAyahText = "1" }
        if endAyah < 1 { endAyah = 1; endAyahText = "1" }
        if startAyah > endAyah { endAyah = startAyah; endAyahText = "\(startAyah)" }
    }

    private var ayahCount: Int {
        max(0, endAyah - startAyah + 1)
    }

    @ViewBuilder
    private var ayahCountLabel: some View {
        let label = Text("\(ayahCount) ayah\(ayahCount == 1 ? "" : "s") in range")
            .font(.caption)
            .foregroundColor(Color(.tertiaryLabel))

        if #available(iOS 16.0, watchOS 9.0, *) {
            label.contentTransition(.numericText())
        } else {
            label
        }
    }

    private func sanitizedNumberText(from value: String) -> String {
        value.filter(\.isNumber)
    }

    private func syncAyahTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)
        
        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }
        
        // While keyboard is active, allow any value (even empty or invalid)
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = parsed
            }
            return
        }
        
        // When keyboard is dismissed, validate and clamp
        guard !sanitized.isEmpty else {
            text.wrappedValue = "\(value.wrappedValue)"
            value.wrappedValue = 1
            return
        }
        
        let parsed = Int(sanitized) ?? 1
        let clamped = min(Swift.max(1, parsed), maxAyah)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    private func syncRepeatTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        // While keyboard is active, allow any value (even empty or invalid)
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = parsed
            }
            return
        }
        
        // When keyboard is dismissed, validate and clamp
        guard !sanitized.isEmpty else {
            text.wrappedValue = "\(value.wrappedValue)"
            value.wrappedValue = Self.repeatMin
            return
        }

        let parsed = Int(sanitized) ?? Self.repeatMin
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    private func adjustAyahValue(_ value: Binding<Int>, text: Binding<String>, delta: Int, onChange: @escaping (Int) -> Void) {
        commitBothAyahFields()

        let newValue = min(Swift.max(1, value.wrappedValue + delta), maxAyah)
        withAnimation(.easeInOut(duration: 0.15)) {
            value.wrappedValue = newValue
            text.wrappedValue = "\(newValue)"
            onChange(newValue)
        }
    }

    private func adjustRepeatValue(_ value: Binding<Int>, text: Binding<String>, delta: Int) {
        commitRepeatInput(value: value, text: text)

        let newValue = min(Swift.max(Self.repeatMin, value.wrappedValue + delta), Self.repeatMax)
        withAnimation(.easeInOut(duration: 0.15)) {
            value.wrappedValue = newValue
            text.wrappedValue = "\(newValue)"
        }
    }

    private func syncRepeatTextInput(value: Binding<Int>, text: Binding<String>) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        guard !sanitized.isEmpty else { return }

        let parsed = Int(sanitized) ?? value.wrappedValue
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)

        if parsed != clamped {
            text.wrappedValue = "\(clamped)"
        }

        if value.wrappedValue != clamped {
            withAnimation(.easeInOut(duration: 0.18)) {
                value.wrappedValue = clamped
            }
        }
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
            .safeAreaInset(edge: .bottom) {
                playButtonBar
            }
        }
        .onAppear { clampRangeToMaxAyah() }
        .onChange(of: settings.displayQiraahForArabic) { _ in clampRangeToMaxAyah() }
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
                Text("Surah \(surah.id) · \(maxAyah) ayahs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ayah range", systemImage: "number")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        startAyah = 1
                        startAyahText = "1"
                    }
                } label: {
                    Label("Go to start", systemImage: "arrow.left.to.line")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(settings.accentColor.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .contentShape(Rectangle())
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        endAyah = maxAyah
                        endAyahText = "\(maxAyah)"
                    }
                } label: {
                    Label("Go to end", systemImage: "arrow.right.to.line")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(settings.accentColor.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .contentShape(Rectangle())
                }
            }

            HStack(spacing: 12) {
                rangeField(title: "From", value: $startAyah, text: $startAyahText, isFocused: $startAyahFocused) { new in
                    if new > endAyah {
                        startAyah = endAyah
                        startAyahText = "\(endAyah)"
                    }
                }
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))
                rangeField(title: "To", value: $endAyah, text: $endAyahText, isFocused: $endAyahFocused) { new in
                    if new < startAyah {
                        endAyah = startAyah
                        endAyahText = "\(startAyah)"
                    }
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
                    endAyah = maxAyah
                    startAyahText = "1"
                    endAyahText = "\(maxAyah)"
                }
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Whole surah (1–\(maxAyah))")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(settings.accentColor.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
            }

            ayahCountLabel
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .animation(.easeInOut, value: startAyah)
        .animation(.easeInOut, value: endAyah)
    }

    private func rangeField(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 0) {
                Button {
                    settings.hapticFeedback()
                    adjustAyahValue(value, text: text, delta: -1, onChange: onChange)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue > 1 ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .disabled(value.wrappedValue <= 1)

                Spacer()
                
                TextField("", text: text)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 44, alignment: .center)
                    .focused(isFocused)
                    .onChange(of: text.wrappedValue) { _ in
                        syncAyahTextInput(value: value, text: text, isFocused: isFocused.wrappedValue)
                    }
                    .onChange(of: isFocused.wrappedValue) { newValue in
                        // When keyboard dismisses (newValue = false), validate both fields together
                        if !newValue {
                            commitBothAyahFields()
                        }
                    }
                    .onSubmit {
                        commitBothAyahFields()
                    }
                
                Spacer()
                
                Button {
                    settings.hapticFeedback()
                    adjustAyahValue(value, text: text, delta: 1, onChange: onChange)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue < maxAyah ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                }
                .disabled(value.wrappedValue >= maxAyah)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
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
        let s = Int(startAyahText.trimmingCharacters(in: .whitespaces)) ?? startAyah
        let e = Int(endAyahText.trimmingCharacters(in: .whitespaces)) ?? endAyah
        
        // Clamp to 1...maxAyah (handles negatives and out-of-range)
        let clampedStart = min(Swift.max(1, s), maxAyah)
        let clampedEnd = min(Swift.max(1, e), maxAyah)
        
        // Ensure start <= end (if not, swap to make valid range)
        let from = min(clampedStart, clampedEnd)
        let to = Swift.max(clampedStart, clampedEnd)
        
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

            repeatRow(title: "Each ayah", value: $repeatPerAyah, text: $repeatPerAyahText, isFocused: $repeatPerAyahFocused)
            repeatRow(title: "Whole section", value: $repeatSection, text: $repeatSectionText, isFocused: $repeatSectionFocused)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
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
                .contentShape(Rectangle())
                .animation(.easeInOut, value: startAyah)
                .animation(.easeInOut, value: endAyah)
            }
        }
    }

    private func repeatRow(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
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
                                withAnimation {
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
                                    .contentShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)

                repeatStepper(value: value, text: text, isFocused: isFocused)
            }
        }
        .onChange(of: value.wrappedValue) { newValue in
            text.wrappedValue = "\(newValue)"
        }
    }

    private func repeatStepper(value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        HStack(spacing: 4) {
            Button {
                settings.hapticFeedback()
                adjustRepeatValue(value, text: text, delta: -1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.body)
                    .foregroundStyle(value.wrappedValue > Self.repeatMin ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
            }
            .disabled(value.wrappedValue <= Self.repeatMin)

            TextField("", text: text)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 32, alignment: .center)
                .focused(isFocused)
                .onChange(of: text.wrappedValue) { _ in
                    syncRepeatTextInput(value: value, text: text, isFocused: isFocused.wrappedValue)
                }
                .onChange(of: isFocused.wrappedValue) { newValue in
                    // When keyboard dismisses (newValue = false), validate
                    if !newValue {
                        commitAllRepeatFields()
                    }
                }
                .onSubmit { commitAllRepeatFields() }

            Button {
                settings.hapticFeedback()
                adjustRepeatValue(value, text: text, delta: 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                    .foregroundStyle(value.wrappedValue < Self.repeatMax ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
            }
            .disabled(value.wrappedValue >= Self.repeatMax)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
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
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
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
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
            }
            .disabled(!canPlay)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        PlayCustomRangeSheet(
            surah: AlIslamPreviewData.surah,
            initialStartAyah: 1,
            initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                startAyah: 1,
                surah: AlIslamPreviewData.surah,
                displayQiraah: AlIslamPreviewData.settings.displayQiraahForArabic
            ),
            onPlay: { _, _, _, _ in },
            onCancel: {}
        )
    }
}
#endif
