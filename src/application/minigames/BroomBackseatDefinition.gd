class_name BroomBackseatDefinition
extends MinigameDefinition
## Shared cargo-balance tutorial for Marisa's Forest of Magic route.


func _init() -> void:
	minigame_id = &"mini.mrs.broom_backseat"
	title_key = &"ui.minigame.broom_backseat.title"
	objective_key = &"ui.minigame.broom_backseat.objective"
	estimated_duration_seconds = 30
	control_actions = [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.PAUSE]
	assist_ids = [&"assist.minigame.wider_timing"]
