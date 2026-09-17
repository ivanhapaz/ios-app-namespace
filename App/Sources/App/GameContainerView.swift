import SwiftUI
import SpriteKit

/// Hosts the SpriteKit world. SwiftUI owns the chrome (and, in later phases,
/// the HUD, dialogue sheets, and game-over screen) layered over the scene.
struct GameContainerView: View {
    @State private var scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
    }
}
