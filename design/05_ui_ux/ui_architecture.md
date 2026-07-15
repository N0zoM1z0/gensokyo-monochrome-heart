# UI Architecture

## 1. Goals

- Read instantly at 320 × 180.
- Preserve playfield visibility during danmaku and duels.
- Make relationship information legible without exposing numerical affection scores.
- Support English and Japanese without maintaining separate scene layouts.
- Use animation as state confirmation, never decoration that delays input.
- Remain fully operable by keyboard or controller; mouse is optional.

## 2. Visual grammar

### Binary palette

The base game uses pure black and white. No gray values are stored in final sprites. Apparent tone is created with:
- 25%, 50%, and 75% ordered dithers;
- line density;
- alternating animation frames;
- inverted panels;
- stipple reserved for fog, memory stains, and dream states.

### Meaning of inversion

- **White field / black ink:** ordinary reality, menus, calm dialogue.
- **Black field / white ink:** danger, private memory, night, route threshold.
- **Rapid inversion:** damage warning or boundary instability; never use for ordinary selection.

### Geometry

- 1 px rules at internal resolution.
- 3 px minimum interactive line weight.
- 4 px baseline grid.
- 8 px standard interior padding.
- 12 px small touch target at 320 × 180, expanded by input collision margins.
- Rounded corners are avoided; panels look cut, folded, or stamped.

## 3. Component tree

```text
UIRoot
├── SafeFrame
│   ├── HUDLayer
│   │   ├── TimeWeatherChip
│   │   ├── ObjectiveThread
│   │   ├── ContextPrompt
│   │   └── ModeHUD
│   ├── NarrativeLayer
│   │   ├── DialoguePanel
│   │   ├── ChoiceFan
│   │   ├── PortraitStage
│   │   └── MemoryCallback
│   ├── ModalLayer
│   │   ├── Journal
│   │   ├── InventoryKeepsakes
│   │   ├── Map
│   │   ├── Pause
│   │   └── AccessibilityQuickMenu
│   ├── ToastLayer
│   │   ├── RumorStamp
│   │   ├── KeepsakeTag
│   │   └── SaveIndicator
│   └── TransitionLayer
│       ├── PaperWipe
│       ├── BorderFold
│       └── IrisStamp
```

## 4. Reusable components

### `PaperPanel`
Properties: margins, fill inversion, edge style, optional title tab. It is the base for every modal.

### `StampIcon`
A 9 × 9 or 13 × 13 symbolic icon. It must remain recognizable without color. Examples: shrine bell, clock, camera, moon, petal, mask.

### `ThreadLine`
A dotted or knotted line representing unresolved causality. Used in map paths, Journal links, and objective tracking.

### `CharacterTag`
Name, faction mark, speaking direction, optional emotional texture. It never displays affection numerically.

### `ToneChoice`
Four consistent action verbs: Direct, Playful, Patient, Defiant. The line shown is the actual proposed intent, not a vague morality label.

### `ResonanceTell`
A nonnumeric change cue: a knot loosens, a cup moves closer, a photograph develops, a clock hand resumes. The player learns relationships through world state rather than meters.

## 5. Mode-specific HUD

### Exploration
- top left: location + time chip;
- top right: one-line objective thread;
- bottom center: context action;
- no permanent minimap;
- companion skill appears only when usable.

### Danmaku
- player focus marker and hitbox;
- life pips, bombs, Margin gauge;
- boss phase pips and spell title;
- optional safe-lane assist;
- dialogue banter never covers active bullet lanes.

### Fighter
- mirrored vitality bars;
- Temperament meter under each bar;
- round timer optional in story mode;
- move prompts only in training mode.

### Minigame
A bespoke 1-bit instrument panel but always retains:
- fail-safe pause;
- retry/assist hint after failure;
- clear progress unit;
- no hidden mandatory timing window.

## 6. Navigation contract

- Confirm advances; Cancel reverses or opens pause if no parent view exists.
- Holding Confirm accelerates text only after the current line has fully rendered once per profile.
- Every modal remembers last focus.
- Tab shoulder buttons switch Journal pages and map layers.
- The accessibility quick menu is reachable with one chord from every mode.
- No irreversible choice is accepted on the same press that opens a screen.

## 7. Animation budgets

- menu focus: 2–4 frames;
- panel open: 6 frames maximum;
- dialogue portrait entrance: 4 frames or instant setting;
- route-threshold flourish: 12 frames, skippable;
- save indicator: asynchronous, never blocks controls;
- flashing: below accessibility thresholds and replaceable with border pulse.

## 8. UI state ownership

The UI observes a typed `PresentationState`. It does not directly modify story flags. User actions emit commands to the owning system. This prevents dialogue, saves, and combat from becoming coupled to Control nodes.

```gdscript
signal command_requested(command: UICommand)
func present(state: PresentationState) -> void
```

Every screen must be testable from a fixture state without loading a world scene.
