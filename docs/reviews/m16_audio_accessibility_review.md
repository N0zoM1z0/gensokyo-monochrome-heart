# M16 Audio Accessibility and Mix Review

Date: 2026-07-17
Decision: PASS for implementation, persistence, automated mix contracts, and
Options presentation; real-device listener sign-off remains open.

## Mono contract

- Options exposes a persistent bilingual `Mono Audio` / `モノラル音声` switch.
- The switch enables an `AudioEffectStereoEnhance` at the first Master-bus
  effect slot with `pan_pullout = 0`, collapsing current or future stereo
  panning before output.
- All 27 reviewed production WAVs are independently required by the manifest
  alignment test to remain one-channel sources.
- Direction-critical gameplay continues to emit the existing visual cue keys;
  Mono does not remove warning text, focus marks, hit effects, or threat icons.

## Low-dynamic-range contract

- The second Master-bus effect is a compressor with a -14 dB threshold, 3:1
  ratio, +2 dB make-up gain, 20 microsecond attack, and 250 ms release.
- The logical SFX hierarchy compacts from a 13 dB warning-to-ambience span to
  6 dB while retaining warning, player-critical, gameplay, and ambience order.
- Quiet music stems move 35 percent toward the active stem with a -12 dB floor;
  dialogue ducking changes from 3 dB to 2 dB in compact mode.
- Live setting changes update already-created music and SFX players. They do not
  mutate story state, semantic cue IDs, visual equivalents, or telemetry.

## Voice-limit evidence

Dummy/headless playback reserves each chosen voice for the reviewed WAV's
reported duration, matching the real driver's expected occupancy. Five rapid
impact cues allocate exactly four voices, stop at the manifest cap, and steal
the oldest voice exactly once. Runtime and manifest family, cap, priority, and
path values remain exact 12/12 matches.

## Options and persistence evidence

- Settings are written under the `audio` section of `user://settings.cfg`.
- Options applies both switches live and Cancel restores the exact opening pair.
- The M01 integration enters both rows through stable focus IDs, proves the
  persisted values, checks propagation to the active production music director,
  and then proves cancellation restoration.
- The 150% UI evidence is
  `tests/screenshots/generated/m10_options_mono_150_a_en.png` and
  `tests/screenshots/generated/m10_options_low_dynamic_150_d_ja.png`.

Three independent simulated-player reviews returned PASS:

- `eirin_consent_player_review` found both settings discoverable, focused,
  state-readable, unclipped, and supported by clear action/page hints.
- `sanae_player_review` approved the EN/JA wording, label/value separation,
  native readability, and page navigation.
- `remilia_player_review` approved A/D polarity, focus hierarchy, explicit
  ON/OFF states, margins, and the tight English low-dynamic row without overlap.

## Automated evidence

- Godot 4.7.1 imports the two Master effects and all changed scripts without a
  new parser or resource error.
- All 36 unit suites pass with zero failures after the runtime content index is
  regenerated for the two new bilingual keys.
- M01 navigation and persistence integration passes with zero failures.
- Screenshot capture returns exact 320×180 opaque one-bit images in both tested
  profiles and locales.

## Optional later listening pass

Automated amplitude policy does not prove that a mix is comfortable or audible.
Before M16 audio acceptance, a listener must review all five stem families and
the twelve SFX on laptop speakers and headphones, including Mono and Low Dynamic
Range, and record fatigue, warning audibility, dialogue ducking, and cue-balance
results. All currently authored campaign event states now resolve through the
five reviewed families, including three explicit thematic fallbacks; automated
coverage no longer remains open. The owner waived this real-device review from
M16 and project completion on 2026-07-17; the optional device matrix and sign-off
fields remain in `docs/reviews/m16_audio_listener_signoff.md`.
