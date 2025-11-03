import Photos
import UIKit

actor GroupDataManager {
    private let loader = ImageLoader()

    func fetchAssets(for groupRaw: String) -> [String] {
        return PhotoScanner.shared.assets(for: groupRaw)
    }

    func fetchThumbnailImage(for assetID: String, size: CGSize) async -> UIImage? {
        guard let asset = resolveAsset(with: assetID) else { return nil }
        return await loader.loadThumbnail(for: asset, size: size, priority: true)
    }

    func prefetchThumbnails(for assetIDs: [String], size: CGSize) async {
        let assets = resolveAssets(with: assetIDs)
        guard !assets.isEmpty else { return }
        await loader.preloadThumbnails(for: assets, size: size)
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
}
