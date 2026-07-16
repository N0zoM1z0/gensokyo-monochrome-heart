class_name AdaptiveTestTonePlayer
extends AudioStreamPlayer
## Original generated tones with deterministic, bar-boundary state changes.

signal music_state_changed(state_id: StringName)

const MIX_RATE := 22050
const BAR_SECONDS := 2.0
const SILENT_DB := -80.0
const STATE_PITCHES := {
	&"mus_shrine_day": 196.00,
	&"mus_border_crossing": 233.08,
	&"mus_shrine_duel": 293.66,
	&"mus_reimu_private": 174.61,
	&"mus_sdm_foyer": 164.81,
	&"mus_sakuya_kitchen": 246.94,
	&"mus_sakuya_clock": 277.18,
	&"mus_patchouli_route": 185.00,
	&"mus_remilia_route": 207.65,
}

var current_state_id: StringName
var queued_state_id: StringName
var bar_elapsed_seconds: float = 0.0
var transition_count: int = 0
var is_muted: bool = false
var is_dialogue_ducked: bool = false

var _streams: Dictionary[StringName, AudioStreamWAV] = {}


func _ready() -> void:
	_update_volume()
	set_process(true)


func _process(delta: float) -> void:
	_advance(maxf(0.0, delta))


func request_state(state_id: StringName) -> bool:
	if not STATE_PITCHES.has(state_id):
		return false
	if current_state_id == &"":
		_apply_state(state_id)
	elif state_id == current_state_id:
		queued_state_id = &""
	else:
		queued_state_id = state_id
	return true


func set_music_muted(enabled: bool) -> void:
	is_muted = enabled
	_update_volume()


func set_dialogue_ducked(enabled: bool) -> void:
	is_dialogue_ducked = enabled
	_update_volume()


func _update_volume() -> void:
	volume_db = SILENT_DB if is_muted else AudioMixPolicy.music_gain_db(is_dialogue_ducked)


func stop_music() -> void:
	stop()
	stream = null
	current_state_id = &""
	queued_state_id = &""
	bar_elapsed_seconds = 0.0


func advance_for_test(delta: float) -> void:
	_advance(maxf(0.0, delta))


func _advance(delta: float) -> void:
	if current_state_id == &"":
		return
	bar_elapsed_seconds += delta
	while bar_elapsed_seconds >= BAR_SECONDS:
		bar_elapsed_seconds -= BAR_SECONDS
		if queued_state_id != &"":
			var next_state := queued_state_id
			queued_state_id = &""
			_apply_state(next_state)
			break


func _apply_state(state_id: StringName) -> void:
	current_state_id = state_id
	bar_elapsed_seconds = 0.0
	transition_count += 1
	if DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy":
		if not _streams.has(state_id):
			_streams[state_id] = _build_loop(float(STATE_PITCHES[state_id]))
		stop()
		stream = _streams[state_id]
		play()
	music_state_changed.emit(state_id)


func _build_loop(pitch_hz: float) -> AudioStreamWAV:
	var frame_count := roundi(BAR_SECONDS * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var fundamental_step := TAU * pitch_hz / float(MIX_RATE)
	var harmonic_step := fundamental_step * 1.5
	for index: int in range(frame_count):
		var beat_phase := fmod(float(index) / MIX_RATE, 0.5) / 0.5
		var pulse := 0.55 + 0.45 * (1.0 - beat_phase)
		var sample := (
			sin(index * fundamental_step) * 0.055
			+ sin(index * harmonic_step) * 0.018
		) * pulse
		data.encode_s16(index * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = MIX_RATE
	wave.stereo = false
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_begin = 0
	wave.loop_end = frame_count
	wave.data = data
	return wave


func _exit_tree() -> void:
	stop_music()
	_streams.clear()
