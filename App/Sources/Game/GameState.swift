import SwiftUI

/// The four meters that decide your fate. All clamp to 0...100.
/// Suspicion is inverted: it *rises* toward danger and you lose at 100.
struct Meters {
    var royalFavor: Int = 50
    var piety: Int = 50
    var wealth: Int = 50
    var suspicion: Int = 0
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
}

struct GameOverInfo: Identifiable {
    let id = UUID()
    let cause: String
}

/// Central game state, observed by SwiftUI. Owns the meters, the currently
/// nearby NPC, the open dilemma, and the loss state.
///
/// NOTE: the two systems most worth tuning live here — `apply(_:)` (how choices
/// move the meters) and `checkLoss()` (what ends a run). Keep them readable.
final class GameState: ObservableObject {
    @Published var meters = Meters()
    @Published var nearby: NPCID?
    @Published var activeDilemma: Dilemma?
    @Published var gameOver: GameOverInfo?

    /// Apply a choice's deltas, clamped to 0...100, then test for a loss.
    func apply(_ delta: MeterDelta) {
        meters.royalFavor = clamp(meters.royalFavor + delta.royalFavor)
        meters.piety = clamp(meters.piety + delta.piety)
        meters.wealth = clamp(meters.wealth + delta.wealth)
        meters.suspicion = clamp(meters.suspicion + delta.suspicion)
        checkLoss()
    }

    private func clamp(_ value: Int) -> Int {
        return min(100, max(0, value))
    }

    /// A run ends when any "good" meter bottoms out, or Suspicion tops out.
    private func checkLoss() {
        if meters.royalFavor <= 0 {
            fail("You lost the King's favour. To the Tower.")
        } else if meters.piety <= 0 {
            fail("Branded a heretic. To the Tower.")
        } else if meters.wealth <= 0 {
            fail("Penniless and without friends. To the Tower.")
        } else if meters.suspicion >= 100 {
            fail("Your Suspicion was too great. To the Tower.")
        }
    }

    private func fail(_ cause: String) {
        activeDilemma = nil
        nearby = nil
        gameOver = GameOverInfo(cause: cause)
    }

    func restart() {
        meters = Meters()
        activeDilemma = nil
        gameOver = nil
    }
}
