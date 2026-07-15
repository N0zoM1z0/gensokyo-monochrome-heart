class_name TestSaveRepository
extends RefCounted
## M03 slot, atomic interruption, checksum, backup, migration, and metadata tests.

const TEST_ROOT := "user://tests/m03_save_repository"
const T1 := "2026-07-15T10:00:00Z"
const T2 := "2026-07-15T11:00:00Z"
const T3 := "2026-07-15T12:00:00Z"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(TEST_ROOT)
	var repository := SaveRepository.new(TEST_ROOT)
	var state := _create_state()
	if state == null:
		return ["could not create save repository fixture state"]
	_expect_slot_contract(failures)
	_expect_round_trip_and_cards(repository, state, failures)
	_expect_atomic_interruption(repository, state, failures)
	_expect_truncated_recovery(repository, state, failures)
	_expect_checksum_recovery(repository, state, failures)
	_expect_v1_envelope_migration(repository, failures)
	_remove_tree(TEST_ROOT)
	return failures


func _expect_slot_contract(failures: Array[String]) -> void:
	if SaveSlotRules.manual(1) != &"manual_01" or SaveSlotRules.manual(3) != &"manual_03" or SaveSlotRules.manual(4) != &"":
		failures.append("manual slot contract is not exactly 1..3")
	var reasons := {
		&"day_start": &"auto_day",
		&"event_completion": &"auto_event",
		&"event_checkpoint": &"auto_event",
		&"before_mode": &"auto_mode",
		&"after_mode": &"auto_mode",
	}
	for reason: StringName in reasons:
		if SaveSlotRules.autosave_for(reason) != reasons[reason]:
			failures.append("autosave reason %s mapped to the wrong rolling slot" % reason)
	if SaveSlotRules.ALL_SLOTS.size() != 6 or SaveSlotRules.autosave_for(&"unsafe_mid_effect") != &"":
		failures.append("save slot rules accepted an unsafe or unknown boundary")


func _expect_round_trip_and_cards(
	repository: SaveRepository,
	state: GameState,
	failures: Array[String]
) -> void:
	var context := SaveCardContext.new()
	context.visible_character_ids = [&"char.reimu_hakurei", &"char.fixture.missing", &"char.marisa_kirisame"]
	context.accessibility_preset_id = &"accessibility.story"
	context.screenshot_path = "user://profiles/p08/screenshots/manual_01.png"
	var opening_canonical := GameStateCodec.new().canonical_state(state)
	var saved := repository.save(state, &"manual_01", context, T1)
	if not saved.is_success():
		failures.append("first manual save failed: %s %s" % [saved.message, saved.diagnostics])
		return
	if not FileAccess.file_exists(repository.slot_path(state.profile_id, &"manual_01")):
		failures.append("manual save file was not committed")
	if not FileAccess.file_exists(repository.card_path(state.profile_id, &"manual_01")):
		failures.append("lightweight save card was not committed")
	if not FileAccess.file_exists(repository.profile_index_path(state.profile_id)):
		failures.append("profile.json index was not generated")
	var loaded := repository.load(state.profile_id, &"manual_01")
	if not loaded.is_success():
		failures.append("manual save load failed: %s" % loaded.message)
	elif GameStateCodec.new().canonical_state(loaded.state) != opening_canonical:
		failures.append("save/load round trip is not deep-equal")
	var card_result := repository.load_card(state.profile_id, &"manual_01")
	if not card_result.is_success():
		failures.append("save card could not load independently")
	else:
		var card := card_result.card
		if card.day != state.day or card.location_id != state.current_location or card.play_time_seconds != state.play_time_seconds:
			failures.append("save card omitted core slot metadata")
		if card.visible_character_ids != [&"char.marisa_kirisame", &"char.reimu_hakurei"]:
			failures.append("save card did not filter and sort visible characters")
		if card.accessibility_preset_id != &"accessibility.story" or card.screenshot_path != context.screenshot_path:
			failures.append("save card omitted accessibility or screenshot context")
	var card_text := FileAccess.get_file_as_string(repository.card_path(state.profile_id, &"manual_01"))
	if card_text.contains('"payload"') or card_text.contains('"relationship"'):
		failures.append("lightweight card retained the full story payload")
	var auto_saved := repository.save(state, &"auto_day", context, T1)
	if not auto_saved.is_success() or repository.list_cards(state.profile_id).size() != 2:
		failures.append("rolling day autosave or card listing failed")
	var invalid_slot := repository.save(state, &"manual_04", context, T1)
	if invalid_slot.code != SaveOperationResult.Code.INVALID_SLOT:
		failures.append("repository accepted a fourth manual slot")


