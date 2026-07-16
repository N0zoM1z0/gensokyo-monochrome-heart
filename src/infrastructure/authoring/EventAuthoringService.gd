class_name EventAuthoringService
extends RefCounted
## M11 boundary for duplicating, validating, and previewing isolated event bundles.

const DEFAULT_EVENT_PATH := "res://content/events/sample_event_empty_cushion.json"
const DEFAULT_DIALOGUE_PATH := "res://content/dialogue/dialogue_samples.json"
const DEFAULT_LOCALIZATION_PATH := "res://content/localization/strings.csv"
const EVENT_SCHEMA_PATH := "res://schemas/event_graph.schema.json"
const DIALOGUE_SCHEMA_PATH := "res://schemas/dialogue_index.schema.json"
const MANIFEST_FILE := "manifest.json"
const EVENT_FILE := "event.json"
const DIALOGUE_FILE := "dialogue.json"
const STRINGS_FILE := "strings.csv"


func duplicate_empty_cushion(new_event_id: StringName, output_path: String) -> EventAuthoringBundle:
	var result := EventAuthoringBundle.new()
	result.bundle_path = output_path
	if not _valid_event_id(new_event_id):
		result.errors.append("event ID must match evt.<lowercase_namespace>: %s" % new_event_id)
		return result
	if output_path.strip_edges().is_empty():
		result.errors.append("output path cannot be empty")
		return result
	var absolute_output := ProjectSettings.globalize_path(output_path)
	if DirAccess.dir_exists_absolute(absolute_output):
		result.errors.append("output directory already exists: %s" % output_path)
		return result
	var event_data := _load_json_dictionary(DEFAULT_EVENT_PATH, result.errors)
	var dialogue_data := _load_json_dictionary(DEFAULT_DIALOGUE_PATH, result.errors)
	var localization_rows := _load_csv(DEFAULT_LOCALIZATION_PATH, result.errors)
	if not result.errors.is_empty():
		return result

	var source_event_id := String(event_data.get("id", ""))
	var source_scope := source_event_id.trim_prefix("evt.")
	var new_scope := String(new_event_id).trim_prefix("evt.")
	var referenced_beat_ids := _referenced_values(event_data, "beat_id")
	var selected_beats: Array = []
	var referenced_string_keys := _referenced_graph_string_keys(event_data)
	for raw_beat: Variant in dialogue_data.get("beats", []):
		if not raw_beat is Dictionary or String(raw_beat.get("id", "")) not in referenced_beat_ids:
			continue
		selected_beats.append(raw_beat.duplicate(true))
		_retain_unique(referenced_string_keys, String(raw_beat.get("text_key", "")))
	for row: PackedStringArray in localization_rows:
		if row.size() > 0 and row[0].begins_with("journal.%s." % source_scope):
			_retain_unique(referenced_string_keys, row[0])

	var key_map: Dictionary = {}
	for old_key: String in referenced_string_keys:
		key_map[old_key] = _remap_localization_key(old_key, source_scope, new_scope)
	var cloned_event: Variant = _remap_value(event_data, source_scope, new_scope, key_map)
	var cloned_beats: Array = []
	for raw_beat: Dictionary in selected_beats:
		cloned_beats.append(_remap_value(raw_beat, source_scope, new_scope, key_map))
	var cloned_dialogue := {"schema_version": 1, "beats": cloned_beats}
	var cloned_rows: Array[PackedStringArray] = []
	for row: PackedStringArray in localization_rows:
		if row.size() == 0 or row[0] not in referenced_string_keys:
			continue
		var cloned_row := row.duplicate()
		cloned_row[0] = String(key_map[row[0]])
		cloned_rows.append(cloned_row)
	cloned_rows.sort_custom(func(left: PackedStringArray, right: PackedStringArray) -> bool: return left[0] < right[0])
	var manifest := {
		"schema_version": 1,
		"bundle_kind": "event_authoring_draft",
		"event_id": String(new_event_id),
		"source_event_id": source_event_id,
		"files": [EVENT_FILE, DIALOGUE_FILE, STRINGS_FILE],
	}
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output)
	if directory_error != OK:
		result.errors.append("could not create output directory: error %d" % directory_error)
		return result
	_write_json(_join(output_path, MANIFEST_FILE), manifest, result.errors)
	_write_json(_join(output_path, EVENT_FILE), cloned_event, result.errors)
	_write_json(_join(output_path, DIALOGUE_FILE), cloned_dialogue, result.errors)
	_write_csv(_join(output_path, STRINGS_FILE), cloned_rows, result.errors)
	if not result.errors.is_empty():
		return result
	return validate_bundle(output_path)


