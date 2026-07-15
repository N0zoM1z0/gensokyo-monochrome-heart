class_name TestGameStateInspector
extends RefCounted
## Developer inspection, fixture migration, envelope validation, and path-safety tests.

const TEST_ROOT := "user://tests/m03_state_inspector"
const T1 := "2026-07-15T15:00:00Z"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(TEST_ROOT)
	var state := _create_state()
	if state == null:
		return ["could not create state inspector fixture"]
	_expect_report(state, failures)
	_expect_payload_fixtures(failures)
	_expect_envelope_fixture(state, failures)
	_remove_tree(TEST_ROOT)
	return failures


func _expect_report(state: GameState, failures: Array[String]) -> void:
	var report := GameStateInspector.inspect(state, "/home/developer/private/fixture.save")
	var text := report.human_readable()
	if not report.is_valid or report.profile_id != state.profile_id:
		failures.append("valid state produced an invalid inspector report")
	if not text.contains("DEV-ONLY HIDDEN FACETS — NEVER PLAYER UI"):
		failures.append("inspector did not isolate raw relationship facets as developer-only")
	if not text.contains("char.reimu_hakurei") or not text.contains("trust=2(open)"):
		failures.append("inspector omitted deterministic hidden facet evidence")
	if text.contains("/home/") or text.contains("res://") or text.contains("user://"):
		failures.append("inspector report leaked a machine or project path")
	var missing := GameStateInspector.inspect(null)
	if missing.is_valid or not missing.human_readable().contains("GameState is missing"):
		failures.append("inspector did not diagnose a missing typed state")


func _expect_payload_fixtures(failures: Array[String]) -> void:
	var loader := GameStateFixtureLoader.new()
	var migrated := loader.load_path("res://tests/fixtures/saves/v1_route_affinity_payload.json")
	if not migrated.is_success() or not migrated.was_migrated:
		failures.append("fixture loader did not migrate the historical v1 payload")
	elif migrated.state.route_intent_id != &"route.hakurei.friendship":
		failures.append("fixture loader lost route intent during migration")
	var malformed := loader.load_text('{"schema_version":', "/private/malformed.json")
	if malformed.code != GameStateFixtureLoadResult.Code.PARSE_ERROR or malformed.source_label != "malformed.json":
		failures.append("fixture loader did not return a path-safe malformed JSON diagnostic")
	var unsupported := loader.load_text('{"kind":"not_state"}', "unsupported.json")
	if unsupported.code != GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT:
		failures.append("fixture loader accepted an unrelated JSON object")
	var future := loader.load_text('{"schema_version":999,"profile_id":"p01"}', "future.json")
	if future.code != GameStateFixtureLoadResult.Code.FUTURE_VERSION:
		failures.append("fixture loader did not preserve future saves as read-only diagnostics")


func _expect_envelope_fixture(state: GameState, failures: Array[String]) -> void:
	var repository := SaveRepository.new(TEST_ROOT)
	var saved := repository.save(state, &"manual_01", null, T1)
	if not saved.is_success():
		failures.append("could not create inspector envelope fixture")
		return
	var path := repository.slot_path(state.profile_id, &"manual_01")
	var loader := GameStateFixtureLoader.new()
	var loaded := loader.load_path(path)
	if not loaded.is_success() or GameStateCodec.new().canonical_state(loaded.state) != GameStateCodec.new().canonical_state(state):
		failures.append("fixture loader did not share production envelope decoding")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if raw is Dictionary:
		raw.payload.day = 42
		var tampered := loader.load_text(JSON.stringify(raw), "tampered.save")
		if tampered.code != GameStateFixtureLoadResult.Code.CHECKSUM_ERROR:
			failures.append("fixture loader accepted an envelope with a stale checksum")


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
	var state := GameStateFactory.create_new(&"p09", character_ids, region_ids, 9090)
	GameCommandDispatcher.new().dispatch(
		state,
		AdjustRelationshipCommand.new(&"char.reimu_hakurei", &"trust", 2)
	)
	return state


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
