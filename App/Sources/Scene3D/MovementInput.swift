import CoreGraphics

/// Shared movement input, written by the SwiftUI joystick (main thread) and
/// read by the SceneKit render loop each frame. `dx` is right-positive and `dy`
/// is up/forward-positive, each in the range -1...1.
///
/// A reference type so the joystick view and the scene controller share one
/// instance; it is intentionally kept off SwiftUI's observation system since
/// the render loop polls it every frame rather than reacting to changes.
final class MovementInput {
    var vector: CGVector = .zero
}