func validate_bundle(bundle_path: String) -> EventAuthoringBundle:
	var bundle := EventAuthoringBundle.new()
	bundle.bundle_path = bundle_path
	var manifest_path := _join(bundle_path, MANIFEST_FILE)
	var event_path := _join(bundle_path, EVENT_FILE)
	var dialogue_path := _join(bundle_path, DIALOGUE_FILE)
	var strings_path := _join(bundle_path, STRINGS_FILE)
	var manifest := _load_json_dictionary(manifest_path, bundle.errors)
	_validate_manifest(manifest, manifest_path, bundle.errors)
	if not manifest.is_empty():
		bundle.source_event_id = StringName(String(manifest.get("source_event_id", "")))
	var load_report := ContentLoadReport.new()
	var parser := ContentFileParser.new(load_report)
	bundle.graph = parser.parse_event_graph(event_path, EVENT_SCHEMA_PATH)
	bundle.dialogue_beats = parser.parse_dialogue(dialogue_path, DIALOGUE_SCHEMA_PATH)
	bundle.localized_strings = parser.parse_localization(strings_path)
	for diagnostic: ContentDiagnostic in load_report.diagnostics:
		if diagnostic.severity == ContentDiagnostic.ERROR:
			bundle.errors.append("%s: %s" % [diagnostic.source, diagnostic.message])
		elif diagnostic.severity == ContentDiagnostic.WARNING:
			bundle.warnings.append("%s: %s" % [diagnostic.source, diagnostic.message])
	if bundle.graph == null:
		bundle.errors.append("event graph could not be parsed")
		return bundle
	if StringName(String(manifest.get("event_id", ""))) != bundle.graph.id:
		bundle.errors.append("manifest event_id does not match event.json: %s" % bundle.graph.id)
	for error: String in EventGraphValidator.new().validate(bundle.graph):
		bundle.errors.append("event.json: %s" % error)
	_validate_bundle_references(bundle)
	_validate_catalog_references(bundle)
	return bundle


func render_preview(bundle: EventAuthoringBundle, locale: StringName) -> String:
	if bundle == null or not bundle.is_valid() or bundle.graph == null:
		return ""
	if locale not in [&"en", &"ja"]:
		return ""
	var title := _localized(bundle, bundle.graph.title_key, locale)
	var lines: PackedStringArray = [
		"# %s" % title,
		"",
		"- Event: `%s`" % bundle.graph.id,
		"- Locale: `%s`" % locale,
		"- Location: `%s` / spot `%s`" % [bundle.graph.location_id, bundle.graph.spot_id],
		"- Cast: %s" % ", ".join(_names_to_strings(bundle.graph.cast)),
		"- Entry: `%s`" % bundle.graph.entry_node_id,
		"",
		"## Event graph",
		"",
	]
	var visited: Array[StringName] = []
	_append_preview_node(bundle.graph.entry_node_id, bundle, locale, visited, lines)
	return "\n".join(lines).strip_edges() + "\n"


