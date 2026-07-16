class_name HalfPhantomBalanceDefinition
extends MinigameDefinition
## A calm paired-body crossing where Youmu and her phantom are separately controllable.


func _init() -> void:
	minigame_id = &"mini.hgy.half_phantom_balance"
	title_key = &"ui.minigame.half_phantom.title"
	objective_key = &"ui.minigame.half_phantom.objective"
	estimated_duration_seconds = 45
	control_actions = [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.PAUSE]
	assist_ids = [&"assist.minigame.slower_pace"]
