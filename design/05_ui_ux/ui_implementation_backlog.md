# UI Implementation Backlog for Codex

## Definition of ready

A task can start only when the referenced screen row, component definitions, assets and localized string keys exist. Placeholder copy is allowed; placeholder dimensions are not.

## P0 — Foundation

- [ ] tokens/theme resources
- [ ] bitmap font import + EN/JA measure
- [ ] input action/glyph service
- [ ] focus router
- [ ] base frame + list + action hint
- [ ] palette/profile validator

## P1 — Core loop

- [ ] title
- [ ] language_select
- [ ] new_game_setup
- [ ] save_load
- [ ] world_map
- [ ] destination_detail
- [ ] exploration_hud
- [ ] pause

## P2 — Narrative

- [ ] dialogue
- [ ] dialogue_choice
- [ ] backlog
- [ ] chapter_card
- [ ] spot_card
- [ ] route_threshold
- [ ] ending_card

## P3 — Journal

- [ ] journal_summary
- [ ] journal_people
- [ ] journal_places
- [ ] journal_rumors
- [ ] memory_thread
- [ ] keepsakes
- [ ] character_profile

## P4 — Combat

- [ ] danmaku_hud
- [ ] spell_card_intro
- [ ] danmaku_result
- [ ] fighter_hud
- [ ] fighter_result
- [ ] training_pause

## P5 — Activities

- [ ] minigame_shell
- [ ] photo_camera
- [ ] trade_shop
- [ ] clinic
- [ ] activity_result

## P6 — System & polish

- [ ] options
- [ ] accessibility
- [ ] content_notice
- [ ] profile_select
- [ ] credits
- [ ] full EN/JA + forced A + reduced motion QA

## Per-screen completion gate

- [ ] Scene uses catalog components only, or a reviewed new shared component.
- [ ] Every declared state has a deterministic fixture/screenshot.
- [ ] Keyboard, controller, remapping and cancel path pass.
- [ ] EN and JA budgets pass with pseudo-localization.
- [ ] Native profile and forced A pass at 1×.
- [ ] Reduced motion and photosensitivity settings pass.
- [ ] No story/gameplay variable is stored in the UI node.
