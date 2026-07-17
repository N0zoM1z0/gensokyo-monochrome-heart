# M10 External Vertical-slice Playtest Protocol

This protocol supports the M10 exit gate: five external sessions comprising two Touhou-aware players, two players unfamiliar with Touhou, and one accessibility-focused player. Empty rows in the companion CSV are intentional; simulated reviews and developer automation do not count as external participants.

For the current technical-goal handoff, the owner explicitly deferred these
sessions until after owner playback and feedback. This is recorded in
`docs/reviews/m17_m10_owner_deferred_review.md`; it is not a claim that the
external gate passed.

## Before each session

- Record only a random session ID; do not enter a name, email address, account name, or free-form demographic detail.
- Record the exact commit, build channel, OS, input device, locale, accessibility preset, one-handed preset, and UI scale.
- Ask for consent to observe and take non-identifying notes. Recording is off unless separately consented.
- Begin from a fresh profile. Do not explain Touhou, the core loop, controls, assists, or failure behavior unless the participant becomes route-blocked.
- Keep `user://telemetry/vertical_slice_latest.json` after the session and rename the exported copy to the random session ID outside the repository. It contains phase/result timing but no personal filesystem path or identity.

## Observer script

Use neutral prompts only:

1. “Please start and play until you feel the slice is finished.”
2. If silent for a long period: “What are you looking for right now?”
3. After the first mechanical failure: “What do you think the game expects you to do next?”
4. At the Journal: “What changed, and what can you do from here?”
5. At the end: “Describe the loop in your own words.”

Do not teach a control before recording the first confusion. A route-block is any point where the participant cannot progress for 90 seconds without a hint.

## Required observations

- Time to leave title and time to understand the shrine objective.
- Every control lookup, missed focus state, unreadable/clipped string, unexplained icon, and accidental input.
- Whether the four tone choices are understood as intent rather than morality/alignment.
- Whether Tea Temperature, danmaku, and fighter goals/assists are discovered.
- Failure response: retry, accept loss, or belief that progress is blocked.
- Understanding of Keepsake, Journal update, read-only replay, save state, and explicit completion.
- Comfort-toggle use and any needle/alcohol/coercion information loss.
- Motion, flash, text-size, timing, audio-hierarchy, fatigue, and one-handed concerns.

## Severity and exit decision

- `blocker`: cannot complete or loses/corrupts progress.
- `critical_confusion`: route continues only after observer help, or participant forms a false model that changes a major decision.
- `major`: repeated control/readability/assist failure with a workaround.
- `minor`: local friction that does not alter completion or understanding.

M10 can exit only when all five required external rows are completed, no blocker or critical-confusion issue remains open, both unfamiliar players can explain the day loop, and the accessibility-focused session has no unresolved route block. Automated matrices and simulated visual reviewers remain supporting evidence, not substitutes.

## Companion artifacts

- Session sheet: `docs/playtest/m10_external_playtest_sheet.csv`
- Local acceptance telemetry schema: `gmh-vertical-slice-telemetry-v1`
- Automated route evidence: `tests/integration/run_m09_accessibility_matrix.gd`
- Stability evidence: `docs/performance/m09_slice_stability.md`
- EN/JA screenshot runner: `scripts/capture_m09_screenshots.sh`
