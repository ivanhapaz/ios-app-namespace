import SceneKit
import UIKit

/// Builds the cast from SceneKit primitives, following the designer's 3D
/// Primitive Kit exactly (rig = capsule body at y0.9 + sphere head at y1.78,
/// facing -Z, ~2.07 m tall). Each archetype is the rig plus distinguishing
/// primitives in the palette below. No meshes, no textures.
enum CharacterKit {

    // MARK: Palette (3D world tokens)
    enum P {
        static let royalCrimson = UIColor(hex: 0xA6301F)
        static let goldTrim = UIColor(hex: 0xC9A227)
        static let inkBlack = UIColor(hex: 0x23201B)
        static let timberDark = UIColor(hex: 0x4A3524)
        static let plasterWhite = UIColor(hex: 0xE3DCC8)
        static let steelGrey = UIColor(hex: 0x8E9299)
        static let strawGold = UIColor(hex: 0xC4A24B)
        static let ermine = UIColor(hex: 0xEFEAE0)
        static let skinTone = UIColor(hex: 0xC89A72)
        static let hairBrown = UIColor(hex: 0x4A3524)
        static let woodFloor = UIColor(hex: 0x8A6238)
        static let parchment = UIColor(hex: 0xE8DCC0)
        static let rivalPlum = UIColor(hex: 0x6B2E3E)
        static let servantDun = UIColor(hex: 0x6B5A3E)
        static let playerBlue = UIColor(hex: 0x33406B)
    }

    enum Faction {
        case boleyn, seymour, oldCatholic
        var field: UIColor {
            switch self {
            case .boleyn: return UIColor(hex: 0x3F6B4A)
            case .seymour: return UIColor(hex: 0x2B4C7E)
            case .oldCatholic: return UIColor(hex: 0x6B2E3E)
            }
        }
    }

    // MARK: Dispatch

    static func character(for npc: NPCID) -> SCNNode {
        switch npc {
        case .king: return makeKing()
        case .cromwell: return makeCromwell()
        case .priest: return makePriest()
        case .rivalCourtier: return makeRival()
        case .servantSpy: return makeServant()
        case .ladyInWaiting: return makeLady(faction: .boleyn)
        }
    }

    // MARK: Archetypes

