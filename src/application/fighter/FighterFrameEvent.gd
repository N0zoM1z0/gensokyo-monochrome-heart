class_name FighterFrameEvent
extends RefCounted
## Audited move event evaluated by fixed-step logic, never by animation playback.

const TYPES := [
	&"hitbox_on",
	&"hitbox_off",
	&"projectile",
	&"root_motion",
	&"invulnerable_on",
	&"invulnerable_off",
]

var tick: int = 0
var type: StringName
var value: int = 0


func validation_errors(move_id: StringName, duration_ticks: int) -> Array[String]:
	var errors: Array[String] = []
	if tick < 0 or tick >= duration_ticks:
		errors.append("move %s frame event falls outside its duration" % move_id)
	if type not in TYPES:
		errors.append("move %s uses unsupported frame event %s" % [move_id, type])
	return errors
