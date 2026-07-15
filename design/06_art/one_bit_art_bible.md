# One-Bit Art Bible

## 1. Visual thesis

The game should resemble a half-remembered handheld title that never existed: hard black ink, luminous white paper, handmade imperfections, and motion that feels surprisingly fluid despite severe constraints. “Retro” means disciplined information design, not random low resolution.

## 2. Technical canvas

- internal resolution: **320 × 180**;
- target: 60 fps;
- integer scaling only in pixel-perfect mode;
- nearest-neighbor sampling;
- all gameplay sprites snap to the pixel grid at rest;
- subpixel motion may be simulated in physics but is quantized for render;
- final base assets are 1-bit or indexed with only two values;
- alpha is allowed for compositing, but visible pixels remain black or white.

## 3. Palette roles

### Ordinary field
White background, black foreground. Used for daytime, menus, domestic interiors, and calm exploration.

### Inverted field
Black background, white foreground. Used for night, underground, memory spaces, boss phase cards, and high privacy.

### Dither
Dither is texture, not a third color.

| Pattern | Use | Prohibited use |
|---|---|---|
| 25% Bayer | mist, distant foliage | text background |
| 50% checker | stone, water shadow | moving bullets at small size |
| 75% Bayer | deep recess, red implied tone | character face |
| sparse stipple | memory stain, snow, ash | every empty area |
| directional hatch | wind, speed, fabric | UI panels |

Never animate a full-screen checker at one-pixel phase; it flickers destructively.

## 4. Line hierarchy

- 1 px: texture, hair strands, distant architecture;
- 2 px: character outer contour at standard scale, critical props;
- 3 px: action silhouettes and interactive edges;
- 4+ px: only giant bosses, foreground wipes, or UI focus.

A character must survive conversion to a solid silhouette. Face detail is secondary to hat, bow, wings, sleeves, weapon, stance, and companion object.

## 5. Implied color without color

Recurring textures stand in for iconic color groups without claiming literal color:
- Reimu red: solid black ribbons against mostly white garment mass;
- Marisa black: solid hat/dress mass with white apron cuts;
- Scarlet red: 75% dither halos and bat-wing black;
- ghostly pale: white bodies with black contour and sparse stipple;
- mountain green: vertical hatch and leaf triangles;
- moon violet/blue: black sky, white circular geometry, horizontal interference lines.

Do not rely on implied color alone. Every character still needs a unique silhouette.

## 6. Lighting

Lighting is represented by **shape replacement**, not translucent gray:
- a lit side becomes white and loses interior line;
- a shadow side becomes black and gains a white edge highlight;
- lantern pools are clean white cutouts in night scenes;
- spell flashes invert only the actor and immediate ground for 1–3 frames;
- portraits may use a single diagonal hatch shadow, never airbrush gradients.

## 7. Animation tiers

### Tier A — Core playable / route lead
- 8-direction optional exploration set or 4-direction + mirrored;
- 8-frame walk, 4-frame idle, 6-frame interaction;
- 4–8 portrait micro-animations;
- full danmaku and fighter sets.

### Tier B — Regional support
- 4-frame walk;
- 3-frame idle;
- 2–4 event gestures;
- danmaku boss set if applicable.

### Tier C — Cameo / crowd
- 2-frame idle;
- entrance/exit pose;
- portrait or silhouette only.

## 8. Animation principles

- Hold strong key poses longer than transition poses.
- Use accessory lag: bow, hat ribbon, wing tip, sleeve, half-phantom.
- Do not move every pixel every frame.
- Idle motion communicates role: Reimu's sleeve settles, Marisa's hat tips, Sakuya's hand checks a watch, Aya's camera strap shifts.
- Smear frames are solid graphic wedges, not blurred duplicates.
- Impact frames may use one full inversion frame; provide a no-flash alternative.

## 9. Camera and composition

- exploration camera shows 20 × 11.25 tiles at 16 px or equivalent;
- player normally occupies 12–18% of screen height;
- dialogue portraits may break panel boundaries by up to 8 px;
- danmaku reserves a clear 200 × 152 primary play area;
- fighter stages use strong foreground baseline and two readable depth layers;
- no parallax layer may cross the player's hitbox at combat readability settings.

## 10. Content boundaries

Character designs are original fan interpretations. Do not trace official portraits, copy official sprite proportions frame-for-frame, or lift another fan artist's costume solution. Keep the recognizable identity in iconic accessories and relationships, not copied pixels.
