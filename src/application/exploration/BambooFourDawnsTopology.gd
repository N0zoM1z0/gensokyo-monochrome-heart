class_name BambooFourDawnsTopology
extends ExplorationLoopTopology
## Four fair corridor loops: remember one audiovisual anchor, then cross the seam.

const ANCHOR_SEQUENCE: Array[StringName] = [
	&"prop.ein.wind_chime",
	&"prop.ein.medicine_click",
	&"prop.ein.rabbit_knock",
	&"prop.ein.bird_call",
]

var _iteration: int = 0
var _primed_anchor_id: StringName
var _crossings: int = 0


func observe_anchor(target_id: StringName) -> bool:
	if _iteration >= ANCHOR_SEQUENCE.size() or target_id != ANCHOR_SEQUENCE[_iteration]:
		return false
	_primed_anchor_id = target_id
	return true


func cross_exit() -> ExplorationLoopTransition:
	_crossings += 1
	var transition := ExplorationLoopTransition.new()
	transition.iteration_before = _iteration
	transition.iteration_after = _iteration
	if _iteration >= ANCHOR_SEQUENCE.size() or _primed_anchor_id != ANCHOR_SEQUENCE[_iteration]:
		return transition
	transition.accepted_anchor_id = _primed_anchor_id
	transition.advanced = true
	_primed_anchor_id = &""
	_iteration += 1
	transition.iteration_after = _iteration
	transition.completed = _iteration >= ANCHOR_SEQUENCE.size()
	return transition


func current_iteration() -> int:
	return _iteration


func total_iterations() -> int:
	return ANCHOR_SEQUENCE.size()


func primed_for_exit() -> bool:
	return _iteration < ANCHOR_SEQUENCE.size() and _primed_anchor_id == ANCHOR_SEQUENCE[_iteration]


func expected_anchor_id() -> StringName:
	return ANCHOR_SEQUENCE[_iteration] if _iteration < ANCHOR_SEQUENCE.size() else &""


func crossing_count() -> int:
	return _crossings