    static func makeKing() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.royalCrimson, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(cone(0.40, 0.68, 1.50, P.royalCrimson, at: v(0, 0.75, 0)))
        root.addChildNode(sphere(0.23, P.royalCrimson, at: v(-0.36, 1.48, 0)))
        root.addChildNode(sphere(0.23, P.royalCrimson, at: v(0.36, 1.48, 0)))
        root.addChildNode(torus(0.33, 0.10, P.ermine, at: v(0, 1.52, 0)))
        root.addChildNode(tube(0.27, 0.31, 0.13, P.goldTrim, at: v(0, 2.00, 0)))
        root.addChildNode(cone(0, 0.06, 0.17, P.goldTrim, at: v(0, 2.14, -0.28)))
        root.addChildNode(cone(0, 0.06, 0.17, P.goldTrim, at: v(0.24, 2.14, 0.14)))
        root.addChildNode(cone(0, 0.06, 0.17, P.goldTrim, at: v(-0.24, 2.14, 0.14)))
        root.addChildNode(cylinder(0.035, 1.15, P.goldTrim, at: v(0.48, 0.95, 0.10)))
        root.addChildNode(sphere(0.075, P.goldTrim, at: v(0.48, 1.58, 0.10)))
        return root
    }

    static func makeCromwell() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.inkBlack, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(cone(0.38, 0.56, 1.45, P.inkBlack, at: v(0, 0.72, 0)))
        root.addChildNode(cylinder(0.32, 0.09, P.inkBlack, at: v(0, 2.06, 0)))
        root.addChildNode(box(0.52, 0.10, 0.32, P.ermine, at: v(0, 1.58, -0.04)))
        root.addChildNode(torus(0.25, 0.035, P.goldTrim, at: v(0, 1.48, 0)))
        root.addChildNode(sphere(0.065, P.goldTrim, at: v(0, 1.28, -0.23)))
        root.addChildNode(box(0.30, 0.03, 0.38, P.parchment, at: v(0.40, 0.97, -0.14), euler: e(-18, 14, 0)))
        root.addChildNode(sphere(0.08, P.skinTone, at: v(0.40, 0.92, -0.04)))
        return root
    }

    static func makePriest() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.inkBlack, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(cone(0.38, 0.54, 1.52, P.inkBlack, at: v(0, 0.76, 0)))
        root.addChildNode(torus(0.255, 0.055, P.hairBrown, at: v(0, 1.84, 0)))
        root.addChildNode(box(0.28, 0.13, 0.28, P.inkBlack, at: v(0, 2.06, 0)))
        root.addChildNode(box(0.04, 0.09, 0.28, P.inkBlack, at: v(0, 2.16, 0)))
        root.addChildNode(torus(0.23, 0.025, P.goldTrim, at: v(0, 1.50, 0)))
        root.addChildNode(box(0.07, 0.44, 0.05, P.goldTrim, at: v(0, 1.14, -0.30)))
        root.addChildNode(box(0.24, 0.07, 0.05, P.goldTrim, at: v(0, 1.26, -0.30)))
        root.addChildNode(box(0.13, 0.85, 0.03, P.royalCrimson, at: v(-0.16, 1.15, -0.35)))
        root.addChildNode(box(0.13, 0.85, 0.03, P.royalCrimson, at: v(0.16, 1.15, -0.35)))
        return root
    }

    static func makeRival() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.rivalPlum, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(sphere(0.44, P.rivalPlum, at: v(0, 0.78, 0)))
        root.addChildNode(sphere(0.18, P.goldTrim, at: v(-0.34, 1.34, 0)))
        root.addChildNode(sphere(0.18, P.goldTrim, at: v(0.34, 1.34, 0)))
        root.addChildNode(torus(0.30, 0.09, P.ermine, at: v(0, 1.62, 0)))
        root.addChildNode(cylinder(0.29, 0.11, P.inkBlack, at: v(0, 2.05, 0)))
        root.addChildNode(cone(0.01, 0.045, 0.46, P.plasterWhite, at: v(0.17, 2.24, 0.05), euler: e(0, 0, -34)))
        root.addChildNode(box(0.035, 0.88, 0.035, P.steelGrey, at: v(0.45, 0.72, 0.14), euler: e(0, 0, 22)))
        root.addChildNode(torus(0.065, 0.02, P.goldTrim, at: v(0.47, 1.16, 0.14), euler: e(0, 90, 0)))
        return root
    }

    static func makeServant() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.servantDun, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(box(0.54, 0.72, 0.04, P.ermine, at: v(0, 0.76, -0.35)))
        root.addChildNode(torus(0.33, 0.04, P.timberDark, at: v(0, 1.06, 0)))
        root.addChildNode(cylinder(0.27, 0.14, P.ermine, at: v(0, 2.01, 0)))
        root.addChildNode(cylinder(0.03, 1.55, P.timberDark, at: v(0.42, 0.78, 0.08), euler: e(0, 0, 7)))
        root.addChildNode(box(0.26, 0.24, 0.11, P.strawGold, at: v(0.33, 0.12, 0.08), euler: e(0, 0, 7)))
        root.addChildNode(capsule(0.19, 0.55, P.strawGold, at: v(-0.46, 0.26, 0.12), euler: e(74, 0, 0)))
        return root
    }

    static func makeLady(faction: Faction) -> SCNNode {
        let root = SCNNode()
        root.addChildNode(cone(0.34, 0.84, 1.18, faction.field, at: v(0, 0.59, 0)))
        root.addChildNode(capsule(0.36, 1.5, faction.field, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(box(0.38, 0.52, 0.06, P.goldTrim, at: v(0, 1.24, -0.31)))
        root.addChildNode(torus(0.29, 0.075, P.ermine, at: v(0, 1.60, 0)))
        root.addChildNode(box(0.36, 0.32, 0.32, P.inkBlack, at: v(0, 1.92, 0)))
        root.addChildNode(pyramid(0.36, 0.20, 0.12, P.parchment, at: v(0, 2.06, -0.15), euler: e(90, 0, 0)))
        root.addChildNode(box(0.34, 0.52, 0.07, P.inkBlack, at: v(0, 1.72, 0.23)))
        root.addChildNode(cylinder(0.17, 0.03, P.parchment, at: v(0.46, 1.16, -0.10), euler: e(90, 0, 20)))
        root.addChildNode(cylinder(0.02, 0.14, P.timberDark, at: v(0.46, 1.00, -0.10), euler: e(0, 0, 20)))
        return root
    }

    static func makeGuard(faction: Faction) -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.timberDark, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(capsule(0.38, 0.82, P.steelGrey, at: v(0, 1.26, 0)))
        root.addChildNode(box(0.46, 0.82, 0.04, faction.field, at: v(0, 1.24, -0.39)))
        root.addChildNode(box(0.46, 0.82, 0.04, faction.field, at: v(0, 1.24, 0.39)))
        root.addChildNode(sphere(0.325, P.steelGrey, at: v(0, 1.84, 0)))
        root.addChildNode(torus(0.325, 0.05, P.steelGrey, at: v(0, 1.70, 0)))
        root.addChildNode(cylinder(0.035, 2.45, P.timberDark, at: v(0.49, 1.22, 0.10)))
        root.addChildNode(box(0.24, 0.36, 0.03, P.steelGrey, at: v(0.49, 2.30, 0.10)))
        root.addChildNode(cone(0, 0.04, 0.28, P.steelGrey, at: v(0.49, 2.59, 0.10)))
        return root
    }

    /// The player courtier (seen from behind): a neutral figure distinct from
    /// the cast.
    static func makePlayer() -> SCNNode {
        let root = SCNNode()
        root.addChildNode(capsule(0.36, 1.5, P.playerBlue, at: v(0, 0.90, 0)))
        root.addChildNode(sphere(0.29, P.skinTone, at: v(0, 1.78, 0)))
        root.addChildNode(box(0.50, 0.10, 0.30, P.ermine, at: v(0, 1.56, -0.02)))
        root.addChildNode(cylinder(0.28, 0.10, P.inkBlack, at: v(0, 2.02, 0)))
        return root
    }

    // MARK: Primitive helpers (position = primitive centre; euler in degrees)

    private static func v(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
        SCNVector3(x: x, y: y, z: z)
    }
    private static func e(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
        let k = Float.pi / 180
        return SCNVector3(x: x * k, y: y * k, z: z * k)
    }
    private static func configure(_ node: SCNNode, _ color: UIColor, _ pos: SCNVector3, _ euler: SCNVector3) -> SCNNode {
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = pos
        node.eulerAngles = euler
        node.castsShadow = true
        return node
    }

    private static func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ c: UIColor,
                            at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNBox(width: w, height: h, length: d, chamferRadius: 0.02)), c, pos, euler)
    }
    private static func sphere(_ r: CGFloat, _ c: UIColor,
                               at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNSphere(radius: r)), c, pos, euler)
    }
    private static func capsule(_ capR: CGFloat, _ h: CGFloat, _ c: UIColor,
                                at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNCapsule(capRadius: capR, height: h)), c, pos, euler)
    }
    private static func cone(_ top: CGFloat, _ bot: CGFloat, _ h: CGFloat, _ c: UIColor,
                             at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNCone(topRadius: top, bottomRadius: bot, height: h)), c, pos, euler)
    }
    private static func cylinder(_ r: CGFloat, _ h: CGFloat, _ c: UIColor,
                                 at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNCylinder(radius: r, height: h)), c, pos, euler)
    }
    private static func torus(_ R: CGFloat, _ p: CGFloat, _ c: UIColor,
                              at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNTorus(ringRadius: R, pipeRadius: p)), c, pos, euler)
    }
    private static func tube(_ ri: CGFloat, _ ro: CGFloat, _ h: CGFloat, _ c: UIColor,
                             at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNTube(innerRadius: ri, outerRadius: ro, height: h)), c, pos, euler)
    }
    private static func pyramid(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ c: UIColor,
                                at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        configure(SCNNode(geometry: SCNPyramid(width: w, height: h, length: d)), c, pos, euler)
    }
}
