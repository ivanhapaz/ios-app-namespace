import SceneKit
import UIKit
import GameCore

/// Builds and drives the 3D palace: one bounded room at a time, rebuilt when you
/// walk through a doorway. Rooms come from `RoomCatalog`, so the world is exactly
/// the floor plan — no aimless open space. Everything is placeholder primitives
/// (boxes, capsules, cones) so it runs with zero art assets.
///
/// Doubles as the SceneKit render delegate: each frame it reads the shared
/// `MovementInput`, walks the player (clamped to the room), turns them to face
/// travel, glides the follow-camera behind them, checks doorway triggers, and
/// reports NPC proximity to the `GameState`.
final class WorldSceneController: NSObject, SCNSceneRendererDelegate {

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private let player = SCNNode()
    private let lookTarget = SCNNode()
    private let input: MovementInput
    private weak var game: GameState?

    // MARK: Room state
    private var currentRoom: RoomID = .courtyard
    private var previousRoom: RoomID?
    private let roomNode = SCNNode()        // all room-specific geometry lives here
    private let ambientNode = SCNNode()     // per-room ambient (the lighting ladder)
    private let sunNode = SCNNode()         // per-room directional light
    private var npcs: [(id: NPCID, node: SCNNode)] = []
    private var doorTriggers: [DoorTrigger] = []
    private var lastNearby: NPCID?
    private var isTransitioning = false

    private var kingNode: SCNNode?
    private var lastSlot: TimeSlot?

    // Dev walkthrough "tour": deliberate room-by-room movement with establishing
    // pauses, so a viewer can follow where the courtier is and see each room.
    private let tourEnabled = false // dev walkthrough only; never on in shipped play
    private enum TourState { case begin, toViewpoint, viewing, toNPC, converse, toExit }
    private var tourState: TourState = .begin
    private var tourTimer: Double = 0

    // MARK: Tunables
    private let speed: Float = 6.0
    private let roomHalf: Float = 14          // half the room's side length
    private let wallHeight: Float = 6
    private let wallThick: Float = 0.6
    private let doorGap: Float = 4.5          // width of a doorway opening
    private let doorHeight: Float = 2.9       // opening height (above it is a lintel, not sky)
    private let triggerDepth: Float = 2.6     // how far into the room a doorway trigger reaches
    private let clampMargin: Float = 0.9      // keep the player just inside the walls
    private let interactRadius: Float = 3.0
    private let camDistance: Float = 8.0
    private let camHeight: Float = 4.2
    private let camLerp: Float = 0.12

    // MARK: 3D material palette (from the design handoff)
    private static let stoneWall = UIColor(hex: 0xA79C85)
    private static let woodFloor = UIColor(hex: 0x8A6238)
    private static let chapelStone = UIColor(hex: 0xCFC6AE)
    private static let gardenGreen = UIColor(hex: 0x55703F)
    private static let royalCrimson = UIColor(hex: 0xA6301F)
    private static let goldTrim = UIColor(hex: 0xC9A227)
    private static let towerStone = UIColor(hex: 0x6B2E3E)
    // Walls share the stone-wall tone across rooms.
    private static let plaster = UIColor(hex: 0xA79C85)

    /// A doorway resolved into scene geometry: a walkable trigger zone (in the
    /// XZ plane) and where to drop the player when they enter via this edge.
    private struct DoorTrigger {
        let doorway: Doorway
        let centerX: Float
        let centerZ: Float
        let halfX: Float
        let halfZ: Float
    }

    init(input: MovementInput, game: GameState? = nil) {
        self.input = input
        self.game = game
        super.init()
        buildStaticScene()
        loadRoom(.courtyard, from: nil)
    }

    // MARK: Static (persists across rooms)

