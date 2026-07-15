# Keine Kamishirasawa — Production Modeling Brief
## 上白沢 慧音

- **Production tier:** C
- **Region / faction:** Human Village / history guardian
- **Route scope:** Support route
- **Source character contract:** `04_characters/keine_kamishirasawa/skills.md`

## Silhouette lock

teacher cap or horned form, book and upright village-guardian stance

- Primary prop: history book / chalk
- Separate child/FX layer: page and horn-form layer
- Preferred presentation profiles: A, B, C

## Motion lock

- Idle: turns one page, pauses to listen outside.
- Talk/gesture: points to text or corrects a date with a small chalk gesture.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

teacherly patience, vigilance, embarrassment

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

school work; night guard; hakutaku event form

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
