#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../..');
const OUT = path.join(ROOT, '05_ui_ux');

const tokens = {
  schema: 'gensokyo-monochrome-ui-v2',
  internal_canvas: [320, 180],
  scale: { allowed: [2,3,4,5,6], filter: 'nearest', fractional_scaling: false },
  palette: { ink: '#000000', paper: '#ffffff', transparent: '#00000000', visible_colors: 2 },
  grid: { micro: 2, ui: 4, tile: 16, safe_margin: 4, text_baseline: 8 },
  typography: {
    latin: { family: 'Kiri8', cell: [6,8], baseline: 7, body: 8, label: 8, title: 16 },
    japanese: { family: 'DotGothic16 subset', cell: [8,8], baseline: 7, body: 8, label: 8, title: 16 },
    fallback: 'full-width 8x8 bitmap glyph; no runtime antialiasing',
    line_heights: [8,10,12,16]
  },
  borders: { hairline: 1, standard: 2, heavy: 3, double_gap: 2, focus_inset: 2 },
  timing_frames_60fps: { focus_move: 4, confirm: 3, cancel: 3, panel_open: 6, page_turn: 8, toast_hold: 90, profile_switch_max: 6 },
  dither: { matrix: '4x4 Bayer', levels: [0,25,50,75,100], animate: false, forbidden_zones: ['body text','choice label','bullet field','focus reticle'] },
  profiles: {
    A: { name: 'Pocket Shrine', polarity: 'paper', black_budget: '25-35%', frame: '2px open-corner', use: 'default/exploration/system' },
    B: { name: 'PC-98 Dither', polarity: 'paper or controlled ink', black_budget: '40-50%', frame: '1px double + corner blocks', use: 'dense interiors/investigation' },
    C: { name: 'Woodblock Adventure', polarity: 'paper', black_budget: 'compositional blocks', frame: 'paper slip + fold', use: 'relationship/memory/chapter' },
    D: { name: 'Midnight LCD', polarity: 'ink', black_budget: '70-85%', frame: '2px white line', use: 'combat/night/dream/underground' }
  },
  input: {
    actions: ['move','confirm','cancel','menu','journal','focus','shot','bomb','light','heavy','skill','spell','companion','page_left','page_right'],
    glyphs: 'resolved from active device; text action name is always available',
    hold_threshold_ms: 350,
    repeat_ms: { initial: 300, interval: 80 }
  },
  accessibility: {
    min_target: [16,16],
    focus: '2px outline + leading > or corner notch; never polarity alone',
    reduced_motion: 'replace wipes/shake/flicker with 3-frame border tick',
    forced_profile: 'A must support every screen and every gameplay outcome',
    combat_contrast: 'bullet/hazard center contrast must be 100%; decor is suppressed in focus mode',
    photosensitivity: 'no full-screen alternating flash; hit inversion limited to local 32x32 for one frame'
  }
};

