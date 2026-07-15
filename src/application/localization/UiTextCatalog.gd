class_name UiTextCatalog
extends RefCounted
## Typed runtime boundary for the implementation-owned bilingual UI catalog.

const DEFAULT_PATH := "res://content/localization/ui_strings.json"
const SCHEMA_PATH := "res://schemas/ui_localization.schema.json"
const REVIEWED_CSV_PATH := "res://content/localization/strings.csv"

var errors: Array[String] = []
var _records: Dictionary[StringName, LocalizedTextRecord] = {}


func load_default() -> bool:
	if not load_from_file(DEFAULT_PATH):
		return false
	_merge_reviewed_csv(REVIEWED_CSV_PATH)
	return errors.is_empty()


func load_from_file(path: String) -> bool:
	errors.clear()
	_records.clear()
	var data: Variant = _load_json(path)
	var schema: Variant = _load_json(SCHEMA_PATH)
	if data == null or schema == null:
		return false
	if not data is Dictionary or not schema is Dictionary:
		errors.append("UI localization data and schema must be objects")
		return false
	for schema_error: String in JsonSchemaValidator.new().validate(data, schema):
		errors.append("%s: %s" % [path, schema_error])
	if not errors.is_empty():
		return false
	for raw_record: Variant in data.strings:
		var record_data: Dictionary = raw_record
		var key := StringName(record_data.key)
		if _records.has(key):
			errors.append("duplicate UI localization key: %s" % key)
			continue
		_records[key] = LocalizedTextRecord.new(key, record_data.en, record_data.ja)
	return errors.is_empty()


func text(key: StringName, locale: StringName) -> String:
	if not _records.has(key):
		return "[%s]" % key
	return _records[key].resolve(locale)


func has_key(key: StringName) -> bool:
	return _records.has(key)


func keys() -> Array[StringName]:
	var result: Array[StringName] = _records.keys()
	result.sort()
	return result


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("missing JSON file: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("cannot open JSON file: %s" % path)
		return null
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		errors.append("JSON parse failed: %s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _merge_reviewed_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("cannot open reviewed localization CSV: %s" % path)
		return
	var header := file.get_csv_line()
	if not header.is_empty():
		header[0] = header[0].trim_prefix("\ufeff")
	var key_index := header.find("key")
	var en_index := header.find("en")
	var ja_index := header.find("ja")
	if key_index < 0 or en_index < 0 or ja_index < 0:
		errors.append("reviewed localization CSV requires key, en, and ja columns")
		return
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].is_empty():
			continue
		if row.size() <= maxi(key_index, maxi(en_index, ja_index)):
			errors.append("incomplete reviewed localization CSV row")
			continue
		var key := StringName(row[key_index])
		if _records.has(key):
			errors.append("duplicate localization key across UI sources: %s" % key)
		else:
			_records[key] = LocalizedTextRecord.new(key, row[en_index], row[ja_index])
