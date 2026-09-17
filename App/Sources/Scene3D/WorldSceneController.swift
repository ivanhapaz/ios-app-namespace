import SceneKit
import UIKit

/// Builds and drives the 3D world for the walkable spike: a Tudor courtyard you
/// explore in third-person. Everything is placeholder primitives (boxes,
/// capsules, cones) so it runs with zero art assets — we replace these with
/// real models in later art passes.
///
/// It doubles as the SceneKit render delegate: each frame it reads the shared
/// `MovementInput`, walks the player, turns them to face travel, and glides the
/// follow-camera behind them.
final class WorldSceneController: NSObject, SCNSceneRendererDelegate {

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private let player = SCNNode()
    private let lookTarget = SCNNode()   // camera aims here (player's chest, not feet)
    private let input: MovementInput
    private weak var game: GameState?

    private var npcs: [(id: NPCID, node: SCNNode)] = []
    private var lastNearby: NPCID?
    private let interactRadius: Float = 3.0

    private var lastTime: TimeInterval = 0

    // MARK: Tunables
    private let speed: Float = 6.0                       // metres / second
    private let bounds: Float = 22                       // courtyard half-extent (movement clamp)
    private let camDistance: Float = 8.0                 // how far behind the player the camera sits
    private let camHeight: Float = 4.2                   // camera height (lower = more over-the-shoulder)
    private let camLerp: Float = 0.12                    // camera smoothing (0..1 per frame)

    // Shared placeholder palette (muted Tudor tones).
    private static let plaster = UIColor(red: 0.90, green: 0.86, blue: 0.78, alpha: 1)
    private static let timber = UIColor(red: 0.34, green: 0.22, blue: 0.15, alpha: 1)
    private static let chapelRoof = UIColor(red: 0.32, green: 0.16, blue: 0.16, alpha: 1)

    init(input: MovementInput, game: GameState? = nil) {
        self.input = input
        self.game = game
        super.init()
        buildWorld()
    }

    // MARK: World construction

    private func buildWorld() {
        scene.background.contents = Self.skyImage()
        // Distance fog to fake atmospheric depth for free.
        scene.fogColor = UIColor(red: 0.82, green: 0.86, blue: 0.90, alpha: 1)
        scene.fogStartDistance = 40
        scene.fogEndDistance = 115

        buildGround()
        buildLighting()
        buildCourtyard()
        buildTrees()
        buildNPC()
        buildPlayer()
        buildCamera()
    }

    private func buildGround() {
        let floor = SCNFloor()
        floor.reflectivity = 0
        let mat = floor.firstMaterial
        mat?.diffuse.contents = Self.cobbleImage()
        mat?.diffuse.wrapS = .repeat
        mat?.diffuse.wrapT = .repeat
        mat?.diffuse.contentsTransform = SCNMatrix4MakeScale(24, 24, 0) // tile the cobbles
        let node = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(node)
    }

