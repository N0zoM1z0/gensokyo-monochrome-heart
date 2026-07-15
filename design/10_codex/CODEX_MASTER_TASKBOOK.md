# Codex Master Taskbook

## 0. Mission

Build a maintainable vertical slice first, then expand the same architecture into the complete game. The slice must prove the integrated emotional rhythm:

> comic escalation → mechanical climax → quiet sincere afterbeat

The slice is not “a map demo plus separate combat prototypes.” It is one authored event chain at the Hakurei Shrine that moves through exploration, bilingual dialogue, a location minigame, short danmaku, a compact duel, Journal update, and save/load.

## 1. Non-negotiable product constraints

- Engine: Godot 4.7 stable, typed GDScript.
- Internal canvas: 320 × 180.
- Output: integer pixel scaling with letterbox fallback.
- Visuals: original 1-bit placeholders until reviewed art exists.
- Languages: EN and JA from stable keys.
- Input: keyboard and controller feature parity.
- Story progression: data-authored.
- Relationship: Trust, Ease, Respect, Spark, Strain; never raw UI numbers.
- Modes: exploration, dialogue, minigame, danmaku, fighter.
- Difficulty: narrative routes completable with Story assists.
- Runtime network: none.
- Shipping assets: no official/ripped Touhou material.
- Accessibility: first-run preset, remapping, low motion, bullet assists, instant text.
- Save: three manual slots, rolling autosaves, versioned migration.
- Target: 60 fps on measured modest hardware; do not publish minimum specs before profiling.

## 2. Agent operating protocol

### Before a milestone

- Read the milestone's design references.
- Inspect current code and tests.
- Identify dependencies and risks.
- Propose a plan of no more than 10 implementation steps.
- Confirm that the milestone does not require unapproved assets or addons.

### During implementation

- Prefer pure Domain objects and narrow scene adapters.
- Use stable content IDs.
- Add fixtures before broad content.
- Keep generated files reproducible.
- Add debug visualization for complex systems.
- Commit or report in logical increments.

### After implementation

Run, as available:

```bash
godot --headless --path . --editor --quit
godot --headless --path . -s res://src/tools/validate_content.gd
godot --headless --path . -s res://tests/run_all.gd
godot --headless --path . --quit-after 300 --write-movie /tmp/smoke.avi
```

Command flags may vary by installed Godot patch. Verify rather than assume. Report skipped commands honestly.

## 3. Milestone map

| Milestone | Product proof | Exit gate |
|---|---|---|
| M00 | repository and deterministic tooling | clean import, CI skeleton, no red validators |
| M01 | fixed-resolution shell and input | title → empty mode → pause works EN/JA |
| M02 | typed content database | all starter JSON loads and validates |
| M03 | GameState, commands, saves | state round trip + migration fixture |
| M04 | event interpreter and dialogue | sample conversation branches in EN/JA |
| M05 | shrine exploration | playable spot with interactions and companion hook |
| M06 | Tea Temperature minigame | clear/loss/assist branches return `ModeResult` |
| M07 | danmaku foundation | deterministic 3-phase story encounter |
| M08 | fighter foundation | Reimu/Marisa compact duel with simple inputs |
| M09 | integrated Empty Cushion slice | complete day loop and afterbeat |
| M10 | UI/Journal/accessibility polish | vertical-slice UX acceptance |
| M11 | authoring tools | nonprogrammer edits event and previews it |
| M12 | Scarlet Devil Mansion expansion | second region proves architecture reuse |
| M13 | five headline regions | chapter backbone playable |
| M14 | twelve deep routes | route gates and finales content-complete |
| M15 | roster/support content | 71 profiles integrated, not necessarily playable |
| M16 | art/audio production integration | no placeholders in release candidate |
| M17 | localization/content review | EN/JA sign-off and canon/fanon audit |
| M18 | performance/accessibility hardening | stress gates pass |
| M19 | demo/release packaging | clean-machine release candidate |

---

# M00 — Repository, Engine Lock, and Automation

## Objective

Create a reproducible repository that imports cleanly and rejects invalid content before gameplay code grows around it.

## Read

- `08_technical/build_release.md`
- `08_technical/coding_standards.md`
- `08_technical/testing_strategy.md`
- `10_codex/REPO_STRUCTURE.md`

## Tasks

