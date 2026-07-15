class_name TimeGridServiceDefinition
extends MinigameDefinition
## Data-neutral declaration for the deterministic stopped-time service grid.


func _init() -> void:
	minigame_id = &"mini.sdm.time_grid_service"
	title_key = &"ui.minigame.time_grid.title"
	objective_key = &"ui.minigame.time_grid.objective"
	estimated_duration_seconds = 45
	control_actions = [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.FOCUS, GameInput.CONFIRM, GameInput.PAUSE]
	assist_ids = [&"assist.minigame.slower_pace", &"assist.minigame.wider_timing", &"assist.minigame.no_timer"]
