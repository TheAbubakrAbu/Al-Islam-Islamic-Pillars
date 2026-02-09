import SwiftUI

/// Holds the current image generation request id so completion blocks can check against the latest (avoids applying stale images after many rapid toggles).
private final class ShareImageGenerationId: ObservableObject {
    var value: Int = 0
}

enum ActionMode: String {
    case text
    case image
}

struct ShareAyahSheet: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    
    @Environment(\.presentationMode) private var presentationMode
    
    let surahNumber: Int
    let ayahNumber: Int
    
    @State private var shareSettings = ShareSettings()

    @AppStorage("shareIncludeRiwayah") private var shareIncludeRiwayah = false
    @AppStorage("shareArabicFont") private var storedShareArabicFont = ""
    @AppStorage("shareAyahLastActionMode") private var storedActionModeRaw: String = ActionMode.image.rawValue
    @State private var actionMode: ActionMode = .image
    
    @State private var didInit = false
    
    @State private var generatedImage: UIImage?
    @State private var activityItems: [Any] = []
    @State private var showingActivityView = false
    @State private var includeNote: Bool = false
    @StateObject private var imageGenerationIdHolder = ShareImageGenerationId()
    private static let shareImageQueue = DispatchQueue(label: "app.shareAyah.imageGeneration", qos: .userInitiated)
    
    private func fetchNote() -> String? {
        if let idx = settings.bookmarkedAyahs.firstIndex(where: {
            $0.surah == surahNumber && $0.ayah == ayahNumber
        }) {
            let trimmed = settings.bookmarkedAyahs[idx].note?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (trimmed?.isEmpty == true) ? nil : trimmed
        }
        return nil
    }
    
    private var noteText: String? {
        guard let n = fetchNote()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !n.isEmpty else { return nil }
        return n
    }
        
    private var surah: Surah? { quranData.quran.first(where: { $0.id == surahNumber }) }
    private var ayah: Ayah? { surah?.ayahs.first(where: { $0.id == ayahNumber }) }
    
    private var shareText: String {
        guard let surah = surah, let ayah = ayah else { return "Loading…" }

        var s = ""

        @inline(__always) func sepIfNeeded() {
            if !s.isEmpty { s += "\n\n" }
        }

        @inline(__always) func appendBlock(label: String?, text: String?) {
            guard let text = text, !text.isEmpty else { return }
            sepIfNeeded()
            if let label = label, !label.isEmpty {
                s += "\(label)\n"
            }
            s += text
        }

        // Arabic
        if shareSettings.arabic {
            let header: String? = settings.showAyahInformation
                ? "[\(surah.nameArabic) \(surah.idArabic):\(ayah.idArabic)]"
                : nil

            let arabicText = ayah.displayArabicText(surahId: surah.id, clean: shareSettings.cleanArabic)
            appendBlock(
                label: header,
                text: (settings.showAyahInformation ? arabicText : "\(arabicText) \(ayah.idArabic)")
            )
        }

        // Transliteration (Hafs an Asim only)
        if shareSettings.transliteration, settings.isHafsDisplay {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameTransliteration

            let header: String? = settings.showAyahInformation
                ? "[\(trLabelName) \(surah.id):\(ayah.id)]"
                : nil
            
            appendBlock(
                label: header,
                text: settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))"
            )
        }

        // English
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let headerName = (!shareSettings.transliteration)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameEnglish

            sepIfNeeded()

            if settings.showAyahInformation {
                s += "[\(headerName) \(surah.id):\(ayah.id)]\n"
            }

            if shareSettings.englishSaheeh {
                if settings.showAyahInformation {
                    s += "— Saheeh International\n"
                }
                
                s += settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))"
            }

            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n\n" } else if !settings.showAyahInformation { /* keep as-is */ } else { s += "\n" }
                if settings.showAyahInformation {
                    s += "— Mustafa Khattab\n"
                }
                s += settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))"
            }
        }

        // Note
        if includeNote, let note = noteText {
            appendBlock(label: "Note", text: note)
        }

        // Qiraah type (optional) — one line: Riwayah: English - Arabic
        if shareSettings.includeQiraah {
            let labels = Self.qiraahLabels(displayQiraah: settings.displayQiraah)
            appendBlock(label: nil, text: "Riwayah: \(labels.english) – \(labels.arabic)")
        }

        if settings.showSurahInformation {
            if shareSettings.includeQiraah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")"
        }

        return s
    }
    
    private func combinedName(translit: String, english: String) -> String {
        if translit.isEmpty { return english }
        if english.isEmpty { return translit }
        return "\(translit) | \(english)"
    }

    /// Returns (English, Arabic) display names for the given displayQiraah tag.
    private static func qiraahLabels(displayQiraah: String) -> (english: String, arabic: String) {
        let key = displayQiraah.isEmpty ? "" : displayQiraah
        let map: [(tag: String, en: String, ar: String)] = [
            ("", "Hafs an Asim (default)", "حَفْص عَنْ عَاصِم"),
            ("Warsh an Nafi", "Warsh an Nafi", "وَرْش عَنْ نَافِع"),
            ("Qaloon an Nafi", "Qaloon an Nafi", "قَالُون عَنْ نَافِع"),
            ("Ad-Duri an Abi Amr", "Ad-Duri an Abi Amr", "الدُّورِي عَنْ أَبِي عَمْرٍو"),
            ("Al-Buzzi an Ibn Kathir", "Al-Buzzi an Ibn Kathir", "البَزِّي عَنْ ابْنِ كَثِيرٍ"),
            ("Qunbul an Ibn Kathir", "Qunbul an Ibn Kathir", "قُنْبُل عَنْ ابْنِ كَثِيرٍ"),
            ("Shu'bah an Asim", "Shu'bah an Asim", "شُعْبَة عَنْ عَاصِم"),
            ("As-Susi an Abi Amr", "As-Susi an Abi Amr", "السُّوسِي عَنْ أَبِي عَمْرٍو")
        ]
        
        return map.first(where: { $0.tag == key }).map { ($0.en, $0.ar) } ?? (map[0].en, map[0].ar)
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Group {
                    if actionMode == .image {
                        if let img = generatedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(24)
                                .padding(.horizontal, 16)
                                .contextMenu { copyMenu(image: img) }
                        }
                    } else {
                        Text(shareText)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            .contextMenu { copyMenu(image: generatedImage) }
                            .lineLimit(nil)
                            .minimumScaleFactor(0.1)
                    }
                }
                
                Spacer()

                ScrollView {
                    VStack(spacing: 2) {
                        toggle("Arabic", $shareSettings.arabic,
                               disabled: !shareSettings.transliteration && !shareSettings.englishSaheeh && !shareSettings.englishMustafa)

                        if settings.isHafsDisplay {
                            toggle("Transliteration", $shareSettings.transliteration,
                                   disabled: !shareSettings.arabic && !shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                            toggle("Translation — Saheeh International", $shareSettings.englishSaheeh,
                                   disabled: !shareSettings.arabic && !shareSettings.transliteration && !shareSettings.englishMustafa)
                            toggle("Translation — Mustafa Khattab", $shareSettings.englishMustafa,
                                   disabled: !shareSettings.arabic && !shareSettings.transliteration && !shareSettings.englishSaheeh)
                        }

                        if noteText != nil {
                            Toggle("Include Note", isOn: $includeNote.animation(.easeInOut))
                                .tint(settings.accentColor.color)
                                .scaleEffect(0.8)
                                .padding(.horizontal, -24)
                                .padding(.vertical, 2)
                        }
                        
                        if shareSettings.arabic {
                            Picker("Arabic Font", selection: Binding(
                                get: { shareSettings.shareArabicFont.isEmpty ? (settings.fontArabic) : shareSettings.shareArabicFont },
                                set: { val in
                                    storedShareArabicFont = val
                                    shareSettings = ShareSettings(
                                        arabic: shareSettings.arabic,
                                        transliteration: shareSettings.transliteration,
                                        englishSaheeh: shareSettings.englishSaheeh,
                                        englishMustafa: shareSettings.englishMustafa,
                                        includeQiraah: shareSettings.includeQiraah,
                                        shareArabicFont: val,
                                        cleanArabic: shareSettings.cleanArabic
                                    )
                                }
                            ).animation(.easeInOut)) {
                                Text("Uthmani").tag("KFGQPCQUMBULUthmanicScript-Regu")
                                Text("Indopak").tag("Al_Mushaf")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)

                            Toggle("Clean Arabic Text (No Tashkeel)", isOn: $shareSettings.cleanArabic.animation(.easeInOut))
                                .tint(settings.accentColor.color)
                                .scaleEffect(0.8)
                                .padding(.horizontal, -24)
                                .padding(.vertical, 2)
                        }

                        Toggle("Show Ayah Information", isOn: $settings.showAyahInformation.animation(.easeInOut))
                            .tint(settings.accentColor.color)
                            .scaleEffect(0.8)
                            .padding(.horizontal, -24)
                            .padding(.vertical, 2)

                        Toggle("Show Surah Information", isOn: $settings.showSurahInformation.animation(.easeInOut))
                            .tint(settings.accentColor.color)
                            .scaleEffect(0.8)
                            .padding(.horizontal, -24)
                            .padding(.vertical, 2)

                        Toggle("Include Riwayah/Qiraah type", isOn: Binding(
                            get: { shareSettings.includeQiraah },
                            set: { shareIncludeRiwayah = $0; shareSettings = ShareSettings(arabic: shareSettings.arabic, transliteration: shareSettings.transliteration, englishSaheeh: shareSettings.englishSaheeh, englishMustafa: shareSettings.englishMustafa, includeQiraah: $0, shareArabicFont: shareSettings.shareArabicFont, cleanArabic: shareSettings.cleanArabic) }
                        ).animation(.easeInOut))
                            .tint(settings.accentColor.color)
                            .scaleEffect(0.8)
                            .padding(.horizontal, -24)
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxHeight: 200)

                Picker("Action Mode", selection: $actionMode.animation(.easeInOut)) {
                    Text("Image").tag(ActionMode.image)
                    Text("Text").tag(ActionMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                
                HStack(spacing: 12) {
                    actionButton("Copy")   { performCopyOrGenerate() }
                    actionButton("Share")  { performShareOrGenerate() }
                }
                .padding(.horizontal, 16)
                .padding(.bottom)
                .sheet(isPresented: $showingActivityView) {
                    if #available(iOS 16.0, *) {
                        ActivityView(activityItems: activityItems)
                            .presentationDetents([.medium])
                    } else {
                        ActivityView(activityItems: activityItems)
                    }
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accentColor(settings.accentColor.color)
        .onAppear {
            guard !didInit else { return }
            didInit = true

            withAnimation {
                let font = storedShareArabicFont.isEmpty ? settings.fontArabic : storedShareArabicFont
                shareSettings = ShareSettings(
                    arabic: settings.showArabicText,
                    transliteration: settings.isHafsDisplay ? settings.showTransliteration : false,
                    englishSaheeh: settings.isHafsDisplay ? settings.showEnglishSaheeh : false,
                    englishMustafa: settings.isHafsDisplay ? settings.showEnglishMustafa : false,
                    includeQiraah: shareIncludeRiwayah,
                    shareArabicFont: font,
                    cleanArabic: settings.cleanArabicText
                )
                
                actionMode = ActionMode(rawValue: storedActionModeRaw) ?? .image
                generatePreviewImage()
            }
        }

        .onChange(of: actionMode) { newValue in
            storedActionModeRaw = newValue.rawValue
            if newValue == .image && generatedImage == nil {
                generatePreviewImage()
            }
        }
        .onChange(of: shareSettings) { _ in generatePreviewImage() }
        .onChange(of: settings.showSurahInformation) { _ in generatePreviewImage() }
        .onChange(of: settings.showAyahInformation) { _ in generatePreviewImage() }
        .onChange(of: includeNote) { _ in generatePreviewImage() }
        .onChange(of: shareIncludeRiwayah) { _ in generatePreviewImage() }
        .onChange(of: showingActivityView) { if !$0 { presentationMode.wrappedValue.dismiss() } }
    }
    
    @ViewBuilder
    private func toggle(_ title: LocalizedStringKey, _ binding: Binding<Bool>, disabled: Bool) -> some View {
        Toggle(isOn: binding.animation(.easeInOut)) {
            Text(title).foregroundColor(.primary)
        }
        .tint(settings.accentColor.color)
        .disabled(disabled)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
    
    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            settings.hapticFeedback(); action()
        }) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(settings.accentColor.color)
                .cornerRadius(24)
                .foregroundColor(.primary)
        }
    }
    
    private func copyMenu(image: UIImage?) -> some View {
        Group {
            Button { UIPasteboard.general.string = shareText }  label: { Label("Copy Text", systemImage: "doc.on.doc") }
            Button {
                if let img = image { UIPasteboard.general.image = img }
            } label: { Label("Copy Image", systemImage: "doc.on.doc.fill") }
        }
    }
    
    private func performCopyOrGenerate() {
        switch actionMode {
        case .text:
            UIPasteboard.general.string = shareText
            presentationMode.wrappedValue.dismiss()
        case .image:
            if let img = generatedImage {
                UIPasteboard.general.image = img
                presentationMode.wrappedValue.dismiss()
            } else {
                generatePreviewImage()
            }
        }
    }
    
    private func performShareOrGenerate() {
        switch actionMode {
        case .text:
            activityItems = [shareText]; showingActivityView = true
        case .image:
            if let img = generatedImage {
                activityItems = [img]; showingActivityView = true
            } else {
                generatePreviewImage()
            }
        }
    }
    
    private func generatePreviewImage() {
        imageGenerationIdHolder.value += 1
        let requestId = imageGenerationIdHolder.value
        let idHolder = imageGenerationIdHolder
        Self.shareImageQueue.async { [self] in
            let img: UIImage = autoreleasepool { self.drawImage() }
            DispatchQueue.main.async {
                guard idHolder.value == requestId else { return }
                withAnimation(.easeInOut) {
                    self.generatedImage = img
                    if self.actionMode == .image {
                        self.activityItems = [img]
                    }
                }
            }
        }
    }
    
    private func drawImage() -> UIImage {
        guard let surah = surah, let ayah = ayah else { return UIImage() }

        let bodyFont   = UIFont.preferredFont(forTextStyle: .body)
        let arabicFontName = shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
        let arabicFont = UIFont(name: arabicFontName, size: bodyFont.pointSize * 1.15) ?? bodyFont
        let captionFont = UIFont.preferredFont(forTextStyle: .caption2)
        
        let textColor      = UIColor.white
        let secondaryColor = UIColor.secondaryLabel
        let accent         = settings.accentColor.color.uiColor
        
        // --- Layout constants
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = UIScreen.main.bounds.width - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)
        
        // Paragraph styles
        let right = NSMutableParagraphStyle();  right.alignment = .right
        let left  = NSMutableParagraphStyle();  left.alignment  = .left
        let cent  = NSMutableParagraphStyle();  cent.alignment  = .center
        
        // Attr dictionaries
        let bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor] as [NSAttributedString.Key: Any]
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent,    .paragraphStyle: left]
        let arAccent = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent,    .paragraphStyle: right]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent,    .paragraphStyle: cent]
        let captionAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor,.paragraphStyle: left]
        let captionCentAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        
        // --- Compose full attributed text once
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any]) { text.append(NSAttributedString(string: str, attributes: attrs)) }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr) } }
        
        // Arabic
        if shareSettings.arabic {
            var arabicText = ayah.displayArabicText(surahId: surah.id, clean: shareSettings.cleanArabic)

            if settings.showAyahInformation {
                append("[\(surah.nameArabic) ", arAccent)
                append("\(surah.idArabic):\(ayah.idArabic)]", accentAttr)
                append("\n", bodyAttr)
            } else {
                arabicText += " \(ayah.idArabic)"
            }
            
            append(arabicText, arAttr)
        }
        
        // Transliteration (Hafs only)
        if shareSettings.transliteration, settings.isHafsDisplay {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameTransliteration

            sepIfNeeded()
            
            if settings.showAyahInformation {
                append("[\(trLabelName) \(surah.id):\(ayah.id)]", accentAttr)
                append("\n", bodyAttr)
            }
            
            append(settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))", bodyAttr)
        }

        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish, settings.isHafsDisplay {
            let enHeaderName = (!shareSettings.transliteration)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameEnglish

            sepIfNeeded()

            if settings.showAyahInformation {
                append("[\(enHeaderName) \(surah.id):\(ayah.id)]", accentAttr)
                append("\n", bodyAttr)
            }

            if shareSettings.englishSaheeh {
                if settings.showAyahInformation {
                    append("— Saheeh International", captionAttr)
                    append("\n", bodyAttr)
                }
                append(settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))", bodyAttr)
            }

            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { append("\n\n", bodyAttr) }

                if settings.showAyahInformation {
                    append("— Clear Quran (Mustafa Khattab)", captionAttr)
                    append("\n", bodyAttr)
                }
                append(settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))", bodyAttr)
            }
        }
        
        if includeNote, let note = noteText {
            sepIfNeeded()
            append("— Note", captionAttr)
            append("\n", bodyAttr)
            append(note, bodyAttr)
        }

        if shareSettings.includeQiraah {
            sepIfNeeded()
            let labels = Self.qiraahLabels(displayQiraah: settings.displayQiraah)
            append("Riwayah: \(labels.english) – \(labels.arabic)", captionCentAttr)
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah { append("\n", bodyAttr) } else { sepIfNeeded() }
            append("\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")", captionCentAttr)
        }
        // --- Watermark
        let wmString = "Al-Islam | Islamic Pillars"
        let wmText = NSAttributedString(string: wmString, attributes: centAccent)
        var logo = UIImage(named: "Al-Islam")
        
        var wmTextSize = wmText.size()
        var logoSize = CGSize(width: wmTextSize.height, height: wmTextSize.height)
        let availWidth = maxWidth - 2*padding
        let desiredWmW = logoSize.width + spacing + wmTextSize.width
        
        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width*scale, height: wmTextSize.height*scale)
            logoSize = CGSize(width: logoSize.width*scale, height: logoSize.height*scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }
        
        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width  += 2*padding
        textRect.size.height += logoSize.height + extraSpacing + 25
        
        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))
        
        let r1 = UIGraphicsImageRenderer(size: canvas.size)
        let blackCard = r1.image { ctx in
            UIColor.black.setFill(); ctx.fill(canvas)
            text.draw(in: CGRect(x: padding, y: padding, width: canvas.width - 2*padding, height: canvas.height))
            
            let wmY = canvas.height - logoSize.height - extraSpacing/2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height*0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: 20).addClip()
            blackCard.draw(at: .zero)
        }
    }
}

