import SwiftUI
import UIKit

struct HomeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {

        return UINavigationController(rootViewController: HomeViewController())
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
