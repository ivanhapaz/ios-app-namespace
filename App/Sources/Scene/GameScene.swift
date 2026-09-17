import SpriteKit
import UIKit

/// Phase 1 world: a single SKScene that renders one static room at a time and
/// swaps its contents when the player walks through a doorway. We deliberately
/// use one scene (rather than one SKScene per room) so that shared state — the
/// player, and later the meters/clock — lives in one place and survives room
/// changes.
final class GameScene: SKScene {

    // MARK: Tunables

    private let playerSpeed: CGFloat = 340        // points per second
    private let playerRadius: CGFloat = 20
    private let sideMargin: CGFloat = 26
    private let topMargin: CGFloat = 84           // leaves headroom for a future HUD
    private let bottomMargin: CGFloat = 30
    private let doorWidth: CGFloat = 116
    private let triggerDepth: CGFloat = 52
    private let wallThickness: CGFloat = 8

    // MARK: State

    private var currentRoom: RoomID = .greatHall
    private var previousRoom: RoomID?

    private let roomLayer = SKNode()              // room-specific visuals, rebuilt per room
    private let player = SKNode()
    private var facingNub: SKShapeNode!
    private let joystick = Joystick()

    private var facing = CGVector(dx: 0, dy: -1)  // top-down; starts facing "down"
    private var lastUpdateTime: TimeInterval = 0
    private var transitionReadyAt: TimeInterval = 0

    /// A doorway resolved into scene geometry for the current layout.
    private struct DoorTrigger {
        let rect: CGRect
        let entry: CGPoint
        let doorway: Doorway
    }
    private var doorTriggers: [DoorTrigger] = []

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
        scaleMode = .resizeFill

        roomLayer.zPosition = 0
        addChild(roomLayer)

        buildPlayer()
        addChild(player)

        joystick.zPosition = 1000
        addChild(joystick)

