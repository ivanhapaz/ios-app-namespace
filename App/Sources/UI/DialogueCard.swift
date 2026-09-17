import SwiftUI

/// The dilemma card: a manuscript panel with a vermilion drop cap, the setup in
/// Iowan Old Style, a gold divider, and two roman-numeralled choice buttons.
struct DialogueCard: View {
    let dilemma: Dilemma
    let onChoose: (Choice) -> Void

    private var dropCap: String { String(dilemma.setup.prefix(1)) }
    private var bodyText: String { String(dilemma.setup.dropFirst()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(dropCap)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.parchment)
                    .frame(width: 56, height: 56)
                    .background(Theme.vermilion)
                    .overlay(Rectangle().strokeBorder(Theme.goldLeaf, lineWidth: 2))
                Text(bodyText)
                    .font(Theme.body(18))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DividerRule()
                .padding(.top, 20)
                .padding(.bottom, 16)

            VStack(spacing: 9) {
                choiceButton(dilemma.choiceA, numeral: "I", color: Theme.vermilion)
                choiceButton(dilemma.choiceB, numeral: "II", color: Theme.lapis)
            }
        }
        .padding(.top, 22)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .manuscriptPanel(inner: [FrameRule(gutter: 4, color: Theme.goldLeaf)])
        .padding(.horizontal, 18)
    }

    private func choiceButton(_ choice: Choice, numeral: String, color: Color) -> some View {
        Button {
            onChoose(choice)
        } label: {
            HStack(spacing: 10) {
                Text(numeral)
                    .font(Theme.display(10))
                    .foregroundStyle(Theme.goldLeaf)
                Text(choice.text)
                    .font(Theme.body(16))
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(ManuscriptButtonStyle(
            fill: Theme.parchmentLight,
            pressedFill: Theme.pressedFill,
            inner: [FrameRule(gutter: 2, color: Theme.goldLeaf.opacity(0.75))],
            vPad: 13, hPad: 14
        ))
    }
}
