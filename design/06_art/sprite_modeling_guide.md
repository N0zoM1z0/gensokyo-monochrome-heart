# Sprite Modeling Guide

## 1. Three compatible body models

The project deliberately supports several “modeling” styles. They share proportions for collision and animation tags so event logic can reuse them.

### Model S — `16 × 24` Map Chibi
Purpose: world-map markers, crowd scenes, low-memory cameos.

Proportions:
- head 7–8 px high;
- body 10–11 px;
- legs 5–6 px;
- iconic accessory may extend 4 px outside nominal width;
- one eye pair at most; emotion comes from pose.

Animation: 2-frame idle, 4-frame walk, 2-frame interact.

### Model M — `24 × 32` Exploration Standard
Purpose: side-view spot exploration and minigames.

Proportions:
- head 10 px;
- torso 9 px;
- lower body 12 px;
- hands 2 × 2 px minimum in interaction poses;
- face has eyes, brow/hat shadow, and one mouth pixel cluster;
- accessories can use independent child sprites.

Animation: 4-frame idle, 8-frame walk, 4-frame turn, 6-frame context action, 2–4 reactions.

### Model L — `32 × 48` Duel / Dramatic
Purpose: fighting game and event close-ups.

Proportions:
- head 13–14 px;
- torso 14–16 px;
- legs 18–20 px;
- hands/feet large enough to communicate martial line;
- costume texture uses no more than two dither regions.

Animation: fighter set or 8–16 dramatic poses.

### Portrait — `88 × 120` source, cropped to UI
Purpose: dialogue. Draw at exact target resolution. Do not downsample painted art.

## 2. Construction order

1. Draw a solid 1-bit silhouette.
2. Verify recognition at 1×, 2×, and in peripheral view.
3. Cut white negative spaces for face, sleeves, apron, wing gaps, or hair separations.
4. Add one texture region.
5. Add face marks.
6. Test inversion.
7. Test overlap with black and white backgrounds.
8. Animate accessory lag.
9. Export collision and anchor metadata.

## 3. Required anchors

Every sprite exports:
- `feet_anchor`;
- `focus_anchor` for danmaku hitbox;
- `hand_primary` and `hand_secondary`;
- `head_top` for hats/effects;
- `portrait_eye_line`;
- `shadow_width`;
- optional `companion_anchor` (half-phantom, doll, third eye, camera).

## 4. Collision policy

Visual silhouette and gameplay collision are separate.
- exploration capsule: 8 × 20 px at Model M;
- interaction reach: 12 px forward;
- danmaku damage hitbox: typically 2–3 px radius;
- fighter hurtboxes follow torso/limbs but exclude ribbons, hats, wings unless a move explicitly uses them;
- environmental props cannot infer collision from sprite bounds.

## 5. Expression packs

A route lead requires at minimum:
- working neutral;
- social neutral;
- amused;
- irritated;
- focused;
- startled;
- tired/private;
- sincere but restrained;
- route-specific vulnerable state.

Avoid a universal “anime blush” layer. Blushing, where used, should be two or three stipple pixels and not the only cue.

## 6. Costume variants

Costume variants are earned through event context, not a generic wardrobe monetization system.

Supported categories:
- ordinary/canon-inspired baseline;
- work variant (kitchen, garden, archive, mountain patrol);
- festival / formal;
- weather (rain coat, winter layer);
- dream archive distortion;
- postgame outside-world memory;
- joke variant with explicit fanon label.

Each variant reuses the base skeleton but may have bespoke silhouette frames. Never force a long skirt onto a short-skirt skeleton by clipping.

## 7. Approval checklist

- recognizable in silhouette among same-faction characters;
- readable on both palette polarities;
- no single-pixel noise at 1×;
- iconic prop does not obscure face in idle;
- animation loop returns to exact anchor;
- no copied official or fan sprites;
- JA name label fits UI tag;
- accessibility outline pass tested in danmaku.
