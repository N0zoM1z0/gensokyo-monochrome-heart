class_name ContentFileParser
extends RefCounted
## The only M02 boundary allowed to inspect authored JSON Dictionaries and CSV rows.

var _report: ContentLoadReport


func _init(report: ContentLoadReport) -> void:
	_report = report


func parse_manifest(path: String) -> ContentManifestRecord:
	var data: Variant = _load_json(path, &"parse_manifest")
	if not data is Dictionary:
		return ContentManifestRecord.new(0, &"unknown")
	var raw: Dictionary = data
	var manifest := ContentManifestRecord.new(
		int(raw.get("package_schema_version", 0)),
		StringName(String(raw.get("content_revision", "unknown")).strip_edges())
	)
	var counts: Variant = raw.get("counts", null)
	if counts is Dictionary:
		manifest.expected_characters = int(counts.get("characters", 0))
		manifest.expected_locations = int(counts.get("locations", 0))
		manifest.expected_events = int(counts.get("events", 0))
		manifest.expected_localization_rows = int(counts.get("localization_rows", 0))
	else:
		_report.add_error(&"parse_manifest", path, "counts must be an object")
	manifest.files = _strings(raw.get("files", []))
	manifest.schemas = _strings(raw.get("schemas", []))
	_report.record_check(&"parse_manifest")
	return manifest


func parse_characters(path: String, schema_path: String) -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	var data: Variant = _load_validated_json(path, schema_path, &"parse_characters")
	for raw: Variant in _object_array(data, "characters", path, &"parse_characters"):
		var record: Dictionary = raw
		result.append(
			CharacterRecord.new(
				_name(record.get("id", "")),
				_name(record.get("slug", "")),
				_clean(record.get("display_name_en", "")),
				_clean(record.get("display_name_ja", "")),
				_clean(record.get("faction_region", "")),
				_name(record.get("route_depth", "")),
				_clean(record.get("route_scope_note", "")),
				_name(record.get("canon_confidence", "")),
				_clean(record.get("skills_document", "")),
				_names(record.get("tags", [])),
				path
			)
		)
		_report.record_check(&"parse_characters")
	return result


func parse_locations(path: String, schema_path: String) -> Array[LocationRecord]:
	var result: Array[LocationRecord] = []
	var data: Variant = _load_validated_json(path, schema_path, &"parse_locations")
	for raw: Variant in _object_array(data, "locations", path, &"parse_locations"):
		var record: Dictionary = raw
		var position_values: Variant = record.get("map_position", [])
		var map_position := Vector2i.ZERO
		if position_values is Array and position_values.size() >= 2:
			map_position = Vector2i(int(position_values[0]), int(position_values[1]))
		result.append(
			LocationRecord.new(
				_name(record.get("id", "")),
				_clean(record.get("display_name_en", "")),
				_clean(record.get("display_name_ja", "")),
				_clean(record.get("bible_path", "")),
				map_position,
				_clean(record.get("thesis", "")),
				_name(record.get("launch_tier", "")),
				path
			)
		)
		_report.record_check(&"parse_locations")
	return result


func parse_events(path: String, schema_path: String) -> Array[EventIndexRecord]:
	var result: Array[EventIndexRecord] = []
	var data: Variant = _load_validated_json(path, schema_path, &"parse_events")
	for raw: Variant in _object_array(data, "events", path, &"parse_events"):
		var record: Dictionary = raw
		result.append(
			EventIndexRecord.new(
				_name(record.get("id", "")),
				_name(record.get("legacy_id", "")),
				_clean(record.get("title_en", "")),
				_name(record.get("location_id", "")),
				_names(record.get("lead_character_ids", [])),
				_name(record.get("primary_mode", "")),
				_clean(record.get("core_change", "")),
				_name(record.get("status", "")),
				int(record.get("estimated_minutes", 0)),
				_names(record.get("comfort_tags", [])),
				path
			)
		)
		_report.record_check(&"parse_events")
	return result


func parse_dialogue(path: String, schema_path: String) -> Array[DialogueBeatRecord]:
	var result: Array[DialogueBeatRecord] = []
	var data: Variant = _load_validated_json(path, schema_path, &"parse_dialogue")
	for raw: Variant in _object_array(data, "beats", path, &"parse_dialogue"):
		var record: Dictionary = raw
		result.append(
			DialogueBeatRecord.new(
				_name(record.get("id", "")),
				_name(record.get("speaker_id", "")),
				_name(record.get("text_key", "")),
				_name(record.get("portrait", "")),
				_name(record.get("nonverbal_key", "")),
				_name(record.get("advance_policy", "")),
				_name(record.get("memory_tag", "")),
				path
			)
		)
		_report.record_check(&"parse_dialogue")
	return result