    private func buildStaticScene() {
        scene.background.contents = Self.skyImage()
        scene.fogColor = UIColor(red: 0.82, green: 0.86, blue: 0.90, alpha: 1)
        scene.fogStartDistance = 30
        scene.fogEndDistance = 90

        // Lighting: base nodes configured once; intensities/tints per room
        // are set by applyLighting(for:) — the "lighting ladder".
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        scene.rootNode.addChildNode(ambientNode)

        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        sunNode.light?.castsShadow = true
        sunNode.light?.shadowMode = .deferred
        sunNode.light?.shadowColor = UIColor(white: 0, alpha: 0.35)
        sunNode.eulerAngles = SCNVector3(x: -Float.pi / 3, y: Float.pi / 4, z: 0)
        scene.rootNode.addChildNode(sunNode)

        scene.rootNode.addChildNode(roomNode)

        // Player (persists; only the room around them changes).
        player.addChildNode(CharacterKit.makePlayer())
        scene.rootNode.addChildNode(player)
        lookTarget.position = SCNVector3(x: 0, y: 1.4, z: 0)
        player.addChildNode(lookTarget)

        // Camera.
        let cam = SCNCamera()
        cam.zFar = 250
        cam.fieldOfView = 60
        cameraNode.camera = cam
        let look = SCNLookAtConstraint(target: lookTarget)
        look.isGimbalLockEnabled = true
        cameraNode.constraints = [look]
        scene.rootNode.addChildNode(cameraNode)
    }

    // MARK: Room loading

    private func loadRoom(_ id: RoomID, from origin: RoomID?) {
        currentRoom = id
        previousRoom = origin

        roomNode.childNodes.forEach { $0.removeFromParentNode() }
        npcs.removeAll()
        doorTriggers.removeAll()

        let def = RoomCatalog.room(id)
        buildFloor(def)
        for edge in [Edge.north, .south, .east, .west] {
            // Outdoor rooms open to the sky at the north — facades/perimeter
            // (added by RoomDressing) form the backdrop instead of a wall.
            if edge == .north && def.isOutdoor { continue }
            buildWall(on: edge, doorway: def.doorways.first { $0.edge == edge })
        }
        if !def.isOutdoor {
            // A timber ceiling so interiors feel enclosed (no sky overhead).
            let ceiling = SCNBox(width: CGFloat(roomHalf * 2), height: 0.3,
                                 length: CGFloat(roomHalf * 2), chamferRadius: 0)
            ceiling.firstMaterial?.diffuse.contents = UIColor(hex: 0x3B2E20)
            let node = SCNNode(geometry: ceiling)
            node.position = SCNVector3(x: 0, y: wallHeight + 0.15, z: 0)
            roomNode.addChildNode(node)
        }
        buildRoomNPC(def)
        roomNode.addChildNode(RoomDressing.dress(id))
        applyLighting(for: id)
        kingNode = nil
        lastSlot = game?.slot
        addKingIfNeeded()

        // Place the player at the doorway they arrived through (facing into the
        // room), else near the "south" of the room facing in.
        player.position = entryPosition(from: origin)
        player.eulerAngles = SCNVector3(x: 0, y: entryFacing(from: origin), z: 0)
        lastNearby = nil
        snapCameraBehindPlayer()

        // Restart the tour's per-room sequence in the new room.
        tourState = .toViewpoint
        tourTimer = 0

        // Publish room + a soft objective to the HUD.
        let name = def.name
        DispatchQueue.main.async { [weak self] in
            self?.game?.roomName = name
            self?.game?.nearby = nil
        }
    }

