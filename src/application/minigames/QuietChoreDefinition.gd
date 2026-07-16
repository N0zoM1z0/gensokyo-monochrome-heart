class_name QuietChoreDefinition
extends MinigameDefinition
## Shared-host declaration for Reimu's sweep, mend, and sit routine.


func _init() -> void:
	minigame_id = &"mini.hkr.quiet_chore"
	title_key = &"ui.minigame.quiet_chore.title"
	objective_key = &"ui.minigame.quiet_chore.objective"
	estimated_duration_seconds = 30
	control_actions = [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.PAUSE]
	assist_ids = [&"assist.minigame.slower_pace"]
