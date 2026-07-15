# Momiji Inubashiri — Production Modeling Brief
## 犬走 椛

- **Production tier:** C
- **Region / faction:** Youkai Mountain / white wolf tengu patrol
- **Route scope:** Support route
- **Source character contract:** `04_characters/momiji_inubashiri/skills.md`

## Silhouette lock

wolf ears/tail, round shield and scimitar patrol silhouette

- Primary prop: shield / blade
- Separate child/FX layer: ear and tail layer
- Preferred presentation profiles: A, D

## Motion lock

- Idle: ears scan opposite directions before the shield shifts.
- Talk/gesture: shield tap or map-pointing gesture.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

professional caution, territorial pride, dry camaraderie

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

mountain patrol coat; off-duty scarf; storm lookout

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
