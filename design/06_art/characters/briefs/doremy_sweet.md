# Doremy Sweet — Production Modeling Brief
## ドレミー・スイート

- **Production tier:** B
- **Region / faction:** Dream World
- **Route scope:** Major support
- **Source character contract:** `04_characters/doremy_sweet/skills.md`

## Silhouette lock

nightcap, soft robe, dream-tail curl and floating orb silhouette

- Primary prop: dream orb / pillow
- Separate child/FX layer: dream bubbles and tail layer
- Preferred presentation profiles: C, D

## Motion lock

- Idle: body barely moves while bubbles drift out of phase.
- Talk/gesture: reshapes one orb into the subject of the sentence.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 4–8 dramatic poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

gentle distance, clinical dream-reading, sly amusement

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

sleep-clinic wrap; dream librarian; nightmare inversion

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
