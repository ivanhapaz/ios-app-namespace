import Foundation

/// Authoring-time description of a delayed consequence: fire it `delayDays`
/// after the choice that scheduled it, apply `effect`, and show `title`/`body`.
struct EventTemplate {
    let delayDays: Int
    let title: String
    let body: String
    let effect: MeterDelta
}

/// A consequence queued to fire on a specific day. Shown as a one-button card.
struct ScheduledEvent: Identifiable {
    let id = UUID()
    let fireOnDay: Int
    let title: String
    let body: String
    let effect: MeterDelta
}
