# Floor 404 — Development Roadmap

## Status definitions
- **Reported**: described by the project owner, not independently verified here.
- **Verified**: confirmed by inspecting project files and/or testing in the engine.
- **Planned**: agreed design direction, not implemented.

## Reported state (verify in repository)
- Floor 4 has an established office layout and an electrical-panel/elevator puzzle.
- Floor 3 has recently been completed with approximately 85 rooms and extensive corridors.
- The project uses Godot, with Blender/BlenderKit assets in its workflow.

## Phase 0 — Audit and alignment (NEXT)
1. Inspect repository structure, engine version, autoloads, scene transitions, save system, and current docs.
2. Verify actual Floor 3 and Floor 4 status; note discrepancies without rewriting scenes.
3. Check whether existing README/design documents conflict with these design decisions; propose reconciliations.
4. Create a small, prioritized implementation plan with file-level impact and regression risks.

## Phase 1 — Environmental storytelling pilot
1. Agree data model and reusable interaction architecture.
2. Implement 8–12 hand-placed story items on Floor 4, covering terminal, paper, and wall writing.
3. Add accessible reading UI and discovery persistence only if needed.
4. Test actual visibility, interactions, and save/load.

## Phase 2 — Expand and refine
1. Populate Floor 3 selectively without altering its completed layout.
2. Evaluate furnishing density, performance, and connectivity with actual measurements.
3. Develop Floor 5 broken-elevator/stairwell gameplay after design approval.

## Later phases
Develop distinct floor identities, interconnected lore, optional puzzles, and a deliberately ambiguous ending. Avoid building all levels before validating the core exploration loop.

## Agent completion report template
- Files inspected
- Implemented vs reported status
- Proposed changes and risks
- Tests run and outcomes
- Unverified assumptions
- Suggested next small task
