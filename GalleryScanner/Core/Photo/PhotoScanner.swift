import Photos
import Combine
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
        Task {
            await self.startScreen()
        }
    }
    
    func resumeOrStartScan() async {
        if let persisted = await PersistenceManager.shared.loadScanState() {
            self.scannedPhotos = persisted.photos
        }
        Task {
            await self.startScreen()
        }
    }
    
    @MainActor
    func startScreen() async {
        guard !isScanning else { return }
        isScanning = true

        var currentAssets = fetchingAllAssets()
        self.totalAssets = currentAssets.count

        self.scannedPhotos.removeAll { scanned in
            !currentAssets.contains(where: { $0.localIdentifier == scanned.id })
        }
        let scannedIDs = Set(self.scannedPhotos.map(\.id))
        currentAssets.removeAll { scannedIDs.contains($0.localIdentifier) }
        self.processedAssets = self.scannedPhotos.count
        self.progressPublisher.send((self.processedAssets, self.totalAssets))

        do {
            _ = try await concurrentTaskGroup(currentAssets)
        } catch {
            print("Scan failed \(error)")
        }
        
        // for test case
         try? await PersistenceManager.shared.clearScanState()

        self.isScanning = false
        self.finishedPublisher.send()
    }

    
    private func concurrentTaskGroup(_ assets: [PHAsset] = [], maxConcurrent: Int = 10)async throws -> [ScannedPhoto]{
        var iterator = assets.makeIterator()
        var newPhotos: [ScannedPhoto] = []
        let saveInterval: Int = 25
        
        try await withThrowingTaskGroup(of: ScannedPhoto?.self) { group in
            for _ in 0..<maxConcurrent {
                if let asset = iterator.next() {
                    group.addTask {
                        self.processAsset(asset)
                    }
                }
            }
            
            for try await scanned in group {
                if let scannedPhoto = scanned {
                    self.scannedPhotos.append(scannedPhoto)
                    self.processedAssets += 1
                    
                    if processedAssets % saveInterval == 0 {
                        try? await PersistenceManager.shared.saveScanState(
                                scannedPhotos,
                                progressIndex: processedAssets)
                    }
                    
                    //try? await Task.sleep(nanoseconds: 50_000_000)
                    
                    await MainActor.run {
                        self.scannedBatchesPublisher.send([scannedPhoto])
                        self.progressPublisher.send((self.processedAssets, self.totalAssets))
                    }
                    newPhotos.append(scannedPhoto)
                }
                if let nextAsset = iterator.next() {
                    group.addTask {
                        self.processAsset(nextAsset)
                    }
                }
            }
        }
        return newPhotos
    }
    
    private func processAsset(_ asset: PHAsset) -> ScannedPhoto? {
        let value = asset.reliableHash()
        let groupRaw = PhotoGroup.group(for: value)?.rawValue ?? "other"
        
        return ScannedPhoto(
            id: asset.localIdentifier,
            group: groupRaw,
            cretaedAt: asset.creationDate ?? Date()
        )
    }

    
    private func fetchingAllAssets() -> [PHAsset] {
        var currentAssets: [PHAsset] = []
        let assets = PHAsset.fetchAssets(with: .image, options: nil)
        assets.enumerateObjects { asset, _, _ in
            currentAssets.append(asset)
        }
        return currentAssets
    }
    
    func groupedScanned() -> [String: Int] {
        var groupCounts: [String: Int] = [:]
        for photo in self.scannedPhotos {
            groupCounts[photo.group, default: 0] += 1
        }
        return groupCounts
    }
    
    func assets(for groupRaw: String) -> [String] {
        self.scannedPhotos.filter { $0.group == groupRaw }.map { $0.id }
    }
    
    func reset()async throws {
        scannedPhotos.removeAll()
        self.processedAssets = 0
        try? await PersistenceManager.shared.clearScanState()
    }
}
