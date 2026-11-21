# Floor 404 — Development Roadmap

## Status definitions
- **Reported**: described by the project owner, not independently verified here.
- **Verified**: confirmed by inspecting project files. Not the same as an in-engine playtest.
- **Playtest pending**: implemented in code, not exercised in Godot during the 21 Nov 2026 audit.
- **Planned**: agreed design direction, not implemented.

Audit date: 21 Nov 2026. Engine features in `project.godot`: Godot 4.7, Forward Plus, Jolt Physics. Main scene: `res://scenes/title.tscn`.

## Verified implementation

| Area | Status | Evidence |
|---|---|---|
| Title, New Game, Continue | Verified in code. Playtest pending. | `scripts/title_screen.gd`. New Game resets state, erases `user://savegame.json`, loads `scenes/office_level.tscn`. Continue loads that save and travels to `last_activation_floor` at `ContinueSpawn`. |
| Save format | Verified in code. Playtest pending. | `scripts/save_manager.gd`, `scripts/game_state.gd`. Schema version 1. Atomic write through `savegame.tmp`. Unknown panel/elevator IDs are dropped. Partial wire state is not written. `game_completed` is stored and never set. |
| Floor graph | Verified in code. | `scripts/floor_registry.gd`. IDs `F01`–`F15`, `B1`, `B2`, `G`. Only `F03`, `F04`, and `F05` have scene paths. Other travel attempts log an error and do not change floors. |
| Electrical panel | Verified in code. Playtest pending. | Eight wires. Pairing is a stable shuffle of `panel_id`. A correct seat stays while the UI is open. A wrong seat does not clear earlier seats. Esc discards an unfinished board. Completion calls `GameState.complete_panel`, turns the wall lamp green, activates the mapped elevator, and writes the save. A finished panel reopens read-only. |
| Floor 4 panels and elevators | Verified in code. | `F04_DOWN_PANEL` / `F04_DOWN` toward Floor 3, `F04_UP_PANEL` / `F04_UP` toward Floor 5. The imported cabinet forwards E to the nearest panel. The 3D node is the status lamp. The puzzle is `scenes/ui/electrical_panel_ui.tscn`. |
| Floor 3 | Verified by generator report from the current script. Playtest pending. | `scenes/floors/floor_03.tscn` runs `scripts/floor_03_level.gd`. Report written 18 Nov 2026, after that script's last edit: 85 rooms, 203 hall cells, 506/506 cells reachable, 2 non-panel one-door rooms. Both panels and both elevators are present. Storage and utility ladders use the Blendkit ladder at its native size, the same as Floor 4 (1.84 m tall, 1.15 m deep). |
| Floor 4 layout | Verified by reading the builder. Not a stored room count. | `scenes/office_level.tscn` runs `scripts/office_level.gd`. Static reconstruction of its cell and wall marks: 676 walkable cells (66 in the original south wing, 610 in the expansion), two elevator cars, one long corridor, and about 82 doorway-separated volumes. This is larger than the 65-room design target. Do not rebuild it to match that target. |
| Floor 5 | Verified in code. It is a small prototype. | `scenes/floors/floor_05.tscn` uses `scripts/standard_floor.gd` with `floor_id = F05`. About 22 cells, two working elevators, two panels, one locked red EXIT. This is not the broken-elevator / stairwell floor in the new design. |
| Movement and interaction | Verified in code. | `scripts/player.gd`. WASD, mouse look, E, no jump, no body mesh. Ray length 2.5 m. No general interaction prompt. `E — Read` appears only while the ray is on a story entry. No InputMap `interact` action. |
| Door knobs | Measured in Godot 4.7.2 and shown in a rendered close-up of both door faces. Not walked in play. | `models/blendkit/spherical_handle.glb` is the free Blendkit spherical handle. `scenes/modular/door_frame.tscn` uses it on both faces of the shared door (floors 3, 4, and 5). Stall bars and the red EXIT bars on floors 3 and 4 use the same mesh at the old handle's width. Leaf size, collision, and swing are unchanged. Floor 5's locked EXIT had no handle mesh. |
| Environmental storytelling | Verified by a Godot 4.7.2 load of Floor 4 and rendered close-ups of all ten entries. | `scripts/story/`. Ten catalog ids, reader, prompt, and placements. Two story CRTs are opaque black with green text. The other 57 CRTs keep their original emission. |

