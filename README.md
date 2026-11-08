# Floor 404 — The Null Pointer

First-person liminal walking simulator set in an abandoned corporate office. There are no monsters, no weapons, no HUD, and no visible player body. The feel comes from the rooms, the sound, and a few instant-reset hazards.

This document is the setup guide for the repository: install the tools, open the Godot project, and move assets from Blender, GIMP, and Audacity into the game.

## Tools

| Tool | Role | Version used here |
|---|---|---|
| [Godot](https://godotengine.org/download) | Game engine and scene editor | 4.7.2, Forward+ |
| [Blender](https://www.blender.org/download/) | Meshes, modular kit pieces, doors, props | 5.2 LTS |
| Blendkit addon for Blender | Browse and download the Blendkit catalog inside Blender | 3.21.3 |
| Blendkit addon for Godot | Same catalog, from the Godot editor. Enabled in `project.godot` | 0.7.2 |
| [GIMP](https://www.gimp.org/downloads/) | Textures, decals, grunge, window dirt | Current stable |
| [Audacity](https://www.audacityteam.org/download/) | Footsteps, door sounds, rain, HVAC, thunder | Current stable |

Godot is the only tool that runs the game. Blender, GIMP, and Audacity produce the source art. Exported files are what Godot imports.

A code editor is optional. This repo includes `floor404.code-workspace` for Cursor or VS Code. If you use the Godot Tools extension, set `godotTools.editorPath.godot4` in that workspace file to your `Godot_v4.7.x` executable.

## Repository layout

```
floor-404/
  floor404.code-workspace          Cursor / VS Code workspace
  architecture_design_patterns.md  Design notes
  .cursorrules                     Editor rules for GDScript
  godot_project/                   The Godot project (this is res://)
    project.godot
    addons/blendkit/             Godot Blendkit plugin 0.7.2
    models/blendkit/             Free Blendkit props used on the floor
    models/office/               Walls, floors, doors, cubicle, columns
    scenes/
    scripts/
  assets_src/                      Blender, GIMP, and Audacity source files
  docs/                            Extra design documents
```

`assets_src/` and `docs/` are source folders. They are not inside the Godot project. Create them if they are not there yet. Keep `.blend`, `.xcf`, and Audacity project files in `assets_src/`. Copy only the exports into `godot_project/`.

Godot writes a `.godot/` cache next to `project.godot`. That folder is gitignored. Do not commit it.

## 1. Install Godot

1. Download **Godot 4.7.x** (standard build, not .NET) from the Godot site.
2. Unzip it somewhere stable, for example `C:/Gamedev/Tools/Godot/`.
3. Run the executable once so the Project Manager opens.

The project was created with **Forward+** and the **Jolt** 3D physics engine. Open it with Godot 4.7 or newer.

## 2. Open the game project

The Godot project root is the folder that already contains `project.godot`:

```
C:/projects/floor-404/godot_project
```

From PowerShell, this opens the editor on that project:

```powershell
& "C:\Gamedev\Tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "C:\projects\floor-404\godot_project"
```

Change the executable path if Godot is installed somewhere else. Inside the editor, **F5** runs the game. The main scene is `scenes/office_level.tscn`.

In the Project Manager:

1. Click **Import**.
2. Browse to `godot_project` and select `project.godot`.
3. Click **Import**, then **Edit**.

If `project.godot` is missing and you need to create the project in that same folder:

1. Click **Create New Project**, not Import. Import only works when `project.godot` already exists.
2. Project name: `Floor 404`.
3. Project path: `.../floor-404/godot_project`.
4. Turn **Create Folder** off. If it stays on, Godot makes a new subfolder and the existing scripts stay outside the project.
5. Renderer: **Forward+**.
6. Version control metadata: **Git**.
7. Godot will warn that the folder is not empty. That is expected. Create continues and adds `project.godot` beside the scripts. It does not delete them.

After the editor opens, `scripts/` and `scenes/` show up in the FileSystem dock.

## 3. Run a scene

`project.godot` sets the main scene to `scenes/office_level.tscn`. Press **F5** to walk the office.

`scenes/test_level.tscn` is still there: a flat floor with `scenes/player.tscn`. Open it and press **F6** to run that scene alone.

`scripts/office_level.gd` builds the floor at runtime from the 4 m kit. The south end keeps the original corridor, break room, cubicles, security room, and stair. North of that are more offices, a stairwell, two linked elevators, a server room, a meeting room, and a small room with an old CRT desk.

Corridors stay empty. Other rooms are either bare or hold one cluster: a lone chair, a desk, a CRT with a tower, a cubicle, folding chairs, or a ladder. Some of the bare rooms are offices with a computer. A few rooms switch to a concrete floor with cold light, or a brown floor with warm light and tinted walls. The outer walls carry the same dark windows as the cubicle hall.

### Controls

| Input | Action |
|---|---|
| W A S D | Move. No jump, no crouch. |
| Mouse | Look. Pitch is clamped to −89° … 89°. |
| E | Interact, when the crosshair ray hits an object with `interact()`. |
| Escape | Release or recapture the mouse. |

The player script uses Input Map actions named `move_forward`, `move_back`, `move_left`, `move_right`, and `interact` when those actions exist. Until you add them, the physical keys above are used directly.

Movement speed, mouse sensitivity, and interaction distance are exported on the player and can be changed in the Inspector.

## 4. What is already in the project

### Scripts

| File | Node | Purpose |
|---|---|---|
| `scripts/office_level.gd` | `Node3D` | Builds the office floor, rooms, and props |
| `scripts/player.gd` | `CharacterBody3D` | Walk, mouse look, head bob, interaction ray, footsteps |
| `scripts/elevator_doors.gd` | `StaticBody3D` | Sliding elevator doors |
| `scripts/elevator_panel.gd` | `StaticBody3D` | Floor buttons. E rides to the other car |
| `scripts/interactable.gd` | `Node3D` | Base `interact()` used by the ray |
| `scripts/door.gd` | `Node3D` or `AnimatableBody3D` | Hinged or sliding door, optional lock, open/close audio |
| `scripts/checkpoint_zone.gd` | `Area3D` | Saves `player.last_safe_transform` on enter |
| `scripts/hazard_zone.gd` | `Area3D` | Fade out, respawn, fade in |
| `scripts/ui/fade_overlay.gd` | `CanvasLayer` | Full-screen black fade. Created at runtime if the scene has none |

A hazard respawn fades to black in 0.1 s, moves the player to the last checkpoint, then fades in over 0.15 s. Velocity is cleared so a fall does not continue after the teleport. The first safe pose is wherever the player spawns, until they enter a checkpoint.

### Modular greybox kit

Scenes in `scenes/modular/` use a **4 meter grid**. Each prefab's origin is the corner of a cell. Place instances on multiples of 4.

| Scene | Size | Notes |
|---|---|---|
| `floor_4x4.tscn` | 4 × 4 m, 0.2 m thick | Extends along +X and +Z. Walk surface is local y = 0. Static body is in the `tile` group. |
| `wall_4x3.tscn` | 4 m wide, 3 m tall, 0.2 m thick | Sits on the local z = 0 edge. Rotate Y by 90° for a wall along Z. |
| `door_frame.tscn` | Same footprint as the wall | 1.2 × 2.4 m opening. The `Door` node uses `door.gd` and opens with E. |

`scenes/modular/` also has carpet, concrete, ceiling, wall, window, and light-panel scenes. The playable floor instances the exported glTF kit in `models/office/` (`carpet_4x4.glb`, `wall_4x3.glb`, `door_frame.glb`, `door_leaf.glb`, and the prop meshes). Door leaves have a handle on each face. Keep the same origins if you replace a mesh, so the 4 m grid still lines up.

### Door audio

On `door_frame.tscn`, select the `Door` node and assign streams:

- `open_sound`
- `close_sound`
- `locked_sound`

A locked door plays `locked_sound` and stays shut until `unlock()` is called, or until the interactor has `required_key`.

### Footstep surfaces

The floor ray emits `footstep_triggered` with a surface name. Tag the floor body with one of these groups, or set the `floor_surface` metadata:

`carpet`, `tile`, `marble`, `concrete`, `water`, `metal`

The greybox floor uses `tile`.

## 5. Blender

Model in meters. Godot's unit is 1 meter, and this kit is built on a 4 m cell and a 3 m ceiling.

1. Set the scene units to **Metric**, unit scale **1.0**.
2. Apply rotation and scale (`Ctrl+A`) before export.
3. Match the Godot pivot:
   - Floor and wall modules: origin at the cell corner, geometry in +X / +Z, floor top at z = 0 in Blender if Z is up. Godot is Y-up. glTF export converts this, so a floor whose top is at Blender z = 0 arrives with its walk surface at Godot y = 0 if the object origin is on that corner.
   - Doors: origin on the hinge, leaf extending along one axis, same as `door_frame.tscn`.
4. Export **glTF 2.0 Binary (`.glb`)** into `godot_project/assets/models/`.
5. Godot imports the file on focus. Drag the imported scene into a level, or swap it in for the CSG mesh on a prefab.

Suggested source layout:

```
assets_src/blender/modular/
assets_src/blender/props/
godot_project/assets/models/
```

### Blendkit

Blendkit (the current name of BlenderKit) is an online catalog, not a pack stored in this repo. The Blender addon 3.21.3 and the Godot addon 0.7.2 (`addons/blendkit/`, already enabled) both talk to [blendkit.com](https://www.blendkit.com) and see the same assets. Nothing is on disk until it is downloaded.

Godot needs the **glTF** file (`gltf_godot`, a `.glb`). The catalog entry named `resolution_1K` is a `.blend`, and Godot does not import that. For this floor the glTF was downloaded, then any embedded image longer than 1024 px was scaled to 1K in Blender and the file was exported again. That cap is for the GTX 950M. The results are in `godot_project/models/blendkit/`.

`scripts/office_level.gd` instances those scenes and adds a box collision from the mesh bounds. The catalog models do not bring gameplay collision with them.

Props that now come from Blendkit:

| File | Used as |
|---|---|
| `office_chair.glb` | Swivel chair with wheels. Every computer desk uses this one. |
| `wooden_chair.glb` | Side chair at plain tables |
| `folding_chair.glb` | Break-room and empty-room chairs |
| `conference.glb` | Every table: break rooms, meeting room, and desk stands. About 2.0 × 1.2 m, top near 0.82 m. |
| `crt.glb` | Old monitor, scaled to 0.42 m tall |
| `keyboard.glb` | Desk keyboard |
| `tower.glb` | Small desktop case |
| `cooler.glb` | Water dispenser |
| `fridge.glb` | Closed steel fridge. The old open fridge with drinks is gone. |
| `extinguisher.glb` | Fire extinguishers along the walls |
| `ladder.glb` | Folding ladder |
| `plant.glb` | Snake plant |
| `tree.glb` | Potted palm |
| `shelf.glb` | Standing shelf |
| `copier.glb` | Floor copier |
| `cabinet.glb` | Filing cabinet |
| `camera.glb` | Security camera |

The shell is still the office kit: walls, floors, ceilings, doors, elevators, and columns. Cubicle stalls, break-room counters, server racks, and the small printer on the CRT desk stayed as they were.

After import, three fits were made so the models sit in the rooms:

- The office-chair column was shortened. The seat is about 0.50 m, and the wheels stay on the floor. Wooden and folding chairs lost a little leg.
- Table tops and the cubicle desktop were raised about 8 cm. Monitors and keyboards moved up with the surface.
- Tables cycle three finishes, one after another: silver, brown, black. Chairs are placed just outside the real tabletop, facing it. A chair at a computer is always the wheeled one.

To drop another catalog model into the floor: download the glTF (from the Godot Blendkit dock, or the Blender addon), save the `.glb` under `models/blendkit/`, and if a texture is over 1024 px scale it in Blender and export glTF with Y up. Then preload it from `office_level.gd`.

## 6. GIMP

Paint or assemble textures, then export images Godot can import.

1. Work in an `.xcf` under `assets_src/gimp/` so layers stay editable.
2. Export **PNG** into `godot_project/assets/textures/`.
3. Prefer power-of-two sizes (512, 1024, 2048) for tiled office surfaces.
4. In Godot, create a `StandardMaterial3D`, assign the albedo (and normal or roughness maps if you exported them), and put that material on the mesh.

Use GIMP for wall grime, ceiling stains, carpet tiles, signage, and the dark exterior visible through windows. Those textures replace the flat colors on the CSG blockout.

## 7. Audacity

Edit and export the sounds the office needs: fluorescent hum, HVAC, rain on glass, distant thunder, footsteps per surface, and door open, close, and locked attempts.

1. Keep Audacity projects (`.aup3`) in `assets_src/audio/`.
2. Export into `godot_project/assets/audio/`.
   - Short effects (footsteps, switches, door latches): **WAV 16-bit** or **OGG Vorbis**.
   - Loops (hum, rain, HVAC): **OGG Vorbis**, so they stay small.
3. Trim silence, and for loops use a zero crossing so the seam does not click. Set Godot's `AudioStreamPlayer` loop flag on the imported stream when the sound should repeat.
4. Assign clips in the Inspector. Door streams go on the `Door` node. Footstep clips should be played from the player's `footstep_triggered` signal, chosen by the surface name.

Godot imports audio the same way it imports models: save the file under `godot_project/` and it appears in the FileSystem dock.

## 8. Suggested Godot asset folders

Create these as you export. They do not exist until the first asset is added.

```
godot_project/assets/models/
godot_project/assets/textures/
godot_project/assets/audio/footsteps/
godot_project/assets/audio/doors/
godot_project/assets/audio/ambient/
```

## Design constraints

- First person only. The player has a capsule collision and a camera, not a visible mesh.
- Interaction is the E key, through objects that implement `interact()`.
- Death is an instant respawn at the last checkpoint, with a short black fade and no loading screen.
- Hazards are environmental: exposed wiring, missing floors, empty elevator shafts. Nothing hunts the player.
- Windows look onto darkness. Rain and thunder stay outside.

## What is on the floor

The layout is generated, not painted into `office_level.tscn`. Rooms worth knowing:

| Place | What you find |
|---|---|
| Break rooms | Three of them. Blendkit tables (silver, brown, or black), wooden or folding chairs, a water dispenser, and a closed steel fridge on the first one. Counters stay on the wall, clear of the door. The ceiling lights in these rooms are all on. |
| Cubicle bays | Kit partitions, with a Blendkit CRT, keyboard, and wheeled chair pulled up to the desk. The north bay stays inside its walls and clear of the west door. |
| Column room | One wheeled chair in the open floor. |
| Security | Desk with Blendkit CRT monitors, a desktop case, and two wheeled chairs. |
| Stairs | Climbable flight to a red door, plus a taller concrete stairwell. A folding ladder stands in some rooms. |
| Elevators | Two cars in different wings. E on the doors opens them. E on the 15-button panel rides to the other car. |
| Server room | Black racks, blue status lights, one bay lit red. Concrete floor. West side of the north wing. |
| Meeting room | Blendkit conference table, four wheeled chairs, a large screen on the east wall. |
| CRT room | One Blendkit table: CRT, keyboard, desktop case, the small kit printer, and a wheeled chair. |

Reference photos live in `docs/reference/level4/`.