const components = [
  ['frame','PanelFrame','variable, min 24x16','idle/focused/disabled/urgent','A open-corner; B double; C fold; D white line','9-slice with integer margins'],
  ['top_ribbon','TopRibbon','312x16','normal/incident/combat','time, weather, location, thread state','never more than 40 Latin cells'],
  ['region_stamp','RegionStamp','12x12 / 16x16','locked/known/active/changed','unique 1-bit mark per region','must pass at 12x12'],
  ['tab','Tab','48x14 min','idle/focused/selected/disabled/new','label + optional 6x6 badge','selected uses lower-edge merge'],
  ['list_row','ListRow','variable x 16','idle/focused/selected/disabled/changed','icon, label, status tail','one row = one focus target'],
  ['focus_marker','FocusMarker','variable','keyboard/pad/pointer','leading > + 2px inset corners','4-frame move, no tween blur'],
  ['action_hint','ActionHint','min 36x12','available/held/blocked/alternate','device glyph + verb','verb remains visible without glyph'],
  ['prompt_chip','PromptChip','min 20x12','observe/talk/use/carry/danger','12x12 shape + 8px text','world anchored, clamped to safe area'],
  ['dialogue_panel','DialoguePanel','312x64 standard','idle/typing/await/auto/history','name, body, continue mark, voice state','3 EN lines or 4 JA lines'],
  ['nameplate','Nameplate','min 48x12','speaker/aside/narrator/unknown','localized name + speaking notch','never baked into portrait'],
  ['portrait_window','PortraitWindow','88x120 / 80x104','normal/crop/occluded/absent','separate portrait and frame layers','may break C frame by max 8px'],
  ['choice_card','ChoiceCard','296x18 min','idle/focused/committed/locked/changed','stance stamp + 1-2 lines','stack gap 2px; no timeout by default'],
  ['stance_stamp','StanceStamp','12x12','direct/playful/patient/defiant/context','shape + text label','relationship meaning is never color-coded'],
  ['toast','Toast','max 216x24','info/item/rumor/error','icon, 1-2 lines, optional action','queues; never covers choices or hitbox'],
  ['scrollbar','PixelScrollbar','6x variable','idle/focused/drag/at_start/at_end','track, 4px min thumb, arrow ends','page actions work without dragging'],
  ['meter','Meter','variable x 8','normal/gain/loss/locked/unknown','outline, fill, delayed change notch','also exposes numeric/text alternative'],
  ['pip_row','PipRow','8px pitch','full/empty/used/charged/locked','shape differs by semantic','max 12 before grouping'],
  ['reticle','FocusReticle','16x16 / 24x24','free/target/locked/danger','four corners + center point','no smooth scaling'],
  ['spell_banner','SpellBanner','312x24','intro/active/timeout/cleared/failed','owner, card title, bonus state','skippable after first view'],
  ['combat_timer','CombatTimer','40x12','normal/low/paused/sudden','digits + border cadence','low state adds !, not flash'],
  ['save_slot','SaveSlot','296x36','empty/valid/focused/overwrite/corrupt','thumbnail 64x32, chapter, place, time','corrupt slot remains exportable'],
  ['map_node','MapNode','12x12 / 16x16','unknown/known/available/active/changed/locked','region stamp + link anchor','link line never crosses its label'],
  ['thread_node','ThreadNode','12x12','observed/contradicted/changed/resolved/route','shape + connecting line style','status remains textual in detail pane'],
  ['tooltip','Tooltip','max 152x48','info/help/error','title + 1-4 short lines','opens after 350ms or help action'],
  ['modal','Modal','272x80 min','question/warning/destructive/progress','title, body, actions','default action cannot be destructive'],
  ['toggle','PixelToggle','28x12','off/on/focused/disabled/mixed','text label + two-position marker','does not rely on black/white polarity'],
  ['slider','PixelSlider','96x12','focused/drag/disabled','ticks + value text','step actions and reset available'],
  ['page_indicator','PageIndicator','48x10','normal/last/unread','current/total + optional unread notch','placed consistently at bottom right'],
  ['relation_seal','RelationSeal','32x32','quiet/open/strained/threshold/complete','character motif + qualitative word','no affection number in narrative UI'],
  ['loading_mark','LoadingMark','16x16','loading/saving/complete/error','4-frame rotating gohei corners','saving text remains until flush completes']
].map(([id,node,size,states,content,rule])=>({id,node,size,states:states.split('/'),content,rule}));

const S = (id, category, profile, scene, layout, componentsUsed, states, input, localization, assets, acceptance) => ({
  id, category, default_profile: profile, godot_scene: `res://ui/screens/${scene}.tscn`,
  layout, components: componentsUsed, states, input, localization, assets, acceptance
});

