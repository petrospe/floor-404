# Floor 404 — Gameplay Progression & Mechanics Specification

> **Status:** The panel, elevator, and save rules below match the current code for floors that have scenes. Unbuilt floors are still a target.  
> **Narrative authority:** `docs/`. This file does not decide the ending or whether anyone in the building is simulated.  
> **Level layout:** `level_design_logic.md`. **Code contracts:** `architecture_design_patterns.md`.

## 1. Core concept

First-person liminal walking simulator, no monsters, weapons, traditional HUD, or visible player body. The player starts on **Floor 4**. Repaired electrical panels unlock elevator trips between the floors that exist today: 3, 4, and 5. Later floors, basements, and an ending are not built. The story should leave the player's nature unresolved.

Exploration is non-linear at the start: the player can discover an upward route (the route required for completion) or go down to Floor 1 first (an intentional dead end until the basement objective is completed). The game must never permanently soft-lock the player.

## 2. Floor graph (authoritative)

- **Normal floors 2–14:** two local elevators, one to the immediately higher floor and one to the immediately lower floor; each is unlocked by its own electrical panel on the **departure floor**.
- **Floor 4:** initial spawn, same two-elevator pattern; player may go up or down.
- **Floor 1:** elevator **UP → Floor 2** is controlled by a local panel. Elevator **DOWN → Ground Floor** has **no local panel**; it is unlocked remotely by the Master Panel in Basement 2.
- **Floor 15:** one elevator **DOWN → Floor 14** and one **SPECIAL → Basement 1**, each with its own local panel.
- **Basement 1:** two elevators: **RETURN → Floor 15** and **DOWN → Basement 2**, each controlled by its own local panel. This explicit return route is needed to prevent a soft lock.
- **Basement 2:** one physical elevator **RETURN → Basement 1**, controlled by a local panel. A separate **Master Panel** remotely unlocks Floor 1 → Ground Floor. There is **no second elevator** in Basement 2.
- **Ground Floor:** ending-only destination. No electrical panels and no additional progression elevator.

The player can return to previously visited floors via the same floor graph, provided the elevator's *departure-side* control has been activated. **Do not assume that activating A→B also activates B→A.** Each elevator is a distinct directed transition and has a unique ID.

### Intended routes

- Optional early detour: `4 → 3 → 2 → 1` (discover locked Ground Floor access), then `1 → 2 → 3 → 4 → 5 → … → 15`.
- Direct route: `4 → 5 → … → 15`.
- Endgame: `15 → B1 → B2` → repair Master Panel → `B2 → B1 → 15 → 14 → … → 1 → Ground Floor` → ending.

**Design invariant:** Before finalizing a floor graph, verify there is a return path from every reachable floor. A player who repairs only one elevator must still be able to return or eventually progress; if not, provide a safe fallback without silently unlocking puzzle-controlled elevators. The exact route must be playtested.

## 3. Elevator rules

1. Elevator cabin doors can be interacted with before activation, but travel controls start **red/inactive**.
2. Repairing the corresponding panel permanently unlocks that *specific elevator transition*. Its travel button becomes **green/active**.
3. Pressing an inactive button does not travel and provides an in-world feedback sound/light; it must not change the save.
4. Pressing an active button initiates a single travel transaction: prevent duplicate interaction → close doors → fade/load destination floor scene → place player at the destination arrival marker → open doors → restore control.
5. An elevator **changes floor scene**. Teleporting between two cabins on the same floor is only a legacy prototype and **is not the intended final mechanic**.
6. Elevator state remains activated permanently in the save, including after backtracking or restarting the game.
7. Travel must never spawn the player inside a wall, closed collider, or hazard. Missing destination markers should fail safely and log an error rather than losing the save.

## 4. Electrical panel puzzle

- Player approaches a panel, sees a minimal contextual `[i]` interaction hint, presses **E**, and enters a focused puzzle interface.
- Puzzle has **8 ordered connections** between left-side wires and right-side sockets. An indicator shows which left wire is currently active, but not its correct right-side match.
- On a **correct match**, the connection is locked in, its indicator turns off, and the next left wire becomes active.
- On an **incorrect match**, only that attempted match is rejected. **All previously correct matches remain completed**. Unlimited retries; no death, global reset, or penalty.
- If the player **closes/exits an incomplete panel UI**, the incomplete puzzle resets to connection 1. Returning to that panel starts again from the beginning.
- Partial puzzle connections are **session-only UI state**, never saved to disk.
- After all 8 matches succeed: close/finish the panel, show a persistent **green external light**, activate the mapped elevator (or the remote Ground Floor elevator for the Master Panel), and **immediately autosave**.
- A completed panel is permanent and cannot be accidentally reset by re-entering the room or interacting again. Its UI should show a completed/read-only state, not replay the puzzle.
- Puzzle matching data must be deterministic per panel, so reopening an incomplete puzzle does not silently change the solution. The exact pairing and visual feedback assets are implementation data, not random guesses by an AI agent.

