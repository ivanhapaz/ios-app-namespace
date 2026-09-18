import SwiftUI
import GameCore

/// Hosts the 3D palace and layers the manuscript UI over it, driven by the game
/// phase: a title screen, the live HUD + inventory + dialogue, room-transition
/// fade, and the game-over screen.
struct GameContainerView: View {
    @State private var input = MovementInput()
    @StateObject private var game = GameState()

    var body: some View {
        ZStack {
            GameSceneView(input: input, game: game)
                .ignoresSafeArea()

            // Movement: drag anywhere on the open view (only while playing).
            if game.phase == .playing {
                MoveCatcher(input: input)
                    .ignoresSafeArea()
            }

            // HUD + inventory during play.
            if game.phase == .playing {
                VStack(spacing: 0) {
                    MetersHUD(meters: game.meters)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                    Spacer()
                    InventoryBar(items: game.inventory, day: game.day, slot: game.slot)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                }

                // Bottom-centre action: Approach when near someone, else Wait to
                // pass the time (which moves the King along his schedule).
                VStack {
                    Spacer()
                    if let npc = game.nearby, game.activeDilemma == nil, game.activeEvent == nil {
                        Button {
                            game.activeDilemma = DilemmaCatalog.dilemma(for: npc, holding: Set(game.inventory))
                        } label: {
                            Text("Approach")
                                .font(Theme.body(16))
                                .foregroundStyle(Theme.ink)
                        }
                        .buttonStyle(ManuscriptButtonStyle(
                            fill: Theme.parchmentLight,
                            pressedFill: Theme.pressedFill,
                            inner: [FrameRule(gutter: 2, color: Theme.goldLeaf)],
                            vPad: 12, hPad: 22
                        ))
                        .fixedSize()
                        .padding(.bottom, 118)
                    } else if game.activeDilemma == nil, game.activeEvent == nil {
                        Button {
                            withAnimation { game.wait() }
                        } label: {
                            Label("Wait", systemImage: "hourglass")
                                .font(Theme.body(15))
                                .foregroundStyle(Theme.mutedText)
                        }
                        .buttonStyle(ManuscriptButtonStyle(
                            fill: Theme.parchmentLight,
                            pressedFill: Theme.pressedFill,
                            inner: [FrameRule(gutter: 2, color: Theme.goldLeaf.opacity(0.75))],
                            vPad: 10, hPad: 18
                        ))
                        .fixedSize()
                        .padding(.bottom, 118)
                    }
                }
            }

            // Room-transition fade (covers everything for a clean wipe).
            Color.black
                .opacity(game.fade)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // A delayed consequence has come due (shown over a light dim).
            if let event = game.activeEvent, game.phase == .playing {
                Color.black.opacity(0.35).ignoresSafeArea()
                EventCard(event: event) { game.dismissEvent() }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            // Dilemma over a light dim.
            if let dilemma = game.activeDilemma, game.activeEvent == nil, game.phase == .playing {
                Theme.ink.opacity(0.28).ignoresSafeArea()
                DialogueCard(dilemma: dilemma) { choice in
                    game.choose(choice)
                    game.activeDilemma = nil
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Title.
            if game.phase == .title {
                TitleView { withAnimation(.easeInOut(duration: 0.3)) { game.begin() } }
                    .transition(.opacity)
            }

            // Game over.
            if game.phase == .gameOver, let info = game.gameOver {
                GameOverView(info: info) {
                    withAnimation(.easeInOut(duration: 0.3)) { game.restart() }
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .animation(.easeInOut(duration: 0.18), value: game.nearby)
        .animation(.easeOut(duration: 0.25), value: game.activeDilemma?.id)
        .animation(.easeOut(duration: 0.25), value: game.activeEvent?.id)
        .animation(.easeInOut(duration: 0.22), value: game.fade)
        .animation(.easeInOut(duration: 0.35), value: game.phase)
    }
}
