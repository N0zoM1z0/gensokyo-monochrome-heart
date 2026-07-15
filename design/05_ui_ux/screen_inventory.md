# Complete UI Screen Inventory v2

**40 screens** are specified below. Each one has a stable Godot scene path, default profile, composition, components, states, inputs, localization budget, asset dependencies and a blocking acceptance rule.

| Category | Count |
|---|---:|
| system | 11 |
| narrative | 11 |
| journal | 7 |
| combat | 6 |
| activity | 5 |

## SYSTEM

### boot

- Scene: `res://ui/screens/boot_screen.tscn`
- Default profile: **A**
- Layout: center 160x64 mark; status y=148.
- Components: `loading_mark`.
- States: loading, saving_migration, error, ready.
- Input: cancel only during non-destructive loading.
- Localization budget: brand text <=24 EN / 12 JA glyphs.
- Required art: brand_mark_64, loading_gohei_16.
- Acceptance: **never shows a blank frame longer than 500ms; error exposes safe quit and retry.**

### language_select

- Scene: `res://ui/screens/language_select.tscn`
- Default profile: **A**
- Layout: title y=28; two 120x28 cards centered; help y=142.
- Components: `frame`, `choice_card`, `focus_marker`, `action_hint`.
- States: first_boot, from_options.
- Input: move/confirm/cancel when from options.
- Localization budget: language names are endonyms; each card <=12 glyphs.
- Required art: language_stamp_en, language_stamp_ja.
- Acceptance: **chosen font renders sample before confirmation; selection is stored immediately.**

### content_notice

- Scene: `res://ui/screens/content_notice.tscn`
- Default profile: **A**
- Layout: 272x132 modal; scroll body 244x76; actions bottom.
- Components: `modal`, `scrollbar`, `choice_card`, `action_hint`.
- States: first_view, revisit.
- Input: scroll/confirm/cancel.
- Localization budget: body 33 EN chars x 7 lines or 16 JA glyphs x 7.
- Required art: notice_icons_12.
- Acceptance: **full notice keyboard/pad readable; accept is never pre-committed by held input.**

### title

- Scene: `res://ui/screens/title_screen.tscn`
- Default profile: **A**
- Layout: logo x=16 y=20; menu x=176 y=86 w=128; version bottom.
- Components: `frame`, `list_row`, `focus_marker`, `loading_mark`.
- States: fresh, continue_available, no_save, update_notice.
- Input: move/confirm/cancel/menu.
- Localization budget: menu <=18 EN / 9 JA glyphs.
- Required art: title_logo_192x64, title_bg_320x180, season_overlay.
- Acceptance: **logo/background remain readable at 1x; continue hidden only when no valid save exists.**

### profile_select

- Scene: `res://ui/screens/profile_select.tscn`
- Default profile: **A**
- Layout: four 72x96 cards; preview top 48; explanation bottom.
- Components: `frame`, `choice_card`, `focus_marker`, `tooltip`.
- States: choose_default, preview, forced_A.
- Input: move/confirm/cancel/help.
- Localization budget: profile label <=14 EN / 7 JA; explanation 42x3 EN.
- Required art: profile_preview_A-D_64x48.
- Acceptance: **profiles change presentation only; forced A statement is explicit.**

### new_game_setup

- Scene: `res://ui/screens/new_game_setup.tscn`
- Default profile: **A**
- Layout: left options 160x124; right summary 136x124; confirm bottom.
- Components: `frame`, `list_row`, `toggle`, `slider`, `tooltip`, `modal`.
- States: new, preset_applied, confirm.
- Input: move/adjust/confirm/cancel/help.
- Localization budget: labels <=20 EN / 10 JA.
- Required art: difficulty_stamps_12, input_glyphs.
- Acceptance: **all difficulty/access choices are reversible; no route is chosen here.**

### save_load

