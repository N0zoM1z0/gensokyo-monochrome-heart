# Nue Houjuu — Production Modeling Brief
## 封獣 ぬえ

- **Production tier:** C
- **Region / faction:** Myouren Temple circle / unidentified youkai
- **Route scope:** Support route
- **Source character contract:** `04_characters/nue_houjuu/skills.md`

## Silhouette lock

trident, asymmetrical wings and deliberately conflicting shape language

- Primary prop: trident / unidentified seed
- Separate child/FX layer: UFO/seed and shifting-wing layer
- Preferred presentation profiles: C, D

## Motion lock

- Idle: one side of the silhouette changes category.
- Talk/gesture: trident stays still while a companion shape lies about its form.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

teasing ambiguity, loneliness, guarded affiliation

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

temple casual; night scare; identified/quiet set

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