    /// The lighting ladder — each room is told apart by brightness/tint before
    /// its props even register. Extra lights (fires, chandelier) live in the set
    /// pieces; this sets the base ambient + directional per room.
    private func applyLighting(for room: RoomID) {
        let ambientTint: UIColor
        let ambientIntensity: CGFloat
        let sunIntensity: CGFloat
        var sunTint = UIColor(red: 1.0, green: 0.97, blue: 0.90, alpha: 1)

        switch room {
        case .gardens:
            ambientTint = UIColor(hex: 0xFFF6E0); ambientIntensity = 600; sunIntensity = 800
        case .courtyard:
            ambientTint = UIColor(hex: 0xFFF6E0); ambientIntensity = 500; sunIntensity = 750
        case .kitchens:
            ambientTint = UIColor(hex: 0x6E6353); ambientIntensity = 400; sunIntensity = 500
        case .greatHall:
            ambientTint = UIColor(hex: 0x6E6353); ambientIntensity = 300; sunIntensity = 700
        case .privyChamber:
            ambientTint = UIColor(hex: 0x6E6353); ambientIntensity = 300; sunIntensity = 600
        case .chapel:
            ambientTint = UIColor(hex: 0x6E6353); ambientIntensity = 200; sunIntensity = 500
            sunTint = UIColor(hex: 0xC9D6E8)
        case .tower:
            ambientTint = UIColor(hex: 0x3A3630); ambientIntensity = 120; sunIntensity = 0
        }

        ambientNode.light?.color = ambientTint
        ambientNode.light?.intensity = ambientIntensity
        sunNode.light?.color = sunTint
        sunNode.light?.intensity = sunIntensity
    }

    private func buildFloor(_ def: RoomDefinition) {
        let floor = SCNBox(width: CGFloat(roomHalf * 2), height: 0.2,
                           length: CGFloat(roomHalf * 2), chamferRadius: 0)
        let mat = floor.firstMaterial
        func tile(_ image: UIImage, repeats: Float) {
            mat?.diffuse.contents = image
            mat?.diffuse.wrapS = .repeat
            mat?.diffuse.wrapT = .repeat
            mat?.diffuse.contentsTransform = SCNMatrix4MakeScale(repeats, repeats, 0)
        }
        switch def.id {
        case .courtyard: tile(FloorTextures.cobble(), repeats: 28)
        case .chapel: tile(FloorTextures.flagstone(), repeats: 10)
        case .kitchens: tile(FloorTextures.kitchenStone(), repeats: 10)
        case .greatHall, .privyChamber: tile(FloorTextures.plank(), repeats: 14)
        case .gardens: mat?.diffuse.contents = Palette.gardenGreen
        case .tower: mat?.diffuse.contents = UIColor(hex: 0x6E675C)
        }
        let node = SCNNode(geometry: floor)
        node.position = SCNVector3(x: 0, y: -0.1, z: 0)
        roomNode.addChildNode(node)
    }

    /// Build a wall on `edge`. If there's a doorway, leave a gap (and register a
    /// trigger for open ones, or a sealed slab + lock for locked ones).
    private func buildWall(on edge: Edge, doorway: Doorway?) {
        let horizontal = (edge == .north || edge == .south)
        let edgePos = edgePosition(edge)

        if let doorway = doorway {
            // Two wall segments flanking the gap.
            let segLength = roomHalf - doorGap / 2
            let offset = roomHalf - segLength / 2 // centre of each flanking segment
            addWallSegment(horizontal: horizontal, edgePos: edgePos, along: -offset, length: segLength)
            addWallSegment(horizontal: horizontal, edgePos: edgePos, along: offset, length: segLength)
            addLintel(on: edge) // cap the opening so it's a door, not a full-height gap

            if doorway.locked {
                addSealedDoor(on: edge)
            } else {
                doorTriggers.append(makeTrigger(on: edge, doorway: doorway))
                addDoorBackdrop(on: edge)  // a shadowy "beyond" so you don't see sky through the door
                addDoorwaySign(on: edge, destination: doorway.destination)
            }
        } else {
            addWallSegment(horizontal: horizontal, edgePos: edgePos, along: 0, length: roomHalf * 2)
        }
    }

