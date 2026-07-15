# Remilia Scarlet — Production Modeling Brief
## レミリア・スカーレット

- **Production tier:** A
- **Region / faction:** Scarlet Devil Mansion
- **Route scope:** Deep route; launch fighter
- **Source character contract:** `04_characters/remilia_scarlet/skills.md`

## Silhouette lock

tiny body, cap, bat wings and exaggerated authority/spear line

- Primary prop: Gungnir / parasol
- Separate child/FX layer: wing and fate-thread layer
- Preferred presentation profiles: B, C, D

## Motion lock

- Idle: wings hold a throne-like triangle while one foot hovers.
- Talk/gesture: spear or finger makes a grand claim; body remains small and certain.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk + 2 interact
- Model M 24×32: 4 idle + 8 walk + 4 talk + 6 interact + 4 reaction
- Model L 32×48: full fighter/danmaku key set
- Portrait 80×104: 9 expressions/working states

## Portrait direction

command, theatricality, private dependence

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

parasol day set; throne cape; night formal

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
