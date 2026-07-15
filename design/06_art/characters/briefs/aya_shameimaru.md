# Aya Shameimaru — Production Modeling Brief
## 射命丸 文

- **Production tier:** A
- **Region / faction:** Youkai Mountain / Bunbunmaru Newspaper
- **Route scope:** Deep route; launch fighter and danmaku lead
- **Source character contract:** `04_characters/aya_shameimaru/skills.md`

## Silhouette lock

tokin cap, wing wedge, camera and notebook, geta stance

- Primary prop: camera / feather fan
- Separate child/FX layer: wings, strap and newspaper layers
- Preferred presentation profiles: A, B, D

## Motion lock

- Idle: camera strap shifts while her eyes keep tracking.
- Talk/gesture: camera rises, shutter cuts one frame, then she lowers it only if sincere.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle + 4 walk + 2 interact
- Model M 24×32: 4 idle + 8 walk + 4 talk + 6 interact + 4 reaction
- Model L 32×48: full fighter/danmaku key set
- Portrait 80×104: 9 expressions/working states

## Portrait direction

professional smile, predatory curiosity, camera-lowered sincerity

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

press armband; mountain patrol coat; rain cape

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
