# M18 Performance, Accessibility, and Stability Hardening Audit

Date: 2026-07-17 (Asia/Singapore)
Scope: the repository's deterministic P0/P1 gates and the available Linux
headless/Xvfb environment. This report deliberately does not turn a software
rasterizer measurement into a target-hardware performance claim.

## Result

The automated hardening gates pass. The remaining performance evidence gap is
explicitly documented: 2,500 fully rendered danmaku bullets exceed the
16.67 ms target under Mesa llvmpipe, while the deterministic simulation is
well within budget. The project must retain that known issue until a real
target-class integrated-GPU capture is attached; it is not reported as a pass.

| Requirement | Evidence | Result |
| --- | --- | --- |
| 2,500-bullet simulation | `run_m07_bullet_pool_stress.gd`: p95 0.924 ms; 2,500 active; zero drops | Pass |
| Full danmaku presentation | `run_m07_render_stress.gd`: 2,500 source/rendered; 32.256 ms p95 on llvmpipe | Structural pass; timing issue recorded |
| Fighter presentation | `run_m08_fighter_render_stress.gd`: 2 fighters, 128 projectiles, 40 effects; 10.426 ms p95 on llvmpipe | Pass in this environment |
| Replay/memory soak | `run_m09_stability_matrix.gd`: 20 completed runs, 10 replay cycles, zero object drift | Pass |
| Save corruption/recovery | M09, M12, and M13 save/resume matrices; atomic-write unit cases | Pass |
| Controller interruption and focus loss | M01 flow disconnect/reconnect/focus-loss pause checks | Pass |
| EN/JA switching soak | `run_m18_locale_switch_soak.gd`: five live route states × 80 toggles; no route/state/object/memory retention | Pass |
| Low Motion/no-flash and assists | M09 four-scenario and M12 two-scenario accessibility matrices | Pass |
| Telemetry/privacy boundary | `TestVerticalSliceServices`: exact telemetry schema plus no path, dialogue, or protagonist-name leakage | Pass |

## Commands included in the release gate

`scripts/verify_project.sh` now invokes the M18 locale soak after the M09
stability matrix. It runs with the verification script's isolated
`XDG_DATA_HOME`, so saved language preferences and telemetry cannot leak
between test jobs. The full suite also retains the M07 packed-pool gate, M09
and M12 accessibility matrices, M09/M12/M13 recovery matrices, all unit
suites, content validation, release validation, and visual matrices.

## Accessibility and route completion

The M09 matrix completes the mandatory Empty Cushion route through keyboard and
controller configurations in both Story and Low Motion modes, including
one-handed left/right presets and the all-comfort-filter configuration. It
checks Story assists, Low Motion no-flash presentation, and an Assist Clear
for the mandatory danmaku encounter. The M12 matrix repeats that contract for
the Scarlet Devil Mansion route. Losses remain accepted outcomes rather than
progress blocks.

## Privacy review boundary

Local acceptance telemetry is written atomically beneath `user://` and is
limited to build/content identifiers, an internal profile identifier, and
locale-free phase/result/timing/attempt records. Its unit test rejects new
document or record fields unless that schema review is updated, and rejects
personal filesystem paths, authored dialogue, and the protagonist name. This
matches the release policy in `design/08_technical/build_release.md`: no full
save, personal path, protagonist name, or free-form dialogue enters default
logs.

## Known issue and release hand-off

The M07 renderer has no per-bullet Nodes and keeps all 2,500 source bullets
visible in the stress scene, but the available renderer is Mesa llvmpipe. Its
M18 p95 was 32.256 ms versus the 16.67 ms target. The CPU pool itself passes at
0.924 ms p95. Before publishing minimum hardware or claiming the full render
budget closed, M19 needs one comparable capture on the declared target
integrated-GPU class. The detailed measurements are retained in
`docs/performance/m07_bullet_pool_profile.md` and
`docs/performance/m08_fighter_render_profile.md`.