- Scene: `res://ui/screens/save_load.tscn`
- Default profile: **A**
- Layout: tabs y=6; five 296x36 slots paged; modal overlay.
- Components: `tab`, `save_slot`, `scrollbar`, `page_indicator`, `modal`, `loading_mark`.
- States: save, load, autosave, empty, overwrite, corrupt.
- Input: move/confirm/cancel/page/help.
- Localization budget: chapter/place each <=23 EN / 11 JA.
- Required art: save_thumbnail_region_64x32, slot_status_8.
- Acceptance: **save waits for flush mark; overwrite has explicit slot identity; corrupt slots are not silently deleted.**

### options

- Scene: `res://ui/screens/options_screen.tscn`
- Default profile: **A**
- Layout: tabs y=6; rows x=12 y=28; help pane bottom 42.
- Components: `tab`, `list_row`, `toggle`, `slider`, `tooltip`, `modal`.
- States: video, audio, gameplay, language, reset.
- Input: move/adjust/confirm/cancel/page/help.
- Localization budget: row label <=24 EN / 12 JA; help 45x3 EN.
- Required art: option_icons_12, input_glyphs.
- Acceptance: **live preview for scale/profile; cancel restores pre-open values when requested.**

### accessibility

- Scene: `res://ui/screens/accessibility_screen.tscn`
- Default profile: **A**
- Layout: category rail 84; settings pane 220; preview 220x36 bottom.
- Components: `tab`, `list_row`, `toggle`, `slider`, `tooltip`.
- States: visual, motion, combat, text, input, audio_cues.
- Input: move/adjust/confirm/cancel/help.
- Localization budget: row label <=25 EN / 12 JA.
- Required art: contrast_test_96x36, bullet_shapes_12.
- Acceptance: **every switch testable in preview; reset is per category; forced A completes all content.**

### pause

- Scene: `res://ui/screens/pause_screen.tscn`
- Default profile: **A**
- Layout: game frozen behind 50% ordered mask; menu 136x148 right.
- Components: `frame`, `list_row`, `focus_marker`, `action_hint`.
- States: field, danmaku, fighter, minigame.
- Input: move/confirm/cancel/journal.
- Localization budget: label <=18 EN / 9 JA.
- Required art: pause_stamp_16.
- Acceptance: **opens within one frame offline; active input is released; combat resumes after 3-frame countdown.**

### credits

- Scene: `res://ui/screens/credits_screen.tscn`
- Default profile: **C**
- Layout: scroll field 296x140; chapter cards; skip hint.
- Components: `frame`, `region_stamp`, `page_indicator`, `action_hint`.
- States: rolling, paused, fast, complete.
- Input: confirm pause; hold page fast; cancel skip modal.
- Localization budget: credit role <=28 EN / 14 JA.
- Required art: ending_stamps, staff_portrait_cameos.
- Acceptance: **text never scrolls faster than 24px/s by default; full credits accessible from title.**


## NARRATIVE

### chapter_card

- Scene: `res://ui/screens/chapter_card.tscn`
- Default profile: **C**
- Layout: full composition; 240x64 title slip; stamp 32; continue bottom.
- Components: `frame`, `region_stamp`, `relation_seal`, `action_hint`.
- States: chapter, memory, incident, afterbeat.
- Input: confirm/cancel to skip after first view.
- Localization budget: title <=28 EN / 14 JA; subtitle <=42 EN.
- Required art: chapter_woodcut_320x180, region_stamp_32.
- Acceptance: **remains 90 frames minimum on first view; title survives forced A.**

### world_map

- Scene: `res://ui/screens/world_map.tscn`
- Default profile: **A**
- Layout: top ribbon 16; graph x=4 y=24 w=224 h=132; detail x=232 w=84; footer 20.
- Components: `top_ribbon`, `map_node`, `region_stamp`, `focus_marker`, `tooltip`, `action_hint`.
- States: free, travel_locked, incident, changed.
- Input: move/confirm/cancel/journal/page/help.
- Localization budget: node <=12 EN / 6 JA; detail <=12x8 EN.
- Required art: map_graph, 19_region_stamps_12, route_lines.
- Acceptance: **every node reachable without pointer; link direction and lock cause are readable.**

### destination_detail

