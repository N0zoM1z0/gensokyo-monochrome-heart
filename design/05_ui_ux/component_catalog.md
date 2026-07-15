# UI Component Catalog v2

This is the canonical component contract. Screens compose these components; they must not redraw local one-off substitutes. All dimensions are internal 320×180 pixels.

| ID / Godot node | Size | Required states | Content | Hard rule |
|---|---|---|---|---|
| `frame` / `PanelFrame` | variable, min 24x16 | idle, focused, disabled, urgent | A open-corner; B double; C fold; D white line | 9-slice with integer margins |
| `top_ribbon` / `TopRibbon` | 312x16 | normal, incident, combat | time, weather, location, thread state | never more than 40 Latin cells |
| `region_stamp` / `RegionStamp` | 12x12 / 16x16 | locked, known, active, changed | unique 1-bit mark per region | must pass at 12x12 |
| `tab` / `Tab` | 48x14 min | idle, focused, selected, disabled, new | label + optional 6x6 badge | selected uses lower-edge merge |
| `list_row` / `ListRow` | variable x 16 | idle, focused, selected, disabled, changed | icon, label, status tail | one row = one focus target |
| `focus_marker` / `FocusMarker` | variable | keyboard, pad, pointer | leading > + 2px inset corners | 4-frame move, no tween blur |
| `action_hint` / `ActionHint` | min 36x12 | available, held, blocked, alternate | device glyph + verb | verb remains visible without glyph |
| `prompt_chip` / `PromptChip` | min 20x12 | observe, talk, use, carry, danger | 12x12 shape + 8px text | world anchored, clamped to safe area |
| `dialogue_panel` / `DialoguePanel` | 312x64 standard | idle, typing, await, auto, history | name, body, continue mark, voice state | 3 EN lines or 4 JA lines |
| `nameplate` / `Nameplate` | min 48x12 | speaker, aside, narrator, unknown | localized name + speaking notch | never baked into portrait |
| `portrait_window` / `PortraitWindow` | 88x120 / 80x104 | normal, crop, occluded, absent | separate portrait and frame layers | may break C frame by max 8px |
| `choice_card` / `ChoiceCard` | 296x18 min | idle, focused, committed, locked, changed | stance stamp + 1-2 lines | stack gap 2px; no timeout by default |
| `stance_stamp` / `StanceStamp` | 12x12 | direct, playful, patient, defiant, context | shape + text label | relationship meaning is never color-coded |
| `toast` / `Toast` | max 216x24 | info, item, rumor, error | icon, 1-2 lines, optional action | queues; never covers choices or hitbox |
| `scrollbar` / `PixelScrollbar` | 6x variable | idle, focused, drag, at_start, at_end | track, 4px min thumb, arrow ends | page actions work without dragging |
| `meter` / `Meter` | variable x 8 | normal, gain, loss, locked, unknown | outline, fill, delayed change notch | also exposes numeric/text alternative |
| `pip_row` / `PipRow` | 8px pitch | full, empty, used, charged, locked | shape differs by semantic | max 12 before grouping |
| `reticle` / `FocusReticle` | 16x16 / 24x24 | free, target, locked, danger | four corners + center point | no smooth scaling |
| `spell_banner` / `SpellBanner` | 312x24 | intro, active, timeout, cleared, failed | owner, card title, bonus state | skippable after first view |
| `combat_timer` / `CombatTimer` | 40x12 | normal, low, paused, sudden | digits + border cadence | low state adds !, not flash |
| `save_slot` / `SaveSlot` | 296x36 | empty, valid, focused, overwrite, corrupt | thumbnail 64x32, chapter, place, time | corrupt slot remains exportable |
| `map_node` / `MapNode` | 12x12 / 16x16 | unknown, known, available, active, changed, locked | region stamp + link anchor | link line never crosses its label |
| `thread_node` / `ThreadNode` | 12x12 | observed, contradicted, changed, resolved, route | shape + connecting line style | status remains textual in detail pane |
| `tooltip` / `Tooltip` | max 152x48 | info, help, error | title + 1-4 short lines | opens after 350ms or help action |
| `modal` / `Modal` | 272x80 min | question, warning, destructive, progress | title, body, actions | default action cannot be destructive |
| `toggle` / `PixelToggle` | 28x12 | off, on, focused, disabled, mixed | text label + two-position marker | does not rely on black/white polarity |
| `slider` / `PixelSlider` | 96x12 | focused, drag, disabled | ticks + value text | step actions and reset available |
| `page_indicator` / `PageIndicator` | 48x10 | normal, last, unread | current/total + optional unread notch | placed consistently at bottom right |
| `relation_seal` / `RelationSeal` | 32x32 | quiet, open, strained, threshold, complete | character motif + qualitative word | no affection number in narrative UI |
| `loading_mark` / `LoadingMark` | 16x16 | loading, saving, complete, error | 4-frame rotating gohei corners | saving text remains until flush completes |

## Skin contract

Every component receives `PresentationProfile A|B|C|D`; it may change border, polarity, stamp, portrait crop and permitted dither, but not focus order, semantic state, text, hit target or saved data. Profile A is the functional fallback for every component.

## Nine-slice and pixel rules

- Insets are integer values on the 4 px UI grid.
- Texture filtering, font filtering and transform interpolation are disabled.
- Focus moves instantly at the logical layer; the four-frame visual move never delays input.
- Disabled state uses a strike/notch and label, never low-contrast gray.
- All custom components expose `state_description` to screen readers / text-log mode.