    /// Add one wall box. `horizontal` walls run along X (north/south);
    /// otherwise they run along Z (east/west). `along` is the offset of the
    /// segment centre along the wall's run; `edgePos` is the fixed coordinate.
    private func addWallSegment(horizontal: Bool, edgePos: Float, along: Float, length: Float) {
        let box: SCNBox
        let position: SCNVector3
        if horizontal {
            box = SCNBox(width: CGFloat(length), height: CGFloat(wallHeight),
                         length: CGFloat(wallThick), chamferRadius: 0.05)
            position = SCNVector3(x: along, y: wallHeight / 2, z: edgePos)
        } else {
            box = SCNBox(width: CGFloat(wallThick), height: CGFloat(wallHeight),
                         length: CGFloat(length), chamferRadius: 0.05)
            position = SCNVector3(x: edgePos, y: wallHeight / 2, z: along)
        }
        box.firstMaterial?.diffuse.contents = Self.plaster
        let node = SCNNode(geometry: box)
        node.position = position
        node.castsShadow = true
        roomNode.addChildNode(node)
    }

    /// Fill the gap above the door opening so you don't see sky through the top.
    private func addLintel(on edge: Edge) {
        let horizontal = (edge == .north || edge == .south)
        let edgePos = edgePosition(edge)
        let h = wallHeight - doorHeight
        let midY = doorHeight + h / 2
        let box: SCNBox
        let pos: SCNVector3
        if horizontal {
            box = SCNBox(width: CGFloat(doorGap), height: CGFloat(h), length: CGFloat(wallThick), chamferRadius: 0.05)
            pos = SCNVector3(x: 0, y: midY, z: edgePos)
        } else {
            box = SCNBox(width: CGFloat(wallThick), height: CGFloat(h), length: CGFloat(doorGap), chamferRadius: 0.05)
            pos = SCNVector3(x: edgePos, y: midY, z: 0)
        }
        box.firstMaterial?.diffuse.contents = Self.plaster
        let node = SCNNode(geometry: box)
        node.position = pos
        node.castsShadow = true
        roomNode.addChildNode(node)
    }

    /// A dark panel just outside an open doorway — reads as a shadowed passage
    /// beyond, rather than open sky.
    private func addDoorBackdrop(on edge: Edge) {
        let dark = UIColor(hex: 0x18160F)
        let out: Float = 0.7
        let box: SCNBox
        let pos: SCNVector3
        switch edge {
        case .north:
            box = SCNBox(width: CGFloat(doorGap + 0.6), height: CGFloat(doorHeight + 0.4), length: 0.3, chamferRadius: 0)
            pos = SCNVector3(x: 0, y: doorHeight / 2, z: -roomHalf - out)
        case .south:
            box = SCNBox(width: CGFloat(doorGap + 0.6), height: CGFloat(doorHeight + 0.4), length: 0.3, chamferRadius: 0)
            pos = SCNVector3(x: 0, y: doorHeight / 2, z: roomHalf + out)
        case .east:
            box = SCNBox(width: 0.3, height: CGFloat(doorHeight + 0.4), length: CGFloat(doorGap + 0.6), chamferRadius: 0)
            pos = SCNVector3(x: roomHalf + out, y: doorHeight / 2, z: 0)
        case .west:
            box = SCNBox(width: 0.3, height: CGFloat(doorHeight + 0.4), length: CGFloat(doorGap + 0.6), chamferRadius: 0)
            pos = SCNVector3(x: -roomHalf - out, y: doorHeight / 2, z: 0)
        }
        box.firstMaterial?.diffuse.contents = dark
        let node = SCNNode(geometry: box)
        node.position = pos
        roomNode.addChildNode(node)
    }

