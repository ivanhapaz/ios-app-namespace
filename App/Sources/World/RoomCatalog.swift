import Foundation

/// The palace floor plan, kept as plain data so rooms and connections are
/// trivial to tweak. Layout mirrors the design's map:
///
///                 Privy Chamber
///                       |
///   Kitchens ——— Great Hall ——— Chapel
///                       |            :
///                    Gardens ····· Tower
///
/// Great Hall is the hub (north→Privy, west→Kitchens, east→Chapel,
/// south→Gardens). The Chapel and Gardens each hold a locked, story-only
/// passage toward the Tower.
enum RoomCatalog {
    static let all: [RoomID: RoomDefinition] = {
        let defs: [RoomDefinition] = [
            RoomDefinition(
                id: .greatHall,
                name: "Great Hall",
                subtitle: "Rival courtier · gossiping ladies",
                floor: (0.84, 0.80, 0.71), // warm stone
                doorways: [
                    Doorway(.north, to: .privyChamber),
                    Doorway(.west, to: .kitchens),
                    Doorway(.east, to: .chapel),
                    Doorway(.south, to: .gardens),
                ]
            ),
            RoomDefinition(
                id: .privyChamber,
                name: "Privy Chamber",
                subtitle: "Cromwell · the King",
                floor: (0.93, 0.84, 0.62), // royal gold
                doorways: [
                    Doorway(.south, to: .greatHall),
                ]
            ),
            RoomDefinition(
                id: .chapel,
                name: "Chapel",
                subtitle: "The priest · Piety",
                floor: (0.70, 0.72, 0.66), // cool stone
                doorways: [
                    Doorway(.west, to: .greatHall),
                    Doorway(.south, to: .tower, locked: true),
                ]
            ),
            RoomDefinition(
                id: .kitchens,
                name: "Kitchens",
                subtitle: "The servant-spy",
                floor: (0.72, 0.66, 0.58), // smoky brown-grey
                doorways: [
                    Doorway(.east, to: .greatHall),
                ]
            ),
            RoomDefinition(
                id: .gardens,
                name: "Gardens",
                subtitle: "Lady-in-waiting",
                floor: (0.55, 0.64, 0.49), // forest green
                doorways: [
                    Doorway(.north, to: .greatHall),
                    Doorway(.east, to: .tower, locked: true),
                ]
            ),
            RoomDefinition(
                id: .tower,
                name: "The Tower",
                subtitle: "Fail state",
                floor: (0.52, 0.20, 0.20), // ominous deep red
                doorways: [
                    // Reciprocals of the story-only passages, also locked.
                    Doorway(.north, to: .chapel, locked: true),
                    Doorway(.west, to: .gardens, locked: true),
                ]
            ),
        ]
        return Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })
    }()

    static func room(_ id: RoomID) -> RoomDefinition {
        guard let def = all[id] else {
            fatalError("Missing room definition for \(id)")
        }
        return def
    }

    /// The doorway in `room` that leads back to `origin`, if any. Used to place
    /// the player at the correct entry point after a transition.
    static func doorway(in room: RoomID, leadingTo origin: RoomID) -> Doorway? {
        return all[room]?.doorways.first { $0.destination == origin }
    }
}
