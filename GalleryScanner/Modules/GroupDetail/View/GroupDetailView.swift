import SwiftUI
import UIKit

struct GroupDetailView: View {
    @StateObject private var viewModel: GroupDetailViewModel
    
    init(groupRaw: String) {
        _viewModel = StateObject(
            wrappedValue: GroupDetailViewModel(groupRaw: groupRaw)
        )
    }

    var body: some View {
        VStack(alignment: .center) {
            Text("Group \(viewModel.groupRaw.uppercased())")
                .titleStyle()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 16) {
                    ForEach(viewModel.assetIDs, id: \.self) { assetID in
                        NavigationLink {
                            ImageDetailView(
                                assetIDs: viewModel.assetIDs,
                                startIndex: viewModel.assetIDs.firstIndex(of: assetID) ?? 0
                            )
                        } label: {
                            ThumbnailCell(assetID: assetID, viewModel: viewModel)
                                .frame(width: 150, height: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    struct ThumbnailCell: View {
        let assetID: String
        @ObservedObject var viewModel: GroupDetailViewModel
        
        var body: some View {
            ZStack {
                switch viewModel.imageState(for: assetID) {
                case .thumbnail(let image), .full(let image):
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .padding()
                case .none:
                    Color.gray.opacity(0.2)
                        .frame(width: 150, height: 150)
                    ProgressView()
                }
            }
            .clipped()
            .onAppear {
                viewModel.ensureThumbnailLoaded(for: assetID)
            }
        }
    }
}
