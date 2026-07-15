# Risk Register

Scale: Probability (P) and Impact (I) from 1–5. Score = P × I. Reassess at every milestone.

| ID | Risk | P | I | Score | Trigger | Mitigation / response |
|---|---|---:|---:|---:|---|---|
| R01 | Scope explosion from 71 characters and 100+ events | 5 | 5 | 25 | milestone velocity below 70% plan; text/assets grow without cuts | vertical slice gate; tier characters; chapter batches; explicit cut order |
| R02 | Hybrid modes feel disconnected | 4 | 5 | players describe “three minigames in one package” | every event shares state and emotional rhythm; integrated slice before expansion |
| R03 | Character mischaracterization / meme flattening | 4 | 5 | review finds one-joke scenes or unsupported relationship claims | skills.md, fanon dial, character reviewer, origin tags, route autonomy checklist |
| R04 | Japanese dialogue feels translated or inconsistent | 4 | 5 | native review rewrites most lines | parallel EN/JA authoring, native editor early, terminology and screenshot pass |
| R05 | Danmaku unreadable in 1-bit | 4 | 5 | bullets disappear against background or shape families collide | shape grammar, outline/background dim, density tiers, stress screenshots |
| R06 | Fighter scope consumes the whole project | 4 | 4 | per-character fighter cost exceeds route event cost | launch eight maximum; compact move sets; cut roster before story/accessibility |
| R07 | Save migration breaks long campaign | 3 | 5 | schema changes lack fixtures; public saves fail | migrations from day one, golden saves, stable IDs, atomic backups |
| R08 | Official/unlicensed asset enters build | 3 | 5 | reference file appears in assets or rights record missing | no official placeholders, provenance database, release scanner, rights owner |
| R09 | Music rights/arrangements delayed | 4 | 4 | cue remains reference-only near content lock | original fallback motifs, family/stem plan, commission early, cue-level gates |
| R10 | Runtime performance collapses under bullets/effects | 3 | 5 | stress fixture misses frame budget | pooled structs, fixed-step, early 2,500-bullet test, profile before content expansion |
| R11 | Accessibility added too late | 3 | 5 | mandatory patterns cannot scale; UI architecture fixed | presets and assists in vertical slice, per-encounter acceptance, external testing |
| R12 | Relationship system becomes hidden-score metagame | 4 | 4 | guides reduce routes to point optimization | semantic observations, multi-facet tradeoffs, route understanding gates, no number UI |
| R13 | Harem source material pushes coercive/sexualized framing | 3 | 5 | scene treats authority/intoxication/injury as consent | PG-13 boundary policy, adaptation matrix, comfort alternatives, review gate |
| R14 | Protagonist erases cast autonomy | 4 | 4 | every event motive is “win protagonist” | non-romantic motive and independent success required per route/event |
| R15 | Tooling lags and writers edit code | 4 | 4 | event changes require engineer for every line/branch | M11 tools before broad content; data schemas and previewer |
| R16 | External dependency/addon becomes unmaintained | 2 | 4 | engine upgrade blocked by addon | no addon without ADR/license/maintenance plan; narrow adapter; vendor only if necessary |
| R17 | Godot engine patch differences break build | 3 | 3 | developer/CI versions diverge | exact stable patch lock, clean import CI, upgrade test branch |
| R18 | Pixel-art workload underestimated | 4 | 4 | portrait/animation backlog dominates | model tiers, silhouette-first, reuse anchors, lock eight fighters, cut variants |
| R19 | 89 cues interpreted as 89 unique commissions | 3 | 4 | audio budget spikes | arrangement families and adaptive stems; original fallbacks; priority tiers |
| R20 | Team burnout / unpaid crunch | 4 | 5 | repeated overtime, slipping reviews, quality drop | stop/go gates, scope cuts, transparent estimates, no hidden overtime assumption |
| R21 | Community expectations around ships/fanon conflict | 4 | 3 | feedback argues project declares fan pairing canon | Canon/Fanon/Original labeling, optional routes, no canon-romance claims, respectful credits |
| R22 | Storefront/fan-work rules change | 2 | 5 | policy or platform updates after lock | recheck at public milestones, conservative release options, ability to change storefront |
| R23 | Source archive adaptation remains too episodic | 4 | 4 | main campaign feels like random festival sketches | 6-chapter Archive spine, event thesis, quiet afterbeats, Dream Theatre separation |
| R24 | AI-assisted drafts leak without review | 2 | 5 | generated text enters localization DB directly | offline workflow, provenance, schema/lint plus human gates, no runtime generation |
| R25 | Mod-friendly data exposes unsafe arbitrary scripting | 3 | 4 | event JSON executes scripts or file paths | audited node/component IDs only; sandboxed data; validation and content signatures |

## Top-risk actions now

1. Do not expand beyond the Empty Cushion slice before P0 passes.
2. Lock Japanese editorial capacity before promising bilingual release dates.
3. Prototype 1-bit danmaku contrast and three sprite scales immediately.
4. Build save migrations and stable IDs before content quantity grows.
5. Commission/test one legal-safe arrangement family early.
