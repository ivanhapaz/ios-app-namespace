import SwiftUI

/// The four meters that decide your fate. All clamp to 0...100.
/// Suspicion is inverted: it *rises* toward danger and you lose at 100.
struct Meters {
    var royalFavor: Int = 50
    var piety: Int = 50
    var wealth: Int = 50
    var suspicion: Int = 10
}

/// A choice's effect on the meters. Positive raises, negative lowers.
struct MeterDelta {
    var royalFavor: Int = 0
    var piety: Int = 0
    var wealth: Int = 0
    var suspicion: Int = 0
}

/// The people you can approach. Only the priest is placed in the courtyard for
/// now; the rest have content ready for when their rooms exist.
enum NPCID: String {
    case priest
    case rivalCourtier
    case servantSpy
    case ladyInWaiting
    case cromwell
    case king
}

/// Held quest items (the design's letter / jewel / relic).
enum Item {
    case letter
    case jewel
    case relic
}

/// Top-level flow: the manuscript title, the live game, and the loss screen.
enum GamePhase {
    case title
    case playing
    case gameOver
}

struct GameOverInfo: Identifiable {
    let id = UUID()
    let cause: String
    let daysSurvived: Int
    let rank: String
}

/// Central game state, observed by SwiftUI. Owns the phase, meters, day count,
/// inventory, the nearby NPC, the open dilemma, and the loss state.
///
/// NOTE: the two systems most worth tuning live here — `apply(_:)` (how choices
/// move the meters + advance the day) and `checkLoss()` (what ends a run).
final class GameState: ObservableObject {
    @Published var phase: GamePhase = .title
    @Published var meters = Meters()
    @Published var day: Int = 1
    @Published var slot: TimeSlot = .morning
    @Published var inventory: [Item] = []

    @Published var nearby: NPCID?
    @Published var activeDilemma: Dilemma?
    @Published var gameOver: GameOverInfo?

    /// The room you're currently standing in (for the HUD/scene banner).
    @Published var roomName: String = "Courtyard"
    /// Screen fade for room transitions: 0 = clear, 1 = black.
    @Published var fade: Double = 0

    /// The rank you'll be remembered by (shown on the game-over screen).
    var rank = "a groom of the chamber"

    // MARK: Flow

    func begin() {
        phase = .playing
    }

    /// Apply a choice's deltas, advance the clock, then test for a loss.
    func apply(_ delta: MeterDelta) {
        meters.royalFavor = clamp(meters.royalFavor + delta.royalFavor)
        meters.piety = clamp(meters.piety + delta.piety)
        meters.wealth = clamp(meters.wealth + delta.wealth)
        meters.suspicion = clamp(meters.suspicion + delta.suspicion)
        advanceClock()
        checkLoss()
    }

    /// Bide your time: advance the clock without an encounter.
    func wait() {
        advanceClock()
    }

    /// Move to the next slot; roll to a new day after Evening.
    private func advanceClock() {
        let (next, newDay) = slot.advanced()
        slot = next
        if newDay { day += 1 }
    }

    private func clamp(_ value: Int) -> Int {
        return min(100, max(0, value))
    }

    /// A run ends when any "good" meter bottoms out, or Suspicion tops out.
    private func checkLoss() {
        if meters.royalFavor <= 0 {
            fail("You lost the King's favour, and with it your place at court.")
        } else if meters.piety <= 0 {
            fail("Branded a heretic before the whole court.")
        } else if meters.wealth <= 0 {
            fail("Penniless and without a friend to vouch for you.")
        } else if meters.suspicion >= 100 {
            fail("Overheard once too often; the King's men came at dawn.")
        }
    }

    private func fail(_ cause: String) {
        activeDilemma = nil
        nearby = nil
        gameOver = GameOverInfo(cause: cause, daysSurvived: day, rank: rank)
        phase = .gameOver
    }

    /// Begin a fresh run (from the game-over screen).
    func restart() {
        meters = Meters()
        day = 1
        slot = .morning
        inventory = []
        activeDilemma = nil
        gameOver = nil
        nearby = nil
        phase = .playing
    }
}
