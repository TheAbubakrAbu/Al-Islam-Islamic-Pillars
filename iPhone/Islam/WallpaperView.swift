import SwiftUI
#if !os(watchOS)
import Photos
#endif

private struct Wallpaper: Identifiable {
    let id = UUID()
    let imageName: String
    let description: String
}

private let wallpapers: [Wallpaper] = [
    Wallpaper(imageName: "Palestine Wallpaper", description: "FREE PALESTINE PHONE WALLPAPER"),
    Wallpaper(imageName: "Phone Wallpaper", description: "AL-ISLAM PHONE WALLPAPER"),
    Wallpaper(imageName: "Laptop Wallpaper", description: "LAPTOP (16:9) WALLPAPER"),
    Wallpaper(imageName: "Desktop Wallpaper", description: "DESKTOP (21:9) WALLPAPER"),
]

struct WallpaperView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        List {
            ForEach(wallpapers) { WallpaperCell(wallpaper: $0) }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .navigationTitle("Wallpapers")
    }
}

private struct WallpaperCell: View {
    let wallpaper: Wallpaper

    var body: some View {
        Section(header: Text(wallpaper.description)) {
            Image(wallpaper.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(24)
                #if !os(watchOS)
                .contextMenu {
                    Button {
                        if let uiImg = UIImage(named: wallpaper.imageName) {
                            UIPasteboard.general.image = uiImg
                        }
                    } label: {
                        Label("Copy Image", systemImage: "doc.on.doc")
                    }

                    Button {
                        guard let uiImg = UIImage(named: wallpaper.imageName) else { return }

                        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                            guard status == .authorized || status == .limited else { return }
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAsset(from: uiImg)
                            })
                        }
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                }
                #endif
        }
    }
}
