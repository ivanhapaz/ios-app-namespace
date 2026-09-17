import SwiftUI

@main
struct TudorCourtApp: App {
    var body: some Scene {
        WindowGroup {
            GameContainerView()
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
