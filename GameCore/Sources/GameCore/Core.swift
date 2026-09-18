import Foundation

/// The four meters that decide your fate. All clamp to 0...100.
/// Suspicion is inverted: it *rises* toward danger and you lose at 100.
public struct Meters: Equatable {
    public var royalFavor: Int
    public var piety: Int
    public var wealth: Int
    public var suspicion: Int

    public init(royalFavor: Int = 50, piety: Int = 50, wealth: Int = 50, suspicion: Int = 10) {
        self.royalFavor = royalFavor
        self.piety = piety
        self.wealth = wealth
        self.suspicion = suspicion
    }
}

/// A choice's effect on the meters. Positive raises, negative lowers.
public struct MeterDelta: Equatable {
    public var royalFavor: Int
    public var piety: Int
    public var wealth: Int
    public var suspicion: Int

    public init(royalFavor: Int = 0, piety: Int = 0, wealth: Int = 0, suspicion: Int = 0) {
        self.royalFavor = royalFavor
        self.piety = piety
        self.wealth = wealth
        self.suspicion = suspicion
    }
}

/// The people you can approach.
public enum NPCID: String {
    case priest
    case rivalCourtier
    case servantSpy
    case ladyInWaiting
    case cromwell
    case king
}

/// Held quest items (the design's letter / jewel / relic).
public enum Item {
    case letter
    case jewel
    case relic
}

/// Top-level flow: the manuscript title, the live game, and the loss screen.
public enum GamePhase {
    case title
    case playing
    case gameOver
}

/// How a run ended (shown on the game-over screen).
public struct GameOverInfo: Identifiable {
    public let id = UUID()
    public let cause: String
    public let daysSurvived: Int
    public let rank: String

    public init(cause: String, daysSurvived: Int, rank: String) {
        self.cause = cause
        self.daysSurvived = daysSurvived
        self.rank = rank
    }
}
