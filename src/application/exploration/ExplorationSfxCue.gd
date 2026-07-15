class_name ExplorationSfxCue
extends AudioCueIntent
## Audio intent with a parallel visual key for subtitle-safe exploration feedback.

func _init(
	p_cue_id: StringName = &"",
	p_visual_key: StringName = &"",
	p_pitch_hz: float = 220.0,
	p_duration_seconds: float = 0.08
) -> void:
	super._init(p_cue_id, p_visual_key, p_pitch_hz, p_duration_seconds)
