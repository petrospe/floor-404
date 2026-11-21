# Floor 404

**First-person liminal walking simulator** built with **Godot 4.7**. Tagline: **Reality Not Found.** No monsters, weapons, visible player body, or persistent HUD. The tension comes from an ordinary office after everyone else has gone, then from records and rooms that stop agreeing with each other.

The older subtitle "The Null Pointer" is a retired working title. A luminous Ground Floor ending is also retired. The ending is intentionally undecided. Narrative direction lives in `docs/`. Panel, elevator, and save behavior that is already in the scenes stays as implemented until a change is explicitly approved.

> **Current build:** New Game starts on Floor 4. Floors 3 and 5 have scenes. An eight-wire panel repairs one elevator and autosaves. Continue returns to the floor of the last repaired panel. Floor 4 also has ten readable story entries. Floors 1, 2, 6–15, the basements, and any finale are not built. Floor 4 still pairs its two shafts for the door-present lamp. The cabin button itself loads the destination floor after that elevator's panel is repaired.

## Documentation map — read before implementing

| File | Purpose |
|---|---|
| [`docs/GAME_VISION.md`](docs/GAME_VISION.md) | Current tone, pillars, and ending restraint |
| [`docs/STORY_AND_LORE.md`](docs/STORY_AND_LORE.md) | Current narrative direction. Ambiguity is intentional |
| [`docs/ENVIRONMENTAL_STORYTELLING.md`](docs/ENVIRONMENTAL_STORYTELLING.md) | Notes, terminals, wall text, and the pilot target |
| [`docs/BUILDING_DESIGN.md`](docs/BUILDING_DESIGN.md) | Future floor targets. Do not rebuild a finished floor to match a target count |
| [`docs/PUZZLE_DESIGN.md`](docs/PUZZLE_DESIGN.md) | Future puzzle variety. The existing eight-wire panel stays |
| [`docs/DEVELOPMENT_ROADMAP.md`](docs/DEVELOPMENT_ROADMAP.md) | Verified progress and the next slice of work |
| [`gameplay_progression.md`](gameplay_progression.md) | Implemented panel, elevator, and save rules, plus what is still unbuilt |
| [`level_design_logic.md`](level_design_logic.md) | 4 m grid and the floors that exist |
| [`architecture_design_patterns.md`](architecture_design_patterns.md) | Godot services, including the story catalog |
| `README.md` | Entry point, toolchain, and how to run the current build |

## Toolchain

| Tool | Purpose | Version referenced in existing project documentation |
|---|---|---|
| Godot | Engine and scene editor | 4.7.2, Forward+ |
| Blender | Modular geometry, props | 5.2 LTS |
| BlenderKit / Blendkit | Catalog and imported props | Blender addon 3.21.3; Godot addon 0.7.2 |
| GIMP | Textures and decals | Current stable |
| Audacity | Sound editing | Current stable |
| VS Code / Cursor | Optional GDScript editing | Workspace: `floor404.code-workspace` |

Versions are those recorded in the existing README, not freshly validated installations.

## Project structure (existing and planned)

```text
floor-404/
  README.md
  gameplay_progression.md
  level_design_logic.md
  architecture_design_patterns.md
  docs/                         # Current creative direction
  godot_project/
    project.godot               # Main scene: scenes/title.tscn
    scenes/
      title.tscn
      office_level.tscn         # Floor 4
      floors/floor_03.tscn
      floors/floor_05.tscn      # Small two-panel prototype
      player.tscn
      ui/electrical_panel_ui.tscn
      modular/
    scripts/
      game_state.gd             # Autoload
      save_manager.gd           # Autoload
      floor_registry.gd         # Autoload
      floor_transition.gd       # Autoload
      electrical_panel.gd
      electrical_panel_ui.gd
      story/                    # Catalog, reader, Floor 4 placements
```

Godot's `.godot/` cache should not be committed.

## Opening and running the current prototype

1. Open Godot's Project Manager and import `godot_project/project.godot`.
2. The main scene is `scenes/title.tscn`.
3. Press **F5**. New Game loads Floor 4. Continue loads `user://savegame.json` when that file exists.
4. Controls: **WASD** move, **Mouse** look, **E** interact, **Esc** release/recapture mouse. No jump or crouch. Looking at a note, terminal, or wall line shows `E — Read`.
5. `scripts/office_level.gd` builds Floor 4. `scripts/floor_03_level.gd` builds Floor 3. Do not regenerate either layout to match a target room count.

## What exists vs. what must change

