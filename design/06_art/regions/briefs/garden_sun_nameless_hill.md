# Garden of the Sun and Nameless Hill — Visual Production Brief

Source narrative bible: `03_locations/garden_sun_nameless_hill.md`  
Production tier: **C**  
Profile family: **C → A**  
Region stamp: **sunflower split by a lily-of-the-valley bell**

## Visual thesis

Beauty and poison share a border that must be approached, not erased.

## Recognition lock

- Silhouette vocabulary: sunflower walls, parasol circle, low poisonous bells and abandoned doll shapes.
- Landmark: one enormous sunflower turns away from the player while every small flower faces them.
- Texture rule: parallel soil hatch; flower heads are solid black disks with white seed notches.
- Entry transition: a parasol closes to a vertical line, then opens onto the next field.

## Four depth bands

1. **FAR:** white sun disc and distant flower horizon.
2. **MID:** alternating tall sunflower and low hill bands.
3. **PLAY:** soil rows, narrow safe paths and petal clearings.
4. **FRONT:** petals, parasol edge and close swaying stems.

## Signature 16×16 tile families

- sunflower stem
- turning flower head
- lily bell
- poison soil
- safe stepping stone
- doll scrap
- parasol shade
- wind furrow

## Authored spot coverage

- Sunflower Rows: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Umbrella Path: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Night Bloom Corner: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Nameless Hill: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Lily Valley: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Abandoned Doll Site: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

petal drift, flower turns, poison motes and abrupt wind silence. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: tall and low fields remain clearly distinct
- INCIDENT: flower heads track contradictory targets
- ROUTE: a safe picnic shade appears without cleansing the hill
- SEASON: bloom density changes through sparse overlays
- AFTER: warning markers become handmade and cared for

## Combat and interaction readability

poison zones use perimeter animation, never noisy fill; flower bullets remain circular while harmful pollen uses tiny crosses. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Yuuka: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Medicine cameo: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Hina visitors: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Alice visitors: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Flower Listening: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Shadow Watering: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Poison Wind Route: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Doll Memorial: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
