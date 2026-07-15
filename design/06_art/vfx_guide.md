# VFX and Danmaku Shape Guide

## 1. Bullet families

In 1-bit, shape replaces color. Every bullet family has a unique silhouette and motion signature.

| Family | Shape | Motion meaning |
|---|---|---|
| amulet | tall rectangle with notch | homing / correction |
| needle | 1 × 5 line with bright tip | fast direct pressure |
| orb | ring with black/white core inversion | stable radial field |
| star | 5-point pixel spark | accelerating magic |
| knife | asymmetric diamond + tail | delayed time release |
| butterfly | two-lobe shape | drifting curve / death motif |
| leaf | angled teardrop | wind lanes |
| arrow | chevron + shaft | aimed zoning |
| shard | irregular triangle | break / Flandre / corruption |
| plate | flat ellipse | ricochet / Taoist geometry |
| spirit | comma flame | slow attraction / soul collection |
| keystone chip | square with crack | gravity / grounded hazard |

Shape must remain readable at 70% bullet-density assist.

## 2. Telegraph phases

1. **Source pose** — boss/body cue.
2. **Guide mark** — line, ring, or floor shadow.
3. **Spawn** — bullet appears but cannot damage for 2–8 frames depending on speed.
4. **Commit** — damage active.
5. **Dissolve** — clean removal or reward conversion.

No bullet may become damaging on the same frame it first becomes visible in story mode.

## 3. Memory effects

The Archive is shown through violations of the normal 1-bit rules:
- a sprite repeats one frame late;
- a dither patch does not move with its object;
- a panel edge remains after the panel closes;
- an object appears in both polarities;
- a safe lane resembles an earlier event but shifts by one tile;
- handwritten pixels overwrite machine-straight lines in the finale.

Avoid generic VHS noise except in Outside World device scenes.

## 4. Hit and impact

- light hit: 2-frame white burst, 3–5 px;
- heavy hit: 1 inversion frame + 4-frame wedge burst;
- graze: two crescent pixels and a quiet tick;
- bomb: expand negative-space circle that erases bullets by category;
- fighter counter: rectangular “stamp” impact, not a screen-filling flash;
- damage numbers are off by default; training can show them.

## 5. Character-specific VFX grammar

- Reimu: clean circles, gaps, amulet rows, effortless drift.
- Marisa: hard stars, beam rectangles, smoke wedges, overexposure inversion.
- Sakuya: frozen guide lines, suspended knives, clock ticks.
- Remilia: bat-wing arcs, spear diagonals, fate-line intersections.
- Patchouli: geometric elemental layers with distinct shapes, not colors.
- Youmu: delayed slash line, spirit comma, two-stage cut.
- Aya: wind hatching and camera-frame capture boxes.
- Kaguya: impossible objects with rules that change the arena.
- Tenshi: floor fracture, stone squares, weather-field borders.

## 6. Accessibility variants

Every effect provides:
- no-flash version;
- reduced-particle version;
- thicker-outline version;
- low-motion version;
- background-dim compatibility;
- monochrome inversion test screenshot.
