import SwiftUI
import SceneKit

/// Bridges the SceneKit world into SwiftUI. Keeps a continuous render loop so
/// the controller's per-frame `renderer(_:updateAtTime:)` runs for movement and
/// camera follow.
struct GameSceneView: UIViewRepresentable {
    let input: MovementInput

    func makeCoordinator() -> WorldSceneController {
        WorldSceneController(input: input)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.delegate = context.coordinator
        view.isPlaying = true
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
