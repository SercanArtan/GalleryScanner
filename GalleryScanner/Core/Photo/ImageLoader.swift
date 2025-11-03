import Foundation
import Photos
import UIKit

actor ImageLoader {
    private enum Variant: Hashable {
        case thumbnail(width: Int, height: Int)
        case full(width: Int, height: Int)
        
        var cacheSuffix: String {
            switch self {
            case let .thumbnail(width, height):
                return "thumb_\(width)x\(height)"
            case let .full(width, height):
                return "full_\(width)x\(height)"
            }
        }
    }
    
    private struct QueueItem {
        let asset: PHAsset
        let size: CGSize
        let variant: Variant
        let key: String
        let delayNanoseconds: UInt64
    }
    
    private let manager = PHCachingImageManager()
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 150
        cache.totalCostLimit = 40 * 1024 * 1024
    }
    
    private var active = 0
    private let maxConcurrent = 4
    private var queue: [QueueItem] = []
    private var pendingContinuations: [String: [CheckedContinuation<UIImage?, Never>]] = [:]
    
    func loadThumbnail(for asset: PHAsset, size: CGSize, priority: Bool) async -> UIImage? {
        let variant = Variant.thumbnail(width: Int(size.width.rounded()), height: Int(size.height.rounded()))
        let key = cacheKey(for: asset.localIdentifier, variant: variant)
        
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }
        
        return await enqueue(
            asset: asset,
            size: size,
            variant: variant,
            key: key,
            delayNanoseconds: priority ? 0 : 10_000_000
        )
    }
    
    func loadFullImage(for asset: PHAsset, targetSize: CGSize, priority: Bool) async -> UIImage? {
        let variant = Variant.full(width: Int(targetSize.width.rounded()), height: Int(targetSize.height.rounded()))
        let key = cacheKey(for: asset.localIdentifier, variant: variant)
        
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }
       
        
        return await enqueue(
            asset: asset,
            size: targetSize,
            variant: variant,
            key: key,
            delayNanoseconds: priority ? 0 : 10_000_000
        )
    }
    
    func preloadThumbnails(for assets: [PHAsset], size: CGSize) {
        guard !assets.isEmpty else { return }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        manager.startCachingImages(for: assets, targetSize: size, contentMode: .aspectFill, options: options)
    }
    
    func preloadFullImages(for assets: [PHAsset], targetSize: CGSize) {
        guard !assets.isEmpty else { return }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        manager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFit, options: options)
    }
    
    private func enqueue(
        asset: PHAsset,
        size: CGSize,
        variant: Variant,
        key: String,
        delayNanoseconds: UInt64
    ) async -> UIImage? {
        if pendingContinuations[key] != nil {
            return await withCheckedContinuation { continuation in
                var continuations = pendingContinuations[key] ?? []
                continuations.append(continuation)
                pendingContinuations[key] = continuations
            }
        }
        
        return await withCheckedContinuation { continuation in
            let item = QueueItem(asset: asset, size: size, variant: variant, key: key, delayNanoseconds: delayNanoseconds)
            pendingContinuations[key] = [continuation]
            if delayNanoseconds == 0 {
                queue.insert(item, at: 0)
            } else {
                queue.append(item)
            }
            processQueue()
        }
    }
    
    private func processQueue() {
        guard active < maxConcurrent, !queue.isEmpty else { return }
        
        active += 1
        let item = queue.removeFirst()
        
        let options = imageOptions(for: item.variant)
        let contentMode = preferredContentMode(for: item.variant)
        
        manager.requestImage(for: item.asset, targetSize: item.size, contentMode: contentMode, options: options) { [weak self] image, _ in
            guard let self = self else { return }
            Task {
                if item.delayNanoseconds > 0 {
                    try? await Task.sleep(nanoseconds: item.delayNanoseconds)
                }
                await self.finishRequest(for: item, image: image)
            }
        }
    }
    
    private func finishRequest(for item: QueueItem, image: UIImage?) {
        if let img = image {
            cache.setObject(img, forKey: item.key as NSString, cost: cacheCost(for: item.size))
        }
        
        let continuations = pendingContinuations.removeValue(forKey: item.key) ?? []
        continuations.forEach { $0.resume(returning: image) }
        
        active = max(active - 1, 0)
        processQueue()
    }
    
    private func imageOptions(for variant: Variant) -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        
        switch variant {
        case .full:
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
            options.isNetworkAccessAllowed = true
        case .thumbnail:
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
        }
        return options
    }
    
    private func preferredContentMode(for variant: Variant) -> PHImageContentMode {
        switch variant {
        case .thumbnail:
            return .aspectFill
        case .full:
            return .aspectFit
        }
    }
    
    private func cacheKey(for identifier: String, variant: Variant) -> String {
        "\(identifier)_\(variant.cacheSuffix)"
    }
    
    private func cacheCost(for size: CGSize) -> Int {
        let pixels = max(Int(size.width * size.height), 1)
        return min(pixels * 4, Int(Int32.max))
    }
    
    func clearCaches() {
        cache.removeAllObjects()
        manager.stopCachingImagesForAllAssets()
    }
}
