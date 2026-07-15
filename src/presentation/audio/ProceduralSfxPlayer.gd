class_name ProceduralSfxPlayer
extends AudioStreamPlayer
## Lightweight original placeholder tones with subtitle-safe visual cue identities.

signal cue_played(cue_id: StringName, visual_key: StringName)

const MIX_RATE := 22050

var last_cue_id: StringName
var last_visual_key: StringName
var _waves: Dictionary[StringName, AudioStreamWAV] = {}


func play_cue(cue: AudioCueIntent) -> void:
	if cue == null:
		return
	last_cue_id = cue.cue_id
	last_visual_key = cue.visual_key
	# Headless and Dummy-audio validation have no listener or mix callback.
	# Preserve the cue contract without allocating playback that cannot drain.
	if DisplayServer.get_name() == "headless" or AudioServer.get_driver_name() == "Dummy":
		cue_played.emit(cue.cue_id, cue.visual_key)
		return
	if not _waves.has(cue.cue_id):
		_waves[cue.cue_id] = _build_wave(cue)
	stop()
	stream = _waves[cue.cue_id]
	play()
	cue_played.emit(cue.cue_id, cue.visual_key)


func _exit_tree() -> void:
	stop()
	stream = null
	_waves.clear()


func _build_wave(cue: AudioCueIntent) -> AudioStreamWAV:
	var frame_count := ceili(cue.duration_seconds * MIX_RATE)
	var phase_step := TAU * cue.pitch_hz / float(MIX_RATE)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for index: int in range(frame_count):
		var envelope := 1.0 - float(index) / maxf(1.0, frame_count)
		var sample := sin(index * phase_step) * envelope * 0.14
		data.encode_s16(index * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = MIX_RATE
	wave.stereo = false
	wave.data = data
	return wave
