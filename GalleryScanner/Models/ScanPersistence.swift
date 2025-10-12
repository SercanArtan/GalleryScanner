import Foundation

struct ScanPersistence: Codable {
    var photos: [ScannedPhoto]
    var progressIndex: Int
}
