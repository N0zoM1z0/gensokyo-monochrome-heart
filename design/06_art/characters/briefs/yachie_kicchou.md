# Yachie Kicchou — Production Modeling Brief
## 吉弔 八千慧

- **Production tier:** C
- **Region / faction:** Animal Realm / Kiketsu Family
- **Route scope:** Support antagonist
- **Source character contract:** `04_characters/yachie_kicchou/skills.md`

## Silhouette lock

antlers, turtle-dragon tail and elegant command posture

- Primary prop: fan / command seal
- Separate child/FX layer: tail and faction-emblem layer
- Preferred presentation profiles: B, D

## Motion lock

- Idle: tail curls while the upper body remains diplomatically still.
- Talk/gesture: one finger or fan edge redirects the room.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: 4 boss silhouettes
- Portrait 80×104: 3 expressions/working states

## Portrait direction

soft-spoken control, pressure, strategic courtesy

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

Kiketsu formal; negotiation cloak; battlefield command

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
