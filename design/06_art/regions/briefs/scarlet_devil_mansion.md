# Scarlet Devil Mansion — Visual Production Brief

Source narrative bible: `03_locations/scarlet_devil_mansion.md`  
Production tier: **A**  
Profile family: **B → D**  
Region stamp: **clock hand crossing a bat wing**

## Visual thesis

Perfection is a performance built from labor, hierarchy and chosen loyalty.

## Recognition lock

- Silhouette vocabulary: gothic roof, tall windows, clock hands, maid geometry, bat wings, library stacks and crystal prisms.
- Landmark: the great clock shows three readable times at three depths, only one belonging to the current room.
- Texture rule: large 4x4 checker groups on floors, vertical book rhythm, solid curtain masses; never 1-pixel checker.
- Entry transition: clock hands meet; the black wedge between them expands into the next room.

## Four depth bands

1. **FAR:** black night or white mist behind roofline.
2. **MID:** tower windows and long corridor vanishing points.
3. **PLAY:** checker-reduced floors, service passages and library platforms.
4. **FRONT:** curtains, chandelier edge, knife glints and crystal silhouettes.

## Signature 16×16 tile families

- gothic brick
- tall window
- clock gear
- service door
- library shelf
- tea cart rail
- basement lock
- crystal play mark

## Authored spot coverage

- Front Gate: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Grand Hall: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Clock Corridor: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Kitchen: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Dining Room: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Voile Library: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Clock Tower: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Basement Playroom: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Roof: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

clock tick, curtain shift, page drift, tea steam and crystal quarter-turn. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: servant routes and room clocks agree
- INCIDENT: one minute is missing from every corridor
- ROUTE: a private cup/book/knife placement persists by character
- SEASON: exterior mist and interior drapery overlays change
- AFTER: repaired furniture keeps small mismatched joins

## Combat and interaction readability

floor pattern drops to 25% during combat; knives are thin black shapes with white rim; crystal break points use diamonds, never bullet circles. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Remilia: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Flandre: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Sakuya: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Patchouli: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Meiling: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Koakuma: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Gate Nap Patrol: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Perfect Tea Service: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Library Breathing Room: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Red Mist Etiquette: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Crystal Play Rules: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
