# Flandre Scarlet — Production Modeling Brief
## フランドール・スカーレット

- **Production tier:** C
- **Region / faction:** Scarlet Devil Mansion
- **Route scope:** Support route; high-safety writing review
- **Source character contract:** `04_characters/flandre_scarlet/skills.md`

## Silhouette lock

cap, small body and two crystal-laden wing rods

- Primary prop: wand / crystal prism
- Separate child/FX layer: eight crystal children with fixed spacing
- Preferred presentation profiles: B, C, D

## Motion lock

- Idle: crystals rotate one step while her body remains intent.
- Talk/gesture: crouches closer or tilts one prism; avoid generic manic bouncing.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

intense curiosity, isolation, careful trust

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

mansion daywear; supervised garden cape; dream silhouette

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
