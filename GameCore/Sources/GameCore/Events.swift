import Foundation

/// Authoring-time description of a delayed consequence: fire it `delayDays`
/// after the choice that scheduled it, apply `effect`, and show `title`/`body`.
public struct EventTemplate {
    public let delayDays: Int
    public let title: String
    public let body: String
    public let effect: MeterDelta

    public init(delayDays: Int, title: String, body: String, effect: MeterDelta) {
        self.delayDays = delayDays
        self.title = title
        self.body = body
        self.effect = effect
    }
}

/// A consequence queued to fire on a specific day. Shown as a one-button card.
public struct ScheduledEvent: Identifiable {
    public let id = UUID()
    public let fireOnDay: Int
    public let title: String
    public let body: String
    public let effect: MeterDelta

    public init(fireOnDay: Int, title: String, body: String, effect: MeterDelta) {
        self.fireOnDay = fireOnDay
        self.title = title
        self.body = body
        self.effect = effect
    }
}
