import SwiftUI
import Combine

enum ActionMode { case text, image }

final class Debouncer {
    private var cancellable: AnyCancellable?
    private let interval: TimeInterval
    init(interval: TimeInterval) { self.interval = interval }
    func callAsFunction(_ block: @escaping () -> Void) {
        cancellable?.cancel()
        cancellable = Just(())
            .delay(for: .seconds(interval), scheduler: RunLoop.main)
            .sink(receiveValue: block)
    }
}

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
    
    private let debouncer = Debouncer(interval: 0.15)
    
    private var surah: Surah { quranData.quran.first(where: { $0.id == surahNumber })! }
    private var ayah: Ayah  { surah.ayahs.first(where: { $0.id == ayahNumber })! }
    
    private var shareText: String {
        var s = ""
        if shareSettings.arabic {
            s += "[\(surah.nameArabic) \(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]\n"
            s += settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic
        }
        
        func appendBlock(label: String, text: String?) {
            guard let text = text else { return }
            if !s.isEmpty { s += "\n\n" }
            s += "\(label)\n\(text)"
        }
        
        if shareSettings.transliteration && shareSettings.translation {
            appendBlock(label: "[\(surah.nameTransliteration) \(surah.id):\(ayah.id)]", text: ayah.textTransliteration)
            appendBlock(label: "[\(surah.nameEnglish) \(surah.id):\(ayah.id)]", text: ayah.textEnglish)
        } else {
            if shareSettings.transliteration {
                appendBlock(
                    label: "[\(surah.nameTransliteration) | \(surah.nameEnglish) \(surah.id):\(ayah.id)]",
                    text: ayah.textTransliteration
                )
            }
            if shareSettings.translation {
                appendBlock(
                    label: "[\(surah.nameEnglish) | \(surah.nameTransliteration) \(surah.id):\(ayah.id)]",
                    text: ayah.textEnglish
                )
            }
        }
        if shareSettings.showFooter {
            if !s.isEmpty { s += "\n\n" }
            s += "\(surah.numberOfAyahs) Ayahs – \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")"
        }
        return s
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
                    }
                }
                
                Spacer()
                
                toggle("Arabic", $shareSettings.arabic, disabled: !shareSettings.transliteration && !shareSettings.translation)
                toggle("Transliteration", $shareSettings.transliteration, disabled: !shareSettings.arabic && !shareSettings.translation)
                toggle("Translation", $shareSettings.translation, disabled: !shareSettings.arabic && !shareSettings.transliteration)
                Toggle("Show Footer", isOn: $shareSettings.showFooter.animation(.easeInOut))
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
        debouncer {
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
    }
    
    private func drawImage() -> UIImage {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let arabicFont = UIFont(name: settings.fontArabic, size: bodyFont.pointSize) ?? bodyFont
        let textColor = UIColor.white
        let accent = settings.accentColor.color.uiColor
        
        // --- Layout constants
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let maxWidth = UIScreen.main.bounds.width - 50
        
        // Paragraph styles
        let right = NSMutableParagraphStyle();  right.alignment = .right
        let left = NSMutableParagraphStyle();  left.alignment = .left
        let cent = NSMutableParagraphStyle();  cent.alignment = .center
        
        // Attr dictionaries
        let bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor] as [NSAttributedString.Key: Any]
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: left]
        let arAccent = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent, .paragraphStyle: right]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: cent]
        
        // --- Compose full attributed text once
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any]) { text.append(NSAttributedString(string: str, attributes: attrs)) }
        
        if shareSettings.arabic {
            append("[\(surah.nameArabic) ", arAccent)
            append("\(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]\n", accentAttr)
            append(settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic, arAttr)
        }
        if shareSettings.transliteration && shareSettings.translation {
            if text.length > 0 { append("\n\n", bodyAttr) }
            append("[\(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n", accentAttr)
            append(ayah.textTransliteration, bodyAttr)
            append("\n\n[\(surah.nameEnglish) \(surah.id):\(ayah.id)]\n", accentAttr)
            append(ayah.textEnglish, bodyAttr)
        } else {
            if shareSettings.transliteration {
                if text.length > 0 { append("\n\n", bodyAttr) }
                append("[\(surah.nameTransliteration) | \(surah.nameEnglish) \(surah.id):\(ayah.id)]\n", accentAttr)
                append(ayah.textTransliteration, bodyAttr)
            }
            if shareSettings.translation {
                if text.length > 0 { append("\n\n", bodyAttr) }
                append("[\(surah.nameEnglish) | \(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n", accentAttr)
                append(ayah.textEnglish, bodyAttr)
            }
        }
        if shareSettings.showFooter {
            if text.length > 0 { append("\n\n", bodyAttr) }
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
        
        // Down‑scale watermark if needed
        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width*scale, height: wmTextSize.height*scale)
            logoSize = CGSize(width: logoSize.width*scale, height: logoSize.height*scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }
        
        // Bounding sizes
        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width  += 2*padding
        textRect.size.height += logoSize.height + extraSpacing + 25
        
        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))
        
        // Render
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
    let activityItems: [Any]; var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.modalPresentationStyle = .formSheet; return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Color { var uiColor: UIColor { UIColor(self) } }
