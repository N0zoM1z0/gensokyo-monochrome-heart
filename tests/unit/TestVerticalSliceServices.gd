class_name TestVerticalSliceServices
extends RefCounted
## M09 local telemetry and generated adaptive-tone contracts.

const TEST_ROOT := "user://tests/m09_slice_services"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(TEST_ROOT)
	_expect_adaptive_tones(failures)
	_expect_local_telemetry(failures)
	_remove_tree(TEST_ROOT)
	return failures


func _expect_adaptive_tones(failures: Array[String]) -> void:
	var player := AdaptiveTestTonePlayer.new()
	if not player.request_state(&"mus_shrine_day") or player.current_state_id != &"mus_shrine_day":
		failures.append("adaptive tone player did not start its first reviewed state immediately")
	if not player.request_state(&"mus_border_crossing") or player.queued_state_id != &"mus_border_crossing":
		failures.append("adaptive tone player did not queue a cross-state transition")
	player.advance_for_test(AdaptiveTestTonePlayer.BAR_SECONDS - 0.01)
	if player.current_state_id != &"mus_shrine_day":
		failures.append("adaptive tone player changed before a bar boundary")
	player.advance_for_test(0.02)
	if player.current_state_id != &"mus_border_crossing" or player.transition_count != 2:
		failures.append("adaptive tone player did not change exactly at the next bar boundary")
	player.set_music_muted(true)
	if not player.is_muted or player.volume_db > AdaptiveTestTonePlayer.SILENT_DB:
		failures.append("music mute did not silence the generated tone")
	player.set_dialogue_ducked(true)
	player.set_music_muted(false)
	if player.volume_db != AudioMixPolicy.music_gain_db(true):
		failures.append("important dialogue did not apply the reviewed 3 dB music duck")
	player.set_dialogue_ducked(false)
	if player.volume_db != AudioMixPolicy.MUSIC_DB:
		failures.append("music did not return to its reviewed base gain after dialogue")
	var warning_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.threat.warning")
	var damage_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.player.damage")
	var gameplay_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.danmaku.graze")
	var ambience_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.step.wood")
	if not (warning_db > damage_db and damage_db > gameplay_db and gameplay_db > ambience_db):
		failures.append("procedural cue gains violate the warning/damage/gameplay/ambience hierarchy")
	if player.request_state(&"mus.not_reviewed"):
		failures.append("adaptive tone player accepted an unaudited music state")
	player.free()


func _expect_local_telemetry(failures: Array[String]) -> void:
	var telemetry := VerticalSliceTelemetry.new()
	telemetry.begin_session(&"p90", &"2026.07.16.5", "a".repeat(64), 1000)
	telemetry.enter_phase(&"exploration", 1100)
	telemetry.exit_phase(&"exploration", 1450)
	var mode_telemetry := ModeTelemetry.new()
	mode_telemetry.attempt_count = 2
	var result := ModeResult.new(&"clear")
	result.telemetry = mode_telemetry
	telemetry.record_mode_result(&"danmaku.hkr.boundary_stain", result, 800)
	telemetry.complete_session(2200)
	var path := "%s/latest.json" % TEST_ROOT
	var write_result := telemetry.write_local(path)
	if not write_result.is_success():
		failures.append("local acceptance telemetry could not be written atomically: %s" % write_result.message)
		return
	var source := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(source)
	if not parsed is Dictionary or parsed.get("schema", "") != VerticalSliceTelemetry.SCHEMA_ID:
		failures.append("local acceptance telemetry did not round-trip its schema")
		return
	var records: Variant = parsed.get("records", [])
	if not records is Array or records.size() != 5:
		failures.append("local acceptance telemetry omitted ordered session evidence")
	if source.contains("/home/") or source.contains("\\Users\\"):
		failures.append("local acceptance telemetry leaked a personal filesystem path")
	if not bool(parsed.get("completed", false)):
		failures.append("local acceptance telemetry omitted session completion")


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
