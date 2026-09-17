import SceneKit
import UIKit

/// Set dressing for each room, composed from `Prim` primitives per the
/// designer's 3D Primitive Kit. `dress(_:)` returns a node holding every set
/// piece (and its lights) already placed for that room; the scene adds it under
/// the room layer. Rooms not yet dressed return an empty node.
enum RoomDressing {

    static func dress(_ room: RoomID) -> SCNNode {
        let root = SCNNode()
        switch room {
        case .chapel: dressChapel(root)
        case .greatHall: dressGreatHall(root)
        default: break
        }
        return root
    }

    // MARK: Placement helper

    private static func place(_ node: SCNNode, _ x: Float, _ y: Float, _ z: Float, yDeg: Float = 0) -> SCNNode {
        node.position = Prim.v(x, y, z)
        node.eulerAngles = Prim.deg(0, yDeg, 0)
        return node
    }

    private static func emit(_ node: SCNNode, _ color: UIColor, _ intensity: CGFloat = 0.8) -> SCNNode {
        node.geometry?.firstMaterial?.emission.contents = color
        node.geometry?.firstMaterial?.emission.intensity = intensity
        return node
    }

    // MARK: Chapel

    private static func dressChapel(_ root: SCNNode) {
        root.addChildNode(place(altar(), 0, 0, -11.6))
        root.addChildNode(place(roodCross(), 0, 0, -12.8))
        root.addChildNode(place(candleStand(), -1.7, 0, -11.4))
        root.addChildNode(place(candleStand(), 1.7, 0, -11.4))
        root.addChildNode(place(lancet(), -5.5, 0, -13.6))
        root.addChildNode(place(lancet(), 5.5, 0, -13.6))
        root.addChildNode(place(pew(), -2.6, 0, -6.5))
        root.addChildNode(place(pew(), -2.6, 0, -4.2))
        root.addChildNode(place(pew(), 2.6, 0, -6.5))
        root.addChildNode(place(pew(), 2.6, 0, -4.2))
        root.addChildNode(place(lectern(), 3.6, 0, -9.8, yDeg: -25))
    }

