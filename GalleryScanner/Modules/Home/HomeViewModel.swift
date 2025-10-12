import UIKit
import Combine
import Photos

class HomeViewModel: ObservableObject {
    @Published var groupCounts: [String : Int] = [:]
    @Published var progress: Float = 0
    @Published var statusText = "Waiting for permission"
    
    let showAlert = PassthroughSubject<UIAlertController, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }

    func requestPhotoAuthorization() {
        PHPhotoLibrary.requestAuthorization{ status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self.statusText = "Authorized - Starting scan ..."
                    PhotoScanner.shared.resumeOrStartScan()
                } else {
                    self.statusText = "Photo access denied"
                    self.showDeniedAlert()
                }
            }
        }
    }
    
    private func setupBindings() {
        PhotoScanner.shared.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processed, total in
                guard let self = self else { return }
                self.progress = total == 0 ? 0 : Float(processed) / Float(total)
                self.statusText = "Processed \((self.progress * 100).rounded(.down)) % photos"
                self.groupCounts = PhotoScanner.shared.groupedScanned()
            }
            .store(in: &cancellables)
        
        PhotoScanner.shared.finishedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.statusText = "Scan Complete"
                self.progress = 1
            }
            .store(in: &cancellables)
    }
    
    private func showDeniedAlert() {
        let alert = UIAlertController(title: "Photo Access Denied Limited Access", message: "Please allow this app to full access your photos in Settings", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.showAlert.send(alert)
    }
}
