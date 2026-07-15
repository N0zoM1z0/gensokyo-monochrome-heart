class_name GameStateFixtureLoader
extends RefCounted
## Loads raw payload or full save-envelope fixtures through production migration rules.

var _migrator := SaveMigrator.new()
var _codec := GameStateCodec.new()


func load_path(path: String) -> GameStateFixtureLoadResult:
	var label := path.get_file()
	if not FileAccess.file_exists(path):
		return _failure(GameStateFixtureLoadResult.Code.NOT_FOUND, label, "fixture file is missing")
	var text := FileAccess.get_file_as_string(path)
	var parsed := _parse(text, label)
	if not parsed.is_success() and parsed.code != GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT:
		return parsed
	var raw: Variant = JSON.parse_string(text)
	if raw is Dictionary and String(raw.get("format", "")) == SaveRepository.SAVE_FORMAT:
		return _load_envelope_path(path, label)
	return _load_payload(raw, label)


func load_text(text: String, source_label: String = "memory") -> GameStateFixtureLoadResult:
	var safe_label := source_label.get_file()
	var parsed := _parse(text, safe_label)
	if parsed.code != GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT:
		return parsed
	var raw: Variant = JSON.parse_string(text)
	if raw is Dictionary and String(raw.get("format", "")) == SaveRepository.SAVE_FORMAT:
		return _load_envelope(raw, safe_label)
	return _load_payload(raw, safe_label)


func _parse(text: String, label: String) -> GameStateFixtureLoadResult:
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK or not json.data is Dictionary:
		return _failure(
			GameStateFixtureLoadResult.Code.PARSE_ERROR,
			label,
			"fixture JSON is malformed at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		)
	var result := GameStateFixtureLoadResult.new()
	result.code = GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT
	result.source_label = label
	return result


func _load_envelope_path(path: String, label: String) -> GameStateFixtureLoadResult:
	var decoded := SaveRepository.new("user://developer_fixture_reader").decode_envelope_file(path)
	if decoded.is_success():
		return _success(decoded.state, label, decoded.was_migrated)
	var code := GameStateFixtureLoadResult.Code.INVALID_STATE
	match decoded.code:
		SaveOperationResult.Code.PARSE_ERROR, SaveOperationResult.Code.SCHEMA_ERROR, SaveOperationResult.Code.VERIFY_ERROR:
			code = GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT
		SaveOperationResult.Code.CHECKSUM_ERROR:
			code = GameStateFixtureLoadResult.Code.CHECKSUM_ERROR
		SaveOperationResult.Code.MIGRATION_ERROR:
			code = GameStateFixtureLoadResult.Code.MIGRATION_ERROR
		SaveOperationResult.Code.FUTURE_VERSION:
			code = GameStateFixtureLoadResult.Code.FUTURE_VERSION
	var result := _failure(code, label, decoded.message)
	result.errors.append_array(decoded.diagnostics)
	return result


func _load_envelope(raw: Dictionary, label: String) -> GameStateFixtureLoadResult:
	for required: String in ["schema_version", "profile_id", "checksum", "payload"]:
		if not raw.has(required):
			return _failure(GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT, label, "save envelope is missing %s" % required)
	if not raw.payload is Dictionary:
		return _failure(GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT, label, "save envelope payload is not an object")
	var schema_version := int(raw.schema_version)
	var profile_id := StringName(raw.profile_id)
	var payload: Dictionary = raw.payload
	if StringName(payload.get("profile_id", "")) != profile_id or int(payload.get("schema_version", -1)) != schema_version:
		return _failure(GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT, label, "save envelope identity does not match payload")
	if not SaveChecksum.matches(String(raw.checksum), schema_version, profile_id, payload):
		return _failure(GameStateFixtureLoadResult.Code.CHECKSUM_ERROR, label, "save fixture checksum does not match canonical payload")
	return _load_payload(payload, label)


func _load_payload(raw: Variant, label: String) -> GameStateFixtureLoadResult:
	if not raw is Dictionary or not raw.has("schema_version") or not raw.has("profile_id"):
		return _failure(GameStateFixtureLoadResult.Code.UNSUPPORTED_FORMAT, label, "fixture is neither a save envelope nor a GameState payload")
	var migration := _migrator.migrate(raw)
	if migration.is_future_version:
		var future := _failure(GameStateFixtureLoadResult.Code.FUTURE_VERSION, label, migration.errors[0])
		future.errors.clear()
		future.errors.append_array(migration.errors)
		return future
	if not migration.is_success():
		var failed := _failure(GameStateFixtureLoadResult.Code.MIGRATION_ERROR, label, "fixture migration failed")
		failed.errors.append_array(migration.errors)
		return failed
	var decoded := _codec.decode(migration.payload)
	if not decoded.is_success():
		var invalid := _failure(GameStateFixtureLoadResult.Code.INVALID_STATE, label, "fixture failed typed GameState validation")
		invalid.errors.append_array(decoded.errors)
		return invalid
	return _success(decoded.state, label, migration.was_migrated)


func _success(state: GameState, label: String, was_migrated: bool) -> GameStateFixtureLoadResult:
	var result := GameStateFixtureLoadResult.new()
	result.source_label = label
	result.state = state
	result.was_migrated = was_migrated
	return result


func _failure(code: GameStateFixtureLoadResult.Code, label: String, message: String) -> GameStateFixtureLoadResult:
	var result := GameStateFixtureLoadResult.new()
	result.code = code
	result.source_label = label
	result.errors.append(message)
	return result
