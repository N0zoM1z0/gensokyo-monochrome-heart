class_name TestBulletPatternLab
extends RefCounted
## M11 contracts for pattern duplication, data edits, validation, and simulation.

const TEST_ROOT := "user://tests/m11_bullet_pattern_lab"
const PATTERN_PATH := TEST_ROOT + "/writer_pattern.json"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(ProjectSettings.globalize_path(TEST_ROOT))
	var service := BulletPatternLabService.new()
	var duplicated := service.duplicate_template(&"danmaku.lab.writer_pattern", PATTERN_PATH)
	if not duplicated.is_valid():
		failures.append("pattern duplication failed: %s" % duplicated.human_readable())
		return failures
	var contents := FileAccess.get_file_as_string(PATTERN_PATH)
	for stale: String in ["danmaku.hkr.boundary_stain", "phase.boundary.", "emit.boundary."]:
		if contents.contains(stale):
			failures.append("pattern duplication retained private template ID %s" % stale)
	var raw: Variant = JSON.parse_string(contents)
	if not raw is Dictionary:
		failures.append("duplicated pattern could not be edited as JSON")
		return failures
	raw.phases[0].emitters[0].interval_ticks = 30
	raw.phases[0].emitters[0].speed_pixels_per_tick = 1.2
	_write_json(PATTERN_PATH, raw, failures)
	var report := service.render_report(PATTERN_PATH)
	if not report.is_valid():
		failures.append("edited pattern report failed: %s" % report.human_readable())
	else:
		for expected: String in ["`emit.lab.writer_pattern.amulet_teach`", "30/30/7", "1.20", "55:8"]:
			if not report.output.contains(expected):
				failures.append("pattern report omitted edited evidence %s" % expected)
	var first := service.run_simulation_smoke(PATTERN_PATH, 85, 70)
	var second := service.run_simulation_smoke(PATTERN_PATH, 85, 70)
	if not first.is_valid() or not first.output.contains("result=clear"):
		failures.append("edited pattern simulation failed: %s" % first.human_readable())
	elif first.output != second.output:
		failures.append("pattern simulation evidence is nondeterministic")
	raw.phases[0].emitters[0].pattern = "unsupported_spiral"
	_write_json(PATTERN_PATH, raw, failures)
	var invalid := service.validate_pattern(PATTERN_PATH)
	if invalid.is_valid() or "unsupported danmaku pattern component" not in "; ".join(invalid.errors):
		failures.append("closed pattern vocabulary did not reject unsupported_spiral")
	_remove_tree(ProjectSettings.globalize_path(TEST_ROOT))
	return failures


func _write_json(path: String, data: Variant, failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write bullet lab fixture")
		return
	file.store_string(JSON.stringify(data, "  ", false) + "\n")


func _remove_tree(absolute_path: String) -> void:
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := absolute_path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute_path)
