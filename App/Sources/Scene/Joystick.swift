import SpriteKit

/// A floating on-screen thumbstick. It stays hidden until the player touches
/// the movement area, then appears under their finger and reports a direction
/// vector with magnitude 0...1.
final class Joystick: SKNode {
    private let baseRadius: CGFloat
    private let knobRadius: CGFloat
    private let base: SKShapeNode
    private let knob: SKShapeNode

    /// Current input, normalised to a max magnitude of 1. `.zero` when idle.
    private(set) var vector: CGVector = .zero

    /// The touch currently driving the stick (floating joysticks own one touch).
    private(set) weak var activeTouch: UITouch?

    init(baseRadius: CGFloat = 62, knobRadius: CGFloat = 30) {
        self.baseRadius = baseRadius
        self.knobRadius = knobRadius
        self.base = SKShapeNode(circleOfRadius: baseRadius)
        self.knob = SKShapeNode(circleOfRadius: knobRadius)
        super.init()

        base.fillColor = SKColor(white: 1.0, alpha: 0.10)
        base.strokeColor = SKColor(white: 1.0, alpha: 0.28)
        base.lineWidth = 2
        base.zPosition = 900

        knob.fillColor = SKColor(white: 1.0, alpha: 0.32)
        knob.strokeColor = SKColor(white: 1.0, alpha: 0.5)
        knob.lineWidth = 2
        knob.zPosition = 901

        addChild(base)
        addChild(knob)
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Show the stick centred on the touch and begin tracking it.
    func begin(touch: UITouch, at location: CGPoint) {
        activeTouch = touch
        position = location
        knob.position = .zero
        vector = .zero
        isHidden = false
    }

    /// Update the knob and direction vector from the touch's new location.
    func update(location: CGPoint) {
        let dx = location.x - position.x
        let dy = location.y - position.y
        let distance = max(0.0001, hypot(dx, dy))
        let clamped = min(distance, baseRadius)
        let nx = dx / distance
        let ny = dy / distance

        knob.position = CGPoint(x: nx * clamped, y: ny * clamped)
        // Magnitude scales 0...1 across the base radius.
        let magnitude = clamped / baseRadius
        vector = CGVector(dx: nx * magnitude, dy: ny * magnitude)
    }

    /// Stop tracking and hide the stick.
    func end() {
        activeTouch = nil
        vector = .zero
        knob.position = .zero
        isHidden = true
    }
}
