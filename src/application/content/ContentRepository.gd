class_name ContentRepository
extends RefCounted
## Atomic typed content snapshot, deterministic queries, references, graph, and hash.

const RUNTIME_INDEX_SCHEMA := "gmh-runtime-content-index-v1"

var report: ContentLoadReport
var manifest: ContentManifestRecord
var event_graph: EventGraphRecord
var dependency_graph := ContentDependencyGraph.new()

var _characters: Dictionary[StringName, CharacterRecord] = {}
var _locations: Dictionary[StringName, LocationRecord] = {}
var _events: Dictionary[StringName, EventIndexRecord] = {}
var _dialogue_beats: Dictionary[StringName, DialogueBeatRecord] = {}
var _strings: Dictionary[StringName, ContentStringRecord] = {}
var _music_cues: Dictionary[StringName, MusicCueRecord] = {}
var _deferred: Dictionary[StringName, DeferredReferenceRecord] = {}
var _global_id_sources: Dictionary[StringName, String] = {}


func load_sources(sources: ContentSourceSet = null) -> ContentLoadReport:
	var active_sources := sources if sources != null else ContentSourceSet.new()
	_reset()
	var parser := ContentFileParser.new(report)
	manifest = parser.parse_manifest(active_sources.manifest_path)
	var characters := parser.parse_characters(
		active_sources.characters_path,
		active_sources.character_schema_path
	)
	for path: String in active_sources.supplemental_character_paths:
		characters.append_array(parser.parse_characters(path, active_sources.character_schema_path))
	var locations := parser.parse_locations(
		active_sources.locations_path,
		active_sources.location_schema_path
	)
	for path: String in active_sources.supplemental_location_paths:
		locations.append_array(parser.parse_locations(path, active_sources.location_schema_path))
	var events := parser.parse_events(active_sources.events_path, active_sources.event_schema_path)
	for path: String in active_sources.supplemental_event_paths:
		events.append_array(parser.parse_events(path, active_sources.event_schema_path))
	var dialogue := parser.parse_dialogue(
		active_sources.dialogue_path,
		active_sources.dialogue_schema_path
	)
	for path: String in active_sources.supplemental_dialogue_paths:
		dialogue.append_array(parser.parse_dialogue(path, active_sources.dialogue_schema_path))
	var strings := parser.parse_localization(active_sources.localization_path)
	for path: String in active_sources.supplemental_localization_paths:
		strings.append_array(parser.parse_localization(path))
	strings.append_array(
		parser.parse_ui_localization(
			active_sources.ui_localization_path,
			active_sources.ui_localization_schema_path
		)
	)
	for path: String in active_sources.supplemental_ui_localization_paths:
		strings.append_array(parser.parse_ui_localization(path, active_sources.ui_localization_schema_path))
	var music_cues := parser.parse_music_cues(active_sources.music_cues_path)
	for path: String in active_sources.supplemental_music_cue_paths:
		music_cues.append_array(parser.parse_music_cues(path))
	var deferred := parser.parse_deferred_references(active_sources.deferred_references_path)
	for path: String in active_sources.supplemental_deferred_reference_paths:
		deferred.append_array(parser.parse_deferred_references(path))
	event_graph = parser.parse_event_graph(
		active_sources.event_graph_path,
		active_sources.event_graph_schema_path
	)
	report.content_revision = manifest.content_revision
	report.content_hash = ContentHashBuilder.new().compute(active_sources.content_paths(), report)
	_index_records(
		characters,
		locations,
		events,
		dialogue,
		strings,
		music_cues,
		deferred,
		active_sources
	)
	_validate_manifest_counts(active_sources)
	_validate_references(active_sources)
	_finalize_counts()
	report.add_note(&"complete", "ContentRepository", diagnostic_header())
	return report


func character(character_id: StringName) -> CharacterRecord:
	return _characters.get(character_id)


func location(location_id: StringName) -> LocationRecord:
	return _locations.get(location_id)


func event(event_id: StringName) -> EventIndexRecord:
	return _events.get(event_id)