func write_preview(bundle_path: String, locale: StringName, output_path: String) -> EventAuthoringBundle:
	var bundle := validate_bundle(bundle_path)
	if not bundle.is_valid():
		return bundle
	if locale not in [&"en", &"ja"]:
		bundle.errors.append("locale must be en or ja: %s" % locale)
		return bundle
	var preview := render_preview(bundle, locale)
	if output_path == "-":
		print(preview)
		return bundle
	_write_text(output_path, preview, bundle.errors)
	return bundle


func render_dependency_report(bundle: EventAuthoringBundle) -> String:
	if bundle == null or not bundle.is_valid() or bundle.graph == null:
		return ""
	var graph := _build_dependency_graph(bundle)
	var lines: PackedStringArray = [
		"# Event dependency report",
		"",
		"- Event: `%s`" % bundle.graph.id,
		"- Nodes: %d" % graph.node_ids().size(),
		"- Edges: %d" % graph.edges().size(),
		"",
		"| Source | Relationship | Target |",
		"| --- | --- | --- |",
	]
	for edge: ContentDependencyEdge in graph.edges():
		lines.append("| `%s` | %s | `%s` |" % [edge.source_id, edge.kind, edge.target_id])
	return "\n".join(lines) + "\n"


func write_dependency_report(bundle_path: String, output_path: String) -> EventAuthoringBundle:
	var bundle := validate_bundle(bundle_path)
	if not bundle.is_valid():
		return bundle
	var report := render_dependency_report(bundle)
	if output_path == "-":
		print(report)
	else:
		_write_text(output_path, report, bundle.errors)
	return bundle


