class_name TeaTemperatureDefinition
extends MinigameDefinition
## Tea at the Right Silence declaration used by both host and tutorial UI.


func _init() -> void:
	minigame_id = &"mini.shrine.tea_temperature"
	title_key = &"ui.minigame.tea.title"
	objective_key = &"ui.minigame.tea.objective"
	estimated_duration_seconds = 45
	control_actions = [
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.FOCUS,
		GameInput.CONFIRM,
		GameInput.PAUSE,
	]
	assist_ids = [
		&"assist.minigame.slower_heat",
		&"assist.minigame.wider_band",
		&"assist.minigame.no_timer",
	]
