# M16 Production Audio Runtime Integration Review

Date: 2026-07-17
Decision: PASS for production playback, complete authored-event state coverage,
and its follow-up mix-accessibility slice; M16 audio remains open for real-device
listener review.

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

## Accessibility update

Persistent Mono Audio and Low Dynamic Range controls now apply live through
`SettingsService`, the Master bus, and both production players. Exact behavior,
UI review, and cancellation/persistence evidence is recorded in
`docs/reviews/m16_audio_accessibility_review.md`.

## Campaign state coverage

Every `music_state` referenced by the 104 shipped event graphs resolves to a
reviewed production family. Three states outside the five headline location
names use explicit, documented thematic fallbacks rather than silent defaults:

- `mus_marisa_night` uses Hakurei Shrine's person-forward mix because that
  reviewed family already owns Marisa's arrival identity;
- `mus_sanae_route` uses Youkai Mountain's person-forward mix because Moriya
  Shrine is part of the mountain campaign geography;
- `mus_tenshi_route` uses Youkai Mountain's person-forward mix for its reviewed
  high-altitude, wind, and terrain language.

The unit suite scans every event JSON and fails if any authored music state no
longer resolves. Unknown external or future states are still rejected.

## Remaining gate

A listener review must judge audibility, fatigue, ducking, cue priority, and the
balance of all five stem families on a real audio driver. Automated state,
rights, and amplitude checks are supporting evidence, not a substitute for that
human listening gate. Use `docs/reviews/m16_audio_listener_signoff.md` to record
the result without conflating device listening with headless verification.
