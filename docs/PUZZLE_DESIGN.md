# Floor 404 — Puzzle Design

## Existing system — verify against code
An electrical cabinet puzzle has reportedly been implemented: 8 wires connect to 8 terminals; correct connections persist, incorrect attempts do not undo solved connections, completion activates an associated elevator, and progress survives saving/loading. The Floor 4 3D cabinet should remain in place. A 2D interactive puzzle appears when the player interacts. Confirm all specifics in the repository before editing.

## Design principles
- Give each floor a distinct gameplay identity; do not repeat the same wire puzzle everywhere.
- Integrate puzzles into believable infrastructure and the story.
- Provide discoverable clues; avoid requiring blind searches across dozens of rooms.
- Support optional lore discoveries without making every note a required clue.
- Persist major solved states, unlocks, and irreversible progress.
- Ensure no softlocks; verify alternate routes and save/reload behavior.

## Candidate puzzles (not implementation commitments)
- Find a key to access the electrical cabinet room, with contextual clues.
- Floor 5: broken elevator and stairwell detour, possibly requiring access to a locked stairwell door.
- Archives: employee identifier → cabinet → access code.
- Power distribution: switches operated using a schematic found elsewhere.
- Near-identical rooms: identify a meaningful discrepancy.
- Security office: CCTV screens reveal spatial clues.
- Spatial anomalies: subtly inconsistent connections, used sparingly.

## Regression checklist
Existing panel interactions; solved-wire persistence; elevator unlock; scene transitions; save/load; player navigation; collision and interactable prompts.
