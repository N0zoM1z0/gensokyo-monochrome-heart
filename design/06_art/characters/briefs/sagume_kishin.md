# Sagume Kishin — Production Modeling Brief
## 稀神 サグメ

- **Production tier:** B
- **Region / faction:** Lunar Capital
- **Route scope:** Late-game support
- **Source character contract:** `04_characters/sagume_kishin/skills.md`

## Silhouette lock

single wing, short lunar silhouette and hand held near the mouth

- Primary prop: tablet / arrow motif
- Separate child/FX layer: single wing and reversal-text layer
- Preferred presentation profiles: B, C, D

## Motion lock

- Idle: wing freezes whenever she almost speaks.
- Talk/gesture: one minimal gesture replaces a sentence; text card may reverse after.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk
- Model M 24×32: 4 idle + 4 walk + 4 talk + 2 reaction
- Model L 32×48: 4–8 dramatic poses
- Portrait 80×104: 6 expressions/working states

## Portrait direction

restraint, consequence-aware tension, oblique trust

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

lunar formal; battlefield cloak; dream interference

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
