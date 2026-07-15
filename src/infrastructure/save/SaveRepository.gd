class_name SaveRepository
extends RefCounted
## Versioned envelope, atomic slot IO, backup recovery, and lightweight card storage.

const ENVELOPE_SCHEMA_PATH := "res://schemas/save_envelope.schema.json"
const CARD_SCHEMA_PATH := "res://schemas/save_card.schema.json"
const SAVE_FORMAT := "gmh_save"
const CARD_FORMAT := "gmh_save_card"

var root_path: String
var game_version: String
var fault_after_step: StringName = &""

var _codec := GameStateCodec.new()
var _migrator := SaveMigrator.new()
var _writer := AtomicFileWriter.new()
var _envelope_schema: Dictionary = {}
var _card_schema: Dictionary = {}


func _init(p_root_path: String = "user://profiles") -> void:
	root_path = p_root_path.trim_suffix("/")
	game_version = String(ProjectSettings.get_setting("application/config/version", "0.1.0-dev"))


func save(
	state: GameState,
	slot_id: StringName,
	context: SaveCardContext = null,
	timestamp_override: String = ""
) -> SaveOperationResult:
	if not SaveSlotRules.is_valid(slot_id):
		return _failure(SaveOperationResult.Code.INVALID_SLOT, "invalid save slot: %s" % slot_id)
	var state_errors := GameStateValidator.new().validate(state)
	if not state_errors.is_empty():
		var invalid_result := _failure(SaveOperationResult.Code.INVALID_STATE, "GameState failed pre-save validation")
		invalid_result.diagnostics = state_errors
		return invalid_result
	var path := slot_path(state.profile_id, slot_id)
	var timestamp := timestamp_override if not timestamp_override.is_empty() else Time.get_datetime_string_from_system(true, false)
	var created_utc := _existing_created_utc(path)
	if created_utc.is_empty():
		created_utc = timestamp
	var payload := _codec.encode(state)
	var envelope := {
		"format": SAVE_FORMAT,
		"schema_version": state.schema_version,
		"game_version": game_version,
		"profile_id": String(state.profile_id),
		"created_utc": created_utc,
		"saved_utc": timestamp,
		"checksum": SaveChecksum.compute(state.schema_version, state.profile_id, payload),
		"payload": payload,
	}
	var contents := JSON.stringify(envelope, "  ", false) + "\n"
	var injected_fault := fault_after_step
	fault_after_step = &""
	var write_result := _writer.write_text(
		path,
		backup_path(state.profile_id, slot_id),
		contents,
		_verify_envelope_path.bind(state.profile_id),
		injected_fault
	)
	if not write_result.is_success():
		var failed := _failure(
			SaveOperationResult.Code.IO_ERROR,
			"atomic save failed at %s: %s" % [write_result.step, write_result.message],
			path
		)
		return failed
	var card := _build_card(state, slot_id, context, timestamp)
	var card_error := _write_card(card)
	var result := SaveOperationResult.new(SaveOperationResult.Code.OK, "save committed")
	result.path = path
	result.state = state.deep_copy()
	result.card = card
	result.created_utc = created_utc
	result.saved_utc = timestamp
	if card_error != OK:
		result.diagnostics.append("save data is safe, but card metadata failed with error %d" % card_error)
	var profile_error := _write_profile_index(state.profile_id, timestamp)
	if profile_error != OK:
		result.diagnostics.append("profile index failed with error %d" % profile_error)
	return result


