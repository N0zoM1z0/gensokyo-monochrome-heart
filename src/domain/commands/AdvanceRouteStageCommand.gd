class_name AdvanceRouteStageCommand
extends GameCommand
## Moves one character's authored route checkpoint forward without allowing regressions.

var character_id: StringName
var target_stage: int


func _init(p_character_id: StringName, p_target_stage: int) -> void:
	super(&"state.advance_route_stage")
	character_id = p_character_id
	target_stage = p_target_stage
