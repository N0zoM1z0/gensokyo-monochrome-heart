# Core Loop and Event Runtime

## Macro loop

```
DAY START
  ↓
INVITATIONS + RUMORS
  ↓
REGION CHOICE
  ↓
SPOT EVENT
  ├─ exploration
  ├─ dialogue
  ├─ minigame / danmaku / duel
  └─ afterbeat
  ↓
JOURNAL + STATE CHANGES
  ↓
OPTIONAL NIGHT EVENT
  ↓
NEXT DAY
```

## Spot Event finite-state flow

1. `LOCKED`
2. `AVAILABLE`
3. `INTRO`
4. `FREE_EXPLORE`
5. `SOCIAL_CHOICE`
6. `MODE_SETUP`
7. `ACTIVE_MODE`
8. `RESOLUTION`
9. `AFTERBEAT`
10. `COMPLETE`
11. `ECHO_PENDING`

Events may bypass states but must never jump directly from INTRO to reward without player agency.

## Event inputs

- chapter
- day and time
- region state
- required and excluded flags
- active character availability
- route facet thresholds
- prior approach choices
- player settings
- random seed for cosmetic variation only

## Event outputs

- world flags
- Resonance facet deltas
- rumor additions/removals
- spot transformation
- Keepsake or journal entry
- next-event scheduling
- optional voice-line or music cue unlock
- recovery line if failed

## Time pressure

There is no global calendar failure. Time creates texture, not fear of missing content.

- Most main events consume one slot.
- Small conversations may consume no slot.
- Night events are invitations, not mandatory stamina sinks.
- A missed invitation returns later with altered context.
- Some characters prefer specific times, but routes remain recoverable.

## Event replay

After completion, a Journal page offers:
- replay scene;
- replay mechanical section;
- view alternative tone responses already discovered;
- practice danmaku pattern;
- compare English/Japanese text.

Replays do not modify canonical profile state unless “Re-enter Memory” is explicitly selected from postgame.
