import Foundation

/// The pure game rules — no UI framework, so it runs and tests on any platform.
/// The iOS app wraps this in an `ObservableObject` for SwiftUI.
///
/// The two systems most worth tuning live here: `choose(_:)`/`apply(_:)` (how a
/// turn moves the meters + advances the clock) and `checkLoss()` (what ends a
/// run). After each action, `lastFiredEvent` holds a consequence that just came
/// due (if any), and `gameOver` is set once the run has ended.
public struct GameEngine {
    public var meters: Meters
    public var day: Int
    public var slot: TimeSlot
    public var inventory: [Item]
    public var pendingEvents: [ScheduledEvent]
    public var rank: String

    public private(set) var lastFiredEvent: ScheduledEvent?
    public private(set) var gameOver: GameOverInfo?

    public init(meters: Meters = Meters(),
                day: Int = 1,
                slot: TimeSlot = .morning,
                inventory: [Item] = [],
                rank: String = "a groom of the chamber") {
        self.meters = meters
        self.day = day
        self.slot = slot
        self.inventory = inventory
        self.pendingEvents = []
        self.rank = rank
        self.lastFiredEvent = nil
        self.gameOver = nil
    }

    // MARK: Inventory

    public func has(_ item: Item) -> Bool { inventory.contains(item) }
    public mutating func add(_ item: Item) { inventory.append(item) }
    public mutating func remove(_ item: Item) {
        if let index = inventory.firstIndex(of: item) { inventory.remove(at: index) }
    }

    // MARK: Turns

    /// Resolve a dilemma choice: move items, schedule any consequence, apply
    /// meters, then let a slot pass.
    public mutating func choose(_ choice: Choice) {
        lastFiredEvent = nil
        if let granted = choice.grant { add(granted) }
        if let consumed = choice.consume { remove(consumed) }
        if let template = choice.schedules {
            pendingEvents.append(ScheduledEvent(
                fireOnDay: day + template.delayDays,
                title: template.title,
                body: template.body,
                effect: template.effect
            ))
        }
        applyMeters(choice.delta)
        tick()
    }

    /// Apply a bare meter delta, then let a slot pass.
    public mutating func apply(_ delta: MeterDelta) {
        lastFiredEvent = nil
        applyMeters(delta)
        tick()
    }

    /// Bide your time: let a slot pass (which can trigger delayed consequences).
    public mutating func wait() {
        lastFiredEvent = nil
        tick()
    }

    // MARK: Internals

    private mutating func applyMeters(_ delta: MeterDelta) {
        meters.royalFavor = clamp(meters.royalFavor + delta.royalFavor)
        meters.piety = clamp(meters.piety + delta.piety)
        meters.wealth = clamp(meters.wealth + delta.wealth)
        meters.suspicion = clamp(meters.suspicion + delta.suspicion)
    }

    private mutating func tick() {
        advanceClock()
        fireDueEvents()
        checkLoss()
    }

    private mutating func advanceClock() {
        let (next, newDay) = slot.advanced()
        slot = next
        if newDay { day += 1 }
    }

    private mutating func fireDueEvents() {
        guard let index = pendingEvents.firstIndex(where: { $0.fireOnDay <= day }) else { return }
        let event = pendingEvents.remove(at: index)
        applyMeters(event.effect)
        lastFiredEvent = event
    }

    private func clamp(_ value: Int) -> Int { min(100, max(0, value)) }

    /// A run ends when any "good" meter bottoms out, or Suspicion tops out.
    private mutating func checkLoss() {
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

    private mutating func fail(_ cause: String) {
        gameOver = GameOverInfo(cause: cause, daysSurvived: day, rank: rank)
    }
}
