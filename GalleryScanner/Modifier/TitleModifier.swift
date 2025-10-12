import SwiftUI

struct TitleModifier: ViewModifier {
    var size: CGFloat
    var color: Color
    var isBold: Bool
    func body(content: Content) -> some View {
        content
            .font(isBold ? .system(size: size, weight: .bold) : .system(size: size))
            .foregroundColor(color)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
    }
}

extension View {
    func titleStyle(size: CGFloat = 28, color: Color = .primary, isBold: Bool = true) -> some View {
        self.modifier(TitleModifier(size: size, color: color, isBold: isBold))
    }
}
