# M16 Production Portrait Runtime Integration Review

Date: 2026-07-17
Decision: approved for the current Shrine, Scarlet Devil Mansion, and Youkai
Mountain dialogue surfaces.

## Runtime contract

`ProductionPortraitResolver` binds the eight reviewed launch-character portrait
packs to the existing authored dialogue data. It resolves every authored
portrait token to one of the nine production expressions without rewriting
event content, and it refuses unsupported character IDs instead of silently
substituting an unrelated face.

- All 8×9 character/expression combinations resolve to a native 80×104 cell.
- A and D presentation profiles receive exact reciprocal black/white rasters.
- English 100% dialogue uses the native cell; Japanese and large-text layouts
  use a dedicated 40×52 compact cell.
- The compact raster applies detail-preserving 2×2 reduction: any source ink in
  a block survives. This keeps one- and two-pixel eyes, brows, and mouths from
  disappearing under GPU downscaling.
- Dialogue text wraps around the large-text portrait, while the compact
  Japanese portrait remains outside the text panel.

The dialogue event fixture now uses the same production resolver as the playable
vertical slice, replacing its hand-drawn Reimu-only proof.

## Simulated-player review

Three independent player perspectives reviewed the integration matrix.
`sanae_player_review` approved English/Japanese readability, name tags, four-line
150% text, controls, speaker identity, and scale balance. `eirin_consent_player_review`
approved non-obstruction, complete large text, calm staging, and expression fit.

`remilia_player_review` found two concrete blockers during iteration:

1. The initial 150% implementation asked the GPU to shrink 80×104 to 40×52,
   producing a blank-looking face. The dedicated ink-preserving compact raster
   restored Reimu's eyes, brow angle, mouth, bow silhouette, and line-appropriate
   expression in both A and D profiles.
2. The corrected D/JA capture exposed `自動: オフ` clipped to ambiguous
   `自動: オ`. Locale-aware footer allocation restored the full Auto state while
   preserving complete `次へ` and `履歴` prompts.

The final targeted review passed at native 320×180: portrait, speaker name,
dialogue, and all three footer controls remain complete, distinct, and
unobstructed.

## Automated evidence

- Unit suite: 36 suites, 0 failures.
- Content database: 71 characters, 19 locations, 104 events, 713 beats, 2,063
  strings, 89 cues, and 1,720 nodes; 0 errors and 0 warnings.
- Portrait contracts cover the 8×9 native and compact matrices, semantic token
  mapping, cell dimensions, visible one-bit detail, compact facial detail,
  reciprocal polarity, and unsupported-character refusal.
- Isolated A/EN and D/JA captures at 150% completed without save-state sharing.

## Remaining scope

This approval closes portrait runtime integration only. The subsequent region
gate is recorded in `m16_region_runtime_integration_review.md`, and the bullet,
UI, and standard/reduced-flash VFX gate is recorded in
`m16_combat_ui_vfx_runtime_integration_review.md`. Overall M16 acceptance still
requires the final cross-system audit.
