# Will They Keep Their Head?

A small Tudor-court immersive-sim for iOS. You play a minor courtier newly
arrived at Henry VIII's palace — survive the season without losing your head.
Explore a small palace of connected rooms in third-person 3D; the people in
them present dilemmas, and every choice moves four meters (Royal Favor, Piety,
Wealth, Suspicion). Bottom one out — or let Suspicion max — and you're dragged
to the Tower.

Tone: arch and gossipy — Reigns crossed with a soap opera about beheadings.

## Tech

- **Swift**, with **SwiftUI** for the menus/HUD/dialogue and **SceneKit** for the
  3D world (third-person, walk-through rooms).
- Target **iOS 17+**. **No third-party game engines and no external art assets** —
  the entire 3D world (characters, rooms, props, floors) is built in code from
  SceneKit primitives with flat materials and a few code-generated patterns.
- **Fonts** are iOS built-ins: **Copperplate** for display (the sanctioned
  fallback for Cinzel) and **Iowan Old Style** for body copy. No bundled fonts.
- The Xcode project is generated reproducibly with
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) from [`project.yml`](project.yml),
  so it is not checked in.

## Build phases

Built in order; each phase runs and is playable before the next.

- [x] **Phase 1 — Walkable world.** Data-driven 3D palace (SceneKit): connected
  rooms, third-person follow-camera, on-screen movement, and walk-through
  doorways with fades. The camera faces north, so each room's north wall is
  solid and carries its set piece; doors are on east/west/south.
- [x] **Phase 2 — NPC encounters.** A resident in each room; walk up and a
  dialogue card presents a two-choice dilemma.
- [x] **Phase 3 — Meters.** Choices move the four meters; bottoming one out (or
  maxing Suspicion) ends the run at the Tower.
- [x] **Phase 4 — The schedule clock.** Morning / Midday / Evening; the crowned
  King moves Chapel → Great Hall → Privy Chamber, and can only be petitioned
  when he's present.
- [x] **Phase 5 — Inventory & quest items.** Real inventory; the Boleyn-letter
  quest (lady → Cromwell) with a **delayed consequence** (an arrest two days
  later), plus two gift loops (jewel → King, relic → priest).
- [ ] **Phase 6 — Factions & line-of-sight.** Faction standing, guard/rival
  vision cones, and Suspicion for being seen with the wrong things.

Presentation also follows a design handoff: an "illuminated manuscript" 2D UI
(title / HUD / dilemma / inventory / game-over) and a 3D "primitive kit" for the
cast, room set dressing, floor patterns, a per-room lighting ladder, exterior
half-timber facades, and faction heraldry.

## Building locally

Requires macOS with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
xcodegen generate       # writes TudorCourt.xcodeproj
open TudorCourt.xcodeproj
```

Then run the `TudorCourt` scheme on any iOS 17+ simulator. There's also a helper
that generates, builds, boots a simulator, installs, and launches in one step
(handy on a remote Mac): `./scripts/preview-simulator.sh`.

CI (Namespace macOS runner) generates the project and runs the build + unit
tests on every push.

## Project layout

```
project.yml                 XcodeGen project definition
App/Sources/App/            SwiftUI app entry + the container hosting the SceneKit view
App/Sources/Game/           Game logic & content (GameState, meters, dilemmas, schedule, events)
App/Sources/World/          Room model + floor-plan catalog (plain data)
App/Sources/Scene3D/        SceneKit world: controller, character kit, room dressing,
                            exterior kit, palette, primitive helpers, floor textures
App/Sources/UI/             SwiftUI overlay: theme + HUD, dialogue, inventory, title, game-over
App/Resources/              Asset catalog (accent color, app icon slot)
Tests/                      Unit tests (floor-plan graph, schedule, quest, gifts)
```