- Scene: `res://ui/screens/destination_detail.tscn`
- Default profile: **A**
- Layout: region plate 128x72 left; spots/people right; travel action bottom.
- Components: `frame`, `region_stamp`, `list_row`, `thread_node`, `action_hint`.
- States: known, partial, changed, locked.
- Input: move/confirm/cancel/page.
- Localization budget: spot <=20 EN / 10 JA.
- Required art: region_thumb_128x72, cast_head_16.
- Acceptance: **shows knowledge state, not hidden spoiler; active companion affordance is explicit.**

### travel_confirm

- Scene: `res://ui/screens/travel_confirm.tscn`
- Default profile: **A**
- Layout: modal 272x88 over dimmed map; route line 232x16.
- Components: `modal`, `region_stamp`, `action_hint`, `loading_mark`.
- States: normal, cost, companion_warning, blocked.
- Input: confirm/cancel.
- Localization budget: cause <=40 EN x3 / 19 JA x3.
- Required art: travel_route_icons_12.
- Acceptance: **default focus is cancel only for irreversible warning; otherwise travel.**

### exploration_hud

- Scene: `res://ui/screens/exploration_hud.tscn`
- Default profile: **A**
- Layout: top ribbon optional; world prompts; footer appears only on hold/help.
- Components: `top_ribbon`, `prompt_chip`, `toast`, `action_hint`, `region_stamp`.
- States: free, near_spot, conversation_ready, changed, stealth, companion_action.
- Input: move/confirm/cancel/menu/journal/companion.
- Localization budget: prompt <=12 EN / 6 JA.
- Required art: prompt_shapes, companion_action_icons, region_stamp.
- Acceptance: **no permanent HUD covers faces; prompts clamp within 4px; hidden mode remains operable via audio/text cue.**

### spot_card

- Scene: `res://ui/screens/spot_card.tscn`
- Default profile: **C**
- Layout: 88x120 scene slip left; title and known hooks right; action footer.
- Components: `frame`, `region_stamp`, `thread_node`, `action_hint`.
- States: first_visit, repeat, changed, route_private.
- Input: confirm/cancel/journal.
- Localization budget: title <=24 EN / 12 JA.
- Required art: spot_woodcut_88x120, spot_stamp_16.
- Acceptance: **first visit establishes location; repeat variant completes in <=30 frames.**

### dialogue

- Scene: `res://ui/screens/dialogue_screen.tscn`
- Default profile: **A**
- Layout: portrait optional x=4 y=56; panel x=4 y=112 w=312 h=64; nameplate overlaps y=104.
- Components: `dialogue_panel`, `nameplate`, `portrait_window`, `action_hint`, `toast`.
- States: typing, await, auto, skip_read, narrator, aside, two_portrait.
- Input: confirm/cancel/menu/journal/page/help.
- Localization budget: 3x48 EN cells or 4x22 JA glyphs; name <=18 EN/9 JA.
- Required art: portrait_80x104, expression_parts, continue_marks.
- Acceptance: **no orphan one-word final line; auto/skip state visible; backlog stores exact localized text.**

### dialogue_choice

- Scene: `res://ui/screens/dialogue_choice.tscn`
- Default profile: **C**
- Layout: context panel 188x64 left; 3-4 cards x=200 y=100 w=116; optional portrait.
- Components: `dialogue_panel`, `choice_card`, `stance_stamp`, `focus_marker`, `tooltip`.
- States: direct, playful, patient, defiant, locked, changed.
- Input: move/confirm/cancel/help.
- Localization budget: choice <=26 EN x2 / 13 JA x2.
- Required art: stance_stamps_12, portrait_crop_80x104.
- Acceptance: **choice intent is described; locked reason available; no invisible affinity number.**

### backlog

- Scene: `res://ui/screens/backlog.tscn`
- Default profile: **A**
- Layout: speaker rail 72; text pane 238; scrollbar; event markers.
- Components: `frame`, `tab`, `list_row`, `scrollbar`, `page_indicator`, `action_hint`.
- States: dialogue, choice, system, filter_character.
- Input: move/confirm/cancel/page/help.
- Localization budget: exact prior localized lines; no truncation.
- Required art: speaker_heads_12, choice_stamps_8.
- Acceptance: **opens at latest line; choice and system records distinguishable without color.**

