import Foundation


actor PersistenceManager {
    static let shared = PersistenceManager()
    
    private var documentUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func fileURL(named: String) -> URL {
        documentUrl.appendingPathComponent(named)
    }
    
    func saveScanState(_ photos: [ScannedPhoto], progressIndex: Int) async throws {
        let container = ScanPersistence(photos: photos, progressIndex: progressIndex)
        let data = try JSONEncoder().encode(container)
        try data.write(to: fileURL(named: "scanned_images.json"), options: .atomic)
    }
    
    func loadScanState()async -> ScanPersistence? {
        let url = fileURL(named: "scanned_images.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ScanPersistence.self, from: data)
    }
    
    func clearScanState()async throws {
        let url = fileURL(named: "scanned_images.json")
        try? FileManager.default.removeItem(at: url)
    }
}
