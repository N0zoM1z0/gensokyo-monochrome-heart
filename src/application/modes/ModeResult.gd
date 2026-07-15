class_name ModeResult
extends RefCounted
## Stable mechanical outcome returned to an event without mutating story state.

var result_tag: StringName
var performance_band: StringName
var outcome_tags: Array[StringName] = []
var used_assist: bool = false
var telemetry: ModeTelemetry


func _init(p_result_tag: StringName = &"") -> void:
	result_tag = p_result_tag
	performance_band = p_result_tag