### route_threshold

- Scene: `res://ui/screens/route_threshold.tscn`
- Default profile: **C**
- Layout: relation seal 48 center; two narrative blocks; confirm action after reveal.
- Components: `frame`, `relation_seal`, `thread_node`, `action_hint`.
- States: quiet, open, strained, crossed, deferred.
- Input: confirm/cancel after 90 frames.
- Localization budget: title <=20 EN /10 JA; body 38x5 EN.
- Required art: character_route_seal_48, threshold_woodcut.
- Acceptance: **never says romance locked by a hidden number; consequence text is qualitative and reviewable in journal.**

### ending_card

- Scene: `res://ui/screens/ending_card.tscn`
- Default profile: **C**
- Layout: full 320x180 woodcut; 248x72 text slip; ending stamp 24.
- Components: `frame`, `relation_seal`, `region_stamp`, `action_hint`.
- States: route, ensemble, bad, afterbeat.
- Input: confirm; cancel skip modal.
- Localization budget: title <=28 EN /14 JA; body <=42x4 EN.
- Required art: ending_woodcut_320x180, ending_stamp_24.
- Acceptance: **ending ID stored after card completes; replay gallery lists unlocked language versions.**


## JOURNAL

### journal_summary

- Scene: `res://ui/screens/journal_summary.tscn`
- Default profile: **A**
- Layout: tabs y=4; active thread 304x40; recent changes; footer.
- Components: `tab`, `thread_node`, `list_row`, `relation_seal`, `page_indicator`, `action_hint`.
- States: normal, new, incident, route.
- Input: move/confirm/cancel/page.
- Localization budget: row <=32 EN /16 JA.
- Required art: journal_tabs, status_shapes.
- Acceptance: **new information sorted but never auto-opens spoilers; all states have text label.**

### journal_people

- Scene: `res://ui/screens/journal_people.tscn`
- Default profile: **B**
- Layout: list 96 left; 80x104 portrait; facts/rumors 126 right.
- Components: `tab`, `list_row`, `portrait_window`, `thread_node`, `scrollbar`, `relation_seal`.
- States: known, partial, changed, route_ready, unknown.
- Input: move/confirm/cancel/page/help.
- Localization budget: bio 20x8 EN /10x8 JA.
- Required art: portrait_80x104, person_stamp_16.
- Acceptance: **facts and rumors visually separated; relationship is qualitative; unknown data not inferable from layout count.**

### journal_places

- Scene: `res://ui/screens/journal_places.tscn`
- Default profile: **A**
- Layout: region list 92; thumbnail 128x72; spot grid and state key.
- Components: `tab`, `list_row`, `region_stamp`, `thread_node`, `page_indicator`.
- States: known, partial, changed, completed.
- Input: move/confirm/cancel/page.
- Localization budget: spot <=19 EN/9 JA.
- Required art: 19_region_stamps, region_thumb_128x72, 19_spot_maps.
- Acceptance: **state overlays list what player observed, not implementation flags.**

### journal_rumors

- Scene: `res://ui/screens/journal_rumors.tscn`
- Default profile: **B**
- Layout: filter tabs; rumor cards 296x28; source/status tail.
- Components: `tab`, `list_row`, `thread_node`, `scrollbar`, `tooltip`.
- States: observed, contradicted, changed, resolved, unreliable.
- Input: move/confirm/cancel/page/help.
- Localization budget: rumor <=42x2 EN /20x2 JA.
- Required art: rumor_status_shapes_8, source_heads_12.
- Acceptance: **source certainty and contradiction are text+shape; sorting never rewrites chronology.**

### memory_thread

- Scene: `res://ui/screens/memory_thread.tscn`
- Default profile: **B**
- Layout: graph 304x108; detail pane 304x48; pan cursor.
- Components: `thread_node`, `focus_marker`, `tooltip`, `scrollbar`, `action_hint`.
- States: observed, contradicted, changed, route, resolved.
- Input: move/pan/confirm/cancel/page/help.
- Localization budget: node <=16 EN/8 JA; detail <=48x4 EN.
- Required art: thread_lines, thread_status_shapes, evidence_icons.
- Acceptance: **all nodes reachable in linear list fallback; edges have pattern and label; no color dependence.**

