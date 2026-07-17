# M16 Production Audio Runtime Integration Review

Date: 2026-07-17
Decision: PASS for the first production playback slice; M16 audio remains open
for mix accessibility, listener review, and non-headline campaign coverage.

## Runtime contract

- The playable vertical-slice coordinator uses `ProductionAdaptiveMusicPlayer`,
  not the legal M11 audition tone generator.
- Five reviewed families each provide synchronized Place, Person, and Incident
  streams. All three players load the same family together and begin at sample
  position zero.
- State changes wait for the current family's native 4/4 bar boundary. A state
  within the same family changes stem gains without restarting playback; a
  cross-family state reloads and restarts the three synchronized streams once.
- The 33 accepted authored state aliases cover Hakurei Shrine, Scarlet Devil
  Mansion, Youkai Mountain, Eientei/Bamboo Forest, Hakugyokurou, and the M09
  boundary-crossing handoff. Unknown states are rejected rather than silently
  substituting unreviewed audio.
- Dialogue ducking and music mute operate on the complete three-stem mix.

## SFX contract

- Exploration, danmaku, compact fighter, and tea runtime scenes use
  `ProductionSfxPlayer` instead of synthesized placeholder waves.
- Exact production IDs remain exact; legacy semantic cue IDs resolve by intent
  to one of the twelve reviewed WAVs.
- Pools are owned per manifest family, never exceed the reviewed cap, and steal
  the oldest active voice after saturation.
- Every voice is routed to the SFX bus; every music stem is routed to Music.
  Both buses feed Master through the checked-in default layout.
- Visual cue keys and original semantic cue IDs are still emitted unchanged, so
  subtitle-safe equivalents and gameplay telemetry do not depend on playback.

## Automated evidence

- Godot 4.7.1 headless import completes without new parser or resource errors.
- All 36 unit suites pass with zero failures.
- Tests prove production paths exist, state transitions occur at the native bar,
  same-family transitions preserve synchronization, cross-family transitions
  restart exactly once, incident mix hierarchy is correct, unknown music states
  are rejected, SFX aliases resolve correctly, and Music/SFX buses are present.
- The M09 playable vertical-slice integration passes with zero failures after
  replacing its generated tone player and using the production bar duration.

## Remaining gate

The next audio slice must add persistent mono and low-dynamic-range controls and
apply them to both players. A listener review must then judge audibility,
fatigue, ducking, cue priority, and the balance of all five stem families on a
real audio driver. Remaining campaign regions need new approved production
families or an explicitly reviewed fallback policy; they must not be silently
mapped to unrelated headline-region music.
