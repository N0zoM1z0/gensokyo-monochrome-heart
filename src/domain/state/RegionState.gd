class_name RegionState
extends RefCounted
## Persistent location discovery and transformation state.

var region_id: StringName
var condition_id: StringName = &"region.normal"
var visit_count: int = 0
var last_visited_day: int = 0
var discovered_spot_ids: Array[StringName] = []


func _init(p_region_id: StringName = &"") -> void:
	region_id = p_region_id


func duplicate_state() -> RegionState:
	var copy := RegionState.new(region_id)
	copy.condition_id = condition_id
	copy.visit_count = visit_count
	copy.last_visited_day = last_visited_day
	copy.discovered_spot_ids = discovered_spot_ids.duplicate()
	return copy
