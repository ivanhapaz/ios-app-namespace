# Will They Keep Their Head?

A small Tudor-court immersive-sim for iOS. You play a minor courtier newly
arrived at Henry VIII's palace — survive the season without losing your head.
Walk a small palace of connected rooms; the people standing in them present
dilemmas, and every choice moves four meters (Royal Favor, Piety, Wealth,
Suspicion). Bottom one out and you're dragged to the Tower.

Tone: arch and gossipy — Reigns crossed with a soap opera about beheadings.

## Tech

- **Swift**, **SwiftUI** for menus/HUD, **SpriteKit** for the top-down world.
- Target **iOS 17+**. No third-party game engines, no external art — SF Symbols
  and simple colored shapes as placeholder art so it runs from day one.
- The Xcode project is generated reproducibly with
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) from [`project.yml`](project.yml),
  so it is not checked in.

## Build phases

Built strictly in order; each phase runs and is playable before the next.

- [x] **Phase 1 — Walkable world.** Six SpriteKit rooms, a thumbstick-controlled
  player, and doorway transitions wired to the floor plan (Chapel & Gardens hold
  locked, story-only passages toward the Tower).
- [ ] Phase 2 — NPC encounters
- [ ] Phase 3 — Meters
- [ ] Phase 4 — The schedule clock
- [ ] Phase 5 — Inventory & quest items
- [ ] Phase 6 — Factions & line-of-sight

## Building locally

Requires macOS with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
xcodegen generate       # writes TudorCourt.xcodeproj
open TudorCourt.xcodeproj
```

Then run the `TudorCourt` scheme on any iOS 17+ simulator. CI (Namespace macOS
runner) generates the project and runs the build + unit tests on every push.

## Project layout

```
project.yml                 XcodeGen project definition
App/Sources/App/            SwiftUI app entry + SpriteKit host view
App/Sources/World/          Room model + floor-plan catalog (plain data)
App/Sources/Scene/          GameScene, floating joystick
App/Resources/              Asset catalog (accent color, app icon slot)
Tests/                      Unit tests (floor-plan graph)
```
