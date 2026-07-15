class_name ExplorationHintTimer
extends RefCounted
## Configurable Story navigation hint timer, reset by meaningful progress.

var delay_seconds: float = 8.0
var story_hints_enabled: bool = false
var elapsed_seconds: float = 0.0
var has_shown: bool = false


func tick(delta: float) -> bool:
	if not story_hints_enabled or has_shown:
		return false
	elapsed_seconds += maxf(0.0, delta)
	if elapsed_seconds < delay_seconds:
		return false
	has_shown = true
	return true


func reset_after_progress() -> void:
	elapsed_seconds = 0.0
	has_shown = false
