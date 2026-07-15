# UI Acceptance Matrix

A screen is not done when it merely resembles a mockup. It is done when its state, input, localization, profile and accessibility contracts pass.

| Screen | State proof | Input proof | Localization proof | Profile proof | Blocking acceptance |
|---|---|---|---|---|---|
| boot | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | never shows a blank frame longer than 500ms; error exposes safe quit and retry |
| language_select | capture 2 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | chosen font renders sample before confirmation; selection is stored immediately |
| content_notice | capture 2 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | full notice keyboard/pad readable; accept is never pre-committed by held input |
| title | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | logo/background remain readable at 1x; continue hidden only when no valid save exists |
| profile_select | capture 3 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | profiles change presentation only; forced A statement is explicit |
| new_game_setup | capture 3 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | all difficulty/access choices are reversible; no route is chosen here |
| save_load | capture 6 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | save waits for flush mark; overwrite has explicit slot identity; corrupt slots are not silently deleted |
| options | capture 5 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | live preview for scale/profile; cancel restores pre-open values when requested |
| accessibility | capture 6 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | every switch testable in preview; reset is per category; forced A completes all content |
| pause | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | opens within one frame offline; active input is released; combat resumes after 3-frame countdown |
| credits | capture 4 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | text never scrolls faster than 24px/s by default; full credits accessible from title |
| chapter_card | capture 4 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | remains 90 frames minimum on first view; title survives forced A |
| world_map | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | every node reachable without pointer; link direction and lock cause are readable |
| destination_detail | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | shows knowledge state, not hidden spoiler; active companion affordance is explicit |
| travel_confirm | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | default focus is cancel only for irreversible warning; otherwise travel |
| exploration_hud | capture 6 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | no permanent HUD covers faces; prompts clamp within 4px; hidden mode remains operable via audio/text cue |
| spot_card | capture 4 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | first visit establishes location; repeat variant completes in <=30 frames |
| dialogue | capture 7 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | no orphan one-word final line; auto/skip state visible; backlog stores exact localized text |
| dialogue_choice | capture 6 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | choice intent is described; locked reason available; no invisible affinity number |
| backlog | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | opens at latest line; choice and system records distinguishable without color |
| route_threshold | capture 5 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | never says romance locked by a hidden number; consequence text is qualitative and reviewable in journal |
| ending_card | capture 4 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | ending ID stored after card completes; replay gallery lists unlocked language versions |
| journal_summary | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | new information sorted but never auto-opens spoilers; all states have text label |
| journal_people | capture 5 states | keyboard + pad + remap | EN/JA overflow test | B + forced A | facts and rumors visually separated; relationship is qualitative; unknown data not inferable from layout count |
| journal_places | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | state overlays list what player observed, not implementation flags |
| journal_rumors | capture 5 states | keyboard + pad + remap | EN/JA overflow test | B + forced A | source certainty and contradiction are text+shape; sorting never rewrites chronology |
| memory_thread | capture 5 states | keyboard + pad + remap | EN/JA overflow test | B + forced A | all nodes reachable in linear list fallback; edges have pattern and label; no color dependence |
| keepsakes | capture 5 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | unknown slots do not disclose exact total for secret items; changes preserve prior description in history |
| character_profile | capture 5 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | profile uses authored public knowledge only; production tier is never visible to player |
| danmaku_hud | capture 7 states | keyboard + pad + remap | EN/JA overflow test | D + forced A | bullets retain full contrast; score is secondary; focus reticle shows hitbox; decor suppressed on focus |
| spell_card_intro | capture 3 states | keyboard + pad + remap | EN/JA overflow test | D + forced A | first intro <=60 frames; repeated <=24; collision inactive until banner exits |
| danmaku_result | capture 4 states | keyboard + pad + remap | EN/JA overflow test | D + forced A | shows capture/fail reason in words; restart is one confirmation; story mode always exposes continue policy |
| fighter_hud | capture 6 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | both sides mirrored semantically; health loss has delayed notch; arena decor drops under effects |
| fighter_result | capture 5 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | story outcome explains narrative continuation; versus supports immediate rematch |
| training_pause | capture 4 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | all fighter actions discoverable; reset position one action; frame display optional |
| minigame_shell | capture 6 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | every minigame declares objective and controls before input; retry <=2 actions; story never hard-locks on dexterity |
| photo_camera | capture 5 states | keyboard + pad + remap | EN/JA overflow test | D + forced A | shutter flash replaced by border close in safe mode; target criteria readable before capture |
| trade_shop | capture 5 states | keyboard + pad + remap | EN/JA overflow test | A + forced A | price/currency shown in digits and icon; unavailable reason shown; irreversible unique trade confirms |
| clinic | capture 5 states | keyboard + pad + remap | EN/JA overflow test | B + forced A | wrong answer gives narrative feedback without medical-realism claims; ingredient effects reviewable |
| activity_result | capture 5 states | keyboard + pad + remap | EN/JA overflow test | C + forced A | partial success is explicit; relationship reaction described qualitatively; no hidden score required for route |

## Global automated checks

1. Scan exported textures: every visible pixel must be #000 or #fff.
2. Reject non-integer Control positions, scale or camera zoom.
3. Traverse focus graph from every entry node; no trap, no unreachable enabled target.
4. Render pseudo-localized EN at +35% and JA at representative full-width count; flag crop/overlap.
5. Compare every screen under forced A; gameplay state and available actions must match native profile.
6. Capture 1×, 2×, 4×; reject filtering, uneven pixel widths and font smoothing.
7. In combat focus mode, sample 16 px around each bullet/hazard; decor must not share its exact shape/frequency.
