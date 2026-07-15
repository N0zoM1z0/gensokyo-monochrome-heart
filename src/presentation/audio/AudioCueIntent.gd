class_name AudioCueIntent
extends RefCounted
## Generic original procedural sound plus its subtitle-safe visual equivalent.

var cue_id: StringName
var visual_key: StringName
var pitch_hz: float
var duration_seconds: float


func _init(
	p_cue_id: StringName = &"",
	p_visual_key: StringName = &"",
	p_pitch_hz: float = 220.0,
	p_duration_seconds: float = 0.08
) -> void:
	cue_id = p_cue_id
	visual_key = p_visual_key
	pitch_hz = p_pitch_hz
	duration_seconds = p_duration_seconds
