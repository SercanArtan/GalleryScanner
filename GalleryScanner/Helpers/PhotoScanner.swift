import Foundation
import Combine
import Photos

final class PhotoScanner: NSObject, PHPhotoLibraryChangeObserver {
    static let shared = PhotoScanner()
    
    let progressPublisher = PassthroughSubject<(processed: Int, total: Int), Never>()
    let scannedBatchesPublisher = PassthroughSubject<[ScannedPhoto], Never>()
    let finishedPublisher = PassthroughSubject<Void, Never>()
    
    private var isScanning = false
    private(set) var scannedPhotos: [ScannedPhoto] = []
    private var totalAssets = 0
    private var processedAssets = 0
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            await startScreen()
        }
    }
    
    func resumeOrStartScan() {
        if let persisted = PersistenceManager.shared.loadScanState() {
            self.scannedPhotos = persisted.photos
        }
        Task { @MainActor in
            await startScreen()
        }
    }
    
    func startScreen() async {
        guard !isScanning else { return }
        isScanning = true
        
        Task(priority: .userInitiated) {
            
            let currentAssets = fetchingAllAssets()
            self.totalAssets = currentAssets.count
            
            self.scannedPhotos.removeAll { scanned in
                !currentAssets.contains(where: { $0.localIdentifier == scanned.id })
            }
            
            self.processedAssets = self.scannedPhotos.count
            
                await MainActor.run {
                    self.progressPublisher.send((self.processedAssets, self.totalAssets))
                }
                
                for asset in currentAssets {
                    guard !self.scannedPhotos.contains(where: { $0.id == asset.localIdentifier }) else { continue }
                    
                    // for test case to visiualize progress bar
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    let value = asset.reliableHash()
                    let groupRaw = PhotoGroup.group(for: value)?.rawValue ?? "other"
                    
                    let newScannedPhoto = ScannedPhoto(id:asset.localIdentifier, group: groupRaw, cretaedAt: asset.creationDate ?? Date())
                    self.scannedPhotos.append(newScannedPhoto)
                    self.processedAssets += 1
                    
                    try PersistenceManager.shared.saveScanState(scannedPhotos, progressIndex: processedAssets)
                    
                    await MainActor.run {
                        self.scannedBatchesPublisher.send([newScannedPhoto])
                        self.progressPublisher.send((self.processedAssets, self.totalAssets))
                    }
                    
                    
                }
                // Clean all data
                try? PersistenceManager.shared.clearScanState()
                await MainActor.run {
                    self.isScanning = false
                    self.finishedPublisher.send()
                }
                
                
                
            
        }
    }
    
    private func fetchingAllAssets() -> [PHAsset] {
        var currentAssets: [PHAsset] = []
        let assets = PHAsset.fetchAssets(with: .image, options: nil)
        assets.enumerateObjects { (asset, _, _) in
            currentAssets.append(asset)
        }
        
        return currentAssets
    }
    
    func groupedScanned() -> [String: Int] {
        var groupCounts: [String : Int] = [:]
        for photo in self.scannedPhotos {
            groupCounts[photo.group, default: 0] += 1
        }
        return groupCounts
    }
    
    func assets(for groupRaw: String) -> [String] {
        self.scannedPhotos.filter { $0.group == groupRaw }.map { $0.id}
    }
    
    // for testing
    func reset() throws {
        scannedPhotos.removeAll()
        self.processedAssets = 0
        try? PersistenceManager.shared.clearScanState()
    }
}
