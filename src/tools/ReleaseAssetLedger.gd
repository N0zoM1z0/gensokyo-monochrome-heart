class_name ReleaseAssetLedger
extends RefCounted
## Release-native mirror of the M16 art/audio/font provenance gate.

const LEDGER_PATH := "res://assets/asset_ledger.json"
const EXPECTED_SCHEMA := "gmh-runtime-asset-ledger-v1"
const APPROVED_STATUS := "approved_for_release"
const ALLOWED_RIGHTS: Array[StringName] = [
	&"project_original",
	&"commissioned",
	&"licensed",
]

var registered_files: int = 0
var discovered_files: int = 0


func validate_release_assets() -> Array[String]:
	registered_files = 0
	discovered_files = 0
	var errors: Array[String] = []
	var ledger := _read_json(LEDGER_PATH, errors)
	if ledger.is_empty():
		return errors
	if String(ledger.get("schema", "")) != EXPECTED_SCHEMA:
		errors.append("asset ledger has an unsupported schema")
	var records: Array = ledger.get("records", [])
	var release_roots: Array = ledger.get("release_roots", [])
	var excluded_directories: Array = ledger.get("excluded_directories", [])
	var tracked_extensions: Array = ledger.get("tracked_extensions", [])
	if records.is_empty() or release_roots.is_empty() or tracked_extensions.is_empty():
		errors.append("asset ledger policy arrays must not be empty")
		return errors

	var records_by_id: Dictionary = {}
	var registered_paths: Dictionary = {}
	for index: int in range(records.size()):
		if not records[index] is Dictionary:
			errors.append("asset ledger record %d is not an object" % index)
			continue
		_validate_record(records[index], index, records_by_id, registered_paths, errors)
	registered_files = registered_paths.size()
	_validate_pairs(records, records_by_id, errors)

	var discovered: Dictionary = {}
	for root: Variant in release_roots:
		_collect_assets(
			"res://%s" % String(root),
			tracked_extensions,
			excluded_directories,
			discovered
		)
	discovered_files = discovered.size()
	for path: String in discovered:
		if not registered_paths.has(path):
			errors.append("runtime art/audio/font is absent from the asset ledger: %s" % path)
	for path: String in registered_paths:
		if not discovered.has(path):
			errors.append("ledger path is outside tracked release assets: %s" % path)
	return errors


func _validate_record(
	record: Dictionary,
	index: int,
	records_by_id: Dictionary,
	registered_paths: Dictionary,
	errors: Array[String]
) -> void:
	var required := [
		"id", "path", "kind", "creator", "rights_basis", "license_id",
		"source_paths", "sha256", "approval_status", "approval_basis",
		"accessibility_pair",
	]
	for field: String in required:
		if not record.has(field):
			errors.append("asset ledger record %d lacks %s" % [index, field])
	if errors.any(func(error: String) -> bool: return error.begins_with("asset ledger record %d lacks" % index)):
		return
	var asset_id := String(record["id"])
	var path := String(record["path"])
	if not asset_id.begins_with("asset."):
		errors.append("asset ledger record has invalid id: %s" % asset_id)
	elif records_by_id.has(asset_id):
		errors.append("asset ledger has duplicate id: %s" % asset_id)
	else:
		records_by_id[asset_id] = record
	if path.begins_with("/") or path.begins_with("../") or path.contains("/../"):
		errors.append("asset ledger has unsafe path: %s" % path)
		return
	if registered_paths.has(path):
		errors.append("asset ledger has duplicate path: %s" % path)
	registered_paths[path] = true
	var resource_path := "res://%s" % path
	if not FileAccess.file_exists(resource_path):
		errors.append("registered asset is missing: %s" % path)
	elif String(record["sha256"]) != _sha256(resource_path):
		errors.append("asset hash mismatch: %s" % path)
	if StringName(record["rights_basis"]) not in ALLOWED_RIGHTS:
		errors.append("unsupported rights basis for %s" % asset_id)
	if String(record["approval_status"]) != APPROVED_STATUS:
		errors.append("asset is not release-approved: %s" % asset_id)
	if String(record["approval_basis"]).strip_edges().is_empty():
		errors.append("asset approval lacks an evidence note: %s" % asset_id)
	var sources: Array = record["source_paths"]
	if sources.is_empty():
		errors.append("asset lacks source provenance: %s" % asset_id)
	else:
		for source: Variant in sources:
			if not FileAccess.file_exists("res://%s" % String(source)):
				errors.append("asset source is missing for %s: %s" % [asset_id, source])
	if String(record["rights_basis"]) == "licensed":
		var license_path := String(record.get("license_path", ""))
		if license_path.is_empty() or not FileAccess.file_exists("res://%s" % license_path):
			errors.append("licensed asset lacks its license file: %s" % asset_id)


func _validate_pairs(
	records: Array,
	records_by_id: Dictionary,
	errors: Array[String]
) -> void:
	for record: Variant in records:
		if not record is Dictionary:
			continue
		var asset_id := String(record.get("id", ""))
		var pair_id := String(record.get("accessibility_pair", ""))
		if pair_id.is_empty():
			continue
		if not records_by_id.has(pair_id):
			errors.append("accessibility pair is unknown for %s: %s" % [asset_id, pair_id])
		elif String(records_by_id[pair_id].get("accessibility_pair", "")) != asset_id:
			errors.append("accessibility pair is not reciprocal: %s / %s" % [asset_id, pair_id])


func _collect_assets(
	path: String,
	tracked_extensions: Array,
	excluded_directories: Array,
	output: Dictionary
) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			if entry not in excluded_directories:
				_collect_assets(child_path, tracked_extensions, excluded_directories, output)
		elif entry.get_extension().to_lower() in tracked_extensions:
			output[child_path.trim_prefix("res://")] = true
		entry = directory.get_next()
	directory.list_dir_end()


func _read_json(path: String, errors: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("asset ledger is missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		errors.append("asset ledger is not valid JSON object: %s" % path)
		return {}
	return parsed


func _sha256(path: String) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()
