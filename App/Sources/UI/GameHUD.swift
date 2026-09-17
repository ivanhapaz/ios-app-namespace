import SwiftUI

/// Placeholder hotbar (bottom-right), purely for period flavour.
struct ItemBar: View {
    private let icons = ["flame.fill", "drop.fill", "book.closed.fill", "bag.fill", "seal.fill"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(icons, id: \.self) { name in
                Image(systemName: name)
                    .font(.system(size: 19))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
        }
    }
}
