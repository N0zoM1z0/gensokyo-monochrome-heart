class_name MinigameDefinition
extends RefCounted
## Shared declaration every hosted minigame provides before accepting input.

var minigame_id: StringName
var title_key: StringName
var objective_key: StringName
var estimated_duration_seconds: int = 45
var control_actions: Array[StringName] = []
var assist_ids: Array[StringName] = []


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not String(minigame_id).begins_with("mini."):
		errors.append("minigame ID must begin with mini.: %s" % minigame_id)
	if title_key == &"" or objective_key == &"":
		errors.append("minigame requires localized title and objective keys")
	if estimated_duration_seconds < 30 or estimated_duration_seconds > 60:
		errors.append("minigame estimate must remain within 30..60 seconds")
	if GameInput.CONFIRM not in control_actions or GameInput.PAUSE not in control_actions:
		errors.append("minigame controls require Confirm and Pause")
	return errors