    private func addSealedDoor(on edge: Edge) {
        let horizontal = (edge == .north || edge == .south)
        let edgePos = edgePosition(edge)
        let slab: SCNBox
        let pos: SCNVector3
        if horizontal {
            slab = SCNBox(width: CGFloat(doorGap), height: CGFloat(wallHeight * 0.8),
                          length: CGFloat(wallThick + 0.1), chamferRadius: 0.05)
            pos = SCNVector3(x: 0, y: wallHeight * 0.4, z: edgePos)
        } else {
            slab = SCNBox(width: CGFloat(wallThick + 0.1), height: CGFloat(wallHeight * 0.8),
                          length: CGFloat(doorGap), chamferRadius: 0.05)
            pos = SCNVector3(x: edgePos, y: wallHeight * 0.4, z: 0)
        }
        slab.firstMaterial?.diffuse.contents = UIColor(red: 0.30, green: 0.30, blue: 0.33, alpha: 1)
        let node = SCNNode(geometry: slab)
        node.position = pos
        roomNode.addChildNode(node)

        if let lock = Self.symbolNode("lock.fill", pointSize: 26, color: UIColor(white: 0.85, alpha: 1)) {
            lock.constraints = [SCNBillboardConstraint()]
            lock.position = SCNVector3(x: pos.x, y: 2.4, z: pos.z)
            roomNode.addChildNode(lock)
        }
    }

    private func addDoorwaySign(on edge: Edge, destination: RoomID) {
        let label = Self.signText(RoomCatalog.room(destination).name)
        let signY: Float = doorHeight + 0.55 // sits on the lintel above the opening
        let inset: Float = 0.14
        switch edge {
        case .north:
            label.position = SCNVector3(x: 0, y: signY, z: -roomHalf + inset)
            label.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        case .south:
            label.position = SCNVector3(x: 0, y: signY, z: roomHalf - inset)
            label.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        case .east:
            label.position = SCNVector3(x: roomHalf - inset, y: signY, z: 0)
            label.eulerAngles = SCNVector3(x: 0, y: -Float.pi / 2, z: 0)
        case .west:
            label.position = SCNVector3(x: -roomHalf + inset, y: signY, z: 0)
            label.eulerAngles = SCNVector3(x: 0, y: Float.pi / 2, z: 0)
        }
        roomNode.addChildNode(label)
    }

    private func buildRoomNPC(_ def: RoomDefinition) {
        guard let npc = def.npc else { return }
        let node = CharacterKit.character(for: npc)
        // Stand toward the back of the room, facing the centre.
        node.position = SCNVector3(x: 3, y: 0, z: -roomHalf * 0.45)
        node.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        node.addChildNode(Self.glowRing())
        roomNode.addChildNode(node)

        npcs.append((id: npc, node: node))
    }

    // MARK: The King (moves on a schedule)

    /// Add the crowned King to the current room if his schedule places him here.
    private func addKingIfNeeded() {
        guard let slot = game?.slot, slot.kingRoom == currentRoom else { return }
        let king = CharacterKit.makeKing()
        king.position = SCNVector3(x: -3.5, y: 0, z: -roomHalf * 0.4)
        king.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        king.addChildNode(Self.glowRing())
        roomNode.addChildNode(king)
        npcs.append((id: .king, node: king))
        kingNode = king
    }

    private func removeKing() {
        kingNode?.removeFromParentNode()
        kingNode = nil
        npcs.removeAll { $0.id == .king }
    }

