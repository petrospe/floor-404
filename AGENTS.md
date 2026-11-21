# Floor 404 — Agent Instructions

Read `docs/GAME_VISION.md`, `docs/STORY_AND_LORE.md`, `docs/BUILDING_DESIGN.md`, `docs/PUZZLE_DESIGN.md`, `docs/ENVIRONMENTAL_STORYTELLING.md`, and `docs/DEVELOPMENT_ROADMAP.md` before making changes.

## Source of truth
- The actual repository is authoritative for implemented features, paths, engine versions, and architecture.
- Documentation contains **design intentions** unless marked verified. Inspect scenes/scripts and test before claiming completion.
- Do not rewrite or regenerate completed floors merely to align with design targets.
- Protect the existing electrical-panel puzzle, elevator activation, persistent state and save/load behavior.
- Preserve scene compatibility and existing player interactions. Prefer small, reviewable changes.
- Do not invent missing assets or dependencies; inventory what exists first.
- Before coding: summarize findings, planned files, dependencies, and regression risks; seek approval for broad refactors.
- After coding: run available project checks, report tested/unverified items, and update roadmap.
- For all text assets, verify legibility, orientation, and placement from the player's viewpoint; avoid negative-scale mirroring.
- Use English for in-game document drafts initially; localization can follow.
