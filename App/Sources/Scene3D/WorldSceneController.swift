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

    private var lastTime: TimeInterval = 0

    // MARK: Tunables
    private let speed: Float = 6.0                       // metres / second
    private let bounds: Float = 22                       // courtyard half-extent (movement clamp)
    private let camOffset = SCNVector3(x: 0, y: 9, z: 13) // third-person camera offset
    private let camLerp: Float = 0.12                    // camera smoothing (0..1 per frame)

    init(input: MovementInput) {
        self.input = input
        super.init()
        buildWorld()
    }

    // MARK: World construction

    private func buildWorld() {
        scene.background.contents = UIColor(red: 0.53, green: 0.68, blue: 0.82, alpha: 1) // sky
        // Distance fog to fake atmospheric depth for free.
        scene.fogColor = UIColor(red: 0.72, green: 0.80, blue: 0.87, alpha: 1)
        scene.fogStartDistance = 35
        scene.fogEndDistance = 95

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
        floor.firstMaterial?.diffuse.contents = UIColor(red: 0.56, green: 0.55, blue: 0.50, alpha: 1) // cobble
        let node = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(node)
    }

    private func buildLighting() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.55, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(white: 0.95, alpha: 1)
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
                          length: CGFloat(size.z), chamferRadius: 0.15)
        wall.firstMaterial?.diffuse.contents = UIColor(red: 0.90, green: 0.86, blue: 0.78, alpha: 1) // plaster
        let node = SCNNode(geometry: wall)
        node.position = SCNVector3(x: pos.x, y: size.y / 2, z: pos.z)
        node.castsShadow = true

        // Timber-dark roof, slightly overhanging.
        let roof = SCNBox(width: CGFloat(size.x * 1.12), height: 0.6,
                          length: CGFloat(size.z * 1.12), chamferRadius: 0.1)
        roof.firstMaterial?.diffuse.contents = isChapel
            ? UIColor(red: 0.30, green: 0.16, blue: 0.16, alpha: 1)   // deep chapel red-brown
            : UIColor(red: 0.34, green: 0.22, blue: 0.15, alpha: 1)   // timber
        let roofNode = SCNNode(geometry: roof)
        roofNode.position = SCNVector3(x: 0, y: size.y / 2 + 0.3, z: 0)
        node.addChildNode(roofNode)

        // A single dark doorway on the courtyard-facing side (+Z), for flavour.
        let door = SCNBox(width: 1.6, height: 2.6, length: 0.2, chamferRadius: 0.05)
        door.firstMaterial?.diffuse.contents = UIColor(red: 0.20, green: 0.13, blue: 0.08, alpha: 1)
        let doorNode = SCNNode(geometry: door)
        doorNode.position = SCNVector3(x: 0, y: 1.3 - size.y / 2, z: size.z / 2 + 0.05)
        node.addChildNode(doorNode)

        scene.rootNode.addChildNode(node)
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
    }

    private func buildPlayer() {
        let body = Self.makeCharacter(tunic: UIColor(red: 0.20, green: 0.24, blue: 0.42, alpha: 1)) // courtier blue
        player.addChildNode(body)
        player.position = SCNVector3(x: 0, y: 0, z: 8)
        scene.rootNode.addChildNode(player)

        lookTarget.position = SCNVector3(x: 0, y: 1.4, z: 0)
        player.addChildNode(lookTarget)
    }

    private func buildCamera() {
        let cam = SCNCamera()
        cam.zFar = 250
        cam.fieldOfView = 55
        cameraNode.camera = cam
        cameraNode.position = SCNVector3(x: player.position.x + camOffset.x,
                                         y: camOffset.y,
                                         z: player.position.z + camOffset.z)
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

        // Glide the camera toward its offset from the player (fixed viewing angle).
        let desired = SCNVector3(x: player.position.x + camOffset.x,
                                 y: camOffset.y,
                                 z: player.position.z + camOffset.z)
        cameraNode.position = lerp(cameraNode.position, desired, camLerp)
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
}
