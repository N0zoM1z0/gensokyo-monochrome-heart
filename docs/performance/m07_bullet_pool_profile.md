# M07 Packed Bullet Pool Profile

Date: 2026-07-15 (Asia/Singapore)

## Environment

- Godot `4.7.1.stable.official.a13da4feb`, headless compatibility build
- Linux `6.6.87.2-microsoft-standard-WSL2` x86_64
- Intel Core i9-13900H, 20 logical CPUs visible
- Fixture: `tests/performance/run_m07_bullet_pool_stress.gd`

## Method

The fixture fills a fixed-capacity packed-array pool with exactly 2,500 committed
bullets, then measures 240 fixed updates. It includes lifecycle, fixed-point
motion, arena retirement, and lifetime checks. It intentionally excludes
render submission and player collision; those require the M07 stress scene and
must not be inferred from this result.

The provisional pool gate is p95 at or below 3.5 ms, matching the mode-gameplay
simulation allowance in `design/08_technical/performance_budget.md`.

## Measurements

| Revision | Average | p95 | Maximum | Result |
|---|---:|---:|---:|---|
| Initial repeated packed-array reads | 2.578 ms | 4.023 ms | 7.047 ms | Over budget |
| Cached hot-path values, run 1 | 1.300 ms | 2.131 ms | 2.407 ms | Pass |
| Cached hot-path values, run 2 | 1.386 ms | 2.059 ms | 2.459 ms | Pass |
| Cached hot-path values, run 3 | 1.272 ms | 2.029 ms | 2.292 ms | Pass |

All post-change runs retained 2,500 active bullets with zero dropped spawns.
The optimization changes only repeated array reads; deterministic lifecycle and
golden replay results remain covered by the unit suite.

## Presentation render stress

The companion fixture `tests/performance/run_m07_render_stress.gd` runs through
the X11/OpenGL compatibility path at 320×180. It warms 12 frames, then measures
120 complete redraws with an explicit render synchronization. Every measured
frame contains 2,500 source bullets and 2,500 visible instances, the full HUD,
and the one-bit post-process. V-Sync is disabled. The current environment exposes
Mesa `llvmpipe (LLVM 20.1.2, 256 bits)`, so this is a software-renderer bottleneck
measurement rather than a proxy for the target integrated GPU.

| Submission strategy | Average | p95 | Maximum | 16.67 ms result |
|---|---:|---:|---:|---|
| Per-bullet CanvasItem primitives | 75.370 ms | 91.667 ms | 98.224 ms | Over budget |
| Two aggregated multiline buffers | 51.827 ms | 64.312 ms | 75.090 ms | Over budget |
| Eight texture MultiMeshes, run 1 | 27.716 ms | 35.378 ms | 59.740 ms | Over budget |
| Eight texture MultiMeshes, run 2 | 29.235 ms | 39.916 ms | 57.139 ms | Over budget |
| Eight texture MultiMeshes, run 3 | 29.229 ms | 42.020 ms | 50.511 ms | Over budget |

The final strategy has no bullet nodes and streams one transform into one of
eight lifecycle/family/polarity batches. It reduces average full-frame time by
about 62% from the first rendered version while retaining the three silhouettes,
paper/ink cores, telegraphs, and dissolve state. The remaining measured
bottleneck is software rasterization plus 2,500 per-redraw instance transform
updates. The fixture emits `within_budget: false` honestly while failing only if
the source/visible count or zero-drop structural contract is broken.

## Conclusion

The packed simulation pool meets its 3.5 ms provisional budget on this machine.
The final rendered stress scene does not meet 16.67 ms under llvmpipe, and M07
therefore records the open renderer bottleneck instead of claiming a 60 fps
result. A hardware-GPU capture on target-class integrated graphics is still
required before setting minimum hardware or closing the full-frame budget.
