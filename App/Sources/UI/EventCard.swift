import SwiftUI

/// A one-button "event" card for delayed consequences (e.g. the arrest a couple
/// of days after you sell out an ally). Manuscript-styled like the dilemma card.
struct EventCard: View {
    let event: ScheduledEvent
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(event.title)
                .font(Theme.display(18))
                .tracking(0.5)
                .foregroundStyle(Theme.danger)
                .multilineTextAlignment(.center)

            DividerRule()

            Text(event.body)
                .font(Theme.body(16))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onContinue) {
                Text("So be it")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(ManuscriptButtonStyle(
                fill: Theme.parchmentLight,
                pressedFill: Theme.pressedFill,
                inner: [FrameRule(gutter: 2, color: Theme.goldLeaf)],
                vPad: 12, hPad: 20
            ))
            .padding(.top, 4)
        }
        .padding(.top, 22)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: 340)
        .manuscriptPanel(inner: [FrameRule(gutter: 4, color: Theme.goldLeaf)])
        .padding(.horizontal, 18)
    }
}
