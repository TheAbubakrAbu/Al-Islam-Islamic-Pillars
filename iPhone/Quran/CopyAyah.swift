import SwiftUI
import Combine

#if !os(watchOS)
struct CopySettings: Equatable {
    var arabic = false
    var transliteration = false
    var translation = false
    var showFooter = false
}

enum ActionMode {
    case text
    case image
}

class Debouncer {
    private var cancellable: AnyCancellable?
    private let interval: TimeInterval

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func callAsFunction(action: @escaping () -> Void) {
        cancellable?.cancel()
        cancellable = Just(())
            .delay(for: .seconds(interval), scheduler: RunLoop.main)
            .sink(receiveValue: action)
    }
}

struct CopyAyahSheet: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @Environment(\.presentationMode) var presentationMode

    @State private var showingActivityView = false
    @State private var activityItems: [Any] = []
    @State private var generatedImage: UIImage?
    @State private var actionMode: ActionMode = .image

    @Binding var copySettings: CopySettings

    var surahNumber: Int
    var ayahNumber: Int

    var surah: Surah {
        quranData.quran.first(where: { $0.id == surahNumber })!
    }

    var ayah: Ayah {
        surah.ayahs.first(where: { $0.id == ayahNumber })!
    }

    private let imageGenerationDebouncer = Debouncer(interval: 0.1)

    var copyText: String {
        var text = ""
        if copySettings.arabic {
            text += "[\(surah.nameArabic) \(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]\n"
            let ar = settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic
            text += ar
        }
        if copySettings.transliteration && copySettings.translation {
            if !text.isEmpty { text += "\n\n" }
            text += "[\(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n"
            text += "\(ayah.textTransliteration ?? "No transliteration")"
            if !text.isEmpty { text += "\n\n" }
            text += "[\(surah.nameEnglish) \(surah.id):\(ayah.id)]\n"
            text += "\(ayah.textEnglish ?? "No translation")"
        } else {
            if copySettings.transliteration {
                if !text.isEmpty { text += "\n\n" }
                text += "[\(surah.nameTransliteration) | \(surah.nameEnglish) \(surah.id):\(ayah.id)]\n"
                text += "\(ayah.textTransliteration ?? "No transliteration")"
            }
            if copySettings.translation {
                if !text.isEmpty { text += "\n\n" }
                text += "[\(surah.nameEnglish) | \(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n"
                text += "\(ayah.textEnglish ?? "No translation")"
            }
        }
        if copySettings.showFooter {
            if !text.isEmpty { text += "\n\n" }
            text += "\(surah.numberOfAyahs) Ayahs - \(surah.type.capitalized) \(surah.type == "meccan" ? "🕋" : "🕌")"
        }
        return text
    }

    func generateImage() -> UIImage {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let arabicFont = UIFont(name: settings.fontArabic, size: bodyFont.pointSize) ?? bodyFont
        let padding: CGFloat = 20
        let textColor = UIColor.white
        let accentColor = settings.accentColor.color.uiColor

        let rightAligned = NSMutableParagraphStyle()
        rightAligned.alignment = .right
        let leftAligned = NSMutableParagraphStyle()
        leftAligned.alignment = .left
        let centerAligned = NSMutableParagraphStyle()
        centerAligned.alignment = .center

        let bodyAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: textColor]
        let arabicAttrs: [NSAttributedString.Key: Any] = [.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: rightAligned]
        let accentAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: accentColor, .paragraphStyle: leftAligned]
        let arabicAccent: [NSAttributedString.Key: Any] = [.font: arabicFont, .foregroundColor: accentColor, .paragraphStyle: rightAligned]

        let combined = NSMutableAttributedString()

        if copySettings.arabic {
            combined.append(NSAttributedString(string: "[\(surah.nameArabic) ", attributes: arabicAccent))
            combined.append(NSAttributedString(string: "\(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]\n", attributes: accentAttrs))
            let ar = settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic
            combined.append(NSAttributedString(string: ar, attributes: arabicAttrs))
        }
        if copySettings.transliteration && copySettings.translation {
            if combined.length > 0 { combined.append(NSAttributedString(string: "\n\n", attributes: bodyAttrs)) }
            combined.append(NSAttributedString(string: "[\(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n", attributes: accentAttrs))
            combined.append(NSAttributedString(string: "\(ayah.textTransliteration ?? "No transliteration")", attributes: bodyAttrs))
            if combined.length > 0 { combined.append(NSAttributedString(string: "\n\n", attributes: bodyAttrs)) }
            combined.append(NSAttributedString(string: "[\(surah.nameEnglish) \(surah.id):\(ayah.id)]\n", attributes: accentAttrs))
            combined.append(NSAttributedString(string: "\(ayah.textEnglish ?? "No translation")", attributes: bodyAttrs))
        } else {
            if copySettings.transliteration {
                if combined.length > 0 { combined.append(NSAttributedString(string: "\n\n", attributes: bodyAttrs)) }
                combined.append(NSAttributedString(string: "[\(surah.nameTransliteration) | \(surah.nameEnglish) \(surah.id):\(ayah.id)]\n", attributes: accentAttrs))
                combined.append(NSAttributedString(string: "\(ayah.textTransliteration ?? "No transliteration")", attributes: bodyAttrs))
            }
            if copySettings.translation {
                if combined.length > 0 { combined.append(NSAttributedString(string: "\n\n", attributes: bodyAttrs)) }
                combined.append(NSAttributedString(string: "[\(surah.nameEnglish) | \(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n", attributes: accentAttrs))
                combined.append(NSAttributedString(string: "\(ayah.textEnglish ?? "No translation")", attributes: bodyAttrs))
            }
        }
        if copySettings.showFooter {
            if combined.length > 0 { combined.append(NSAttributedString(string: "\n\n", attributes: bodyAttrs)) }
            let centerAccent: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: accentColor, .paragraphStyle: centerAligned]
            let centerBody: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: textColor, .paragraphStyle: centerAligned]
            combined.append(NSAttributedString(string: "\(surah.numberOfAyahs) Ayahs - \(surah.type.capitalized) ", attributes: centerAccent))
            combined.append(NSAttributedString(string: surah.type == "meccan" ? "🕋" : "🕌", attributes: centerBody))
        }

        let box = CGSize(width: UIScreen.main.bounds.width - 50 - 2 * padding, height: .greatestFiniteMagnitude)
        var rect = combined.boundingRect(with: box, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        rect.size.width += 2 * padding
        rect.size.height += 2 * padding
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { ctx in
            UIColor.black.set()
            ctx.fill(rect)
            combined.draw(in: CGRect(x: padding, y: padding, width: rect.width - 2 * padding, height: rect.height - 2 * padding))
        }
        return image
    }

    func generateImageAsync() {
        imageGenerationDebouncer {
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.generateImage()
                DispatchQueue.main.async {
                    self.generatedImage = result
                    self.activityItems = [result]
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                if actionMode == .image {
                    if let img = generatedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = copyText
                                } label: {
                                    Label("Copy Text", systemImage: "doc.on.doc")
                                }
                                Button {
                                    UIPasteboard.general.image = img
                                } label: {
                                    Label("Copy Image", systemImage: "doc.on.doc.fill")
                                }
                            }
                    }
                } else {
                    Text(copyText)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .padding()
                        .background(Color.black)
                        .cornerRadius(15)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = copyText
                            } label: {
                                Label("Copy Text", systemImage: "doc.on.doc")
                            }
                            Button {
                                UIPasteboard.general.image = generatedImage
                            } label: {
                                Label("Copy Image", systemImage: "doc.on.doc.fill")
                            }
                        }
                }
                Spacer()
                Toggle(isOn: $copySettings.arabic.animation(.easeInOut)) {
                    Text("Arabic").foregroundColor(.primary)
                }
                .tint(settings.accentColor.color)
                .disabled(!copySettings.transliteration && !copySettings.translation)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                Toggle(isOn: $copySettings.transliteration.animation(.easeInOut)) {
                    Text("Transliteration").foregroundColor(.primary)
                }
                .tint(settings.accentColor.color)
                .disabled(!copySettings.arabic && !copySettings.translation)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                Toggle(isOn: $copySettings.translation.animation(.easeInOut)) {
                    Text("Translation").foregroundColor(.primary)
                }
                .tint(settings.accentColor.color)
                .disabled(!copySettings.arabic && !copySettings.transliteration)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                Toggle(isOn: $copySettings.showFooter.animation(.easeInOut)) {
                    Text("Show Footer").foregroundColor(.primary)
                }
                .scaleEffect(0.8)
                .tint(settings.accentColor.color)
                .padding(.horizontal, -24)
                .padding(.vertical, 2)

                Picker("Action Mode", selection: $actionMode.animation(.easeInOut)) {
                    Text("Image").tag(ActionMode.image)
                    Text("Text").tag(ActionMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom)

                HStack {
                    Spacer()
                    Button {
                        settings.hapticFeedback()
                        switch actionMode {
                        case .text:
                            UIPasteboard.general.string = copyText
                            presentationMode.wrappedValue.dismiss()
                        case .image:
                            if generatedImage == nil {
                                generateImageAsync()
                            } else {
                                UIPasteboard.general.image = generatedImage
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    } label: {
                        Text("Copy")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .background(settings.accentColor.color)
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .padding(.bottom)
                    }
                    Spacer()
                    Button {
                        settings.hapticFeedback()
                        switch actionMode {
                        case .text:
                            activityItems = [copyText]
                            showingActivityView = true
                        case .image:
                            if generatedImage == nil {
                                generateImageAsync()
                            } else {
                                activityItems = [generatedImage!]
                                showingActivityView = true
                            }
                        }
                    } label: {
                        Text("Share")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .background(settings.accentColor.color)
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .padding(.bottom)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .sheet(isPresented: $showingActivityView) {
                    ActivityView(activityItems: activityItems, applicationActivities: nil)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accentColor(settings.accentColor.color)
        .onAppear {
            generateImageAsync()
        }
        .onChange(of: copySettings) { _ in
            generateImageAsync()
        }
        .onChange(of: showingActivityView) { newValue in
            if !newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.modalPresentationStyle = .formSheet
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}
#endif
