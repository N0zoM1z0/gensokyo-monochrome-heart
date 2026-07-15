# Misty Lake — Visual Production Brief

Source narrative bible: `03_locations/misty_lake.md`  
Production tier: **B**  
Profile family: **A → D**  
Region stamp: **ice crystal reflected in a wave**

## Visual thesis

Playful mistakes become landmarks when friends remember them together.

## Recognition lock

- Silhouette vocabulary: flat waterline, reed clusters, ice-crystal wings, umbrella arc and mansion shadow.
- Landmark: the mansion silhouette appears only through a narrow clear slit in three moving fog bands.
- Texture rule: horizontal 25% ripple lines; fog stays white; ice uses black edge with white interior.
- Entry transition: fog fills the frame; a ripple opens a circular view onto the next spot.

## Four depth bands

1. **FAR:** white fog field with mansion pinprick.
2. **MID:** two reed/island bands dissolving into mist.
3. **PLAY:** shore stones, docks, ice floes and shallow water.
4. **FRONT:** fog curtains, close reeds, umbrella pop and splash arcs.

## Signature 16×16 tile families

- shore pebble
- reed base
- dock plank
- water ripple
- ice edge
- fog pocket
- umbrella puddle
- fairy marker

## Authored spot coverage

- Fog Shore: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Frozen Reeds: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Fairy Island: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Boat Wreck: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Mansion Causeway: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Moon Reflection: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

fog drift, ripple ring, uneven ice-wing twitch and surprise umbrella blink. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: fog lanes loop predictably
- INCIDENT: reflections lead one tile away from bodies
- ROUTE: a ridiculous handmade marker persists on one island
- SEASON: ice/fog/rain alter traversal overlays
- AFTER: repaired dock boards retain mismatched widths

## Combat and interaction readability

water reflection is disabled in focus mode; ice hazards telegraph with a thick crack outline; fog never lowers bullet contrast below AA target. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Cirno: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Daiyousei cameo: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Wakasagihime cameo: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Meiling patrols: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Scarlet residents: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Perfect Freeze Puzzle: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Fog Echo Tag: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Fairy Territory Flags: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
