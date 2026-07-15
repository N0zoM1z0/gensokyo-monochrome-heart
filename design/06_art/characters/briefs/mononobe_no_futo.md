# Mononobe no Futo — Production Modeling Brief
## 物部 布都

- **Production tier:** C
- **Region / faction:** Senkai / Taoist
- **Route scope:** Support route
- **Source character contract:** `04_characters/mononobe_no_futo/skills.md`

## Silhouette lock

small cap, Taoist robe, plates and boat/fire geometry

- Primary prop: plate / ritual vessel
- Separate child/FX layer: plate orbit and flame layer
- Preferred presentation profiles: A, B, D

## Motion lock

- Idle: one plate spins with old-fashioned ceremony.
- Talk/gesture: broad archaic gesture that nearly loses a plate.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

archaic confidence, literalism, competitive zeal

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

mausoleum work; festival robe; fire ritual set

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
