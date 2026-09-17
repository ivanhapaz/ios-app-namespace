import SceneKit
import UIKit

/// Reusable half-timber exterior recipes (kit §6) for the outdoor rooms'
/// backdrops — facades for the Courtyard, a brick perimeter for the Gardens.
enum ExteriorKit {

    /// A one-storey plastered wall mass with sill and plate.
    static func wallMass() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(6.0, 3.2, 4.0, Palette.plasterWhite, at: Prim.v(0, 1.60, 0)))
        n.addChildNode(Prim.box(6.1, 0.22, 4.1, Palette.timberDark, at: Prim.v(0, 0.11, 0)))
        n.addChildNode(Prim.box(6.1, 0.24, 4.1, Palette.timberDark, at: Prim.v(0, 3.20, 0)))
        return n
    }

    /// The structural timber pattern on the front (+Z-facing) face.
    static func timberBeams() -> SCNNode {
        let n = SCNNode()
        for x in [Float(-2.85), -1.0, 1.0, 2.85] {
            n.addChildNode(Prim.box(0.22, 3.2, 0.12, Palette.timberDark, at: Prim.v(x, 1.60, -2.02)))
        }
        n.addChildNode(Prim.box(6.0, 0.18, 0.12, Palette.timberDark, at: Prim.v(0, 1.60, -2.02)))
        n.addChildNode(Prim.box(0.18, 1.55, 0.12, Palette.timberDark, at: Prim.v(-1.95, 2.40, -2.02), euler: Prim.deg(0, 0, 38)))
        n.addChildNode(Prim.box(0.18, 1.55, 0.12, Palette.timberDark, at: Prim.v(1.95, 2.40, -2.02), euler: Prim.deg(0, 0, -38)))
        return n
    }

    /// A heavy pitched roof with deep eaves. Place its origin atop the wall.
    static func roof() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.pyramid(7.2, 2.4, 5.2, Palette.slateRoof, at: Prim.v(0, 0, 0)))
        n.addChildNode(Prim.box(7.3, 0.16, 0.20, UIColor(hex: 0x3A3A38), at: Prim.v(0, 2.36, 0)))
        n.addChildNode(Prim.box(7.3, 0.18, 0.30, Palette.timberDark, at: Prim.v(0, 0.06, -2.60)))
        n.addChildNode(Prim.box(7.3, 0.18, 0.30, Palette.timberDark, at: Prim.v(0, 0.06, 2.60)))
        return n
    }

    static func chimney() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.95, 4.20, 0.95, Palette.tudorBrick, at: Prim.v(0, 2.10, 0)))
        for y in [Float(1.4), 2.2, 3.0] {
            n.addChildNode(Prim.torus(0.42, 0.10, Palette.brickDiaper, at: Prim.v(0, y, 0)))
        }
        n.addChildNode(Prim.box(1.25, 0.25, 1.25, Palette.chapelStone, at: Prim.v(0, 4.32, 0)))
        n.addChildNode(Prim.cyl(0.22, 0.55, Palette.tudorBrick, at: Prim.v(0, 4.72, 0)))
        return n
    }

    static func mullionedWindow() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(1.70, 1.40, 0.24, Palette.chapelStone, at: Prim.v(0, 0, 0)))
        n.addChildNode(Prim.plane(1.30, 1.05, Palette.leadedGlass, at: Prim.v(0, 0, -0.13),
                                  emission: Palette.leadedGlass, emissionIntensity: 0.2, doubleSided: true))
        n.addChildNode(Prim.box(0.07, 1.05, 0.08, Palette.inkBlack, at: Prim.v(-0.33, 0, -0.15)))
        n.addChildNode(Prim.box(0.07, 1.05, 0.08, Palette.inkBlack, at: Prim.v(0.33, 0, -0.15)))
        n.addChildNode(Prim.box(1.30, 0.07, 0.08, Palette.inkBlack, at: Prim.v(0, 0, -0.15)))
        return n
    }

    static func archedDoorway() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.42, 2.35, 0.55, Palette.chapelStone, at: Prim.v(-1.06, 1.17, 0)))
        n.addChildNode(Prim.box(0.42, 2.35, 0.55, Palette.chapelStone, at: Prim.v(1.06, 1.17, 0)))
        n.addChildNode(Prim.tube(0.85, 1.27, 0.55, Palette.chapelStone, at: Prim.v(0, 2.35, 0), euler: Prim.deg(90, 0, 0)))
        n.addChildNode(Prim.box(1.70, 2.30, 0.12, Palette.timberDark, at: Prim.v(0, 1.15, -0.10)))
        n.addChildNode(Prim.cyl(0.85, 0.12, Palette.timberDark, at: Prim.v(0, 2.35, -0.10)))
        n.addChildNode(Prim.box(1.70, 0.10, 0.04, Palette.steelGrey, at: Prim.v(0, 0.75, -0.18)))
        n.addChildNode(Prim.box(1.70, 0.10, 0.04, Palette.steelGrey, at: Prim.v(0, 1.75, -0.18)))
        n.addChildNode(Prim.torus(0.11, 0.025, Palette.steelGrey, at: Prim.v(0.45, 1.25, -0.20), euler: Prim.deg(90, 0, 0)))
        return n
    }

    /// A ready building: wall + timbers + roof + a window and a door.
    static func facade(withDoor: Bool = false) -> SCNNode {
        let n = SCNNode()
        n.addChildNode(wallMass())
        n.addChildNode(timberBeams())
        let roofNode = roof()
        roofNode.position = Prim.v(0, 3.2, 0)
        n.addChildNode(roofNode)
        if withDoor {
            let door = archedDoorway()
            door.position = Prim.v(0, 0, -2.03)
            n.addChildNode(door)
        } else {
            let win = mullionedWindow()
            win.position = Prim.v(0, 1.9, -2.03)
            n.addChildNode(win)
        }
        let chim = chimney()
        chim.position = Prim.v(2.0, 3.2, 0.5)
        n.addChildNode(chim)
        return n
    }

    /// A low brick perimeter wall with a stone coping (Gardens backdrop).
    static func brickPerimeter(length: CGFloat) -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(length, 2.5, 0.5, Palette.tudorBrick, at: Prim.v(0, 1.25, 0)))
        n.addChildNode(Prim.box(length, 0.2, 0.7, Palette.chapelStone, at: Prim.v(0, 2.6, 0)))
        return n
    }
}
