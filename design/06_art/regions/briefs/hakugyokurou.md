# Hakugyokurou — Visual Production Brief

Source narrative bible: `03_locations/hakugyokurou.md`  
Production tier: **A**  
Profile family: **C → A**  
Region stamp: **half-phantom curling around a fan**

## Visual thesis

Care for the dead is expressed through chores, appetite and disciplined incompleteness.

## Recognition lock

- Silhouette vocabulary: endless stair, cherry boughs, broad ghost sleeves, twin swords and drifting soul commas.
- Landmark: the staircase rises through three depth bands toward a tree too large to fit the frame.
- Texture rule: very sparse 25% petal fields; black reserved for trunks, roofs and emotional beats.
- Entry transition: petals gather into a butterfly; its wings open as the next scene.

## Four depth bands

1. **FAR:** white heaven with faint petal diagonals.
2. **MID:** stair terraces and Saigyou Ayakashi crown.
3. **PLAY:** garden paths, veranda boards and grave edges.
4. **FRONT:** petal veils, close branches and passing phantoms.

## Signature 16×16 tile families

- white stone stair
- cherry root
- petal mound
- spirit lantern
- garden rake line
- meal tray
- sword stand
- sealed tree bark

## Authored spot coverage

- Long Stairway: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Front Garden: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Soul Orchard: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Kitchen: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Veranda: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Training Yard: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Saigyou Ayakashi View: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Netherworld Gate: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

petal parallax, phantom breathing, fan flick and food steam. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: spirits drift in slow readable lanes
- INCIDENT: stairs repeat one landing and petals fall upward
- ROUTE: one shared meal setting persists on the veranda
- SEASON: blossoms, bare branches and snow use the same collision map
- AFTER: repaired garden lines include one playful detour

## Combat and interaction readability

ghost bullets use hollow comma silhouettes; petals are non-colliding and dim to 25% behind combat; sword trails occupy one frame only. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Yuyuko: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Youmu: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Yukari: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Komachi: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- visiting spirits: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Soul Garden: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Bottomless Banquet: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Half-Phantom Balance: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Memorial Kitchen: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
