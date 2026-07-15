# Rinnosuke Morichika — Production Modeling Brief
## 森近 霖之助

- **Production tier:** C
- **Region / faction:** Kourindou / Forest of Magic edge
- **Route scope:** Support route
- **Source character contract:** `04_characters/rinnosuke_morichika/skills.md`

## Silhouette lock

glasses, long shop coat/apron and rectangular outside-world object

- Primary prop: unidentified tool / book
- Separate child/FX layer: object label and lens-glint layer
- Preferred presentation profiles: A, B

## Motion lock

- Idle: adjusts glasses after examining the object, not before.
- Talk/gesture: turns the object to show one wrong-but-plausible function.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

calm expertise, blind spots, gentle stubbornness

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

shop work; field salvage coat; formal merchant

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
