import Foundation

/// The three slots of a court day. The King keeps a fixed daily routine, so the
/// slot determines which room he holds court in — and therefore when you can
/// seek his favour.
public enum TimeSlot: Int, CaseIterable {
    case morning
    case midday
    case evening

    public var label: String {
        switch self {
        case .morning: return "MORNING"
        case .midday: return "MIDDAY"
        case .evening: return "EVENING"
        }
    }

    /// Advance one slot. Returns the next slot and whether the day rolled over
    /// (Evening → next Morning).
    public func advanced() -> (slot: TimeSlot, newDay: Bool) {
        switch self {
        case .morning: return (.midday, false)
        case .midday: return (.evening, false)
        case .evening: return (.morning, true)
        }
    }

    /// Where His Majesty holds court during this slot.
    public var kingRoom: RoomID {
        switch self {
        case .morning: return .chapel        // at Mass
        case .midday: return .greatHall       // holding court
        case .evening: return .privyChamber   // his inner sanctum
        }
    }
}
