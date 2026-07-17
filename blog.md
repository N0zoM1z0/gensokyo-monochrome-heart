# From a Design Archive to a Release Candidate: The Making of *Gensokyo: Monochrome Heart*

*A complete development retrospective, from the first verified design import to the `0.1.0-rc.1` technical handoff — July 15–17, 2026.*

## Before the story begins

This is the record of an unusually concentrated development run. It began with a prepared design archive and an empty implementation repository. It ended with a typed Godot project, a data-authored bilingual campaign, five mechanically distinct regions, twelve deep character routes, production one-bit art and original audio, a large deterministic test system, and reproducible Linux and Windows release-candidate packages.

The word *ended* needs one qualification. The technical goal ended. Public-release approval did not. Human editorial review, external playtesting, owner playthrough feedback, a target-GPU performance capture, and a clean Windows-machine run remain deliberately separate from the automated completion claim. That distinction became one of the most important disciplines of the project: evidence had to say exactly what had happened, never what we merely hoped had happened.

At the final technical handoff, before this retrospective itself was committed, the repository contained:

| Measure | Final value |
| --- | ---: |
| Implementation commits | 223 |
| Tracked files | 2,405 |
| GDScript files | 503 |
| Test scripts | 169 |
| Integration-test scripts | 118 |
| GDScript, Python, and shell lines | 51,214 |
| Runtime characters | 71 |
| Runtime locations | 19 |
| Event graphs | 104 |
| Dialogue beats | 713 |
| Localized strings | 2,065 |
| Music cues | 89 |
| Event nodes | 1,720 |
| Provenance-tracked runtime assets | 63 |
| Candidate version | `0.1.0-rc.1` |
| Content revision | `2026.07.17.1` |
| Save schema | `2` |

The persisted goal reported 137,714 seconds of active execution: **38 hours, 15 minutes, and 14 seconds**. The wall-clock interval from goal creation to completion was 52 hours, 5 minutes, and 32 seconds, including pauses and periods when no active goal time was being charged. The first and last implementation commits were 52 hours, 8 minutes, and 29 seconds apart.

Those figures are not a sensible estimate for a conventional production team. The run depended on a large preproduction package, extreme automation, rapid machine-generated drafting, reusable architecture, parallel bounded analysis, and continuous regression testing. It should be read as a case study in a particular workflow, not as a promise that a normal game of this scope takes two days.

## 1. What we actually started with

The project did not begin as a vague prompt to “make a Touhou game.” It began with a substantial preproduction handoff stored under `preparation/`. The first job was to unpack it, understand it, and decide whether it could serve as an authoritative specification rather than a loose reference pile.

The imported design package covered game design, narrative structure, character contracts, locations, UI and UX, art direction, audio, technical architecture, data schemas, production planning, testing, legal boundaries, and a milestone taskbook. The initial import pinned 570 manifest-controlled files after rechecking every recorded SHA-256 digest. As generated manifests and synchronized material were added, the package validator later reported 575 design files.

That first decision mattered. The archive was copied into the repository as the canonical `design/` tree, while the original compressed bundle remained outside version control. From that point onward, implementation could cite stable, reviewable sources instead of depending on an opaque archive.

The creative promise was unusually specific. Gensokyo was not to be treated as a theme park of recognizable characters. It was supposed to feel like a place made of routines, obligations, weather, food, pride, rumor, grudges, and private habits. Romance would emerge from participation in those routines rather than from collecting affection points. The strongest rewards were small behavioral changes: a cushion left beside Reimu, a camera lowered by Aya, an unfinished task tolerated by Sakuya, or a finite evening chosen by Kaguya.

The design had six central pillars:

1. Monochrome had to function as a language, not as a post-processing filter.
2. Every major location had to change the rules of play.
3. Character truth had to outrank the joke.
4. Romance had to be reciprocal participation, with refusal and boundaries intact.
5. Incidents had to be short enough to replay while still accumulating into longer routes.
6. Comedy had to occur through mechanics as often as through dialogue.

The technical constraints were equally firm. The game would use Godot 4.7 stable and typed GDScript, render internally at 320×180, preserve integer pixel scaling, support English and Japanese from stable localization keys, offer keyboard/controller parity, keep story progression data-authored, expose relationship state semantically rather than numerically, run without a network connection, ship no ripped official material, support accessibility from the first-run flow, and use versioned atomic saves.

Finally, the [Codex Master Taskbook](design/10_codex/CODEX_MASTER_TASKBOOK.md) divided the work into M00 through M19. It did not ask for disconnected prototypes. Its first major proof was an integrated emotional rhythm:

> comic escalation → mechanical climax → quiet sincere afterbeat

The first vertical slice, **The Empty Cushion**, had to move through exploration, bilingual dialogue, a location minigame, danmaku, a compact duel, Journal updates, and save/load as one authored day. Everything after that had to expand the same architecture rather than replace it.

## 2. The operating method

The implementation followed a few rules that made the speed survivable.

### The repository was the source of truth

Every meaningful unit ended in an English, descriptive Git commit. Commits were small enough to identify a coherent proof — content parsing, an atomic save boundary, a route event, a screenshot regression — but large enough to be useful checkpoints. This produced 223 commits rather than a single dramatic dump at the end.

