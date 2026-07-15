class_name ExplorationInteractionRegistry
extends RefCounted
## Central interaction query with four-pixel magnetism; targets perform no frame polling.

const MAGNET_MARGIN := 4.0

var query_count: int = 0
var _interactables: Dictionary[StringName, ExplorationInteractable] = {}


func register(interactable: ExplorationInteractable) -> bool:
	if interactable == null or interactable.interactable_id == &"" or interactable.action == null:
		return false
	if _interactables.has(interactable.interactable_id):
		return false
	_interactables[interactable.interactable_id] = interactable
	return true


func nearest(
	origin: Vector2,
	facing: Vector2 = Vector2.RIGHT,
	maximum_probe_distance: float = 36.0
) -> ExplorationInteractable:
	query_count += 1
	var normalized_facing := facing.normalized() if not facing.is_zero_approx() else Vector2.RIGHT
	var best: ExplorationInteractable
	var best_score := INF
	for interactable: ExplorationInteractable in _interactables.values():
		var offset := interactable.world_position - origin
		var distance := offset.length()
		var reach := minf(maximum_probe_distance, interactable.interaction_radius + MAGNET_MARGIN)
		if distance > reach:
			continue
		var direction_alignment := normalized_facing.dot(offset.normalized()) if distance > 0.001 else 1.0
		if direction_alignment < -0.15:
			continue
		var score := distance - maxf(0.0, direction_alignment) * MAGNET_MARGIN
		if score < best_score:
			best = interactable
			best_score = score
	return best


func by_id(interactable_id: StringName) -> ExplorationInteractable:
	return _interactables.get(interactable_id)


func all() -> Array[ExplorationInteractable]:
	var records: Array[ExplorationInteractable] = []
	for interactable: ExplorationInteractable in _interactables.values():
		records.append(interactable)
	records.sort_custom(func(left: ExplorationInteractable, right: ExplorationInteractable) -> bool:
		return String(left.interactable_id) < String(right.interactable_id)
	)
	return records
