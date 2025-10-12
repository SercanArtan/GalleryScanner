import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var viewModel: GroupDetailViewModel
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Group \(viewModel.groupRaw.uppercased())")
                .titleStyle()
            
            ScrollView {
                ImageGrid(images: viewModel.images)
                    .padding()
            }
        }
    }
}

struct ImageGrid: View {
    let images: [UIImage]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 16) {
            ForEach(images.indices, id: \.self) { index in
                NavigationLink(destination: ImageDetailView(images: images, startIndex: index)){
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(3)
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}