### keepsakes

- Scene: `res://ui/screens/keepsakes.tscn`
- Default profile: **C**
- Layout: 5x3 40x40 grid left; selected 88x120 composition right.
- Components: `tab`, `list_row`, `focus_marker`, `tooltip`, `relation_seal`.
- States: unknown, found, changed, gifted, returned.
- Input: move/confirm/cancel/page/help.
- Localization budget: item <=20 EN/10 JA; note <=18x8 EN.
- Required art: keepsake_icons_32, item_woodcut_88x120.
- Acceptance: **unknown slots do not disclose exact total for secret items; changes preserve prior description in history.**

### character_profile

- Scene: `res://ui/screens/character_profile.tscn`
- Default profile: **C**
- Layout: portrait 88x120; route seal 32; facts, voice cue, shared memories.
- Components: `portrait_window`, `relation_seal`, `thread_node`, `page_indicator`, `action_hint`.
- States: known, major, deep, route_open, complete.
- Input: move/confirm/cancel/page.
- Localization budget: quote max 36 EN /18 JA; facts 22x7 EN.
- Required art: portrait_88x120, route_seal_32, motif_strip.
- Acceptance: **profile uses authored public knowledge only; production tier is never visible to player.**


## COMBAT

### danmaku_hud

- Scene: `res://ui/screens/danmaku_hud.tscn`
- Default profile: **D**
- Layout: playfield 224x152 left; status rail 88 right; top spell 16; footer 12.
- Components: `meter`, `pip_row`, `combat_timer`, `spell_banner`, `reticle`, `action_hint`.
- States: normal, focus, bomb, life_lost, spell, pause, clear.
- Input: move/focus/shot/bomb/pause.
- Localization budget: spell <=24 EN/12 JA; labels <=10 EN.
- Required art: bullet_shape_atlas, player_hitbox, boss_stamp, HUD_icons.
- Acceptance: **bullets retain full contrast; score is secondary; focus reticle shows hitbox; decor suppressed on focus.**

### spell_card_intro

- Scene: `res://ui/screens/spell_card_intro.tscn`
- Default profile: **D**
- Layout: 24px banner; owner stamp; card title; playfield remains visible.
- Components: `spell_banner`, `region_stamp`, `action_hint`.
- States: first, repeat, timeout.
- Input: confirm skips repeat only.
- Localization budget: title <=26 EN/13 JA.
- Required art: spell_owner_stamps, spell_banner_corners.
- Acceptance: **first intro <=60 frames; repeated <=24; collision inactive until banner exits.**

### danmaku_result

- Scene: `res://ui/screens/danmaku_result.tscn`
- Default profile: **D**
- Layout: result card 272x128; stat rows; retry/continue actions.
- Components: `frame`, `list_row`, `meter`, `pip_row`, `choice_card`.
- States: clear, fail, practice, new_record.
- Input: move/confirm/cancel.
- Localization budget: stat <=18 EN/9 JA.
- Required art: result_stamps, capture_mark.
- Acceptance: **shows capture/fail reason in words; restart is one confirmation; story mode always exposes continue policy.**

### fighter_hud

- Scene: `res://ui/screens/fighter_hud.tscn`
- Default profile: **A**
- Layout: name+life top edges; timer center; spell pips; arena bottom footer.
- Components: `meter`, `pip_row`, `combat_timer`, `action_hint`, `relation_seal`.
- States: round_intro, active, spell_break, down, pause, sudden.
- Input: move/light/heavy/skill/spell/companion/pause.
- Localization budget: name <=16 EN/8 JA.
- Required art: fighter_portrait_24, skill_icons_12, round_stamps.
- Acceptance: **both sides mirrored semantically; health loss has delayed notch; arena decor drops under effects.**

### fighter_result

