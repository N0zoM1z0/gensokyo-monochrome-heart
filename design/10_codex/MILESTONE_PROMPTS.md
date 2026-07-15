# Milestone Prompts for Codex

Use one prompt per task session. Attach the repository and keep the design package at `design/`.

## M00

> Implement M00 from `design/10_codex/CODEX_MASTER_TASKBOOK.md`. Do not write gameplay. Establish the Godot 4.7 stable repository, content/schema sync, headless validator, test runner, CI skeleton, asset/license policy, and a release-channel placeholder scanner. Read the referenced technical documents first. Run every available verification and report exact results.

## M01

> Implement M01 only: persistent 320×180 shell, integer scaling, SceneRouter, remappable input, title/options/pause, first-run accessibility preset, EN/JA switching, and screenshot fixtures. Use original geometric placeholders. Do not start narrative/gameplay systems.

## M02

> Implement the typed content database for the starter files in `design/09_data`. Validate stable IDs, references, localization keys, and content hashes. Do not expose raw nested Dictionaries beyond parser boundaries. Add failure fixtures and human-readable reports.

## M03

> Implement GameState, commands, five relationship facets with semantic bands, inventory/rumor/Journal/time state, deterministic RNG, atomic saves, backups, metadata cards, and migration fixtures. No player UI may show raw relationship values.

## M04

> Implement the event interpreter and bilingual dialogue system sufficient to execute `design/09_data/sample_event_empty_cushion.json` with mocked mode results. Include backlog, four-tone choices, transactional effects, replay isolation, debug overlay, graph validation, and locale switch mid-dialogue.

## M05

> Build the Hakurei Shrine veranda exploration spot using original 1-bit geometric placeholders. Implement movement, collision, interaction magnetism, objective HUD, object observations, event triggers, companion-skill preview, accessibility navigation hint, and input parity. Do not hard-code event IDs in the player controller.

## M06

> Build the Tea Temperature minigame through the shared Minigame interface. It must return typed results, support clear/excellent/loss, slower heat/wider band/no timer assists, deterministic fixtures, pause/retry/accept-loss, and full reset.

## M07

> Build the danmaku foundation and three-phase boundary-stain encounter. Use pooled data bullets, fixed-step deterministic simulation, telegraphs, Focus/hitbox, shot/bomb/graze/Margin, density and speed assists, auto-bomb, phase retry, Assist Clear, replay fixtures, and a 2,500-bullet stress scene. Use no official patterns or assets.

## M08

> Build the compact fighter foundation with original placeholder versions of Reimu and Marisa. Implement data-driven moves, fixed-step input buffers, hitboxes/hurtboxes, Temperament, distinct character mechanics, story AI, simple input parity, assists, replay fixture, and complete round reset. Do not copy official fighting-game frame data.

## M09

> Integrate the full Empty Cushion vertical slice exactly as defined in `VERTICAL_SLICE_ACCEPTANCE.md`. Author data/localization, transitions, adaptive test-tone music, afterbeat, Keepsake, Journal, save/load, and replay. Run the entire P0 matrix and list every failure.

## M10

> Polish the vertical slice UX/accessibility only. Resolve first-time-player confusion, EN/JA layout, controller focus, one-handed presets, Low Motion/no-flash, assist discoverability, failure wording, and audio hierarchy. Do not expand content until P0 acceptance passes.

## M11

> Implement authoring/debug tools: event preview, dialogue EN/JA preview, dependency graph, character skills browser/output validator, localization width report, spot fixture launcher, bullet lab, fighter hitbox viewer, migration harness, screenshot runner, and legal test-tone music audition. Prove a nonprogrammer can duplicate/edit/preview the sample event without GDScript.

## Expansion prompt template

> Implement milestone `<ID>` from the taskbook. First produce a dependency/risk assessment and identify which vertical-slice systems are reused unchanged. Reject any design that requires character/region conditionals inside generic systems. Add content incrementally with EN/JA, accessibility, tests, screenshots, and provenance records in the same PR.

## Bug-fix prompt template

> Reproduce issue `<ID>` from a minimal fixture. Do not patch symptoms in presentation if the invariant belongs to Domain/Application. Add a failing automated test first where feasible, implement the smallest fix, run affected and regression suites, and report whether save/replay compatibility changes.

## Performance prompt template

> Profile fixture `<name>` on the available environment. Provide frame-time/memory evidence before changing architecture. Preserve deterministic results and accessibility tiers. Make one optimization class at a time, compare before/after captures, and avoid unverifiable claims.
