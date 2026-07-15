class_name ContentStageResult
extends RefCounted
## Aggregate counters for one deterministic content load stage.

var id: StringName
var checks: int = 0
var errors: int = 0
var warnings: int = 0


func _init(p_id: StringName) -> void:
	id = p_id
