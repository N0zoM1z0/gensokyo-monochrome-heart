# Hakurei Shrine — Visual Production Brief

Source narrative bible: `03_locations/hakurei_shrine.md`  
Production tier: **A**  
Profile family: **A → C**  
Region stamp: **yin-yang orb beneath a torii**

## Visual thesis

A home is recognizable by the work that resumes after every incident.

## Recognition lock

- Silhouette vocabulary: torii, low shrine eaves, donation box, bell rope, gohei zigzags and broad sky.
- Landmark: torii and donation box align for one instant when the boundary is stable.
- Texture rule: white breathing room; black eaves; 25% stone and cloud dither only.
- Entry transition: a gohei swipe wipes a paper-white strip across the frame.

## Four depth bands

1. **FAR:** mostly white sky with one weather band.
2. **MID:** mountain line, distant torii and tree masses.
3. **PLAY:** stone path, veranda, yard and shrine interior.
4. **FRONT:** leaves, rope, eave edge and boundary tear.

## Signature 16×16 tile families

- stone step
- weathered plank
- tatami edge
- donation box
- paper charm
- bell rope
- leaf pile
- boundary seam

## Authored spot coverage

- Long Stone Stairway: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Torii and Boundary Edge: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Donation Box: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Veranda: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Main Hall: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Back Storehouse: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Old Well: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Festival Yard: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

leaf loops, charm flutter, kettle steam, bell tail and one-pixel boundary crawl. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: chores and guest shoes create readable micro-state
- INCIDENT: boundary seams cross ordinary objects
- ROUTE: a chosen cushion and cup placement persist
- SEASON: tree/leaf/weather overlays change independently
- AFTER: patched wood and uneven new charms remain visible

## Combat and interaction readability

protect a wide white center; boundary hazards use thick frame lines; leaves disappear in focus mode; donation box collision is outlined before impact. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Reimu: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Marisa: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Suika: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Yukari: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Kasen: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- visiting ensemble: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Donation Box Arithmetic: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Leaf-Graze Sweep: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Tea at the Right Silence: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Festival Setup: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

## Asset budget

| Asset | Count |
|---|---:|
| 16×16 base tiles | 64 |
| 32×32 macro tiles | 18 |
| Animated props | 12 |
| 320×180 background strips | 8 |
| Foreground masks | 6 |
| Landmark sets | 3 |
| World-state overlays | 5 |

## Acceptance

- [ ] Region identified from stamp at 12×12 and landmark at 80×45.
- [ ] Four depth bands can be disabled independently.
- [ ] All authored spots have at least one matching tile/prop family.
- [ ] Five world states read without color.
- [ ] UI, dialogue, danmaku and fighter visibility tests pass.
- [ ] Reduced-motion mode removes foreground wipes and keeps navigation cues.
- [ ] Japanese and English signs fit their measured boxes.