    /// A soft gold ring under an interactable character.
    static func glowRing() -> SCNNode {
        let ring = SCNTorus(ringRadius: 1.1, pipeRadius: 0.06)
        ring.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.86, blue: 0.55, alpha: 0.9)
        ring.firstMaterial?.emission.contents = UIColor(red: 0.95, green: 0.86, blue: 0.55, alpha: 0.6)
        let node = SCNNode(geometry: ring)
        node.position = SCNVector3(x: 0, y: 0.05, z: 0)
        return node
    }

    // MARK: Geometry helpers

    private func edgePosition(_ edge: Edge) -> Float {
        switch edge {
        case .north: return -roomHalf
        case .south: return roomHalf
        case .east: return roomHalf
        case .west: return -roomHalf
        }
    }

    private func makeTrigger(on edge: Edge, doorway: Doorway) -> DoorTrigger {
        let near = roomHalf - triggerDepth / 2
        switch edge {
        case .north:
            return DoorTrigger(doorway: doorway, centerX: 0, centerZ: -near,
                               halfX: doorGap / 2, halfZ: triggerDepth / 2)
        case .south:
            return DoorTrigger(doorway: doorway, centerX: 0, centerZ: near,
                               halfX: doorGap / 2, halfZ: triggerDepth / 2)
        case .east:
            return DoorTrigger(doorway: doorway, centerX: near, centerZ: 0,
                               halfX: triggerDepth / 2, halfZ: doorGap / 2)
        case .west:
            return DoorTrigger(doorway: doorway, centerX: -near, centerZ: 0,
                               halfX: triggerDepth / 2, halfZ: doorGap / 2)
        }
    }

    /// Where to drop the player when entering `currentRoom` from `origin`:
    /// just inside the doorway that leads back to `origin`.
    private func entryPosition(from origin: RoomID?) -> SCNVector3 {
        let inset = triggerDepth + 1.8
        if let origin = origin,
           let back = RoomCatalog.doorway(in: currentRoom, leadingTo: origin) {
            switch back.edge {
            case .north: return SCNVector3(x: 0, y: 0, z: -roomHalf + inset)
            case .south: return SCNVector3(x: 0, y: 0, z: roomHalf - inset)
            case .east:  return SCNVector3(x: roomHalf - inset, y: 0, z: 0)
            case .west:  return SCNVector3(x: -roomHalf + inset, y: 0, z: 0)
            }
        }
        return SCNVector3(x: 0, y: 0, z: roomHalf * 0.4) // near the "south" of the room
    }

    /// Yaw so the player faces *into* the room from whichever doorway they used.
    private func entryFacing(from origin: RoomID?) -> Float {
        guard let origin = origin,
              let back = RoomCatalog.doorway(in: currentRoom, leadingTo: origin) else {
            return 0 // face -Z (into the room from the south)
        }
        switch back.edge {
        case .north: return Float.pi          // came from north wall → face +Z
        case .south: return 0                 // face -Z
        case .east:  return Float.pi / 2      // face -X
        case .west:  return -Float.pi / 2     // face +X
        }
    }

    // MARK: Per-frame update

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !isTransitioning {
            if tourEnabled { driveTour() }
            let v = input.vector
            let magnitude = hypot(v.dx, v.dy)
            if magnitude > 0.05 {
                let vx = Float(v.dx) * speed
                let vz = Float(-v.dy) * speed
                let bound = roomHalf - clampMargin
                var p = player.position
                p.x = clamp(p.x + vx / 60.0, -bound, bound)
                p.z = clamp(p.z + vz / 60.0, -bound, bound)
                player.position = p
                player.eulerAngles = SCNVector3(x: 0, y: atan2(-vx, -vz), z: 0)
                checkDoorways()
            }

            // If the clock advanced, the King may have entered or left this room.
            if let slot = game?.slot, slot != lastSlot {
                lastSlot = slot
                removeKing()
                addKingIfNeeded()
            }

            updateProximity()
        }
        cameraNode.position = lerp(cameraNode.position, cameraTarget(), camLerp)
    }

    // MARK: Walkthrough tour (dev)

    /// Drives `input.vector` and dilemma choices to play a legible tour: walk to
    /// a south viewpoint and pause facing the room (camera frames the set
    /// piece), approach the resident, converse, then leave through a doorway.
    private func driveTour() {
        guard let game = game else { return }
        tourTimer += 1.0 / 60.0

        // Global phases / modals first.
        if game.phase == .title {
            input.vector = .zero
            if tourTimer > 1.6 { mainAsync { game.begin() }; tourState = .toViewpoint; tourTimer = 0 }
            return
        }
        if game.phase == .gameOver {
            input.vector = .zero
            if tourTimer > 3.2 { mainAsync { game.restart() }; tourState = .toViewpoint; tourTimer = 0 }
            return
        }
        if game.activeEvent != nil {
            input.vector = .zero
            if tourTimer > 2.2 { mainAsync { game.dismissEvent() }; tourTimer = 0 }
            return
        }
        if game.activeDilemma != nil {
            input.vector = .zero
            if tourTimer > 2.6 {
                mainAsync {
                    if let d = game.activeDilemma { game.choose(d.choiceA) }
                    game.activeDilemma = nil
                }
                tourState = .toExit
                tourTimer = 0
            }
            return
        }

        switch tourState {
        case .begin:
            tourState = .toViewpoint; tourTimer = 0
        case .toViewpoint:
            if moveToward(0, 8) { tourState = .viewing; tourTimer = 0 }
        case .viewing:
            input.vector = .zero
            player.eulerAngles = SCNVector3(x: 0, y: 0, z: 0) // face the north set piece
            if tourTimer > 3.4 { tourState = npcs.isEmpty ? .toExit : .toNPC; tourTimer = 0 }
        case .toNPC:
            if let npc = npcs.first {
                let p = npc.node.position
                if moveToward(p.x, p.z + 2.3) { openTourDilemma(); tourState = .converse; tourTimer = 0 }
            } else {
                tourState = .toExit; tourTimer = 0
            }
        case .converse:
            input.vector = .zero
            if game.activeDilemma == nil && tourTimer > 1.6 { tourState = .toExit; tourTimer = 0 }
        case .toExit:
            let target = tourExitTarget()
            _ = moveToward(target.0, target.1) // a doorway transition fires on arrival
        }
    }

    private func moveToward(_ tx: Float, _ tz: Float) -> Bool {
        let dx = tx - player.position.x
        let dz = tz - player.position.z
        let dist = hypot(dx, dz)
        if dist < 0.7 { input.vector = .zero; return true }
        input.vector = CGVector(dx: CGFloat(dx / dist), dy: CGFloat(-dz / dist))
        return false
    }

    private func tourExitTarget() -> (Float, Float) {
        let preferred = doorTriggers.first { $0.doorway.destination != previousRoom } ?? doorTriggers.first
        if let d = preferred { return (d.centerX, d.centerZ) }
        return (0, 8)
    }

    private func openTourDilemma() {
        guard let game = game, let npc = npcs.first?.id else { return }
        mainAsync { game.activeDilemma = DilemmaCatalog.dilemma(for: npc, holding: Set(game.inventory)) }
    }

    private func mainAsync(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    private func checkDoorways() {
        let p = player.position
        for trigger in doorTriggers {
            if abs(p.x - trigger.centerX) <= trigger.halfX,
               abs(p.z - trigger.centerZ) <= trigger.halfZ {
                beginTransition(to: trigger.doorway.destination)
                return
            }
        }
    }

    private func beginTransition(to destination: RoomID) {
        isTransitioning = true
        let origin = currentRoom
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.game?.fade = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                self.loadRoom(destination, from: origin)
                self.game?.fade = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isTransitioning = false
                }
            }
        }
    }

    private func updateProximity() {
        var found: NPCID?
        let p = player.position
        for entry in npcs {
            let dx = entry.node.position.x - p.x
            let dz = entry.node.position.z - p.z
            if (dx * dx + dz * dz) < interactRadius * interactRadius {
                found = entry.id
                break
            }
        }
        guard found != lastNearby else { return }
        lastNearby = found
        DispatchQueue.main.async { [weak self] in
            self?.game?.nearby = found
        }
    }

    private func cameraTarget() -> SCNVector3 {
        let yaw = player.eulerAngles.y
        // Keep the camera inside the walls so it never clips through them (which
        // would reveal doorway signs point-blank). Near a wall the view tightens.
        let limit = roomHalf - 0.7
        let x = clamp(player.position.x + sin(yaw) * camDistance, -limit, limit)
        let z = clamp(player.position.z + cos(yaw) * camDistance, -limit, limit)
        return SCNVector3(x: x, y: camHeight, z: z)
    }

    private func snapCameraBehindPlayer() {
        cameraNode.position = cameraTarget()
    }

    // MARK: Small math helpers

    private func clamp(_ x: Float, _ lo: Float, _ hi: Float) -> Float {
        return min(max(x, lo), hi)
    }

    private func lerp(_ a: SCNVector3, _ b: SCNVector3, _ t: Float) -> SCNVector3 {
        return SCNVector3(x: a.x + (b.x - a.x) * t,
                          y: a.y + (b.y - a.y) * t,
                          z: a.z + (b.z - a.z) * t)
    }

    // MARK: Procedural textures + labels (so we ship no image files)

    private static func billboardLabel(_ string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.05)
        text.font = UIFont(name: "Georgia-Bold", size: 1.2) ?? UIFont.boldSystemFont(ofSize: 1.2)
        text.flatness = 0.1
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.firstMaterial?.isDoubleSided = true

        let node = SCNNode(geometry: text)
        let (minB, maxB) = text.boundingBox
        node.pivot = SCNMatrix4MakeTranslation((minB.x + maxB.x) / 2,
                                               (minB.y + maxB.y) / 2, 0)
        node.scale = SCNVector3(x: 0.6, y: 0.6, z: 0.6)
        node.constraints = [SCNBillboardConstraint()]
        return node
    }

    /// A fixed (non-billboard) engraved doorway sign, mounted on the lintel.
    private static func signText(_ string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.04)
        text.font = UIFont(name: "Georgia-Bold", size: 1.2) ?? UIFont.boldSystemFont(ofSize: 1.2)
        text.flatness = 0.1
        text.firstMaterial?.diffuse.contents = UIColor(hex: 0x3A2E1A)
        text.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: text)
        let (minB, maxB) = text.boundingBox
        node.pivot = SCNMatrix4MakeTranslation((minB.x + maxB.x) / 2, (minB.y + maxB.y) / 2, 0)
        node.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        return node
    }

    private static func symbolNode(_ name: String, pointSize: CGFloat, color: UIColor) -> SCNNode? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        guard let image = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) else {
            return nil
        }
        let plane = SCNPlane(width: 1.0, height: 1.0)
        plane.firstMaterial?.diffuse.contents = image
        plane.firstMaterial?.isDoubleSided = true
        return SCNNode(geometry: plane)
    }

    private static func skyImage() -> UIImage {
        let size = CGSize(width: 4, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [
                UIColor(red: 0.45, green: 0.62, blue: 0.82, alpha: 1).cgColor,
                UIColor(red: 0.86, green: 0.90, blue: 0.94, alpha: 1).cgColor
            ] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: size.height),
                    options: []
                )
            }
        }
    }

    private static func cobbleImage() -> UIImage {
        let dimension: CGFloat = 256
        let size = CGSize(width: dimension, height: dimension)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let c = ctx.cgContext
            c.setFillColor(UIColor(red: 0.54, green: 0.52, blue: 0.48, alpha: 1).cgColor)
            c.fill(CGRect(origin: .zero, size: size))
            c.setStrokeColor(UIColor(red: 0.38, green: 0.37, blue: 0.34, alpha: 1).cgColor)
            c.setLineWidth(3)
            let tile = dimension / 4
            for row in 0..<4 {
                let y = CGFloat(row) * tile
                let offset = (row % 2 == 0) ? 0 : tile / 2
                var x = offset - tile
                while x < dimension {
                    c.stroke(CGRect(x: x, y: y, width: tile, height: tile))
                    x += tile
                }
            }
        }
    }
}
