# Will They Keep Their Head?

A small Tudor-court immersive-sim for iOS. You play a minor courtier newly
arrived at Henry VIII's palace — survive the season without losing your head.
Explore a small palace of connected rooms in third-person 3D; the people in
them present dilemmas, and every choice moves four meters (Royal Favor, Piety,
Wealth, Suspicion). Bottom one out — or let Suspicion max — and you're dragged
to the Tower.

Tone: arch and gossipy — Reigns crossed with a soap opera about beheadings.

## Tech

- **Swift**, with **SwiftUI** for menus/HUD/dialogue and **SceneKit** for the 3D
  world (third-person, walk-through rooms). Target **iOS 17+**.
- **No third-party game engines and no external art assets** — the 3D world
  (characters, rooms, props, floors) is built in code from SceneKit primitives
  with flat materials and a few code-generated patterns.
- **Fonts** are iOS built-ins: **Copperplate** for display (the sanctioned
  fallback for Cinzel) and **Iowan Old Style** for body copy.
- **Architecture:** all game *logic* lives in a pure-Swift **`GameCore`** package
  (no SwiftUI/SceneKit), so it builds and tests on Linux as well as in the app.
  The iOS app wraps `GameCore` in the SceneKit world + SwiftUI HUD.
- The Xcode project is generated reproducibly with
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) from [`project.yml`](project.yml)
  (which depends on the local `GameCore` package), so it is not checked in.

## Architecture

- **`GameCore/`** — a pure-Swift package with the rules and content: the four
  meters, the day/schedule clock, rooms & floor plan, dilemmas, delayed
  consequences, and a `GameEngine` that ties them together. No Apple UI
  frameworks, so it compiles and `swift test`s anywhere (including Linux).
- **App layer (`App/Sources/`)** — the SceneKit 3D world and SwiftUI overlay.
  `GameState` is a thin `ObservableObject` that wraps `GameEngine` and
  republishes its state to the UI; it's the only place Combine/SwiftUI touch the
  rules. This split keeps the logic portable and cheaply testable.

## Build phases

Built in order; each phase runs and is playable before the next.

- [x] **Phase 1 — Walkable world.** Data-driven 3D palace (SceneKit): connected
  rooms, third-person follow-camera, on-screen movement, walk-through doorways
  with fades. The camera faces north, so each room's north wall is solid and
  carries its set piece; doors are on east/west/south.
- [x] **Phase 2 — NPC encounters.** A resident per room; walk up for a
  two-choice dilemma card.
- [x] **Phase 3 — Meters.** Choices move the four meters; bottoming one out (or
  maxing Suspicion) ends the run at the Tower.
- [x] **Phase 4 — Schedule clock.** Morning / Midday / Evening; the crowned King
  moves Chapel → Great Hall → Privy Chamber and can only be petitioned when
  present.
- [x] **Phase 5 — Inventory & quest items.** The Boleyn-letter quest (lady →
  Cromwell) with a **delayed consequence** (an arrest two days later), plus two
  gift loops (jewel → King, relic → priest).
- [ ] **Phase 6 — Factions & line-of-sight.** Faction standing, guard/rival
  vision cones, and Suspicion for being seen with the wrong things.

Presentation follows a design handoff: an "illuminated manuscript" 2D UI and a
3D "primitive kit" for the cast, room set dressing, floor patterns, a per-room
lighting ladder, exterior half-timber facades, and faction heraldry.

## Building & testing locally

Requires macOS with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
# Fast logic tests — pure Swift, no simulator (works on macOS or Linux):
swift test --package-path GameCore

# The full app:
xcodegen generate       # writes TudorCourt.xcodeproj (depends on GameCore)
open TudorCourt.xcodeproj
```

`./scripts/preview-simulator.sh` generates, builds, boots a simulator, installs,
and launches in one step (handy on a remote Mac).

## CI (Namespace)

A **two-OS pipeline** runs on every push:

- **`gamecore` (Linux, label-driven runner):** `swift test` on the package, with
  a SwiftPM cache and Namespace's cached checkout. Swift is installed in one
  clearly-marked step — the spot a **custom base image** will later replace.
- **`app` (macOS):** generates the project and builds the SwiftUI + SceneKit app,
  with an Xcode/Homebrew cache.

## Project layout

```
project.yml                 XcodeGen project definition (app depends on GameCore)
GameCore/                   Pure-Swift game logic package (rules, content, engine) + tests
App/Sources/App/            SwiftUI app entry + the container hosting the SceneKit view
App/Sources/Game/           GameState (ObservableObject wrapper over GameCore)
App/Sources/Scene3D/        SceneKit world: controller, character kit, room dressing,
                            exterior kit, palette, primitive helpers, floor textures
App/Sources/UI/             SwiftUI overlay: theme + HUD, dialogue, inventory, title, game-over
App/Resources/              Asset catalog (accent color, app icon slot)
```
