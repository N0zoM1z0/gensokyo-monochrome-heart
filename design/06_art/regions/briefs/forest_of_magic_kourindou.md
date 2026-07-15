# Forest of Magic and Kourindou — Visual Production Brief

Source narrative bible: `03_locations/forest_of_magic_kourindou.md`  
Production tier: **A**  
Profile family: **A → D**  
Region stamp: **mushroom cap over a price tag**

## Visual thesis

Curiosity makes a home from clutter, but every object keeps an unknown past.

## Recognition lock

- Silhouette vocabulary: leaning trees, mushroom shelves, broom diagonals, shop roof and outside-world rectangles.
- Landmark: Kourindou window: a bright display grid of objects whose silhouettes never quite match their labels.
- Texture rule: organic stipple in forest; clean parallel hatching on shop wood; no checker noise.
- Entry transition: a found object rotates as a black silhouette and becomes the next scene aperture.

## Four depth bands

1. **FAR:** white mist with crooked canopy islands.
2. **MID:** tree arches and distant object piles.
3. **PLAY:** soft root ground, shop floorboards and mushroom rings.
4. **FRONT:** hanging herbs, close branches and unlabeled junk.

## Signature 16×16 tile families

- root bridge
- mushroom cluster
- spark moss
- herb hook
- shop shelf
- radio rectangle
- broom rack
- price tag

## Authored spot coverage

- Forest Edge: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Mushroom Field: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Marisa's House: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Alice's House: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Doll Clearing: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Kourindou: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Discard Stream: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

spore drift, hanging herb swing, mini-hakkero spark and radio scan line. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: paths curve around useful clutter
- INCIDENT: object labels detach and float to wrong items
- ROUTE: the companion leaves a persistent object on one shelf
- SEASON: fungi and canopy density swap by tile overlay
- AFTER: a repaired object hums imperfectly in the shop

## Combat and interaction readability

forest hazards use slow root telegraphs; sparks and bullets use hollow/solid polarity pairs; shop duels protect shelf silhouettes from visual overlap. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Marisa: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Alice: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Rinnosuke: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Patchouli visitors: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- fairies: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Mushroom Field Notes: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Doll Orchestra: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Curio Identification: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Broom Cargo Run: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