1. Initialize Godot project and set 320 × 180 base viewport.
2. Record engine version in `ENGINE_VERSION.md` and CI configuration.
3. Create repository folders exactly or document justified deviations.
4. Add `.gitignore`, `.gitattributes`, line-ending policy, and optional LFS policy.
5. Add development, QA, demo, release feature flags.
6. Copy `09_data/schemas` and starter content into `content/` through a documented sync step.
7. Implement a headless content validator entry point.
8. Implement stable-ID uniqueness and reference-resolution checks.
9. Add a minimal headless test runner.
10. Add CI skeleton that imports project and runs validators/tests.
11. Add `LICENSES/README.md`, `CREDITS.yml`, and placeholder asset policy.
12. Add a script that fails on `ph_` assets in release channel.

## Deliverables

- clean project import;
- `scripts/verify_project.*` appropriate to platform;
- `src/tools/validate_content.gd`;
- `tests/run_all.gd`;
- CI workflow;
- contributor setup instructions.

## Acceptance

- fresh clone plus approved engine imports without manual editor clicks;
- duplicate content ID fixture fails with readable code and file path;
- valid starter data passes;
- release validation catches a deliberate `ph_` test asset;
- no external addon is present.

## Do not

- build gameplay systems;
- commit downloaded reference images/audio;
- hide validation errors behind warnings.

---

# M01 — Fixed-Resolution Shell, Input, and Basic Navigation

## Objective

Prove the game shell, integer scaling, persistent UI layers, input abstraction, and locale switching.

## Tasks

1. Build persistent `Main.tscn` shell from `scene_tree.md`.
2. Implement integer pixel scaling and letterbox fallback.
3. Implement `SceneRouter` with async load/configure/swap.
4. Implement remappable action map from `05_ui_ux/controls.md`.
5. Add keyboard/controller hot-swap and glyph provider.
6. Build Title, Options, Pause, and a placeholder Mode screen.
7. Add first-run accessibility preset.
8. Add EN/JA locale switch with reflow.
9. Preserve focus across modal open/close.
10. Add Low Motion transition variant.
11. Add screenshot fixtures for title/options in EN/JA.

## Acceptance

- title → new profile stub → placeholder mode → pause → title works;
- 320 × 180 remains crisp at 2×, 3×, 4× and letterboxed arbitrary size;
- controller can complete every flow without mouse;
- locale switch updates active screen without scene restart;
- Low Motion disables paper-fold animation;
- no display text lives in scripts.

---

# M02 — Content Database and Typed Parsing

## Objective

Load, validate, and query characters, locations, events, localization, and music metadata without exposing raw Dictionaries to gameplay systems.

## Tasks

1. Implement typed records for Character, Location, EventIndex, DialogueBeat, Choice, and MusicCue.
2. Implement `ContentDB` load stages with error aggregation.
3. Validate against project rules in addition to JSON Schema.
4. Resolve stable references and produce dependency graph.
5. Build generated runtime index cache.
6. Add development hot reload for content files outside active combat.
7. Add query methods by ID, tag, region, route depth.
8. Add content version/hash.
9. Add fixtures for missing/duplicate/invalid references.
10. Add human-readable validation report.

## Acceptance

- all files in `09_data` parse into typed records;
- invalid character, location, event, or localization reference fails before title screen in dev;
- queries are deterministic and sorted where ordering matters;
- runtime code does not retain arbitrary JSON dictionaries;
- content hash appears in diagnostics and replay headers.

---

# M03 — Game State, Commands, Relationship Facets, and Saves

## Objective

Establish the state model that all modes share.

## Tasks

1. Implement `GameState` and nested typed state classes.
2. Implement command dispatch and validation.
3. Implement five relationship facets and semantic bands.
4. Implement flags, rumors, Journal entries, inventory, Keepsakes, Tea Blends, time slots.
5. Implement deterministic RNG state.
6. Implement three manual and rolling autosave slots.
7. Implement atomic write, checksum, backup recovery.
8. Implement schema migration framework and at least v1→v2 fixture.
9. Implement lightweight save-card metadata.
10. Add developer state inspector and fixture loader.
11. Add transaction rollback for multi-effect event nodes.

## Acceptance

- new profile produces deterministic default state;
- every command has a positive and negative test;
- save/load round trip is deep-equal except allowed timestamps;
- simulated truncated write recovers old save;
- migration preserves route intent;
- raw relationship numbers never appear in player UI fixtures.

---

# M04 — Event Interpreter and Bilingual Dialogue

## Objective

Execute `sample_event_empty_cushion.json` through dialogue and choices, with mock mechanical results.

## Tasks