## 5. Persistent save and Continue

- **New Game:** reset progression and spawn on Floor 4 at its safe initial spawn marker.
- **Autosave trigger:** successful completion of **any** panel, including the Master Panel. Save the completed panel ID, the newly activated elevator ID, and the floor where that panel was completed.
- **Continue:** spawn on the **floor that was loaded when the game last closed**, at a designated **safe continue spawn marker** (not the previous arbitrary position and not necessarily inside the elevator). Closing the window writes `current_floor`. Arriving by elevator writes it too. A save with no `current_floor` still opens on `last_activation_floor`.
- **No save yet:** Continue stays disabled. After a session has saved, a game that closed on Floor 4 with no repaired panel continues on Floor 4.
- **Revisits/backtracking:** the Continue floor is the floor the player was on, not the numerically highest floor and not the last repaired panel.
- **Persist:** completed panel IDs, activated elevator IDs, last activation floor and panel ID, current floor, `game_completed`, schema version, and optional `discovered_entries`. Never persist partially connected wires. Nothing in the current scenes sets `game_completed`.
- **Save failures:** do not claim success; keep the game playable and expose a recoverable error. Write saves atomically and validate data on load.
- **Hazard checkpoints** are temporary respawn locations and are **not** the Continue/save spawn. They do not trigger persistent saves.
- **Story reads** also write the save. They add an id and leave the Continue floor where it was.

Example schema. The basement ids are registry keys for an unbuilt floor, shown so the field names stay clear:

```json
{
  "save_version": 1,
  "completed_panels": ["F04_UP_PANEL"],
  "activated_elevators": ["F04_UP"],
  "last_activation_floor": "F04",
  "last_activation_panel": "F04_UP_PANEL",
  "current_floor": "F03",
  "game_completed": false,
  "discovered_entries": ["f04_ellis_terminal"]
}
```

## 6. Ending

No ending scene is in the project. An earlier draft sent the player through Basement 2 to a bright Ground Floor hall, a luminous door, white light, and credits. That draft is retired. `docs/STORY_AND_LORE.md` keeps the ending undecided and forbids a literal "you are a simulation" reveal. The registry still has a `G` floor and a `B2_MASTER_PANEL` id so old route notes stay readable. Do not build that ending unless a new ending is approved.

## 6b. Story discoveries

Floor 4 has ten catalog entries in `scripts/story/story_catalog.gd`. Terminals, papers, and wall lines use the same E ray as doors. `E — Read` appears only while the ray is on one of them. Esc closes the reader.

- The first reading of an id appends it to `discovered_entries` and writes the save.
- A second reading opens the text again and does not store a duplicate.
- The write does not change `last_activation_floor`, repaired panels, or activated elevators.
- An open electrical board blocks the reader, and the reader does not clear or store wire seats.
- Saves without `discovered_entries` load with an empty list.
- There is no journal screen. The id list is the data a later journal would show.

## 7. Environmental gameplay

- False EXIT doors: 1–3 per ordinary floor, red and permanently locked; interacting plays a locked-handle sound.
- No monsters or combat. Liminal horror comes from repeating assets, altered layouts, emptiness, lighting, rain, thunder, and ambient sound.
- Hazards (electricity/falls) may cause rapid fade and respawn to the latest *temporary* safe checkpoint. They do not undo completed panels or permanent elevator activations.

## 8. Acceptance criteria

1. On fresh save, Floor 4 elevator buttons are red; no inter-floor travel without panel completion.
2. Correct matches 1–3 remain after a wrong attempt at match 4; closing and reopening resets all eight if incomplete.
3. Completing a panel turns its exterior lamp green, enables only its mapped elevator, and writes a durable save.
4. Relaunching the game loads the last **panel-activation floor** with all prior elevators still enabled.
5. Floor 1 → Ground Floor remains disabled until the Basement 2 Master Panel is completed.
6. Basement 2 has exactly one physical return elevator plus the Master Panel.
7. No elevator trip travels to another cabin on the same floor as a substitute for changing floors.
8. No finale is required for the current build. Do not treat a white-light Ground Floor as shipped content.
9. Backtracking cannot erase repaired panels. Story discoveries cannot erase them either.
10. On Floor 4, each of the ten story entries can be read, and a save reload keeps those ids without moving the Continue floor.
