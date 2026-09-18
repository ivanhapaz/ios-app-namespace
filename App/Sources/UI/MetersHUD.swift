import SwiftUI
import GameCore

/// The persistent four-meter HUD, top of screen. A 2×2 grid of chip + labelled
/// bar. Suspicion is the danger meter: danger-coloured label, an extra outline,
/// and a slow pulse once it climbs past 75.
struct MetersHUD: View {
    let meters: Meters

    var body: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 9) {
            GridRow {
                cell("F", "FAVOR", meters.royalFavor,
                     chip: Theme.vermilion, letter: Theme.parchment, bar: Theme.vermilion)
                cell("P", "PIETY", meters.piety,
                     chip: Theme.lapis, letter: Theme.parchment, bar: Theme.lapis)
            }
            GridRow {
                cell("W", "WEALTH", meters.wealth,
                     chip: Theme.goldLeaf, letter: Theme.ink, bar: Theme.goldLeaf)
                cell("S", "SUSPICION", meters.suspicion,
                     chip: Theme.ink, letter: Theme.parchment, bar: Theme.danger, isDanger: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .manuscriptPanel(radius: 4)
    }

    private func cell(_ initial: String, _ label: String, _ value: Int,
                      chip: Color, letter: Color, bar: Color, isDanger: Bool = false) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2)
                .fill(chip)
                .frame(width: 18, height: 18)
                .overlay(
                    Text(initial)
                        .font(Theme.display(9))
                        .foregroundStyle(letter)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(Theme.display(8))
                    .tracking(0.6)
                    .foregroundStyle(isDanger ? Theme.danger : Theme.mutedText)
                MeterBar(value: value, fill: bar, isDanger: isDanger)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A 5pt bar whose fill animates to `value`%. The danger bar carries an extra
/// outline and pulses when high.
private struct MeterBar: View {
    let value: Int
    let fill: Color
    var isDanger: Bool = false

    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.track)
                Rectangle()
                    .fill(fill)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 100)) / 100)
                    .animation(.easeOut(duration: 0.45), value: value)
            }
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.danger, lineWidth: isDanger ? 1 : 0)
                    .opacity(isDanger && value >= 75 ? (pulse ? 0.45 : 1.0) : 1.0)
            )
        }
        .frame(height: 5)
        .onAppear {
            if isDanger {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}
