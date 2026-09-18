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
        case .courtyard: dressCourtyard(root)
        case .privyChamber: dressPrivy(root)
        case .kitchens: dressKitchens(root)
        case .gardens: dressGardens(root)
        case .tower: dressTower(root)
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
        root.addChildNode(place(banner(.boleyn), -13.5, 5.3, -8, yDeg: 90))
        root.addChildNode(place(banner(.seymour), -13.5, 5.3, 0, yDeg: 90))
        root.addChildNode(place(banner(.oldCatholic), 13.5, 5.3, -4, yDeg: -90))
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

    private static func banner(_ faction: CharacterKit.Faction) -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.05, 2.0, Palette.timberDark, at: Prim.v(0, 0, 0), euler: Prim.deg(0, 0, 90)))
        n.addChildNode(Prim.plane(1.6, 3.4, faction.field, at: Prim.v(0, -1.75, 0.06), doubleSided: true))
        let device = chargeDevice(faction)
        device.position = Prim.v(0, -1.55, 0.09)
        n.addChildNode(device)
        return n
    }

    /// The heraldic charge for a faction, built from primitives (no texture):
    /// Boleyn chevron (ermine), Seymour cross (gold), Old-Catholic roundel (stone).
    private static func chargeDevice(_ faction: CharacterKit.Faction) -> SCNNode {
        let n = SCNNode()
        switch faction {
        case .boleyn:
            let metal = Palette.ermine
            n.addChildNode(Prim.box(0.44, 0.10, 0.02, metal, at: Prim.v(-0.16, 0, 0), euler: Prim.deg(0, 0, 38)))
            n.addChildNode(Prim.box(0.44, 0.10, 0.02, metal, at: Prim.v(0.16, 0, 0), euler: Prim.deg(0, 0, -38)))
        case .seymour:
            let metal = Palette.goldTrim
            n.addChildNode(Prim.box(0.10, 0.62, 0.02, metal, at: Prim.v(0, 0, 0)))
            n.addChildNode(Prim.box(0.44, 0.10, 0.02, metal, at: Prim.v(0, 0.10, 0)))
        case .oldCatholic:
            n.addChildNode(Prim.cyl(0.19, 0.02, Palette.chapelStone, at: Prim.v(0, 0, 0), euler: Prim.deg(90, 0, 0)))
        }
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

    // MARK: Courtyard

    private static func dressCourtyard(_ root: SCNNode) {
        // North backdrop: two facades (their decorated fronts face the player).
        root.addChildNode(place(ExteriorKit.facade(), -4.0, 0, -15.5, yDeg: 180))
        root.addChildNode(place(ExteriorKit.facade(withDoor: true), 4.0, 0, -15.5, yDeg: 180))
        root.addChildNode(place(gateArch(), 0, 0, 13.4))
        root.addChildNode(place(well(), 0, 0, -2.0))
        root.addChildNode(place(marketStall(), -9.5, 0, 4.0, yDeg: 22))
        root.addChildNode(place(courtyardTree(), 11.0, 0, -10.5))
        root.addChildNode(place(barrelStack(), -12.4, 0, -9.0, yDeg: -15))
    }

    private static func well() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.tube(0.75, 0.95, 1.05, Palette.stoneWall, at: Prim.v(0, 0.52, 0)))
        n.addChildNode(Prim.cyl(0.75, 0.04, Palette.waterBlue, at: Prim.v(0, 0.35, 0)))
        n.addChildNode(Prim.box(0.12, 1.9, 0.12, Palette.timberDark, at: Prim.v(-0.85, 1.55, 0)))
        n.addChildNode(Prim.box(0.12, 1.9, 0.12, Palette.timberDark, at: Prim.v(0.85, 1.55, 0)))
        n.addChildNode(Prim.pyramid(2.4, 0.7, 1.6, Palette.slateRoof, at: Prim.v(0, 2.50, 0)))
        n.addChildNode(Prim.cyl(0.09, 1.55, Palette.timberDark, at: Prim.v(0, 2.05, 0), euler: Prim.deg(0, 0, 90)))
        n.addChildNode(Prim.cyl(0.16, 0.24, Palette.timberDark, at: Prim.v(0, 1.55, 0)))
        return n
    }

    private static func gateArch() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.9, 4.4, 1.0, Palette.chapelStone, at: Prim.v(-2.5, 2.2, 0)))
        n.addChildNode(Prim.box(0.9, 4.4, 1.0, Palette.chapelStone, at: Prim.v(2.5, 2.2, 0)))
        n.addChildNode(Prim.box(5.9, 0.8, 1.0, Palette.chapelStone, at: Prim.v(0, 4.8, 0)))
        n.addChildNode(Prim.tube(2.05, 2.55, 1.0, Palette.chapelStone, at: Prim.v(0, 4.4, 0), euler: Prim.deg(90, 0, 0)))
        for i in 0..<5 {
            let x = -1.8 + Float(i) * 0.9
            n.addChildNode(Prim.box(0.07, 1.1, 0.07, Palette.steelGrey, at: Prim.v(x, 5.1, 0)))
        }
        n.addChildNode(Prim.box(2.2, 0.55, 0.12, Palette.royalCrimson, at: Prim.v(0, 5.55, -0.52)))
        return n
    }

    private static func marketStall() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(2.6, 0.10, 1.0, Palette.woodFloor, at: Prim.v(0, 0.85, 0)))
        for sx in [Float(-1.15), 1.15] {
            for sz in [Float(-0.40), 0.40] {
                n.addChildNode(Prim.box(0.12, 0.85, 0.12, Palette.timberDark, at: Prim.v(sx, 0.42, sz)))
            }
        }
        n.addChildNode(Prim.box(0.10, 2.4, 0.10, Palette.timberDark, at: Prim.v(-1.25, 1.20, -0.45)))
        n.addChildNode(Prim.box(0.10, 2.4, 0.10, Palette.timberDark, at: Prim.v(1.25, 1.20, -0.45)))
        n.addChildNode(Prim.box(2.9, 0.08, 1.5, Palette.royalCrimson, at: Prim.v(0, 2.35, 0.10), euler: Prim.deg(-14, 0, 0)))
        let goods = [Palette.strawGold, Palette.gardenGreen, Palette.strawGold]
        for (i, color) in goods.enumerated() {
            n.addChildNode(Prim.sphere(0.14, color, at: Prim.v(-0.6 + Float(i) * 0.6, 0.97, 0)))
        }
        return n
    }

    private static func courtyardTree() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.22, 2.2, Palette.timberDark, at: Prim.v(0, 1.10, 0)))
        n.addChildNode(Prim.sphere(1.35, Palette.gardenGreen, at: Prim.v(0, 2.60, 0)))
        n.addChildNode(Prim.sphere(0.95, Palette.foliageDark, at: Prim.v(0.35, 3.55, -0.20)))
        n.addChildNode(Prim.tube(0.85, 1.05, 0.35, Palette.stoneWall, at: Prim.v(0, 0.17, 0)))
        return n
    }

    private static func barrelStack() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.cyl(0.38, 0.95, Palette.timberDark, at: Prim.v(-0.42, 0.48, 0)))
        n.addChildNode(Prim.cyl(0.38, 0.95, Palette.timberDark, at: Prim.v(0.42, 0.48, 0.10)))
        n.addChildNode(Prim.cyl(0.38, 0.95, Palette.timberDark, at: Prim.v(0, 1.05, -0.30), euler: Prim.deg(0, 0, 90)))
        n.addChildNode(Prim.torus(0.39, 0.035, Palette.steelGrey, at: Prim.v(-0.42, 0.24, 0)))
        n.addChildNode(Prim.torus(0.39, 0.035, Palette.steelGrey, at: Prim.v(-0.42, 0.72, 0)))
        n.addChildNode(Prim.torus(0.39, 0.035, Palette.steelGrey, at: Prim.v(0.42, 0.24, 0.10)))
        n.addChildNode(Prim.torus(0.39, 0.035, Palette.steelGrey, at: Prim.v(0.42, 0.72, 0.10)))
        return n
    }

    // MARK: Privy Chamber

    private static func dressPrivy(_ root: SCNNode) {
        root.addChildNode(place(canopiedBed(), -8.0, 0, -11.4))
        root.addChildNode(place(fireplace(), 13.3, 0, -5.0, yDeg: -90))
        root.addChildNode(place(writingDesk(), 9.0, 0, 3.5, yDeg: -40))
        root.addChildNode(place(goldPanel(), -13.5, 0, -2, yDeg: 90))
        root.addChildNode(place(goldPanel(), -13.5, 0, 3, yDeg: 90))
        root.addChildNode(place(goldPanel(), 6.0, 0, -13.5))
    }

    private static func canopiedBed() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(2.4, 0.45, 3.0, Palette.timberDark, at: Prim.v(0, 0.22, 0)))
        n.addChildNode(Prim.box(2.3, 0.35, 2.9, Palette.ermine, at: Prim.v(0, 0.62, 0)))
        n.addChildNode(Prim.box(2.42, 0.20, 2.3, Palette.royalCrimson, at: Prim.v(0, 0.70, 0.25)))
        for px in [Float(-1.10), 1.10] {
            for pz in [Float(-1.40), 1.40] {
                n.addChildNode(Prim.cyl(0.09, 3.2, Palette.goldTrim, at: Prim.v(px, 1.60, pz)))
                n.addChildNode(Prim.sphere(0.11, Palette.goldTrim, at: Prim.v(px, 3.42, pz)))
            }
        }
        n.addChildNode(Prim.box(2.5, 0.16, 3.1, Palette.goldTrim, at: Prim.v(0, 3.28, 0)))
        n.addChildNode(Prim.plane(2.2, 1.9, Palette.royalCrimson, at: Prim.v(0, 1.90, -1.44), doubleSided: true))
        return n
    }

    private static func writingDesk() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(1.8, 0.10, 0.85, Palette.woodFloor, at: Prim.v(0, 0.80, 0)))
        for lx in [Float(-0.80), 0.80] {
            for lz in [Float(-0.34), 0.34] {
                n.addChildNode(Prim.box(0.11, 0.80, 0.11, Palette.timberDark, at: Prim.v(lx, 0.40, lz)))
            }
        }
        n.addChildNode(Prim.box(0.34, 0.03, 0.44, Palette.parchment, at: Prim.v(-0.42, 0.87, 0.04), euler: Prim.deg(0, 12, 0)))
        n.addChildNode(Prim.box(0.40, 0.10, 0.30, Palette.inkBlack, at: Prim.v(0.45, 0.90, -0.06)))
        n.addChildNode(Prim.cyl(0.06, 0.11, Palette.inkBlack, at: Prim.v(0.10, 0.91, 0.18)))
        n.addChildNode(Prim.cone(0, 0.02, 0.34, Palette.ermine, at: Prim.v(0.10, 1.08, 0.18), euler: Prim.deg(0, 0, 18)))
        n.addChildNode(Prim.cyl(0.26, 0.50, Palette.timberDark, at: Prim.v(0, 0.25, 0.75)))
        return n
    }

    private static func fireplace() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.55, 1.85, 0.65, Palette.chapelStone, at: Prim.v(-1.35, 0.92, 0)))
        n.addChildNode(Prim.box(0.55, 1.85, 0.65, Palette.chapelStone, at: Prim.v(1.35, 0.92, 0)))
        n.addChildNode(Prim.box(3.25, 0.45, 0.65, Palette.chapelStone, at: Prim.v(0, 2.07, 0)))
        n.addChildNode(Prim.pyramid(3.25, 1.5, 0.65, Palette.chapelStone, at: Prim.v(0, 2.30, 0)))
        n.addChildNode(Prim.box(2.15, 1.85, 0.30, Palette.inkBlack, at: Prim.v(0, 0.92, -0.20)))
        for lx in [Float(-0.3), 0, 0.3] {
            n.addChildNode(Prim.cyl(0.11, 1.1, Palette.timberDark, at: Prim.v(lx, 0.13, -0.05), euler: Prim.deg(0, 0, 90)))
        }
        n.addChildNode(emit(Prim.cone(0, 0.45, 0.85, Palette.flame, at: Prim.v(0, 0.45, 0)), Palette.flame, 0.7))
        n.addChildNode(Prim.box(2.2, 0.55, 0.10, Palette.goldTrim, at: Prim.v(0, 3.15, -0.22)))
        n.addChildNode(Prim.omni(intensity: 340, color: Palette.flame, distance: 8, at: Prim.v(0, 0.6, 0.3)))
        return n
    }

    private static func goldPanel() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(2.4, 2.8, 0.08, Palette.woodFloor, at: Prim.v(0, 1.60, 0)))
        n.addChildNode(Prim.box(2.4, 0.10, 0.12, Palette.goldTrim, at: Prim.v(0, 3.02, 0.02)))
        n.addChildNode(Prim.box(0.65, 0.65, 0.06, Palette.goldTrim, at: Prim.v(0, 1.60, 0.06), euler: Prim.deg(0, 0, 45)))
        return n
    }

    // MARK: Kitchens

    private static func dressKitchens(_ root: SCNNode) {
        root.addChildNode(place(hearthOven(), -7.5, 0, -12.2))
        root.addChildNode(place(worktable(), 0, 0, -6.0))
        root.addChildNode(place(sacksAndBarrels(), 12.0, 0, -11.5, yDeg: -30))
        root.addChildNode(place(hangingRack(), 0, 3.1, -8.6))
        root.addChildNode(place(sacksAndBarrels(), -12.6, 0, 6.0, yDeg: 40))
    }

    private static func hearthOven() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(3.2, 1.05, 1.6, Palette.tudorBrick, at: Prim.v(0, 0.52, 0)))
        n.addChildNode(Prim.sphere(1.05, Palette.tudorBrick, at: Prim.v(0, 1.05, 0)))
        n.addChildNode(Prim.tube(0.42, 0.58, 0.35, Palette.inkBlack, at: Prim.v(0, 1.05, 0.80), euler: Prim.deg(90, 0, 0)))
        n.addChildNode(emit(Prim.cone(0, 0.32, 0.55, Palette.flame, at: Prim.v(0, 1.00, 0.72)), Palette.flame, 0.7))
        n.addChildNode(Prim.box(0.85, 3.4, 0.85, Palette.tudorBrick, at: Prim.v(0, 2.90, -0.30)))
        n.addChildNode(Prim.sphere(0.34, Palette.inkBlack, at: Prim.v(1.15, 1.25, 0.55)))
        n.addChildNode(Prim.omni(intensity: 300, color: Palette.flame, distance: 6, at: Prim.v(0, 1.0, 0.72)))
        return n
    }

    private static func worktable() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(3.0, 0.14, 1.1, Palette.ermine, at: Prim.v(0, 0.86, 0)))
        n.addChildNode(Prim.box(2.9, 0.16, 1.0, Palette.woodFloor, at: Prim.v(0, 0.72, 0)))
        for lx in [Float(-1.35), 1.35] {
            for lz in [Float(-0.42), 0.42] {
                n.addChildNode(Prim.box(0.16, 0.80, 0.16, Palette.timberDark, at: Prim.v(lx, 0.40, lz)))
            }
        }
        n.addChildNode(Prim.box(0.55, 0.05, 0.38, Palette.woodFloor, at: Prim.v(-0.75, 0.95, 0.05), euler: Prim.deg(0, 8, 0)))
        n.addChildNode(Prim.capsule(0.11, 0.36, Palette.strawGold, at: Prim.v(0.60, 1.00, -0.02), euler: Prim.deg(0, 0, 90)))
        return n
    }

    private static func sacksAndBarrels() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.capsule(0.38, 1.05, Palette.strawGold, at: Prim.v(-0.55, 0.50, 0), euler: Prim.deg(12, 0, 0)))
        n.addChildNode(Prim.capsule(0.34, 0.95, UIColor(hex: 0xB8985F), at: Prim.v(0.30, 0.45, -0.35), euler: Prim.deg(0, 0, -10)))
        n.addChildNode(Prim.cyl(0.40, 1.00, Palette.timberDark, at: Prim.v(0.95, 0.50, 0.30)))
        n.addChildNode(Prim.torus(0.41, 0.035, Palette.steelGrey, at: Prim.v(0.95, 0.24, 0.30)))
        n.addChildNode(Prim.torus(0.41, 0.035, Palette.steelGrey, at: Prim.v(0.95, 0.76, 0.30)))
        n.addChildNode(Prim.box(0.75, 0.55, 0.60, Palette.timberDark, at: Prim.v(-1.30, 0.27, 0.50), euler: Prim.deg(0, 16, 0)))
        return n
    }

    private static func hangingRack() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(3.6, 0.16, 0.16, Palette.timberDark, at: Prim.v(0, 0, 0)))
        for i in 0..<5 {
            let x = -1.4 + Float(i) * 0.7
            n.addChildNode(Prim.torus(0.06, 0.015, Palette.steelGrey, at: Prim.v(x, -0.12, 0), euler: Prim.deg(90, 0, 0)))
        }
        n.addChildNode(Prim.sphere(0.22, Palette.inkBlack, at: Prim.v(-1.4, -0.42, 0)))
        n.addChildNode(Prim.cyl(0.17, 0.30, Palette.steelGrey, at: Prim.v(-0.7, -0.40, 0)))
        n.addChildNode(Prim.cyl(0.24, 0.07, Palette.inkBlack, at: Prim.v(0, -0.36, 0)))
        n.addChildNode(Prim.cone(0.14, 0.03, 0.45, Palette.gardenGreen, at: Prim.v(0.7, -0.48, 0)))
        n.addChildNode(Prim.cone(0.12, 0.03, 0.40, Palette.foliageDark, at: Prim.v(1.4, -0.46, 0)))
        return n
    }

    // MARK: Gardens

    private static func dressGardens(_ root: SCNNode) {
        // Gravel cross paths.
        root.addChildNode(Prim.box(28, 0.06, 1.4, UIColor(hex: 0xB3A98E), at: Prim.v(0, 0.03, 0)))
        root.addChildNode(Prim.box(1.4, 0.06, 28, UIColor(hex: 0xB3A98E), at: Prim.v(0, 0.03, 0)))
        root.addChildNode(place(fountain(), 0, 0, 0))
        var i = 0
        for qx in [Float(-6.5), 6.5] {
            for qz in [Float(-6.5), 6.5] {
                root.addChildNode(place(knotQuadrant(crimson: i % 2 == 0), qx, 0, qz))
                i += 1
            }
        }
        for tx in [Float(-2.9), 2.9] {
            for tz in [Float(-2.9), 2.9] {
                root.addChildNode(place(topiaryCone(), tx, 0, tz))
            }
        }
        root.addChildNode(place(ExteriorKit.brickPerimeter(length: 27), 0, 0, -13.8))
        root.addChildNode(place(gardenBench(), 11.6, 0, 8.0, yDeg: -55))
    }

    private static func fountain() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.tube(1.55, 1.85, 0.55, Palette.chapelStone, at: Prim.v(0, 0.27, 0)))
        n.addChildNode(Prim.cyl(1.55, 0.06, Palette.waterBlue, at: Prim.v(0, 0.46, 0)))
        n.addChildNode(Prim.cyl(0.38, 0.70, Palette.chapelStone, at: Prim.v(0, 0.35, 0)))
        n.addChildNode(Prim.cyl(0.16, 1.30, Palette.chapelStone, at: Prim.v(0, 1.35, 0)))
        n.addChildNode(Prim.tube(0.50, 0.68, 0.20, Palette.chapelStone, at: Prim.v(0, 2.05, 0)))
        n.addChildNode(Prim.cone(0.05, 0.02, 0.55, Palette.waterBlue, at: Prim.v(0, 2.42, 0)))
        n.addChildNode(Prim.sphere(0.13, Palette.goldTrim, at: Prim.v(0, 2.78, 0)))
        return n
    }

    private static func knotQuadrant(crimson: Bool) -> SCNNode {
        let hedge = UIColor(hex: 0x3F6B4A)
        let n = SCNNode()
        n.addChildNode(Prim.box(4.4, 0.45, 0.45, hedge, at: Prim.v(0, 0.22, -1.98)))
        n.addChildNode(Prim.box(4.4, 0.45, 0.45, hedge, at: Prim.v(0, 0.22, 1.98)))
        n.addChildNode(Prim.box(0.45, 0.45, 3.5, hedge, at: Prim.v(1.98, 0.22, 0)))
        n.addChildNode(Prim.box(0.45, 0.45, 3.5, hedge, at: Prim.v(-1.98, 0.22, 0)))
        n.addChildNode(Prim.box(1.9, 0.10, 1.9, crimson ? Palette.royalCrimson : Palette.goldTrim,
                                at: Prim.v(0, 0.05, 0), euler: Prim.deg(0, 45, 0)))
        n.addChildNode(Prim.sphere(0.42, Palette.foliageDark, at: Prim.v(0, 0.62, 0)))
        return n
    }

    private static func topiaryCone() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.75, 0.55, 0.75, Palette.chapelStone, at: Prim.v(0, 0.27, 0)))
        n.addChildNode(Prim.cone(0, 0.42, 1.55, Palette.gardenGreen, at: Prim.v(0, 1.32, 0)))
        n.addChildNode(Prim.sphere(0.13, Palette.foliageDark, at: Prim.v(0, 2.14, 0)))
        return n
    }

    private static func gardenBench() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(2.1, 0.14, 0.50, Palette.chapelStone, at: Prim.v(0, 0.46, 0)))
        n.addChildNode(Prim.box(0.22, 0.46, 0.50, Palette.chapelStone, at: Prim.v(-0.94, 0.23, 0)))
        n.addChildNode(Prim.box(0.22, 0.46, 0.50, Palette.chapelStone, at: Prim.v(0.94, 0.23, 0)))
        n.addChildNode(Prim.box(2.1, 0.55, 0.12, Palette.chapelStone, at: Prim.v(0, 0.80, 0.19)))
        return n
    }

    // MARK: The Tower

    private static func dressTower(_ root: SCNNode) {
        root.addChildNode(place(cellBars(), 0, 0, 8.5))
        root.addChildNode(place(barredWindow(), 0, 4.3, -13.6))
        root.addChildNode(place(chains(), -13.4, 2.4, -4.0, yDeg: 90))
        root.addChildNode(place(chains(), -13.4, 2.4, 1.0, yDeg: 90))
        root.addChildNode(place(block(), 0, 0, -8.0, yDeg: 12))
        root.addChildNode(place(cellBars(), 13.4, 0, -2.0, yDeg: 90))
    }

    private static func cellBars() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(5.0, 0.25, 0.35, Palette.chapelStone, at: Prim.v(0, 0.12, 0)))
        n.addChildNode(Prim.box(5.0, 0.25, 0.35, Palette.chapelStone, at: Prim.v(0, 3.90, 0)))
        for i in 0..<9 {
            let x = -2.2 + Float(i) * 0.55
            n.addChildNode(Prim.cyl(0.06, 3.7, Palette.steelGrey, at: Prim.v(x, 2.0, 0)))
        }
        n.addChildNode(Prim.box(4.6, 0.10, 0.10, Palette.steelGrey, at: Prim.v(0, 2.00, 0)))
        return n
    }

    private static func barredWindow() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.95, 1.50, 0.70, Palette.chapelStone, at: Prim.v(0, 0, 0)))
        n.addChildNode(Prim.plane(0.60, 1.15, Palette.skyBackdrop, at: Prim.v(0, 0, -0.30),
                                  emission: Palette.skyBackdrop, emissionIntensity: 0.6, doubleSided: true))
        n.addChildNode(Prim.cyl(0.045, 1.15, Palette.steelGrey, at: Prim.v(0, 0, -0.26)))
        n.addChildNode(Prim.cyl(0.045, 0.60, Palette.steelGrey, at: Prim.v(0, 0, -0.26), euler: Prim.deg(0, 0, 90)))
        // A single cold shaft of daylight.
        let spot = SCNNode()
        let light = SCNLight()
        light.type = .spot
        light.color = Palette.skyBackdrop
        light.intensity = 500
        light.spotOuterAngle = 40
        spot.light = light
        spot.position = Prim.v(0, 0, -0.6)
        spot.eulerAngles = Prim.deg(-35, 0, 0)
        n.addChildNode(spot)
        return n
    }

    private static func chains() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.30, 0.30, 0.10, Palette.steelGrey, at: Prim.v(0, 0, 0)))
        for i in 0..<5 {
            let y = -0.2 - Float(i) * 0.2
            let euler = i % 2 == 0 ? Prim.deg(90, 0, 0) : Prim.deg(0, 0, 90)
            n.addChildNode(Prim.torus(0.09, 0.025, Palette.steelGrey, at: Prim.v(0, y, 0.03), euler: euler))
        }
        n.addChildNode(Prim.torus(0.11, 0.035, Palette.steelGrey, at: Prim.v(0, -1.22, 0.03), euler: Prim.deg(90, 0, 0)))
        return n
    }

    private static func block() -> SCNNode {
        let n = SCNNode()
        n.addChildNode(Prim.box(0.90, 0.55, 0.70, Palette.timberDark, at: Prim.v(0, 0.27, 0), chamfer: 0.10))
        n.addChildNode(Prim.cyl(0.22, 0.72, UIColor(hex: 0x5C4226), at: Prim.v(0, 0.55, 0), euler: Prim.deg(90, 0, 0)))
        n.addChildNode(Prim.box(2.4, 0.08, 1.8, Palette.strawGold, at: Prim.v(0, 0.04, 0.9), euler: Prim.deg(0, 8, 0)))
        n.addChildNode(Prim.box(1.6, 0.08, 1.2, UIColor(hex: 0xB8985F), at: Prim.v(-1.1, 0.04, 1.4), euler: Prim.deg(0, -22, 0)))
        return n
    }
}
