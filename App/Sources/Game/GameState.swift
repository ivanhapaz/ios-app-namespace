import SwiftUI
import GameCore

/// SwiftUI-facing wrapper around the pure `GameEngine` (which lives in GameCore
/// and holds all the rules). This layer is the only place Apple frameworks
/// (Combine/`@Published`) appear — it forwards player actions to the engine and
/// republishes its state so the SceneKit world + SwiftUI HUD can observe it.
final class GameState: ObservableObject {
    /// The rules/state. Mutating it republishes to the UI.
    @Published private(set) var engine = GameEngine()

    // UI-only state (presentation, not rules).
    @Published var phase: GamePhase = .title
    @Published var nearby: NPCID?
    @Published var activeDilemma: Dilemma?
    @Published var activeEvent: ScheduledEvent?
    @Published var roomName: String = "Courtyard"
    @Published var fade: Double = 0

    // Forwarders so views keep reading `game.meters`, `game.day`, etc.
    var meters: Meters { engine.meters }
    var day: Int { engine.day }
    var slot: TimeSlot { engine.slot }
    var inventory: [Item] { engine.inventory }
    var gameOver: GameOverInfo? { engine.gameOver }

    // MARK: Flow

    func begin() { phase = .playing }

    func has(_ item: Item) -> Bool { engine.has(item) }

    func choose(_ choice: Choice) {
        engine.choose(choice)
        activeDilemma = nil
        resolveAfterTurn()
    }

    func apply(_ delta: MeterDelta) {
        engine.apply(delta)
        resolveAfterTurn()
    }

    func wait() {
        engine.wait()
        resolveAfterTurn()
    }

    func dismissEvent() { activeEvent = nil }

    func restart() {
        engine = GameEngine()
        phase = .playing
        nearby = nil
        activeDilemma = nil
        activeEvent = nil
    }

    /// After a turn, surface any consequence that fired and any loss.
    private func resolveAfterTurn() {
        if let fired = engine.lastFiredEvent { activeEvent = fired }
        if engine.gameOver != nil {
            activeDilemma = nil
            nearby = nil
            phase = .gameOver
        }
    }
}
