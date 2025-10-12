import Foundation
import Combine
import Photos
import UIKit

class GroupDetailViewModel: ObservableObject {

    @Published var images: [UIImage] = []
    
    let groupRaw: String
    private var assetsIDs: [String] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(groupRaw: String) {
        self.groupRaw = groupRaw
        loadAssets()
        newAssetLoaded()
    }
    
    func loadAssets() {
        let ids = PhotoScanner.shared.assets(for: groupRaw)

        let newAssetIDs = ids.filter { !self.assetsIDs.contains($0) }
        
        guard !newAssetIDs.isEmpty else { return }
        fetchImage(newAssetIDs)
    }
    
    private func newAssetLoaded() {
         PhotoScanner.shared.scannedBatchesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.loadAssets()
            }.store(in: &cancellables)
    }
    
    func fetchImage(_ newAssetIDs: [String] = []) {
        Task(priority: .userInitiated) {
            let fetched = PHAsset.fetchAssets(withLocalIdentifiers: newAssetIDs, options: nil)
            var phAssets: [PHAsset] = []
            fetched.enumerateObjects { (asset, _, _) in
                phAssets.append(asset)
            }
            
            let manager = PHImageManager.default()
            let opts = PHImageRequestOptions()
            opts.isSynchronous = true
            opts.deliveryMode = .opportunistic
            opts.resizeMode = .fast
            
            var newImages: [UIImage] = []
            for asset in phAssets {
                manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: opts) { (image, _) in
                    if let img = image {
                        newImages.append(img)
                    }
                }
            }

            await MainActor.run {
                self.images.append(contentsOf: newImages)
                self.assetsIDs.append(contentsOf: newAssetIDs)
            }
        }
    }
}
