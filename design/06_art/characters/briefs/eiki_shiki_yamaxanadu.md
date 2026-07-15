# Eiki Shiki, Yamaxanadu — Production Modeling Brief
## 四季映姫・ヤマザナドゥ

- **Production tier:** B
- **Region / faction:** Higan / Ministry of Right and Wrong
- **Route scope:** Major support
- **Source character contract:** `04_characters/eiki_shiki_yamaxanadu/skills.md`

## Silhouette lock

judge cap, formal robe column and unmistakable rod

- Primary prop: Rod of Remorse
- Separate child/FX layer: verdict tablet layer
- Preferred presentation profiles: B, C

## Motion lock

- Idle: nearly motionless; rod angle changes one pixel.
- Talk/gesture: rod indicates the issue, not the person, until the final beat.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 4–8 dramatic poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

measured concern, severity, reluctant warmth

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

court formal; field inspection cloak

Variants reuse anchors but may replace the silhouette. Never clip a long skirt or large sleeve onto an incompatible skeleton.

## 1-bit rules

- Visible pixels are #000000 or #FFFFFF; ordered dither is a material region, never facial antialiasing.
- Validate on white and inverted fields. If inversion merges the prop into the body, author an inverted override.
- Test at 1× in peripheral vision and as a solid silhouette.
- Do not trace official or fan sprites; identity comes from original pixel construction around canonical accessories.

## Acceptance

- [ ] solid silhouette
- [ ] white field
- [ ] inverted field
- [ ] 1x peripheral read
- [ ] anchor loop
- [ ] no copied sprite geometry