func dialogue_beat(beat_id: StringName) -> DialogueBeatRecord:
	return _dialogue_beats.get(beat_id)


func music_cue(cue_id: StringName) -> MusicCueRecord:
	return _music_cues.get(cue_id)


func localized_string(key: StringName) -> ContentStringRecord:
	return _strings.get(key)


func graph(graph_id: StringName) -> EventGraphRecord:
	return event_graph if event_graph != null and event_graph.id == graph_id else null


func choice(choice_id: StringName) -> ChoiceRecord:
	if event_graph == null:
		return null
	for node: EventNodeRecord in event_graph.nodes:
		if node.choice != null and node.choice.id == choice_id:
			return node.choice
	return null


func all_characters() -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	for record: CharacterRecord in _characters.values():
		result.append(record)
	result.sort_custom(_character_less)
	return result


func all_locations() -> Array[LocationRecord]:
	var result: Array[LocationRecord] = []
	for record: LocationRecord in _locations.values():
		result.append(record)
	result.sort_custom(_location_less)
	return result


func all_events() -> Array[EventIndexRecord]:
	var result: Array[EventIndexRecord] = []
	for record: EventIndexRecord in _events.values():
		result.append(record)
	result.sort_custom(_event_less)
	return result


func all_dialogue_beats() -> Array[DialogueBeatRecord]:
	var result: Array[DialogueBeatRecord] = []
	for record: DialogueBeatRecord in _dialogue_beats.values():
		result.append(record)
	result.sort_custom(_dialogue_less)
	return result


func all_music_cues() -> Array[MusicCueRecord]:
	var result: Array[MusicCueRecord] = []
	for record: MusicCueRecord in _music_cues.values():
		result.append(record)
	result.sort_custom(_music_less)
	return result


func all_localization() -> Array[ContentStringRecord]:
	var result: Array[ContentStringRecord] = []
	for record: ContentStringRecord in _strings.values():
		result.append(record)
	result.sort_custom(_string_less)
	return result


func characters_by_tag(tag: StringName) -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	for record: CharacterRecord in _characters.values():
		if tag in record.tags:
			result.append(record)
	result.sort_custom(_character_less)
	return result


func characters_by_region(region: String) -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	var needle := region.strip_edges().to_lower()
	for record: CharacterRecord in _characters.values():
		if not needle.is_empty() and record.faction_region.to_lower().contains(needle):
			result.append(record)
	result.sort_custom(_character_less)
	return result


func characters_by_route_depth(route_depth: StringName) -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	for record: CharacterRecord in _characters.values():
		if record.route_depth == route_depth:
			result.append(record)
	result.sort_custom(_character_less)
	return result


func locations_by_launch_tier(launch_tier: StringName) -> Array[LocationRecord]:
	var result: Array[LocationRecord] = []
	for record: LocationRecord in _locations.values():
		if record.launch_tier == launch_tier:
			result.append(record)
	result.sort_custom(_location_less)
	return result


func events_by_location(location_id: StringName) -> Array[EventIndexRecord]:
	var result: Array[EventIndexRecord] = []
	for record: EventIndexRecord in _events.values():
		if record.location_id == location_id:
			result.append(record)
	result.sort_custom(_event_less)
	return result


func events_by_mode(primary_mode: StringName) -> Array[EventIndexRecord]:
	var result: Array[EventIndexRecord] = []
	for record: EventIndexRecord in _events.values():
		if record.primary_mode == primary_mode:
			result.append(record)
	result.sort_custom(_event_less)
	return result


func events_by_comfort_tag(tag: StringName) -> Array[EventIndexRecord]:
	var result: Array[EventIndexRecord] = []
	for record: EventIndexRecord in _events.values():
		if tag in record.comfort_tags:
			result.append(record)
	result.sort_custom(_event_less)
	return result


