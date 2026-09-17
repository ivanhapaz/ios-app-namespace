import SwiftUI

/// Hosts the 3D SceneKit world and overlays the SwiftUI game UI: the four-meter
/// HUD, the movement joystick, the "Approach" prompt, the dialogue card, and the
/// game-over screen. `MovementInput` and `GameState` are held as stable state so
/// the joystick, HUD, and scene controller all share the same instances.
struct GameContainerView: View {
    @State private var input = MovementInput()
    @StateObject private var game = GameState()

    var body: some View {
        ZStack {
            GameSceneView(input: input, game: game)
                .ignoresSafeArea()

            // Top: always-visible meters.
            VStack {
                MetersHUD(meters: game.meters)
                    .padding(.top, 10)
                Spacer()
            }

            // Bottom: movement + decorative item bar.
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    JoystickView(input: input)
                    Spacer()
                    ItemBar()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }

            // "Approach" prompt when near an NPC (and not already busy).
            if let npc = game.nearby, game.activeDilemma == nil, game.gameOver == nil {
                VStack {
                    Spacer()
                    Button {
                        game.activeDilemma = DilemmaCatalog.dilemma(for: npc)
                    } label: {
                        Label("Approach", systemImage: "bubble.left.fill")
                            .font(.system(.headline, design: .serif))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color(red: 0.30, green: 0.25, blue: 0.50)))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 128)
                }
            }

            // Dialogue over a dimmed world.
            if let dilemma = game.activeDilemma, game.gameOver == nil {
                Color.black.opacity(0.35).ignoresSafeArea()
                DialogueCard(dilemma: dilemma) { choice in
                    game.apply(choice.delta)
                    game.activeDilemma = nil
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Loss screen.
            if let info = game.gameOver {
                GameOverView(info: info) {
                    game.restart()
                }
            }
        }
        .statusBarHidden(true)
        .animation(.easeInOut(duration: 0.18), value: game.nearby)
        .animation(.easeInOut(duration: 0.2), value: game.activeDilemma?.id)
    }
}
