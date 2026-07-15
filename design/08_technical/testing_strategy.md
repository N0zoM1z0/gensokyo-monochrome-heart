# Testing Strategy

## 1. Test pyramid

### Domain unit tests
Fast, headless tests for:
- relationship bands and deltas;
- event predicates;
- command validation;
- inventory and rumor rules;
- deterministic RNG;
- save migrations;
- result-band mapping;
- content ID parsing.

### Application integration tests
- event graph from entry to every end;
- choice transaction rollback;
- mode transition suspend/resume;
- autosave boundaries;
- locale switch mid-dialogue;
- Journal replay isolation;
- assist clear branch.

### Presentation tests
- screenshot matrix at 320 × 180 and supported window scales;
- input focus restoration;
- EN/JA overflow;
- no-flash variants;
- controller glyph swap;
- one-handed preset;
- bullet contrast under every region background.

### Playtests
- first-time Touhou player;
- experienced Touhou player;
- visual accessibility pass;
- low-mobility / one-handed pass;
- bilingual narrative review;
- canon/fanon characterization review.

## 2. Content validators

Release build fails on:
- duplicate or missing stable IDs;
- unresolved references;
- unreachable event nodes;
- event graph without end;
- unbounded unmarked cycle;
- missing localization row;
- missing approved music/SFX rights record;
- placeholder asset prefix;
- missing comfort tag for flagged content;
- route finale with impossible predicate;
- character line absent from review status.

## 3. Deterministic replay tests

For danmaku and fighter fixtures, record:
- game version;
- pattern/fighter data hash;
- seed;
- fixed-step count;
- inputs;
- assist settings;
- expected checkpoints and final result.

CI replays a small golden set. A mismatch requires explicit replay-version migration or fixture update with review.

## 4. Combat tests

### Danmaku
- no spawn-on-hitbox without telegraph;
- every story phase clearable at each assist tier;
- bullet pool exhaustion degrades safely;
- density scaling preserves pattern identity;
- auto-bomb windows;
- pause and resume determinism;
- off-screen warning correctness.

### Fighter
- hitbox/hurtbox frame audit;
- input buffer boundaries;
- throw tech and guard behavior;
- combo escape policy;
- story AI cannot infinite loop;
- simple inputs have parity without damage advantage;
- round reset cleans all projectiles and state.

## 5. Save tests

See `save_system.md`; run corruption and migration fixtures in CI. Every public demo save remains loadable in later demo patches where promised.

## 6. Performance tests

Automated stress scenes:
- 2,500 danmaku bullets plus UI;
- two fighters, 40 effects, and stage layers;
- 80 animated crowd sprites at festival;
- Journal with 1,000 entries;
- localization database cold load;
- rapid region scene swaps;
- save file with full v1 content.

## 7. Acceptance record

Each milestone stores:
- build hash;
- test suite result;
- performance capture;
- known issues;
- accessibility pass matrix;
- EN/JA screenshot set;
- content review sign-off;
- asset/license audit status.
