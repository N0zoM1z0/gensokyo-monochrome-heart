# Byakuren Hijiri — Production Modeling Brief
## 聖 白蓮

- **Production tier:** B
- **Region / faction:** Myouren Temple
- **Route scope:** Major support; fighter expansion
- **Source character contract:** `04_characters/byakuren_hijiri/skills.md`

## Silhouette lock

long two-tone-implied hair, layered monk robes, broad calm sleeves

- Primary prop: scroll / lotus light
- Separate child/FX layer: beads and lotus glyph layer
- Preferred presentation profiles: B, C, D

## Motion lock

- Idle: beads settle after the sleeve, never bouncy.
- Talk/gesture: open palm and level gaze; power is shown by stillness.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 8–16 boss/fighter key poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

compassion, resolve, restrained physical power

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

temple work robe; travel mantle; formal sermon robe

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
