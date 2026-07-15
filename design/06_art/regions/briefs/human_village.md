# Human Village — Visual Production Brief

Source narrative bible: `03_locations/human_village.md`  
Production tier: **A**  
Profile family: **A → B**  
Region stamp: **open book behind a shop curtain**

## Visual thesis

Ordinary routines are the infrastructure that makes extraordinary lives possible.

## Recognition lock

- Silhouette vocabulary: layered tiled roofs, shop curtains, carts, books, school boards and crowded human-scale doors.
- Landmark: main crossing: four readable shop signs and one rumor board fit a 320-pixel frame without text collision.
- Texture rule: low-frequency plaster speckle and wood hatch; crowds remain uncluttered solid shapes.
- Entry transition: a shop curtain sweeps sideways; its crest identifies the destination category.

## Four depth bands

1. **FAR:** white sky, smoke lines and distant roof rhythm.
2. **MID:** alley roofs, market banners and school facade.
3. **PLAY:** stone drains, packed-earth streets and shop interiors.
4. **FRONT:** passing carts, curtains, signboards and crowd silhouettes.

## Signature 16×16 tile families

- roof cap
- plaster wall
- street drain
- shop curtain
- book shelf
- school slate
- market crate
- rumor notice

## Authored spot coverage

- Market Street: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Temple School: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Hieda Residence: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Suzunaan: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Izakaya Alley: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Festival Square: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Village Edge: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

curtain lift, cooking steam, page flip, cart wheel and changing notice slips. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: schedules visible through shutters and stall props
- INCIDENT: rumor slips multiply faster than shops open
- ROUTE: one shared routine alters a storefront at a fixed hour
- SEASON: awnings, produce and street wetness use overlays
- AFTER: residents reuse incident debris in repairs

## Combat and interaction readability

civilian silhouettes vacate before arena lock; shop signs dim behind bullets; no random crowd motion during choice or combat focus. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Akyuu: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Kosuzu: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Keine: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Rinnosuke visitors: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Reimu: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Aya: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Mamizou cameo: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Chronicle Redaction: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Demon Book Checkout: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Classroom History Reconstruction: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Festival Stall Logistics: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
