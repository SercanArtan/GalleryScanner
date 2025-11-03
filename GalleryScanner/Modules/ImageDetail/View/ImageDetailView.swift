import SwiftUI

struct ImageDetailView: View {
    @StateObject private var viewModel: ImageDetailViewModel

    init(assetIDs: [String], startIndex: Int ) {
        _viewModel = StateObject(
            wrappedValue: ImageDetailViewModel(
                assetIDs: assetIDs,
                startIndex: startIndex
            )
        )
    }

    var body: some View {
        TabView(selection: viewModel.bindingForCurrentIndex()) {
            ForEach(viewModel.assetIDs.indices, id: \.self) { index in
                let assetID = viewModel.assetIDs[index]

                ZStack {
                    switch viewModel.imageState(for: assetID) {
                    case .full(let image):
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                    case .thumbnail(let image):
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                    case .none:
                        Color.black
                        ProgressView()
                    }
                }
                .tag(index)
                .onAppear {
                    viewModel.ensureImageLoaded(for: assetID)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}
