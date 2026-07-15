# Tewi Inaba — Production Modeling Brief
## 因幡 てゐ

- **Production tier:** C
- **Region / faction:** Eientei / earth rabbits
- **Route scope:** Support route
- **Source character contract:** `04_characters/tewi_inaba/skills.md`

## Silhouette lock

rabbit ears, compact dress and trap/coin shapes hidden near the feet

- Primary prop: luck charm / trap / coin
- Separate child/FX layer: ear and hidden-trap layer
- Preferred presentation profiles: A, B

## Motion lock

- Idle: ears twitch toward opportunity, not sound.
- Talk/gesture: coin vanishes between hands while the smile stays innocent.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

calculation, playfulness, community longevity

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

Eientei errands; festival vendor; forest prank set

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