func parse_localization(path: String) -> Array[ContentStringRecord]:
	var result: Array[ContentStringRecord] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_report.add_error(&"parse_localization", path, "could not open CSV")
		return result
	var header := file.get_csv_line()
	if not header.is_empty():
		header[0] = header[0].trim_prefix("\ufeff")
	for index: int in header.size():
		header[index] = header[index].trim_prefix("_")
	var required := ["key", "context", "speaker", "en", "ja", "max_width_px", "origin"]
	for column: String in required:
		if header.find(column) < 0:
			_report.add_error(&"parse_localization", path, "missing CSV column: %s" % column)
	if _report.error_count() > 0 and header.find("key") < 0:
		return result
	var line_number := 1
	while not file.eof_reached():
		var row := file.get_csv_line()
		line_number += 1
		if row.size() == 1 and row[0].is_empty():
			continue
		if row.size() < header.size():
			_report.add_error(&"parse_localization", path, "incomplete CSV row %d" % line_number)
			continue
		if row.size() > header.size():
			_report.add_error(
				&"parse_localization",
				path,
				"unexpected CSV column count on row %d: expected %d, found %d" % [line_number, header.size(), row.size()]
			)
			continue
		result.append(
			ContentStringRecord.new(
				StringName(row[header.find("key")].strip_edges()),
				StringName(row[header.find("context")].strip_edges()),
				row[header.find("speaker")].strip_edges(),
				row[header.find("en")],
				row[header.find("ja")],
				int(row[header.find("max_width_px")]),
				StringName(row[header.find("origin")].strip_edges()),
				path
			)
		)
		_report.record_check(&"parse_localization")
	return result


func parse_ui_localization(path: String, schema_path: String) -> Array[ContentStringRecord]:
	var result: Array[ContentStringRecord] = []
	var data: Variant = _load_validated_json(path, schema_path, &"parse_localization")
	for raw: Variant in _object_array(data, "strings", path, &"parse_localization"):
		var record: Dictionary = raw
		result.append(
			ContentStringRecord.new(
				_name(record.get("key", "")),
				&"ui",
				"",
				String(record.get("en", "")),
				String(record.get("ja", "")),
				0,
				&"Implementation",
				path
			)
		)
		_report.record_check(&"parse_localization")
	return result


func parse_music_cues(path: String) -> Array[MusicCueRecord]:
	var result: Array[MusicCueRecord] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_report.add_error(&"parse_music", path, "could not open CSV")
		return result
	var header := file.get_csv_line()
	if not header.is_empty():
		header[0] = header[0].trim_prefix("\ufeff")
	for index: int in header.size():
		header[index] = header[index].trim_prefix("_")
	var required := [
		"cue_id",
		"section",
		"scene_or_system",
		"mood_function",
		"touhou_reference_en",
		"touhou_reference_ja",
		"source_work",
		"arrangement_brief",
		"loop",
		"priority",
	]
	for column: String in required:
		if header.find(column) < 0:
			_report.add_error(&"parse_music", path, "missing CSV column: %s" % column)
	if header.find("cue_id") < 0:
		return result
	var line_number := 1
	while not file.eof_reached():
		var row := file.get_csv_line()
		line_number += 1
		if row.size() == 1 and row[0].is_empty():
			continue
		if row.size() < header.size():
			_report.add_error(&"parse_music", path, "incomplete CSV row %d" % line_number)
			continue
		result.append(
			MusicCueRecord.new(
				StringName(row[header.find("cue_id")].strip_edges()),
				StringName(row[header.find("section")].strip_edges()),
				row[header.find("scene_or_system")].strip_edges(),
				row[header.find("mood_function")].strip_edges(),
				row[header.find("touhou_reference_en")].strip_edges(),
				row[header.find("touhou_reference_ja")].strip_edges(),
				row[header.find("source_work")].strip_edges(),
				row[header.find("arrangement_brief")].strip_edges(),
				row[header.find("loop")].strip_edges().to_lower() == "yes",
				StringName(row[header.find("priority")].strip_edges()),
				path
			)
		)
		_report.record_check(&"parse_music")
	return result


