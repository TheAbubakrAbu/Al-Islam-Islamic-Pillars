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
        guard let foundSurah = quranData.quran.first(where: { $0.id == surahNumber }) else {
            fatalError("Surah with ID \(surahNumber) not found")
        }
        return foundSurah
    }

    var ayah: Ayah {
        guard let foundAyah = surah.ayahs.first(where: { $0.id == ayahNumber }) else {
            fatalError("Ayah with ID \(ayahNumber) not found in Surah \(surahNumber)")
        }
        return foundAyah
    }
    
    private let imageGenerationDebouncer = Debouncer(interval: 0.1)

    var copyText: String {
        var text = ""

        if copySettings.arabic {
            text += "[\(surah.nameArabic) \(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]\n"
            let arabicText = settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic
            text += "\(arabicText)"
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
        let arabicFont: UIFont
        if let namedFont = UIFont(name: settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize) {
            arabicFont = namedFont
        } else {
            arabicFont = UIFont.preferredFont(forTextStyle: .body)
        }
        let padding: CGFloat = 20

        let textColor: UIColor = .white
        let accentColor: UIColor = settings.accentColor.color.uiColor

        let rightAlignedParagraphStyle = NSMutableParagraphStyle()
        rightAlignedParagraphStyle.alignment = .right

        let leftAlignedParagraphStyle = NSMutableParagraphStyle()
        leftAlignedParagraphStyle.alignment = .left

        let bodyTextAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: textColor]
        let arabicTextAttributes: [NSAttributedString.Key: Any] = [
            .font: arabicFont,
            .foregroundColor: textColor,
            .paragraphStyle: rightAlignedParagraphStyle
        ]
        let accentTextAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: accentColor,
            .paragraphStyle: leftAlignedParagraphStyle
        ]
        let arabicAccentTextAttributes: [NSAttributedString.Key: Any] = [
            .font: arabicFont,
            .foregroundColor: accentColor,
            .paragraphStyle: rightAlignedParagraphStyle
        ]

        let combinedText = NSMutableAttributedString()

        if copySettings.arabic {
            let arabicSurahName = NSAttributedString(string: "[\(surah.nameArabic) ", attributes: arabicAccentTextAttributes)
            let surahNumber = NSAttributedString(string: "\(arabicNumberString(from: surah.id)):\(arabicNumberString(from: ayah.id))]\n", attributes: accentTextAttributes)
            combinedText.append(arabicSurahName)
            combinedText.append(surahNumber)

            let arabicText = settings.cleanArabicText ? ayah.textClearArabic : ayah.textArabic
            combinedText.append(NSAttributedString(string: "\(arabicText)", attributes: arabicTextAttributes))
        }

        if copySettings.transliteration && copySettings.translation {
            if combinedText.length > 0 { combinedText.append(NSAttributedString(string: "\n\n", attributes: bodyTextAttributes)) }
            
            let reference = NSAttributedString(string: "[\(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n", attributes: accentTextAttributes)
            combinedText.append(reference)
            
            combinedText.append(NSAttributedString(string: "\(ayah.textTransliteration ?? "No transliteration")", attributes: bodyTextAttributes))

            if combinedText.length > 0 { combinedText.append(NSAttributedString(string: "\n\n", attributes: bodyTextAttributes)) }

            let referenceTranslation = NSAttributedString(string: "[\(surah.nameEnglish) \(surah.id):\(ayah.id)]\n", attributes: accentTextAttributes)
            combinedText.append(referenceTranslation)

            combinedText.append(NSAttributedString(string: "\(ayah.textEnglish ?? "No translation")", attributes: bodyTextAttributes))
        } else {
            if copySettings.transliteration {
                if combinedText.length > 0 { combinedText.append(NSAttributedString(string: "\n\n", attributes: bodyTextAttributes)) }
                
                let reference = NSAttributedString(string: "[\(surah.nameTransliteration) | \(surah.nameEnglish) \(surah.id):\(ayah.id)]\n", attributes: accentTextAttributes)
                combinedText.append(reference)
                
                combinedText.append(NSAttributedString(string: "\(ayah.textTransliteration ?? "No transliteration")", attributes: bodyTextAttributes))
            }

            if copySettings.translation {
                if combinedText.length > 0 { combinedText.append(NSAttributedString(string: "\n\n", attributes: bodyTextAttributes)) }
                
                let reference = NSAttributedString(string: "[\(surah.nameEnglish) | \(surah.nameTransliteration) \(surah.id):\(ayah.id)]\n", attributes: accentTextAttributes)
                combinedText.append(reference)
                
                combinedText.append(NSAttributedString(string: "\(ayah.textEnglish ?? "No translation")", attributes: bodyTextAttributes))
            }
        }

        if copySettings.showFooter {
            if combinedText.length > 0 { combinedText.append(NSAttributedString(string: "\n\n", attributes: bodyTextAttributes)) }
            
            let centerAlignedParagraphStyle = NSMutableParagraphStyle()
            centerAlignedParagraphStyle.alignment = .center
            
            let centeredAccentTextAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: accentColor,
                .paragraphStyle: centerAlignedParagraphStyle
            ]
            let centeredBodyTextAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: centerAlignedParagraphStyle
            ]

            let footer = "\(surah.numberOfAyahs) Ayahs - \(surah.type.capitalized) "
            combinedText.append(NSAttributedString(string: footer, attributes: centeredAccentTextAttributes))
            combinedText.append(NSAttributedString(string: surah.type == "meccan" ? "🕋" : "🕌", attributes: centeredBodyTextAttributes))
        }

        let constraintBox = CGSize(width: UIScreen.main.bounds.width - 50 - 2 * padding, height: .greatestFiniteMagnitude)
        var rect = combinedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral

        rect.size.width += 2 * padding
        rect.size.height += 2 * padding

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { context in
            UIColor.black.set()
            context.fill(rect)
            combinedText.draw(in: CGRect(x: padding, y: padding, width: rect.width - 2 * padding, height: rect.height - 2 * padding))
        }

        return image
    }

    func generateImageAsync() {
        imageGenerationDebouncer {
            DispatchQueue.global(qos: .userInitiated).async {
                let image = self.generateImage()
                DispatchQueue.main.async {
                    self.generatedImage = image
                    self.activityItems = [image]
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                if actionMode == .image {
                    if let generatedImage = generatedImage {
                        Image(uiImage: generatedImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .contextMenu {
                                Button(action: {
                                    UIPasteboard.general.string = copyText
                                }) {
                                    Label("Copy Text", systemImage: "doc.on.doc")
                                }
                                
                                Button(action: {
                                    UIPasteboard.general.image = generatedImage
                                }) {
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
                            Button(action: {
                                UIPasteboard.general.string = copyText
                            }) {
                                Label("Copy Text", systemImage: "doc.on.doc")
                            }
                            
                            Button(action: {
                                UIPasteboard.general.image = generatedImage
                            }) {
                                Label("Copy Image", systemImage: "doc.on.doc.fill")
                            }
                        }
                }
                
                Spacer()
                
                Toggle(isOn: $copySettings.arabic.animation(.easeInOut)) {
                    Text("Arabic")
                        .foregroundColor(.primary)
                }
                .tint(settings.accentColor.color)
                .disabled(!copySettings.transliteration && !copySettings.translation)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                Toggle(isOn: $copySettings.transliteration.animation(.easeInOut)) {
                    Text("Transliteration")
                        .foregroundColor(.primary)
                }
                .tint(settings.accentColor.color)
                .disabled(!copySettings.arabic && !copySettings.translation)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                Toggle(isOn: $copySettings.translation.animation(.easeInOut)) {
                    Text("Translation")
                        .foregroundColor(.primary)
                }
                .tint(settings.accentColor.color)
                .disabled(!copySettings.arabic && !copySettings.transliteration)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                Toggle(isOn: $copySettings.showFooter.animation(.easeInOut)) {
                    Text("Show Footer")
                        .foregroundColor(.primary)
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
                    
                    Button(action: {
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
                    }) {
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
                    
                    Button(action: {
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
                    }) {
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
        .onChange(of: copySettings) { newValue in
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

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.modalPresentationStyle = .formSheet
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}

extension Color {
    var uiColor: UIColor {
        return UIColor(self)
    }
}
#endif
