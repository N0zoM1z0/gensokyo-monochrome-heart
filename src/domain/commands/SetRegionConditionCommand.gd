class_name SetRegionConditionCommand
extends GameCommand
## Applies one visible, persistent world-state condition to a known region.

var region_id: StringName
var condition_id: StringName


func _init(p_region_id: StringName, p_condition_id: StringName) -> void:
	super(&"state.set_region_condition")
	region_id = p_region_id
	condition_id = p_condition_id