### Validation preceded scale

Stable IDs, schemas, deterministic hashes, negative fixtures, one-bit checks, pixel-alignment checks, and release scans were built before broad content. A bad reference had to fail before the title screen. A placeholder filename had to fail the release channel. A cyclic graph had to fail with the event and node path. This front-loaded work felt slower for the first few hours, then became the reason later route authoring could move quickly without silently corrupting the project.

### Generic systems were kept free of character branches

The architecture separated Domain, Application, Presentation, Infrastructure, Content, and Tools. Presentation could call application services; domain rules could not load scenes or reach into autoloads. Every mode accepted typed context and returned a typed `ModeResult`. A minigame, danmaku pattern, or fighter did not mutate romance or route state directly. The event interpreter consumed its result and applied authored effects transactionally.

That boundary became the central scalability test. The shrine could not be hard-coded into exploration. Sakuya could not appear as an `if character == sakuya` branch inside a generic minigame. Later regions had to arrive as data, typed definitions, and reusable components.

### Failure was evidence, not embarrassment

Several of the best improvements began as failed screenshots, failed exports, or deliberately failing fixtures. The workflow did not hide those failures. It recorded the cause, fixed the system, added a regression, and committed the proof.

### Tool time limits were treated as an orchestration problem

During the later audit, the environment repeatedly stopped long outer tool invocations after roughly forty seconds. This was the source of messages such as “paused at the environment execution limit.” It was not a project runtime limit and it did not erase work. Long verification jobs were split into independently reported batches or resumed through execution sessions. Git checkpoints and the worktree remained intact. Once the final verifier became fast enough and could run through a resumable session, the complete command finished successfully with one exit status.

### Human evidence was never fabricated

Specialist agents could inspect screenshots as simulated players, find clipping, compare locale captures, or audit interaction clarity. They could not become human canon editors, external playtest participants, or listeners using physical speakers. When the owner later chose to defer those gates until personal playthrough feedback, the project recorded the deferral explicitly instead of filling in fake approvals.

## 3. M00 and VA00: making the project reproducible

The first implementation commit after importing the design package established a Godot 4.7.1 project. The engine build was pinned exactly, along with an upstream checksum and a user-local installer. Network downloads could use the requested proxy, but no privileged credential was saved in the repository or scripts.

The project locked its internal canvas to 320×180, used nearest-neighbor texture behavior, integer scale mode, pixel snapping, and the GL Compatibility renderer. Development, QA, demo, and release channels were defined early so debug tools and placeholder material could not accidentally become release defaults.

The visual foundation then established four presentation profiles — Pocket Shrine, PC-98 Dither, Woodblock Adventure, and Midnight LCD — as visual-only resources. They were required to preserve gameplay and state. Strict one-bit validators rejected gray pixels and partial alpha. Pixel-alignment validators rejected fractional Control and Sprite2D positions. Screenshot fixtures rendered at the native 1× canvas before scaling.

The first useful visual failure appeared almost immediately. The Kiri8 bitmap font looked correct as source data but rendered as solid rectangles through the initial AngelCode descriptor route. Screenshot review caught what metric tests had missed. The font pipeline was moved to Godot's image-font importer, its glyph masks and grid were locked, and a regression test was added. The Japanese/Latin DotGothic16 subsets were synchronized with OFL provenance and exact hashes.

Release hygiene also began here. A scanner rejected shipping filenames and identifiers using the placeholder prefix. Preview directories, raw art, and legal test-tone directories were explicitly excluded from release presets. The first unified verifier checked the engine version, design manifest, synchronized content, clean import, content rules, visual rules, deliberate negative fixtures, smoke boot, and screenshot output.

By the end of M00/VA00, the repository was not yet a game, but it was already difficult to damage accidentally.

## 4. M01–M04: shell, content, state, saves, and dialogue

### M01 — a persistent bilingual shell

M01 replaced the minimal boot surface with an always-resident shell containing a 320×180 world viewport, mode host, persistent UI, audio root, transition layer, input routing, and scaling controller. Title, Profile Select, first-run Accessibility, Options, Pause, and a foundation mode all used semantic controls rather than raw keys.

Input mappings supported keyboard and controller, device-aware glyphs, focus restoration across nested modals, remapping, and one-handed presets. Locale switching updated the active screen without restarting it. Low Motion replaced the normal paper-fold transition with a short border transition. Visible text was loaded from stable EN/JA keys rather than embedded in scripts.

### M02 — typed content before gameplay ownership

The content layer parsed characters, locations, event indexes, dialogue beats, choices, localization, and music into explicit records. Raw dictionaries were confined to the infrastructure boundary. Validation aggregated schema failures, duplicate IDs, invalid stable IDs, missing references, unreachable nodes, and source hashes into staged diagnostics.

`ContentDB` only accepted a complete validated snapshot. During development it could detect changed source hashes, parse a candidate, reject invalid edits without losing the active snapshot, and defer hot reload while combat was running. The title route was blocked if the initial content package failed. This eliminated an entire class of late, presentation-layer null errors.

### M03 — one state model, transactional commands, resilient saves

