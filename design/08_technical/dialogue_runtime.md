# Dialogue and Event Runtime

## 1. Separation of concerns

- **EventInterpreter** owns graph position and waits for results.
- **DialoguePresenter** renders beats and choices.
- **GameStateRules** applies validated effects.
- **LocalizationService** returns display strings.
- **Character skills** guide authoring and offline generation; they are not parsed as runtime behavior code.

## 2. Interpreter state

```gdscript
class_name EventRuntimeState
extends RefCounted

var event_id: StringName
var node_id: StringName
var locals: Dictionary[StringName, Variant]
var call_stack: Array[StringName]
var waiting_for: StringName
var attempt_counts: Dictionary[StringName, int]
var deterministic_seed: int
```

Interpreter execution is step-limited to prevent accidental infinite loops. A node may return:
- `CONTINUE`;
- `WAIT_INPUT`;
- `WAIT_MODE`;
- `WAIT_TIMER`;
- `END`;
- `ERROR`.

## 3. Choice resolution

1. Evaluate visibility predicates.
2. Evaluate availability predicates.
3. Present visible options; unavailable options may show an in-world reason.
4. Confirm selection.
5. Log choice ID, not localized text.
6. Apply effects transactionally.
7. Advance to target node.
8. Emit optional resonance presentation cues.

A transaction either applies all effects or none. Save checkpoints occur after a committed node, never halfway through a state change.

## 4. Relationship application

Effects pass through clamped Domain rules. Rules can add contextual modifiers, but they may not silently reverse a choice. Example: a Playful choice at high Strain may increase Spark and Strain together.

## 5. Mechanical transitions

`start_minigame`, `start_danmaku`, and `start_duel` nodes:
- create a typed `ModeContext` from event data;
- request a checkpoint;
- suspend interpreter;
- ask `SceneRouter` to load mode;
- receive `ModeResult`;
- map result tags to authored branches;
- unload mode and resume event.

## 6. Backlog and replay

The backlog stores presentation records:
- locale key and formatted arguments;
- speaker display key;
- nonverbal cue key;
- timestamp / event node;
- no hidden state deltas.

Journal replay launches a read-only event instance with choices fixed to the completed path unless “Explore Alternate Tone” is explicitly unlocked. Replay cannot mutate the main save.

## 7. Offline character-agent workflow

The authoring tool may call an LLM/agent using a character `skills.md`. Shipped builds do not require network generation.

Workflow:
1. Event writer creates objective and state packet.
2. Agent proposes one or more beats in `agent_schema.json`.
3. Validator checks schema and guardrails.
4. Human editor checks canon, EN, JA, humor, boundaries, and route pacing.
5. Accepted text receives stable localization keys.
6. Source and review provenance are recorded.

No generated draft enters the game automatically.

## 8. Debugging

Developer overlay shows:
- event/node ID;
- active predicates and their results;
- relationship semantic bands;
- last five commands;
- RNG seed;
- pending save checkpoint;
- localization key;
- content origin tags (Canon/Fanon/Original).

A “copy minimal reproduction” command writes state plus event fixture without personal machine paths.
