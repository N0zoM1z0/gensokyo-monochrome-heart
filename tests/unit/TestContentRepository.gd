class_name TestContentRepository
extends RefCounted
## M02 contract tests for typed parsing, deterministic queries, references, and cache identity.

const RUNTIME_INDEX_PATH := "res://content/indexes/runtime_content_index.json"


func run() -> Array[String]:
	var failures: Array[String] = []
	var repository := ContentRepository.new()
	var report := repository.load_sources()
	if not report.is_success():
		failures.append("reviewed typed content failed: %s" % report.human_readable())
		return failures
	_expect_counts(report, failures)
	_expect_hash_and_cache(repository, failures)
	_expect_queries(repository, failures)
	_expect_reference_graph(repository, failures)
	_expect_multiple_event_graphs(failures)
	_expect_no_authored_dictionaries(repository, failures)
	_expect_invalid_fixtures(failures)
	return failures


func _expect_counts(report: ContentLoadReport, failures: Array[String]) -> void:
	var actual := [
		report.character_count,
		report.location_count,
		report.event_count,
		report.dialogue_count,
		report.localization_count,
		report.music_cue_count,
		report.event_node_count,
	]
	var expected := [71, 19, 28, 35, 372, 89, 70]
	if actual != expected:
		failures.append("typed starter counts differ: expected %s, got %s" % [expected, actual])
	if not report.human_readable().contains("content_hash=%s" % report.content_hash):
		failures.append("human-readable report omitted the content hash")
	if report.stages.size() < 10:
		failures.append("aggregated report omitted load stages: %d" % report.stages.size())


func _expect_hash_and_cache(repository: ContentRepository, failures: Array[String]) -> void:
	var first_hash := repository.report.content_hash
	var second := ContentRepository.new()
	second.load_sources()
	if first_hash.length() != 64 or first_hash != second.report.content_hash:
		failures.append("content SHA-256 is absent or nondeterministic: %s / %s" % [first_hash, second.report.content_hash])
	if not repository.runtime_index_matches(RUNTIME_INDEX_PATH):
		failures.append("generated runtime content index is missing or stale")
	var parsed: Variant = JSON.parse_string(repository.runtime_index_json())
	var schema: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/content_runtime_index.schema.json"))
	if not parsed is Dictionary or not schema is Dictionary:
		failures.append("runtime index or schema could not be parsed")
	else:
		var schema_errors := JsonSchemaValidator.new().validate(parsed, schema)
		if not schema_errors.is_empty():
			failures.append("runtime index schema failed: %s" % "; ".join(schema_errors))
	var replay_header := repository.replay_header()
	if replay_header.content_hash != first_hash or replay_header.content_revision != &"2026.07.16.10":
		failures.append("typed replay header omitted content identity")
	if replay_header.diagnostic_header() != repository.diagnostic_header():
		failures.append("diagnostic and replay content headers diverge")


func _expect_queries(repository: ContentRepository, failures: Array[String]) -> void:
	var reimu := repository.character(&"char.reimu_hakurei")
	if reimu == null or reimu.display_name_en != "Reimu Hakurei":
		failures.append("character lookup did not return typed Reimu metadata")
	var alice := repository.character(&"char.alice_margatroid")
	if alice == null or alice.faction_region != alice.faction_region.strip_edges():
		failures.append("character parser did not normalize reviewed trailing whitespace")
	var choice := repository.choice(&"choice.hkr.empty_cushion.01")
	if choice == null or choice.options.size() != 4:
		failures.append("typed choice lookup did not expose the four authored tones")
	if repository.characters_by_route_depth(&"deep").size() != 12:
		failures.append("deep-route query expected 12 characters")
	if repository.locations_by_launch_tier(&"headline").size() != 5:
		failures.append("headline location query expected 5 records")
	if repository.events_by_mode(&"danmaku").size() != 4:
		failures.append("danmaku event query expected 4 records")
	if repository.dialogue_by_speaker(&"char.reimu_hakurei").size() != 18:
		failures.append("Reimu dialogue query expected 18 vertical-slice beats")
	if repository.dialogue_by_speaker(&"char.marisa_kirisame").size() != 1:
		failures.append("Marisa dialogue query expected the duel-introduction beat")
	if repository.music_by_priority(&"A").size() != 44:
		failures.append("priority-A music query expected 44 cues")
	if repository.music_by_section(&"system").size() != 12:
		failures.append("system music query expected 12 cues")
	if repository.characters_by_region("Scarlet Devil Mansion").is_empty():
		failures.append("case-normalized region query returned no characters")
	_assert_sorted_records(repository.all_characters(), "characters", failures)
	_assert_sorted_records(repository.all_locations(), "locations", failures)
	_assert_sorted_records(repository.all_events(), "events", failures)
	_assert_sorted_records(repository.all_dialogue_beats(), "dialogue", failures)
	_assert_sorted_records(repository.all_music_cues(), "music", failures)


