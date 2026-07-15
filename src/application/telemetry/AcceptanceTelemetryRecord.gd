class_name AcceptanceTelemetryRecord
extends RefCounted
## One locale-free, non-identifying vertical-slice acceptance observation.

var sequence: int = 0
var kind: StringName
var phase_id: StringName
var result_tag: StringName
var elapsed_ms: int = 0
var attempt_count: int = 0
var is_replay: bool = false


func to_data() -> Dictionary:
	return {
		"attempt_count": attempt_count,
		"elapsed_ms": elapsed_ms,
		"is_replay": is_replay,
		"kind": String(kind),
		"phase_id": String(phase_id),
		"result_tag": String(result_tag),
		"sequence": sequence,
	}
