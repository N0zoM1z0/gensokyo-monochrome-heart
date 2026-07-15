# Koakuma — Production Modeling Brief
## 小悪魔

- **Production tier:** C
- **Region / faction:** Scarlet Devil Mansion / Voile Library
- **Route scope:** Minor support
- **Source character contract:** `04_characters/koakuma/skills.md`

## Silhouette lock

small bat wings, bob hair, pointed tail and book-carrying silhouette

- Primary prop: book stack / library key
- Separate child/FX layer: wings and tail layer
- Preferred presentation profiles: B

## Motion lock

- Idle: balances books; wing tips correct the weight.
- Talk/gesture: peeks around the stack, then offers the relevant volume.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

busy competence, curiosity, minor-devil mischief

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

archive work; dust mask; formal library service

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