// MARK: - Copy Ayah (matches Share sheet: image or text per stored preference)
extension ShareAyahSheet {
    private static let copyActionModeKey = "shareAyahLastActionMode"

    private static let shareIncludeRiwayahKey = "shareIncludeRiwayah"

    static func copyAyahToPasteboard(surahNumber: Int, ayahNumber: Int, settings: Settings, quranData: QuranData) {
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }),
              let ayah = surah.ayahs.first(where: { $0.id == ayahNumber }) else { return }
        let includeRiwayah = UserDefaults.standard.bool(forKey: shareIncludeRiwayahKey)
        let shareFont = UserDefaults.standard.string(forKey: "shareArabicFont") ?? ""
        let shareSettings = ShareSettings(
            arabic: settings.showArabicText,
            transliteration: settings.showTransliteration,
            englishSaheeh: settings.showEnglishSaheeh,
            englishMustafa: settings.showEnglishMustafa,
            includeQiraah: includeRiwayah,
            shareArabicFont: shareFont.isEmpty ? settings.fontArabic : shareFont,
            cleanArabic: settings.cleanArabicText
        )
        let noteText: String? = {
            guard let idx = settings.bookmarkedAyahs.firstIndex(where: { $0.surah == surahNumber && $0.ayah == ayahNumber }) else { return nil }
            let trimmed = settings.bookmarkedAyahs[idx].note?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (trimmed?.isEmpty == true) ? nil : trimmed
        }()
        let includeNote = (noteText != nil)
        let actionModeRaw = UserDefaults.standard.string(forKey: copyActionModeKey) ?? ActionMode.image.rawValue
        let actionMode = ActionMode(rawValue: actionModeRaw) ?? .image

        switch actionMode {
        case .text:
            let text = buildShareText(surah: surah, ayah: ayah, shareSettings: shareSettings, settings: settings, includeNote: includeNote, noteText: noteText)
            UIPasteboard.general.string = text
        case .image:
            DispatchQueue.global(qos: .userInitiated).async {
                let img = buildShareImage(surah: surah, ayah: ayah, shareSettings: shareSettings, settings: settings, includeNote: includeNote, noteText: noteText)
                DispatchQueue.main.async {
                    UIPasteboard.general.image = img
                }
            }
        }
    }

    private static func combinedName(translit: String, english: String) -> String {
        if translit.isEmpty { return english }
        if english.isEmpty { return translit }
        return "\(translit) | \(english)"
    }

    private static func buildShareText(surah: Surah, ayah: Ayah, shareSettings: ShareSettings, settings: Settings, includeNote: Bool, noteText: String?) -> String {
        var s = ""
        func sepIfNeeded() { if !s.isEmpty { s += "\n\n" } }
        func appendBlock(label: String?, text: String?) {
            guard let text = text, !text.isEmpty else { return }
            sepIfNeeded()
            if let label = label, !label.isEmpty { s += "\(label)\n" }
            s += text
        }
        if shareSettings.arabic {
            let header: String? = settings.showAyahInformation ? "[\(surah.nameArabic) \(surah.idArabic):\(ayah.idArabic)]" : nil
            let arabicText = ayah.displayArabicText(surahId: surah.id, clean: shareSettings.cleanArabic)
            appendBlock(label: header, text: settings.showAyahInformation ? arabicText : "\(arabicText) \(ayah.idArabic)")
        }
        if shareSettings.transliteration, settings.isHafsDisplay {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameTransliteration
            let header: String? = settings.showAyahInformation ? "[\(trLabelName) \(surah.id):\(ayah.id)]" : nil
            appendBlock(label: header, text: settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))")
        }
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish, settings.isHafsDisplay {
            let headerName = (!shareSettings.transliteration) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameEnglish
            sepIfNeeded()
            if settings.showAyahInformation { s += "[\(headerName) \(surah.id):\(ayah.id)]\n" }
            if shareSettings.englishSaheeh {
                if settings.showAyahInformation { s += "— Saheeh International\n" }
                s += settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))"
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n\n" } else if settings.showAyahInformation { s += "\n" }
                if settings.showAyahInformation { s += "— Mustafa Khattab\n" }
                s += settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))"
            }
        }
        if includeNote, let note = noteText { appendBlock(label: "Note", text: note) }
        if shareSettings.includeQiraah {
            let labels = qiraahLabels(displayQiraah: settings.displayQiraah)
            appendBlock(label: nil, text: "Riwayah: \(labels.english) – \(labels.arabic)")
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")"
        }
        return s
    }

    private static func buildShareImage(surah: Surah, ayah: Ayah, shareSettings: ShareSettings, settings: Settings, includeNote: Bool, noteText: String?) -> UIImage {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let arabicFontName = shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
        let arabicFont = UIFont(name: arabicFontName, size: bodyFont.pointSize * 1.15) ?? bodyFont
        let captionFont = UIFont.preferredFont(forTextStyle: .caption2)
        let textColor = UIColor.white
        let secondaryColor = UIColor.secondaryLabel
        let accent = settings.accentColor.color.uiColor
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = UIScreen.main.bounds.width - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)
        let right = NSMutableParagraphStyle(); right.alignment = .right
        let left = NSMutableParagraphStyle(); left.alignment = .left
        let cent = NSMutableParagraphStyle(); cent.alignment = .center
        let bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor] as [NSAttributedString.Key: Any]
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let arAccent = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let captionAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let captionCentAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any]) { text.append(NSAttributedString(string: str, attributes: attrs)) }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr) } }
        if shareSettings.arabic {
            var arabicText = ayah.displayArabicText(surahId: surah.id, clean: shareSettings.cleanArabic)
            if settings.showAyahInformation {
                append("[\(surah.nameArabic) ", arAccent)
                append("\(surah.idArabic):\(ayah.idArabic)]", accentAttr)
                append("\n", bodyAttr)
            } else { arabicText += " \(ayah.idArabic)" }
            append(arabicText, arAttr)
        }
        if shareSettings.transliteration, settings.isHafsDisplay {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameTransliteration
            sepIfNeeded()
            if settings.showAyahInformation { append("[\(trLabelName) \(surah.id):\(ayah.id)]", accentAttr); append("\n", bodyAttr) }
            append(settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))", bodyAttr)
        }
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish, settings.isHafsDisplay {
            let enHeaderName = (!shareSettings.transliteration) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameEnglish
            sepIfNeeded()
            if settings.showAyahInformation { append("[\(enHeaderName) \(surah.id):\(ayah.id)]", accentAttr); append("\n", bodyAttr) }
            if shareSettings.englishSaheeh {
                if settings.showAyahInformation { append("— Saheeh International", captionAttr); append("\n", bodyAttr) }
                append(settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))", bodyAttr)
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { append("\n\n", bodyAttr) }
                if settings.showAyahInformation { append("— Clear Quran (Mustafa Khattab)", captionAttr); append("\n", bodyAttr) }
                append(settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))", bodyAttr)
            }
        }
        if includeNote, let note = noteText { sepIfNeeded(); append("— Note", captionAttr); append("\n", bodyAttr); append(note, bodyAttr) }
        if shareSettings.includeQiraah {
            sepIfNeeded()
            let labels = qiraahLabels(displayQiraah: settings.displayQiraah)
            append("Riwayah: \(labels.english) – \(labels.arabic)", captionCentAttr)
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah { append("\n", bodyAttr) } else { sepIfNeeded() }
            append("\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")", captionCentAttr)
        }
        let wmString = "Al-Islam | Islamic Pillars"
        let wmText = NSAttributedString(string: wmString, attributes: centAccent)
        var logo = UIImage(named: "Al-Islam")
        var wmTextSize = wmText.size()
        var logoSize = CGSize(width: wmTextSize.height, height: wmTextSize.height)
        let availWidth = maxWidth - 2 * padding
        let desiredWmW = logoSize.width + spacing + wmTextSize.width
        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width * scale, height: wmTextSize.height * scale)
            logoSize = CGSize(width: logoSize.width * scale, height: logoSize.height * scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }
        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width += 2 * padding
        textRect.size.height += logoSize.height + extraSpacing + 25
        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))
        let r1 = UIGraphicsImageRenderer(size: canvas.size)
        let blackCard = r1.image { ctx in
            UIColor.black.setFill(); ctx.fill(canvas)
            text.draw(in: CGRect(x: padding, y: padding, width: canvas.width - 2 * padding, height: canvas.height))
            let wmY = canvas.height - logoSize.height - extraSpacing / 2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height * 0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: 20).addClip()
            blackCard.draw(at: .zero)
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.modalPresentationStyle = .formSheet
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Color { var uiColor: UIColor { UIColor(self) } }

#Preview {
    ShareAyahSheet(surahNumber: 2, ayahNumber: 5)
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
