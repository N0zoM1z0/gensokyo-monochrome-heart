# Ran Yakumo — Production Modeling Brief
## 八雲 藍

- **Production tier:** C
- **Region / faction:** Yakumo household / boundaries
- **Route scope:** Support route
- **Source character contract:** `04_characters/ran_yakumo/skills.md`

## Silhouette lock

fox ears, hat, nine-tail fan and formal shikigami posture

- Primary prop: charm / calculation scroll
- Separate child/FX layer: nine tail layers and formula glyph
- Preferred presentation profiles: A, B, C

## Motion lock

- Idle: tails move in a slow solved pattern.
- Talk/gesture: writes a formula in air or redirects one tail toward the task.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

competence, calculation, household tenderness

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

household work; boundary patrol; formal shikigami

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