- Scene: `res://ui/screens/fighter_result.tscn`
- Default profile: **C**
- Layout: winner woodcut 136x104; round marks; rematch/continue.
- Components: `frame`, `relation_seal`, `pip_row`, `choice_card`.
- States: win, loss, draw, story_continue, versus.
- Input: move/confirm/cancel.
- Localization budget: result line <=32 EN/16 JA.
- Required art: winner_pose_136x104, round_marks.
- Acceptance: **story outcome explains narrative continuation; versus supports immediate rematch.**

### training_pause

- Scene: `res://ui/screens/training_pause.tscn`
- Default profile: **A**
- Layout: command list 136; frame data 168; input history bottom.
- Components: `tab`, `list_row`, `toggle`, `slider`, `scrollbar`, `action_hint`.
- States: commands, dummy, display, reset.
- Input: move/adjust/confirm/cancel/page.
- Localization budget: command <=20 EN/10 JA.
- Required art: command_icons, input_history_glyphs.
- Acceptance: **all fighter actions discoverable; reset position one action; frame display optional.**


## ACTIVITY

### minigame_shell

- Scene: `res://ui/screens/minigame_shell.tscn`
- Default profile: **A**
- Layout: top objective 20; central custom playfield; progress/status; footer controls.
- Components: `top_ribbon`, `meter`, `pip_row`, `combat_timer`, `action_hint`, `region_stamp`.
- States: intro, active, success, partial, fail, pause.
- Input: custom + confirm/cancel/pause.
- Localization budget: objective <=38 EN/19 JA.
- Required art: 19_region_stamps, activity_icons_12, result_marks.
- Acceptance: **every minigame declares objective and controls before input; retry <=2 actions; story never hard-locks on dexterity.**

### photo_camera

- Scene: `res://ui/screens/photo_camera.tscn`
- Default profile: **D**
- Layout: viewfinder 272x144; right exposure rail; target tags; shutter footer.
- Components: `reticle`, `meter`, `pip_row`, `action_hint`, `toast`.
- States: free, target, locked, shutter, review.
- Input: move/adjust/confirm/cancel/focus.
- Localization budget: target <=16 EN/8 JA.
- Required art: camera_corners, subject_tags, photo_grade_stamps.
- Acceptance: **shutter flash replaced by border close in safe mode; target criteria readable before capture.**

### trade_shop

- Scene: `res://ui/screens/trade_shop.tscn`
- Default profile: **A**
- Layout: category tabs; item list 124; item detail 176; purse footer.
- Components: `tab`, `list_row`, `tooltip`, `pip_row`, `modal`, `toast`.
- States: buy, sell, trade, unavailable, confirm.
- Input: move/confirm/cancel/page/help.
- Localization budget: item <=22 EN/11 JA; description 28x5 EN.
- Required art: item_icons_16, currency_shapes, shop_stamp.
- Acceptance: **price/currency shown in digits and icon; unavailable reason shown; irreversible unique trade confirms.**

### clinic

- Scene: `res://ui/screens/clinic.tscn`
- Default profile: **B**
- Layout: patient rail 80; symptoms/evidence 116; medicine tray 108; result modal.
- Components: `tab`, `list_row`, `thread_node`, `focus_marker`, `modal`, `toast`.
- States: observe, diagnose, compound, administer, result.
- Input: move/confirm/cancel/page/help.
- Localization budget: symptom <=22 EN/11 JA.
- Required art: vial_icons_16, symptom_shapes, dosage_meter.
- Acceptance: **wrong answer gives narrative feedback without medical-realism claims; ingredient effects reviewable.**

### activity_result

- Scene: `res://ui/screens/activity_result.tscn`
- Default profile: **C**
- Layout: region stamp 24; result seal 48; 3 stat rows; continue/retry.
- Components: `frame`, `region_stamp`, `relation_seal`, `list_row`, `choice_card`.
- States: success, partial, fail, route_variant, record.
- Input: move/confirm/cancel.
- Localization budget: result <=36 EN/18 JA.
- Required art: activity_result_seals, character_reaction_head.
- Acceptance: **partial success is explicit; relationship reaction described qualitatively; no hidden score required for route.**

