import SwiftUI

/// The title screen: a four-rule manuscript panel over the live 3D scene (no
/// scrim), with a BEGIN call to action.
struct TitleView: View {
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Here beginneth the chronicle of")
                .font(Theme.bodyItalic(12))
                .tracking(1.0)
                .foregroundStyle(Theme.mutedText)

            VStack(spacing: 0) {
                Text("WILL THEY")
                Text("KEEP THEIR")
                Text("HEAD?")
            }
            .font(Theme.display(30))
            .tracking(0.6)
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.top, 16)

            DividerRule(device: .diamond)
                .padding(.top, 20)

            Text("Wherein a courtier of no great birth must keep both his wits and his neck.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 20)

            Button(action: onBegin) {
                Text("BEGIN")
                    .font(Theme.display(15))
                    .tracking(3.6)
                    .foregroundStyle(Theme.parchmentLight)
            }
            .buttonStyle(ManuscriptButtonStyle(
                fill: Theme.vermilion,
                pressedFill: Color(hex: 0xBB3623),
                inner: [FrameRule(gutter: 3, color: Theme.goldLeaf)],
                vPad: 16, hPad: 16
            ))
            .padding(.top, 28)
        }
        .padding(.top, 36)
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
        .manuscriptPanel(
            inner: [FrameRule(gutter: 5, color: Theme.goldLeaf),
                    FrameRule(gutter: 3, color: Theme.vermilion)],
            shadowRadius: 25, shadowY: 20
        )
        .padding(.horizontal, 24)
    }
}