func dialogue_by_speaker(character_id: StringName) -> Array[DialogueBeatRecord]:
	var result: Array[DialogueBeatRecord] = []
	for record: DialogueBeatRecord in _dialogue_beats.values():
		if record.speaker_id == character_id:
			result.append(record)
	result.sort_custom(_dialogue_less)
	return result


func music_by_section(section: StringName) -> Array[MusicCueRecord]:
	var result: Array[MusicCueRecord] = []
	for record: MusicCueRecord in _music_cues.values():
		if record.section == section:
			result.append(record)
	result.sort_custom(_music_less)
	return result


func music_by_priority(priority: StringName) -> Array[MusicCueRecord]:
	var result: Array[MusicCueRecord] = []
	for record: MusicCueRecord in _music_cues.values():
		if record.priority == priority:
			result.append(record)
	result.sort_custom(_music_less)
	return result


func diagnostic_header() -> String:
	return "content_revision=%s content_hash=%s" % [report.content_revision, report.content_hash]


func replay_header() -> ContentReplayHeaderRecord:
	return ContentReplayHeaderRecord.new(report.content_revision, report.content_hash)


func runtime_index_json() -> String:
	# Dictionaries exist only as a transient serialization value and are never retained.
	var dependency_records: Array[Dictionary] = []
	for edge: ContentDependencyEdge in dependency_graph.edges():
		dependency_records.append(
			{
				"source": String(edge.source_id),
				"target": String(edge.target_id),
				"kind": String(edge.kind),
			}
		)
	var data := {
		"schema": RUNTIME_INDEX_SCHEMA,
		"content_revision": String(report.content_revision),
		"content_hash": report.content_hash,
		"counts": {
			"characters": _characters.size(),
			"locations": _locations.size(),
			"events": _events.size(),
			"dialogue_beats": _dialogue_beats.size(),
			"localization": _strings.size(),
			"music_cues": _music_cues.size(),
			"event_nodes": event_graph.nodes.size() if event_graph != null else 0,
		},
		"ids": {
			"characters": _string_ids(_characters.keys()),
			"locations": _string_ids(_locations.keys()),
			"events": _string_ids(_events.keys()),
			"dialogue_beats": _string_ids(_dialogue_beats.keys()),
			"localization": _string_ids(_strings.keys()),
			"music_cues": _string_ids(_music_cues.keys()),
		},
		"dependencies": dependency_records,
	}
	return JSON.stringify(data, "  ", false) + "\n"


func write_runtime_index(path: String) -> Error:
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		return directory_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(runtime_index_json())
	return OK


func runtime_index_matches(path: String) -> bool:
	return FileAccess.file_exists(path) and FileAccess.get_file_as_string(path) == runtime_index_json()


func _reset() -> void:
	report = ContentLoadReport.new()
	manifest = null
	event_graph = null
	dependency_graph = ContentDependencyGraph.new()
	_characters.clear()
	_locations.clear()
	_events.clear()
	_dialogue_beats.clear()
	_strings.clear()
	_music_cues.clear()
	_deferred.clear()
	_global_id_sources.clear()