func _expect_atomic_interruption(
	repository: SaveRepository,
	opening_state: GameState,
	failures: Array[String]
) -> void:
	var committed := opening_state.deep_copy()
	committed.day = 2
	committed.play_time_seconds = 500
	var second_save := repository.save(committed, &"manual_01", null, T2)
	if not second_save.is_success():
		failures.append("second save could not create the recovery baseline: %s" % second_save.message)
		return
	if second_save.created_utc != T1:
		failures.append("slot overwrite did not retain created_utc")
	for fault_step: StringName in [&"after_temp_write", &"after_temp_verify", &"after_backup", &"before_commit"]:
		var interrupted := committed.deep_copy()
		interrupted.day = 3
		interrupted.play_time_seconds += 1
		repository.fault_after_step = fault_step
		var failed_save := repository.save(interrupted, &"manual_01", null, T3)
		if failed_save.is_success() or not failed_save.message.contains(String(fault_step)):
			failures.append("fault injection %s did not stop the atomic save" % fault_step)
		var loaded := repository.load(committed.profile_id, &"manual_01")
		if not loaded.is_success() or loaded.state.day != 2 or loaded.state.play_time_seconds != 500:
			failures.append("fault injection %s did not preserve the prior save" % fault_step)


func _expect_truncated_recovery(
	repository: SaveRepository,
	opening_state: GameState,
	failures: Array[String]
) -> void:
	# Re-establish distinct current/backup generations after interruption tests.
	var old_state := opening_state.deep_copy()
	old_state.day = 4
	old_state.play_time_seconds = 600
	repository.save(old_state, &"manual_02", null, T1)
	var current_state := old_state.deep_copy()
	current_state.day = 5
	current_state.play_time_seconds = 700
	repository.save(current_state, &"manual_02", null, T2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(repository.card_path(old_state.profile_id, &"manual_02")))
	_write_text(repository.slot_path(old_state.profile_id, &"manual_02"), '{"format":"gmh_save",')
	var recovered := repository.load(old_state.profile_id, &"manual_02")
	if not recovered.is_success() or not recovered.was_recovered_from_backup:
		failures.append("truncated current save did not recover its backup: %s" % recovered.message)
		return
	if recovered.state.day != 4 or recovered.state.play_time_seconds != 600:
		failures.append("truncated save recovered the wrong generation")
	if recovered.card == null or recovered.card.day != 4 or recovered.card.saved_utc != T1:
		failures.append("backup recovery left stale lightweight metadata")
	elif recovered.card.accessibility_preset_id != old_state.protagonist.comfort_profile_id:
		failures.append("card reconstruction replaced the persisted comfort profile with a default")
	var reloaded := repository.load(old_state.profile_id, &"manual_02")
	if not reloaded.is_success() or reloaded.was_recovered_from_backup or reloaded.state.day != 4:
		failures.append("recovered backup was not restored as the new valid current file")


func _expect_checksum_recovery(
	repository: SaveRepository,
	opening_state: GameState,
	failures: Array[String]
) -> void:
	var old_state := opening_state.deep_copy()
	old_state.day = 6
	repository.save(old_state, &"auto_event", null, T1)
	var current_state := old_state.deep_copy()
	current_state.day = 7
	repository.save(current_state, &"auto_event", null, T2)
	var path := repository.slot_path(old_state.profile_id, &"auto_event")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		failures.append("checksum fixture could not parse current save")
		return
	raw.payload.play_time_seconds = 999999
	_write_text(path, JSON.stringify(raw, "  ", false) + "\n")
	var recovered := repository.load(old_state.profile_id, &"auto_event")
	if not recovered.is_success() or not recovered.was_recovered_from_backup or recovered.state.day != 6:
		failures.append("checksum mismatch did not recover the previous generation")


func _expect_v1_envelope_migration(repository: SaveRepository, failures: Array[String]) -> void:
	var payload: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/saves/v1_route_affinity_payload.json")
	)
	if not payload is Dictionary:
		failures.append("v1 migration payload fixture could not parse")
		return
	var envelope := {
		"format": "gmh_save",
		"schema_version": 1,
		"game_version": "0.0.1-fixture",
		"profile_id": "p01",
		"created_utc": T1,
		"saved_utc": T1,
		"checksum": SaveChecksum.compute(1, &"p01", payload),
		"payload": payload,
	}
	var path := repository.slot_path(&"p01", &"manual_03")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	_write_text(path, JSON.stringify(envelope, "  ", false) + "\n")
	var loaded := repository.load(&"p01", &"manual_03")
	if not loaded.is_success() or not loaded.was_migrated:
		failures.append("valid v1 envelope did not load through the migration chain: %s" % loaded.message)
	elif loaded.state.route_intent_id != &"route.hakurei.friendship" or loaded.state.characters[&"char.reimu_hakurei"].route_intent != &"friendship":
		failures.append("loaded historical envelope lost route intent")


func _create_state() -> GameState:
	var content := ContentRepository.new()
	if not content.load_sources().is_success():
		return null
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in content.all_characters():
		character_ids.append(character.id)
	var region_ids: Array[StringName] = []
	for location: LocationRecord in content.all_locations():
		region_ids.append(location.id)
	var state := GameStateFactory.create_new(&"p08", character_ids, region_ids, 8080)
	state.protagonist.comfort_profile_id = &"accessibility.story"
	state.play_time_seconds = 420
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	return state


func _write_text(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(contents)
		file.flush()


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
		if entry != "." and entry != "..":
			var child := "%s/%s" % [path, entry]
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
