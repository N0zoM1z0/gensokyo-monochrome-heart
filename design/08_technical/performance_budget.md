# Performance Budget

## 1. Target hardware

Desktop-first target: a modest integrated GPU and four-core CPU capable of current Godot 4.x desktop rendering. Exact minimum specification is established after the vertical slice and published only from measured builds.

Target:
- 60 fps fixed simulation;
- frame time under 16.67 ms;
- 1% low target above 55 fps in ordinary content;
- title-to-gameplay under 5 seconds on reference SSD;
- mode swap under 1.5 seconds after assets are cached;
- memory target under 1 GB in headline regions; vertical slice under 600 MB.

## 2. Frame budget

| Area | Budget |
|---|---:|
| domain/application simulation | 1.5 ms |
| mode gameplay simulation | 3.5 ms |
| collision | 2.0 ms |
| rendering submission | 4.5 ms |
| UI/layout | 1.0 ms |
| audio/update | 0.5 ms |
| scripting/GC margin | 1.5 ms |
| safety margin | 2.17 ms |

Budgets are guidance; profile on target hardware.

## 3. Danmaku

- design stress: 2,500 visible bullets;
- story normal typical: 500–1,200;
- reduced-density tier: 55–70%;
- bullets stored in packed arrays/pools;
- broad-phase spatial grid or arena partition;
- custom/batched rendering after profiling;
- no Node per bullet;
- collision computes only player-vs-bullet and required cancels;
- bullets outside padded arena retire immediately;
- SFX uses grouped emitters.

## 4. Fighter

- fixed 60 Hz;
- maximum 64 active projectiles/effects per fighter before pooling/merging policy;
- hitbox checks use small typed arrays;
- animation texture atlas per character/context;
- stage has two parallax layers plus optional foreground;
- camera and UI allocations must be zero in steady-state rounds.

## 5. Exploration

- 80 animated crowd actors stress target;
- off-screen actors update at reduced cadence if noninteractive;
- TileMap layers chunked by region/room;
- particles capped by region profile;
- navigation is simple side-view; avoid heavyweight pathfinding where steering suffices;
- object prompts use registry/spatial query, not every object polling player distance.

## 6. UI and localization

- layout cached until text, locale, or scale changes;
- Journal pages virtualize long lists;
- portrait layers preloaded per event cast;
- no per-frame string formatting;
- glyph coverage and font fallback profiled in Japanese;
- screenshot/debug overlays excluded from release performance captures.

## 7. Memory

- one headline region resident at a time plus shared cast cache;
- route leads can retain portrait sets; other portraits unload by LRU policy;
- audio streams compressed appropriately, seamless loops tested;
- source-resolution art never shipped if only atlas exports are used;
- debug resources stripped from release exports.

## 8. Performance gate

A feature cannot be accepted on “the final build will optimize it.” Every milestone includes a stress fixture and capture. Optimization must preserve deterministic rules and accessibility variants.
