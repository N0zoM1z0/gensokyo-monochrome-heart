# M16 Production Region Runtime Integration Review

Date: 2026-07-17
Decision: approved for the five headline runtime surfaces. The later bullet,
UI, and VFX gate is tracked separately.

## Runtime and metadata contract

`ProductionRegionTiles` binds the five reviewed 128×128 atlases to Hakurei
Shrine, Scarlet Devil Mansion, Youkai Mountain, Eientei/Bamboo Forest, and
Hakugyokurou. Each atlas exposes 64 native 16×16 cells in the manifest's fixed
eight-row order: terrain, collision edges, architecture, props, calm, incident,
route/season, and after.

Every cell has deterministic data-only metadata with the required `tile_id`,
`region_id`, `collision_shape`, `occlusion_band`, `interaction_shape`,
`material_sfx`, `profile_safe`, and `state_tags` fields. Collision-edge cells
also expose explicit polygons. All other visual rows declare `none` and an empty
polygon, preventing a decorative tile from silently becoming solid. The
existing exploration `floor_y` and typed `solid_obstacles` remain the runtime
movement truth.

Both A and D profiles pass through the same binary palette reconstruction:
source black becomes foreground, source white becomes background, and
transparency remains transparent. The cell, position, and alpha are identical
between profiles. Eientei's runtime `loc.eientei` ID resolves explicitly to the
`loc.eientei_bamboo_forest` production atlas.

## Composition policy

The 16×16 cells are used as sparse semantic sockets over the existing broad
procedural silhouettes, not as seamless wallpaper. Navigation floors remain
continuous hand-authored lines, and state cells replace only a few non-solid
world accents.

- Shrine cells attach to veranda pillars and outer architectural anchors. The
  former full-width one-pixel sky stipple was removed for calm A/D staging.
- Mansion cells form aligned upper window groups around a quiet central clock,
  tray, character, and door corridor. The previous repeated loose-square wall
  treatment was removed.
- Mountain cells extend the left and right ridge groups or attach to the remote
  notice/perch; the central newspaper and guardrail route remains empty.
- Bamboo cells reinforce selected stalks, sound anchors, and the fixed gate.
  Manual stalk spacing was reduced so the center no longer reads as a barcode.
- Hakugyokurou cells attach to one dominant old cherry branch above a stepped
  stone terrace. Rounded memorial canopies keep the three trees distinct from
  cursor rails and spirits, with a reviewed clear halo around the right spirit.

## Simulated-player review and corrections

Three independent simulated-player perspectives reviewed the A/EN and D/JA
five-region matrix at native 320×180, with additional D/JA 150% and second-room
captures inspected during correction.

`sanae_player_review` initially blocked Mansion wallpaper density, floating
Mountain triangles, and Shrine symbols that resembled interaction glints. Those
were replaced with aligned window groups, ridge-attached marks, and
pillar-attached Shrine forms. The reviewer then caught the revised cherry branch
touching the right Soul Garden spirit; lifting and trimming the branch restored
at least four pixels of visual separation. Final decision: PASS.

`eirin_consent_player_review` blocked the Shrine's pattern-glare risk and Soul
Garden's verb-only footer. The stipple was removed, and the active footer now
shows complete actual bindings for move/align, carry/send, and pause in both
languages. Final decision: PASS.

`remilia_player_review` blocked Mansion cells that read as debug debris and a
Soul Garden composition that read as an abstract alignment diagram. Aligned
architecture plus the cherry/terrace/memorial composition made both regions
immediately intentional without obstructing controls or play objects. Final
decision: PASS.

All reviewers confirmed reciprocal A/D hierarchy, distinct regional identity,
continuous navigation floors, readable prompts, and no remaining visual
blocker.

## Automated evidence

- Unit suite: 36 suites, 0 failures.
- Content database: 71 characters, 19 locations, 104 events, 713 beats, 2,065
  strings, 89 cues, and 1,720 nodes; 0 errors and 0 warnings.
- Metadata coverage: five atlases × 64 unique cells, all required fields,
  collision isolation, state tags, atlas bounds, alias resolution, and exact A/D
  reciprocity.
- M09 Shrine, M12 Mansion, M13 Mountain, M13 Bamboo, and M13 Soul Garden
  integration flows: 0 failures each.
- Pixel alignment: 5 relevant scenes, 0 errors.
- Generated screenshot one-bit validation: 0 errors.
- Release validation: 0 errors; provenance remains 63 registered / 63
  discovered assets.
- M16 production coverage: 33 visual and 27 audio assets, including all five
  headline regions.

## Remaining scope

This approval closes the five headline region atlas/runtime gate. The subsequent
production bullet, UI export, and standard/reduced-flash VFX mapping, composed
screenshots, and player review are recorded in
`m16_combat_ui_vfx_runtime_integration_review.md`. Overall M16 acceptance still
requires the final cross-system audit.
