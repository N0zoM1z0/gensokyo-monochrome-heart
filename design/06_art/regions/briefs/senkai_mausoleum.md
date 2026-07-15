# Senkai and the Hall of Dreams' Great Mausoleum — Visual Production Brief

Source narrative bible: `03_locations/senkai_mausoleum.md`  
Production tier: **B**  
Profile family: **B → D**  
Region stamp: **earmuff arc above a ritual plate**

## Visual thesis

Revival turns old certainty into a conversation with a present that did not wait.

## Recognition lock

- Silhouette vocabulary: mausoleum stairs, Taoist arches, cape triangle, ritual plates, wall passages and jiang-shi talisman.
- Landmark: a formal stair ascends into a doorway whose back is visibly a floating island.
- Texture rule: concentric ritual lines and broad stone fields; speech waves are sparse dashed outlines.
- Entry transition: a wall outline slides across the player; the reverse side is the destination.

## Four depth bands

1. **FAR:** white hermit sky with floating architecture traces.
2. **MID:** mausoleum roofs and Senkai islands.
3. **PLAY:** stone court, ritual floor and wall-crossing passages.
4. **FRONT:** plate arcs, cape edge, talisman strips and listening waves.

## Signature 16×16 tile families

- mausoleum stone
- Tao seal
- ritual plate
- incense square
- wall passage
- speech wave
- talisman door
- Senkai cloud edge

## Authored spot coverage

- Mausoleum Gate: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Desire Hall: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Senkai Path: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Futo's Plate Court: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Seiga's Passage Wall: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Audience Chamber: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Rooftop Stars: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

plate orbit, cape settle, wall ripple, talisman flap and multi-voice wave. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: rituals map cleanly to doors
- INCIDENT: old labels summon modern side effects
- ROUTE: a jointly translated sign remains installed
- SEASON: cloud island vegetation uses overlays
- AFTER: new wiring/signage sits visibly beside ancient stone

## Combat and interaction readability

plates orbit on fixed readable radii; wall-pass silhouettes are previewed on both surfaces; voice waves remain HUD cues, not collision objects. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Miko: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Futo: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Seiga: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Yoshika: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Kokoro visitors: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Desire Chorus: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Plate Feng Shui: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Wall-Walk Rescue: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Jiang-Shi Instruction Queue: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
