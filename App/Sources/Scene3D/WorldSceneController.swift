import SceneKit
import UIKit

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
    private var npcs: [(id: NPCID, node: SCNNode)] = []
    private var doorTriggers: [DoorTrigger] = []
    private var lastNearby: NPCID?
    private var isTransitioning = false

    // MARK: Tunables
    private let speed: Float = 6.0
    private let roomHalf: Float = 14          // half the room's side length
    private let wallHeight: Float = 6
    private let wallThick: Float = 0.6
    private let doorGap: Float = 4.5          // width of a doorway opening
    private let triggerDepth: Float = 2.6     // how far into the room a doorway trigger reaches
    private let clampMargin: Float = 0.9      // keep the player just inside the walls
    private let interactRadius: Float = 3.0
    private let camDistance: Float = 8.0
    private let camHeight: Float = 4.2
    private let camLerp: Float = 0.12

    // MARK: Palette (muted Tudor tones)
    private static let plaster = UIColor(red: 0.90, green: 0.86, blue: 0.78, alpha: 1)
    private static let timber = UIColor(red: 0.34, green: 0.22, blue: 0.15, alpha: 1)
    private static let chapelRoof = UIColor(red: 0.32, green: 0.16, blue: 0.16, alpha: 1)

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

        // Lighting.
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.62, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(red: 1.0, green: 0.97, blue: 0.90, alpha: 1)
        sun.light?.intensity = 1150
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowColor = UIColor(white: 0, alpha: 0.35)
        sun.eulerAngles = SCNVector3(x: -Float.pi / 3, y: Float.pi / 4, z: 0)
        scene.rootNode.addChildNode(sun)

        scene.rootNode.addChildNode(roomNode)

        // Player (persists; only the room around them changes).
        let body = Self.makeCharacter(tunic: UIColor(red: 0.20, green: 0.24, blue: 0.42, alpha: 1))
        player.addChildNode(body)
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
            buildWall(on: edge, doorway: def.doorways.first { $0.edge == edge })
        }
        buildRoomNPC(def)

        // Place the player at the doorway they arrived through (facing into the
        // room), else near the "south" of the room facing in.
        player.position = entryPosition(from: origin)
        player.eulerAngles = SCNVector3(x: 0, y: entryFacing(from: origin), z: 0)
        lastNearby = nil
        snapCameraBehindPlayer()

        // Publish room + a soft objective to the HUD.
        let name = def.name
        DispatchQueue.main.async { [weak self] in
            self?.game?.roomName = name
            self?.game?.nearby = nil
            self?.game?.objective = Self.objective(in: id)
        }
    }

    private func buildFloor(_ def: RoomDefinition) {
        let floor = SCNBox(width: CGFloat(roomHalf * 2), height: 0.2,
                           length: CGFloat(roomHalf * 2), chamferRadius: 0)
        let mat = floor.firstMaterial
        if def.isOutdoor {
            mat?.diffuse.contents = Self.cobbleImage()
            mat?.diffuse.wrapS = .repeat
            mat?.diffuse.wrapT = .repeat
            mat?.diffuse.contentsTransform = SCNMatrix4MakeScale(8, 8, 0)
        } else {
            mat?.diffuse.contents = UIColor(red: def.floor.r, green: def.floor.g,
                                            blue: def.floor.b, alpha: 1)
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

            if doorway.locked {
                addSealedDoor(on: edge)
            } else {
                doorTriggers.append(makeTrigger(on: edge, doorway: doorway))
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
        let label = Self.billboardLabel(RoomCatalog.room(destination).name)
        let edgePos = edgePosition(edge)
        let inward: Float = 0.6
        switch edge {
        case .north: label.position = SCNVector3(x: 0, y: 3.4, z: edgePos + inward)
        case .south: label.position = SCNVector3(x: 0, y: 3.4, z: edgePos - inward)
        case .east:  label.position = SCNVector3(x: edgePos - inward, y: 3.4, z: 0)
        case .west:  label.position = SCNVector3(x: edgePos + inward, y: 3.4, z: 0)
        }
        roomNode.addChildNode(label)
    }

    private func buildRoomNPC(_ def: RoomDefinition) {
        guard let npc = def.npc else { return }
        let tunic: UIColor
        switch npc {
        case .priest: tunic = UIColor(red: 0.24, green: 0.20, blue: 0.30, alpha: 1)
        case .rivalCourtier: tunic = UIColor(red: 0.45, green: 0.18, blue: 0.20, alpha: 1)
        case .servantSpy: tunic = UIColor(red: 0.35, green: 0.32, blue: 0.26, alpha: 1)
        case .ladyInWaiting: tunic = UIColor(red: 0.30, green: 0.42, blue: 0.48, alpha: 1)
        case .cromwell: tunic = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
        }
        let node = Self.makeCharacter(tunic: tunic)
        // Stand toward the back of the room, facing the centre.
        node.position = SCNVector3(x: 3, y: 0, z: -roomHalf * 0.45)
        node.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        roomNode.addChildNode(node)

        // A soft glowing ring so the interactable NPC reads clearly.
        let ring = SCNTorus(ringRadius: 1.1, pipeRadius: 0.06)
        ring.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.86, blue: 0.55, alpha: 0.9)
        ring.firstMaterial?.emission.contents = UIColor(red: 0.95, green: 0.86, blue: 0.55, alpha: 0.6)
        let ringNode = SCNNode(geometry: ring)
        ringNode.position = SCNVector3(x: 0, y: 0.05, z: 0)
        node.addChildNode(ringNode)

        npcs.append((id: npc, node: node))
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
            updateProximity()
        }
        cameraNode.position = lerp(cameraNode.position, cameraTarget(), camLerp)
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
        return SCNVector3(x: player.position.x + sin(yaw) * camDistance,
                          y: camHeight,
                          z: player.position.z + cos(yaw) * camDistance)
    }

    private func snapCameraBehindPlayer() {
        cameraNode.position = cameraTarget()
    }

    // MARK: Character factory

    static func makeCharacter(tunic: UIColor) -> SCNNode {
        let root = SCNNode()

        let body = SCNCapsule(capRadius: 0.36, height: 1.5)
        body.firstMaterial?.diffuse.contents = tunic
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(x: 0, y: 0.9, z: 0)
        bodyNode.castsShadow = true
        root.addChildNode(bodyNode)

        let head = SCNSphere(radius: 0.29)
        head.firstMaterial?.diffuse.contents = UIColor(red: 0.90, green: 0.75, blue: 0.62, alpha: 1)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(x: 0, y: 1.78, z: 0)
        headNode.castsShadow = true
        root.addChildNode(headNode)

        let nose = SCNCone(topRadius: 0, bottomRadius: 0.09, height: 0.22)
        nose.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.86, blue: 0.55, alpha: 1)
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(x: 0, y: 1.78, z: -0.30)
        noseNode.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
        root.addChildNode(noseNode)

        return root
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

    // MARK: Soft guidance copy

    private static func objective(in room: RoomID) -> String {
        switch room {
        case .courtyard: return "The courtyard connects every room. Pick a doorway."
        case .greatHall: return "A rival courtier eyes you. The King's chamber lies north."
        case .privyChamber: return "The King's inner sanctum. Mind Cromwell."
        case .chapel: return "The priest keeps count of your Piety."
        case .kitchens: return "A servant trades in whispers."
        case .gardens: return "A lady-in-waiting has secrets to share."
        case .tower: return "To the Tower."
        }
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
        node.constraints = [SCNBillboardConstraint()]
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