func load(profile_id: StringName, slot_id: StringName) -> SaveOperationResult:
	if not SaveSlotRules.is_valid(slot_id):
		return _failure(SaveOperationResult.Code.INVALID_SLOT, "invalid save slot: %s" % slot_id)
	var path := slot_path(profile_id, slot_id)
	var current := decode_envelope_file(path, profile_id)
	if current.is_success():
		current.card = load_card(profile_id, slot_id).card
		return current
	var backup := backup_path(profile_id, slot_id)
	var recovered := decode_envelope_file(backup, profile_id)
	if not recovered.is_success():
		current.diagnostics.append("backup recovery failed: %s" % recovered.message)
		current.diagnostics.append_array(recovered.diagnostics)
		return current
	var restore_result := _writer.restore_backup(
		backup,
		path,
		_verify_envelope_path.bind(profile_id)
	)
	if not restore_result.is_success():
		current.diagnostics.append("valid backup could not be restored: %s" % restore_result.message)
		return current
	var stale_card_result := load_card(profile_id, slot_id)
	var recovery_context := _context_from_card(stale_card_result.card)
	var recovered_card := _build_card(recovered.state, slot_id, recovery_context, recovered.saved_utc)
	var recovery_card_error := _write_card(recovered_card)
	recovered.path = path
	recovered.was_recovered_from_backup = true
	recovered.message = "recovered valid backup after current save failed: %s" % current.message
	recovered.card = recovered_card
	if recovery_card_error != OK:
		recovered.diagnostics.append("recovered save card could not be refreshed (error %d)" % recovery_card_error)
	return recovered


func load_card(profile_id: StringName, slot_id: StringName) -> SaveOperationResult:
	if not SaveSlotRules.is_valid(slot_id):
		return _failure(SaveOperationResult.Code.INVALID_SLOT, "invalid save slot: %s" % slot_id)
	var path := card_path(profile_id, slot_id)
	if not FileAccess.file_exists(path):
		return _failure(SaveOperationResult.Code.NOT_FOUND, "save card is missing", path)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		return _failure(SaveOperationResult.Code.PARSE_ERROR, "save card is not valid JSON", path)
	var schema_errors := JsonSchemaValidator.new().validate(raw, _load_card_schema())
	if not schema_errors.is_empty():
		var invalid := _failure(SaveOperationResult.Code.SCHEMA_ERROR, "save card schema failed", path)
		invalid.diagnostics = schema_errors
		return invalid
	if StringName(raw.profile_id) != profile_id or StringName(raw.slot_id) != slot_id:
		return _failure(SaveOperationResult.Code.VERIFY_ERROR, "save card identity does not match its path", path)
	var result := SaveOperationResult.new(SaveOperationResult.Code.OK, "save card loaded")
	result.path = path
	result.card = _decode_card(raw)
	return result


func list_cards(profile_id: StringName) -> Array[SaveCardMetadata]:
	var result: Array[SaveCardMetadata] = []
	for slot_id: StringName in SaveSlotRules.ALL_SLOTS:
		var loaded := load_card(profile_id, slot_id)
		if loaded.is_success():
			result.append(loaded.card)
	return result


func slot_path(profile_id: StringName, slot_id: StringName) -> String:
	return "%s/%s/%s" % [root_path, profile_id, SaveSlotRules.filename(slot_id)]


func card_path(profile_id: StringName, slot_id: StringName) -> String:
	return "%s/%s/%s" % [root_path, profile_id, SaveSlotRules.card_filename(slot_id)]


func backup_path(profile_id: StringName, slot_id: StringName) -> String:
	return "%s/%s/backup/%s.bak" % [root_path, profile_id, SaveSlotRules.filename(slot_id)]


func profile_index_path(profile_id: StringName) -> String:
	return "%s/%s/profile.json" % [root_path, profile_id]