func parse_deferred_references(path: String) -> Array[DeferredReferenceRecord]:
	var result: Array[DeferredReferenceRecord] = []
	var data: Variant = _load_json(path, &"parse_deferred")
	for raw: Variant in _object_array(data, "references", path, &"parse_deferred"):
		var record: Dictionary = raw
		result.append(
			DeferredReferenceRecord.new(
				_name(record.get("id", "")),
				_name(record.get("kind", "")),
				_name(record.get("target_milestone", "")),
				_clean(record.get("reason", "")),
				path
			)
		)
		_report.record_check(&"parse_deferred")
	return result


func parse_event_graph(path: String, schema_path: String) -> EventGraphRecord:
	var data: Variant = _load_validated_json(path, schema_path, &"parse_event_graph")
	if not data is Dictionary:
		return EventGraphRecord.new(0, &"", &"", &"", &"", [], &"", [])
	var raw: Dictionary = data
	var graph := EventGraphRecord.new(
		int(raw.get("schema_version", 0)),
		_name(raw.get("id", "")),
		_name(raw.get("title_key", "")),
		_name(raw.get("location_id", "")),
		_name(raw.get("spot_id", "")),
		_names(raw.get("cast", [])),
		_name(raw.get("entry_node", "")),
		_names(raw.get("comfort_tags", [])),
		path
	)
	var availability: Variant = raw.get("availability", [])
	if availability is Array:
		for raw_predicate: Variant in availability:
			if raw_predicate is Dictionary:
				graph.availability.append(
					AvailabilityPredicateRecord.new(
						_name(raw_predicate.get("predicate", "")),
						_name(raw_predicate.get("value", "")),
						_name(raw_predicate.get("key", "")),
						_names(raw_predicate.get("values", [])),
						_name(raw_predicate.get("character_id", "")),
						_name(raw_predicate.get("facet", "")),
						_name(raw_predicate.get("band", ""))
					)
				)
	var raw_nodes: Variant = raw.get("nodes", null)
	if raw_nodes is Dictionary:
		var node_keys: Array = raw_nodes.keys()
		node_keys.sort()
		for node_key: Variant in node_keys:
			var raw_node: Variant = raw_nodes[node_key]
			if not raw_node is Dictionary:
				_report.add_error(&"parse_event_graph", path, "node %s must be an object" % node_key)
				continue
			graph.nodes.append(_parse_event_node(StringName(node_key), raw_node))
			_report.record_check(&"parse_event_graph")
	else:
		_report.add_error(&"parse_event_graph", path, "nodes must be an object")
	var origin_tags: Variant = raw.get("origin_tags", null)
	if origin_tags is Dictionary:
		graph.origin_canon = int(origin_tags.get("canon", 0))
		graph.origin_fanon = int(origin_tags.get("fanon", 0))
		graph.origin_original = int(origin_tags.get("original", 0))
	return graph


