# Codex Test Plan

## Per-commit minimum

- parser/schema tests for changed content;
- domain unit tests for changed rules;
- event graph validation if content changes;
- locale missing-key and width check if text/UI changes;
- headless import where available;
- one focused smoke fixture.

## Per-milestone

- all unit/integration tests;
- deterministic replay golden set;
- EN/JA screenshot matrix;
- keyboard/controller flow;
- Story and Low Motion presets;
- save/load and checkpoint resume;
- memory/performance capture for affected mode;
- placeholder/license scanner.

## Golden fixtures

1. `empty_cushion_patient_clear`
2. `empty_cushion_playful_loss`
3. `boundary_stain_normal_replay`
4. `boundary_stain_story_assist`
5. `spell_terms_reimu_win`
6. `spell_terms_marisa_win_accept_loss`
7. `locale_switch_choice_open`
8. `save_resume_pre_minigame`
9. `save_resume_danmaku_phase_2`
10. `journal_replay_no_mutation`

## Content matrix

For each deep route event:
- all visible choice branches;
- minimum and maximum semantic relationship bands;
- comfort toggles;
- EN and JA;
- clear/loss/assist mechanical outcomes;
- event replay;
- save before/after mode;
- absence of unsupported relationship claims.

## Regression priorities

P0:
- data loss;
- route blocker;
- crash/hang;
- untelegraphed unavoidable damage in Story mode;
- input inaccessible;
- missing localization;
- license/provenance failure;
- explicit content or coercion boundary violation;
- deterministic replay divergence affecting save/result.

P1:
- serious characterization error;
- layout clipping;
- performance below target;
- audio warning masked;
- assist not resetting cleanly;
- Journal misinformation.

P2:
- cosmetic animation defect;
- minor audio repetition;
- nonblocking typo;
- debug-only tool inconvenience.

## Test reporting

A test report includes environment, engine patch, build/commit, content hash, commands, pass/fail/skip counts, failures with stable IDs, screenshots/replays, and known nondeterministic components.