const screens = [
  S('boot','system','A','boot_screen','center 160x64 mark; status y=148','loading_mark',['loading','saving_migration','error','ready'],'cancel only during non-destructive loading','brand text <=24 EN / 12 JA glyphs','brand_mark_64, loading_gohei_16','never shows a blank frame longer than 500ms; error exposes safe quit and retry'),
  S('language_select','system','A','language_select','title y=28; two 120x28 cards centered; help y=142','frame,choice_card,focus_marker,action_hint',['first_boot','from_options'],'move/confirm/cancel when from options','language names are endonyms; each card <=12 glyphs','language_stamp_en, language_stamp_ja','chosen font renders sample before confirmation; selection is stored immediately'),
  S('content_notice','system','A','content_notice','272x132 modal; scroll body 244x76; actions bottom','modal,scrollbar,choice_card,action_hint',['first_view','revisit'],'scroll/confirm/cancel','body 33 EN chars x 7 lines or 16 JA glyphs x 7','notice_icons_12','full notice keyboard/pad readable; accept is never pre-committed by held input'),
  S('title','system','A','title_screen','logo x=16 y=20; menu x=176 y=86 w=128; version bottom','frame,list_row,focus_marker,loading_mark',['fresh','continue_available','no_save','update_notice'],'move/confirm/cancel/menu','menu <=18 EN / 9 JA glyphs','title_logo_192x64, title_bg_320x180, season_overlay','logo/background remain readable at 1x; continue hidden only when no valid save exists'),
  S('profile_select','system','A','profile_select','four 72x96 cards; preview top 48; explanation bottom','frame,choice_card,focus_marker,tooltip',['choose_default','preview','forced_A'],'move/confirm/cancel/help','profile label <=14 EN / 7 JA; explanation 42x3 EN','profile_preview_A-D_64x48','profiles change presentation only; forced A statement is explicit'),
  S('new_game_setup','system','A','new_game_setup','left options 160x124; right summary 136x124; confirm bottom','frame,list_row,toggle,slider,tooltip,modal',['new','preset_applied','confirm'],'move/adjust/confirm/cancel/help','labels <=20 EN / 10 JA','difficulty_stamps_12, input_glyphs','all difficulty/access choices are reversible; no route is chosen here'),
  S('save_load','system','A','save_load','tabs y=6; five 296x36 slots paged; modal overlay','tab,save_slot,scrollbar,page_indicator,modal,loading_mark',['save','load','autosave','empty','overwrite','corrupt'],'move/confirm/cancel/page/help','chapter/place each <=23 EN / 11 JA','save_thumbnail_region_64x32, slot_status_8','save waits for flush mark; overwrite has explicit slot identity; corrupt slots are not silently deleted'),
  S('options','system','A','options_screen','tabs y=6; rows x=12 y=28; help pane bottom 42','tab,list_row,toggle,slider,tooltip,modal',['video','audio','gameplay','language','reset'],'move/adjust/confirm/cancel/page/help','row label <=24 EN / 12 JA; help 45x3 EN','option_icons_12, input_glyphs','live preview for scale/profile; cancel restores pre-open values when requested'),
  S('accessibility','system','A','accessibility_screen','category rail 84; settings pane 220; preview 220x36 bottom','tab,list_row,toggle,slider,tooltip',['visual','motion','combat','text','input','audio_cues'],'move/adjust/confirm/cancel/help','row label <=25 EN / 12 JA','contrast_test_96x36, bullet_shapes_12','every switch testable in preview; reset is per category; forced A completes all content'),
  S('pause','system','A','pause_screen','game frozen behind 50% ordered mask; menu 136x148 right','frame,list_row,focus_marker,action_hint',['field','danmaku','fighter','minigame'],'move/confirm/cancel/journal','label <=18 EN / 9 JA','pause_stamp_16','opens within one frame offline; active input is released; combat resumes after 3-frame countdown'),
  S('credits','system','C','credits_screen','scroll field 296x140; chapter cards; skip hint','frame,region_stamp,page_indicator,action_hint',['rolling','paused','fast','complete'],'confirm pause; hold page fast; cancel skip modal','credit role <=28 EN / 14 JA','ending_stamps, staff_portrait_cameos','text never scrolls faster than 24px/s by default; full credits accessible from title'),

  S('chapter_card','narrative','C','chapter_card','full composition; 240x64 title slip; stamp 32; continue bottom','frame,region_stamp,relation_seal,action_hint',['chapter','memory','incident','afterbeat'],'confirm/cancel to skip after first view','title <=28 EN / 14 JA; subtitle <=42 EN','chapter_woodcut_320x180, region_stamp_32','remains 90 frames minimum on first view; title survives forced A'),
  S('world_map','narrative','A','world_map','top ribbon 16; graph x=4 y=24 w=224 h=132; detail x=232 w=84; footer 20','top_ribbon,map_node,region_stamp,focus_marker,tooltip,action_hint',['free','travel_locked','incident','changed'],'move/confirm/cancel/journal/page/help','node <=12 EN / 6 JA; detail <=12x8 EN','map_graph, 19_region_stamps_12, route_lines','every node reachable without pointer; link direction and lock cause are readable'),
  S('destination_detail','narrative','A','destination_detail','region plate 128x72 left; spots/people right; travel action bottom','frame,region_stamp,list_row,thread_node,action_hint',['known','partial','changed','locked'],'move/confirm/cancel/page','spot <=20 EN / 10 JA','region_thumb_128x72, cast_head_16','shows knowledge state, not hidden spoiler; active companion affordance is explicit'),
  S('travel_confirm','narrative','A','travel_confirm','modal 272x88 over dimmed map; route line 232x16','modal,region_stamp,action_hint,loading_mark',['normal','cost','companion_warning','blocked'],'confirm/cancel','cause <=40 EN x3 / 19 JA x3','travel_route_icons_12','default focus is cancel only for irreversible warning; otherwise travel'),
  S('exploration_hud','narrative','A','exploration_hud','top ribbon optional; world prompts; footer appears only on hold/help','top_ribbon,prompt_chip,toast,action_hint,region_stamp',['free','near_spot','conversation_ready','changed','stealth','companion_action'],'move/confirm/cancel/menu/journal/companion','prompt <=12 EN / 6 JA','prompt_shapes, companion_action_icons, region_stamp','no permanent HUD covers faces; prompts clamp within 4px; hidden mode remains operable via audio/text cue'),
  S('spot_card','narrative','C','spot_card','88x120 scene slip left; title and known hooks right; action footer','frame,region_stamp,thread_node,action_hint',['first_visit','repeat','changed','route_private'],'confirm/cancel/journal','title <=24 EN / 12 JA','spot_woodcut_88x120, spot_stamp_16','first visit establishes location; repeat variant completes in <=30 frames'),
  S('dialogue','narrative','A','dialogue_screen','portrait optional x=4 y=56; panel x=4 y=112 w=312 h=64; nameplate overlaps y=104','dialogue_panel,nameplate,portrait_window,action_hint,toast',['typing','await','auto','skip_read','narrator','aside','two_portrait'],'confirm/cancel/menu/journal/page/help','3x48 EN cells or 4x22 JA glyphs; name <=18 EN/9 JA','portrait_80x104, expression_parts, continue_marks','no orphan one-word final line; auto/skip state visible; backlog stores exact localized text'),
  S('dialogue_choice','narrative','C','dialogue_choice','context panel 188x64 left; 3-4 cards x=200 y=100 w=116; optional portrait','dialogue_panel,choice_card,stance_stamp,focus_marker,tooltip',['direct','playful','patient','defiant','locked','changed'],'move/confirm/cancel/help','choice <=26 EN x2 / 13 JA x2','stance_stamps_12, portrait_crop_80x104','choice intent is described; locked reason available; no invisible affinity number'),
  S('backlog','narrative','A','backlog','speaker rail 72; text pane 238; scrollbar; event markers','frame,tab,list_row,scrollbar,page_indicator,action_hint',['dialogue','choice','system','filter_character'],'move/confirm/cancel/page/help','exact prior localized lines; no truncation','speaker_heads_12, choice_stamps_8','opens at latest line; choice and system records distinguishable without color'),
  S('route_threshold','narrative','C','route_threshold','relation seal 48 center; two narrative blocks; confirm action after reveal','frame,relation_seal,thread_node,action_hint',['quiet','open','strained','crossed','deferred'],'confirm/cancel after 90 frames','title <=20 EN /10 JA; body 38x5 EN','character_route_seal_48, threshold_woodcut','never says romance locked by a hidden number; consequence text is qualitative and reviewable in journal'),
  S('ending_card','narrative','C','ending_card','full 320x180 woodcut; 248x72 text slip; ending stamp 24','frame,relation_seal,region_stamp,action_hint',['route','ensemble','bad','afterbeat'],'confirm; cancel skip modal','title <=28 EN /14 JA; body <=42x4 EN','ending_woodcut_320x180, ending_stamp_24','ending ID stored after card completes; replay gallery lists unlocked language versions'),

  S('journal_summary','journal','A','journal_summary','tabs y=4; active thread 304x40; recent changes; footer','tab,thread_node,list_row,relation_seal,page_indicator,action_hint',['normal','new','incident','route'],'move/confirm/cancel/page','row <=32 EN /16 JA','journal_tabs, status_shapes','new information sorted but never auto-opens spoilers; all states have text label'),
  S('journal_people','journal','B','journal_people','list 96 left; 80x104 portrait; facts/rumors 126 right','tab,list_row,portrait_window,thread_node,scrollbar,relation_seal',['known','partial','changed','route_ready','unknown'],'move/confirm/cancel/page/help','bio 20x8 EN /10x8 JA','portrait_80x104, person_stamp_16','facts and rumors visually separated; relationship is qualitative; unknown data not inferable from layout count'),
  S('journal_places','journal','A','journal_places','region list 92; thumbnail 128x72; spot grid and state key','tab,list_row,region_stamp,thread_node,page_indicator',['known','partial','changed','completed'],'move/confirm/cancel/page','spot <=19 EN/9 JA','19_region_stamps, region_thumb_128x72, 19_spot_maps','state overlays list what player observed, not implementation flags'),
  S('journal_rumors','journal','B','journal_rumors','filter tabs; rumor cards 296x28; source/status tail','tab,list_row,thread_node,scrollbar,tooltip',['observed','contradicted','changed','resolved','unreliable'],'move/confirm/cancel/page/help','rumor <=42x2 EN /20x2 JA','rumor_status_shapes_8, source_heads_12','source certainty and contradiction are text+shape; sorting never rewrites chronology'),
  S('memory_thread','journal','B','memory_thread','graph 304x108; detail pane 304x48; pan cursor','thread_node,focus_marker,tooltip,scrollbar,action_hint',['observed','contradicted','changed','route','resolved'],'move/pan/confirm/cancel/page/help','node <=16 EN/8 JA; detail <=48x4 EN','thread_lines, thread_status_shapes, evidence_icons','all nodes reachable in linear list fallback; edges have pattern and label; no color dependence'),
  S('keepsakes','journal','C','keepsakes','5x3 40x40 grid left; selected 88x120 composition right','tab,list_row,focus_marker,tooltip,relation_seal',['unknown','found','changed','gifted','returned'],'move/confirm/cancel/page/help','item <=20 EN/10 JA; note <=18x8 EN','keepsake_icons_32, item_woodcut_88x120','unknown slots do not disclose exact total for secret items; changes preserve prior description in history'),
  S('character_profile','journal','C','character_profile','portrait 88x120; route seal 32; facts, voice cue, shared memories','portrait_window,relation_seal,thread_node,page_indicator,action_hint',['known','major','deep','route_open','complete'],'move/confirm/cancel/page','quote max 36 EN /18 JA; facts 22x7 EN','portrait_88x120, route_seal_32, motif_strip','profile uses authored public knowledge only; production tier is never visible to player'),

  S('danmaku_hud','combat','D','danmaku_hud','playfield 224x152 left; status rail 88 right; top spell 16; footer 12','meter,pip_row,combat_timer,spell_banner,reticle,action_hint',['normal','focus','bomb','life_lost','spell','pause','clear'],'move/focus/shot/bomb/pause','spell <=24 EN/12 JA; labels <=10 EN','bullet_shape_atlas, player_hitbox, boss_stamp, HUD_icons','bullets retain full contrast; score is secondary; focus reticle shows hitbox; decor suppressed on focus'),
  S('spell_card_intro','combat','D','spell_card_intro','24px banner; owner stamp; card title; playfield remains visible','spell_banner,region_stamp,action_hint',['first','repeat','timeout'],'confirm skips repeat only','title <=26 EN/13 JA','spell_owner_stamps, spell_banner_corners','first intro <=60 frames; repeated <=24; collision inactive until banner exits'),
  S('danmaku_result','combat','D','danmaku_result','result card 272x128; stat rows; retry/continue actions','frame,list_row,meter,pip_row,choice_card',['clear','fail','practice','new_record'],'move/confirm/cancel','stat <=18 EN/9 JA','result_stamps, capture_mark','shows capture/fail reason in words; restart is one confirmation; story mode always exposes continue policy'),
  S('fighter_hud','combat','A','fighter_hud','name+life top edges; timer center; spell pips; arena bottom footer','meter,pip_row,combat_timer,action_hint,relation_seal',['round_intro','active','spell_break','down','pause','sudden'],'move/light/heavy/skill/spell/companion/pause','name <=16 EN/8 JA','fighter_portrait_24, skill_icons_12, round_stamps','both sides mirrored semantically; health loss has delayed notch; arena decor drops under effects'),
  S('fighter_result','combat','C','fighter_result','winner woodcut 136x104; round marks; rematch/continue','frame,relation_seal,pip_row,choice_card',['win','loss','draw','story_continue','versus'],'move/confirm/cancel','result line <=32 EN/16 JA','winner_pose_136x104, round_marks','story outcome explains narrative continuation; versus supports immediate rematch'),
  S('training_pause','combat','A','training_pause','command list 136; frame data 168; input history bottom','tab,list_row,toggle,slider,scrollbar,action_hint',['commands','dummy','display','reset'],'move/adjust/confirm/cancel/page','command <=20 EN/10 JA','command_icons, input_history_glyphs','all fighter actions discoverable; reset position one action; frame display optional'),

  S('minigame_shell','activity','A','minigame_shell','top objective 20; central custom playfield; progress/status; footer controls','top_ribbon,meter,pip_row,combat_timer,action_hint,region_stamp',['intro','active','success','partial','fail','pause'],'custom + confirm/cancel/pause','objective <=38 EN/19 JA','19_region_stamps, activity_icons_12, result_marks','every minigame declares objective and controls before input; retry <=2 actions; story never hard-locks on dexterity'),
  S('photo_camera','activity','D','photo_camera','viewfinder 272x144; right exposure rail; target tags; shutter footer','reticle,meter,pip_row,action_hint,toast',['free','target','locked','shutter','review'],'move/adjust/confirm/cancel/focus','target <=16 EN/8 JA','camera_corners, subject_tags, photo_grade_stamps','shutter flash replaced by border close in safe mode; target criteria readable before capture'),
  S('trade_shop','activity','A','trade_shop','category tabs; item list 124; item detail 176; purse footer','tab,list_row,tooltip,pip_row,modal,toast',['buy','sell','trade','unavailable','confirm'],'move/confirm/cancel/page/help','item <=22 EN/11 JA; description 28x5 EN','item_icons_16, currency_shapes, shop_stamp','price/currency shown in digits and icon; unavailable reason shown; irreversible unique trade confirms'),
  S('clinic','activity','B','clinic','patient rail 80; symptoms/evidence 116; medicine tray 108; result modal','tab,list_row,thread_node,focus_marker,modal,toast',['observe','diagnose','compound','administer','result'],'move/confirm/cancel/page/help','symptom <=22 EN/11 JA','vial_icons_16, symptom_shapes, dosage_meter','wrong answer gives narrative feedback without medical-realism claims; ingredient effects reviewable'),
  S('activity_result','activity','C','activity_result','region stamp 24; result seal 48; 3 stat rows; continue/retry','frame,region_stamp,relation_seal,list_row,choice_card',['success','partial','fail','route_variant','record'],'move/confirm/cancel','result <=36 EN/18 JA','activity_result_seals, character_reaction_head','partial success is explicit; relationship reaction described qualitatively; no hidden score required for route')
];

