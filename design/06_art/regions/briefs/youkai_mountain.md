# Youkai Mountain — Visual Production Brief

Source narrative bible: `03_locations/youkai_mountain.md`  
Production tier: **A**  
Profile family: **A → D**  
Region stamp: **tengu feather over a waterfall notch**

## Visual thesis

Every view is political: who can see, report, patrol, build and pass through.

## Recognition lock

- Silhouette vocabulary: steep switchbacks, waterfall columns, tengu wings/cameras, kappa pipes, wolf shield and cable structures.
- Landmark: one waterfall crosses all three depth bands but breaks into different pixel rhythms at each.
- Texture rule: diagonal rock hatch, vertical water stripes and clean white spray gaps.
- Entry transition: a newspaper page flips; its photo window expands into the destination view.

## Four depth bands

1. **FAR:** white sky with distant summit and cloud shelf.
2. **MID:** waterfalls, ropeways and settlement terraces.
3. **PLAY:** rock paths, bridges, workshops and patrol gates.
4. **FRONT:** spray curtains, leaves, camera frame and close pipework.

## Signature 16×16 tile families

- mountain ledge
- waterfall lip
- rope bridge
- tengu notice
- patrol marker
- kappa pipe
- workshop plate
- camera perch

## Authored spot coverage

- Mountain Trail: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Great Youkai Forest: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Waterfall of Nine Heavens: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Tengu Village Threshold: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Bunbunmaru Office: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Kappa Valley: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Wind Ridge: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

spray step, leaf gust, camera shutter, valve spin and patrol ear twitch. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: patrol, press and workshop routes are separately legible
- INCIDENT: reports redraw access before terrain changes
- ROUTE: a shared lookout gains a private annotation
- SEASON: waterfall volume, leaves and snow use overlays
- AFTER: temporary bridges become accepted shortcuts without looking official

## Combat and interaction readability

waterfall animation slows under dense bullets; wind arrows and patrol cones use different outlines; camera shutter uses no full-screen flash in safe mode. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Aya: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Hatate: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Momiji: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Nitori: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Hina: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Kanako: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Sanae: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Suwako: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Headline or Harm: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Wind-Frame Graze: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Thoughtography Search: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Waterwheel Tuning: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Patrol Line: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Misfortune Carousel: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
