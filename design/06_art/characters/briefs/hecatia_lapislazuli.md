# Hecatia Lapislazuli — Production Modeling Brief
## ヘカーティア・ラピスラズリ

- **Production tier:** B
- **Region / faction:** Hell / Earth, Moon, and Otherworld
- **Route scope:** Major support / late-game challenge
- **Source character contract:** `04_characters/hecatia_lapislazuli/skills.md`

## Silhouette lock

collar and chain, casual dress, three unmistakable planet spheres

- Primary prop: planet sphere
- Separate child/FX layer: three orbiting world layers
- Preferred presentation profiles: C, D

## Motion lock

- Idle: worlds rotate at different periods while she slouches casually.
- Talk/gesture: one world replaces another at the point of emphasis.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 4–8 dramatic poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

casual cosmic authority, humor, sudden seriousness

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

Earth casual; Moon formal; Otherworld inversion

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
