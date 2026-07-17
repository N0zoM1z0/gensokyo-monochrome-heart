class_name TestVerticalSliceServices
extends RefCounted
## M09 local telemetry plus M16 production adaptive-audio contracts.

const TEST_ROOT := "user://tests/m09_slice_services"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(TEST_ROOT)
	_expect_production_adaptive_music(failures)
	_expect_production_sfx(failures)
	_expect_production_manifest_alignment(failures)
	_expect_local_telemetry(failures)
	_remove_tree(TEST_ROOT)
	return failures


func _expect_production_adaptive_music(failures: Array[String]) -> void:
	var player := ProductionAdaptiveMusicPlayer.new()
	if not player.request_state(&"mus_shrine_day") or player.current_state_id != &"mus_shrine_day":
		failures.append("production music director did not start its first reviewed state immediately")
	if player.current_family_id != &"hakurei_shrine" or player.family_restart_count != 1:
		failures.append("production music director did not resolve the shrine stem family")
	for role: StringName in ProductionAdaptiveMusicPlayer.STEM_ROLES:
		var path := player.stem_path(role)
		if path.is_empty() or not ResourceLoader.exists(path):
			failures.append("production music director omitted the %s stem" % role)
	if not player.request_state(&"mus_border_crossing") or player.queued_state_id != &"mus_border_crossing":
		failures.append("production music director did not queue a cross-state transition")
	player.advance_for_test(player.current_bar_seconds() - 0.01)
	if player.current_state_id != &"mus_shrine_day":
		failures.append("production music director changed before a bar boundary")
	player.advance_for_test(0.02)
	if player.current_state_id != &"mus_border_crossing" or player.transition_count != 2:
		failures.append("production music director did not change exactly at the next bar boundary")
	if player.family_restart_count != 1:
		failures.append("same-family music transition restarted synchronized stems")
	if not (
		player.stem_volume_db(&"incident") > player.stem_volume_db(&"person")
		and player.stem_volume_db(&"person") > player.stem_volume_db(&"place")
	):
		failures.append("incident music state did not promote the incident stem")
	player.set_music_muted(true)
	if not player.is_muted or player.volume_db > ProductionAdaptiveMusicPlayer.SILENT_DB:
		failures.append("music mute did not silence the production stem mix")
	player.set_dialogue_ducked(true)
	player.set_music_muted(false)
	if player.volume_db != AudioMixPolicy.music_gain_db(true):
		failures.append("important dialogue did not apply the reviewed music duck")
	player.set_dialogue_ducked(false)
	if player.volume_db != AudioMixPolicy.MUSIC_DB:
		failures.append("music did not return to its reviewed base gain after dialogue")
	if not player.request_state(&"mus_sdm_foyer"):
		failures.append("production music director rejected a reviewed mansion state")
	player.advance_for_test(player.current_bar_seconds())
	if player.current_family_id != &"scarlet_devil_mansion" or player.family_restart_count != 2:
		failures.append("cross-family transition did not restart one synchronized stem family")
	var warning_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.threat.warning")
	var damage_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.player.damage")
	var gameplay_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.danmaku.graze")
	var ambience_db := AudioMixPolicy.gain_db(AudioMixPolicy.Role.AUTO, &"sfx.step.wood")
	if not (warning_db > damage_db and damage_db > gameplay_db and gameplay_db > ambience_db):
		failures.append("production cue gains violate the warning/damage/gameplay/ambience hierarchy")
	if player.request_state(&"mus.not_reviewed"):
		failures.append("production music director accepted an unaudited music state")
	player.free()
	if AudioServer.get_bus_index(&"Music") < 0 or AudioServer.get_bus_index(&"SFX") < 0:
		failures.append("production Music/SFX buses are absent from the default layout")


func _expect_production_sfx(failures: Array[String]) -> void:
	var player := ProductionSfxPlayer.new()
	var impact := AudioCueIntent.new(&"sfx.fighter.impact", &"ui.fighter.cue.impact", 180.0, 0.1)
	player.play_cue(impact)
	if player.last_resolved_asset_id != &"sfx.combat.impact":
		failures.append("fighter impact did not resolve to the production combat impact")
	if player.voice_count_for_family(&"impact") != 1:
		failures.append("production impact family did not allocate a bounded voice pool")
	if ProductionSfxPlayer.resolve_asset_id(&"sfx.danmaku.graze") != &"sfx.danmaku.graze":
		failures.append("reviewed graze cue lost its exact production identity")
	if ProductionSfxPlayer.resolve_asset_id(&"sfx.fighter.spell_break") != &"sfx.player.damage":
		failures.append("critical spell-break cue did not resolve to the player-critical family")
	if ProductionSfxPlayer.resolve_asset_id(&"sfx.step.wood") != &"sfx.ambience.region_bed":
		failures.append("exploration ambience cue did not resolve to the production ambience family")
	for asset_id: StringName in ProductionSfxPlayer.ASSETS:
		var path := ProductionSfxPlayer.asset_path(asset_id)
		if path.is_empty() or not ResourceLoader.exists(path):
			failures.append("production SFX asset is unavailable: %s" % asset_id)
	player.free()


func _expect_production_manifest_alignment(failures: Array[String]) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/audio/production/production_manifest.json"
	))
	if not parsed is Dictionary or not parsed.get("assets", []) is Array:
		failures.append("production audio manifest could not be parsed")
		return
	var registered_music_paths: Dictionary[String, bool] = {}
	for family_id: StringName in ProductionAdaptiveMusicPlayer.FAMILY_DEFINITIONS:
		var family: Dictionary = ProductionAdaptiveMusicPlayer.FAMILY_DEFINITIONS[family_id]
		for role: StringName in ProductionAdaptiveMusicPlayer.STEM_ROLES:
			registered_music_paths[String(family[role])] = true
	var music_count := 0
	var sfx_count := 0
	for record_value: Variant in parsed.assets:
		var record: Dictionary = record_value
		var kind := String(record.get("kind", ""))
		if kind == "music_stem":
			music_count += 1
			if not registered_music_paths.has(String(record.path)):
				failures.append("production music manifest path is absent from the director: %s" % record.path)
		elif kind == "sfx":
			sfx_count += 1
			var asset_id := StringName(record.id)
			if not ProductionSfxPlayer.ASSETS.has(asset_id):
				failures.append("production SFX manifest ID is absent from the runtime: %s" % asset_id)
				continue
			var runtime: Dictionary = ProductionSfxPlayer.ASSETS[asset_id]
			if String(runtime.path) != String(record.path):
				failures.append("production SFX path drifted from the manifest: %s" % asset_id)
			if StringName(runtime.family) != StringName(record.family_id):
				failures.append("production SFX family drifted from the manifest: %s" % asset_id)
			if int(runtime.cap) != int(record.voice_cap) or int(runtime.priority) != int(record.priority):
				failures.append("production SFX voice policy drifted from the manifest: %s" % asset_id)
	if music_count != 15 or registered_music_paths.size() != music_count:
		failures.append("production music runtime/manifest expected exact 15/15 path coverage")
	if sfx_count != 12 or ProductionSfxPlayer.ASSETS.size() != sfx_count:
		failures.append("production SFX runtime/manifest expected exact 12/12 ID coverage")


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
