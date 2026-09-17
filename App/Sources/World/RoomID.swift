import CoreGraphics

/// The six rooms of the palace. The `Tower` is the fail-state room the player
/// never walks into by choice — the game relocates them there on a loss.
enum RoomID: String, CaseIterable, Codable {
    case courtyard
    case greatHall
    case privyChamber
    case chapel
    case kitchens
    case gardens
    case tower
}

/// A wall of a room. Doorways live on edges, and the "opposite" helper lets us
/// place the player at the reciprocal doorway when they enter a new room.
enum Edge {
    case north
    case south
    case east
    case west

    var opposite: Edge {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        }
    }
}

/// A passage from one room to another, sitting on a given wall.
///
/// `locked` doorways are the story-only passages from the Chapel and Gardens
/// toward the Tower. In Phase 1 they render as sealed and cannot be walked
/// through; later phases open them programmatically (e.g. on a loss).
struct Doorway {
    let edge: Edge
    let destination: RoomID
    let locked: Bool

    init(_ edge: Edge, to destination: RoomID, locked: Bool = false) {
        self.edge = edge
        self.destination = destination
        self.locked = locked
    }
}

/// Static description of a room: how it reads and where its doorways are.
/// Content (residents, dilemmas) will be layered on in later phases; for now we
/// only need the label, floor colour, and connections.
struct RoomDefinition {
    let id: RoomID
    let name: String
    /// Short resident/flavour line shown under the title.
    let subtitle: String
    /// Muted Tudor floor tone, as RGB in 0...1.
    let floor: (r: CGFloat, g: CGFloat, b: CGFloat)
    let doorways: [Doorway]
    /// The NPC who lives here, if any (the courtyard hub has none).
    let npc: NPCID?
    /// Outdoor rooms (the courtyard) use cobbles + open sky; indoor rooms use
    /// plaster walls and a warmer interior tone.
    let isOutdoor: Bool

    init(id: RoomID,
         name: String,
         subtitle: String,
         floor: (r: CGFloat, g: CGFloat, b: CGFloat),
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