func _index_records(
	characters: Array[CharacterRecord],
	locations: Array[LocationRecord],
	events: Array[EventIndexRecord],
	dialogue: Array[DialogueBeatRecord],
	strings: Array[ContentStringRecord],
	music_cues: Array[MusicCueRecord],
	deferred: Array[DeferredReferenceRecord],
	sources: ContentSourceSet
) -> void:
	for record: CharacterRecord in characters:
		var source_path := _source(record.source_path, sources.characters_path)
		_validate_id(record.id, "^char\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$", source_path)
		_register(record.id, source_path, _characters, record)
		if record.display_name_en.is_empty() or record.slug == &"":
			report.add_error(&"rules", source_path, "character requires slug and English display name", record.id)
		if record.route_depth not in [&"deep", &"support"]:
			report.add_error(&"rules", source_path, "unsupported route depth: %s" % record.route_depth, record.id)
		if record.skills_document.is_empty() or not FileAccess.file_exists(record.skills_document):
			report.add_error(&"rules", source_path, "skills document is missing: %s" % record.skills_document, record.id)
		record.tags.sort_custom(_string_name_less)
		report.record_check(&"rules", 3)
	for record: LocationRecord in locations:
		var source_path := _source(record.source_path, sources.locations_path)
		_validate_id(record.id, "^loc\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$", source_path)
		_register(record.id, source_path, _locations, record)
		if record.display_name_en.is_empty() or record.thesis.is_empty():
			report.add_error(&"rules", source_path, "location requires English display name and thesis", record.id)
		if record.bible_path.is_empty() or not FileAccess.file_exists(record.bible_path):
			report.add_error(&"rules", source_path, "location bible is missing: %s" % record.bible_path, record.id)
		if record.map_position.x < 0 or record.map_position.x >= 320 or record.map_position.y < 0 or record.map_position.y >= 180:
			report.add_error(&"rules", source_path, "map position is outside 320x180", record.id)
		report.record_check(&"rules", 3)
	for record: EventIndexRecord in events:
		var source_path := _source(record.source_path, sources.events_path)
		_validate_id(record.id, "^evt\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$", source_path)
		_register(record.id, source_path, _events, record)
		if record.title_en.is_empty() or record.primary_mode == &"" or record.status == &"":
			report.add_error(&"rules", source_path, "event index record is incomplete", record.id)
		if record.estimated_minutes < 1:
			report.add_error(&"rules", source_path, "estimated_minutes must be positive", record.id)
		report.record_check(&"rules", 2)
	for record: DialogueBeatRecord in dialogue:
		var source_path := _source(record.source_path, sources.dialogue_path)
		_validate_id(record.id, "^beat\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$", source_path)
		_register(record.id, source_path, _dialogue_beats, record)
		if record.advance_policy not in [&"input", &"auto", &"instant"]:
			report.add_error(&"rules", source_path, "unsupported advance policy", record.id)
		report.record_check(&"rules")
	for record: ContentStringRecord in strings:
		var source_path := _source(record.source_path, sources.localization_path)
		_validate_id(record.key, "^[a-z][a-z0-9_]*(?:\\.[a-z0-9_]+)+$", source_path)
		_register(record.key, source_path, _strings, record)
		if record.english.is_empty() or record.japanese.is_empty():
			report.add_error(&"rules", source_path, "localization must be bilingual", record.key)
		report.record_check(&"rules")
	for record: MusicCueRecord in music_cues:
		var source_path := _source(record.source_path, sources.music_cues_path)
		_validate_id(record.id, "^mus_[a-z0-9_]+$", source_path)
		_register(record.id, source_path, _music_cues, record)
		if record.priority not in [&"A", &"B", &"C"]:
			report.add_error(&"rules", source_path, "music priority must be A, B, or C", record.id)
		report.record_check(&"rules")
	for record: DeferredReferenceRecord in deferred:
		var source_path := _source(record.source_path, sources.deferred_references_path)
		if record.id == &"":
			report.add_error(&"rules", source_path, "deferred reference has an empty ID")
		elif _deferred.has(record.id):
			report.add_error(&"rules", source_path, "duplicate deferred reference", record.id)
		else:
			_deferred[record.id] = record
		report.record_check(&"rules")


func _register(stable_id: StringName, source: String, registry: Dictionary, record: RefCounted) -> void:
	if stable_id == &"":
		report.add_error(&"rules", source, "record has an empty stable ID")
		return
	if registry.has(stable_id) or _global_id_sources.has(stable_id):
		report.add_error(&"rules", source, "duplicate stable ID; first seen in %s" % _global_id_sources.get(stable_id, source), stable_id)
		return
	registry[stable_id] = record
	_global_id_sources[stable_id] = source
	dependency_graph.add_node(stable_id)


func _validate_id(stable_id: StringName, pattern: String, source: String) -> void:
	var expression := RegEx.create_from_string(pattern)
	if expression.search(String(stable_id)) == null:
		report.add_error(&"rules", source, "invalid stable ID format", stable_id)
	report.record_check(&"rules")