1. Implement step-limited event interpreter.
2. Implement all node types needed by sample event.
3. Implement transactional effects.
4. Implement `DialoguePresenter` with backlog, instant text, auto mode.
5. Implement four-tone choice component.
6. Implement EN/JA string lookup and named formatting.
7. Implement nonnumeric resonance presentation cues.
8. Implement event checkpoint boundary.
9. Implement read-only replay mode.
10. Implement debug overlay showing event/node/predicates.
11. Add graph reachability and unbounded-cycle validator.

## Acceptance

- all four choices reach correct branches;
- effect transaction is applied exactly once;
- save and reload at a dialogue boundary resumes correctly;
- locale switches mid-line and keeps choice focus;
- backlog contains text and nonverbal cues but no hidden deltas;
- a deliberately cyclic invalid event is rejected;
- mock `ModeResult` returns resume the graph.

---

# M05 — Hakurei Shrine Exploration

## Objective

Create a real side-view spot with original geometric 1-bit placeholders and interaction grammar.

## Scope

One spot: Shrine veranda and adjacent room. Objects: second cup, empty cushion, donation box, old tree, door, broom. Characters: protagonist, Reimu, Marisa entrance cameo.

## Tasks

1. Build exploration mode contract and scene.
2. Implement grounded side-view movement, collisions, interaction magnetism.
3. Implement interactive registry and typed actions.
4. Implement camera composition and room bounds.
5. Implement location/time/objective HUD.
6. Implement Reimu companion skill preview (`Intuitive Float`) as a traversal diagnostic.
7. Implement observe cues and protagonist notes.
8. Implement event-trigger volumes without hard-coded event IDs in player controller.
9. Add wood footsteps, cup, door placeholder SFX.
10. Add Story navigation hint after configurable delay.
11. Add keyboard/controller and one-handed tests.

## Acceptance

- player can inspect all required objects without pixel-perfect positioning;
- event objective completes only from authored interaction sequence;
- collision is stable at 60 Hz;
- no interactable polls player distance every frame;
- companion skill can be disabled or remapped;
- visual prompts remain legible on both palette polarities.

---

# M06 — Tea Temperature Minigame

## Objective

Build a 30–60 second location-specific minigame that communicates Reimu's indirect domestic care.

## Design

The player balances kettle heat, steep time, and two cup temperatures. The “perfect” result is not maximum heat; it is matching the remembered warmth. Comedy comes from Reimu's impatience and the protagonist overthinking tea.

## Tasks

1. Implement Minigame interface and host.
2. Implement tea state simulation and readable 1-bit instruments.
3. Implement tutorial overlay.
4. Implement clear/excellent/loss result bands.
5. Implement assists: slower heat change, wider target band, no timer.
6. Implement pause/retry/accept-loss flow.
7. Add deterministic fixture runs.
8. Add sound/visual rhythm equivalents.
9. Return typed `ModeResult` with no direct route mutation.
10. Integrate into sample event.

## Acceptance

- keyboard/controller parity;
- every assist tier is completable;
- failure produces authored Reimu response and event completion;
- no rapid tapping required;
- result is deterministic from seed/input fixture;
- restart leaves no stale timer/state.

---

# M07 — Danmaku Foundation and Boundary Stain Encounter

## Objective

Prove readable 1-bit Touhou-inspired danmaku without reproducing official patterns or assets.

## Scope

One player loadout (Reimu-inspired placeholder), one boss/stain, three phases:
1. drifting amulet lanes;
2. offering objects that become bullets;
3. a remembered safe lane shifted by one tile.

## Tasks

1. Implement fixed-step danmaku simulation.
2. Implement pooled bullet structs and batched rendering strategy.
3. Implement player movement, Focus/hitbox, shot, bomb, graze, Margin.
4. Implement pattern data format, emitter components, phase director.
5. Implement telegraph/spawn/commit/dissolve states.
6. Implement phase checkpoints and Story assists.
7. Implement density scaling that preserves pattern identity.
8. Implement deterministic replay recorder/player.
9. Implement bullet contrast, background dim, speed scaling, auto-bomb.
10. Implement result card and event return.
11. Stress-test 2,500 bullets.

## Acceptance

- no damaging bullet appears without telegraph in Story mode;
- normal and 55% density versions remain recognizable;
- golden replay matches expected checkpoints;
- 2,500-bullet stress meets provisional frame budget on test machine or reports profile bottleneck honestly;
- pause/resume and phase retry are deterministic;
- accepting loss returns a valid story result.

---

# M08 — Compact Fighter Foundation

## Objective

Build one story duel between Reimu and Marisa with character-shaped mechanics, not a generic platform fighter.

## Scope

- two placeholder fighters;
- light, heavy, skill, spell;
- movement, jump, guard, throw/tech optional only if stable;
- two spell breaks to win;
- simple input mode;
- one shrine stage.

