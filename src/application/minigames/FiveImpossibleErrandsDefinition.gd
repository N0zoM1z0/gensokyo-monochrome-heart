class_name FiveImpossibleErrandsDefinition
extends MinigameDefinition
## Shared-host declaration for Kaguya's five modular negotiation trials.


func _init() -> void:
	minigame_id = &"mini.ein.five_impossible_errands"
	title_key = &"ui.minigame.errands.title"
	objective_key = &"ui.minigame.errands.objective"
	estimated_duration_seconds = 45
	control_actions = [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.PAUSE]
	assist_ids = []
