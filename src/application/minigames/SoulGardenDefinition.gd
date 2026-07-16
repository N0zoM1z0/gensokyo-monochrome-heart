class_name SoulGardenDefinition
extends MinigameDefinition
## Shared-host declaration for matching and releasing three memorial spirits.


func _init() -> void:
	minigame_id = &"mini.hgy.soul_garden"
	title_key = &"ui.minigame.soul_garden.title"
	objective_key = &"ui.minigame.soul_garden.objective"
	estimated_duration_seconds = 45
	control_actions = [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.PAUSE]
	assist_ids = [&"assist.minigame.slower_pace"]