## Tasks

1. Implement fixed-step fighter simulation and input buffers.
2. Implement data-driven move definitions and frame events.
3. Implement hitbox/hurtbox viewer.
4. Implement vitality and Temperament.
5. Implement Reimu neutral reset passive and Marisa momentum/firepower identity.
6. Implement story AI with authored behavior bands.
7. Implement simple and motion-input control modes with parity.
8. Implement round/phase reset and result return.
9. Implement replay fixture and frame-step training.
10. Add hold-to-guard, slower-speed, auto-face assists.

## Acceptance

- no animation is the sole source of hit timing;
- hitbox visualizer matches data;
- simple input has no damage penalty/bonus;
- AI cannot infinite lock the player;
- story can accept a loss;
- reset cleans projectiles, buffs, hitstop, and camera state;
- keyboard/controller test complete.

---

# M09 — Integrated Vertical Slice: The Empty Cushion

## Objective

Connect the systems into one polished 25–40 minute day.

## Flow

1. title/new profile/accessibility;
2. lodging desk invitation;
3. world map travel to shrine;
4. veranda exploration;
5. Reimu dialogue and four-tone choice;
6. Tea Temperature minigame;
7. boundary stain danmaku escalation;
8. Reimu/Marisa Spell-Card Terms duel or optional fixture depending story branch;
9. quiet second-cup afterbeat;
10. Keepsake and Journal update;
11. day end and save;
12. replay from Journal.

## Tasks

- author complete event graph and localization;
- add scene transitions and adaptive music placeholders;
- ensure state effects survive save/load;
- add acceptance telemetry locally, no network;
- add credits/fan-work notice;
- add all assists and comfort variants;
- remove debug-only blockers;
- run full screenshot and replay matrix.

## Acceptance

Use `VERTICAL_SLICE_ACCEPTANCE.md`. Do not proceed to broad content until all P0 items pass.

---

# M10 — Vertical Slice UX and Accessibility Polish

## Objective

Make the slice comprehensible to a player who has never played Touhou and satisfying to a player who has.

## Tasks

- first-run tutorial pacing;
- objective and Journal wording review;
- all menu focus and cancel behavior;
- EN/JA overflow pass;
- Low Motion and no-flash replacements;
- one-handed presets;
- combat assist discoverability;
- failure copy and accept-loss branches;
- audio mix hierarchy;
- input glyphs;
- screen-reader support feasibility note for future scope;
- external playtest instrumentation sheet.

## Exit gate

At least five external slice playtests: two Touhou-aware, two unfamiliar, one accessibility-focused. Critical confusion and route-blocking issues resolved.

---

# M11 — Authoring and Debug Tools

## Objective

Allow writers/designers to add content without editing scene scripts.

## Tools

1. Event Graph Previewer.
2. Dialogue Previewer EN/JA.
3. Content dependency graph.
4. Character skills browser and output validator.
5. Localization width report.
6. Spot fixture launcher.
7. Bullet Pattern Lab.
8. Fighter hitbox/frame viewer.
9. Save migration harness.
10. Screenshot matrix runner.
11. Music-state audition tool using legal test tones only.

## Acceptance

A nonprogrammer can duplicate the Empty Cushion event, change text/objects/results, validate, and preview without modifying GDScript.

---

# M12 — Scarlet Devil Mansion Architecture Reuse Test

## Objective

Prove that the architecture handles a different region and character without shrine-specific hacks.

## Content

- foyer and kitchen/corridor;
- Sakuya `Late by Three Minutes`;
- time-grid service minigame;
- knife-pattern danmaku escalation;
- missing-minute afterbeat;
- Patchouli library teaser;
- Remilia public/private scene.

## Exit gate

No generic system contains `if character == sakuya` or `if region == sdm` behavior. Character and region differences come from data/components.

---

# M13 — Five Headline Regions and Main Campaign Backbone

## Objective

Implement Shrine, Scarlet Devil Mansion, Youkai Mountain/Moriya, Eientei/Bamboo, and Hakugyokurou through chapter-complete playable events.

## Required proofs

- photo-graze mountain chase;
- rumor confidence/mutation;
- bamboo loop topology;
- Five Impossible Errands multi-minigame framework;
- soul collection/release garden mechanic;
- route-independent chapter reveals;
- cross-region state changes;
- final Archive prototype using recorded player strategies.

## Content budget

Do not author 100 events at once. Complete one chapter at a time with review, localization, accessibility, and performance before the next.

---