## Do not rewrite
- `scripts/office_level.gd` and `scenes/office_level.tscn` geometry, cabinet positions, panel IDs, and spawn markers.
- `scripts/floor_03_level.gd` and `scenes/floors/floor_03.tscn`.
- Panel solution rules, elevator IDs, and the save schema's existing fields.
- `scripts/standard_floor.gd` still contains an unused Floor 3 layout. The live Floor 3 is `floor_03_level.gd`. Leave that unused branch alone unless a cleanup is approved.

## Documentation
`docs/` governs tone, ambiguity, future puzzles, and the ending. The root specs now describe the implemented panel, elevator, and save behavior, and they mark the white-light Ground Floor ending as retired. "The Null Pointer" is a retired working title. The title screen subtitle is "Reality Not Found".

Floor 4 still pairs its two shafts as one shared car for the door indicator. The cabin button loads the destination scene once that panel is repaired. Leave that pairing alone during story work.

`scripts/floor_exit.gd` quits the game, and nothing calls it. Floor 4's red doors are solid props. Floor 3's red EXIT uses `LockedExit` and only beeps.

## Phase 0 — Audit and alignment
Done as a file audit on 21 Nov 2026. The follow-up playtest list is still open.

## Phase 1 — Environmental storytelling pilot
Implemented on 21 Nov 2026. A headless load of Floor 4 and a rendered close-up of each entry passed the same day. A person has looked at the Ellis desk, the security CRT, and the service tag in play. This pass did not walk the eight-wire board or ride an elevator.

Shipped:

- `scripts/story/story_catalog.gd` — ten stable ids.
- `scripts/story/story_readable.gd` — terminal, paper, and wall body. Local +Z faces the reader.
- `scripts/story/story_reader.gd` — Esc to close. Suspends movement.
- `scripts/story/story_prompt.gd` — `E — Read` while the ray is on an entry.
- `scripts/story/floor_04_story.gd` — placements, called at the end of Floor 4 startup.
- `GameState.note_discovery` — optional `discovered_entries` on save version 1. Continue floor unchanged.

The protagonist desk is the existing front-middle cubicle at `(2.1, 0, 43.5)`, with the nameplate `A. ELLIS / DESK 4-12` on its south face. Spawn did not move.

Headless run of a temporary audit scene (removed after the run), Godot 4.7.2:

- An old save dictionary without `discovered_entries` kept `F04_UP_PANEL`, `F04_UP`, and Continue floor `F03`.
- Duplicate and unknown story ids were dropped.
- The first read of an id saved it. The second read did not duplicate it.
- Reload from `user://savegame.json` restored the ids, the panel, and Continue floor `F03`.
- All ten readables were in the built Floor 4. A ray from the readable face hit that readable. None sat within 0.7 m of a panel, cabinet, elevator, or door node origin.
- The nameplate's +Z points south, toward the approach from spawn.

A later run the same day rendered a close-up of every entry with the Forward+ renderer. The words were upright and inside their plates. The meeting-room lines were scaled down so they no longer ran past the plate. The Ellis and security tubes were black, with no desktop picture behind the green text. The other CRT materials still had emission enabled. Pressing E on each entry with a mouse, and walking the wire board, were not part of that run.

## Phase 2 — Expand and refine
Not started.

1. Add a smaller set of entries to Floor 3 without editing its generator's layout.
2. Measure furnishing cost and navigation on the existing floors before adding props.
3. Redesign Floor 5 only after choosing whether it stays a normal two-panel floor or becomes the broken-elevator / stairwell floor.

## Later phases
Floors 1, 2, 6–15, both basements, and Ground Floor have registry slots and no scenes. Build them one floor at a time, each with its own puzzle idea, after the Floor 4 story pilot is accepted. Keep the ending ambiguous until an ending is explicitly chosen.

## Playtest still required
- Fresh game: both Floor 4 buttons stay inactive until their own panel is finished.
- Wrong wire keeps earlier seats. Esc on an unfinished panel clears them. A finished panel survives relaunch.
- Repaired Floor 4 Down loads Floor 3 at `FromF04`. Repaired Floor 4 Up loads Floor 5 at `FromF04`. Floor 3 Up returns to Floor 4 at `FromF03`. Floor 5 Down returns to Floor 4 at `FromF05`.
- Floor 3 Down and Floor 5 Up do not load a missing floor and do not corrupt the save.
- Continue returns to the floor of the latest repaired panel, at `ContinueSpawn`, not to the player's last coordinates.

## Suggested next task
Walk both Floor 4 wire boards and one elevator trip in play before adding floors or more story entries. Do not edit `office_level.gd`'s room construction for story placement.