The shared `GameState` modeled the protagonist, 71-character relationship space, regions, flags, rumors, Journal, inventory, Keepsakes, Tea Blends, time, location, route intent, and deterministic RNG. Its five relationship facets — Trust, Ease, Respect, Spark, and Strain — were bounded internally, but player-facing code could only access semantic bands such as low, open, and high.

Mutations passed through typed commands. Each command applied to a deep-copied candidate, validated the complete invariant set, and committed only on success. Multi-effect transactions could roll back as a unit. This mattered later when a route choice changed several flags, relationship facets, and Journal objects at once.

Persistence used canonical JSON, SHA-256 checksums, schema-versioned envelopes, three manual slots, rolling autosaves, temporary writes, backups, and recovery. Tests interrupted writes at every atomic boundary, truncated saves, corrupted checksums, rebuilt stale cards, and migrated a v1 route-affinity fixture into the v2 five-facet relationship model without losing route intent.

### M04 — a deterministic event interpreter

The event interpreter executed music, objectives, dialogue, tone choices, effects, mode handoffs, rewards, Journal changes, and completion nodes. It was step-limited, transaction-aware, resumable at checkpoints, and capable of read-only replay against a private state copy. Automatic effects were guarded against double application after save/load.

The dialogue presenter added grapheme-aware reveal timing, instant text, auto mode, a bounded backlog, nonverbal cues, four semantic tones — Direct, Playful, Patient, and Defiant — and live locale switching without losing choice focus. English wrapping and Japanese kinsoku rules were tested with the actual project fonts.

At the end of M04, the sample Empty Cushion conversation could run every branch in English and Japanese, hand control to mocked mechanics, resume from a save boundary, and reject an authored unbounded cycle.

## 5. M05–M09: building the first complete day

### M05 — Hakurei Shrine exploration

The veranda and adjacent room became a real side-view spot. The player could inspect the second cup, empty cushion, donation box, old tree, door, and broom without pixel-perfect positioning. A passive interaction registry replaced per-object distance polling. The spot owned its event triggers and objective sequence; the player controller did not contain story IDs.

Reimu's **Intuitive Float** companion preview functioned as both character expression and traversal diagnostic. Story hints appeared after a delay. Keyboard, controller, and one-handed traversal used the same interaction grammar.

### M06 — Tea Temperature

Tea Temperature turned domestic care into a deterministic 30–60 second minigame. The player balanced kettle heat, steep time, and two cup temperatures. Maximum heat was not the ideal result; remembered warmth was. Clear, excellent, loss, retry, accept-loss, slower-heat, wider-band, and no-timer paths all returned typed results without mutating the route directly.

The mechanic expressed the scene's emotional idea instead of sitting beside it. Reimu's impatience supplied comedy; the afterbeat made the second cup meaningful.

### M07 — Boundary Stain danmaku

The danmaku foundation used fixed-step simulation, pooled bullet data, batched MultiMesh presentation, authored emitters, telegraph/commit/dissolve states, density scaling, replay recording, Story assists, auto-bomb, contrast controls, and phase retry. The Boundary Stain encounter moved through drifting lanes, offering objects becoming bullets, and a remembered safe lane shifted by one tile.

No damaging Story-mode bullet could appear without a warning. A 2,500-bullet simulation fixture established the CPU-side budget. Importantly, the game borrowed the language of Touhou danmaku without copying official patterns or assets.

### M08 — a compact Reimu/Marisa duel

The fighter foundation added fixed-step combat, input buffers, data-authored frame events, hitboxes and hurtboxes, vitality, Temperament, story AI, simple-input parity, round cleanup, replay fixtures, and assists. Reimu's neutral reset and Marisa's momentum/firepower identity were modeled as mechanics rather than cosmetic labels.

The presentation was required to follow simulation data; animation could not become the sole source of hit timing. Reset tests cleaned projectiles, buffs, hitstop, camera state, and round resources.

### M09 — The Empty Cushion

The integrated day connected the title and profile flow, invitation, world map, shrine exploration, Reimu dialogue, Tea Temperature, Boundary Stain, the Reimu/Marisa duel where appropriate, the second-cup afterbeat, Keepsake and Journal updates, day-end autosave, and Journal replay.

Several integration bugs appeared only after the systems met each other:

- exploration and dialogue could both interpret a shared action until the active mode became the explicit input owner;
- combat tutorials advanced too quickly until confirmation became an authored state;
- completed days needed an explicit safe return to title;
- bilingual text that worked in isolated fixtures clipped in the complete slice;
- save checkpoints needed complete mode and event state, not merely the active event ID;
- repeated Journal replays accumulated acceptance telemetry until every replay became a bounded fresh session.

Each issue produced a fix and a regression. The final M09 stability matrix completed twenty full runs and ten replay cycles without live-object drift or unbounded static-memory growth.

## 6. M10: accessibility and UX as system behavior

M10 did not treat accessibility as a settings page added after the game. It forced every active mode to honor the same presentation and input contracts.

The UI reflowed at 100%, 125%, and 150% scale. Options became paginated rather than shrinking text. Contextual controls displayed the player's actual bindings. Controller glyphs, left-handed and right-handed presets, held-confirm protection, focus restoration, instant text, Low Motion, no-flash variants, combat assists, and accept-loss branches were exercised through the complete slice.