# M14 — Twelve Deep Routes

## Objective

Implement the route beats in `02_narrative/romance_route_beats.md` without reducing characters to rewards.

## Per-route checklist

- 5–7 core events;
- at least two scenes where the character acts on a non-romantic goal;
- one boundary test;
- one mechanical expression of the central flaw/value;
- one conflict that cannot be solved by flattering the character;
- one quiet afterbeat;
- route finale with semantic prerequisites;
- intimate/undefined/primary-bond outcome options where designed;
- EN and JA voice review against `skills.md`;
- fanon dial audit;
- comfort/boundary audit;
- Journal objects that change across the route.

## Route order recommendation

1. Reimu
2. Marisa
3. Sakuya
4. Youmu
5. Aya
6. Kaguya
7. Patchouli
8. Remilia
9. Yuyuko
10. Sanae
11. Eirin
12. Tenshi

This alternates production needs and prevents one faction from monopolizing review.

---

# M15 — Support Roster and Postgame

## Objective

Integrate all 71 profile records at appropriate depth without pretending every character needs a launch romance route.

## Tasks

- 2–4 event hooks for high-priority support characters;
- cameo and crowd tiers;
- regional companion skills where warranted;
- support danmaku bosses;
- postgame Dream Theatre explicitly labeled non-main-continuity;
- seasonal event framework;
- Ensemble Accord compatibility rules;
- no route promises unsupported by content budget.

## Acceptance

Every roster entry resolves to a valid skills document and runtime record. Sparse-canon characters remain conservative. No character exists only to praise the protagonist.

---

# M16 — Production Art and Audio Integration

## Objective

Replace geometric placeholders with original/licensed work through a tracked pipeline.

## Tasks

- lock Model M exploration style and eight launch fighter Model L sets;
- portrait expression packs;
- five headline region tilesets;
- bullet shape library;
- UI export pass;
- adaptive music stems and cue rights records;
- SFX voice limits and mix;
- asset hashes and license database;
- no-placeholder release scanner;
- credits generation.

## Acceptance

No official or unlicensed asset is present. Every shipped audio/art item has provenance and approval. Accessibility variants exist for VFX.

---

# M17 — Localization, Characterization, and Content Review

## Objective

Treat EN and JA as authored releases, and audit canon/fanon/original boundaries.

## Review passes

1. factual/canon anchors;
2. relationship anchors;
3. fanon intensity;
4. character autonomy;
5. romance consent/boundaries;
6. humor setup/payoff;
7. EN voice;
8. JA voice/register;
9. UI width/kinsoku;
10. comfort alternatives;
11. credits and terminology.

No draft generated through an agent can bypass human review.

---

# M18 — Performance, Accessibility, and Stability Hardening

## Objective

Meet measured gates under realistic content load.

## Tasks

- run all stress fixtures;
- profile and remove steady-state allocations;
- bullet batching/pooling optimization;
- Journal virtualization;
- scene load cache policy;
- memory leak soak tests;
- controller disconnect/reconnect;
- locale switching soak;
- save corruption/recovery;
- Low Motion/no-flash full-game pass;
- assist clear for every mandatory encounter;
- crash/log privacy review.

## Exit gate

All P0/P1 tests pass, known issues documented, no mandatory route depends on high execution skill.

---

# M19 — Demo and Release Candidate

## Objective

Produce a legally and technically clean public build.

## Tasks

- select demo boundary and save compatibility policy;
- final fan-work guideline and storefront review;
- clean-machine installation tests;
- credits and fan-work notice;
- license/permission archive audit;
- final EN/JA screenshots and store copy;
- export Windows/Linux, optionally macOS after signing pipeline;
- release manifest and SHA-256;
- rollback build;
- support/error-code documentation;
- post-release migration fixture.

## Final acceptance

See `DEFINITION_OF_DONE.md`. A build is not done because it launches on the developer's machine.

---

# 4. Change-control rules

Any proposal that changes these requires a written design decision record:
- engine/version family;
- internal resolution;
- runtime-generated dialogue;
- relationship model;
- route content rating;
- external dependency;
- online/analytics feature;
- monetization;
- official asset policy;
- save compatibility promise;
- number of deep launch routes;
- mandatory combat difficulty.

A decision record states problem, options, chosen path, consequences, migration, and owner.

# 5. Definition of a useful Codex report

End every work unit with:

```text
Summary
Files changed
Design references followed
Commands/tests run and exact results
Manual checks performed
Performance observations
Assumptions
Known limitations / risks
Next recommended task (one only)
```

Do not provide a celebratory summary without evidence.
