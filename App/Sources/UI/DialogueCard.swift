import SwiftUI

/// A parchment-styled choice card shown over the 3D world when you converse.
struct DialogueCard: View {
    let dilemma: Dilemma
    let onChoose: (Choice) -> Void

    private let ink = Color(red: 0.20, green: 0.15, blue: 0.10)

    var body: some View {
        VStack(spacing: 18) {
            Text(dilemma.speaker)
                .font(.system(.title3, design: .serif).weight(.bold))
            Text(dilemma.setup)
                .font(.system(.body, design: .serif))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                choiceButton(dilemma.choiceA)
                choiceButton(dilemma.choiceB)
            }
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.96, green: 0.93, blue: 0.84))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.42, green: 0.30, blue: 0.18), lineWidth: 2)
        )
        .foregroundStyle(ink)
        .shadow(radius: 24)
        .padding(24)
    }

    private func choiceButton(_ choice: Choice) -> some View {
        Button {
            onChoose(choice)
        } label: {
            Text(choice.text)
                .font(.system(.callout, design: .serif))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.52, green: 0.20, blue: 0.20))
                )
                .foregroundStyle(.white)
        }
    }
}