Three content comfort filters — needles, alcohol, and coercive pursuit — were persisted independently and tested together. Enabling all of them could not block plot-critical progress. The project also documented the limits of its custom-drawn UI: no screen-reader support claim was made without the required semantic-control bridge.

Audio gained an explicit mix hierarchy. Warnings and player-critical cues outranked gameplay, UI, ambience, and music; dialogue ducked music by 3 dB; mute could not lose the ducking state. These were still test tones at this stage, but the bus and persistence contracts were production-oriented.

A five-session external playtest protocol was created for two Touhou-aware players, two unfamiliar players, and one accessibility-focused player. It remained empty. Simulated visual reviews were useful for finding layout defects, but they were explicitly not counted as those five people.

## 7. M11: turning implementation into an authoring platform

The project could not scale to a campaign if every new event required editing GDScript. M11 therefore built a data-only authoring loop.

The event authoring tool duplicated The Empty Cushion into an isolated bundle, remapped private IDs, validated schemas and references, checked graph reachability, and rendered deterministic English and Japanese Markdown previews. Dependency reports showed event nodes, dialogue, choices, characters, locations, music, modes, rewards, and Journal links. Width reports used the real fonts, wrapping rules, Japanese kinsoku behavior, and 100%/150% budgets.

A character skills browser exposed the ten-section writing contract for all 71 characters and validated structured agent output. A typed authoring workbench registered 18 exploration, minigame, danmaku, fighter, save, migration, screenshot, and legal-tone fixtures. The Bullet Pattern Lab could duplicate a production pattern, change density and speed, pause, single-step, reload data, visualize emitters and safe lanes, and run deterministic simulations without modifying production content.

This milestone changed the nature of later work. New content became mostly an exercise in composing validated records and reusable components. The tools themselves used the production loaders, so preview success meant more than a separate mock editor saying “looks valid.”

## 8. M12: proving the shrine was not a special case

The Scarlet Devil Mansion was the architecture reuse test. Its event, **Late by Three Minutes**, moved through a foyer investigation, Sakuya tone choices, a time-grid service challenge, a missing-minute knife escalation, a quiet afterbeat, a Patchouli teaser, and Remilia public/private scenes.

Time Grid Service used a deterministic 3×3 service queue. The player stopped time to move and queue stations, then released Focus to let service time advance. The Missing Minute danmaku introduced knife lattices, rotating clock hands, and long-telegraph stopped releases through reusable pattern components.

The exploration system accepted a mansion spot definition rather than gaining mansion branches. The slice coordinator was refactored behind typed slice definitions and a stable mode-scene registry. A dedicated architecture scanner searched generic runtime code for Sakuya- or mansion-specific behavior and reported none.

The second region also received full-flow, save/resume, accessibility, localization, screenshot, and replay coverage. This was the point at which the architecture stopped being a proposal and became demonstrated reuse.

## 9. M13: the five-region campaign backbone

M13 expanded one chapter at a time rather than authoring a hundred disconnected events.

The Youkai Mountain chapter added structured rumor confidence and mutation, Wind-Frame photo grazing, a trail exploration spot, **Tomorrow's Headline**, and consequences that propagated into later regions. Aya's camera frame was both a capture mechanic and a social boundary.

Eientei and the Bamboo Forest added the **Four Dawns** loop topology and a multi-minigame framework for **Five Possible Impossibilities**. Hakugyokurou added **Soul Garden**, where collection and release mattered more than simple accumulation. The existing shrine and mansion chapters were folded into the same campaign backbone.

The Archive finale prototype then adapted to strategies the player had actually recorded: how they navigated, grazed, accepted loss, used assists, or approached earlier problems. It did not merely read a final score. Route-independent reveals and cross-region state made the campaign feel like one world rather than five menu entries.

By the end of M13, all five headline regions — Hakurei Shrine, Scarlet Devil Mansion, Youkai Mountain/Moriya, Eientei/Bamboo, and Hakugyokurou — had chapter-complete playable proofs.

## 10. M14: twelve routes without turning characters into rewards

M14 was the largest content expansion. The taskbook required five to seven core events per route, non-romantic goals, a boundary test, a mechanical expression of the character's flaw or value, a conflict that flattery could not solve, a quiet afterbeat, semantic finale prerequisites, and outcomes that did not erase autonomy.

The twelve routes were built in an order that alternated factions and production needs:

### Reimu Hakurei

Reimu's route began with **Offerings Without Owners**, then moved through a quiet-day routine, route-intent persistence, a guesthouse boundary, an unasked rescue, and an Archive refusal. Her Promise finale depended on practiced respect rather than a maximized hidden number.

### Marisa Kirisame

Marisa received the **Broom Backseat** minigame, **Crash Landing**, **Field Notes**, a shelf boundary, a talent conflict, a weather rescue, an Archive refusal, and a Promise finale. Help had to coexist with her competence; the protagonist could not solve her by praising her talent.

### Sakuya Izayoi

Sakuya's route used corridor terms, a midnight kitchen, an explicit consent boundary, a tea favor, and a missing-minute refusal before its finale. The route repeatedly asked whether competence could leave room for choice and incompletion.

