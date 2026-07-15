# Junko — Production Modeling Brief
## 純狐

- **Production tier:** B
- **Region / faction:** Lunar conflict / purified divine spirit
- **Route scope:** Late-game support/antagonist
- **Source character contract:** `04_characters/junko/skills.md`

## Silhouette lock

vast hair mass, crown/halo geometry, long purified robe and orbs

- Primary prop: purification orb
- Separate child/FX layer: aura and orb layer
- Preferred presentation profiles: C, D

## Motion lock

- Idle: everything holds except one perfectly regular orb.
- Talk/gesture: one hand rises; surrounding clutter disappears rather than explodes.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 8–16 boss/fighter key poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

purity, grief held at distance, frightening clarity

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

lunar conflict robe; quiet post-conflict mantle

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
