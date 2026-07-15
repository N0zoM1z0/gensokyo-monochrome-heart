# Controls and Input Map

## 1. Action vocabulary

| Action | Keyboard default | Controller default | Use |
|---|---:|---:|---|
| Move | Arrows / WASD | Left stick / D-pad | All movement modes |
| Confirm / Shot | Z / J / Enter | South face | Select, advance, focused shot |
| Cancel / Focus | X / K / Esc | East face | Back, slow movement, visible hitbox |
| Companion Skill | C / L | West face | Context traversal or assist |
| Bomb / Spell | V / I | North face | Danmaku bomb or fighter spell |
| Journal | Tab | View / Back | Journal quick open |
| Map | M | D-pad Up hold | Region/spot map |
| Page Left / Right | Q / E | LB / RB | Tabs, backlog, targets |
| Pause | Esc / P | Menu / Start | Pause |
| Accessibility Quick Menu | F1 or Q+E | LB+RB hold | Mode-safe accessibility controls |

All bindings are remappable. The game supports simultaneous keyboard/controller hot-swap.

## 2. Exploration

- walk; no run button required;
- ledge drop requires Down + Confirm;
- Observe uses Confirm when a prompt is present;
- companion skill is contextual and may be held for preview;
- interact prompts are magnetic within 4 px to reduce pixel-perfect positioning.

## 3. Danmaku

- unfocused movement: fast;
- Focus: slow, show hitbox and optional trajectory hints;
- Confirm: shot;
- Bomb: screen-clear/character spell;
- Companion Skill: story encounter mechanic, never required in pure challenge mode;
- tap Focus while paused to open bullet-contrast settings.

## 4. Fighter

- horizontal movement, jump, crouch;
- Light / Heavy / Spell / Skill;
- simple input mode maps quarter-circles to direction + Skill;
- advanced mode accepts motion inputs but gives no damage advantage;
- story mode supports auto-guard and one-button specials.

## 5. One-handed presets

### Left hand
WASD movement; Space confirm/shot; Shift focus/cancel; Q skill; E bomb.

### Right hand
Arrows movement; Numpad 0 confirm; Right Shift focus; Numpad 1 skill; Numpad 2 bomb.

Dialogue can be completed with Confirm and Cancel only.

## 6. Input buffering

- dialogue confirm buffer: 120 ms after panel animation;
- exploration coyote time: 80 ms where relevant;
- fighter attack buffer: 5 frames;
- danmaku bomb buffer on hit: configurable 0–8 frames;
- menus reject repeated directional input for 160 ms, then repeat at 75 ms.
