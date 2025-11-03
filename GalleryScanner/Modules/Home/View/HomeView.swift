import SwiftUI
import UIKit

struct HomeView: UIViewControllerRepresentable {
    private let viewModel: HomeViewModel

    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
    }

    func makeUIViewController(context: Context) -> UINavigationController {

        return UINavigationController(rootViewController: HomeViewController(viewModel: viewModel))
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
