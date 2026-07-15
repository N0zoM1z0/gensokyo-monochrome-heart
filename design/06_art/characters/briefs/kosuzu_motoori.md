# Kosuzu Motoori — Production Modeling Brief
## 本居 小鈴

- **Production tier:** C
- **Region / faction:** Human Village / Suzunaan
- **Route scope:** Support friendship only
- **Source character contract:** `04_characters/kosuzu_motoori/skills.md`

## Silhouette lock

twin braids, bell-like ties, bookstore apron and oversized book

- Primary prop: youma book / shop ledger
- Separate child/FX layer: page and seal layer
- Preferred presentation profiles: A, B

## Motion lock

- Idle: book weight shifts; braid follows.
- Talk/gesture: hugs, opens or reluctantly closes the dangerous book.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: not required at launch
- Portrait 80×104: 3 expressions/working states

## Portrait direction

bookish enthusiasm, risk blindness, friendship

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

Suzunaan work; festival reader; incident gloves

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
