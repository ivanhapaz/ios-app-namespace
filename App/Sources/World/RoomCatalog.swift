import Foundation

/// The palace floor plan, kept as plain data so rooms and connections are
/// trivial to tweak. The Courtyard is the hub you start in; its four walls open
/// onto the Great Hall, Chapel, Kitchens, and Gardens. The King's Privy Chamber
/// sits one step deeper, through the Great Hall. The Chapel and Gardens each
/// hold a locked, story-only passage toward the Tower.
///
///                    Privy Chamber
///                          |
///                     Great Hall
///                          |
///   Kitchens ——————  Courtyard  —————— Chapel
///                          |
///                       Gardens
enum RoomCatalog {
    static let all: [RoomID: RoomDefinition] = {
        let defs: [RoomDefinition] = [
            RoomDefinition(
                id: .courtyard,
                name: "Courtyard",
                subtitle: "The heart of the palace",
                floor: (0.56, 0.55, 0.50), // cobble
                doorways: [
                    Doorway(.north, to: .greatHall),
                    Doorway(.east, to: .chapel),
                    Doorway(.west, to: .kitchens),
                    Doorway(.south, to: .gardens),
                ],
                npc: nil,
                isOutdoor: true
            ),
            RoomDefinition(
                id: .greatHall,
                name: "Great Hall",
                subtitle: "A rival courtier · gossiping ladies",
                floor: (0.84, 0.80, 0.71), // warm stone
                doorways: [
                    Doorway(.south, to: .courtyard),
                    Doorway(.north, to: .privyChamber),
                ],
                npc: .rivalCourtier
            ),
            RoomDefinition(
                id: .privyChamber,
                name: "Privy Chamber",
                subtitle: "Cromwell · the King",
                floor: (0.93, 0.84, 0.62), // royal gold
                doorways: [
                    Doorway(.south, to: .greatHall),
                ],
                npc: .cromwell
            ),
            RoomDefinition(
                id: .chapel,
                name: "Chapel",
                subtitle: "The priest · Piety",
                floor: (0.70, 0.72, 0.66), // cool stone
                doorways: [
                    Doorway(.west, to: .courtyard),
                    Doorway(.south, to: .tower, locked: true),
                ],
                npc: .priest
            ),
            RoomDefinition(
                id: .kitchens,
                name: "Kitchens",
                subtitle: "The servant-spy",
                floor: (0.72, 0.66, 0.58), // smoky brown-grey
                doorways: [
                    Doorway(.east, to: .courtyard),
                ],
                npc: .servantSpy
            ),
            RoomDefinition(
                id: .gardens,
                name: "Gardens",
                subtitle: "A lady-in-waiting",
                floor: (0.55, 0.64, 0.49), // forest green
                doorways: [
                    Doorway(.north, to: .courtyard),
                    Doorway(.east, to: .tower, locked: true),
                ],
                npc: .ladyInWaiting,
                isOutdoor: true
            ),
            RoomDefinition(
                id: .tower,
                name: "The Tower",
                subtitle: "Fail state",
                floor: (0.52, 0.20, 0.20), // ominous deep red
                doorways: [
                    Doorway(.north, to: .chapel, locked: true),
                    Doorway(.west, to: .gardens, locked: true),
                ],
                npc: nil
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
