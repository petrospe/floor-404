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
| Title, New Game, Continue | Verified in code. Headless run 23 Nov 2026. Not windowed. | `scripts/title_screen.gd`. New Game resets state, erases `user://savegame.json`, loads `scenes/office_level.tscn`. Continue loads that save and travels to `current_floor` at `ContinueSpawn`. An older save without `current_floor` uses `last_activation_floor`. |
| Save format | Verified in code. Headless run 23 Nov 2026. Not windowed. | `scripts/save_manager.gd`, `scripts/game_state.gd`. Schema version 1. Atomic write through `savegame.tmp`. Unknown panel/elevator IDs are dropped. Partial wire state is not written. `game_completed` is stored and never set. |
| Floor graph | Verified in code. | `scripts/floor_registry.gd`. IDs `F01`–`F15`, `B1`, `B2`, `G`. Only `F03`, `F04`, and `F05` have scene paths. Other travel attempts log an error and do not change floors. |
| Electrical panel | Verified in code. Headless run 23 Nov 2026. Not windowed. | Eight wires. Pairing is a stable shuffle of `panel_id`. A correct seat stays while the UI is open. A wrong seat does not clear earlier seats. Esc discards an unfinished board. Completion calls `GameState.complete_panel`, turns the wall lamp green, activates the mapped elevator, and writes the save. A finished panel reopens read-only. |
| Floor 4 panels and elevators | Verified in code. | `F04_DOWN_PANEL` / `F04_DOWN` toward Floor 3, `F04_UP_PANEL` / `F04_UP` toward Floor 5. The imported cabinet forwards E to the nearest panel. The 3D node is the status lamp. The puzzle is `scenes/ui/electrical_panel_ui.tscn`. |
| Floor 3 | Verified by generator report from the current script. Arrival and return exercised headless on 23 Nov 2026. Rooms not walked. | `scenes/floors/floor_03.tscn` runs `scripts/floor_03_level.gd`. Report written 18 Nov 2026, after that script's last edit: 85 rooms, 203 hall cells, 506/506 cells reachable, 2 non-panel one-door rooms. Both panels and both elevators are present. Storage and utility ladders use the Blendkit ladder at its native size, the same as Floor 4 (1.84 m tall, 1.15 m deep). |
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

## Gameplay regression — 23 Nov 2026
Headless integration run on Godot 4.7.2. A temporary scene drove the live title buttons, cabinet ray, panel UI, elevator travel, and save file, then the scene was removed. No gameplay script or floor layout was changed. The player's existing `user://savegame.json` was copied aside and restored afterward (Continue floor remained `F05`).

Result: 0 failures. This was not a windowed playtest. Nobody looked at the rendered frame, walked with the mouse, or dragged a wire by hand.

Automated checks that passed:

- Project import, every script under `res://scripts`, and every scene, glb, png, and jpg under `res://scenes` and `res://models` loaded. No missing resource and no script error.
- New Game on the title screen starts on Floor 4 with no save. Both panels are incomplete and both elevator lamps are red. Each cabinet opens its own panel.
- On the Floor 4 down board, a wrong socket leaves the board empty. A correct seat stays when the next socket is wrong. Drag seats the next wire without clearing the first. Esc closes an unfinished board and does not write it. Reopening starts empty with the same pairing. Finishing the board turns that lamp green, activates only `F04_DOWN`, and saves the panel, the elevator, and the ten story ids. The up elevator stays inactive. Reopening the finished board is read-only, and Esc leaves the save in place.
- Floor 4 down loads Floor 3 with the player at `FromF04`, on a floor, input restored, and the save floor set to `F03`.
- An unrepaired Floor 3 down does not travel and does not rewrite the save. After `F03_DOWN_PANEL` is solved, the button still stays on Floor 3 because Floor 2 has no scene. The log line `elevator F03_DOWN has no destination scene` is the expected refusal. The save bytes are unchanged.
- Continue from the title loads Floor 3 at `ContinueSpawn` with the panels and all ten story ids.
- Floor 3 up loads Floor 4 at `FromF03`. Floor 4 up then loads Floor 5 at `FromF04`. Both Floor 4 elevators stay active together.
- Solved Floor 5 up stays on Floor 5. The log line `elevator F05_UP has no destination scene` is the expected refusal for Floor 6, and the save is unchanged. Floor 5 down loads Floor 4 at `FromF05`.
- All ten Floor 4 readables have face text, a positive scale, a floor in front of the face, and a ray that hits that readable. Their collision does not overlap a panel, elevator, door, cabinet, or Floor 4 spawn capsule. Opening each one shows the catalog title and body, appends the id once, and does not change the floor or the panels. Reading the first id again does not duplicate it.
- New Game after that progress deletes the save and clears panels and discoveries. The close notification then writes schema version 1 with floor `F04` and empty lists, and that file loads.
- An in-memory save with no `discovered_entries` kept its real panel and elevator. Unknown panel, elevator, and story ids were dropped. A `current_floor` of `F02` fell back to `F04` without dropping the panel.

The only warnings were those three unknown-id drops, produced on purpose by the harness.

## Phase 2 — Expand and refine
Not started. Do not start it on the strength of the headless run.

1. Add a smaller set of entries to Floor 3 without editing its generator's layout.
2. Measure furnishing cost and navigation on the existing floors before adding props.
3. Redesign Floor 5 only after choosing whether it stays a normal two-panel floor or becomes the broken-elevator / stairwell floor.

## Later phases
Floors 1, 2, 6–15, both basements, and Ground Floor have registry slots and no scenes. Build them one floor at a time, each with its own puzzle idea, after the Floor 4 story pilot is accepted. Keep the ending ambiguous until an ending is explicitly chosen.

## Graphical confirmation still open
The 23 Nov 2026 run did not open a window. Still worth doing by hand before any new floor or story work:

- Look at both Floor 4 wire boards. Correct seats should stay visibly connected, and a wrong plug should not pull them off.
- Walk the ten Floor 4 texts and confirm the words are upright and readable. Confirm a note does not catch the player in a doorway.
- Ride Floor 4 down to Floor 3 and Floor 4 up to Floor 5, and ride both back. Confirm the fade and the landing spot.

## Suggested next task
Leave Phase 2 unstarted. The headless regression passed. A windowed look at the wire boards, the ten texts, and one round trip each way is the remaining check. Do not edit `office_level.gd` or `floor_03_level.gd` for that look.
