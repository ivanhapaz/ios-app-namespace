import Foundation

/// One option in a dilemma: a line of dialogue and the meter changes it causes.
struct Choice {
    let text: String
    let delta: MeterDelta
}

/// A two-choice dilemma presented when you approach an NPC.
struct Dilemma: Identifiable {
    let id = UUID()
    let speaker: String
    let setup: String
    let choiceA: Choice
    let choiceB: Choice
}

/// Starter dilemma content, kept as plain data so it's trivial to expand or move
/// into JSON later. Values come straight from the design's section 6.
enum DilemmaCatalog {
    static func dilemma(for npc: NPCID) -> Dilemma {
        switch npc {
        case .priest:
            return Dilemma(
                speaker: "The Priest",
                setup: "You were not at Mass yesterday. Where were you?",
                choiceA: Choice(text: "Confess you overslept.",
                                delta: MeterDelta(piety: 5)),
                choiceB: Choice(text: "Lie — you tended a sick friend.",
                                delta: MeterDelta(piety: -5, suspicion: 15))
            )
        case .rivalCourtier:
            return Dilemma(
                speaker: "Rival Courtier",
                setup: "I saw you slink from the Privy Chamber. Care to explain?",
                choiceA: Choice(text: "Bribe him to forget it.",
                                delta: MeterDelta(wealth: -15, suspicion: -15)),
                choiceB: Choice(text: "Stare him down.",
                                delta: MeterDelta(suspicion: 10))
            )
        case .servantSpy:
            return Dilemma(
                speaker: "The Servant",
                setup: "The Seymours pay for whispers about the Boleyns. Got any?",
                choiceA: Choice(text: "Sell a rumour.",
                                delta: MeterDelta(wealth: 15, suspicion: 5)),
                choiceB: Choice(text: "Tell them nothing.",
                                delta: MeterDelta())
            )
        case .ladyInWaiting:
            return Dilemma(
                speaker: "Lady-in-Waiting",
                setup: "I have a letter that would ruin Lady Rochford. Will you carry it?",
                choiceA: Choice(text: "Take it.",
                                delta: MeterDelta(suspicion: 10)),
                choiceB: Choice(text: "Refuse — keep your hands clean.",
                                delta: MeterDelta(suspicion: -5))
            )
        case .cromwell:
            return Dilemma(
                speaker: "Cromwell",
                setup: "His Majesty wonders where your loyalties truly lie.",
                choiceA: Choice(text: "Pledge yourself to the King.",
                                delta: MeterDelta(royalFavor: 15, suspicion: 5)),
                choiceB: Choice(text: "Stay carefully noncommittal.",
                                delta: MeterDelta(royalFavor: -5, suspicion: -5))
            )
        case .king:
            return Dilemma(
                speaker: "His Majesty the King",
                setup: "His Majesty asks what you think of his new queen.",
                choiceA: Choice(text: "Flatter her endlessly.",
                                delta: MeterDelta(royalFavor: 15, suspicion: 10)),
                choiceB: Choice(text: "Answer honestly.",
                                delta: MeterDelta(royalFavor: -10, piety: 10))
            )
        }
    }
}
