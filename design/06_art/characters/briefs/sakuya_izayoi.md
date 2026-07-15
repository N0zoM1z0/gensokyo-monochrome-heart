# Sakuya Izayoi — Production Modeling Brief
## 十六夜 咲夜

- **Production tier:** A
- **Region / faction:** Scarlet Devil Mansion
- **Route scope:** Deep route; launch fighter and danmaku lead
- **Source character contract:** `04_characters/sakuya_izayoi/skills.md`

## Silhouette lock

maid headpiece, triangular skirt, white apron axis and knife/watch lines

- Primary prop: knife fan / pocket watch
- Separate child/FX layer: headpiece, watch and knife layer
- Preferred presentation profiles: A, B, D

## Motion lock

- Idle: checks one minute with almost no body motion.
- Talk/gesture: precise hand rise; knife fan only when context warrants.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk + 2 interact
- Model M 24×32: 4 idle + 8 walk + 4 talk + 6 interact + 4 reaction
- Model L 32×48: full fighter/danmaku key set
- Portrait 80×104: 9 expressions/working states

## Portrait direction

professional neutrality, dry humor, private fatigue

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

rolled kitchen sleeves; formal tailcoat; rain service coat

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
