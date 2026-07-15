# M10 Screen-reader Feasibility Note

Status: feasible for menus, Journal, and dialogue; not implemented or claimed as supported in the current vertical slice.

## Engine capability

Godot 4.7 exposes assistive-technology metadata directly on `Control`: localized accessibility names and descriptions, labelled/described/flow relationships, live-region behavior, and an accessibility-only focus mode. `Container` can also expose named landmark regions. These are the appropriate native bridge; generated speech alone would not be equivalent to screen-reader support.

Primary references:

- [Godot 4.7 `Control` accessibility properties](https://docs.godotengine.org/en/4.7/classes/class_control.html#class-control-property-accessibility-name)
- [Godot 4.7 accessibility-only focus mode](https://docs.godotengine.org/en/4.7/classes/class_control.html#enum-control-focusmode)
- [Godot 4.7 `Container` accessibility regions](https://docs.godotengine.org/en/4.7/classes/class_container.html#class-container-property-accessibility-region)

## Project gap analysis

The project already has stable semantic input actions, deterministic focus IDs, localized string keys, and discrete `Control` nodes for system-menu rows. Those are strong foundations.

The present UI is nevertheless visually custom-drawn:

- `ListRow` controls do not yet expose localized accessibility names, current values, focus mode, or an accessible activation contract.
- Title, options, profile, pause, and accessibility screens draw headings and context without named landmark regions.
- Dialogue, Journal, exploration, minigame, danmaku, and fighter status are mostly drawn by one root `Control`; their visible text has no parallel semantic node tree.
- Typewriter text must not publish a live-region update per glyph.
- Spatial combat cannot be made fully understandable by merely reading the HUD. A nonvisual alternative or substantially simplified interaction model would be separate product scope.

Therefore the current build must not advertise screen-reader compatibility.

## Recommended implementation slices

1. System UI pilot
   - Assign localized `accessibility_name` and `accessibility_description` to every `ListRow`.
   - Include the current option value and whether an item is disabled.
   - Expose screen title and page position as named regions.
   - Map accessible activation to the same semantic command used by keyboard/controller input.

2. Narrative pilot
   - Represent speaker, completed dialogue line, four tone choices, Journal title/body, and reward summary with semantic controls.
   - Publish one polite live-region update only after a line becomes complete or instant text is shown.
   - Keep backlog order identical to accepted dialogue order and announce replay as read-only.

3. Gameplay feasibility prototype
   - Expose objective, interaction target, assist state, phase/result, vitality, and retry/accept-loss actions.
   - Test whether Story assists plus explicit audio/verbal cues make Tea Temperature viable.
   - Treat exploration, danmaku, and the fighter as requiring alternative navigation/combat design unless blind-player testing demonstrates otherwise.

4. Platform validation
   - Windows: NVDA with keyboard-only navigation.
   - Linux: Orca on the supported desktop stack.
   - macOS/VoiceOver only if macOS becomes a supported release target.
   - Test EN and JA, locale switching, 100/125/150% UI, controller handoff, pause, save/load, and replay.

## Acceptance for a future support claim

- Every interactive system-UI element has a correct localized name, role/behavior, value, state, and deterministic reading order.
- Focus and accessible focus never diverge or become trapped.
- Dynamic announcements are bounded, do not repeat per frame/glyph, and do not hide critical state.
- All nonvisual actions call the same commands and preserve save/replay determinism.
- At least two blind or screen-reader-dependent players complete the claimed flows on each supported platform.
- Known unsupported gameplay is stated precisely in the store page and in-game accessibility documentation.

Until those conditions pass, the shipped accessibility menu should describe the implemented visual, motion, timing, input, and assist features without using “screen-reader supported.”
