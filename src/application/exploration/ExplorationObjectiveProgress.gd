class_name ExplorationObjectiveProgress
extends RefCounted
## Result of one observation against an authored ordered objective.

var target_id: StringName
var accepted_step: bool = false
var completed_now: bool = false
var current_step: int = 0
var total_steps: int = 0
