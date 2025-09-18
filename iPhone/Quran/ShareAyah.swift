import SwiftUI
import Combine

enum ActionMode { case text, image }

struct ShareAyahSheet: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var shareSettings: ShareSettings
    let surahNumber: Int
    let ayahNumber: Int
    
    @State private var actionMode: ActionMode = .image
    @State private var generatedImage: UIImage?
    @State private var activityItems: [Any] = []
    @State private var showingActivityView = false
    @State private var includeNote: Bool = false
    
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
        
    private var surah: Surah { quranData.quran.first(where: { $0.id == surahNumber })! }
    private var ayah: Ayah  { surah.ayahs.first(where: { $0.id == ayahNumber })! }
    
    private var shareText: String {
        var s = ""

        @inline(__always) func sepIfNeeded() {
            if !s.isEmpty { s += "\n\n" }
        }
        
        @inline(__always) func appendBlock(label: String, text: String?) {
            guard let text = text, !text.isEmpty else { return }
            sepIfNeeded()
            s += "\(label)\n\(text)"
        }

        if shareSettings.arabic {
            let header = "[\(surah.nameArabic) \(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]"
            appendBlock(label: header, text: (settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic))
        }

        if shareSettings.transliteration {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameTransliteration

            appendBlock(label: "[\(trLabelName) \(surah.id):\(ayah.id)]",
                        text: ayah.textTransliteration)
        }

        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let headerName = (!shareSettings.transliteration)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameEnglish

            sepIfNeeded()
            s += "[\(headerName) \(surah.id):\(ayah.id)]"

            if shareSettings.englishSaheeh {
                s += "\n— Saheeh International"
                s += "\n\(ayah.textEnglishSaheeh)"
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n" }
                s += "\n— Mustafa Khattab"
                s += "\n\(ayah.textEnglishMustafa)"
            }
        }
        
        if includeNote, let note = noteText {
            appendBlock(label: "Note", text: note)
        }

        if shareSettings.showFooter {
            sepIfNeeded()
            s += "\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")"
        }
        
        return s
    }
    
    private func combinedName(translit: String, english: String) -> String {
        if translit.isEmpty { return english }
        if english.isEmpty { return translit }
        return "\(translit) | \(english)"
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
                                .cornerRadius(15)
                                .padding(.horizontal, 16)
                                .contextMenu { copyMenu(image: img) }
                        }
                    } else {
                        Text(shareText)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(15)
                            .padding(.horizontal, 16)
                            .contextMenu { copyMenu(image: generatedImage) }
                            .lineLimit(nil)
                            .minimumScaleFactor(0.1)
                    }
                }
                
                Spacer()
                
                toggle("Arabic", $shareSettings.arabic,
                       disabled: !shareSettings.transliteration && !shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                
                toggle("Transliteration", $shareSettings.transliteration,
                       disabled: !shareSettings.arabic && !shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                
                toggle("Translation — Saheeh International", $shareSettings.englishSaheeh,
                       disabled: !shareSettings.arabic && !shareSettings.transliteration && !shareSettings.englishMustafa)
                
                toggle("Translation — Mustafa Khattab", $shareSettings.englishMustafa,
                       disabled: !shareSettings.arabic && !shareSettings.transliteration && !shareSettings.englishSaheeh)
                
                if noteText != nil {
                    Toggle("Include Note", isOn: $includeNote.animation(.easeInOut))
                        .tint(settings.accentColor.color)
                        .scaleEffect(0.8)
                        .padding(.horizontal, -24)
                        .padding(.vertical, 2)
                }
                
                Toggle("Show Surah Information", isOn: $shareSettings.showFooter.animation(.easeInOut))
                    .tint(settings.accentColor.color)
                    .scaleEffect(0.8)
                    .padding(.horizontal, -24)
                    .padding(.vertical, 2)
                
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
        .onAppear(perform: generatePreviewImage)
        .onChange(of: shareSettings) { _ in generatePreviewImage() }
        .onChange(of: includeNote) { _ in generatePreviewImage() }
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
        .padding(.vertical, 8)
    }
    
    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            settings.hapticFeedback(); action()
        }) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(settings.accentColor.color)
                .cornerRadius(10)
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
        DispatchQueue.global(qos: .userInitiated).async {
            let img = self.drawImage()
            DispatchQueue.main.async {
                self.generatedImage = img
                if self.actionMode == .image {
                    self.activityItems = [img]
                }
            }
        }
    }
    
    private func drawImage() -> UIImage {
        let bodyFont   = UIFont.preferredFont(forTextStyle: .body)
        let arabicFont = UIFont(name: settings.fontArabic, size: bodyFont.pointSize) ?? bodyFont
        let captionFont = UIFont.preferredFont(forTextStyle: .caption2)
        
        let textColor      = UIColor.white
        let secondaryColor = UIColor.secondaryLabel
        let accent         = settings.accentColor.color.uiColor
        
        // --- Layout constants
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let maxWidth = UIScreen.main.bounds.width - 50
        
        // Paragraph styles
        let right = NSMutableParagraphStyle();  right.alignment = .right
        let left  = NSMutableParagraphStyle();  left.alignment  = .left
        let cent  = NSMutableParagraphStyle();  cent.alignment  = .center
        
        // Attr dictionaries
        let bodyAttr     = [NSAttributedString.Key.font: bodyFont,   .foregroundColor: textColor]      as [NSAttributedString.Key: Any]
        let arAttr       = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right]
        let accentAttr   = [NSAttributedString.Key.font: bodyFont,   .foregroundColor: accent,    .paragraphStyle: left]
        let arAccent     = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent,    .paragraphStyle: right]
        let centAccent   = [NSAttributedString.Key.font: bodyFont,   .foregroundColor: accent,    .paragraphStyle: cent]
        let captionAttr  = [NSAttributedString.Key.font: captionFont,.foregroundColor: secondaryColor,.paragraphStyle: left]
        
        // --- Compose full attributed text once
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any]) { text.append(NSAttributedString(string: str, attributes: attrs)) }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr) } }
        
        // Arabic
        if shareSettings.arabic {
            append("[\(surah.nameArabic) ", arAccent)
            append("\(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]", accentAttr)
            append("\n", bodyAttr)
            append(settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic, arAttr)
        }
        
        // Transliteration
        if shareSettings.transliteration {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameTransliteration

            sepIfNeeded()
            append("[\(trLabelName) \(surah.id):\(ayah.id)]", accentAttr)
            append("\n", bodyAttr)
            append(ayah.textTransliteration, bodyAttr)
        }

        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let enHeaderName = (!shareSettings.transliteration)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameEnglish

            sepIfNeeded()
            append("[\(enHeaderName) \(surah.id):\(ayah.id)]", accentAttr)

            if shareSettings.englishSaheeh {
                append("\n", bodyAttr)
                append("— Saheeh International", captionAttr)
                append("\n", bodyAttr)
                append(ayah.textEnglishSaheeh, bodyAttr)
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { append("\n\n", bodyAttr) } // spacer between translations
                append("— Mustafa Khattab", captionAttr)
                append("\n", bodyAttr)
                append(ayah.textEnglishMustafa, bodyAttr)
            }
        }
        
        if includeNote, let note = noteText {
            sepIfNeeded()
            append("— Note", captionAttr)
            append("\n", bodyAttr)
            append(note, bodyAttr)
        }
        
        // Footer
        if shareSettings.showFooter {
            sepIfNeeded()
            append("\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) ", centAccent)
            append(surah.type == "meccan" ? "🕋" : "🕌", bodyAttr)
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
