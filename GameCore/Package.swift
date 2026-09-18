// swift-tools-version:5.9
import PackageDescription

// Pure-Swift game logic (no SwiftUI/SceneKit), so it builds and `swift test`s on
// Linux as well as inside the iOS app. The iOS app depends on this package and
// wraps it in the SceneKit world + SwiftUI HUD.
let package = Package(
    name: "GameCore",
    products: [
        .library(name: "GameCore", targets: ["GameCore"])
    ],
    targets: [
        .target(name: "GameCore"),
        .testTarget(name: "GameCoreTests", dependencies: ["GameCore"])
    ]
)