function csvCell(v) { const s=String(v??''); return /[",\n]/.test(s)?`"${s.replace(/"/g,'""')}"`:s; }
function write(name, data) { fs.mkdirSync(path.dirname(path.join(OUT,name)),{recursive:true}); fs.writeFileSync(path.join(OUT,name),data); }
function list(v) { return String(v).split(',').map(x=>x.trim()).filter(Boolean); }

const componentIds = new Set(components.map(x=>x.id));
for (const s of screens) {
  s.components = list(s.components);
  const bad = s.components.filter(x=>!componentIds.has(x));
  if (bad.length) throw new Error(`${s.id}: unknown components ${bad.join(',')}`);
}

write('ui_tokens_v2.json', JSON.stringify(tokens,null,2)+'\n');
write('component_catalog.json', JSON.stringify({schema:tokens.schema,components},null,2)+'\n');
write('screen_inventory.json', JSON.stringify({schema:tokens.schema,count:screens.length,screens},null,2)+'\n');
write('godot_scene_map.json', JSON.stringify({
  autoloads: ['UiThemeRegistry','InputGlyphService','FocusRouter','LocalizationMeasure','AccessibilityState','ToastQueue'],
  base_scenes: {
    UiScreenBase:'res://ui/base/ui_screen_base.tscn', ModalBase:'res://ui/base/modal_base.tscn',
    JournalBase:'res://ui/base/journal_base.tscn', CombatHudBase:'res://ui/base/combat_hud_base.tscn', ActivityShellBase:'res://ui/base/activity_shell_base.tscn'
  },
  screens:Object.fromEntries(screens.map(s=>[s.id,s.godot_scene])),
  components:Object.fromEntries(components.map(c=>[c.id,`res://ui/components/${c.id}.tscn`]))
},null,2)+'\n');

const screenCsv = [['id','category','profile','godot_scene','components','states','input','localization','assets','acceptance'],...screens.map(s=>[s.id,s.category,s.default_profile,s.godot_scene,s.components.join('|'),s.states.join('|'),s.input,s.localization,s.assets,s.acceptance])];
write('screen_inventory.csv', screenCsv.map(r=>r.map(csvCell).join(',')).join('\n')+'\n');

let compMd = `# UI Component Catalog v2\n\nThis is the canonical component contract. Screens compose these components; they must not redraw local one-off substitutes. All dimensions are internal 320×180 pixels.\n\n| ID / Godot node | Size | Required states | Content | Hard rule |\n|---|---|---|---|---|\n`;
for (const c of components) compMd += `| \`${c.id}\` / \`${c.node}\` | ${c.size} | ${c.states.join(', ')} | ${c.content} | ${c.rule} |\n`;
compMd += `\n## Skin contract\n\nEvery component receives \`PresentationProfile A|B|C|D\`; it may change border, polarity, stamp, portrait crop and permitted dither, but not focus order, semantic state, text, hit target or saved data. Profile A is the functional fallback for every component.\n\n## Nine-slice and pixel rules\n\n- Insets are integer values on the 4 px UI grid.\n- Texture filtering, font filtering and transform interpolation are disabled.\n- Focus moves instantly at the logical layer; the four-frame visual move never delays input.\n- Disabled state uses a strike/notch and label, never low-contrast gray.\n- All custom components expose \`state_description\` to screen readers / text-log mode.\n`;
write('component_catalog.md',compMd);

const cats = [...new Set(screens.map(s=>s.category))];
let screenMd = `# Complete UI Screen Inventory v2\n\n**${screens.length} screens** are specified below. Each one has a stable Godot scene path, default profile, composition, components, states, inputs, localization budget, asset dependencies and a blocking acceptance rule.\n\n| Category | Count |\n|---|---:|\n`;
for (const c of cats) screenMd += `| ${c} | ${screens.filter(s=>s.category===c).length} |\n`;
for (const cat of cats) {
  screenMd += `\n## ${cat.toUpperCase()}\n\n`;
  for (const s of screens.filter(x=>x.category===cat)) {
    screenMd += `### ${s.id}\n\n- Scene: \`${s.godot_scene}\`\n- Default profile: **${s.default_profile}**\n- Layout: ${s.layout}.\n- Components: ${s.components.map(x=>`\`${x}\``).join(', ')}.\n- States: ${s.states.join(', ')}.\n- Input: ${s.input}.\n- Localization budget: ${s.localization}.\n- Required art: ${s.assets}.\n- Acceptance: **${s.acceptance}.**\n\n`;
  }
}
write('screen_inventory.md',screenMd);

let acceptance = `# UI Acceptance Matrix\n\nA screen is not done when it merely resembles a mockup. It is done when its state, input, localization, profile and accessibility contracts pass.\n\n| Screen | State proof | Input proof | Localization proof | Profile proof | Blocking acceptance |\n|---|---|---|---|---|---|\n`;
for (const s of screens) acceptance += `| ${s.id} | capture ${s.states.length} states | keyboard + pad + remap | EN/JA overflow test | ${s.default_profile} + forced A | ${s.acceptance} |\n`;
acceptance += `\n## Global automated checks\n\n1. Scan exported textures: every visible pixel must be #000 or #fff.\n2. Reject non-integer Control positions, scale or camera zoom.\n3. Traverse focus graph from every entry node; no trap, no unreachable enabled target.\n4. Render pseudo-localized EN at +35% and JA at representative full-width count; flag crop/overlap.\n5. Compare every screen under forced A; gameplay state and available actions must match native profile.\n6. Capture 1×, 2×, 4×; reject filtering, uneven pixel widths and font smoothing.\n7. In combat focus mode, sample 16 px around each bullet/hazard; decor must not share its exact shape/frequency.\n`;
write('ui_acceptance_matrix.md',acceptance);

let backlog = `# UI Implementation Backlog for Codex\n\n## Definition of ready\n\nA task can start only when the referenced screen row, component definitions, assets and localized string keys exist. Placeholder copy is allowed; placeholder dimensions are not.\n\n`;
const phases = [
  ['P0 — Foundation',['tokens/theme resources','bitmap font import + EN/JA measure','input action/glyph service','focus router','base frame + list + action hint','palette/profile validator']],
  ['P1 — Core loop',['title','language_select','new_game_setup','save_load','world_map','destination_detail','exploration_hud','pause']],
  ['P2 — Narrative',['dialogue','dialogue_choice','backlog','chapter_card','spot_card','route_threshold','ending_card']],
  ['P3 — Journal',['journal_summary','journal_people','journal_places','journal_rumors','memory_thread','keepsakes','character_profile']],
  ['P4 — Combat',['danmaku_hud','spell_card_intro','danmaku_result','fighter_hud','fighter_result','training_pause']],
  ['P5 — Activities',['minigame_shell','photo_camera','trade_shop','clinic','activity_result']],
  ['P6 — System & polish',['options','accessibility','content_notice','profile_select','credits','full EN/JA + forced A + reduced motion QA']]
];
for (const [title,items] of phases) { backlog += `## ${title}\n\n`; for (const item of items) backlog += `- [ ] ${item}\n`; backlog += '\n'; }
backlog += `## Per-screen completion gate\n\n- [ ] Scene uses catalog components only, or a reviewed new shared component.\n- [ ] Every declared state has a deterministic fixture/screenshot.\n- [ ] Keyboard, controller, remapping and cancel path pass.\n- [ ] EN and JA budgets pass with pseudo-localization.\n- [ ] Native profile and forced A pass at 1×.\n- [ ] Reduced motion and photosensitivity settings pass.\n- [ ] No story/gameplay variable is stored in the UI node.\n`;
write('ui_implementation_backlog.md',backlog);

const stateMachine = `# UI Navigation and State Ownership\n\n\`GameState\` owns story, relationship, location, battle and save data. \`UiCoordinator\` receives read-only view models and emits semantic actions. A skin is never allowed to decide outcomes.\n\n\`BOOT -> LANGUAGE? -> NOTICE? -> TITLE -> NEW|LOAD -> WORLD_MAP <-> EXPLORATION\`\n\nFrom WORLD_MAP or EXPLORATION, PAUSE may open OPTIONS, ACCESSIBILITY, SAVE_LOAD or JOURNAL. Narrative events push SPOT_CARD -> DIALOGUE -> optional CHOICE -> optional ACTIVITY/COMBAT -> RESULT -> DIALOGUE -> WORLD/EXPLORATION. Route thresholds and endings are event nodes, not alternate save formats.\n\n## Stack rules\n\n1. Exactly one root screen owns navigation focus.\n2. Modal pushes preserve the prior focus ID and restore it on cancel/close.\n3. Toasts never take focus. World prompts take focus only after explicit confirm.\n4. Pause freezes offline simulation immediately; dialogue backlog pauses text advancement but not ambient art unless reduced-motion is on.\n5. Saving snapshots GameState before the saving mark appears; leaving is blocked until disk flush completes.\n6. Profile switches occur only between root scenes or at authored 6-frame transition markers.\n7. Journal reads immutable discovered-entry IDs; opening it cannot mutate route state.\n\n## Semantic signals\n\nEvery screen emits one of: \`ui_confirm(action_id, payload)\`, \`ui_cancel\`, \`ui_navigate(target_id)\`, \`ui_adjust(setting_id, value)\`, \`ui_help(context_id)\`, \`ui_pause_requested\`. Raw device events do not escape the UI layer.\n`;
write('navigation_state_ownership.md',stateMachine);

console.log(`Built ${screens.length} screen specs and ${components.length} shared components.`);
