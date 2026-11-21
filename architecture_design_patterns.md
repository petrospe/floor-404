# Floor 404 — Architecture & Design Patterns

> **Status:** Godot 4.7 / GDScript. The services and the Floor 4 story pilot below are in the project. Unbuilt floors are still targets.  
> **Narrative authority:** `docs/`. Panel, elevator, and save code stays as implemented until a change is approved.  
> Text in the world uses positive scale. `Label3D` is read from its +Z face, aimed at the person standing in front of it.

## 1. Principles

- First-person liminal walking simulator. No monsters, combat, weapons, persistent HUD, or visible player mesh.
- Godot 4 syntax (`CharacterBody3D`, `Node3D`, `Area3D`, `@export`, `@onready`), modular scenes, signals for decoupling, typed GDScript where practical.
- Respect the 4×4 m structural grid and 3 m standard wall height defined in `level_design_logic.md`.
- Never silently alter existing `office_level.tscn`, `office_level.gd`, player movement, doors, checkpoints, or imported Blender asset origins while adding the new progression system.

## 2. Source of truth

| Topic | Authoritative document |
|---|---|
| Tone, ambiguity, ending direction | `docs/GAME_VISION.md`, `docs/STORY_AND_LORE.md` |
| Future puzzles and floor themes | `docs/PUZZLE_DESIGN.md`, `docs/BUILDING_DESIGN.md` |
| Implemented panel, elevator, and save rules | `gameplay_progression.md` and the scripts |
| Grid, finished floors, Floor 5 prototype | `level_design_logic.md` |
| Godot services and the story catalog | This document |
| How to run the project | `README.md` |

Where a finished scene disagrees with a future design target, keep the scene. Floor 4's shared door-lamp between its two shafts is one of those leftovers. The travel button still loads another floor.

## 3. Recommended scene/services layout (planned; confirm paths before creating)

```text
godot_project/
  project.godot                 # Autoloads: FloorRegistry, GameState, SaveManager, FloorTransition
  scenes/
    title.tscn                  # Main scene
    office_level.tscn           # Floor 4
    floors/floor_03.tscn
    floors/floor_05.tscn        # Small prototype
    player.tscn
    ui/electrical_panel_ui.tscn
    modular/
  scripts/
    player.gd
    office_level.gd
    floor_03_level.gd
    standard_floor.gd           # Used by Floor 5. Its Floor 3 branch is unused
    elevator_panel.gd           # Scene travel when elevator_id is set
    elevator_doors.gd
    electrical_panel.gd
    electrical_panel_ui.gd
    game_state.gd
    save_manager.gd
    floor_registry.gd
    floor_transition.gd
    story/story_catalog.gd
    story/story_readable.gd
    story/story_reader.gd
    story/story_prompt.gd
    story/floor_04_story.gd
```

There is no Ground Floor scene. Do not add one as part of a story change.

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
  "last_activation_panel": "",
  "game_completed": false,
  "discovered_entries": []
}
```

`discovered_entries` is optional. A file that omits it loads with an empty list. Version stays 1. `note_discovery` appends one catalog id and writes this same object. It does not change `last_activation_floor`. Duplicate ids are skipped on load and on a second reading. Unknown ids are dropped. `last_activation_floor = F04` before any repair is a default, not evidence of an activated elevator. `game_completed` is stored and never set.

## 7. Elevator travel

`ElevatorPanel` loads `FloorRegistry`'s destination scene when `elevator_id` is set and that elevator is in `activated_elevators`. An empty destination scene logs an error and does not travel. An empty `elevator_id` still runs the old same-floor cabin hop. Floor 4's buttons pass `F04_DOWN` and `F04_UP`, so those buttons change scenes.

Floor 4 also links the two door nodes as partners and parks one "car is here" lamp between them. That lamp logic is still the old paired-shaft behavior. Do not mix a story change into it.

## 7b. Environmental storytelling

Story text lives in `StoryCatalog`. `Floor04Story.install` runs at the end of Floor 4's `_ready` and adds readables without editing room marks. `StoryReadable` is a `StaticBody3D` with `interact()`, so the existing ray can hit it. Local +Z is the readable face. `StoryReader` is a `CanvasLayer` that suspends player input the way the wire board does, and closes on Esc. `StoryPrompt` draws `E — Read` only while the ray is on a readable and input is not suspended.

A future journal can list `GameState.discovered_entries` in order and look up title, body, floor, and medium in the catalog. Do not add that screen in the pilot.

Readable bodies must stay off doors, elevator plates, and the electrical cabinets. The cabinet script forwards E to the nearest panel within 7 m. A paper glued to the cabinet would steal that ray.

## 8. Interaction and audio

- `E` via player's interaction ray for doors, switches, panel access, and elevator buttons.
- Contextual `[i]` prompt and focused puzzle UI are allowed despite the **no persistent HUD** rule.
- Footsteps by surface (carpet, tile, marble, concrete, water, metal); ambience: fluorescent hum, HVAC, rain, distant thunder.
- Red EXIT doors are always locked with audible feedback.
- Hazards fade quickly and respawn at temporary checkpoint without changing persistent progression.

## 9. AI coding agent rules

1. Read `AGENTS.md`, `docs/`, and these root specs before proposing changes. `docs/` wins on story and ending. The scripts win on the panel, elevators, and save.
2. Inspect real `.gd`/`.tscn` files and `project.godot` before claiming a file exists.
3. State affected files and migration risks before editing; preserve Level 4 functionality.
4. Use unique stable floor/panel/elevator IDs, not node display names, for saves.
5. Never unlock an elevator without its panel (except the remote Master Panel's explicit link).
6. Do not invent new routes, floors, UI rules, or endings when the specs are silent; flag the unresolved decision.
7. Deliver incremental features with reproduction steps and acceptance tests.
8. Prefer signals and a single state owner over scene-to-scene hard references.
9. Test a fresh save, a wrong wire, puzzle cancellation, a finished panel, restart, travel between floors that exist, and a story read that does not move the Continue floor.

## 10. Acceptance criteria

Current build:

- Floor 4 remains playable, including its two panels and both elevator trips.
- Save survives a restart and keeps repaired panels.
- Partial wire state never survives closing the board.
- A repaired Floor 4 button loads Floor 3 or Floor 5. A missing destination scene does not travel and does not wipe the save.
- Story discoveries reload, do not duplicate, and do not change the Continue floor.
- A save written before `discovered_entries` still loads.

Later, if those floors are built:

- Floor 1's downward elevator stays locked until whatever endgame unlock is approved. The old Basement 2 master-panel link is only the registry's current placeholder.
- Do not bring back a same-floor cabin hop as the travel button.