    private static func altar() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(3.4, 0.20, 1.7, Palette.chapelStone, at: Prim.v(0, 0.10, 0)))
        n.addChildNode(Prim.box(2.1, 0.85, 0.85, Palette.chapelStone, at: Prim.v(0, 0.62, 0)))
        n.addChildNode(Prim.box(2.16, 0.55, 0.90, Palette.royalCrimson, at: Prim.v(0, 0.52, 0)))
        n.addChildNode(Prim.box(2.45, 0.16, 1.05, Palette.ermine, at: Prim.v(0, 1.12, 0)))
        return n
    }

    private static func roodCross() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.55, 0.22, 0.55, Palette.chapelStone, at: Prim.v(0, 0.11, 0)))
        n.addChildNode(Prim.box(0.16, 2.70, 0.16, Palette.goldTrim, at: Prim.v(0, 1.57, 0)))
        n.addChildNode(Prim.box(0.95, 0.16, 0.16, Palette.goldTrim, at: Prim.v(0, 2.35, 0)))
        n.addChildNode(Prim.sphere(0.11, Palette.goldTrim, at: Prim.v(0, 2.35, 0.09)))
        return n
    }

    private static func candleStand() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.16, 0.06, Palette.goldTrim, at: Prim.v(0, 0.03, 0)))
        n.addChildNode(Prim.cyl(0.05, 1.30, Palette.goldTrim, at: Prim.v(0, 0.71, 0)))
        n.addChildNode(Prim.cyl(0.035, 0.30, Palette.ermine, at: Prim.v(0, 1.51, 0)))
        n.addChildNode(emit(Prim.cone(0, 0.035, 0.12, Palette.flame, at: Prim.v(0, 1.72, 0)), Palette.flame))
        n.addChildNode(Prim.omni(intensity: 90, color: Palette.flame, distance: 3.5, at: Prim.v(0, 1.78, 0)))
        return n
    }

    private static func pew() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(3.6, 0.12, 0.46, Palette.woodFloor, at: Prim.v(0, 0.46, 0)))
        n.addChildNode(Prim.box(3.6, 0.70, 0.10, Palette.woodFloor, at: Prim.v(0, 0.80, 0.22)))
        n.addChildNode(Prim.box(0.14, 0.46, 0.44, Palette.timberDark, at: Prim.v(-1.66, 0.23, 0)))
        n.addChildNode(Prim.box(0.14, 0.46, 0.44, Palette.timberDark, at: Prim.v(1.66, 0.23, 0)))
        return n
    }

    private static func lancet() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(1.9, 4.2, 0.30, Palette.chapelStone, at: Prim.v(0, 2.60, 0)))
        n.addChildNode(Prim.plane(1.45, 3.70, Palette.glassRuby, at: Prim.v(0, 2.60, -0.16),
                                  emission: Palette.glassRuby, doubleSided: true))
        n.addChildNode(Prim.plane(1.45, 0.85, Palette.goldTrim, at: Prim.v(0, 3.50, -0.17),
                                  emission: Palette.goldTrim, doubleSided: true))
        n.addChildNode(Prim.plane(1.45, 0.85, Palette.leadedGlass, at: Prim.v(0, 1.75, -0.17),
                                  emission: Palette.leadedGlass, doubleSided: true))
        n.addChildNode(Prim.box(0.09, 3.70, 0.10, Palette.inkBlack, at: Prim.v(0, 2.60, -0.19)))
        n.addChildNode(Prim.box(1.45, 0.09, 0.10, Palette.inkBlack, at: Prim.v(0, 2.60, -0.19)))
        return n
    }

    private static func lectern() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.34, 0.10, Palette.timberDark, at: Prim.v(0, 0.05, 0)))
        n.addChildNode(Prim.cyl(0.09, 1.10, Palette.woodFloor, at: Prim.v(0, 0.65, 0)))
        n.addChildNode(Prim.box(0.70, 0.06, 0.50, Palette.woodFloor, at: Prim.v(0, 1.24, 0), euler: Prim.deg(-28, 0, 0)))
        n.addChildNode(Prim.box(0.44, 0.05, 0.32, Palette.parchment, at: Prim.v(0, 1.32, -0.03), euler: Prim.deg(-28, 0, 0)))
        return n
    }

    // MARK: Great Hall

    private static func dressGreatHall(_ root: SCNNode) {
        root.addChildNode(place(daisThrone(), 0, 0, -11.8))
        root.addChildNode(place(banquetTable(), -4.5, 0, -5.0, yDeg: 90))
        root.addChildNode(place(hallBench(), -5.65, 0, -5.0, yDeg: 90))
        root.addChildNode(place(hallBench(), -3.35, 0, -5.0, yDeg: 90))
        root.addChildNode(place(banner(CharacterKit.Faction.boleyn.field), -13.5, 5.3, -8, yDeg: 90))
        root.addChildNode(place(banner(CharacterKit.Faction.seymour.field), -13.5, 5.3, 0, yDeg: 90))
        root.addChildNode(place(banner(CharacterKit.Faction.oldCatholic.field), 13.5, 5.3, -4, yDeg: -90))
        root.addChildNode(place(chandelier(), 0, 4.6, -5.0))
    }

    private static func banquetTable() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(8.0, 0.14, 1.30, Palette.woodFloor, at: Prim.v(0, 0.78, 0)))
        n.addChildNode(Prim.box(0.24, 0.71, 1.10, Palette.timberDark, at: Prim.v(-3.0, 0.355, 0)))
        n.addChildNode(Prim.box(0.24, 0.71, 1.10, Palette.timberDark, at: Prim.v(3.0, 0.355, 0)))
        n.addChildNode(Prim.box(6.2, 0.12, 0.14, Palette.timberDark, at: Prim.v(0, 0.30, 0)))
        n.addChildNode(Prim.box(8.1, 0.35, 1.40, Palette.royalCrimson, at: Prim.v(0, 0.62, 0)))
        return n
    }

    private static func hallBench() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(7.4, 0.12, 0.42, Palette.woodFloor, at: Prim.v(0, 0.45, 0)))
        n.addChildNode(Prim.box(0.14, 0.45, 0.40, Palette.timberDark, at: Prim.v(-3.2, 0.225, 0)))
        n.addChildNode(Prim.box(0.14, 0.45, 0.40, Palette.timberDark, at: Prim.v(3.2, 0.225, 0)))
        return n
    }

    private static func daisThrone() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(6.0, 0.22, 2.6, Palette.stoneWall, at: Prim.v(0, 0.11, 0)))
        n.addChildNode(Prim.box(4.8, 0.22, 2.0, Palette.stoneWall, at: Prim.v(0, 0.33, -0.15)))
        n.addChildNode(Prim.box(0.95, 0.14, 0.95, Palette.royalCrimson, at: Prim.v(0, 0.88, 0)))
        n.addChildNode(Prim.box(0.95, 1.40, 0.14, Palette.royalCrimson, at: Prim.v(0, 1.60, -0.40)))
        n.addChildNode(Prim.box(0.12, 0.10, 0.85, Palette.goldTrim, at: Prim.v(-0.48, 1.02, 0.02)))
        n.addChildNode(Prim.box(0.12, 0.10, 0.85, Palette.goldTrim, at: Prim.v(0.48, 1.02, 0.02)))
        n.addChildNode(Prim.sphere(0.10, Palette.goldTrim, at: Prim.v(-0.48, 2.34, -0.40)))
        n.addChildNode(Prim.sphere(0.10, Palette.goldTrim, at: Prim.v(0.48, 2.34, -0.40)))
        n.addChildNode(Prim.box(2.0, 0.12, 1.2, Palette.goldTrim, at: Prim.v(0, 2.95, -0.30)))
        n.addChildNode(Prim.plane(1.8, 2.0, Palette.royalCrimson, at: Prim.v(0, 1.95, -0.70), doubleSided: true))
        return n
    }

    private static func banner(_ field: UIColor) -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.05, 2.0, Palette.timberDark, at: Prim.v(0, 0, 0), euler: Prim.deg(0, 0, 90)))
        n.addChildNode(Prim.plane(1.6, 3.4, field, at: Prim.v(0, -1.75, 0.06), doubleSided: true))
        n.addChildNode(Prim.plane(0.7, 0.85, Palette.chapelStone, at: Prim.v(0, -1.55, 0.08), doubleSided: true))
        return n
    }

    private static func chandelier() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.025, 1.20, Palette.steelGrey, at: Prim.v(0, 0.60, 0)))
        n.addChildNode(Prim.torus(0.85, 0.06, Palette.steelGrey, at: Prim.v(0, 0, 0)))
        for i in 0..<6 {
            let a = Float(i) * (.pi / 3)
            let x = cos(a) * 0.85
            let z = sin(a) * 0.85
            n.addChildNode(Prim.cyl(0.04, 0.28, Palette.ermine, at: Prim.v(x, 0.16, z)))
            n.addChildNode(emit(Prim.cone(0, 0.04, 0.12, Palette.flame, at: Prim.v(x, 0.36, z)), Palette.flame))
        }
        n.addChildNode(Prim.omni(intensity: 280, color: Palette.flame, distance: 9, at: Prim.v(0, 0, 0)))
        return n
    }
}
