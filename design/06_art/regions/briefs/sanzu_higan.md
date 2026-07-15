# Sanzu River and Higan — Visual Production Brief

Source narrative bible: `03_locations/sanzu_higan.md`  
Production tier: **C**  
Profile family: **C → A**  
Region stamp: **coin balanced on a judge rod**

## Visual thesis

Judgment gains meaning only after someone listens to the journey that produced the evidence.

## Recognition lock

- Silhouette vocabulary: wide river bands, low ferry, scythe crescent, flower plain, judge dais and rod vertical.
- Landmark: one coin remains perfectly still on the river while every bank line scrolls.
- Texture rule: long horizontal 25% bands; court uses vertical black/white authority blocks.
- Entry transition: the ferry crosses a black river strip; arrival reveals the next scene above it.

## Four depth bands

1. **FAR:** blank far shore with one dark tree.
2. **MID:** river strips and flower horizon.
3. **PLAY:** ferry deck, bank stones and court path.
4. **FRONT:** close reeds, drifting coins, sleeves and flower heads.

## Signature 16×16 tile families

- river ripple
- bank stone
- ferry plank
- oar lock
- coin eddy
- higan flower
- court stair
- verdict tablet

## Authored spot coverage

- Road of Reconsideration: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- River Bank: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Komachi's Boat: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Midstream Fog: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Court Approach: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Judgment Hall: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Unfinished Shore: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

coin drift, oar drip, flower lean, page turn and single rod tap. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: current and ferry schedules are legible
- INCIDENT: memories arrive without matching owners
- ROUTE: a privately heard testimony changes one flower marker
- SEASON: river height and flower density use overlays
- AFTER: queue markers allow pauses and conversation

## Combat and interaction readability

river current arrows appear on floor and HUD; verdict text never overlaps bullets; scythe arcs are thick telegraphs followed by thin active edge. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Komachi: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Eiki: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- departing spirits: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Yuyuko and Youmu in route events: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Ferry Fare: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Two-Color Judgment: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Testimony Ordering: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Distance Knot: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

## Asset budget

| Asset | Count |
|---|---:|
| 16×16 base tiles | 36 |
| 32×32 macro tiles | 10 |
| Animated props | 6 |
| 320×180 background strips | 4 |
| Foreground masks | 3 |
| Landmark sets | 2 |
| World-state overlays | 5 |

## Acceptance

- [ ] Region identified from stamp at 12×12 and landmark at 80×45.
- [ ] Four depth bands can be disabled independently.
- [ ] All authored spots have at least one matching tile/prop family.
- [ ] Five world states read without color.
- [ ] UI, dialogue, danmaku and fighter visibility tests pass.
- [ ] Reduced-motion mode removes foreground wipes and keeps navigation cues.
- [ ] Japanese and English signs fit their measured boxes.
