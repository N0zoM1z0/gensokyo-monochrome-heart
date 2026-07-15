# M09 Vertical Slice Stability Soak

## Gate

`tests/integration/run_m09_stability_matrix.gd` is part of `scripts/verify_project.sh` and performs:

- 20 consecutive complete Empty Cushion runs from invitation to explicit shell return;
- 10 consecutive read-only Journal replay cycles against one completed save;
- canonical save comparison after every replay;
- live-object and static-memory sampling after two idle frames per replay;
- clean scene teardown and release-log scanning through the parent verification script.

The gate rejects any live-object growth, any rise on every sampled cycle, or more than 64 KiB of static allocator drift over the ten-cycle replay window.

## 2026-07-16 reference capture

Environment: Godot 4.7.1 stable, Linux headless, Story accessibility preset, English locale.

- Complete runs: 20/20, no crash or route failure.
- Replay cycles: 10/10, no save mutation.
- Live objects: `4142` for every sample; drift `0`.
- Static memory: `39,783,942` to `39,792,182` bytes; allocator drift `8,240` bytes with flat samples between high-water changes.
- Exit diagnostics: no leaked ObjectDB instances or retained resources.

The small static allocator high-water movement is bounded and is not accompanied by retained objects. Before the fix, the same test found deterministic growth of 28 objects and roughly 34 KiB per replay; the cause was an unbounded acceptance-telemetry record history. Journal replay now starts a fresh telemetry session and marks its completion records as replay data.
