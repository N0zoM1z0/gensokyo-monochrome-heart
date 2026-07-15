class_name ModeContext
extends RefCounted
## Typed mechanical handoff created from an authored event node.

var mode_type: StringName
var mode_id: StringName
var event_id: StringName
var node_id: StringName
var target_band: StringName
var cups: int = 0
var deterministic_seed: int = 1
var is_replay: bool = false
