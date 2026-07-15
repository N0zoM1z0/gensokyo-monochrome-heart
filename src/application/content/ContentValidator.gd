class_name ContentValidator
extends RefCounted
## M00 structural and reference validator for synchronized starter content.

const CHARACTER_PATH := "res://content/characters/characters.json"
const LOCATION_PATH := "res://content/locations/locations.json"
const EVENT_INDEX_PATH := "res://content/events/events.json"
const EVENT_GRAPH_PATH := "res://content/events/sample_event_empty_cushion.json"
const DIALOGUE_PATH := "res://content/dialogue/dialogue_samples.json"
const LOCALIZATION_PATH := "res://content/localization/strings.csv"
const UI_LOCALIZATION_PATH := "res://content/localization/ui_strings.json"
const DEFERRED_PATH := "res://content/indexes/deferred_references.json"
const SCHEMA_DIR := "res://schemas"

var _report: ContentValidationReport
var _id_sources: Dictionary[StringName, String] = {}
var _characters: Dictionary[StringName, bool] = {}
var _locations: Dictionary[StringName, bool] = {}
var _events: Dictionary[StringName, bool] = {}
var _beats: Dictionary[StringName, bool] = {}
var _localization: Dictionary[StringName, bool] = {}
var _deferred: Dictionary[StringName, StringName] = {}
var _schemas: Dictionary[StringName, Dictionary] = {}


func validate_project() -> ContentValidationReport:
	_reset()
	_validate_schema_inventory()
	_load_deferred_references()
	var character_data: Variant = _load_json(CHARACTER_PATH)
	var location_data: Variant = _load_json(LOCATION_PATH)
	var event_index_data: Variant = _load_json(EVENT_INDEX_PATH)
	var dialogue_data: Variant = _load_json(DIALOGUE_PATH)
	var event_graph_data: Variant = _load_json(EVENT_GRAPH_PATH)
	var ui_localization_data: Variant = _load_json(UI_LOCALIZATION_PATH)
	_validate_schema_instance(character_data, &"character_index.schema.json", CHARACTER_PATH)
	_validate_schema_instance(location_data, &"location_index.schema.json", LOCATION_PATH)
	_validate_schema_instance(event_index_data, &"event_index.schema.json", EVENT_INDEX_PATH)
	_validate_schema_instance(event_graph_data, &"event_graph.schema.json", EVENT_GRAPH_PATH)
	_validate_schema_instance(dialogue_data, &"dialogue_index.schema.json", DIALOGUE_PATH)
	_validate_schema_instance(ui_localization_data, &"ui_localization.schema.json", UI_LOCALIZATION_PATH)
	_validate_localization()
	_validate_ui_localization(ui_localization_data)
	_validate_characters(character_data)
	_validate_locations(location_data)
	_validate_event_index(event_index_data)
	_validate_dialogue(dialogue_data)
	_validate_event_graph(event_graph_data)
	return _report


func validate_duplicate_fixture(paths: Array[String]) -> ContentValidationReport:
	_reset()
	for path: String in paths:
		var data: Variant = _load_json(path)
		if not data is Dictionary or not data.has("characters") or not data.characters is Array:
			_report.add_error("fixture index missing characters array: %s" % path)
			continue
		for raw_record: Variant in data.characters:
			if raw_record is Dictionary and raw_record.has("id"):
				_register_id(StringName(raw_record.id), path)
	return _report


func _reset() -> void:
	_report = ContentValidationReport.new()
	_id_sources.clear()
	_characters.clear()
	_locations.clear()
	_events.clear()
	_beats.clear()
	_localization.clear()
	_deferred.clear()
	_schemas.clear()


