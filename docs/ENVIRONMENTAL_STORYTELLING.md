# Floor 404 — Environmental Storytelling

## Purpose
Let the building tell the story through ordinary workplace traces, research terminals, handwritten papers, and wall markings. The player should not know in advance whether an item is mundane, a puzzle clue, or a disturbing piece of evidence.

## Delivery formats
1. **Distinctive computers:** powered-on displays, unusual terminal content, subtle screen glow or sound; interact to read emails, logs, and reports.
2. **Desk notes:** paper, sticky notes, printed memos; readable on interaction; position near plausible office props.
3. **Wall writing:** marker messages in corridors, storage, and stairwells; readable in world, with optional accessible close-up/transcript.

## Content balance (initial proposal)
Aim for ~120 unique entries across the building, subject to playtesting: ~42 mundane, 36 narrative, 24 unsettling, 18 puzzle clues. These are writing targets, not mandatory scene counts.

## Example content — drafts, not canon
| Placement idea | Text | Function |
|---|---|---|
| Floor 4 workstation | `BUILD 2003.04 — FAILED` | Subtle 2003 reference |
| Floor 3 corridor | `WHO TURNED OFF THE PEOPLE?` | Unease |
| Floor 5 desk | `Don't trust the floor numbers.` | Spatial doubt |
| Floor 7 terminal | `ACTIVE USERS: 1` | Isolation |
| Floor 9 note | `I remember a meeting that never happened.` | Memory doubt |
| Floor 11 wall | `YOU HAVE BEEN HERE BEFORE.` | Possible resets |
| Floor 12 terminal | `OBSERVER 404 — STATUS UNKNOWN` | Identity question |
| Floor 15 archive | `REALITY VERIFICATION: INCONCLUSIVE` | Ambiguity |
| B2 console | `ORIGIN NOT FOUND` | Culmination |

## Contradictory traces
- `They are watching us.`
- `There is nobody watching. That's the problem.`
- `What if we are the ones watching?`
Place these far apart and let players interpret them.

## Bostrom / 2003 references
Use 2003 sparingly, e.g. an archived research file and an optional citation: `Bostrom, N. (2003) — Are You Living in a Computer Simulation?`. Do not turn the philosophical argument into a confirmed in-game scientific result.

## Proposed implementation architecture
- Data-driven entry catalog with stable ID, floor, placement, medium, content, optional puzzle reference, and discovery state.
- Reusable Godot interaction components for terminal/paper; wall writing can be static decal/mesh with optional transcript.
- Subtle `E — Read` prompt, readable UI, keyboard/controller handling if supported, and optional journal of discovered entries.
- Persist discovered IDs only where needed; avoid duplicating the save system.
- Inspect project architecture before choosing file formats, scripts, or autoloads.
- Test legibility, texture orientation, collision, distance, and performance in actual gameplay.

## Pilot
Start with 8–12 hand-placed entries on Floor 4, then evaluate discoverability and tone before scaling to Floor 3 and later floors. Do not modify existing architecture just to accommodate notes.
