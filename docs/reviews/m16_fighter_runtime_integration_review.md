# M16 Model L Fighter Runtime Integration Review

Date: 2026-07-17
Decision: approved for the fighter runtime integration phase; this does not
close the remaining M16 portrait, region, bullet, VFX, audio, or credits gates.

## Integrated contract

- The Reimu/Marisa duel now draws the reviewed native 32×48 Model L sheets.
- All ten authored moves map to stable semantic action cells; neutral, forward,
  back, jump, guard, hit, and down states have explicit mappings.
- Ink-polarity presentation recolors the same one-bit source texture at runtime,
  eliminating four duplicate normal/inverted exploration sheets.
- Grounded pushboxes retain at least 28 px center separation. Presentation adds
  a 2 px outward anchor allowance per fighter so contact effects may touch while
  heads and torsos retain negative space. Airborne crossovers remain permitted.
- Fighter hitboxes and hurtboxes remain data-authored and independent of sprite
  bounds.

## Initial simulated-player blocks

`remilia_player_review`, `sanae_player_review`, and
`eirin_consent_player_review` independently inspected the native 320×180 A/D,
English/Japanese, combat, training, spell-break, and result captures. Their first
pass blocked release integration because contact silhouettes collapsed, the
down fixture only exercised hitstun, combat overlays hid boxes/feet, the footer
clipped its second line, spell-break duplicated its message, training hid its
viewport, results omitted identities, and the generic down cell resembled
debris.

## Rework and final evidence

- Added deterministic grounded pushbox separation and its unit test.
- Split hit and true-down fixtures, then mapped frame 23 and frame 24 explicitly.
- Moved the impact stamp above combat, suppressed it during box viewing, and
  retained distinct dashed hurtboxes plus solid hitboxes.
- Moved footer baselines to y=163/y=173, leaving a clear two-pixel bottom margin.
- Removed the duplicate safe-flash spell-break subtitle.
- Rebuilt training as side/top panels so both fighters and boxes remain visible.
- Added named win/down/surrender silhouettes to both result outcomes.
- Redrew all eight down cells with character-specific prone identities and added
  minimum-bounds plus uniqueness generator gates.

Final reviewer decisions:

- `sanae_player_review`: PASS for polarity, clipping, duplicate-message, contact,
  result, and training accessibility.
- `eirin_consent_player_review`: PASS with no remaining combat-UX blocker.
- `remilia_player_review`: PASS after confirming the down-pose rework in both
  runtime captures and all eight native frame-24 cells.

Automated evidence at approval: 36 unit suites with zero failures, M08 event
integration with zero failures, one-bit screenshot validation with zero errors,
and the rendered 2-fighter/128-projectile/40-effect llvmpipe fixture within its
16.67 ms p95 budget.