func decode_envelope_file(path: String, expected_profile_id: StringName = &"") -> SaveOperationResult:
	if path.is_empty() or not FileAccess.file_exists(path):
		return _failure(SaveOperationResult.Code.NOT_FOUND, "save file is missing", path)
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK or not json.data is Dictionary:
		return _failure(
			SaveOperationResult.Code.PARSE_ERROR,
			"save JSON is truncated or malformed at line %d: %s" % [json.get_error_line(), json.get_error_message()],
			path
		)
	var raw: Dictionary = json.data
	var schema_errors := JsonSchemaValidator.new().validate(raw, _load_envelope_schema())
	if not schema_errors.is_empty():
		var schema_failure := _failure(SaveOperationResult.Code.SCHEMA_ERROR, "save envelope schema failed", path)
		schema_failure.diagnostics = schema_errors
		return schema_failure
	var profile_id := StringName(raw.profile_id)
	var schema_version := int(raw.schema_version)
	var payload: Dictionary = raw.payload
	var required_profile_id := expected_profile_id if expected_profile_id != &"" else profile_id
	if profile_id != required_profile_id or StringName(payload.get("profile_id", "")) != required_profile_id:
		return _failure(SaveOperationResult.Code.VERIFY_ERROR, "save profile identity mismatch", path)
	if int(payload.get("schema_version", -1)) != schema_version:
		return _failure(SaveOperationResult.Code.VERIFY_ERROR, "envelope and payload schema versions differ", path)
	var checksum := String(raw.checksum)
	if RegEx.create_from_string("^sha256:[0-9a-f]{64}$").search(checksum) == null:
		return _failure(SaveOperationResult.Code.CHECKSUM_ERROR, "save checksum format is invalid", path)
	if not SaveChecksum.matches(checksum, schema_version, profile_id, payload):
		return _failure(SaveOperationResult.Code.CHECKSUM_ERROR, "save checksum does not match canonical payload", path)
	var migration := _migrator.migrate(payload)
	if migration.is_future_version:
		var future := _failure(SaveOperationResult.Code.FUTURE_VERSION, migration.errors[0], path)
		future.diagnostics = migration.errors
		return future
	if not migration.is_success():
		var migration_failure := _failure(SaveOperationResult.Code.MIGRATION_ERROR, "save migration failed", path)
		migration_failure.diagnostics = migration.errors
		return migration_failure
	var decoded := _codec.decode(migration.payload)
	if not decoded.is_success():
		var decode_failure := _failure(SaveOperationResult.Code.INVALID_STATE, "typed save payload failed validation", path)
		decode_failure.diagnostics = decoded.errors
		return decode_failure
	var result := SaveOperationResult.new(SaveOperationResult.Code.OK, "save loaded")
	result.path = path
	result.state = decoded.state
	result.was_migrated = migration.was_migrated
	result.created_utc = String(raw.get("created_utc", ""))
	result.saved_utc = String(raw.saved_utc)
	return result


func _build_card(
	state: GameState,
	slot_id: StringName,
	context: SaveCardContext,
	saved_utc: String
) -> SaveCardMetadata:
	var card := SaveCardMetadata.new()
	card.slot_id = slot_id
	card.profile_id = state.profile_id
	card.chapter_id = state.chapter_id
	card.day = state.day
	card.time_slot = state.time_slot
	card.location_id = state.current_location
	card.play_time_seconds = state.play_time_seconds
	card.route_completion_ids = state.route_completion_ids.duplicate()
	card.accessibility_preset_id = state.protagonist.comfort_profile_id
	if context != null:
		for character_id: StringName in context.visible_character_ids:
			if state.characters.has(character_id) and character_id not in card.visible_character_ids:
				card.visible_character_ids.append(character_id)
		card.accessibility_preset_id = context.accessibility_preset_id
		card.screenshot_path = context.screenshot_path
	card.visible_character_ids.sort_custom(_id_less)
	card.route_completion_ids.sort_custom(_id_less)
	card.game_version = game_version
	card.save_schema_version = state.schema_version
	card.saved_utc = saved_utc
	return card


func _context_from_card(card: SaveCardMetadata) -> SaveCardContext:
	if card == null:
		return null
	var context := SaveCardContext.new()
	context.visible_character_ids = card.visible_character_ids.duplicate()
	context.accessibility_preset_id = card.accessibility_preset_id
	context.screenshot_path = card.screenshot_path
	return context


func _write_card(card: SaveCardMetadata) -> Error:
	var path := card_path(card.profile_id, card.slot_id)
	var encoded := _encode_card(card)
	var result := _writer.write_text(
		path,
		"",
		JSON.stringify(encoded, "  ", false) + "\n",
		_verify_card_path.bind(card.profile_id, card.slot_id)
	)
	return result.error


