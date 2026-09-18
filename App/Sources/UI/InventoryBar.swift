import SwiftUI
import GameCore

/// The persistent inventory bar (bottom): hand-drawn item tiles + a roman-numeral
/// day count. Icons are drawn from primitives — no image assets.
struct InventoryBar: View {
    let items: [Item]
    let day: Int
    let slot: TimeSlot

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                ItemTile(item: item)
            }
            Spacer()
            Text("DAY \(romanNumeral(day)) · \(slot.label)")
                .font(Theme.display(10))
                .tracking(1.2)
                .foregroundStyle(Theme.mutedText)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .manuscriptPanel()
    }
}

private struct ItemTile: View {
    let item: Item

    var body: some View {
        ZStack {
            Rectangle().fill(Theme.parchmentLight)
            icon
        }
        .frame(width: 34, height: 34)
        .overlay(Rectangle().strokeBorder(Theme.ruleBrown, lineWidth: 1.5))
    }

    @ViewBuilder private var icon: some View {
        switch item {
        case .letter:
            ZStack {
                Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5).frame(width: 20, height: 14)
                Rectangle().fill(Theme.vermilion).frame(width: 16, height: 6).offset(y: -2)
            }
        case .jewel:
            JewelShape().fill(Theme.lapis).frame(width: 14, height: 14)
        case .relic:
            ZStack {
                Rectangle().fill(Theme.goldLeaf).frame(width: 6, height: 18)
                Rectangle().fill(Theme.goldLeaf).frame(width: 18, height: 6).offset(y: -2)
            }
            .frame(width: 18, height: 18)
        }
    }
}

/// A four-point gem: apex top-centre, widest at 40% height, point at bottom.
private struct JewelShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.4))
        p.addLine(to: CGPoint(x: w * 0.5, y: h))
        p.addLine(to: CGPoint(x: 0, y: h * 0.4))
        p.closeSubpath()
        return p
    }
}
