import SwiftUI

struct ImageDetailView: View {
    let images: [UIImage]
    @State var currentIndex: Int

    init(images: [UIImage], startIndex: Int) {
        self.images = images
        self.currentIndex = startIndex
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(images.indices, id: \.self) { i in
                Image(uiImage: images[i])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(1)
                    .tag(i)
                    
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
