import SwiftUI

/// A full-area, invisible movement control: drag anywhere on the open 3D view
/// to walk. A faint stick appears at the touch origin. Sits *below* the HUD,
/// inventory, and buttons in the ZStack, so their taps still register.
struct MoveCatcher: View {
    let input: MovementInput

    @State private var origin: CGPoint?
    @State private var knob: CGSize = .zero
    private let radius: CGFloat = 60

    var body: some View {
        ZStack {
            Color.clear.contentShape(Rectangle())
            if let origin = origin {
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(origin)
                Circle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 52, height: 52)
                    .position(x: origin.x + knob.width, y: origin.y + knob.height)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let start = origin ?? value.startLocation
                    if origin == nil { origin = start }
                    let dx = value.location.x - start.x
                    let dy = value.location.y - start.y
                    let distance = max(0.0001, hypot(dx, dy))
                    let clamped = min(distance, radius)
                    let nx = dx / distance
                    let ny = dy / distance
                    knob = CGSize(width: nx * clamped, height: ny * clamped)
                    let magnitude = clamped / radius
                    input.vector = CGVector(dx: nx * magnitude, dy: -ny * magnitude)
                }
                .onEnded { _ in
                    origin = nil
                    knob = .zero
                    input.vector = .zero
                }
        )
    }
}
