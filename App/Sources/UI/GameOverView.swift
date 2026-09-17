import SwiftUI

/// The loss screen: which meter did you in, and a way to start over.
struct GameOverView: View {
    let info: GameOverInfo
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Color(red: 0.75, green: 0.30, blue: 0.30))

                Text("To the Tower")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(.white)

                Text(info.cause)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Button(action: onRestart) {
                    Text("Try Again")
                        .font(.system(.headline, design: .serif))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color(red: 0.52, green: 0.20, blue: 0.20)))
                        .foregroundStyle(.white)
                }
            }
            .padding(40)
        }
    }
}
