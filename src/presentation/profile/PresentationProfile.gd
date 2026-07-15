class_name PresentationProfile
extends Resource
## Immutable visual policy. Profiles never own commands, state transitions, or outcomes.

@export var profile_id: StringName = &"A"
@export var display_name: String = "Pocket Shrine"
@export var polarity: StringName = &"paper"
@export var black_budget: String = "25-35%"
@export var frame_style: StringName = &"open_corner_2px"
@export var usage: String = "default/exploration/system"
@export var is_inverted: bool = false
@export var ink: Color = Color.BLACK
@export var paper: Color = Color.WHITE


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if profile_id not in [&"A", &"B", &"C", &"D"]:
		errors.append("unsupported profile_id: %s" % profile_id)
	if display_name.is_empty():
		errors.append("display_name is empty")
	if polarity not in [&"paper", &"flexible", &"ink"]:
		errors.append("unsupported polarity: %s" % polarity)
	if black_budget.is_empty() or frame_style == &"" or usage.is_empty():
		errors.append("profile visual contract is incomplete")
	if ink != Color.BLACK or paper != Color.WHITE:
		errors.append("profile palette must remain strict black and white")
	return errors
