import SwiftUI

/// Hosts the 3D SceneKit world and overlays the SwiftUI HUD (title, joystick,
/// item bar). The `MovementInput` is held here as stable state so the joystick
/// and the scene controller share the same instance across view updates.
struct GameContainerView: View {
    @State private var input = MovementInput()

    var body: some View {
        ZStack {
            GameSceneView(input: input)
                .ignoresSafeArea()

            GameHUD()

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    JoystickView(input: input)
                    Spacer()
                    ItemBar()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .statusBarHidden(true)
    }
}
