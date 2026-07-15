# UI Navigation and State Ownership

`GameState` owns story, relationship, location, battle and save data. `UiCoordinator` receives read-only view models and emits semantic actions. A skin is never allowed to decide outcomes.

`BOOT -> LANGUAGE? -> NOTICE? -> TITLE -> NEW|LOAD -> WORLD_MAP <-> EXPLORATION`

From WORLD_MAP or EXPLORATION, PAUSE may open OPTIONS, ACCESSIBILITY, SAVE_LOAD or JOURNAL. Narrative events push SPOT_CARD -> DIALOGUE -> optional CHOICE -> optional ACTIVITY/COMBAT -> RESULT -> DIALOGUE -> WORLD/EXPLORATION. Route thresholds and endings are event nodes, not alternate save formats.

## Stack rules

1. Exactly one root screen owns navigation focus.
2. Modal pushes preserve the prior focus ID and restore it on cancel/close.
3. Toasts never take focus. World prompts take focus only after explicit confirm.
4. Pause freezes offline simulation immediately; dialogue backlog pauses text advancement but not ambient art unless reduced-motion is on.
5. Saving snapshots GameState before the saving mark appears; leaving is blocked until disk flush completes.
6. Profile switches occur only between root scenes or at authored 6-frame transition markers.
7. Journal reads immutable discovered-entry IDs; opening it cannot mutate route state.

## Semantic signals

Every screen emits one of: `ui_confirm(action_id, payload)`, `ui_cancel`, `ui_navigate(target_id)`, `ui_adjust(setting_id, value)`, `ui_help(context_id)`, `ui_pause_requested`. Raw device events do not escape the UI layer.
