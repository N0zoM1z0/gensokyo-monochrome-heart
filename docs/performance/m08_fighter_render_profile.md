# M08 Compact Fighter Render Profile

Date: 2026-07-15 (Asia/Singapore)

## Environment

- Godot `4.7.1.stable.official.a13da4feb`, X11/OpenGL compatibility renderer
- Linux `6.6.87.2-microsoft-standard-WSL2` x86_64
- Intel Core i9-13900H, 20 logical CPUs visible
- Renderer: Mesa `llvmpipe (LLVM 20.1.2, 256 bits)`
- Fixture: `tests/performance/run_m08_fighter_render_stress.gd`

## Method

The fixture renders the complete 320×180 fighter presentation with two fighter
sprites, the HUD and stage, exactly 64 projectiles owned by each fighter, and
40 simultaneous effect marks. It warms 12 frames, measures 120 redraws, and
explicitly synchronizes each frame through `RenderingServer.force_draw(false)`.
V-Sync is disabled. The provisional full-frame target is p95 at or below
16.67 ms.

The structural gate always requires two fighters, 128 active projectiles, 40
effects, and zero dropped projectile spawns. The timing result is reported but
does not hide a structurally valid fixture on a software renderer.

## Measurements

| Submission strategy | Average | p95 | Maximum | 16.67 ms result |
|---|---:|---:|---:|---|
| Per-projectile/effect CanvasItem primitives, run 1 | 27.275 ms | 42.005 ms | 49.028 ms | Over budget |
| Per-projectile/effect CanvasItem primitives, run 2 | 32.191 ms | 46.383 ms | 73.484 ms | Over budget |
| Per-projectile/effect CanvasItem primitives, run 3 | 24.257 ms | 39.370 ms | 59.264 ms | Over budget |
| Four texture MultiMeshes, run 1 | 27.780 ms | 39.870 ms | 62.432 ms | Over budget |
| Four texture MultiMeshes, run 2 | 14.887 ms | 19.295 ms | 21.739 ms | Over budget |
| Four texture MultiMeshes, run 3 | 22.597 ms | 29.731 ms | 34.162 ms | Over budget |

The final implementation submits amulet, star, laser, and effect silhouettes in
four fixed-capacity texture batches. It has no Node per projectile and retains
the exact family shapes and one-bit contrast. A multiline prototype was also
rejected because llvmpipe's line tessellation made it substantially slower.

## Conclusion

The fixture is structurally correct on every run, but it does not meet the
16.67 ms p95 target under llvmpipe. The large run-to-run variance and software
rasterizer identity are recorded rather than presented as target-hardware
performance. A hardware-GPU capture on the target integrated-graphics class is
required before closing the full-frame budget.