func _validate_manifest_counts(sources: ContentSourceSet) -> void:
	if not sources.enforce_manifest_counts or manifest == null:
		return
	_check_count("characters", _characters.size(), manifest.expected_characters, sources.manifest_path)
	_check_count("locations", _locations.size(), manifest.expected_locations, sources.manifest_path)
	_check_count("events", _events.size(), manifest.expected_events, sources.manifest_path)
	var authored_string_count := 0
	for record: ContentStringRecord in _strings.values():
		if record.context != &"ui":
			authored_string_count += 1
	_check_count("localization rows", authored_string_count, manifest.expected_localization_rows, sources.manifest_path)
	_check_count("music cues", _music_cues.size(), 89, sources.music_cues_path)


func _check_count(label: String, actual: int, expected: int, source: String) -> void:
	report.record_check(&"manifest")
	if actual != expected:
		report.add_error(&"manifest", source, "%s expected %d, found %d" % [label, expected, actual])


func _validate_references(sources: ContentSourceSet) -> void:
	for event_record: EventIndexRecord in _events.values():
		var source_path := _source(event_record.source_path, sources.events_path)
		_require_known(event_record.id, event_record.location_id, _locations.has(event_record.location_id), &"location", source_path)
		for character_id: StringName in event_record.lead_character_ids:
			_require_known(event_record.id, character_id, _characters.has(character_id), &"lead_character", source_path)
	for beat: DialogueBeatRecord in _dialogue_beats.values():
		var source_path := _source(beat.source_path, sources.dialogue_path)
		_require_known(beat.id, beat.speaker_id, _characters.has(beat.speaker_id), &"speaker", source_path)
		_require_known(beat.id, beat.text_key, _strings.has(beat.text_key), &"localization", source_path)
	if event_graph == null:
		return
	var graph_source := _source(event_graph.source_path, sources.event_graph_path)
	_require_known(event_graph.id, event_graph.id, _events.has(event_graph.id), &"event_index", graph_source)
	_require_known(event_graph.id, event_graph.location_id, _locations.has(event_graph.location_id), &"location", graph_source)
	_require_known(event_graph.id, event_graph.title_key, _strings.has(event_graph.title_key), &"localization", graph_source)
	_require_deferred(event_graph.id, event_graph.spot_id, &"spot", graph_source)
	for character_id: StringName in event_graph.cast:
		_require_known(event_graph.id, character_id, _characters.has(character_id), &"cast", graph_source)
	var node_ids: Array[StringName] = []
	for node: EventNodeRecord in event_graph.nodes:
		node_ids.append(node.id)
		dependency_graph.add_node(_node_graph_id(node.id))
	if event_graph.entry_node_id not in node_ids:
		report.add_error(&"references", graph_source, "entry node is missing", event_graph.id)
	for node: EventNodeRecord in event_graph.nodes:
		_validate_event_node(node, node_ids, graph_source)
	_validate_graph_reachability(node_ids, graph_source)
	for error: String in EventGraphValidator.new().validate(event_graph):
		report.add_error(&"rules", graph_source, error, event_graph.id)


func _validate_event_node(node: EventNodeRecord, node_ids: Array[StringName], source: String) -> void:
	var owner := _node_graph_id(node.id)
	for target: StringName in node.outgoing_node_ids():
		_require_known(owner, _node_graph_id(target), target in node_ids, &"event_edge", source)
	if node.music_state_id != &"":
		_require_known(owner, node.music_state_id, _music_cues.has(node.music_state_id), &"music", source)
	if node.objective_key != &"":
		_require_known(owner, node.objective_key, _strings.has(node.objective_key), &"localization", source)
	for interactable_id: StringName in node.interactable_ids:
		_require_deferred(owner, interactable_id, &"interactable", source)
	if node.beat_id != &"":
		_require_known(owner, node.beat_id, _dialogue_beats.has(node.beat_id), &"dialogue_beat", source)
	if node.choice != null:
		_validate_id(node.choice.id, "^choice\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$", source)
		dependency_graph.add_edge(owner, node.choice.id, &"choice")
		for option: ChoiceOptionRecord in node.choice.options:
			_require_known(node.choice.id, option.text_key, _strings.has(option.text_key), &"localization", source)
	for effect: EventEffectRecord in node.effects:
		if effect.character_id != &"":
			_require_known(owner, effect.character_id, _characters.has(effect.character_id), &"effect_character", source)
	if node.minigame_id != &"":
		_require_deferred(owner, node.minigame_id, &"minigame", source)
	if node.item_id != &"":
		_require_deferred(owner, node.item_id, &"item", source)
	if node.journal_entry_id != &"":
		_require_deferred(owner, node.journal_entry_id, &"journal_entry", source)


