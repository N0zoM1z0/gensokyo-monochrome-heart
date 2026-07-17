extends Node
## Owns one validated typed snapshot and swaps it atomically during safe dev hot reloads.

signal content_loaded(report: ContentLoadReport)
signal content_reloaded(previous_report: ContentLoadReport, report: ContentLoadReport)
signal content_failed(report: ContentLoadReport)
signal hot_reload_deferred(active_mode_id: StringName)

const RUNTIME_CACHE_PATH := "user://content/runtime_content_index.json"
const HOT_RELOAD_INTERVAL_SECONDS := 0.75
const COMBAT_MODE_IDS: Array[StringName] = [
	&"combat",
	&"danmaku",
	&"danmaku_mode",
	&"duel",
	&"fighter",
	&"fighter_mode",
]

var runtime_cache_path: String = RUNTIME_CACHE_PATH
var write_runtime_cache: bool = true

var _repository: ContentRepository
var _last_report: ContentLoadReport
var _sources := ContentSourceSet.new()
var _observed_hash: String = ""
var _active_mode_id: StringName = &"boot"
var _poll_elapsed: float = 0.0
var _reload_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _last_report == null:
		initialize()
	set_process(BuildChannel.current() == BuildChannel.Kind.DEV)


func _process(delta: float) -> void:
	_poll_elapsed += delta
	if _poll_elapsed < HOT_RELOAD_INTERVAL_SECONDS:
		return
	_poll_elapsed = 0.0
	check_for_source_changes()


func initialize(sources: ContentSourceSet = null) -> bool:
	if sources != null:
		_sources = sources
	var candidate := ContentRepository.new()
	var candidate_report := candidate.load_sources(_sources)
	_last_report = candidate_report
	_observed_hash = candidate_report.content_hash
	if not candidate_report.is_success():
		_report_failure(candidate_report)
		return false
	var previous_report: ContentLoadReport = _repository.report if _repository != null else null
	_repository = candidate
	_reload_pending = false
	_write_cache(candidate)
	_refresh_localization_if_needed(previous_report)
	if previous_report == null:
		content_loaded.emit(candidate_report)
	else:
		content_reloaded.emit(previous_report, candidate_report)
	if is_inside_tree():
		print(candidate_report.summary_line())
	return true


func reload_now() -> bool:
	if is_combat_mode(_active_mode_id):
		_defer_hot_reload()
		return false
	return initialize(_sources)


func check_for_source_changes() -> bool:
	var current_hash := ContentHashBuilder.new().compute(_sources.content_paths())
	if current_hash == _observed_hash:
		return false
	if is_combat_mode(_active_mode_id):
		_defer_hot_reload()
		return false
	return initialize(_sources)


func set_active_mode(mode_id: StringName) -> void:
	_active_mode_id = mode_id
	if _reload_pending and not is_combat_mode(_active_mode_id):
		_reload_pending = false
		initialize(_sources)


func active_mode() -> StringName:
	return _active_mode_id


func has_pending_hot_reload() -> bool:
	return _reload_pending


func is_combat_mode(mode_id: StringName) -> bool:
	return mode_id in COMBAT_MODE_IDS or String(mode_id).begins_with("danmaku.") or String(mode_id).begins_with("fighter.")


func is_loaded() -> bool:
	return _repository != null and _repository.report.is_success()


func snapshot() -> ContentRepository:
	return _repository


func last_report() -> ContentLoadReport:
	return _last_report


func current_report() -> ContentLoadReport:
	return _repository.report if _repository != null else null


func content_revision() -> StringName:
	return _repository.report.content_revision if _repository != null else &"unknown"


func content_hash() -> String:
	return _repository.report.content_hash if _repository != null else ""


func diagnostic_header() -> String:
	if _repository != null:
		return _repository.diagnostic_header()
	return "content_revision=unknown content_hash="


func replay_header() -> ContentReplayHeaderRecord:
	if _repository != null:
		return _repository.replay_header()
	return ContentReplayHeaderRecord.new(&"unknown", "")


func character(character_id: StringName) -> CharacterRecord:
	return _repository.character(character_id) if _repository != null else null


func location(location_id: StringName) -> LocationRecord:
	return _repository.location(location_id) if _repository != null else null


