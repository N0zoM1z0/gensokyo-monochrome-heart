# Myouren Temple and Cemetery — Visual Production Brief

Source narrative bible: `03_locations/myouren_temple.md`  
Production tier: **B**  
Profile family: **B → C**  
Region stamp: **lotus above a ship anchor**

## Visual thesis

A community is not harmony; it is the repeated practice of making room for difference.

## Recognition lock

- Silhouette vocabulary: temple roof, lotus arches, ship ribs, cloud giant, anchor and cemetery markers.
- Landmark: temple facade and ship hull share one contour, readable differently from each side.
- Texture rule: gravel uses sparse fixed dots; robes/lotus spaces remain broad white; cemetery black is clustered low.
- Entry transition: a struck bell emits concentric outlines; the third ring becomes the next frame border.

## Four depth bands

1. **FAR:** white sky and distant pagoda.
2. **MID:** temple/ship structure and cemetery tree line.
3. **PLAY:** courtyard gravel, tatami, grave paths and hold decks.
4. **FRONT:** incense smoke, prayer flags, cloud fists and close grave stones.

## Signature 16×16 tile families

- temple gravel
- lotus floor
- ship rib
- prayer bell
- incense stand
- grave marker
- cloud step
- anchor groove

## Authored spot coverage

- Temple Gate: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Main Hall: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Training Yard: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Kitchen: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Cemetery: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Palanquin Ship Deck: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Bell Tower: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

incense curl, prayer flag, mouse pendulum, umbrella blink and restrained cloud breath. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: incompatible routines overlap without collision
- INCIDENT: one rule is copied everywhere and stops fitting
- ROUTE: a shared duty leaves a named object in the common hall
- SEASON: incense, rain and cemetery foliage use overlays
- AFTER: multiple repair styles remain side by side

## Combat and interaction readability

cemetery markers are outside central arena; Unzan telegraphs with cloud outline before solid fist; incense disappears in focus mode. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Byakuren: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Ichirin: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Murasa: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Nazrin: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Shou cameo: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Kogasa: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Nue: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Temple Chant Relay: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Anchor the Ship: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Surprise Timing: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Treasure Dowse: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Unzan Gesture Match: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
