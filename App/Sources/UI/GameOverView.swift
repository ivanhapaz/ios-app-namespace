import SwiftUI
import GameCore

/// The loss screen: a full-screen scrim, then a danger-ruled manuscript panel
/// with "TO THE TOWER", the cause of death, a run summary, and a restart.
struct GameOverView: View {
    let info: GameOverInfo
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Theme.ink.opacity(0.62).ignoresSafeArea()

            VStack(spacing: 0) {
                Text("T")
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.goldLeaf)
                    .frame(width: 50, height: 50)
                    .background(Theme.ink)
                    .padding(.bottom, 18)

                VStack(spacing: 0) {
                    Text("TO THE")
                    Text("TOWER")
                }
                .font(Theme.display(27))
                .tracking(0.8)
                .foregroundStyle(Theme.danger)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

                Rectangle().fill(Theme.goldLeaf).frame(height: 1)
                    .padding(.horizontal, 10)
                    .padding(.top, 18)

                Text("the cause of thy death")
                    .font(Theme.bodyItalic(11))
                    .tracking(0.8)
                    .foregroundStyle(Theme.mutedText)
                    .padding(.top, 18)

                Text(info.cause)
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, 8)

                Text("Survived \(romanNumeral(info.daysSurvived).lowercased()) days · died \(info.rank)")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 18)

                Button(action: onRestart) {
                    Text("Begin anew")
                        .font(Theme.body(17))
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(ManuscriptButtonStyle(
                    fill: Theme.parchmentLight,
                    pressedFill: Theme.pressedFill,
                    inner: [FrameRule(gutter: 2, color: Theme.goldLeaf)],
                    vPad: 15, hPad: 15
                ))
                .padding(.top, 24)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
            .manuscriptPanel(
                inner: [FrameRule(gutter: 4, color: Theme.danger)],
                shadowRadius: 25, shadowY: 20
            )
            .padding(.horizontal, 22)
        }
    }
}
