import Foundation

/// The six rooms of the palace (plus the Tower fail-state room).
public enum RoomID: String, CaseIterable, Codable {
    case courtyard
    case greatHall
    case privyChamber
    case chapel
    case kitchens
    case gardens
    case tower
}

/// A wall of a room.
public enum Edge {
    case north
    case south
    case east
    case west

    public var opposite: Edge {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        }
    }
}

/// A passage from one room to another, on a given wall. `locked` doorways are
/// story-only (the Chapel/Gardens passages toward the Tower).
public struct Doorway {
    public let edge: Edge
    public let destination: RoomID
    public let locked: Bool

    public init(_ edge: Edge, to destination: RoomID, locked: Bool = false) {
        self.edge = edge
        self.destination = destination
        self.locked = locked
    }
}

/// Static description of a room: label, resident NPC, floor tone, doorways.
public struct RoomDefinition {
    public let id: RoomID
    public let name: String
    public let subtitle: String
    /// Muted Tudor floor tone as RGB in 0...1 (Double, so this stays Linux-safe).
    public let floor: (r: Double, g: Double, b: Double)
    public let doorways: [Doorway]
    public let npc: NPCID?
    public let isOutdoor: Bool

    public init(id: RoomID,
                name: String,
                subtitle: String,
                floor: (r: Double, g: Double, b: Double),
                doorways: [Doorway],
                npc: NPCID? = nil,
                isOutdoor: Bool = false) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.floor = floor
        self.doorways = doorways
        self.npc = npc
        self.isOutdoor = isOutdoor
    }
}

/// The palace floor plan. Courtyard is the hub you start in; its doors open onto
/// the Great Hall, Chapel, and Gardens. The Kitchens and Privy Chamber sit one
/// step deeper, off the Great Hall. The camera faces north, so every room's
/// north wall is solid (it carries the set piece); doors are on E/W/S only.
public enum RoomCatalog {
    public static let all: [RoomID: RoomDefinition] = {
        let defs: [RoomDefinition] = [
            RoomDefinition(
                id: .courtyard, name: "Courtyard", subtitle: "The heart of the palace",
                floor: (0.56, 0.55, 0.50),
                doorways: [Doorway(.south, to: .greatHall), Doorway(.east, to: .chapel), Doorway(.west, to: .gardens)],
                npc: nil, isOutdoor: true
            ),
            RoomDefinition(
                id: .greatHall, name: "Great Hall", subtitle: "A rival courtier · gossiping ladies",
                floor: (0.84, 0.80, 0.71),
                doorways: [Doorway(.south, to: .courtyard), Doorway(.east, to: .privyChamber), Doorway(.west, to: .kitchens)],
                npc: .rivalCourtier
            ),
            RoomDefinition(
                id: .privyChamber, name: "Privy Chamber", subtitle: "Cromwell · the King",
                floor: (0.93, 0.84, 0.62),
                doorways: [Doorway(.west, to: .greatHall)],
                npc: .cromwell
            ),
            RoomDefinition(
                id: .chapel, name: "Chapel", subtitle: "The priest · Piety",
                floor: (0.70, 0.72, 0.66),
                doorways: [Doorway(.west, to: .courtyard), Doorway(.south, to: .tower, locked: true)],
                npc: .priest
            ),
            RoomDefinition(
                id: .kitchens, name: "Kitchens", subtitle: "The servant-spy",
                floor: (0.72, 0.66, 0.58),
                doorways: [Doorway(.east, to: .greatHall)],
                npc: .servantSpy
            ),
            RoomDefinition(
                id: .gardens, name: "Gardens", subtitle: "A lady-in-waiting",
                floor: (0.55, 0.64, 0.49),
                doorways: [Doorway(.east, to: .courtyard), Doorway(.south, to: .tower, locked: true)],
                npc: .ladyInWaiting, isOutdoor: true
            ),
            RoomDefinition(
                id: .tower, name: "The Tower", subtitle: "Fail state",
                floor: (0.52, 0.20, 0.20),
                doorways: [Doorway(.south, to: .chapel, locked: true), Doorway(.west, to: .gardens, locked: true)],
                npc: nil
            ),
        ]
        return Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })
    }()

    public static func room(_ id: RoomID) -> RoomDefinition {
        guard let def = all[id] else { fatalError("Missing room definition for \(id)") }
        return def
    }

    /// The doorway in `room` that leads back to `origin`, if any.
    public static func doorway(in room: RoomID, leadingTo origin: RoomID) -> Doorway? {
        return all[room]?.doorways.first { $0.destination == origin }
    }
}