func _expect_reference_graph(repository: ContentRepository, failures: Array[String]) -> void:
	var event_dependencies := repository.dependency_graph.dependencies_of(&"evt.hkr.empty_cushion")
	for expected: StringName in [&"char.reimu_hakurei", &"loc.hakurei_shrine"]:
		if expected not in event_dependencies:
			failures.append("dependency graph omitted %s from evt.hkr.empty_cushion" % expected)
	var choice_dependents := repository.dependency_graph.dependents_of(&"choice.hkr.empty_cushion.01")
	if &"evt.hkr.empty_cushion.node.n004" not in choice_dependents:
		failures.append("dependency graph omitted the typed choice owner")
	var edges := repository.dependency_graph.edges()
	var prior_key := ""
	for edge: ContentDependencyEdge in edges:
		if not prior_key.is_empty() and edge.sort_key() < prior_key:
			failures.append("dependency graph edges are not deterministically sorted")
			break
		prior_key = edge.sort_key()


func _expect_multiple_event_graphs(failures: Array[String]) -> void:
	var repository := ContentRepository.new()
	var report := repository.load_sources()
	if not report.is_success():
		failures.append("secondary event graph failed typed loading: %s" % report.human_readable())
		return
	if repository.all_event_graphs().size() != 2:
		failures.append("event graph catalog expected two records")
	var sdm := repository.graph(&"evt.sdm.late_by_three_minutes")
	if sdm == null or sdm.location_id != &"loc.scarlet_devil_mansion" or sdm.node(&"n_end") == null:
		failures.append("stable graph lookup did not expose the SDM fixture")
	if report.event_node_count != 70:
		failures.append("event node aggregate expected 70, got %d" % report.event_node_count)
	var parsed: Variant = JSON.parse_string(repository.runtime_index_json())
	if not parsed is Dictionary or int(parsed.counts.event_nodes) != 70:
		failures.append("runtime index did not aggregate multiple event graphs")


func _expect_no_authored_dictionaries(repository: ContentRepository, failures: Array[String]) -> void:
	var records: Array[RefCounted] = []
	records.append_array(repository.all_characters())
	records.append_array(repository.all_locations())
	records.append_array(repository.all_events())
	records.append_array(repository.all_dialogue_beats())
	records.append_array(repository.all_localization())
	records.append_array(repository.all_music_cues())
	records.append_array(repository.all_event_graphs())
	var visited: Dictionary[int, bool] = {}
	for record: RefCounted in records:
		_inspect_typed_record(record, visited, failures)


func _inspect_typed_record(record: RefCounted, visited: Dictionary[int, bool], failures: Array[String]) -> void:
	if record == null or visited.has(record.get_instance_id()):
		return
	visited[record.get_instance_id()] = true
	for property: Dictionary in record.get_property_list():
		if (int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var property_name := StringName(property.name)
		var value: Variant = record.get(property_name)
		if value is Dictionary:
			failures.append("typed record retained a Dictionary: %s.%s" % [record.get_class(), property_name])
		elif value is RefCounted:
			_inspect_typed_record(value, visited, failures)
		elif value is Array:
			for item: Variant in value:
				if item is RefCounted:
					_inspect_typed_record(item, visited, failures)


func _expect_invalid_fixtures(failures: Array[String]) -> void:
	var cases := [
		["supplemental_character_paths", "res://tests/fixtures/invalid/typed_content/invalid_character_id.json", "invalid stable ID format", "char.InvalidCase"],
		["supplemental_character_paths", "res://tests/fixtures/invalid/typed_content/duplicate_character_id.json", "duplicate stable ID", "char.reimu_hakurei"],
		["supplemental_event_paths", "res://tests/fixtures/invalid/typed_content/missing_event_references.json", "unknown location reference", "evt.fixture.missing_references"],
		["supplemental_dialogue_paths", "res://tests/fixtures/invalid/typed_content/missing_localization_reference.json", "unknown localization reference", "beat.fixture.missing_localization"],
	]
	for fixture: Array in cases:
		var sources := ContentSourceSet.new()
		sources.enforce_manifest_counts = false
		sources.get(fixture[0]).append(fixture[1])
		var report := ContentRepository.new().load_sources(sources)
		if report.is_success():
			failures.append("invalid fixture unexpectedly succeeded: %s" % fixture[1])
			continue
		var diagnostic_found := false
		for diagnostic: ContentDiagnostic in report.diagnostics:
			if diagnostic.source == fixture[1] and diagnostic.message.contains(fixture[2]) and diagnostic.owner_id == StringName(fixture[3]):
				diagnostic_found = true
				break
		if not diagnostic_found:
			failures.append("fixture omitted source-located diagnostic %s for %s" % [fixture[2], fixture[1]])


func _assert_sorted_records(records: Array, label: String, failures: Array[String]) -> void:
	var prior := ""
	for record: RefCounted in records:
		var record_id := String(record.get("id"))
		if not prior.is_empty() and record_id < prior:
			failures.append("%s query is not sorted: %s before %s" % [label, record_id, prior])
			return
		prior = record_id
