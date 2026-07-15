# Seiga Kaku — Production Modeling Brief
## 霍 青娥

- **Production tier:** C
- **Region / faction:** Senkai-adjacent / wicked hermit
- **Route scope:** Support antagonist
- **Source character contract:** `04_characters/seiga_kaku/skills.md`

## Silhouette lock

ornate hairpin, long dress and body partially crossing a wall/frame

- Primary prop: hairpin / wall chisel
- Separate child/FX layer: wall-cut and Yoshika link layer
- Preferred presentation profiles: C, D

## Motion lock

- Idle: one edge of her body ignores the frame boundary.
- Talk/gesture: fan/hairpin gesture invites trouble with immaculate calm.
- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.
- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.

## Asset budget

- Model S 16×24: 2 idle
- Model M 24×32: 2 idle + 4 walk + 2 talk/gesture
- Model L 32×48: 4 boss silhouettes
- Portrait 80×104: 3 expressions/working states

## Portrait direction

charm, moral slipperiness, amused manipulation

Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.

## Costume / event variants

hermit formal; mausoleum work; wall-passage set

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