        loadRoom(currentRoom, from: nil)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Re-lay the current room to the new bounds and keep the player inside.
        guard roomLayer.parent != nil else { return }
        layoutCurrentRoom(placePlayer: false)
    }

    // MARK: Building

    private func buildPlayer() {
        let body = SKShapeNode(ellipseOf: CGSize(width: playerRadius * 2, height: playerRadius * 2 + 8))
        body.fillColor = SKColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
        body.strokeColor = SKColor(white: 0.95, alpha: 0.9)
        body.lineWidth = 2
        body.zPosition = 0

        let nub = SKShapeNode(circleOfRadius: 5)
        nub.fillColor = SKColor(red: 0.95, green: 0.86, blue: 0.55, alpha: 1) // gold facing dot
        nub.strokeColor = .clear
        nub.zPosition = 1
        facingNub = nub

        player.addChild(body)
        player.addChild(nub)
        player.zPosition = 500
    }

    /// Rebuild all room-specific nodes and door triggers for `currentRoom`.
    /// When `placePlayer` is true the player is moved to the correct entry
    /// doorway (used on transitions); on a pure resize we leave them put.
    private func layoutCurrentRoom(placePlayer: Bool) {
        roomLayer.removeAllChildren()
        doorTriggers.removeAll()

        let def = RoomCatalog.room(currentRoom)
        let floorRect = currentFloorRect()

        // Floor with a "wall" border.
        let floor = SKShapeNode(rect: floorRect, cornerRadius: 18)
        floor.fillColor = SKColor(red: def.floor.r, green: def.floor.g, blue: def.floor.b, alpha: 1)
        floor.strokeColor = SKColor(white: 0.08, alpha: 1)
        floor.lineWidth = wallThickness
        floor.zPosition = 0
        roomLayer.addChild(floor)

        // Title + resident subtitle, near the top of the floor.
        let title = SKLabelNode(fontNamed: "Georgia-Bold")
        title.text = def.name
        title.fontSize = 30
        title.fontColor = SKColor(white: 0.12, alpha: 1)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: floorRect.midX, y: floorRect.maxY - 42)
        title.zPosition = 2
        roomLayer.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "Georgia")
        subtitle.text = def.subtitle
        subtitle.fontSize = 15
        subtitle.fontColor = SKColor(white: 0.20, alpha: 1)
        subtitle.verticalAlignmentMode = .center
        subtitle.position = CGPoint(x: floorRect.midX, y: floorRect.maxY - 68)
        subtitle.zPosition = 2
        roomLayer.addChild(subtitle)

        // Doorways.
        for doorway in def.doorways {
            let geo = doorGeometry(for: doorway.edge, in: floorRect)
            drawDoor(doorway, at: geo.doorRect, isVertical: geo.isVertical)
            doorTriggers.append(DoorTrigger(rect: geo.triggerRect, entry: geo.entry, doorway: doorway))
        }

        if placePlayer {
            player.position = entryPoint(in: floorRect)
        } else {
            player.position = clampToFloor(player.position, floorRect: floorRect)
        }
        updateFacingNub()
    }

    private func drawDoor(_ doorway: Doorway, at rect: CGRect, isVertical: Bool) {
        let door = SKShapeNode(rect: rect, cornerRadius: 6)
        if doorway.locked {
            door.fillColor = SKColor(red: 0.30, green: 0.30, blue: 0.33, alpha: 1) // cold sealed stone
            door.strokeColor = SKColor(white: 0.10, alpha: 1)
        } else {
            door.fillColor = SKColor(red: 0.36, green: 0.24, blue: 0.16, alpha: 1) // warm wood
            door.strokeColor = SKColor(red: 0.20, green: 0.13, blue: 0.08, alpha: 1)
        }
        door.lineWidth = 2
        door.zPosition = 1
        roomLayer.addChild(door)

        if doorway.locked, let lock = symbolNode("lock.fill", pointSize: 22, color: SKColor(white: 0.85, alpha: 0.95)) {
            lock.position = CGPoint(x: rect.midX, y: rect.midY)
            lock.zPosition = 3
            roomLayer.addChild(lock)
        }

        // A faint label naming where an open doorway leads.
        if !doorway.locked {
            let dest = RoomCatalog.room(doorway.destination)
            let tag = SKLabelNode(fontNamed: "Georgia")
            tag.text = dest.name
            tag.fontSize = 11
            tag.fontColor = SKColor(white: 0.95, alpha: 0.9)
            tag.verticalAlignmentMode = .center
            tag.horizontalAlignmentMode = .center
            tag.zPosition = 3
            tag.position = CGPoint(x: rect.midX, y: rect.midY)
            if !isVertical { tag.zRotation = .pi / 2 } // read along the side walls
            roomLayer.addChild(tag)
        }
    }

    // MARK: Geometry

    private func currentFloorRect() -> CGRect {
        return CGRect(
            x: sideMargin,
            y: bottomMargin,
            width: max(1, size.width - sideMargin * 2),
            height: max(1, size.height - topMargin - bottomMargin)
        )
    }

    private struct DoorGeo {
        let doorRect: CGRect     // the visible door straddling the wall
        let triggerRect: CGRect  // walkable zone inside the room that fires a transition
        let entry: CGPoint       // where the player appears when entering via this edge
        let isVertical: Bool     // true for north/south doors (wide), false for east/west (tall)
    }

    private func doorGeometry(for edge: Edge, in floor: CGRect) -> DoorGeo {
        let entryInset = triggerDepth + playerRadius + 10
        let doorSpan: CGFloat = 24 // how far the visible door straddles the wall line

        switch edge {
        case .north:
            let x = floor.midX - doorWidth / 2
            return DoorGeo(
                doorRect: CGRect(x: x, y: floor.maxY - doorSpan / 2, width: doorWidth, height: doorSpan),
                triggerRect: CGRect(x: x, y: floor.maxY - triggerDepth, width: doorWidth, height: triggerDepth),
                entry: CGPoint(x: floor.midX, y: floor.maxY - entryInset),
                isVertical: true
            )
        case .south:
            let x = floor.midX - doorWidth / 2
            return DoorGeo(
                doorRect: CGRect(x: x, y: floor.minY - doorSpan / 2, width: doorWidth, height: doorSpan),
                triggerRect: CGRect(x: x, y: floor.minY, width: doorWidth, height: triggerDepth),
                entry: CGPoint(x: floor.midX, y: floor.minY + entryInset),
                isVertical: true
            )
        case .east:
            let y = floor.midY - doorWidth / 2
            return DoorGeo(
                doorRect: CGRect(x: floor.maxX - doorSpan / 2, y: y, width: doorSpan, height: doorWidth),
                triggerRect: CGRect(x: floor.maxX - triggerDepth, y: y, width: triggerDepth, height: doorWidth),
                entry: CGPoint(x: floor.maxX - entryInset, y: floor.midY),
                isVertical: false
            )
        case .west:
            let y = floor.midY - doorWidth / 2
            return DoorGeo(
                doorRect: CGRect(x: floor.minX - doorSpan / 2, y: y, width: doorSpan, height: doorWidth),
                triggerRect: CGRect(x: floor.minX, y: y, width: triggerDepth, height: doorWidth),
                entry: CGPoint(x: floor.minX + entryInset, y: floor.midY),
                isVertical: false
            )
        }
    }

    /// Where to drop the player when entering `currentRoom` from `previousRoom`.
    private func entryPoint(in floor: CGRect) -> CGPoint {
        if let origin = previousRoom,
           let door = RoomCatalog.doorway(in: currentRoom, leadingTo: origin) {
            return doorGeometry(for: door.edge, in: floor).entry
        }
        return CGPoint(x: floor.midX, y: floor.midY)
    }

    private func clampToFloor(_ point: CGPoint, floorRect: CGRect) -> CGPoint {
        let inset = playerRadius + wallThickness / 2
        let minX = floorRect.minX + inset
        let maxX = floorRect.maxX - inset
        let minY = floorRect.minY + inset
        let maxY = floorRect.maxY - inset
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }

    // MARK: Room transitions

    private func loadRoom(_ room: RoomID, from origin: RoomID?) {
        previousRoom = origin
        currentRoom = room
        layoutCurrentRoom(placePlayer: origin != nil || player.position == .zero)
        // Small cooldown so we don't instantly re-trigger the doorway we arrived at.
        transitionReadyAt = lastUpdateTime + 0.30
    }

    private func transition(through doorway: Doorway) {
        let origin = currentRoom
        loadRoom(doorway.destination, from: origin)
    }

    // MARK: Update loop

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = min(currentTime - lastUpdateTime, 1.0 / 30.0) // clamp to avoid big jumps
        }
        lastUpdateTime = currentTime

        let v = joystick.vector
        let magnitude = hypot(v.dx, v.dy)
        if magnitude > 0.05 {
            facing = CGVector(dx: v.dx / magnitude, dy: v.dy / magnitude)
            let floorRect = currentFloorRect()
            let proposed = CGPoint(
                x: player.position.x + v.dx * playerSpeed * CGFloat(dt),
                y: player.position.y + v.dy * playerSpeed * CGFloat(dt)
            )
            player.position = clampToFloor(proposed, floorRect: floorRect)
            updateFacingNub()
            checkDoorways(currentTime: currentTime)
        }
    }

    private func updateFacingNub() {
        facingNub.position = CGPoint(
            x: facing.dx * (playerRadius - 2),
            y: facing.dy * (playerRadius - 2)
        )
    }

    private func checkDoorways(currentTime: TimeInterval) {
        guard currentTime >= transitionReadyAt else { return }
        for trigger in doorTriggers where !trigger.doorway.locked {
            if trigger.rect.contains(player.position) {
                transition(through: trigger.doorway)
                return
            }
        }
    }

    // MARK: Touch handling (floating joystick)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard joystick.activeTouch == nil, let touch = touches.first else { return }
        joystick.begin(touch: touch, at: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let active = joystick.activeTouch, touches.contains(active) else { return }
        joystick.update(location: active.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let active = joystick.activeTouch, touches.contains(active) else { return }
        joystick.end()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let active = joystick.activeTouch, touches.contains(active) {
            joystick.end()
        }
    }

    // MARK: Helpers

    /// Render an SF Symbol into a sprite with a baked-in tint colour.
    private func symbolNode(_ name: String, pointSize: CGFloat, color: SKColor) -> SKSpriteNode? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        guard let image = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) else {
            return nil
        }
        return SKSpriteNode(texture: SKTexture(image: image))
    }
}
