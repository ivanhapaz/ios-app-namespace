import SwiftUI

/// A fixed on-screen thumbstick (bottom-left). Dragging it writes a normalised
/// direction into the shared `MovementInput` that the 3D scene polls each frame.
struct JoystickView: View {
    let input: MovementInput

    @State private var knob: CGSize = .zero
    @State private var active = false

    private let radius: CGFloat = 62
    private let knobSize: CGFloat = 54

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .overlay(Circle().stroke(Color.white.opacity(0.30), lineWidth: 2))

            Circle()
                .fill(Color.white.opacity(active ? 0.42 : 0.28))
                .frame(width: knobSize, height: knobSize)
                .offset(knob)
        }
        .frame(width: radius * 2, height: radius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    active = true
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let distance = max(0.0001, hypot(dx, dy))
                    let clamped = min(distance, radius)
                    let nx = dx / distance
                    let ny = dy / distance
                    knob = CGSize(width: nx * clamped, height: ny * clamped)
                    let magnitude = clamped / radius
                    // Screen y grows downward; invert so "up" means forward.
                    input.vector = CGVector(dx: nx * magnitude, dy: -ny * magnitude)
                }
                .onEnded { _ in
                    active = false
                    knob = .zero
                    input.vector = .zero
                }
        )
    }
}