### Youmu Konpaku

Youmu's Garden Shift, paired-body crossing, delegated watch, open conflict boundary, finished meal, guarded farewell, and Promise finale made trust visible as delegated responsibility rather than reassurance.

### Aya Shameimaru

Aya's Exclusive Interview, Wind-Frame Graze, Hidden Folder, visible correction, camera-down scene, withheld headline, and consent-led Promise all revolved around information power. Lowering the camera had to be an action with consequences, not a decorative pose.

### Kaguya Houraisan

Kaguya's route opened through an optional impossible errand and chosen hospitality, then allowed a one-life game to remain lost. It confronted mortality honestly, let Mokou name the cost of rivalry, allowed dawn to arrive without the Archive, and ended with finite moments chosen rather than eternity won.

### Patchouli Knowledge

Patchouli's events made breathing room in the library, rewarded a question rather than an answer, preserved shared silence, replaced a borrowing caricature with terms, held a spell unfinished, left the answering book incomplete, and indexed a future without turning knowledge into ownership.

### Remilia Scarlet

Remilia's route entered a foretold audience by choice, guided silhouettes through mist, let her rest behind the throne without diminishing her, repaired the room after the wrong laugh, protected quietly without overriding choice, broke an allegedly infallible proof, and required declared fate to wait for an answer.

### Yuyuko Saigyouji

The bottomless banquet learned to listen. One joke made room for fear; an ended meal left an empty plate; solemnity was refused as proof of depth; a festival changed before anyone paid; the impossible bowl was overturned; and the final sweet waited for an answer.

### Sanae Kochiya

Sanae planned faith without a master score, translated shorthand she had already changed, repaired a home without erasing another, counted attention without claiming belief, mended what the next road required, returned guaranteed faith to the unknown, and asked before the camera left its case.

### Eirin Yagokoro

Eirin separated evidence from diagnosis, treated patient refusal as a complete answer, gave small care exact attention, rejected a body offered as proof, made rest an audited choice, refused perfection without a patient, and promised only the next appointment. Medical authority was never allowed to stand in for consent.

### Tenshi Hinanawi

Tenshi made her entrance answerable, built a bridge without an audience, let an imperfect meal remain useful, made attention ask permission, repaired a boundary without witnesses, refused a heaven calibrated for boredom, and made a promise that retained an exit.

Scaling the route corpus exposed a serious performance flaw in content validation. Dependency indexing had become quadratic as graphs multiplied. The implementation replaced repeated scans with indexed lookups, restoring practical validation times. CSV sources also had to be made safe for Godot import, while the design sources remained canonical.

Every route received integration coverage, registered gate checks, and real predecessor-state fixtures. Finales were tested against practiced route state, not synthetic flags that skipped the route. Explicit binary consent choices were validated as content contracts. This did not constitute human characterization approval, but it made the material consistently reviewable.

## 11. M15: seventy-one characters without seventy-one false promises

M15 integrated all 71 roster entries into runtime roles. The design never intended 71 launch romance routes, so the implementation distinguished deep-route leads, support characters, cameos, regional roles, and postgame availability.

Every runtime profile resolved to its `skills.md` contract. Sparse-canon characters remained conservative. The postgame Dream Theatre was labeled outside main continuity, and Ensemble Accord eligibility required compatible choices and boundaries rather than the collection of every character. The UI made those continuity promises visible so experimental postgame material could not masquerade as canon campaign state.

This milestone also tightened asset provenance. Release approval became a per-file ledger decision linked to review evidence rather than a directory-level assumption.

## 12. M16: replacing placeholders with a production pipeline

M16 replaced geometric and test-tone foundations with project-original or properly licensed runtime assets.

The final asset ledger contained 63 records:

- one project-original Kiri8 bitmap font and two licensed DotGothic16 subsets;
- eight Model L fighter sheets;
- eight Model M exploration sheets;
- eight portrait packs;
- five region tilesets;
- one twelve-family bullet library;
- one UI export;
- two standard/reduced accessibility VFX atlases;
- fifteen adaptive music stems across five regional families;
- twelve bounded sound effects.

The music and sound effects were deterministically synthesized from project-authored oscillator, envelope, and noise definitions. They used no imported samples and transcribed no official melody. Every authored `music_state` across 104 event graphs resolved to a deliberate cue family; unknown future states failed instead of falling back silently.

Production art was wired into fighter presentation, exploration, portraits, danmaku, minigames, regions, and UI rather than merely copied into an asset folder. Palette polarities, reduced/no-flash VFX, mix persistence, mono behavior, dynamic-range settings, voice limits, and non-audio warning equivalents remained part of the runtime contract.

Three independent simulated-player review passes were used for visual inspection. Their final broad pass did not simply approve everything. It found three actionable problems:

1. Parallel Youkai Mountain screenshot fixtures shared an atomic-save temporary path and could show a checkpoint error.
2. High-load readback could capture incomplete Quiet Chore locale art.
3. The Half-Phantom tutorial placed a bilingual core rule on one clipped line.

