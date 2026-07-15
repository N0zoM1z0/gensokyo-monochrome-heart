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

## Conclusion

The packed simulation pool now meets its provisional budget on this machine.
This is not yet a claim that a rendered 2,500-bullet frame meets 16.67 ms; M07
presentation profiling must add batched drawing, HUD, and frame-time evidence.