| Feature | Current build | Still ahead |
|---|---|---|
| Floor 4 office | Playable. Story entries are added after the builder finishes | Keep the layout |
| Floor 3 labyrinth | Built in code. Generator report: 85 rooms, fully reachable | Do not regenerate it |
| Floor 5 | Small two-elevator prototype | Broken elevator and stairwell are a later phase |
| Movement and E ray | In `player.gd` | — |
| Eight-wire panel | In the cabinet UI. Correct seats stay until Esc. Completion autosaves | In-editor playtest of every wire case is still worth doing |
| Elevator travel | A repaired button loads the destination scene | Floor 4's two shafts still share one "car is here" lamp |
| Save / Continue | `user://savegame.json`, version 1, plus optional `discovered_entries` | — |
| Floors 1–2, 6–15, basements | Registry ids only. Travel is refused | Build one floor at a time |
| Ending | Not built. The old white-light Ground Floor ending is not the current story | Decide later |
| Journal UI | Discovery ids are saved for it | Do not build the journal yet |

Floor 4's door script can still move the "car is here" lamp between its two shafts. That leftover is separate from the travel button, which loads Floor 3 or Floor 5 after the matching panel is repaired.

## Modular kit (existing convention)

**4 × 4 meters is the required structural grid**, not a suggestion. Godot uses 1 unit = 1 meter. Existing examples:

| Asset | Dimensions / rule |
|---|---|
| `floor_4x4.tscn` | 4×4 m, thickness 0.2 m, walking surface local Y=0 |
| `wall_4x3.tscn` | 4 m wide, 3 m tall, thickness 0.2 m |
| `door_frame.tscn` | 4 m module, 1.2×2.4 m opening |
| Structural placement | Origins at module cell corners, positions in multiples of 4 m on X/Z |

The Godot modular kit includes carpet, concrete, ceiling, walls, windows, and light-panel scenes. The office uses imported `.glb` assets including `carpet_4x4.glb`, `wall_4x3.glb`, `door_frame.glb`, and `door_leaf.glb`. Keep existing origins when replacing meshes.

## Existing gameplay scripts (documented inventory)

| Script | Role |
|---|---|
| `scripts/office_level.gd` | Runtime office floor construction |
| `scripts/player.gd` | Character movement, camera, footsteps, interaction ray |
| `scripts/elevator_doors.gd` | Sliding cabin doors |
| `scripts/elevator_panel.gd` | Loads the registered destination floor when the elevator id is set and repaired. An empty id still hops between two cabins |
| `scripts/interactable.gd` | Interaction base |
| `scripts/door.gd` | Hinged/sliding doors, locks, audio |
| `scripts/checkpoint_zone.gd` | Temporary last safe transform |
| `scripts/hazard_zone.gd` | Fade/respawn |
| `scripts/ui/fade_overlay.gd` | Fullscreen fade |

Current README documentation described hazard fade-out around 0.1 s and fade-in around 0.15 s; actual timing should be checked in the scripts before making it a hard requirement.

## Blender → Godot workflow

1. Use Metric units (scale 1.0); model in meters.
2. Keep structural pivots aligned with the existing 4 m grid. Blender is Z-up; Godot is Y-up; verify the glTF conversion.
3. Apply rotation/scale (`Ctrl+A`) before export.
4. Export glTF 2.0 Binary (`.glb`) and import into the Godot project; preserve original modular pivots.
5. For props, prefer ~1K textures when appropriate for the original lower-end GPU target; profile before increasing resolution.
6. Add and validate collisions for imported models; don't assume downloaded props include gameplay collision.

Existing Blendkit props described in the original project include office and wooden chairs, folding chairs, tables, CRT, keyboard, tower, cooler, fridge, extinguisher, ladder, plants, shelves, copier, cabinet, and camera. Their precise on-disk paths should be verified in the project before editing.

## GIMP and Audacity

- GIMP: keep editable `.xcf` sources outside the Godot project; export PNG textures for walls, grime, signage, windows, and floor materials.
- Audacity: keep editable source projects outside Godot; export ambient fluorescent hum, HVAC, rain, thunder, footsteps by material, and door interaction sounds.
- Surface names currently described: `carpet`, `tile`, `marble`, `concrete`, `water`, `metal`. Verify scene metadata/groups before changing footsteps.

## Save system — implemented

- New Game clears progression and starts on Floor 4.
- Finishing an eight-wire panel activates its mapped elevator and writes the save.
- Continue starts on the floor of the most recently completed panel, at that floor's `ContinueSpawn` marker.
- Wrong wires leave earlier correct seats in place while the board is open. Esc discards an unfinished board. Partial wires are not written.
- Reading a story entry appends its id to `discovered_entries` and writes the same save. That write does not change the Continue floor, repaired panels, or an open puzzle board.
- A save from before `discovered_entries` existed still loads. Unknown story ids are ignored.
- Reading the same entry again does not store a second copy.

The registry still describes a Basement 2 master panel and a ground-floor trip. Those scenes are not built, and the old white-light ending is not the current narrative plan.

## What to build next

1. Play the ten Floor 4 entries in the editor and confirm the words are readable.
2. Leave Floor 5 as the small prototype until its own phase.
3. Add story entries to Floor 3 only after the Floor 4 pilot is accepted in play.
4. Build later floors one at a time. Give them their own puzzles. Do not copy the wire board onto every floor.

Do not mark a feature implemented until it has been tested in Godot. A headless scene load is not a playtest.
