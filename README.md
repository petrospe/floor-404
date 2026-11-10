# Floor 404 — The Null Pointer

**First-person liminal walking simulator** built with **Godot 4**. Inspired by the atmosphere of abandoned corporate spaces and dreamlike architectural repetition: no monsters, weapons, visible player body, or persistent HUD. The tension comes from isolation, repeating rooms, rain, lighting, and unsettling spatial design.

> **Important project status:** **Floor 4 is a working playable prototype.** The complete multi-floor progression, electrical-panel puzzle, persistent elevator unlocks, save/Continue system, Basement 2 Master Panel, and Ground Floor ending are **target features**. Do **not** mistake the current two-cabin same-floor elevator prototype for the final elevator mechanic.

## Documentation map — read before implementing

| File | Purpose |
|---|---|
| [`gameplay_progression.md`](gameplay_progression.md) | **Authoritative gameplay rules**: floor route, panel puzzle, permanent unlocks, save/Continue, ending |
| [`level_design_logic.md`](level_design_logic.md) | **Authoritative level rules**: 4 m grid, mandatory rooms, special floors, atmosphere |
| [`architecture_design_patterns.md`](architecture_design_patterns.md) | **Target technical contracts**: Godot services, persistence, floor transitions, AI agent rules |
| `README.md` | Repository entry point, existing prototype inventory, toolchain, workflow |

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
  .cursorrules
  floor404.code-workspace
  godot_project/
    project.godot
    scenes/
      office_level.tscn          # Existing playable Floor 4 prototype
      test_level.tscn            # Existing test scene
      player.tscn
      modular/                  # Existing 4 m kit
      floors/                   # Planned
      ground_floor_ending.tscn  # Planned
    scripts/
      office_level.gd           # Existing procedural Floor 4 builder
      player.gd
      elevator_doors.gd
      elevator_panel.gd         # Existing LEGACY same-floor elevator prototype
      interactable.gd
      door.gd
      checkpoint_zone.gd
      hazard_zone.gd
      ui/fade_overlay.gd
      game_state.gd             # Planned
      save_manager.gd           # Planned
      floor_registry.gd         # Planned
      floor_transition.gd       # Planned
      electrical_panel.gd       # Planned
  assets_src/                   # Optional editable source art
  docs/                         # Optional supporting notes
```

The `assets_src/` and `docs/` folders may need to be created; do not assume they exist. Godot's `.godot/` cache should not be committed.

## Opening and running the current prototype

1. Open Godot's Project Manager and import `godot_project/project.godot`.
2. The existing project documentation identifies `scenes/office_level.tscn` as the main scene. Verify the current `project.godot` setting before running.
3. Press **F5** to play the office. To test the basic player scene, open `scenes/test_level.tscn` and press **F6**.
4. Controls: **WASD** move, **Mouse** look, **E** interact, **Esc** release/recapture mouse. No jump or crouch.
5. Existing `scripts/office_level.gd` procedurally builds the Level 4 office from modular assets. Do not discard this working scene when introducing other floors.

## What exists vs. what must change

| Feature | Current documented state | Target state |
|---|---|---|
| Floor 4 office | Playable prototype | Retain and integrate into full game |
| First-person movement, interaction ray | Existing | Retain |
| Doors and elevator door animations | Existing | Retain/reuse |
| Elevator button travel | **LEGACY: transports player to the other cabin in the same floor** | **REPLACE: loads destination floor scene**, only after corresponding panel repair |
| Checkpoint and hazard fade | Existing prototype | Retain as **temporary** respawn, separate from saved Continue |
| Eight-pair electrical panel puzzles | Design specification | Implement and test |
| Permanent elevator activation | Design specification | Implement via central state and autosave |
| Multi-floor progression F01–F15, B1–B2 | Design specification | Implement per authoritative floor graph |
| Ground Floor ending | Design specification | Implement luminous hall, exit door, white light, credits |

**Critical correction:** The old phrase “E rides to the other car” describes a prototype, **not intended gameplay**. The final `elevator_panel.gd` must resolve an explicit destination floor, check the associated permanent unlock, load the destination scene, and spawn the player safely. This change must not be reported as already implemented.

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
| `scripts/elevator_panel.gd` | **Legacy prototype**, requires inter-floor migration |
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

## Save system — design, not yet confirmed implemented

- New Game starts Floor 4.
- A completed eight-wire panel permanently activates its mapped elevator and **autosaves immediately**.
- Continue starts at the **floor of the most recently completed panel** (last elevator activation floor), at a safe designated spawn point.
- Wrong wire choices have unlimited retries and preserve earlier correct choices **while the UI remains open**; closing an incomplete puzzle resets it.
- Partial puzzle connections and temporary hazard checkpoints are never saved.
- The Basement 2 Master Panel remotely activates Floor 1 → Ground Floor; Ground Floor has **no panel** and is the ending.

See `gameplay_progression.md` for full rules and `architecture_design_patterns.md` for save format and Godot integration.

## Migration order for developers and AI agents

1. Inspect current `project.godot`, scenes and scripts; capture a working Floor 4 baseline.
2. Introduce stable floor/elevator/panel IDs and a floor registry; validate routes.
3. Implement the electrical-panel puzzle with unlimited retries and cancellation reset.
4. Implement central GameState and atomic save/Continue.
5. Replace same-floor elevator teleport with safe cross-scene travel, retaining existing doors/animations.
6. Build the remaining floors, Basement 2 Master Panel, and Ground Floor ending.
7. Regression-test old movement/doors/footsteps/checkpoints and new persistence/route rules.

Do not mark a planned feature “implemented” until tested in Godot. Do not silently invent rules when the design documents are explicit or unresolved.
