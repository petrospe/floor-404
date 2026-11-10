# Floor 404 — Architecture & Design Patterns

> **Status:** Target implementation architecture for Godot 4 / GDScript. Existing Level 4 gameplay must remain playable during migration. This document describes **what to build**, not what is already verified as implemented. All visual assets and scene transformations must comply with the mandatory Visual Orientation and Mirroring Rules defined in AGENTS.md.

## 1. Principles

- First-person liminal walking simulator. No monsters, combat, weapons, persistent HUD, or visible player mesh.
- Godot 4 syntax (`CharacterBody3D`, `Node3D`, `Area3D`, `@export`, `@onready`), modular scenes, signals for decoupling, typed GDScript where practical.
- Respect the 4×4 m structural grid and 3 m standard wall height defined in `level_design_logic.md`.
- Never silently alter existing `office_level.tscn`, `office_level.gd`, player movement, doors, checkpoints, or imported Blender asset origins while adding the new progression system.

## 2. Source of truth

| Topic | Authoritative document |
|---|---|
| Player progression, panel rules, save semantics, ending | `gameplay_progression.md` |
| Floor content, elevator counts, modular kit, atmosphere | `level_design_logic.md` |
| Godot architecture, scene transitions, data contracts | This document |
| Installation, current project files and run instructions | `README.md` |

If existing prototype code contradicts a target gameplay rule, label it **LEGACY PROTOTYPE** and migrate it; do not rewrite the design to match the prototype.

## 3. Recommended scene/services layout (planned; confirm paths before creating)

```text
godot_project/
  project.godot
  scenes/
    office_level.tscn           # Existing playable Floor 4 prototype
    player.tscn
    ground_floor_ending.tscn   # Planned
    floors/                    # Planned separate scenes for other floors
    modular/                   # Existing 4 m kit
    ui/electrical_panel_ui.tscn # Planned
  scripts/
    player.gd                  # Existing
    office_level.gd            # Existing
    elevator_panel.gd          # Existing legacy prototype: migrate
    elevator_doors.gd          # Existing
    checkpoint_zone.gd         # Existing
    hazard_zone.gd             # Existing
    game_state.gd              # Planned Autoload
    save_manager.gd            # Planned persistence service
    floor_registry.gd          # Planned floor/elevator route data
    floor_transition.gd        # Planned safe scene transfer
    electrical_panel.gd        # Planned puzzle controller
```

Paths are **recommendations** except where noted as existing. Inspect the actual repository and preserve its naming and resource paths before coding.

## 4. State ownership

### `GameState` (Autoload)

Owns in-memory authoritative progression: `completed_panels`, `activated_elevators`, `last_activation_floor`, `last_activation_panel`, `game_completed`. All state changes go through methods (e.g., `complete_panel(panel_id)`), not through UI nodes modifying dictionaries directly. Emits `panel_completed(panel_id)` and `elevator_activated(elevator_id)` signals.

### `FloorRegistry` (data/service)

Maps stable IDs to scene paths, elevator transitions, required panel IDs, and safe arrival/Continue spawn marker names. Floor IDs: `F01`…`F15`, `B1`, `B2`, `G`. **No hardcoded special-floor arithmetic**. Every elevator transition has an explicit source/destination. Validate uniqueness and destination existence on startup.

### `SaveManager`

Persists to `user://savegame.json` (or equivalent user-data location) using versioned JSON. Write to temporary file, flush/close, then safely replace the target; validate on load and handle corruption without crashing. Do not store transient puzzle progress or hazard checkpoints. Save **immediately after successful panel completion**; keep last known good state if save fails. On load, reject unknown IDs safely, fall back to Floor 4 for invalid last floor, and log actionable diagnostics.

### `FloorTransition`

Single owner of elevator travel. Resolve elevator ID → destination floor scene → arrival marker. Disable input during transfer, close elevator doors, fade, load destination, position player safely, reset movement velocity and temporary hazard checkpoint, then open doors and restore input. Avoid multiple concurrent transfers. On failure, restore source scene/player control without losing saved progress.

### `ElectricalPanel`

