# Moriya Shrine — Visual Production Brief

Source narrative bible: `03_locations/moriya_shrine.md`  
Production tier: **B**  
Profile family: **B → A**  
Region stamp: **frog eye and snake curve around an onbashira**

## Visual thesis

Faith is maintained through engineering, hospitality and arguments about what counts as progress.

## Recognition lock

- Silhouette vocabulary: mountain shrine roof, enormous rope loop, onbashira columns, frog hat and wind turbines/waterworks.
- Landmark: shimenawa ring frames a practical waterwheel rather than hiding it.
- Texture rule: strong vertical pillars, circular rope/frog forms and clean mechanical hatch.
- Entry transition: a wind gust turns prayer slips into a wipe; one slip carries the next spot name.

## Four depth bands

1. **FAR:** white mountain sky with wind contours.
2. **MID:** lake, shrine roof and rope ring.
3. **PLAY:** stone terrace, plank routes and device platforms.
4. **FRONT:** prayer slips, turbine blades, rope tassels and frog ripples.

## Signature 16×16 tile families

- mountain stone
- shrine plank
- onbashira socket
- rope knot
- frog pond edge
- miracle charm
- water pipe
- wind rotor

## Authored spot coverage

- Mountain Lake: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Main Shrine: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Festival Platform: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Ropeway Station: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Wind Turbine Yard: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Frog Pond: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Private Residence: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

wind sock, rope tassel, frog ripple, rotor step and miracle glyph. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: sacred and mechanical props share the terrace
- INCIDENT: devices produce faith-shaped side effects
- ROUTE: one jointly maintained machine gains a personal modification
- SEASON: water level, snow and wind direction alter overlays
- AFTER: signs explain repairs with conflicting divine annotations

## Combat and interaction readability

rotors lock before combat; wind force uses arrows plus particles; onbashira lanes are 16-pixel aligned and preview impact footprints. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Sanae: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Kanako: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Suwako: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Nitori: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Aya: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Faith Festival Planner: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Divine Ropeway: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Frog-Ring Geometry: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Miracle Demonstration Rehearsal: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

## Asset budget

| Asset | Count |
|---|---:|
| 16×16 base tiles | 48 |
| 32×32 macro tiles | 14 |
| Animated props | 9 |
| 320×180 background strips | 6 |
| Foreground masks | 4 |
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