func event(event_id: StringName) -> EventIndexRecord:
	return _repository.event(event_id) if _repository != null else null


func graph(graph_id: StringName) -> EventGraphRecord:
	return _repository.graph(graph_id) if _repository != null else null


func dialogue_beat(beat_id: StringName) -> DialogueBeatRecord:
	return _repository.dialogue_beat(beat_id) if _repository != null else null


func choice(choice_id: StringName) -> ChoiceRecord:
	return _repository.choice(choice_id) if _repository != null else null


func localized_string(key: StringName) -> ContentStringRecord:
	return _repository.localized_string(key) if _repository != null else null


func music_cue(cue_id: StringName) -> MusicCueRecord:
	return _repository.music_cue(cue_id) if _repository != null else null


func all_characters() -> Array[CharacterRecord]:
	return _repository.all_characters() if _repository != null else []


func all_locations() -> Array[LocationRecord]:
	return _repository.all_locations() if _repository != null else []


func all_events() -> Array[EventIndexRecord]:
	return _repository.all_events() if _repository != null else []


func all_dialogue_beats() -> Array[DialogueBeatRecord]:
	return _repository.all_dialogue_beats() if _repository != null else []


func all_localization() -> Array[ContentStringRecord]:
	return _repository.all_localization() if _repository != null else []


func all_music_cues() -> Array[MusicCueRecord]:
	return _repository.all_music_cues() if _repository != null else []


func characters_by_tag(tag: StringName) -> Array[CharacterRecord]:
	return _repository.characters_by_tag(tag) if _repository != null else []


func characters_by_region(region: String) -> Array[CharacterRecord]:
	return _repository.characters_by_region(region) if _repository != null else []


func characters_by_route_depth(route_depth: StringName) -> Array[CharacterRecord]:
	return _repository.characters_by_route_depth(route_depth) if _repository != null else []


func locations_by_launch_tier(launch_tier: StringName) -> Array[LocationRecord]:
	return _repository.locations_by_launch_tier(launch_tier) if _repository != null else []


func events_by_location(location_id: StringName) -> Array[EventIndexRecord]:
	return _repository.events_by_location(location_id) if _repository != null else []


func events_by_mode(primary_mode: StringName) -> Array[EventIndexRecord]:
	return _repository.events_by_mode(primary_mode) if _repository != null else []


func events_by_comfort_tag(tag: StringName) -> Array[EventIndexRecord]:
	return _repository.events_by_comfort_tag(tag) if _repository != null else []


func dialogue_by_speaker(character_id: StringName) -> Array[DialogueBeatRecord]:
	return _repository.dialogue_by_speaker(character_id) if _repository != null else []


func music_by_section(section: StringName) -> Array[MusicCueRecord]:
	return _repository.music_by_section(section) if _repository != null else []


func music_by_priority(priority: StringName) -> Array[MusicCueRecord]:
	return _repository.music_by_priority(priority) if _repository != null else []


func postgame_framework() -> PostgameFrameworkRecord:
	return _repository.postgame_framework if _repository != null else null


func seasonal_events_by_season(season: StringName) -> Array[SeasonalEventRecord]:
	return _repository.seasonal_events_by_season(season) if _repository != null else []


func _defer_hot_reload() -> void:
	if _reload_pending:
		return
	_reload_pending = true
	hot_reload_deferred.emit(_active_mode_id)


func _write_cache(repository: ContentRepository) -> void:
	if not write_runtime_cache:
		return
	var error := repository.write_runtime_index(runtime_cache_path)
	if error != OK:
		var message := "could not write runtime content cache %s (error %d)" % [runtime_cache_path, error]
		repository.report.add_warning(&"cache", runtime_cache_path, message)
		if is_inside_tree():
			push_warning(message)


func _refresh_localization_if_needed(previous_report: ContentLoadReport) -> void:
	if previous_report == null or not is_inside_tree():
		return
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null and localization.has_method("reload_catalog"):
		localization.call("reload_catalog")


func _report_failure(report: ContentLoadReport) -> void:
	content_failed.emit(report)
	if is_inside_tree():
		push_error("ContentDB rejected authored content before presentation:\n%s" % report.human_readable())
