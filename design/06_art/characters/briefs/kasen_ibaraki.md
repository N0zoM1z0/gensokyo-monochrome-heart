# Kasen Ibaraki — Production Modeling Brief
## 茨木 華扇

- **Production tier:** B
- **Region / faction:** Hermit / Gensokyo sage-associated
- **Route scope:** Major support
- **Source character contract:** `04_characters/kasen_ibaraki/skills.md`

## Silhouette lock

twin buns, one bandaged arm, fitted Chinese dress and animal accents

- Primary prop: staff / bandaged arm
- Separate child/FX layer: animal companion and bandage layer
- Preferred presentation profiles: A, C

## Motion lock

- Idle: bandage curl moves while posture stays corrective.
- Talk/gesture: an animal reacts to what she refuses to say directly.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 4–8 dramatic poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

admonition, care, concealed identity

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

hermit workwear; shrine visit cloak; sealed-arm event set

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