The mountain fixture gained phase- and process-isolated save roots plus a dedicated checkpoint gate. Quiet Chore gained sequential capture and per-region EN/JA ink-equality checks. The Half-Phantom instructions gained bounded pixel-width wrapping and unit coverage for full text and line width. The affected images were recaptured and reviewed again.

Real speaker/headphone listening was different. Headless amplitude and bus tests could prove hierarchy and persistence, but not fatigue, comfort, or physical-device audibility. A listening worksheet was created. The owner explicitly waived it as a completion blocker, so the record says “waived,” not “heard and approved.”

## 13. M17: making human review possible without pretending it happened

The M17 validator assembled objective editorial evidence for 85 shipped event graphs. It required visible casts, bilingual titles/dialogue/choices/objectives, nonverbal cues, width budgets, origin labels, comfort metadata, character-profile links, and fanon limits.

The automated audit covered 1,488 canonical bilingual localization rows and all 71 character profiles. It inventoried sensitive markers instead of silently treating them as safe: 13 consent references, 3 medical references, 73 patient references, 2 photo references, 1 privacy reference, and 18 romance references. It also reported six cast pairs lacking a curated relationship edge as editorial prompts.

Normal readiness mode passed. Strict mode, `--require-human-review`, intentionally failed because no named character, canon, English, or Japanese reviewers had approved all eleven passes for every event. A generator produced an 85-event template with blank reviewer names and every pass marked `pending`; it did not place that template at the strict approval path.

The owner then directed that all human-audit requirements should be non-blocking for this technical goal and would be revisited after personal play. The decision was recorded in [the owner-deferred review record](docs/reviews/m17_m10_owner_deferred_review.md). The strict future-release gate remained intact.

## 14. M18: performance, stability, accessibility, and privacy

M18 hardened the project under realistic content load.

The final audited evidence included:

| Area | Result |
| --- | --- |
| 2,500-bullet simulation | 0.924 ms p95 in the M18 audit; zero dropped spawns; under the 3.5 ms budget |
| Full 2,500-bullet presentation | 32.256 ms p95 under Mesa llvmpipe; structural pass, timing issue retained |
| Fighter presentation | 10.426 ms p95 with two fighters, 128 projectiles, and 40 effects |
| Replay/memory soak | 20 complete runs and 10 replay cycles with no object drift |
| Locale soak | Five live route states × 80 EN/JA switches with no state or memory drift |
| Save recovery | M09, M12, and M13 corruption/resume matrices passed |
| Input interruption | Controller reconnect and focus-loss pause behavior passed |
| Accessibility | Mandatory M09/M12 routes completed through Story, Low Motion, and one-handed configurations |
| Privacy | Telemetry schema rejected paths, authored dialogue, and protagonist-name leakage |

The rendering caveat was important. The CPU-side bullet pool was comfortably within budget, but llvmpipe is a software rasterizer and did not meet the 16.67 ms full-render target. The report did not convert that measurement into a target-hardware failure or success. It retained a requirement for a comparable integrated-GPU capture before publishing minimum specifications.

Local telemetry was restricted to build/content identifiers, an internal profile ID, locale-free phase/result/timing/attempt data, and a reviewed schema. Tests rejected new fields by default and searched for personal paths, dialogue fragments, and protagonist names. The game had no runtime network dependency.

## 15. M19: turning the repository into verifiable packages

The release-candidate pipeline installed the official Godot 4.7.1 export templates only after checking their SHA-256 against the official GitHub release metadata. It validated synchronized content and runtime assets before export, generated a package manifest and `SHA256SUMS`, and included credits, fan-work notice, save compatibility, known issues, store-copy draft, and support/privacy documentation.

Linux received the strongest available packaging proof. The release script exported a portable binary and PCK into a fresh directory, started it with an isolated `XDG_DATA_HOME`, scanned its smoke log for errors, verified every packaged hash, moved the whole install directory away from its original path, and confirmed user data remained separate. That approximated install/run/uninstall behavior for a portable Linux package.

Windows received a real x86_64 cross-export with `.exe`, `.pck`, manifest, documentation, and checksums. It did not receive a real Windows clean-machine launch, so the repository contains a protocol for that future evidence rather than claiming compatibility from cross-export alone.

One of the most consequential release bugs involved localization. Godot treats translation CSV files as import sources and strips the source CSV from the PCK. The development build could therefore load content that disappeared in export. The fix generated deterministic raw-text mirrors under `content/runtime/` for all 89 localization CSV files and the music cue table. Release code read those mirrors, while authoring continued to use the canonical CSV sources. The exported game then loaded all 71 characters, 19 locations, 104 events, 713 beats, 2,065 strings, and 89 cues with no ContentDB errors.

The final preflight found another packaging warning. Godot's platform metadata accepted numeric dotted versions but rejected `0.1.0-rc.1` as the engine application version. The project separated the numeric engine version (`0.1.0`) from the candidate label (`0.1.0-rc.1`). Package names, documentation, and release manifests retained the candidate label without generating the platform-version warning.

The same preflight briefly attempted to exclude `.godot/uid_cache.bin` and the global script-class cache from the PCK. A guarded build failed because Godot intentionally packs those indexes with compiled resources. The assumption was reverted rather than forcing a superficially “cleaner” but potentially broken package. This small episode captured the larger approach: when the evidence contradicted an intuition, the build was allowed to win the argument.

