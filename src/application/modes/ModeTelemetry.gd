class_name ModeTelemetry
extends RefCounted
## Locale-free replay evidence returned by a mechanical mode.

var deterministic_seed: int = 1
var elapsed_ticks: int = 0
var attempt_count: int = 1
var final_state_hash: String


func duplicate_telemetry() -> ModeTelemetry:
	var copy := ModeTelemetry.new()
	copy.deterministic_seed = deterministic_seed
	copy.elapsed_ticks = elapsed_ticks
	copy.attempt_count = attempt_count
	copy.final_state_hash = final_state_hash
	return copy
