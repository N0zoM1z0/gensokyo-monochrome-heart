class_name ExplorationObjectiveTracker
extends RefCounted
## Ordered objective state separated from generic interactions and presentation.

var objective_id: StringName
var required_sequence: Array[StringName] = []
var current_step: int = 0
var observed_ids: Array[StringName] = []


func configure(p_objective_id: StringName, sequence: Array[StringName]) -> void:
	objective_id = p_objective_id
	required_sequence = sequence.duplicate()
	current_step = 0
	observed_ids.clear()


func observe(target_id: StringName) -> ExplorationObjectiveProgress:
	var progress := ExplorationObjectiveProgress.new()
	progress.target_id = target_id
	progress.total_steps = required_sequence.size()
	if target_id not in observed_ids:
		observed_ids.append(target_id)
	if not is_complete() and required_sequence[current_step] == target_id:
		current_step += 1
		progress.accepted_step = true
		progress.completed_now = is_complete()
	progress.current_step = current_step
	return progress


func is_complete() -> bool:
	return not required_sequence.is_empty() and current_step >= required_sequence.size()


func next_target_id() -> StringName:
	return &"" if is_complete() or required_sequence.is_empty() else required_sequence[current_step]
