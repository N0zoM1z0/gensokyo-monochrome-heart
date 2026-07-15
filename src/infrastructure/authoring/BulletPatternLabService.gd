class_name BulletPatternLabService
extends RefCounted
## M11 draft, validation, report, and deterministic simulation boundary.

const TEMPLATE_PATH := "res://content/danmaku/boundary_stain.json"
const DENSITY_TIERS := [55, 70, 85, 100]


func duplicate_template(new_pattern_id: StringName, output_path: String) -> BulletPatternLabResult:
	var result := BulletPatternLabResult.new()
	result.pattern_path = output_path
	if not _valid_pattern_id(new_pattern_id):
		result.errors.append("pattern ID must match danmaku.<lowercase_namespace>: %s" % new_pattern_id)
		return result
	if output_path.strip_edges().is_empty():
		result.errors.append("output path cannot be empty")
		return result
	if FileAccess.file_exists(output_path):
		result.errors.append("output file already exists: %s" % output_path)
		return result
	var raw := _load_json(TEMPLATE_PATH, result.errors)
	if raw.is_empty():
		return result
	var new_scope := String(new_pattern_id).trim_prefix("danmaku.")
	var remapped: Variant = _remap_value(raw, new_pattern_id, new_scope)
	_write_json(output_path, remapped, result.errors)
	if not result.errors.is_empty():
		return result
	return validate_pattern(output_path)


func validate_pattern(path: String) -> BulletPatternLabResult:
	var result := BulletPatternLabResult.new()
	result.pattern_path = path
	var loader := DanmakuPatternLoader.new()
	result.definition = loader.load_path(path)
	result.errors.append_array(loader.errors)
	if result.definition == null and result.errors.is_empty():
		result.errors.append("production loader returned no pattern")
	return result


func render_report(path: String) -> BulletPatternLabResult:
	var result := validate_pattern(path)
	if not result.is_valid():
		return result
	var definition := result.definition
	var rows := PackedStringArray()
	var emitter_count := 0
	for phase_index: int in range(definition.phases.size()):
		var phase := definition.phases[phase_index]
		for emitter: DanmakuEmitterDefinition in phase.emitters:
			emitter_count += 1
			var density_counts := PackedStringArray()
			for density: int in DENSITY_TIERS:
				var slots := emitter.selected_slots(density).size()
				if emitter.pattern_type == &"safe_lane_grid" and emitter.safe_lane in emitter.selected_slots(density):
					slots -= 1
				density_counts.append("%d:%d" % [density, slots])
			rows.append("| %d | `%s` | `%s` | %d/%d/%d | %.2f | %d | %s |" % [
				phase_index + 1,
				emitter.id,
				emitter.pattern_type,
				emitter.start_tick,
				emitter.interval_ticks,
				emitter.volleys,
				emitter.speed_fp / 256.0,
				emitter.telegraph_ticks,
				" ".join(density_counts),
			])
	var lines := PackedStringArray([
		"# Bullet Pattern Lab report",
		"",
		"- Pattern: `%s`" % definition.id,
		"- Source: `%s`" % path,
		"- SHA-256: `%s`" % definition.data_hash,
		"- Arena: `%dx%d`" % [definition.arena_width, definition.arena_height],
		"- Phases: %d" % definition.phases.size(),
		"- Emitters: %d" % emitter_count,
		"",
		"| Phase | Emitter | Component | Start/interval/volleys | Speed | Telegraph | Density:slots |",
		"| ---: | --- | --- | --- | ---: | ---: | --- |",
	])
	lines.append_array(rows)
	result.output = "\n".join(lines) + "\n"
	return result


func run_simulation_smoke(path: String, density_percent: int = 100, speed_percent: int = 100) -> BulletPatternLabResult:
	var result := validate_pattern(path)
	if not result.is_valid():
		return result
	var settings := DanmakuAssistSettings.new()
	settings.story_mode = false
	settings.density_percent = density_percent
	settings.bullet_speed_percent = speed_percent
	var setting_errors := settings.validation_errors()
	if not setting_errors.is_empty():
		result.errors.append_array(setting_errors)
		return result
	var context := ModeContext.new()
	context.mode_type = &"start_danmaku"
	context.mode_id = result.definition.id
	context.event_id = &"evt.authoring.bullet_lab"
	context.node_id = &"lab_preview"
	context.deterministic_seed = 1111
	var runtime := BoundaryStainSimulation.new()
	if not runtime.configure(result.definition, context, settings, 2500):
		result.errors.append("production simulation rejected the validated pattern")
		return result
	var input := DanmakuInputFrame.new()
	var total_ticks := 0
	for phase: DanmakuPhaseDefinition in result.definition.phases:
		total_ticks += phase.duration_ticks
	var peak_active := 0
	var peak_committed := 0
	for _tick: int in range(total_ticks + 4):
		runtime.state.invulnerability_ticks = total_ticks + 60
		runtime.step(input)
		peak_active = maxi(peak_active, runtime.pool.active_count)
		peak_committed = maxi(peak_committed, runtime.pool.committed_count)
		if runtime.final_result != null:
			break
	if runtime.final_result == null or runtime.final_result.result_tag != &"clear":
		result.errors.append("simulation did not complete all phases with clear")
		return result
	result.output = "SIMULATION ticks=%d phases=%d peak_active=%d peak_committed=%d capacity=%d result=%s snapshot_sha256=%s\n" % [
		runtime.state.encounter_tick,
		result.definition.phases.size(),
		peak_active,
		peak_committed,
		runtime.pool.capacity,
		runtime.final_result.result_tag,
		runtime.canonical_snapshot().sha256_text(),
	]
	return result


func _valid_pattern_id(pattern_id: StringName) -> bool:
	return RegEx.create_from_string("^danmaku\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)+$").search(String(pattern_id)) != null


func _remap_value(value: Variant, new_pattern_id: StringName, new_scope: String) -> Variant:
	if value is Dictionary:
		var mapped: Dictionary = {}
		for key: Variant in value:
			mapped[key] = _remap_value(value[key], new_pattern_id, new_scope)
		return mapped
	if value is Array:
		var mapped_array: Array = []
		for child: Variant in value:
			mapped_array.append(_remap_value(child, new_pattern_id, new_scope))
		return mapped_array
	if value is String:
		if value == "danmaku.hkr.boundary_stain":
			return String(new_pattern_id)
		if value.begins_with("phase.boundary."):
			return "phase.%s.%s" % [new_scope, value.trim_prefix("phase.boundary.")]
		if value.begins_with("emit.boundary."):
			return "emit.%s.%s" % [new_scope, value.trim_prefix("emit.boundary.")]
	return value


func _load_json(path: String, errors: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("JSON file is missing: %s" % path)
		return {}
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK or not json.data is Dictionary:
		errors.append("JSON object parse failed %s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	return json.data


func _write_json(path: String, data: Variant, errors: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		errors.append("could not prepare output directory: %s" % absolute_path.get_base_dir())
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		errors.append("could not write pattern draft: %s" % path)
		return
	file.store_string(JSON.stringify(data, "  ", false) + "\n")