func _encode_card(card: SaveCardMetadata) -> Dictionary:
	return {
		"format": CARD_FORMAT,
		"slot_id": String(card.slot_id),
		"profile_id": String(card.profile_id),
		"chapter_id": String(card.chapter_id),
		"day": card.day,
		"time_slot": String(card.time_slot),
		"location_id": String(card.location_id),
		"play_time_seconds": card.play_time_seconds,
		"visible_character_ids": _name_strings(card.visible_character_ids),
		"route_completion_ids": _name_strings(card.route_completion_ids),
		"accessibility_preset_id": String(card.accessibility_preset_id),
		"screenshot_path": card.screenshot_path,
		"game_version": card.game_version,
		"save_schema_version": card.save_schema_version,
		"saved_utc": card.saved_utc,
	}


func _decode_card(raw: Dictionary) -> SaveCardMetadata:
	var card := SaveCardMetadata.new()
	card.slot_id = StringName(raw.slot_id)
	card.profile_id = StringName(raw.profile_id)
	card.chapter_id = StringName(raw.chapter_id)
	card.day = int(raw.day)
	card.time_slot = StringName(raw.time_slot)
	card.location_id = StringName(raw.location_id)
	card.play_time_seconds = int(raw.play_time_seconds)
	card.visible_character_ids = _name_array(raw.visible_character_ids)
	card.route_completion_ids = _name_array(raw.route_completion_ids)
	card.accessibility_preset_id = StringName(raw.accessibility_preset_id)
	card.screenshot_path = String(raw.screenshot_path)
	card.game_version = String(raw.game_version)
	card.save_schema_version = int(raw.save_schema_version)
	card.saved_utc = String(raw.saved_utc)
	return card


func _write_profile_index(profile_id: StringName, timestamp: String) -> Error:
	var slot_ids: Array[String] = []
	for slot_id: StringName in SaveSlotRules.ALL_SLOTS:
		if FileAccess.file_exists(card_path(profile_id, slot_id)):
			slot_ids.append(String(slot_id))
	var data := {
		"format": "gmh_profile_index",
		"profile_id": String(profile_id),
		"updated_utc": timestamp,
		"slot_ids": slot_ids,
	}
	var result := _writer.write_text(
		profile_index_path(profile_id),
		"",
		JSON.stringify(data, "  ", false) + "\n",
		_verify_profile_index_path.bind(profile_id)
	)
	return result.error


func _verify_envelope_path(path: String, profile_id: StringName) -> bool:
	return decode_envelope_file(path, profile_id).is_success()


func _verify_card_path(path: String, profile_id: StringName, slot_id: StringName) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (
		raw is Dictionary
		and JsonSchemaValidator.new().validate(raw, _load_card_schema()).is_empty()
		and StringName(raw.profile_id) == profile_id
		and StringName(raw.slot_id) == slot_id
	)


func _verify_profile_index_path(path: String, profile_id: StringName) -> bool:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw is Dictionary and raw.get("format", "") == "gmh_profile_index" and StringName(raw.get("profile_id", "")) == profile_id


func _existing_created_utc(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return String(raw.get("created_utc", "")) if raw is Dictionary else ""


func _load_envelope_schema() -> Dictionary:
	if _envelope_schema.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENVELOPE_SCHEMA_PATH))
		if raw is Dictionary:
			_envelope_schema = raw
	return _envelope_schema


func _load_card_schema() -> Dictionary:
	if _card_schema.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARD_SCHEMA_PATH))
		if raw is Dictionary:
			_card_schema = raw
	return _card_schema


func _name_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result


func _name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in values:
		result.append(StringName(value))
	return result


func _id_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


func _failure(
	code: SaveOperationResult.Code,
	message: String,
	path: String = ""
) -> SaveOperationResult:
	var result := SaveOperationResult.new(code, message)
	result.path = path
	return result
