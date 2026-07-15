class_name ExplorationModeContext
extends ModeContext
## Typed setup for one side-view spot; event identity remains data owned by triggers.

var location_id: StringName
var spot_id: StringName
var time_slot: StringName = &"day"
var objective_id: StringName
var companion_id: StringName
var story_navigation_hints: bool = false
var companion_skill_enabled: bool = true


func _init() -> void:
	mode_type = &"exploration"
