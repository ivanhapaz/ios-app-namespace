import SceneKit
import UIKit

/// Shared primitive-node builders for set dressing and props. Position is the
/// primitive's centre; rotations are given in degrees. Flat materials, chamfered
/// boxes — matching the designer's 3D Primitive Kit conventions.
enum Prim {

    static func v(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
        SCNVector3(x: x, y: y, z: z)
    }

    /// Euler angles from degrees.
    static func deg(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
        let k = Float.pi / 180
        return SCNVector3(x: x * k, y: y * k, z: z * k)
    }

    private static func cfg(_ node: SCNNode, _ color: UIColor, _ pos: SCNVector3, _ euler: SCNVector3) -> SCNNode {
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = pos
        node.eulerAngles = euler
        node.castsShadow = true
        return node
    }

    static func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ c: UIColor,
                    at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0),
                    chamfer: CGFloat = 0.02) -> SCNNode {
        cfg(SCNNode(geometry: SCNBox(width: w, height: h, length: d, chamferRadius: chamfer)), c, pos, euler)
    }
    static func sphere(_ r: CGFloat, _ c: UIColor,
                       at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNSphere(radius: r)), c, pos, euler)
    }
    static func capsule(_ capR: CGFloat, _ h: CGFloat, _ c: UIColor,
                        at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNCapsule(capRadius: capR, height: h)), c, pos, euler)
    }
    static func cone(_ top: CGFloat, _ bot: CGFloat, _ h: CGFloat, _ c: UIColor,
                     at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNCone(topRadius: top, bottomRadius: bot, height: h)), c, pos, euler)
    }
    static func cyl(_ r: CGFloat, _ h: CGFloat, _ c: UIColor,
                    at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNCylinder(radius: r, height: h)), c, pos, euler)
    }
    static func torus(_ R: CGFloat, _ p: CGFloat, _ c: UIColor,
                      at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNTorus(ringRadius: R, pipeRadius: p)), c, pos, euler)
    }
    static func tube(_ ri: CGFloat, _ ro: CGFloat, _ h: CGFloat, _ c: UIColor,
                     at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNTube(innerRadius: ri, outerRadius: ro, height: h)), c, pos, euler)
    }
    static func pyramid(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ c: UIColor,
                        at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNNode {
        cfg(SCNNode(geometry: SCNPyramid(width: w, height: h, length: d)), c, pos, euler)
    }
    /// A flat plane. Emissive planes (stained glass, window light) pass an
    /// `emission` colour so they glow without a light behind them.
    static func plane(_ w: CGFloat, _ h: CGFloat, _ c: UIColor,
                      at pos: SCNVector3, euler: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0),
                      emission: UIColor? = nil, emissionIntensity: CGFloat = 0.35,
                      doubleSided: Bool = false) -> SCNNode {
        let node = cfg(SCNNode(geometry: SCNPlane(width: w, height: h)), c, pos, euler)
        let mat = node.geometry?.firstMaterial
        mat?.isDoubleSided = doubleSided
        if let emission = emission {
            mat?.emission.contents = emission
            mat?.emission.intensity = emissionIntensity
        }
        node.castsShadow = false
        return node
    }

    /// A point light (candles, fire, chandelier).
    static func omni(intensity: CGFloat, color: UIColor, distance: CGFloat,
                     at pos: SCNVector3) -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.color = color
        light.intensity = intensity
        light.attenuationEndDistance = distance
        let node = SCNNode()
        node.light = light
        node.position = pos
        return node
    }
}