func render_width_report(bundle: EventAuthoringBundle, locale: StringName, ui_scale: int = 100) -> String:
	if bundle == null or not bundle.is_valid() or locale not in [&"en", &"ja"] or ui_scale not in [100, 150]:
		return ""
	var font := UiFontRegistry.japanese() if locale == &"ja" else UiFontRegistry.latin()
	var font_size := 12 if ui_scale == 150 else 8
	var records := bundle.localized_strings.duplicate()
	records.sort_custom(func(left: ContentStringRecord, right: ContentStringRecord) -> bool: return String(left.key) < String(right.key))
	var overflow_count := 0
	var wrapped_count := 0
	var rows := PackedStringArray()
	for record: ContentStringRecord in records:
		var text := record.resolve(locale)
		var budget := ceili(float(record.maximum_width_px) * float(ui_scale) / 100.0)
		var raw_width := ceili(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		var wrapped := PixelTextWrapper.wrap(text, font, budget, font_size, locale)
		var maximum_line_width := 0
		for line: String in wrapped:
			maximum_line_width = maxi(maximum_line_width, ceili(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x))
		var overflow := maxi(0, maximum_line_width - budget)
		var status := "FIT"
		if overflow > 0:
			status = "OVERFLOW"
			overflow_count += 1
		elif wrapped.size() > 1:
			status = "WRAP"
			wrapped_count += 1
		rows.append("| `%s` | %s | %d | %d | %d | %d | %d | %s |" % [
			record.key,
			record.context,
			raw_width,
			budget,
			wrapped.size(),
			maximum_line_width,
			overflow,
			status,
		])
	var lines: PackedStringArray = [
		"# Localization width report",
		"",
		"- Event: `%s`" % bundle.graph.id,
		"- Locale: `%s`" % locale,
		"- UI scale: `%d%%`" % ui_scale,
		"- Font size: `%d px`" % font_size,
		"- Strings: %d" % records.size(),
		"- Wrapped: %d" % wrapped_count,
		"- Overflow: %d" % overflow_count,
		"",
		"| Key | Context | Raw px | Budget px | Lines | Max line px | Overflow px | Status |",
		"| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
	]
	lines.append_array(rows)
	return "\n".join(lines) + "\n"


func write_width_report(
	bundle_path: String,
	locale: StringName,
	ui_scale: int,
	output_path: String
) -> EventAuthoringBundle:
	var bundle := validate_bundle(bundle_path)
	if not bundle.is_valid():
		return bundle
	if locale not in [&"en", &"ja"]:
		bundle.errors.append("locale must be en or ja: %s" % locale)
		return bundle
	if ui_scale not in [100, 150]:
		bundle.errors.append("ui-scale must be 100 or 150: %d" % ui_scale)
		return bundle
	var report := render_width_report(bundle, locale, ui_scale)
	if output_path == "-":
		print(report)
	else:
		_write_text(output_path, report, bundle.errors)
	return bundle


func _build_dependency_graph(bundle: EventAuthoringBundle) -> ContentDependencyGraph:
	var result := ContentDependencyGraph.new()
	var event_id := bundle.graph.id
	result.add_node(event_id)
	result.add_edge(event_id, bundle.graph.title_key, &"title")
	result.add_edge(event_id, bundle.graph.location_id, &"location")
	result.add_edge(event_id, bundle.graph.spot_id, &"spot")
	for character_id: StringName in bundle.graph.cast:
		result.add_edge(event_id, character_id, &"cast")
	for beat: DialogueBeatRecord in bundle.dialogue_beats:
		result.add_edge(beat.id, beat.speaker_id, &"speaker")
		result.add_edge(beat.id, beat.text_key, &"localization")
	for node: EventNodeRecord in bundle.graph.nodes:
		var owner := StringName("%s.node.%s" % [event_id, node.id])
		result.add_edge(event_id, owner, &"node")
		for target: StringName in node.outgoing_node_ids():
			result.add_edge(owner, StringName("%s.node.%s" % [event_id, target]), &"event_edge")
		if node.music_state_id != &"":
			result.add_edge(owner, node.music_state_id, &"music")
		if node.objective_key != &"":
			result.add_edge(owner, node.objective_key, &"localization")
		for interactable_id: StringName in node.interactable_ids:
			result.add_edge(owner, interactable_id, &"interactable")
		if node.beat_id != &"":
			result.add_edge(owner, node.beat_id, &"dialogue_beat")
		if node.choice != null:
			result.add_edge(owner, node.choice.id, &"choice")
			for option: ChoiceOptionRecord in node.choice.options:
				result.add_edge(node.choice.id, option.text_key, &"localization")
		for effect: EventEffectRecord in node.effects:
			if effect.character_id != &"":
				result.add_edge(owner, effect.character_id, &"effect_character")
			if effect.source_character_id != &"":
				result.add_edge(owner, effect.source_character_id, &"rumor_source")
			if effect.claim_key != &"":
				result.add_edge(owner, effect.claim_key, &"localization")
		if node.minigame_id != &"":
			result.add_edge(owner, node.minigame_id, &"mode")
		if node.item_id != &"":
			result.add_edge(owner, node.item_id, &"item")
		if node.journal_entry_id != &"":
			result.add_edge(owner, node.journal_entry_id, &"journal_entry")
	return result


func _validate_bundle_references(bundle: EventAuthoringBundle) -> void:
	var beat_ids: Array[StringName] = []
	var string_keys: Array[StringName] = []
	for record: ContentStringRecord in bundle.localized_strings:
		if record.key in string_keys:
			bundle.errors.append("strings.csv: duplicate localization key %s" % record.key)
		else:
			string_keys.append(record.key)
		if record.english.strip_edges().is_empty() or record.japanese.strip_edges().is_empty():
			bundle.errors.append("strings.csv: %s requires non-empty English and Japanese text" % record.key)
		if record.maximum_width_px <= 0:
			bundle.errors.append("strings.csv: %s requires a positive max_width_px" % record.key)
	for beat: DialogueBeatRecord in bundle.dialogue_beats:
		if not _valid_namespaced_id(beat.id, "beat"):
			bundle.errors.append("dialogue.json: invalid beat ID %s" % beat.id)
		if beat.id in beat_ids:
			bundle.errors.append("dialogue.json: duplicate beat ID %s" % beat.id)
		else:
			beat_ids.append(beat.id)
		if beat.text_key not in string_keys:
			bundle.errors.append("dialogue.json: beat %s references missing string %s" % [beat.id, beat.text_key])
	_validate_string_reference(bundle.graph.title_key, "event title", string_keys, bundle.errors)
	for node: EventNodeRecord in bundle.graph.nodes:
		if node.beat_id != &"" and node.beat_id not in beat_ids:
			bundle.errors.append("event.json: node %s references missing beat %s" % [node.id, node.beat_id])
		if node.objective_key != &"":
			_validate_string_reference(node.objective_key, "objective at node %s" % node.id, string_keys, bundle.errors)
		if node.choice != null:
			if not _valid_namespaced_id(node.choice.id, "choice"):
				bundle.errors.append("event.json: invalid choice ID %s" % node.choice.id)
			for option: ChoiceOptionRecord in node.choice.options:
				_validate_string_reference(option.text_key, "choice %s" % node.choice.id, string_keys, bundle.errors)
				if option.unavailable_reason_key != &"":
					_validate_string_reference(option.unavailable_reason_key, "choice reason %s" % node.choice.id, string_keys, bundle.errors)
		for effect: EventEffectRecord in node.effects:
			if effect.claim_key != &"":
				_validate_string_reference(effect.claim_key, "rumor claim at node %s" % node.id, string_keys, bundle.errors)


func _validate_catalog_references(bundle: EventAuthoringBundle) -> void:
	var catalog := ContentRepository.new()
	var catalog_report := catalog.load_sources()
	if not catalog_report.is_success():
		bundle.errors.append("reviewed content catalog is unavailable; shared references cannot be validated")
		return
	if catalog.location(bundle.graph.location_id) == null:
		bundle.errors.append("event.json: unknown shared location %s" % bundle.graph.location_id)
	if not _valid_namespaced_id(bundle.graph.spot_id, "loc"):
		bundle.errors.append("event.json: spot ID must use the loc namespace: %s" % bundle.graph.spot_id)
	for character_id: StringName in bundle.graph.cast:
		if catalog.character(character_id) == null:
			bundle.errors.append("event.json: unknown cast character %s" % character_id)
	for beat: DialogueBeatRecord in bundle.dialogue_beats:
		if catalog.character(beat.speaker_id) == null:
			bundle.errors.append("dialogue.json: beat %s uses unknown speaker %s" % [beat.id, beat.speaker_id])
	for node: EventNodeRecord in bundle.graph.nodes:
		if node.music_state_id != &"" and catalog.music_cue(node.music_state_id) == null:
			bundle.errors.append("event.json: node %s uses unknown music state %s" % [node.id, node.music_state_id])
		for interactable_id: StringName in node.interactable_ids:
			if not _valid_namespaced_id(interactable_id, "prop"):
				bundle.errors.append("event.json: node %s has invalid prop ID %s" % [node.id, interactable_id])
		for effect: EventEffectRecord in node.effects:
			if effect.character_id != &"" and catalog.character(effect.character_id) == null:
				bundle.errors.append("event.json: node %s affects unknown character %s" % [node.id, effect.character_id])
			if effect.source_character_id != &"" and catalog.character(effect.source_character_id) == null:
				bundle.errors.append("event.json: node %s uses unknown rumor source %s" % [node.id, effect.source_character_id])
		if node.minigame_id != &"":
			var expected_prefix := "mini"
			if node.type == &"start_danmaku":
				expected_prefix = "danmaku"
			elif node.type == &"start_duel":
				expected_prefix = "duel"
			if not _valid_namespaced_id(node.minigame_id, expected_prefix):
				bundle.errors.append("event.json: node %s has invalid %s ID %s" % [node.id, expected_prefix, node.minigame_id])
		if node.item_id != &"" and not _valid_namespaced_id(node.item_id, "item"):
			bundle.errors.append("event.json: node %s has invalid item ID %s" % [node.id, node.item_id])
		if node.journal_entry_id != &"" and not _valid_namespaced_id(node.journal_entry_id, "journal"):
			bundle.errors.append("event.json: node %s has invalid journal ID %s" % [node.id, node.journal_entry_id])


func _validate_string_reference(key: StringName, owner: String, known: Array[StringName], errors: Array[String]) -> void:
	if key == &"" or key not in known:
		errors.append("%s references missing string %s" % [owner, key])


func _append_preview_node(
	node_id: StringName,
	bundle: EventAuthoringBundle,
	locale: StringName,
	visited: Array[StringName],
	lines: PackedStringArray
) -> void:
	if node_id in visited:
		lines.append("- `%s` rejoins an earlier branch." % node_id)
		return
	var node := bundle.graph.node(node_id)
	if node == null:
		return
	visited.append(node_id)
	lines.append("### `%s` — %s" % [node.id, node.type])
	match node.type:
		&"music_state":
			lines.append("Music state: `%s`" % node.music_state_id)
		&"exploration_objective":
			lines.append(_localized(bundle, node.objective_key, locale))
			lines.append("Objects: %s" % ", ".join(_names_to_strings(node.interactable_ids)))
		&"line":
			var beat := bundle.dialogue_beat(node.beat_id)
			lines.append("**%s** (%s): %s" % [beat.speaker_id, beat.portrait, _localized(bundle, beat.text_key, locale)])
		&"choice":
			for option: ChoiceOptionRecord in node.choice.options:
				lines.append("- **%s:** %s → `%s`" % [option.tone, _localized(bundle, option.text_key, locale), option.next_node_id])
		&"effects":
			for effect: EventEffectRecord in node.effects:
				if effect.operation == &"relationship":
					lines.append("Effect: `%s.%s` %+d" % [effect.character_id, effect.facet, effect.delta])
				elif effect.operation == &"route_stage":
					lines.append("Effect: advance `%s` to route stage `%d`" % [effect.character_id, effect.stage])
				elif effect.operation == &"add_rumor":
					lines.append("Effect: add rumor `%s` as `%s`" % [effect.rumor_id, effect.claim_key])
				else:
					lines.append("Effect: set `%s` = %s" % [effect.key, effect.boolean_value])
		&"start_minigame", &"start_danmaku", &"start_duel":
			lines.append("Mode: `%s`" % node.minigame_id)
			for branch: ModeResultBranchRecord in node.result_branches:
				lines.append("- Result **%s** → `%s`" % [branch.result_tag, branch.next_node_id])
		&"give_item":
			lines.append("Give item: `%s`" % node.item_id)
		&"journal_entry":
			lines.append("Journal entry: `%s`" % node.journal_entry_id)
		&"end_event":
			lines.append("Outcome: **%s**" % node.outcome)
	lines.append("")
	for target: StringName in node.outgoing_node_ids():
		_append_preview_node(target, bundle, locale, visited, lines)


func _localized(bundle: EventAuthoringBundle, key: StringName, locale: StringName) -> String:
	var record := bundle.localized_string(key)
	return record.resolve(locale) if record != null else "[%s]" % key


func _validate_manifest(manifest: Dictionary, path: String, errors: Array[String]) -> void:
	if manifest.is_empty():
		return
	for field: String in ["schema_version", "bundle_kind", "event_id", "source_event_id", "files"]:
		if not manifest.has(field):
			errors.append("%s: missing manifest field %s" % [path, field])
	if int(manifest.get("schema_version", 0)) != 1:
		errors.append("%s: unsupported schema_version" % path)
	if String(manifest.get("bundle_kind", "")) != "event_authoring_draft":
		errors.append("%s: unsupported bundle_kind" % path)
	if not _valid_event_id(StringName(String(manifest.get("event_id", "")))):
		errors.append("%s: invalid event_id" % path)
	var files: Variant = manifest.get("files", [])
	if not files is Array or files != [EVENT_FILE, DIALOGUE_FILE, STRINGS_FILE]:
		errors.append("%s: files must list event.json, dialogue.json, and strings.csv" % path)


func _valid_event_id(event_id: StringName) -> bool:
	return RegEx.create_from_string("^evt\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)+$").search(String(event_id)) != null


func _valid_namespaced_id(stable_id: StringName, prefix: String) -> bool:
	var pattern := "^%s\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$" % prefix
	return RegEx.create_from_string(pattern).search(String(stable_id)) != null


func _referenced_values(value: Variant, field: String) -> Array[String]:
	var result: Array[String] = []
	_collect_field_values(value, field, result)
	result.sort()
	return result


func _collect_field_values(value: Variant, field: String, result: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			if String(key) == field:
				_retain_unique(result, String(value[key]))
			else:
				_collect_field_values(value[key], field, result)
	elif value is Array:
		for child: Variant in value:
			_collect_field_values(child, field, result)


func _referenced_graph_string_keys(event_data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for field: String in ["title_key", "objective_key", "text_key", "unavailable_reason_key"]:
		_collect_field_values(event_data, field, result)
	result.sort()
	return result


func _retain_unique(values: Array[String], value: String) -> void:
	if not value.is_empty() and value not in values:
		values.append(value)


func _remap_localization_key(old_key: String, source_scope: String, new_scope: String) -> String:
	if old_key.contains(source_scope):
		return old_key.replace(source_scope, new_scope)
	var parts := old_key.split(".")
	if parts.size() >= 3:
		return "%s.%s.%s" % [parts[0], new_scope, ".".join(parts.slice(2))]
	return "%s.%s" % [old_key, new_scope]


func _remap_value(value: Variant, source_scope: String, new_scope: String, key_map: Dictionary) -> Variant:
	if value is Dictionary:
		var mapped: Dictionary = {}
		for key: Variant in value:
			mapped[key] = _remap_value(value[key], source_scope, new_scope, key_map)
		return mapped
	if value is Array:
		var mapped_array: Array = []
		for child: Variant in value:
			mapped_array.append(_remap_value(child, source_scope, new_scope, key_map))
		return mapped_array
	if value is String:
		if key_map.has(value):
			return key_map[value]
		return value.replace(source_scope, new_scope)
	return value


func _load_json_dictionary(path: String, errors: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("missing JSON file: %s" % path)
		return {}
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK or not json.data is Dictionary:
		errors.append("invalid JSON object %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	return json.data


func _load_csv(path: String, errors: Array[String]) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("could not open CSV: %s" % path)
		return rows
	var header := file.get_csv_line()
	if not header.is_empty():
		header[0] = header[0].trim_prefix("\ufeff")
	if header != PackedStringArray(["key", "context", "speaker", "en", "ja", "max_width_px", "origin"]):
		errors.append("unexpected localization CSV header: %s" % path)
		return rows
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].is_empty():
			continue
		if row.size() != header.size():
			errors.append("incomplete localization CSV row in %s" % path)
			continue
		rows.append(row)
	return rows


func _write_json(path: String, data: Variant, errors: Array[String]) -> void:
	_write_text(path, JSON.stringify(data, "  ", false) + "\n", errors)


func _write_csv(path: String, rows: Array[PackedStringArray], errors: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		errors.append("could not write CSV: %s" % path)
		return
	file.store_csv_line(PackedStringArray(["key", "context", "speaker", "en", "ja", "max_width_px", "origin"]))
	for row: PackedStringArray in rows:
		file.store_csv_line(row)


func _write_text(path: String, contents: String, errors: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		errors.append("could not prepare directory for %s: error %d" % [path, directory_error])
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		errors.append("could not write file: %s" % path)
		return
	file.store_string(contents)


func _join(base_path: String, file_name: String) -> String:
	return base_path.path_join(file_name)


func _names_to_strings(values: Array[StringName]) -> PackedStringArray:
	var result := PackedStringArray()
	for value: StringName in values:
		result.append(String(value))
	return result
