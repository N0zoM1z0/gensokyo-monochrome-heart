class_name GameStateCodecResult
extends RefCounted
## Typed parse result with aggregated schema and invariant diagnostics.

var state: GameState
var errors: Array[String] = []


func is_success() -> bool:
	return state != null and errors.is_empty()
