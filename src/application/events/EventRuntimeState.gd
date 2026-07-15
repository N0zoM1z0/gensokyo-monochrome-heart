class_name EventRuntimeState
extends RefCounted
## Ephemeral interpreter bookkeeping; durable position remains in GameState.

var event_id: StringName
var node_id: StringName
var waiting_for: StringName
var total_steps: int = 0
var deterministic_seed: int = 1
var is_replay: bool = false
var attempt_counts: Dictionary[StringName, int] = {}
var choices: Array[EventChoiceLogRecord] = []
var last_command_ids: Array[StringName] = []
