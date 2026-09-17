import SwiftUI

/// Lightweight chrome over the 3D world: a serif title banner and a decorative
/// item bar echoing the reference's hotbar. Non-functional for now — the real
/// meters and inventory arrive in later phases.
struct GameHUD: View {
    var body: some View {
        VStack {
            HStack {
                Text("Will They Keep Their Head?")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.35), in: Capsule())
                Spacer()
            }
            Spacer()
        }
        .padding(.top, 10)
        .padding(.leading, 16)
    }
}

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