func _validate_graph_reachability(node_ids: Array[StringName], source: String) -> void:
	var reachable: Array[StringName] = []
	var pending: Array[StringName] = [event_graph.entry_node_id]
	while not pending.is_empty():
		var current: StringName = pending.pop_back()
		if current in reachable or current not in node_ids:
			continue
		reachable.append(current)
		var node := event_graph.node(current)
		if node != null:
			pending.append_array(node.outgoing_node_ids())
	for node_id: StringName in node_ids:
		if node_id not in reachable:
			report.add_error(&"references", source, "unreachable event node: %s" % node_id, event_graph.id)
	report.record_check(&"references", node_ids.size())


func _require_known(
	owner_id: StringName,
	target_id: StringName,
	is_known: bool,
	kind: StringName,
	source: String
) -> void:
	report.record_check(&"references")
	if target_id == &"" or not is_known:
		report.add_error(&"references", source, "unknown %s reference: %s" % [kind, target_id], owner_id)
		return
	dependency_graph.add_edge(owner_id, target_id, kind)


func _require_deferred(
	owner_id: StringName,
	target_id: StringName,
	kind: StringName,
	source: String
) -> void:
	report.record_check(&"references")
	var deferred_record: DeferredReferenceRecord = _deferred.get(target_id)
	if target_id == &"" or deferred_record == null:
		report.add_error(&"references", source, "unresolved %s reference without allowlist entry: %s" % [kind, target_id], owner_id)
	elif deferred_record.kind != kind:
		report.add_error(&"references", source, "deferred kind for %s is %s, expected %s" % [target_id, deferred_record.kind, kind], owner_id)
	else:
		dependency_graph.add_edge(owner_id, target_id, kind)


func _node_graph_id(node_id: StringName) -> StringName:
	return StringName("%s.node.%s" % [event_graph.id, node_id])


func _source(authored_path: String, fallback_path: String) -> String:
	return authored_path if not authored_path.is_empty() else fallback_path


func _finalize_counts() -> void:
	report.character_count = _characters.size()
	report.location_count = _locations.size()
	report.event_count = _events.size()
	report.dialogue_count = _dialogue_beats.size()
	report.localization_count = _strings.size()
	report.music_cue_count = _music_cues.size()
	report.event_node_count = event_graph.nodes.size() if event_graph != null else 0


func _string_ids(ids: Array) -> Array[String]:
	var result: Array[String] = []
	for stable_id: Variant in ids:
		result.append(String(stable_id))
	result.sort()
	return result


func _character_less(left: CharacterRecord, right: CharacterRecord) -> bool:
	return String(left.id) < String(right.id)


func _location_less(left: LocationRecord, right: LocationRecord) -> bool:
	return String(left.id) < String(right.id)


func _event_less(left: EventIndexRecord, right: EventIndexRecord) -> bool:
	return String(left.id) < String(right.id)


func _dialogue_less(left: DialogueBeatRecord, right: DialogueBeatRecord) -> bool:
	return String(left.id) < String(right.id)


func _music_less(left: MusicCueRecord, right: MusicCueRecord) -> bool:
	return String(left.id) < String(right.id)


func _string_less(left: ContentStringRecord, right: ContentStringRecord) -> bool:
	return String(left.key) < String(right.key)


func _string_name_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