    private func buildLighting() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.58, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(red: 1.0, green: 0.97, blue: 0.90, alpha: 1) // warm afternoon
        sun.light?.intensity = 1150
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowColor = UIColor(white: 0, alpha: 0.35)
        sun.eulerAngles = SCNVector3(x: -Float.pi / 3, y: Float.pi / 4, z: 0)
        scene.rootNode.addChildNode(sun)
    }

    /// A ring of half-timbered buildings enclosing an open courtyard, with a
    /// taller "chapel" at the far end to anchor the Tudor theme.
    private func buildCourtyard() {
        // Far end (chapel + flanking houses)
        addBuilding(at: SCNVector3(x: 0, y: 0, z: -19), size: SCNVector3(x: 11, y: 9, z: 6), isChapel: true)
        addBuilding(at: SCNVector3(x: -13, y: 0, z: -18), size: SCNVector3(x: 6, y: 5, z: 5))
        addBuilding(at: SCNVector3(x: 13, y: 0, z: -18), size: SCNVector3(x: 6, y: 5, z: 5))
        // Sides
        addBuilding(at: SCNVector3(x: -19, y: 0, z: -3), size: SCNVector3(x: 5, y: 5, z: 11))
        addBuilding(at: SCNVector3(x: 19, y: 0, z: -3), size: SCNVector3(x: 5, y: 5, z: 11))
        // Near corners
        addBuilding(at: SCNVector3(x: -17, y: 0, z: 15), size: SCNVector3(x: 6, y: 4, z: 6))
        addBuilding(at: SCNVector3(x: 17, y: 0, z: 15), size: SCNVector3(x: 6, y: 4, z: 6))
    }

    private func addBuilding(at pos: SCNVector3, size: SCNVector3, isChapel: Bool = false) {
        let wall = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y),
                          length: CGFloat(size.z), chamferRadius: 0.12)
        wall.firstMaterial?.diffuse.contents = Self.plaster
        let node = SCNNode(geometry: wall)
        node.position = SCNVector3(x: pos.x, y: size.y / 2, z: pos.z)
        node.castsShadow = true

        // Timber-dark roof, slightly overhanging.
        let roof = SCNBox(width: CGFloat(size.x * 1.12), height: 0.6,
                          length: CGFloat(size.z * 1.12), chamferRadius: 0.1)
        roof.firstMaterial?.diffuse.contents = isChapel ? Self.chapelRoof : Self.timber
        let roofNode = SCNNode(geometry: roof)
        roofNode.position = SCNVector3(x: 0, y: size.y / 2 + 0.3, z: 0)
        node.addChildNode(roofNode)

        // Half-timber beams on the courtyard-facing (+Z) face: two uprights and
        // a mid-rail. Classic Tudor look, made of thin dark boxes.
        let faceZ = size.z / 2 + 0.04
        addBeam(to: node, size: SCNVector3(x: 0.35, y: size.y, z: 0.1),
                at: SCNVector3(x: -size.x / 2 + 0.6, y: 0, z: faceZ))
        addBeam(to: node, size: SCNVector3(x: 0.35, y: size.y, z: 0.1),
                at: SCNVector3(x: size.x / 2 - 0.6, y: 0, z: faceZ))
        addBeam(to: node, size: SCNVector3(x: size.x, y: 0.35, z: 0.1),
                at: SCNVector3(x: 0, y: size.y * 0.12, z: faceZ))

        // A single dark doorway on the +Z side.
        let door = SCNBox(width: 1.6, height: 2.6, length: 0.2, chamferRadius: 0.05)
        door.firstMaterial?.diffuse.contents = UIColor(red: 0.20, green: 0.13, blue: 0.08, alpha: 1)
        let doorNode = SCNNode(geometry: door)
        doorNode.position = SCNVector3(x: 0, y: 1.3 - size.y / 2, z: faceZ + 0.05)
        node.addChildNode(doorNode)

        if isChapel {
            // Bell tower + spire rising above the chapel to read as a church.
            let tower = SCNBox(width: 2.4, height: 4.5, length: 2.4, chamferRadius: 0.1)
            tower.firstMaterial?.diffuse.contents = Self.plaster
            let towerNode = SCNNode(geometry: tower)
            towerNode.position = SCNVector3(x: 0, y: size.y / 2 + 2.4, z: 0)
            towerNode.castsShadow = true
            node.addChildNode(towerNode)

            let spire = SCNCone(topRadius: 0, bottomRadius: 1.8, height: 3.2)
            spire.firstMaterial?.diffuse.contents = Self.chapelRoof
            let spireNode = SCNNode(geometry: spire)
            spireNode.position = SCNVector3(x: 0, y: 3.8, z: 0)
            towerNode.addChildNode(spireNode)
        }

        scene.rootNode.addChildNode(node)
    }

    private func addBeam(to parent: SCNNode, size: SCNVector3, at position: SCNVector3) {
        let beam = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y),
                          length: CGFloat(size.z), chamferRadius: 0.02)
        beam.firstMaterial?.diffuse.contents = Self.timber
        let n = SCNNode(geometry: beam)
        n.position = position
        parent.addChildNode(n)
    }

    private func buildTrees() {
        for p in [SCNVector3(x: -8, y: 0, z: -2), SCNVector3(x: 9, y: 0, z: -5),
                  SCNVector3(x: -6, y: 0, z: 9), SCNVector3(x: 10, y: 0, z: 8)] {
            addTree(at: p)
        }
    }

    private func addTree(at pos: SCNVector3) {
        let trunk = SCNCylinder(radius: 0.35, height: 3.2)
        trunk.firstMaterial?.diffuse.contents = UIColor(red: 0.40, green: 0.27, blue: 0.16, alpha: 1)
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(x: pos.x, y: 1.6, z: pos.z)
        trunkNode.castsShadow = true

        let foliage = SCNSphere(radius: 1.7)
        foliage.firstMaterial?.diffuse.contents = UIColor(red: 0.20, green: 0.44, blue: 0.22, alpha: 1)
        let foliageNode = SCNNode(geometry: foliage)
        foliageNode.position = SCNVector3(x: 0, y: 2.6, z: 0)
        foliageNode.castsShadow = true
        trunkNode.addChildNode(foliageNode)

        scene.rootNode.addChildNode(trunkNode)
    }

    private func buildNPC() {
        let npc = Self.makeCharacter(tunic: UIColor(red: 0.24, green: 0.20, blue: 0.30, alpha: 1)) // priest robe
        npc.position = SCNVector3(x: 5, y: 0, z: -8)
        npc.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0) // face the courtyard
        scene.rootNode.addChildNode(npc)
        npcs.append((id: .priest, node: npc))
    }

    private func buildPlayer() {
        let body = Self.makeCharacter(tunic: UIColor(red: 0.20, green: 0.24, blue: 0.42, alpha: 1)) // courtier blue
        player.addChildNode(body)
        player.position = SCNVector3(x: 0, y: 0, z: 12)
        scene.rootNode.addChildNode(player)

        lookTarget.position = SCNVector3(x: 0, y: 1.4, z: 0)
        player.addChildNode(lookTarget)
    }

    private func buildCamera() {
        let cam = SCNCamera()
        cam.zFar = 250
        cam.fieldOfView = 60
        cameraNode.camera = cam
        cameraNode.position = cameraTarget()
        let look = SCNLookAtConstraint(target: lookTarget)
        look.isGimbalLockEnabled = true
        cameraNode.constraints = [look]
        scene.rootNode.addChildNode(cameraNode)
    }

    /// Placeholder person: capsule body + sphere head + a gold "nose" cone that
    /// shows which way they're facing. Shared by the player and NPCs.
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
        noseNode.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0) // point the cone toward -Z (forward)
        root.addChildNode(noseNode)

        return root
    }

    // MARK: Per-frame update

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let dt = lastTime == 0 ? 0 : Float(min(time - lastTime, 1.0 / 30.0))
        lastTime = time

        let v = input.vector
        let magnitude = hypot(v.dx, v.dy)
        if magnitude > 0.05 {
            // Stick up (dy>0) drives into the scene (-Z); right (dx>0) drives +X.
            let vx = Float(v.dx) * speed
            let vz = Float(-v.dy) * speed

            var p = player.position
            p.x = clamp(p.x + vx * dt, -bounds, bounds)
            p.z = clamp(p.z + vz * dt, -bounds, bounds)
            player.position = p

            // Turn to face travel direction: node's -Z axis aligns with velocity.
            player.eulerAngles = SCNVector3(x: 0, y: atan2(-vx, -vz), z: 0)
        }

        // Glide the camera to sit behind the player, based on their facing, so
        // it swings around as they turn (third-person follow).
        cameraNode.position = lerp(cameraNode.position, cameraTarget(), camLerp)

        updateProximity()
    }

    /// Report the closest NPC within `interactRadius` to the game state, so the
    /// UI can offer an "Approach" prompt. Only publishes on change, and hops to
    /// the main thread since the render loop runs off-main.
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

    /// Desired camera position: `camDistance` behind the player's current facing
    /// and `camHeight` up. Behind = +(sin yaw, cos yaw) since the player's
    /// forward is the -Z axis rotated by yaw.
    private func cameraTarget() -> SCNVector3 {
        let yaw = player.eulerAngles.y
        return SCNVector3(x: player.position.x + sin(yaw) * camDistance,
                          y: camHeight,
                          z: player.position.z + cos(yaw) * camDistance)
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

    // MARK: Procedural textures (so we ship no image files)

    /// Vertical sky gradient used as the scene background.
    private static func skyImage() -> UIImage {
        let size = CGSize(width: 4, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [
                UIColor(red: 0.45, green: 0.62, blue: 0.82, alpha: 1).cgColor, // zenith blue
                UIColor(red: 0.86, green: 0.90, blue: 0.94, alpha: 1).cgColor  // pale horizon
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

    /// A small running-bond cobblestone tile, repeated across the floor.
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
