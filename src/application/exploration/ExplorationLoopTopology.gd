class_name ExplorationLoopTopology
extends RefCounted
## Optional traversal policy used by spots whose exits reconnect authored space.


func observe_anchor(_target_id: StringName) -> bool:
	return false


func cross_exit() -> ExplorationLoopTransition:
	return ExplorationLoopTransition.new()


func current_iteration() -> int:
	return 0


func total_iterations() -> int:
	return 0


func primed_for_exit() -> bool:
	return false


func expected_anchor_id() -> StringName:
	return &""


func crossing_count() -> int:
	return 0
