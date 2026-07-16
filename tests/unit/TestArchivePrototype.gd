class_name TestArchivePrototype
extends RefCounted
## Recorded-strategy composition and fair familiar-lane removal contracts.

const PATTERN_PATH := "res://content/danmaku/archive_margin_of_error.json"
const SCHEMA_PATH := "res://schemas/danmaku_pattern.schema.json"


func run() -> Array[String]:
	var failures: Array[String] = []
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATTERN_PATH))
	var schema: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCHEMA_PATH))
	var schema_errors := JsonSchemaValidator.new().validate(raw, schema)
	if not schema_errors.is_empty():
		return ["Archive pattern failed its schema: %s" % schema_errors]
	var loader := DanmakuPatternLoader.new()
	var definition := loader.load_path(PATTERN_PATH)
	if definition == null or not loader.errors.is_empty():
		return ["Archive pattern could not load: %s" % loader.errors]

	var strategies: Array[StringName] = [&"strategy.photo_frame", &"strategy.neutral_guard"]
	definition = ArchivePatternComposer.compose(definition, strategies)
	if (
		definition.phases[0].safe_lane != 4
		or definition.phases[1].safe_lane != 7
		or definition.phases[2].safe_lane != 7
	):
		failures.append("Archive composer did not derive familiar and secondary lanes from ranked strategies")
	if ArchivePatternComposer.teaching_key(strategies[0]) != &"ui.archive.teach.photo_frame":
		failures.append("Archive composer did not disclose the indexed photo-frame habit")
	if ArchivePatternComposer.strategies_for_state(null) != [&"strategy.unrecorded_gap"]:
		failures.append("Archive composer omitted its no-history fallback")

	var assists := DanmakuAssistSettings.new()
	assists.safe_lane_preview = true
	var simulation := DanmakuSimulationRegistry.new().create(&"archive_adaptive")
	if not simulation is ArchiveAdaptiveSimulation or not simulation.configure(
		definition,
		_context(),
		assists,
		512
	):
		failures.append("Archive simulation registry rejected the composed pattern")
		return failures
	var archive := simulation as ArchiveAdaptiveSimulation
	archive._enter_phase(2)
	var phase := archive.current_phase()
	var familiar := phase.emitters[0]
	archive.state.phase_tick = phase.transform_tick - 1
	if archive.safe_lane_preview() != 7 or archive.familiar_lane_removed():
		failures.append("Archive removed the familiar guide before the authored transform cue")
	archive.pool.clear(true)
	archive._emit_volley(familiar, 3)
	var familiar_spawn_count := archive.pool.active_count
	archive.pool.clear(true)
	archive.state.phase_tick = phase.transform_tick
	if archive.safe_lane_preview() != -1 or not archive.familiar_lane_removed():
		failures.append("Archive retained the familiar guide after the transform cue")
	archive._emit_volley(familiar, 4)
	if familiar_spawn_count != familiar.slot_count - 1 or archive.pool.active_count != familiar.slot_count:
		failures.append("Archive did not fill exactly the formerly safe lane after its guide vanished")
	if familiar.telegraph_ticks < 42 or familiar.start_tick + familiar.interval_ticks * 4 <= phase.transform_tick:
		failures.append("Archive's first filled-lane volley lacks a fair post-transform telegraph window")
	var accepted := archive.accept_loss()
	if accepted == null or &"archive.familiar_lane_removed" not in accepted.outcome_tags:
		failures.append("Archive result omitted its stable mechanic evidence")

	if EventModeSceneRegistry.new().scene_for(&"danmaku.fin.margin_of_error") == null:
		failures.append("event mode registry omitted the playable Archive prototype")
	return failures


func _context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_danmaku"
	context.mode_id = &"danmaku.fin.margin_of_error"
	context.event_id = &"evt.fin.margin_of_error"
	context.node_id = &"n_danmaku"
	context.deterministic_seed = 131313
	return context
