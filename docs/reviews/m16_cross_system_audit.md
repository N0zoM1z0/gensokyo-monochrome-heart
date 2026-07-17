# M16 Production Art and Audio Cross-System Audit

Date: 2026-07-17
Decision: PASS for the tracked production pipeline, runtime integration,
provenance, accessibility variants, automated release gates, and final visual
player review. Real-device audio listener sign-off remains explicitly open and
must not be inferred from this technical decision.

## Acceptance inventory

- 33 approved original visual assets: eight Model L fighter sets, eight Model M
  markers, five region atlases, twelve bullet families, portrait expressions,
  UI frames/icons, and standard/reduced VFX supplied through the reviewed
  production generators and runtime resolvers.
- 27 approved original audio assets: fifteen adaptive music stems across five
  families and twelve bounded SFX. Every `music_state` in all 104 shipped event
  graphs resolves to a deliberate family; unknown future states are rejected.
- The external asset ledger contains 63 tracked records and the generated
  credits are current. Release discovery reports the same 63 files, so no
  shipped asset bypasses provenance or approval.
- All production inputs are project-original or separately licensed font
  sources with recorded rights. No official Touhou extraction, unlicensed
  sample, transcribed melody, placeholder filename, or hidden release asset was
  found.
- Standard and reduced/no-flash VFX remain distinct in shape and duration;
  warnings retain non-audio equivalents, and A/D palette polarity remains
  one-bit.

## Final verification

The environment terminates a single outer command after roughly 40 seconds, so
the monolithic verifier cannot provide one meaningful exit code here. Its steps
were executed as short, independently reported batches rather than weakening or
skipping them.

- Content: 71 characters, 19 locations, 104 events, 713 beats, 2,065 strings,
  89 cues, and 1,720 nodes; zero errors and warnings.
- Unit suite: 36 suites, zero failures.
- Positive integration scripts: 114 passed, including 20-run/10-replay M09
  stability. The added mountain patrol fixture also reaches `n_after_01`, draws
  `mountain_patrol`, and atomically commits its checkpoint.
- Negative gates: eleven expected failures returned non-zero with their exact
  diagnostics, covering invalid content, typed references, cycles, startup,
  gray pixels, fractional positions, and placeholder filenames.
- Release scan: 1,084 files, zero errors. Provenance: 63 registered and 63
  discovered. M16 coverage: 33 visual, 27 audio, eight fighters, five regions,
  twelve bullets, fifteen stems, and twelve SFX.
- Generated screenshot matrices VA00 and M01/M04/M05/M06/M07/M08/M09/M10/M11/
  M12/M13/M14/M15 all completed. The complete directory passes one-bit
  validation with zero errors; the audited images are 320x180 and two-color.
- Pixel alignment passes all thirteen final review scenes with zero errors.
- The 2,500-bullet pool microbenchmark reports p95 1.047 ms against a 3.5 ms
  budget. Fighter stress reports p95 10.760 ms against 16.67 ms. The separate
  full danmaku software-rasterizer fixture remains honestly structural-only on
  llvmpipe, with three p95 samples of 29.595, 31.740, and 32.085 ms, improved
  from its documented 35.378-42.020 ms baseline.

## Player-review findings and closure

Three independent simulated-player passes first approved the production combat,
UI, portrait, and region work, then audited the complete screenshot matrix. The
final pass found three actionable evidence/runtime issues rather than silently
signing off:

1. parallel mountain captures shared an atomic save temporary path and could
   display a checkpoint error;
2. high-load parallel readback could capture incomplete Quiet Chore locale art;
3. the Half-Phantom tutorial placed a bilingual core rule on one clipped line.

The mountain fixture now isolates save roots by phase and process, exposes no
raw filesystem diagnostic on the player recovery page, and has a dedicated
checkpoint integration gate. Quiet Chore captures now have per-region ink and
EN/JA equality checks in the sequential M14 matrix. Half-Phantom instructions
use bounded pixel-width wrapping with full-text and line-width unit coverage.

After recapture, all three reviewers returned PASS. The independent final sample
covered the twelve repaired EN/JA images and found no new clipping, polarity,
state, or readability regression.

## Open human gate

Headless amplitude, bus, persistence, mono-source, voice-limit, and hierarchy
checks cannot establish comfort, fatigue, or real-device audibility. A human
listener must complete `docs/reviews/m16_audio_listener_signoff.md` on speakers
and headphones for the default, Mono, Low Dynamic Range, and combined mixes.
Until that record says PASS, broader audio/release readiness remains open even
though the automated and visual M16 cross-system audit is complete.
