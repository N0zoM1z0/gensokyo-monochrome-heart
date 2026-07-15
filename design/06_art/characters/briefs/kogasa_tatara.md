# Kogasa Tatara — Production Modeling Brief
## 多々良 小傘

- **Production tier:** C
- **Region / faction:** Wandering karakasa / cemetery vicinity
- **Route scope:** Support route
- **Source character contract:** `04_characters/kogasa_tatara/skills.md`

## Silhouette lock

asymmetric karakasa outfit dominated by one-eyed umbrella

- Primary prop: karakasa umbrella
- Separate child/FX layer: umbrella eye/tongue layer
- Preferred presentation profiles: A, C, D

## Motion lock

- Idle: umbrella blinks before she moves.
- Talk/gesture: sudden pop-in gesture followed by checking whether it worked.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

eagerness to surprise, hurt pride, warmth

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

rain set; cemetery night; festival repair

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
