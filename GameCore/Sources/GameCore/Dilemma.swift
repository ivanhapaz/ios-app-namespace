import Foundation

/// One option in a dilemma: a line of dialogue, the meter changes it causes, and
/// (optionally) an item it grants/consumes and a delayed consequence it sets off.
public struct Choice {
    public let text: String
    public let delta: MeterDelta
    public var grant: Item?
    public var consume: Item?
    public var schedules: EventTemplate?

    public init(text: String, delta: MeterDelta, grant: Item? = nil, consume: Item? = nil, schedules: EventTemplate? = nil) {
        self.text = text
        self.delta = delta
        self.grant = grant
        self.consume = consume
        self.schedules = schedules
    }
}

/// A two-choice dilemma presented when you approach an NPC.
public struct Dilemma: Identifiable {
    public let id = UUID()
    public let speaker: String
    public let setup: String
    public let choiceA: Choice
    public let choiceB: Choice

    public init(speaker: String, setup: String, choiceA: Choice, choiceB: Choice) {
        self.speaker = speaker
        self.setup = setup
        self.choiceA = choiceA
        self.choiceB = choiceB
    }
}

/// Starter dilemma content, kept as plain data so it's trivial to expand.
public enum DilemmaCatalog {
    /// `holding` is what the player currently carries — some encounters change
    /// when you're carrying the right item (delivering the letter, gifting).
    public static func dilemma(for npc: NPCID, holding: Set<Item> = []) -> Dilemma {
        // The Boleyn-letter quest: once you carry it, Cromwell offers to buy it.
        if npc == .cromwell && holding.contains(.letter) {
            return Dilemma(
                speaker: "Cromwell",
                setup: "That letter you carry — the one that ruins Lady Rochford. Hand it to me.",
                choiceA: Choice(text: "Deliver the Boleyn letter.",
                                delta: MeterDelta(royalFavor: 20, wealth: 20),
                                consume: .letter,
                                schedules: EventTemplate(
                                    delayDays: 2,
                                    title: "A Reckoning",
                                    body: "The lady-in-waiting has been dragged to the Tower — and everyone knows whose letter sealed it. The guilt sits ill with you.",
                                    effect: MeterDelta(piety: -10)
                                )),
                choiceB: Choice(text: "Keep it to yourself.",
                                delta: MeterDelta(suspicion: 5))
            )
        }

        // Gift: present a jewel to the King for favour (at the cost of wealth).
        if npc == .king && holding.contains(.jewel) {
            return Dilemma(
                speaker: "His Majesty the King",
                setup: "You kneel and offer a jewel worthy of a king.",
                choiceA: Choice(text: "Present the jewel.",
                                delta: MeterDelta(royalFavor: 15, wealth: -15),
                                consume: .jewel),
                choiceB: Choice(text: "Think better of it.", delta: MeterDelta())
            )
        }

        // Gift: present a holy relic to the priest for piety.
        if npc == .priest && holding.contains(.relic) {
            return Dilemma(
                speaker: "The Priest",
                setup: "You offer a holy relic to adorn the chapel altar.",
                choiceA: Choice(text: "Present the relic.",
                                delta: MeterDelta(piety: 15),
                                consume: .relic),
                choiceB: Choice(text: "Keep it a while longer.", delta: MeterDelta())
            )
        }

        switch npc {
        case .priest:
            return Dilemma(
                speaker: "The Priest",
                setup: "You were not at Mass yesterday. Where were you?",
                choiceA: Choice(text: "Confess you overslept.", delta: MeterDelta(piety: 5)),
                choiceB: Choice(text: "Lie — you tended a sick friend.", delta: MeterDelta(piety: -5, suspicion: 15))
            )
        case .rivalCourtier:
            return Dilemma(
                speaker: "Rival Courtier",
                setup: "I saw you slink from the Privy Chamber. Care to explain?",
                choiceA: Choice(text: "Bribe him to forget it.", delta: MeterDelta(wealth: -15, suspicion: -15)),
                choiceB: Choice(text: "Stare him down.", delta: MeterDelta(suspicion: 10))
            )
        case .servantSpy:
            return Dilemma(
                speaker: "The Servant",
                setup: "The Seymours pay for whispers about the Boleyns. Got any?",
                choiceA: Choice(text: "Sell a rumour.", delta: MeterDelta(wealth: 15, suspicion: 5), grant: .jewel),
                choiceB: Choice(text: "Tell them nothing.", delta: MeterDelta())
            )
        case .ladyInWaiting:
            return Dilemma(
                speaker: "Lady-in-Waiting",
                setup: "I have a letter that would ruin Lady Rochford. Will you carry it?",
                choiceA: Choice(text: "Take it.", delta: MeterDelta(suspicion: 10), grant: .letter),
                choiceB: Choice(text: "Refuse — keep your hands clean.", delta: MeterDelta(suspicion: -5))
            )
        case .cromwell:
            return Dilemma(
                speaker: "Cromwell",
                setup: "His Majesty wonders where your loyalties truly lie.",
                choiceA: Choice(text: "Pledge yourself to the King.", delta: MeterDelta(royalFavor: 15, suspicion: 5), grant: .relic),
                choiceB: Choice(text: "Stay carefully noncommittal.", delta: MeterDelta(royalFavor: -5, suspicion: -5))
            )
        case .king:
            return Dilemma(
                speaker: "His Majesty the King",
                setup: "His Majesty asks what you think of his new queen.",
                choiceA: Choice(text: "Flatter her endlessly.", delta: MeterDelta(royalFavor: 15, suspicion: 10)),
                choiceB: Choice(text: "Answer honestly.", delta: MeterDelta(royalFavor: -10, piety: 10))
            )
        }
    }
}
