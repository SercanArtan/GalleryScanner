import Foundation
import Photos
import UIKit

actor ImageDetailDataManager {
    private let loader = ImageLoader()

    func fetchThumbnailImage(for assetID: String, size: CGSize) async -> UIImage? {
        guard let asset = resolveAsset(with: assetID) else { return nil }
        return await loader.loadThumbnail(for: asset, size: size, priority: true)
    }

    func fetchFullImage(for assetID: String) async -> UIImage? {
        guard let asset = resolveAsset(with: assetID) else { return nil }
        return await loader.loadFullImage(for: asset, targetSize: fullImageTargetSize(), priority: true)
    }

    func prefetchFullImages(for assetIDs: [String]) async {
        let assets = resolveAssets(with: assetIDs)
        guard !assets.isEmpty else { return }
        await loader.preloadFullImages(for: assets, targetSize: fullImageTargetSize())
    }

    func clearCaches() async {
        await loader.clearCaches()
    }

    private func resolveAsset(with identifier: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }

    private func resolveAssets(with identifiers: [String]) -> [PHAsset] {
        guard !identifiers.isEmpty else { return [] }
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        assets.reserveCapacity(fetched.count)
        fetched.enumerateObjects { asset, _, stop in
            assets.append(asset)
            if assets.count == identifiers.count {
                stop.pointee = true
            }
        }
        return assets
    }

    @MainActor
    private func fullImageTargetSize() -> CGSize {
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        return CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }
}
