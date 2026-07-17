# 0.1.0-rc.1 Known Issues and Release Decision

This is a technical release candidate, not a public-release approval.

1. The 2,500-bullet rendered danmaku stress scene measures 32.256 ms p95 under
   Mesa llvmpipe, above the 16.67 ms target. Its CPU simulation passes at
   0.924 ms p95. A capture on the declared target integrated-GPU class is still
   required before publishing a minimum-hardware claim.
2. Screen-reader support is not implemented or claimed. The implemented
   accessibility features are visual/motion/timing/input assists; see
   `docs/accessibility/m10_screen_reader_feasibility.md` in the source archive.
3. The M17 human EN, JA, character/canon, and comfort review manifest is still
   intentionally absent. Automated readiness checks are not a substitute for
   those reviewers; this blocks public-release approval.
4. The owner waived the real-device speaker/headphone audition as a release
   gate. This waiver does not claim a human audition occurred.
5. A public support contact and storefront/distributor decision have not been
   assigned. Do not distribute this candidate publicly until they are set.
