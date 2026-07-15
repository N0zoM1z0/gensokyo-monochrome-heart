# Nitori Kawashiro — Production Modeling Brief
## 河城 にとり

- **Production tier:** C
- **Region / faction:** Youkai Mountain / kappa engineering
- **Route scope:** Support route
- **Source character contract:** `04_characters/nitori_kawashiro/skills.md`

## Silhouette lock

cap, large backpack, wrench and pipe/gadget silhouette

- Primary prop: wrench / optical device
- Separate child/FX layer: backpack valves and camouflage layer
- Preferred presentation profiles: A, B, D

## Motion lock

- Idle: one valve spins; backpack weight shifts.
- Talk/gesture: unfolds a schematic or demonstrates a mechanism too close.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

engineering delight, sales instinct, social caution

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

work overalls; rain gear; market sales set

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