func _parse_event_node(node_id: StringName, raw: Dictionary) -> EventNodeRecord:
	var node := EventNodeRecord.new(node_id, _name(raw.get("type", "")))
	node.next_node_id = _name(raw.get("next", ""))
	node.music_state_id = _name(raw.get("state", ""))
	node.objective_key = _name(raw.get("objective_key", ""))
	node.interactable_ids = _names(raw.get("interactable_ids", []))
	node.beat_id = _name(raw.get("beat_id", ""))
	node.item_id = _name(raw.get("item_id", ""))
	node.item_owner_character_id = _name(raw.get("owner_character_id", ""))
	node.item_dialogue_tags = _names(raw.get("dialogue_tags", []))
	node.journal_entry_id = _name(raw.get("entry_id", ""))
	node.journal_entry_type = _name(raw.get("entry_type", "event_observation"))
	node.journal_tags = _names(raw.get("tags", []))
	node.outcome = _name(raw.get("outcome", ""))
	if node.type == &"choice":
		var options: Array[ChoiceOptionRecord] = []
		var raw_options: Variant = raw.get("options", [])
		if raw_options is Array:
			for raw_option: Variant in raw_options:
				if raw_option is Dictionary:
					var option := ChoiceOptionRecord.new(
							_name(raw_option.get("tone", "")),
							_name(raw_option.get("text_key", "")),
							_name(raw_option.get("next", ""))
						)
					option.visible_if = _parse_predicates(raw_option.get("visible_if", []))
					option.available_if = _parse_predicates(raw_option.get("available_if", []))
					option.unavailable_reason_key = _name(raw_option.get("unavailable_reason_key", ""))
					options.append(option)
		node.choice = ChoiceRecord.new(_name(raw.get("choice_id", "")), options)
	var raw_effects: Variant = raw.get("effects", [])
	if raw_effects is Array:
		for raw_effect: Variant in raw_effects:
			if not raw_effect is Dictionary:
				continue
			var effect := EventEffectRecord.new(_name(raw_effect.get("op", "")))
			effect.character_id = _name(raw_effect.get("character_id", ""))
			effect.facet = _name(raw_effect.get("facet", ""))
			effect.delta = int(raw_effect.get("delta", 0))
			effect.stage = int(raw_effect.get("stage", 0))
			effect.route_intent = _name(raw_effect.get("intent", ""))
			effect.key = _name(raw_effect.get("key", ""))
			effect.boolean_value = bool(raw_effect.get("value", false))
			effect.rumor_id = _name(raw_effect.get("rumor_id", ""))
			effect.claim_key = _name(raw_effect.get("claim_key", ""))
			effect.source_character_id = _name(raw_effect.get("source_character_id", ""))
			effect.reliability_milli = int(raw_effect.get("reliability_milli", 0))
			effect.privacy = _name(raw_effect.get("privacy", "private"))
			effect.status = _name(raw_effect.get("status", "unresolved"))
			node.effects.append(effect)
	node.minigame_id = _name(raw.get("minigame_id", ""))
	var context: Variant = raw.get("context", null)
	if context is Dictionary:
		node.target_band = _name(context.get("target_band", ""))
		node.cups = int(context.get("cups", 0))
	var raw_branches: Variant = raw.get("result_branches", null)
	if raw_branches is Dictionary:
		var result_tags: Array = raw_branches.keys()
		result_tags.sort()
		for result_tag: Variant in result_tags:
			node.result_branches.append(
				ModeResultBranchRecord.new(StringName(result_tag), _name(raw_branches[result_tag]))
			)
	return node


func _parse_predicates(raw_predicates: Variant) -> Array[AvailabilityPredicateRecord]:
	var result: Array[AvailabilityPredicateRecord] = []
	if not raw_predicates is Array:
		return result
	for raw_predicate: Variant in raw_predicates:
		if not raw_predicate is Dictionary:
			continue
		result.append(
			AvailabilityPredicateRecord.new(
				_name(raw_predicate.get("predicate", "")),
				_name(raw_predicate.get("value", "")),
				_name(raw_predicate.get("key", "")),
				_names(raw_predicate.get("values", [])),
				_name(raw_predicate.get("character_id", "")),
				_name(raw_predicate.get("facet", "")),
				_name(raw_predicate.get("band", ""))
			)
		)
	return result


func _load_validated_json(path: String, schema_path: String, stage: StringName) -> Variant:
	var data: Variant = _load_json(path, stage)
	var schema: Variant = _load_json(schema_path, stage)
	if not data is Dictionary or not schema is Dictionary:
		return data
	for error: String in JsonSchemaValidator.new().validate(data, schema):
		_report.add_error(stage, path, "schema: %s" % error)
	return data


func _load_json(path: String, stage: StringName) -> Variant:
	_report.record_check(stage)
	if not FileAccess.file_exists(path):
		_report.add_error(stage, path, "file is missing")
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_report.add_error(stage, path, "file could not be opened")
		return null
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		_report.add_error(
			stage,
			path,
			"JSON line %d: %s" % [json.get_error_line(), json.get_error_message()]
		)
		return null
	return json.data


func _object_array(data: Variant, key: String, path: String, stage: StringName) -> Array:
	if not data is Dictionary or not data.get(key, null) is Array:
		_report.add_error(stage, path, "%s must be an array" % key)
		return []
	var result: Array = []
	for value: Variant in data[key]:
		if value is Dictionary:
			result.append(value)
		else:
			_report.add_error(stage, path, "%s contains a non-object record" % key)
	return result


func _clean(value: Variant) -> String:
	return String(value).strip_edges()


func _name(value: Variant) -> StringName:
	return StringName(_clean(value))


func _names(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for item: Variant in value:
			result.append(_name(item))
	return result


func _strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(_clean(item))
	return result