The official [Touhou Project fan-work guideline](https://touhou-project.news/guideline/) was rechecked on July 17. The package clearly identified itself as unofficial, included generated credits, contained no official/ripped assets, and assigned no storefront, price, crowdfunding plan, or public support contact. Those omissions were intentional: the technical package existed before the publishing decision.

## 16. What the final architecture looked like

The completed project retained the layer boundaries proposed at the beginning:

```text
Content and input
      ↓
typed ContentDB + semantic commands
      ↓
Domain rules and transactional GameState
      ↓
application coordinators and mode contracts
      ↓
presentation scenes, audio, UI, and effects
      ↓
typed ModeResult returned to the event interpreter
      ↓
checkpointed state change and optional replay record
```

Several design choices did most of the long-term work:

- **Stable IDs instead of file paths in saves.** Content could move without invalidating state.
- **One shared typed state model.** Exploration, dialogue, minigames, danmaku, fighters, Journal, and postgame did not invent separate truth.
- **Commands and candidate-state validation.** Invalid multi-effect outcomes rolled back cleanly.
- **Mode results without route mutation.** Mechanics expressed conflict but did not decide social meaning by themselves.
- **Data-authored event graphs.** New routes reused the interpreter and authoring tools.
- **Deterministic fixed-step mechanics.** Replay and performance fixtures could compare exact outcomes.
- **Persistent shell, UI, audio, and focus.** Scene swaps did not reset accessibility or navigation state.
- **Runtime content mirrors with canonical authoring sources.** Export requirements did not degrade editorial reviewability.
- **Per-file provenance.** Release approval could be traced from package discovery to ledger record, hash, rights, and evidence.

The resulting repository was large, but its complexity remained inspectable. A route event could be followed from localization row and graph node through typed parsing, predicate evaluation, mode handoff, result tag, command transaction, save checkpoint, Journal object, screenshot fixture, and release package.

## 17. The defects that taught us the most

The development history is easier to understand through its failures than through its feature list.

### A font can pass metadata tests and still be unreadable

Kiri8's first importer preserved dimensions and references but destroyed the visible masks. The fix established screenshot evidence as a first-class test rather than a decorative artifact.

### Shared input is not semantic input

Mapping every action was insufficient when multiple active scenes could consume it. Explicit mode ownership and focus restoration were required to make remapping reliable.

### Atomic saves still need unique temporary ownership

The save writer was atomic for one process, but parallel screenshot fixtures collided on the same temporary path. Isolation had to include profile, phase, and process identity.

### Screenshot capture is asynchronous work

Rendering a frame and reading it back immediately was not reliable under load. Quiet Chore exposed partial captures. Sequential capture and content-aware image assertions were more useful than simply checking that a PNG existed.

### Correct algorithms become wrong at campaign scale

The original dependency validator was logically correct but quadratic. It passed the vertical slice and became painful across twelve routes. Indexing transformed validation from a scaling blocker back into a routine gate.

### Development imports are not release files

The CSV/PCK issue proved that a clean editor run says nothing about source-file availability after export. Release smoke tests had to inspect the packaged runtime, not reuse the development tree.

### Platform metadata and product labels serve different constraints

Separating numeric engine versioning from the human-facing RC label removed a warning without erasing release semantics.

### Performance claims need hardware context

The bullet simulation passed, the software renderer did not meet 60 fps, and neither fact justified a minimum-GPU claim. The known issue remained open.

### Automation must know where judgment ends

The M17 validator could prove bilingual completeness, metadata, fanon ceilings, width budgets, and marker inventories. It could not prove that Eirin sounded right in Japanese or that a romance scene felt respectful to a human reader. Keeping the strict human gate deliberately red was a feature.

## 18. Verification as a product feature

By the M16 audit, the verification system reported 36 unit suites with zero failures, 114 positive integration scripts, eleven deliberate negative gates, all milestone screenshot matrices from VA00 through M15, strict one-bit validation, and pixel-alignment checks. M18 added locale-soak and privacy hardening. M19 added reproducible export and package verification.

The final full command checked, among other things:

- the exact Godot version;
- the design-package manifest;
- synchronized content, fonts, runtime mirrors, and generated indexes;
- typed parsing and source-located diagnostics;
- one-bit pixels and integer geometry;
- placeholder and provenance release rules;
- deterministic saves, migrations, replays, and mode results;
- every major campaign and route integration;
- input, accessibility, locale, comfort, and interruption matrices;
- stress and stability fixtures;
- M17 automated review readiness plus the intentionally failing incomplete-human-review fixture;
- generated screenshot matrices;
- Linux release export, isolated launch, hashes, and portable uninstall simulation.

The final release scan covered 1,174 files with zero errors. The provenance scan reported 63 registered and 63 discovered runtime assets. Linux and Windows manifests both recorded `0.1.0-rc.1`, content revision `2026.07.17.1`, save schema 2, nine package files, and the final source commit `c15003982a78d8703a2791713f9f4415d6a523cd`. Every listed SHA-256 verified.

The test system was not just a safety net. It was what made the compressed schedule possible. Once a generic contract was covered, later content could reuse it with confidence. When broad content exposed an assumption, the fix went into the shared layer and the regression remained for every later chapter.

## 19. Collaboration and token accounting

The run used one primary goal thread and 21 child-agent threads over its lifetime. Child agents handled bounded analysis, content work, and visual/player-perspective passes; the root thread retained integration ownership and final verification.

The persisted Goal meter recorded **29,663,792 tokens**. That number is a goal-budget consumption metric, not the sum of every raw model request. The local goal database stores only the total, so it cannot be decomposed exactly into input, output, cached input, and reasoning.

The JSONL traces do contain that raw breakdown. Across the root and all 21 child threads during the goal window, the model processed:

| Raw trace category | Tokens |
| --- | ---: |
| Input | 11,899,433,216 |
| Cached input (a subset of input) | 11,569,787,648 |
| Uncached input | 329,645,568 |
| Output | 40,413,874 |
| Reasoning output (a subset of output) | 11,199,961 |
| Non-reasoning output | 29,213,913 |
| Raw input + output | 11,939,847,090 |

The enormous raw input figure is mostly repeated context served from cache; it is not unique authored text and should not be interpreted as an equivalent uncached cost. Approximately 97.2% of the recorded input was cached. The root thread alone accounted for 1,067,918,992 input tokens, of which 1,041,466,112 were cached, plus 3,511,958 output tokens.

These statistics are included because the project was explicitly an experiment in sustained agentic development. They also explain why repository discipline mattered: a long-running context needs durable files, tests, and commits because conversational memory alone is not an adequate project database.

## 20. What was completed, and what was consciously left for people

The technical goal was marked complete. That statement means:

- M00–M19 implementation work was present;
- the complete automated gate passed;
- production assets were integrated and provenance-tracked;
- Linux and Windows packages were reproducible and checksummed;
- the tracked worktree was clean;
- the final commits recorded missing Godot script UIDs and separated engine/candidate version metadata.

It does **not** mean:

- five external players completed the M10 protocol;
- named editors approved all M17 canon, characterization, EN, JA, consent, comfort, and terminology passes;
- a human listener completed the speaker/headphone worksheet;
- a target-class GPU met the full 2,500-bullet rendering budget;
- the Windows package ran on a clean Windows machine;
- a storefront, price, public support contact, or launch date was selected;
- the owner completed the promised personal playthrough.

The owner explicitly authorized human audit, external playtest, and real-device listening as non-hard requirements for this goal. The owner will play the result and provide feedback in a later repair pass. That is a valid development handoff, but it is not permission to erase the pending work from a public-release checklist.

The repository's only deliberately untracked root file at handoff was `droid.resume.txt`, which identifies the resumable session and explicitly says not to delete, track, or commit it. All project changes were committed.

## 21. Final reflections

The most surprising result of this run was not the amount of content. It was how much the early constraints shaped the later speed.

Typed state made twelve routes manageable. Stable IDs made content migration and replay possible. Transactional commands made complex choices safe. A shared mode contract let tea, time-grid service, photo grazing, soul release, danmaku, and fighter encounters participate in one narrative interpreter. One-bit and localization validators turned visual style into enforceable engineering. Per-file provenance turned “we think these assets are safe” into a queryable release fact.

The creative rules mattered just as much. Asking whose desire drove an event, why it belonged to a location, what the player actually did, what changed afterward, and whether the idea remained clear in one-bit art prevented many systems from becoming generic spectacle. The best route events were not confessions. They were changed habits, delegated duties, repaired boundaries, unanswered questions, cameras put down, meals allowed to remain imperfect, and promises that preserved an exit.

The run also demonstrated the limits of automation. A validator can prove that every route has bilingual copy; it cannot feel whether the Japanese voice is alive. A screenshot agent can detect clipping; it cannot become an accessibility-focused external player. An amplitude test can prove a warning is louder than ambience; it cannot report headphone fatigue. A cross-export can produce a Windows executable; it cannot become a clean Windows machine.

That is why the project ends this phase in a useful place rather than a triumphant fiction. The code, content, tools, assets, tests, and packages are ready for the owner to play. The next development cycle begins with that experience: where the pacing drags, where a joke misses, where a control feels awkward, where a route feels earned, and where the world finally feels less like a catalog and more like Gensokyo.

The technical sprint is complete. The player's version of the story starts now.

---

## Repository references

- [Project vision](design/00_project/vision.md)
- [Design principles](design/00_project/design_principles.md)
- [Codex Master Taskbook](design/10_codex/CODEX_MASTER_TASKBOOK.md)
- [Godot architecture](design/08_technical/godot_architecture.md)
- [Testing strategy](design/08_technical/testing_strategy.md)
- [M16 cross-system audit](docs/reviews/m16_cross_system_audit.md)
- [M17 review-readiness audit](docs/reviews/m17_content_review_readiness.md)
- [Owner-deferred human review record](docs/reviews/m17_m10_owner_deferred_review.md)
- [M18 hardening audit](docs/reviews/m18_hardening_audit.md)
- [M19 release-candidate audit](docs/reviews/m19_release_candidate_audit.md)
- [Windows clean-machine protocol](docs/release/WINDOWS_CLEAN_MACHINE_PROTOCOL.md)
