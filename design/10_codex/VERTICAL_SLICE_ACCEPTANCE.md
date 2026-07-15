# Vertical Slice Acceptance — “The Empty Cushion”

## Product experience

A new player can start the game, choose accessibility/language, travel to Hakurei Shrine, investigate the warm second cup, talk with Reimu using tone choices, complete or fail a tea minigame, survive or assist-clear a short boundary-stain danmaku scene, witness a compact Reimu/Marisa duel tutorial, reach a quiet afterbeat, receive a Keepsake, read the Journal change, save, reload, and replay the completed event.

## P0 — Must pass

### Boot and legal presentation
- [ ] Starts from a clean install.
- [ ] Displays unofficial fan-work notice and credits entry.
- [ ] Contains no ripped official asset or unapproved third-party asset.
- [ ] Exact engine version recorded.

### Resolution and input
- [ ] 320 × 180 internal image is crisp at integer scales.
- [ ] Arbitrary window sizes letterbox without blur in pixel-perfect mode.
- [ ] Keyboard completes all flows.
- [ ] Controller completes all flows.
- [ ] All required actions remappable.
- [ ] Focus never becomes trapped or invisible.

### Localization
- [ ] EN complete.
- [ ] JA complete.
- [ ] Locale can switch during dialogue and pause.
- [ ] No overflow at default and 150% UI layouts.
- [ ] Japanese punctuation/line breaks reviewed.
- [ ] No display text hard-coded in scene scripts.

### Narrative/event
- [ ] Event graph validates with no unreachable nodes.
- [ ] All four tone choices have authored responses.
- [ ] Effects apply exactly once.
- [ ] Reimu remains recognizable under her `skills.md` guardrails.
- [ ] Fanon dial does not exceed planned intensity.
- [ ] Quiet afterbeat is not skippable by accidental buffered input.
- [ ] Failure branches are respectful and complete the event.

### Exploration
- [ ] Interactions do not require pixel-perfect positioning.
- [ ] Objective can be understood without a minimap.
- [ ] Navigation hint appears when enabled.
- [ ] Companion skill is optional/remappable.
- [ ] No collision jitter at fixed 60 Hz.

### Minigame
- [ ] Clear, excellent, and loss results reachable.
- [ ] Story assists available before or after failure.
- [ ] No rapid tapping requirement.
- [ ] Restart fully resets state.

### Danmaku
- [ ] Every damaging spawn is telegraphed in Story mode.
- [ ] Hitbox-visible option works.
- [ ] 100/85/70/55% density tiers preserve pattern identity.
- [ ] Speed scale, auto-bomb, background dim, no-flash work.
- [ ] Phase retry and Assist Clear work.
- [ ] Deterministic replay fixture passes.

### Fighter
- [ ] Reimu and Marisa have distinct mechanics.
- [ ] Simple inputs and advanced inputs have parity.
- [ ] Hold guard/auto-face/slower speed assists work.
- [ ] Accept loss reaches authored result.
- [ ] Round reset cleans all state.

### Save/Journal
- [ ] Autosave at required boundaries.
- [ ] Manual save/load works.
- [ ] Corrupted current save recovers a backup.
- [ ] Journal records observations, not hidden numeric scores.
- [ ] Replay cannot mutate the main save.
- [ ] Locale switch after load works.

### Accessibility/comfort
- [ ] Story and Low Motion presets complete the slice.
- [ ] One-handed dialogue and gameplay preset tested.
- [ ] Flash replacement works globally.
- [ ] Needle/alcohol/coercion comfort toggles do not remove necessary plot information.

### Stability
- [ ] No crash in 20 consecutive complete slice runs through automation/manual mix.
- [ ] No growing memory trend over 10 replay cycles.
- [ ] Error logs contain no personal path in release channel.

## P1 — Strongly expected

- [ ] Title-to-play under five seconds on reference SSD.
- [ ] Mode swap under 1.5 seconds after first cache.
- [ ] 60 fps target in ordinary slice scenes.
- [ ] 2,500-bullet stress fixture profiled.
- [ ] Five external playtests completed.
- [ ] At least two players unfamiliar with Touhou understand the loop.
- [ ] One accessibility-focused playtest completed.
- [ ] EN and JA screenshots archived.
- [ ] No placeholder ID in QA build except documented art/audio placeholders.

## Sign-off record

```text
Build:
Commit:
Engine:
Content revision:
Date:
Producer:
Engineering:
Narrative EN:
Narrative JA:
Character/canon review:
Accessibility:
Asset/license audit:
Known issues:
Decision: PASS / CONDITIONAL / FAIL
```
