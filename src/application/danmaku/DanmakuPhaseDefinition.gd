class_name DanmakuPhaseDefinition
extends RefCounted
## One checkpointable teaching/transformation/punchline section of a pattern.

var id: StringName
var title_key: StringName
var duration_ticks: int = 360
var boss_integrity: int = 180
var teaching_ticks: int = 90
var transform_tick: int = 180
var safe_lane: int = -1
var emitters: Array[DanmakuEmitterDefinition] = []


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not String(id).begins_with("phase."):
		errors.append("danmaku phase ID must begin with phase.: %s" % id)
	if title_key == &"":
		errors.append("danmaku phase requires a localized title key: %s" % id)
	if duration_ticks < 60 or boss_integrity <= 0:
		errors.append("danmaku phase duration/integrity is invalid: %s" % id)
	if teaching_ticks < 1 or teaching_ticks >= duration_ticks:
		errors.append("danmaku teaching phrase must fit inside its phase: %s" % id)
	if transform_tick <= teaching_ticks or transform_tick >= duration_ticks:
		errors.append("danmaku transformation must follow teaching and precede the end: %s" % id)
	if emitters.is_empty():
		errors.append("danmaku phase has no emitters: %s" % id)
	for emitter: DanmakuEmitterDefinition in emitters:
		for error: String in emitter.validation_errors():
			errors.append("%s: %s" % [id, error])
	return errors