func _load_json(path: String) -> Variant:
	_report.record_check()
	if not FileAccess.file_exists(path):
		_report.add_error("missing JSON file: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_report.add_error("cannot open JSON file: %s" % path)
		return null
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		_report.add_error("JSON parse failed: %s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _validate_schema_inventory() -> void:
	var required: Array[String] = [
		"character_agent_output.schema.json",
		"character_index.schema.json",
		"event_graph.schema.json",
		"event_index.schema.json",
		"dialogue_index.schema.json",
		"game_state_v2.schema.json",
		"location_index.schema.json",
		"minigame.schema.json",
		"save_card.schema.json",
		"save_envelope.schema.json",
		"ui_localization.schema.json",
		"content_runtime_index.schema.json",
	]
	for filename: String in required:
		var path := "%s/%s" % [SCHEMA_DIR, filename]
		var data: Variant = _load_json(path)
		if data is Dictionary and (not data.has("$schema") or not data.has("type")):
			_report.add_error("schema lacks $schema or type: %s" % path)
		elif data is Dictionary:
			_schemas[StringName(filename)] = data


func _validate_schema_instance(instance: Variant, schema_name: StringName, source_path: String) -> void:
	_report.record_check()
	if instance == null:
		return
	if not _schemas.has(schema_name):
		_report.add_error("missing loaded schema %s for %s" % [schema_name, source_path])
		return
	var schema_errors := JsonSchemaValidator.new().validate(instance, _schemas[schema_name])
	for schema_error: String in schema_errors:
		_report.add_error("schema violation in %s: %s" % [source_path, schema_error])


func _load_deferred_references() -> void:
	var data: Variant = _load_json(DEFERRED_PATH)
	if not data is Dictionary or not data.get("references", null) is Array:
		_report.add_error("deferred reference file lacks references array: %s" % DEFERRED_PATH)
		return
	for raw_record: Variant in data.references:
		if not raw_record is Dictionary or not raw_record.has("id") or not raw_record.has("kind"):
			_report.add_error("invalid deferred reference record in %s" % DEFERRED_PATH)
			continue
		var reference_id := StringName(raw_record.id)
		if _deferred.has(reference_id):
			_report.add_error("duplicate deferred reference: %s" % reference_id)
		else:
			_deferred[reference_id] = StringName(raw_record.kind)


func _validate_characters(data: Variant) -> void:
	var records: Array = _require_array(data, "characters", CHARACTER_PATH)
	for raw_record: Variant in records:
		if not raw_record is Dictionary:
			_report.add_error("non-object character record in %s" % CHARACTER_PATH)
			continue
		var character_id := _require_stable_id(raw_record, "id", "char", CHARACTER_PATH)
		if character_id == &"":
			continue
		_register_id(character_id, CHARACTER_PATH)
		_characters[character_id] = true
		var skills_path := String(raw_record.get("skills_document", ""))
		_report.record_check()
		if skills_path.is_empty() or not FileAccess.file_exists(skills_path):
			_report.add_error("%s has missing skills_document: %s" % [character_id, skills_path])
	_report.record_check()
	if records.size() != 71:
		_report.add_error("expected 71 character records, found %d" % records.size())


func _validate_locations(data: Variant) -> void:
	var records: Array = _require_array(data, "locations", LOCATION_PATH)
	for raw_record: Variant in records:
		if not raw_record is Dictionary:
			_report.add_error("non-object location record in %s" % LOCATION_PATH)
			continue
		var location_id := _require_stable_id(raw_record, "id", "loc", LOCATION_PATH)
		if location_id == &"":
			continue
		_register_id(location_id, LOCATION_PATH)
		_locations[location_id] = true
		var bible_path := String(raw_record.get("bible_path", ""))
		_report.record_check()
		if bible_path.is_empty() or not FileAccess.file_exists(bible_path):
			_report.add_error("%s has missing bible_path: %s" % [location_id, bible_path])
	_report.record_check()
	if records.size() != 19:
		_report.add_error("expected 19 location records, found %d" % records.size())


func _validate_event_index(data: Variant) -> void:
	var records: Array = _require_array(data, "events", EVENT_INDEX_PATH)
	for raw_record: Variant in records:
		if not raw_record is Dictionary:
			_report.add_error("non-object event record in %s" % EVENT_INDEX_PATH)
			continue
		var event_id := _require_stable_id(raw_record, "id", "evt", EVENT_INDEX_PATH)
		if event_id == &"":
			continue
		_register_id(event_id, EVENT_INDEX_PATH)
		_events[event_id] = true
		_require_reference(StringName(raw_record.get("location_id", "")), _locations, "location", event_id)
		var leads: Variant = raw_record.get("lead_character_ids", [])
		if not leads is Array:
			_report.add_error("%s lead_character_ids must be an array" % event_id)
		else:
			for lead: Variant in leads:
				_require_reference(StringName(lead), _characters, "character", event_id)
	_report.record_check()
	if records.size() != 28:
		_report.add_error("expected 28 event records, found %d" % records.size())


func _validate_dialogue(data: Variant) -> void:
	var records: Array = _require_array(data, "beats", DIALOGUE_PATH)
	for raw_record: Variant in records:
		if not raw_record is Dictionary:
			_report.add_error("non-object dialogue beat in %s" % DIALOGUE_PATH)
			continue
		var beat_id := _require_stable_id(raw_record, "id", "beat", DIALOGUE_PATH)
		if beat_id == &"":
			continue
		_register_id(beat_id, DIALOGUE_PATH)
		_beats[beat_id] = true
		_require_reference(StringName(raw_record.get("speaker_id", "")), _characters, "character", beat_id)
		_require_reference(StringName(raw_record.get("text_key", "")), _localization, "localization", beat_id)


func _validate_localization() -> void:
	_report.record_check()
	if not FileAccess.file_exists(LOCALIZATION_PATH):
		_report.add_error("missing localization CSV: %s" % LOCALIZATION_PATH)
		return
	var file := FileAccess.open(LOCALIZATION_PATH, FileAccess.READ)
	if file == null:
		_report.add_error("cannot open localization CSV: %s" % LOCALIZATION_PATH)
		return
	var header := file.get_csv_line()
	if not header.is_empty():
		header[0] = header[0].trim_prefix("\ufeff")
	var key_index := header.find("key")
	var en_index := header.find("en")
	var ja_index := header.find("ja")
	if key_index < 0 or en_index < 0 or ja_index < 0:
		_report.add_error("localization CSV requires key, en, and ja columns")
		return
	var line_number := 1
	while not file.eof_reached():
		var row := file.get_csv_line()
		line_number += 1
		if row.size() == 1 and row[0].is_empty():
			continue
		if row.size() <= maxi(key_index, maxi(en_index, ja_index)):
			_report.add_error("incomplete localization row at %s:%d" % [LOCALIZATION_PATH, line_number])
			continue
		var key := StringName(row[key_index])
		if key == &"" or row[en_index].is_empty() or row[ja_index].is_empty():
			_report.add_error("blank localization field at %s:%d" % [LOCALIZATION_PATH, line_number])
			continue
		if _localization.has(key):
			_report.add_error("duplicate localization key %s at %s:%d" % [key, LOCALIZATION_PATH, line_number])
		else:
			_localization[key] = true
	_report.add_note("loaded %d bilingual localization keys" % _localization.size())


func _validate_ui_localization(data: Variant) -> void:
	var records: Array = _require_array(data, "strings", UI_LOCALIZATION_PATH)
	for raw_record: Variant in records:
		if not raw_record is Dictionary or not raw_record.has("key"):
			_report.add_error("invalid UI localization record in %s" % UI_LOCALIZATION_PATH)
			continue
		var key := StringName(raw_record.key)
		if _localization.has(key):
			_report.add_error("duplicate localization key across catalogs: %s" % key)
		else:
			_localization[key] = true
	_report.add_note("loaded %d total localization keys after UI catalog" % _localization.size())


func _validate_event_graph(data: Variant) -> void:
	if not data is Dictionary:
		_report.add_error("event graph root must be an object: %s" % EVENT_GRAPH_PATH)
		return
	var event_id := _require_stable_id(data, "id", "evt", EVENT_GRAPH_PATH)
	_require_reference(event_id, _events, "event index", EVENT_GRAPH_PATH)
	_require_reference(StringName(data.get("location_id", "")), _locations, "location", event_id)
	for cast_id: Variant in data.get("cast", []):
		_require_reference(StringName(cast_id), _characters, "character", event_id)
	_require_deferred(StringName(data.get("spot_id", "")), &"spot", event_id)
	var raw_nodes: Variant = data.get("nodes", null)
	if not raw_nodes is Dictionary:
		_report.add_error("event graph nodes must be an object: %s" % EVENT_GRAPH_PATH)
		return
	var nodes: Dictionary = raw_nodes
	var entry := StringName(data.get("entry_node", ""))
	if not nodes.has(String(entry)):
		_report.add_error("event entry node is missing: %s" % entry)
		return
	var adjacency: Dictionary[StringName, Array] = {}
	var end_nodes: Dictionary[StringName, bool] = {}
	for node_key: Variant in nodes.keys():
		var node_id := StringName(node_key)
		adjacency[node_id] = []
		var node: Variant = nodes[node_key]
		if not node is Dictionary or not node.has("type"):
			_report.add_error("node %s lacks a type" % node_id)
			continue
		var node_type := StringName(node.type)
		if node_type == &"end_event":
			end_nodes[node_id] = true
		if node.has("next"):
			adjacency[node_id].append(StringName(node.next))
		for target: Variant in node.get("result_branches", {}).values():
			adjacency[node_id].append(StringName(target))
		for option: Variant in node.get("options", []):
			if option is Dictionary and option.has("next"):
				adjacency[node_id].append(StringName(option.next))
				_require_reference(StringName(option.get("text_key", "")), _localization, "localization", node_id)
		if node_type == &"line":
			_require_reference(StringName(node.get("beat_id", "")), _beats, "dialogue beat", node_id)
		elif node_type == &"exploration_objective":
			_require_reference(StringName(node.get("objective_key", "")), _localization, "localization", node_id)
			for interactable: Variant in node.get("interactable_ids", []):
				_require_deferred(StringName(interactable), &"interactable", node_id)
		elif node_type == &"start_minigame":
			_require_deferred(StringName(node.get("minigame_id", "")), &"minigame", node_id)
		elif node_type == &"give_item":
			_require_deferred(StringName(node.get("item_id", "")), &"item", node_id)
		elif node_type == &"journal_entry":
			_require_deferred(StringName(node.get("entry_id", "")), &"journal_entry", node_id)
		elif node_type == &"music_state":
			_require_deferred(StringName(node.get("state", "")), &"music_state", node_id)
	for source: StringName in adjacency:
		for target: StringName in adjacency[source]:
			if not adjacency.has(target):
				_report.add_error("event edge references missing node: %s -> %s" % [source, target])
	var reachable := _walk_graph(entry, adjacency)
	for node_id: StringName in adjacency:
		if not reachable.has(node_id):
			_report.add_error("unreachable event node: %s" % node_id)
	if end_nodes.is_empty():
		_report.add_error("event graph has no end_event node")
	else:
		var reverse := _reverse_graph(adjacency)
		var can_reach_end: Dictionary[StringName, bool] = {}
		for end_id: StringName in end_nodes:
			can_reach_end.merge(_walk_graph(end_id, reverse), true)
		for node_id: StringName in adjacency:
			if not can_reach_end.has(node_id):
				_report.add_error("event node cannot reach an end: %s" % node_id)
	_report.add_note("event graph reachable nodes: %d/%d" % [reachable.size(), adjacency.size()])


func _require_array(data: Variant, key: String, path: String) -> Array:
	if not data is Dictionary or not data.get(key, null) is Array:
		_report.add_error("%s must contain an array named %s" % [path, key])
		return []
	return data[key]


func _require_stable_id(record: Dictionary, key: String, prefix: String, source: String) -> StringName:
	var value := String(record.get(key, ""))
	_report.record_check()
	var expression := RegEx.create_from_string("^%s\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$" % prefix)
	if expression.search(value) == null:
		_report.add_error("invalid %s stable ID in %s: %s" % [prefix, source, value])
		return &""
	return StringName(value)


func _register_id(stable_id: StringName, source: String) -> void:
	_report.record_check()
	if _id_sources.has(stable_id):
		_report.add_error("duplicate stable ID %s in %s and %s" % [stable_id, _id_sources[stable_id], source])
	else:
		_id_sources[stable_id] = source


func _require_reference(stable_id: StringName, registry: Dictionary, kind: String, owner: Variant) -> void:
	_report.record_check()
	if stable_id == &"" or not registry.has(stable_id):
		_report.add_error("%s references unknown %s: %s" % [owner, kind, stable_id])


func _require_deferred(stable_id: StringName, kind: StringName, owner: Variant) -> void:
	_report.record_check()
	if stable_id == &"":
		_report.add_error("%s has an empty %s reference" % [owner, kind])
	elif not _deferred.has(stable_id):
		_report.add_error("%s references undefined %s without an allowlist record: %s" % [owner, kind, stable_id])
	elif _deferred[stable_id] != kind:
		_report.add_error("%s deferred reference kind mismatch for %s: expected %s, recorded %s" % [owner, stable_id, kind, _deferred[stable_id]])


func _walk_graph(start: StringName, adjacency: Dictionary) -> Dictionary[StringName, bool]:
	var seen: Dictionary[StringName, bool] = {}
	var pending: Array[StringName] = [start]
	while not pending.is_empty():
		var current: StringName = pending.pop_back()
		if seen.has(current) or not adjacency.has(current):
			continue
		seen[current] = true
		for neighbor: StringName in adjacency[current]:
			pending.append(neighbor)
	return seen


func _reverse_graph(adjacency: Dictionary) -> Dictionary[StringName, Array]:
	var reverse: Dictionary[StringName, Array] = {}
	for node_id: StringName in adjacency:
		reverse[node_id] = []
	for source: StringName in adjacency:
		for target: StringName in adjacency[source]:
			if reverse.has(target):
				reverse[target].append(source)
	return reverse