Unique `panel_id`, linked `elevator_id`, deterministic eight-match solution. The UI tracks **only temporary** correct matches. Wrong attempts do not erase correct matches. Closing an incomplete puzzle discards temporary progress. Completion calls `GameState.complete_panel(panel_id)`, which unlocks the linked elevator and requests save; completed panels render as repaired with a green external indicator. The Basement 2 Master Panel links to remote `F01_GROUND` elevator.

## 5. State transition contract

```text
UNREPAIRED panel
  ├─ open UI → IN_PROGRESS (temporary)
  │    ├─ wrong pair → same step, previous correct pairs retained
  │    ├─ exit UI → UNREPAIRED, clear temporary pairs
  │    └─ eighth correct pair → REPAIRED
  └─ reopen → fresh eight-pair puzzle
REPAIRED
  └─ permanently unlock linked elevator + autosave; never revert
```

Elevator button is inactive until `activated_elevators` contains its ID. **Do not treat cabin door opening as an elevator unlock**.

## 6. Save / Continue / respawn separation

- **Persistent checkpoint:** latest *successful panel activation floor*, saved on disk; Continue uses that floor's safe Continue marker.
- **Temporary hazard checkpoint:** latest `CheckpointZone` in the currently loaded scene; respawn only. Never overwrites the saved Continue floor.
- **Scene arrival marker:** destination of a specific elevator transition; distinct from Continue marker.
- If no panel was completed, New Game and Continue start at Floor 4.
- After a completed panel on an earlier floor, that earlier floor becomes the latest Continue floor.

Suggested schema:

```json
{
  "save_version": 1,
  "completed_panels": [],
  "activated_elevators": [],
  "last_activation_floor": "F04",
  "last_activation_panel": null,
  "game_completed": false
}
```

`last_activation_floor = F04` before any repair is a default, not evidence of an activated elevator.

## 7. Elevator migration — required correction

The README currently documents `scripts/elevator_panel.gd` as **“E rides to the other car”**. This is **LEGACY PROTOTYPE behavior** and must not be the final architecture. Replace it with real inter-floor scene transitions governed by persistent panel unlock state. The old two-cabins-on-one-floor behavior may remain only in a clearly marked test scene until migration completes.

Do not label this migration complete until a repaired Floor 4 elevator can load a distinct destination floor scene, the destination spawn is safe, and Continue restores the activation floor after relaunch.

## 8. Interaction and audio

- `E` via player's interaction ray for doors, switches, panel access, and elevator buttons.
- Contextual `[i]` prompt and focused puzzle UI are allowed despite the **no persistent HUD** rule.
- Footsteps by surface (carpet, tile, marble, concrete, water, metal); ambience: fluorescent hum, HVAC, rain, distant thunder.
- Red EXIT doors are always locked with audible feedback.
- Hazards fade quickly and respawn at temporary checkpoint without changing persistent progression.

## 9. AI coding agent rules

1. Read all four `.md` files before proposing changes.
2. Inspect real `.gd`/`.tscn` files and `project.godot`; do not claim a planned file already exists.
3. State affected files and migration risks before editing; preserve Level 4 functionality.
4. Use unique stable floor/panel/elevator IDs, not node display names, for saves.
5. Never unlock an elevator without its panel (except the remote Master Panel's explicit link).
6. Do not invent new routes, floors, UI rules, or endings when the specs are silent; flag the unresolved decision.
7. Deliver incremental features with reproduction steps and acceptance tests.
8. Prefer signals and a single state owner over scene-to-scene hard references.
9. Test fresh save, incorrect wire, puzzle cancellation, successful panel, game restart, travel, backtracking, and ending.

## 10. Acceptance criteria for the architectural migration

- Existing Floor 4 remains playable.
- Save survives full application restart and preserves all repaired panels.
- Partial puzzle state never survives closing its UI.
- Elevator unlocks are per-transition and persist.
- Floor 1 Ground Floor elevator unlocks only after Basement 2 Master Panel completion.
- Travel changes to a distinct floor scene, never merely to another cabin on the same floor.
- A missing floor resource or bad save produces safe fallback, not a soft lock or crash.
