# Product Backlog

Priorities: **P0** vertical-slice/release blocker, **P1** core game, **P2** expansion/polish. Status begins `TODO`.

| ID | P | Milestone | Task | Acceptance evidence |
|---|---:|---|---|---|
| ENG-001 | P0 | M00 | Lock Godot 4.7 stable patch and document installation | clean import log records exact version |
| ENG-002 | P0 | M00 | Create repository/layer folders | tree matches documented structure or ADR explains deviation |
| ENG-003 | P0 | M00 | Headless content validator entry point | valid starter data passes; invalid fixture fails |
| ENG-004 | P0 | M00 | Stable-ID registry and duplicate detection | duplicate ID fixture reports both files |
| ENG-005 | P0 | M00 | Reference and localization-key resolution | missing references block dev boot |
| ENG-006 | P0 | M00 | CI import/test/validate skeleton | fresh CI run produces artifacts |
| ENG-007 | P0 | M00 | Release placeholder scanner | deliberate ph_ asset blocks release channel |
| ENG-008 | P1 | M00 | Credits/license data model | test record renders deterministic credits |
| UI-001 | P0 | M01 | Fixed 320x180 viewport and integer scaling | pixel grid screenshots at 2x/3x/4x |
| UI-002 | P0 | M01 | Persistent shell and ModeHost | mode swaps without recreating UI/audio roots |
| UI-003 | P0 | M01 | Input action abstraction/remapping | keyboard/controller complete navigation |
| UI-004 | P0 | M01 | Title/options/pause screens | focus/cancel tests pass EN/JA |
| UI-005 | P0 | M01 | First-run accessibility preset | profile stores preset and can change later |
| UI-006 | P0 | M01 | Runtime locale switch | active screen reflows without restart |
| UI-007 | P1 | M10 | Nonnumeric ResonanceTell component | fixture shows object cue and Journal note |
| UI-008 | P1 | M10 | Backlog and auto/instant text | 200-line backlog and settings tests |
| UI-009 | P1 | M10 | One-handed presets | full slice completed with each preset |
| UI-010 | P1 | M10 | Low Motion/no-flash transitions | screenshot/video comparison |
| DAT-001 | P0 | M02 | Typed character/location/event records | no raw dictionary escapes parser boundary |
| DAT-002 | P0 | M02 | ContentDB indexes and queries | deterministic query tests |
| DAT-003 | P1 | M02 | Content hot reload in dev | edited localization/event refreshes safely |
| STA-001 | P0 | M03 | GameState and nested state classes | deep-equality fixture |
| STA-002 | P0 | M03 | Command dispatcher and validation | positive/negative tests per command |
| STA-003 | P0 | M03 | Five relationship facets and bands | band boundary tests; no numeric UI |
| STA-004 | P0 | M03 | Deterministic RNG state | same seed produces same sequence |
| SAV-001 | P0 | M03 | Atomic manual/autosave writes | power-loss simulation retains previous save |
| SAV-002 | P0 | M03 | Checksum and backup recovery | corrupt current file recovers backup |
| SAV-003 | P0 | M03 | Migration chain and fixtures | all historical fixtures migrate |
| SAV-004 | P1 | M03 | Save-card metadata/screenshot | slot screen loads without full payload |
| EVT-001 | P0 | M04 | Step-limited event interpreter | sample graph reaches every authored end |
| EVT-002 | P0 | M04 | Transactional effects and rollback | forced effect failure leaves state unchanged |
| EVT-003 | P0 | M04 | Choice predicates and semantic bands | visible/disabled/hidden fixture matrix |
| EVT-004 | P0 | M04 | Mechanical mode suspend/resume | mock result resumes exact node |
| EVT-005 | P0 | M04 | Graph reachability/cycle validator | unreachable/unbounded fixtures fail |
| DLG-001 | P0 | M04 | Dialogue beat presenter | EN/JA layout and advance tests |
| DLG-002 | P0 | M04 | Four-tone choice fan | input focus and actual intent text |
| DLG-003 | P0 | M04 | Backlog/replay isolation | replay does not mutate main state |
| DLG-004 | P1 | M11 | Character-agent output validator | schema and guardrail violations rejected |
| EXP-001 | P0 | M05 | Side-view movement/collision | 60Hz jitter and ledge tests |
| EXP-002 | P0 | M05 | Interactive registry and action contracts | player controller has no object-class switches |
| EXP-003 | P0 | M05 | Interaction magnetism/context prompt | all objects usable under keyboard/controller |
| EXP-004 | P1 | M05 | Companion skill interface | Reimu float diagnostic uses data ID |
| EXP-005 | P1 | M05 | Navigation hint/objective HUD | hint timing configurable |
| MIN-001 | P0 | M06 | Shared Minigame interface/host | fixture minigame returns ModeResult |
| MIN-002 | P0 | M06 | Tea Temperature simulation/UI | clear/excellent/loss deterministic |
| MIN-003 | P0 | M06 | Minigame assists and accept loss | all branches tested |
| MIN-004 | P1 | M11 | Minigame fixture launcher | any minigame starts from definition |
| DAN-001 | P0 | M07 | Fixed-step player and arena | movement/focus replay deterministic |
| DAN-002 | P0 | M07 | Pooled bullet data and renderer | no Node per bullet; pool exhaustion safe |
| DAN-003 | P0 | M07 | Pattern emitter/phase data | three-phase sample data-authored |
| DAN-004 | P0 | M07 | Telegraph/spawn/commit states | Story-mode spawn rule test |
| DAN-005 | P0 | M07 | Shot/bomb/graze/Margin | unit/integration fixtures |
| DAN-006 | P0 | M07 | Density/speed/auto-bomb assists | four density screenshots/replays |
| DAN-007 | P0 | M07 | Phase retry/Assist Clear/accept loss | event return matrix |
| DAN-008 | P0 | M07 | Deterministic replay recorder | golden replay CI |
| DAN-009 | P1 | M07 | 2,500-bullet stress/profile | capture and bottleneck report |
| DAN-010 | P1 | M11 | Bullet Pattern Lab | designer edits and previews pattern |
| FIG-001 | P0 | M08 | Fixed-step fighter/input buffer | frame-step deterministic fixture |
| FIG-002 | P0 | M08 | Data-driven moves/frame events | no hit timing from animation alone |
| FIG-003 | P0 | M08 | Hitbox/hurtbox system/viewer | visual audit screenshot |
| FIG-004 | P0 | M08 | Vitality/Temperament/spell breaks | round flow fixture |
| FIG-005 | P0 | M08 | Reimu/Marisa mechanics | distinct neutral/momentum tests |
| FIG-006 | P0 | M08 | Story AI and accept loss | no infinite lock; branch matrix |
| FIG-007 | P0 | M08 | Simple-input and accessibility modes | parity test |
| FIG-008 | P1 | M08 | Replay/training frame step | golden duel replay |
| INT-001 | P0 | M09 | World map/day desk/travel flow | complete slice route |
| INT-002 | P0 | M09 | Empty Cushion authored event | P0 narrative matrix pass |
| INT-003 | P0 | M09 | Keepsake and Journal update | save/load/replay correctness |
| INT-004 | P0 | M09 | Adaptive music-state placeholder | bar-safe transitions and mute controls |
| TOL-001 | P1 | M11 | Event Graph Previewer | nonprogrammer duplication proof |
| TOL-002 | P1 | M11 | Localization width/screenshot runner | EN/JA report artifact |
| TOL-003 | P1 | M11 | Dependency graph viewer | orphan and cycle visibility |
| TOL-004 | P1 | M11 | Save migration harness | all fixtures selectable |
| CNT-001 | P1 | M12 | Late by Three Minutes event | full Sakuya loop and afterbeat |
| CNT-002 | P1 | M13 | Tomorrow’s Headline mountain chain | photo-graze/rumor systems integrated |
| CNT-003 | P1 | M13 | Four Dawns Eientei chain | loop topology and consent event |
| CNT-004 | P1 | M13 | Petal on Hold Hakugyokurou chain | soul release mechanics |
| CNT-005 | P1 | M13 | Archive final prototype | uses recorded strategy without unfair read |
| RTE-001 | P1 | M14 | Reimu deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-002 | P1 | M14 | Marisa deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-003 | P1 | M14 | Sakuya deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-004 | P1 | M14 | Youmu deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-005 | P1 | M14 | Aya deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-006 | P1 | M14 | Kaguya deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-007 | P1 | M14 | Patchouli deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-008 | P1 | M14 | Remilia deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-009 | P1 | M14 | Yuyuko deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-010 | P1 | M14 | Sanae deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-011 | P1 | M14 | Eirin deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| RTE-012 | P1 | M14 | Tenshi deep route implementation | route checklist, EN/JA, clear/loss/assist, finale sign-off |
| ART-001 | P1 | M16 | Lock Model M sprite standard | core cast silhouette/readability review |
| ART-002 | P1 | M16 | Five headline region tilesets | collision/readability/polarity review |
| ART-003 | P1 | M16 | Eight launch fighter sets | hitbox anchors and VFX variants |
| AUD-001 | P1 | M16 | Adaptive music stem integration | rights records and transition tests |
| AUD-002 | P1 | M16 | SFX pooling/mix/mono cues | mix matrix and voice-limit test |
| LOC-001 | P0 | M17 | Complete EN/JA review | zero missing keys, character sign-off |
| CAN-001 | P0 | M17 | Canon/fanon/original audit | all events reviewed against skills profiles |
| ACC-001 | P0 | M18 | Mandatory encounter accessibility pass | Story/Low Motion complete full game |
| PER-001 | P0 | M18 | Stress and soak suite | budgets measured and leaks resolved |
| REL-001 | P0 | M19 | Final asset/license/fanwork audit | signed release checklist |
| REL-002 | P0 | M19 | Clean-machine export tests | supported platforms install/run/uninstall |
| REL-003 | P0 | M19 | Manifest/rollback/support packet | hashes, previous build, known issues ready |

**Starter backlog count:** 102 tasks. Expand content tasks only after the vertical slice passes P0.
