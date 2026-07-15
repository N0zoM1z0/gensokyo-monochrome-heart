# Retro Danmaku System

## Goal

Capture the readable ritual, personality, and beauty of Touhou-style danmaku without requiring official-game density or effects.

## Screen

- 320 × 180
- action field: 240 × 160 centered, with compact side HUD
- 60 FPS fixed update
- player hitbox: 2 × 2 pixels in Focus mode, 4 × 4 otherwise
- bullets: 2–10 pixels with strict silhouette classes

## Controls

- move
- Shoot
- Focus / slow
- Spell / safety
- Ink Shift (contextual; optional on Story mode)

## Core resource: Margin

Grazing fills **Margin**.

Spend Margin to:
- erase a narrow white corridor through bullets;
- stabilize a dialogue prompt during a “verbal danmaku” scene;
- extend a photo frame;
- cancel one hit in Story mode;
- power a character-specific assist.

Margin decays slowly only during inactivity.

## Black/white polarity

The world is not an Ikaruga-style damage puzzle. Polarity is a readability tool:

- **Black bullets** are solid claims, obligations, or direct attacks.
- **White bullets** are omissions, rumors, or negative space.
- The background periodically inverts.
- Bullet outlines preserve visibility during inversion.
- Ink Shift changes which class yields extra Margin, not immunity.

## Pattern construction

Every spell-like sequence has:
1. a readable title card;
2. a 1.5–2.5 second teaching phrase;
3. one transformation;
4. one character-specific punchline;
5. a maximum standard duration of 35 seconds.

## Encounter length

- tutorial: 30–60 seconds
- event pattern: 60–120 seconds
- route boss: 3–5 patterns, 4–7 minutes
- challenge boss: 6–8 patterns

## Character identity examples

### Reimu
- broad safe spaces that drift unexpectedly;
- homing amulets;
- boundary holes;
- pressure is low until the player becomes greedy.

### Marisa
- narrow lanes, high speed, strong telegraph;
- stars accumulate into a laser;
- reward decisive movement.

### Sakuya
- bullets stop, then resume in a readable order;
- clock-hand geometry;
- safe positions become unsafe after time resumes.

### Youmu
- delayed cuts;
- phantom body and human body create paired waves;
- crossing a line at the right beat is safer than retreat.

### Aya
- wind bends trajectories;
- camera frames score the player's silhouette;
- patterns reward staying near visual danger.

## Difficulty presets

### Story
- 0.75× bullet speed
- larger telegraphs
- two automatic Margin saves
- no route penalty

### Normal
- intended baseline

### Hard
- faster transformation phase
- fewer automatic clear lanes

### Lunatic
- challenge-only variations
- cosmetic and journal rewards only

## Bullet budgets

At 320 × 180:
- standard event: ≤ 180 simultaneous bullets
- boss burst: ≤ 320
- challenge burst: ≤ 480 after profiling
- pooled objects only
- no per-bullet dynamic lights or particles

## Failure dialogue

Each boss has:
- first loss line;
- repeated loss line;
- Assist Clear acceptance line;
- successful no-hit line;
- successful messy line.

These lines follow the character skill file and never mock disability settings.
