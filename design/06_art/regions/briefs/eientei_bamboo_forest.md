# Eientei and the Bamboo Forest of the Lost — Visual Production Brief

Source narrative bible: `03_locations/eientei_bamboo_forest.md`  
Production tier: **A**  
Profile family: **C → D**  
Region stamp: **rabbit ears crossing a medicine vial**

## Visual thesis

Repeated corridors become intimate only through tiny, remembered differences.

## Recognition lock

- Silhouette vocabulary: vertical bamboo bars, long rabbit ears, low tiled roofs and an impossible moon disc.
- Landmark: Eientei gate appears as a white horizontal cut through a forest of black verticals.
- Texture rule: low-frequency vertical hatch; interiors return to broad white tatami fields.
- Entry transition: three bamboo trunks pass foreground; the middle trunk becomes a door frame.

## Four depth bands

1. **FAR:** moon and sparse bamboo ghosts.
2. **MID:** two scrolling bamboo bands at unequal speed.
3. **PLAY:** root paths, clinic floor and sliding-door thresholds.
4. **FRONT:** near bamboo wipes, drifting leaves and rabbit-ear peeks.

## Signature 16×16 tile families

- bamboo stalk
- split root
- lost-path fork
- moonlit puddle
- tatami
- medicine shelf
- rabbit burrow
- sealed corridor

## Authored spot coverage

- Forest Entrance: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Looping Bamboo Path: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Rabbit Clearing: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Eientei Gate: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Clinic: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Long Corridor: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Kaguya's Chamber: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Moon-Viewing Veranda: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.
- Hidden Burn Path: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.

## Ambient motion

bamboo sway, ear silhouettes, vial glints and moon phase wipes. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.

## World-state set

- CALM: readable leaf notches identify loops
- INCIDENT: notches migrate and the moon repeats
- ROUTE: a private shortcut gains a character-specific charm
- SEASON: snow, rain and fireflies alter only the far/mid bands
- AFTER: wrong turns retain small gifts instead of punishment

## Combat and interaction readability

use black stalk columns only at arena edges; lunatic wavelength effects are 2-pixel dashed contours, distinct from collision bullets. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.

## Primary cast hooks

- Kaguya: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Eirin: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Reisen: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Tewi: reserve one prop socket and one character-specific ambient reaction in at least one spot.
- Mokou: reserve one prop socket and one character-specific ambient reaction in at least one spot.

## Minigame shell coverage

- Bamboo Loop Memory: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Clinic Triage: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Wavelength Hallway: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Five Impossible Errands: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Rabbit Luck Ledger: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.
- Immortal Escort: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.

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
