# Floor 404 — Level Design Logic & Modular Architecture

> **Status:** Target level design. Gameplay rules are defined in `gameplay_progression.md`; technical interfaces in `architecture_design_patterns.md`.

## 1. Grid and modular kit — fixed convention

The existing Level 4 kit already uses a **4 m × 4 m structural grid**. This is a project standard, **not an example**. In Godot, 1 unit = 1 meter; the X/Z axes form the floor plane, Y is vertical. The existing Level 4 uses a 4×4 meter modular structural grid. This grid is the default building standard for all subsequent floors, not a restriction on individual room sizes, corridors, props, or special architecture. The completed Level 4 geometry must remain unchanged unless a verified technical issue requires modification.

| Module | Existing convention |
|---|---|
| Floor | `floor_4x4.tscn`, 4×4 m, thickness 0.2 m; walking surface at local Y=0 |
| Wall | `wall_4x3.tscn`, 4 m long, 3 m high, thickness 0.2 m |
| Door frame | 4 m module with 1.2×2.4 m opening |
| Structural placement | Origins on cell corners, positions at multiples of 4 m in X/Z; align pivots and rotation |
| Room sizes | Any combination of full cells: 4×4, 4×8, 8×8, 8×12 m, etc. |

Props, furniture, and decorative details need not snap to 4 m. Special architecture may deviate **only with an explicit adapter/transition** and must not change the existing kit's origins or dimensions. Check collisions and seams in Godot after Blender export. Maintain 3 m typical ceiling height unless a documented special area requires otherwise.

## 2. Modular categories and asset reuse

- Corridors: straight, L turns, T junctions, crosses, long empty stretches.
- Rooms: offices, meeting rooms, kitchens/breakrooms, server rooms, storage, toilets, stairwells, panel rooms, elevator hubs.
- Reuse a shared pool of office props (desks, chairs, refrigerators, server racks, fluorescent lights, CRTs, etc.) across floors. Prefer 1K texture resolution for performance; exceptions need profiling.
- **Déjà vu:** each floor reuses recognizable assets but changes walls, corridors, lighting, furniture arrangements, and sightlines. Do not duplicate Floor 4's layout unchanged.
- Floors may mix carpet, concrete, tile, warm-toned rooms, cold-toned rooms, and dead or flickering fluorescent fixtures.
- Windows face absolute darkness, with rain and occasional thunder/lightning; do not reveal a conventional outdoor city.

## 3. Standard floor checklist

Ordinary floors **2–14** contain:

1. One UP elevator hub and one DOWN elevator hub.
2. One electrical panel room per elevator; each panel unlocks **its own departure-floor elevator**.
3. 1–3 red **EXIT** doors that are permanently locked and give audio feedback.
4. A safe arrival spawn for each incoming elevator and a separate safe Continue spawn.
5. Navigable paths to the panel rooms, even when elevators are initially disabled.
6. Optional ambient rooms, props, and hazards, without creating irreversible soft locks.

## 4. Special floors

### Floor 4 — Starting floor

First playable/tutorial floor. Existing Godot scene `scenes/office_level.tscn` is the **working prototype**; preserve it while migrating to multi-floor logic. Two elevators (UP to 5, DOWN to 3), two local panel rooms, recognizable office areas, and a safe New Game spawn. Do not replace this with a new scene without compatibility checks.

### Floor 1 — Exit gateway

Two elevator cabins: UP → Floor 2, activated by **one local panel**; DOWN → Ground Floor, activated **only by the remote Basement 2 Master Panel**. There is **no second local panel** for the Ground Floor elevator. The Ground Floor button is initially red and remains so until Master Panel completion.

### Floor 15 — Zenith

Two local elevator destinations: Floor 14 and Basement 1. Both have their own repairable panels. Use a noticeably different visual mood (darker, damaged, or server-heavy) while retaining recognizable modular rules.

### Basement 1

Two elevators: RETURN → Floor 15 and DOWN → Basement 2, each with a local panel. Industrial transition atmosphere. Verify return path to Floor 15 before allowing travel to Basement 2.

### Basement 2 — Core

Industrial concrete, pipes, darkness. Exactly **one physical elevator**, returning to Basement 1, activated by its own local panel. A **separate Master Panel** unlocks Floor 1 → Ground Floor remotely. No elevator directly from Basement 2 to Floor 15 or Ground Floor.

### Ground Floor — Ending scene

No panels, false exits, or extra maze. A very large bright hall appears when the elevator opens; a monumental luminous exit door is interactable. Opening it reveals absolute white light; entering triggers the credits. Keep ending sequence visually distinct from all dark office floors. Use a dedicated scene (suggested: `scenes/ground_floor_ending.tscn`, planned path, not confirmed existing).

## 5. Floor graph and spatial safety

The authoritative floor connections are in `gameplay_progression.md`. All elevators must declare source floor, destination floor, panel ID, elevator ID, and arrival marker. Do not derive destination by numerical floor arithmetic at special floors. No route may place a player in a blocked or unloaded location. All required panel rooms must be reachable without using the very elevator they unlock.

## 6. Collision and interaction standards

- Structural walls and heavy props: appropriate `StaticBody3D` collision shapes.
- Interactive doors/panels/elevator buttons: consistent collision masks reachable by the player's `RayCast3D` and a shared `interact()` contract; configure actual layer numbers in `project.godot` before hard-coding them.
- No collision gaps at 4 m tile seams; doors must remain usable when closed; safe spawns must not intersect any collider.
- Red EXIT doors remain locked. Elevator door animation is not itself permission to travel.

## 7. Per-floor delivery checklist

- Unique floor ID and scene path; both arrival and Continue markers.
- Correct number of elevators and panels per floor type.
- Every panel has a unique stable ID and maps to exactly one elevator unlock (Master Panel maps to remote Floor 1 exit elevator).
- All layout modules align to the 4 m grid; collision, lighting, ambient audio, and FPS are checked.
- Test New Game, Continue, both elevator directions, failed puzzle, completed puzzle, and backtracking.
