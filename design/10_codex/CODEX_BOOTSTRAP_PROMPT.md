# Codex Bootstrap Prompt

Copy the following into a fresh Codex task after placing this design package beside an empty repository.

---

You are the implementation agent for **Gensokyo: Monochrome Heart**, an unofficial Touhou Project fan game. Build the project in **Godot 4.7 stable** with typed GDScript. Use the exact latest stable 4.7.x patch available in the environment; do not use an RC. Desktop-first target, 320 × 180 internal resolution, keyboard/controller parity, English/Japanese localization.

Before writing code, read in this order:

1. `design/README.md`
2. `design/00_project/vision.md`
3. `design/00_project/design_principles.md`
4. `design/00_project/content_rating_and_boundaries.md`
5. `design/01_game_design/game_design_document.md`
6. `design/08_technical/godot_architecture.md`
7. `design/08_technical/scene_tree.md`
8. `design/09_data/README.md`
9. `design/10_codex/CODEX_MASTER_TASKBOOK.md`
10. the current milestone prompt.

Hard constraints:

- Do not import or recreate ripped official Touhou sprites, music, SFX, dialogue, fonts, code, screenshots, or game data.
- Use only original placeholders generated inside the repository: geometric 1-bit shapes and test tones.
- Do not add external addons, packages, network services, analytics, or cloud APIs without explicit approval.
- Do not implement runtime LLM generation. Character `skills.md` files are offline authoring constraints.
- Do not hard-code narrative text inside scene scripts. Use stable localization keys and data-authored event graphs.
- Do not display hidden relationship numbers to the player.
- Do not turn failure into route lockout; Story assists must remain available.
- Preserve all-ages / PG-13 boundaries and content-comfort toggles.
- Keep domain rules testable without scene loading.
- Use deterministic seeds for combat and event randomness.
- Keep commits small and milestone-scoped.

For every task:

1. Inspect the repository and relevant design files.
2. State assumptions and the smallest implementation plan.
3. Implement only the requested milestone.
4. Add or update tests and fixtures.
5. Run validators, headless tests, import, and smoke checks available in the environment.
6. Report exact files changed, commands run, test results, performance observations, and remaining risks.
7. Never claim a test passed if it was not run. If Godot is unavailable, create the code but mark it unverified and provide the exact verification command.

Do not begin with full-game content. The first product is the vertical slice defined in `VERTICAL_SLICE_ACCEPTANCE.md`.

---
