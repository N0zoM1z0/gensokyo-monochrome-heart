class_name TestContentDB
extends RefCounted
## M02 atomic snapshot and combat-safe hot-reload policy tests.

const CONTENT_DB_SCRIPT := preload("res://src/autoload/ContentDB.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect_atomic_rejection(failures)
	_expect_combat_reload_deferral(failures)
	return failures


func _expect_atomic_rejection(failures: Array[String]) -> void:
	var service := CONTENT_DB_SCRIPT.new()
	service.write_runtime_cache = false
	if not service.initialize():
		failures.append("ContentDB could not initialize reviewed content")
		return
	var accepted_snapshot: ContentRepository = service.snapshot()
	var sources := ContentSourceSet.new()
	sources.enforce_manifest_counts = false
	sources.supplemental_character_paths.append(
		"res://tests/fixtures/invalid/typed_content/duplicate_character_id.json"
	)
	if service.initialize(sources):
		failures.append("ContentDB accepted a duplicate stable-ID snapshot")
	if service.snapshot() != accepted_snapshot:
		failures.append("ContentDB replaced the accepted snapshot after failed validation")
	if service.last_report() == null or service.last_report().is_success():
		failures.append("ContentDB did not retain the rejected attempt report")
	if service.current_report() != accepted_snapshot.report:
		failures.append("ContentDB current report no longer describes the accepted snapshot")
	service.free()


func _expect_combat_reload_deferral(failures: Array[String]) -> void:
	const FIXTURE_PATH := "user://tests/m02_hot_reload_events.json"
	if not _write_event_fixture(FIXTURE_PATH, &"evt.fixture.hot_reload_v1", &"loc.hakurei_shrine"):
		failures.append("could not write the dev hot-reload fixture")
		return
	var sources := ContentSourceSet.new()
	sources.enforce_manifest_counts = false
	sources.supplemental_event_paths.append(FIXTURE_PATH)
	var service := CONTENT_DB_SCRIPT.new()
	service.write_runtime_cache = false
	if not service.initialize(sources):
		failures.append("ContentDB could not initialize for hot-reload test")
		_remove_fixture(FIXTURE_PATH)
		return
	var accepted_snapshot: ContentRepository = service.snapshot()
	if service.event(&"evt.fixture.hot_reload_v1") == null:
		failures.append("ContentDB did not load the initial hot-reload fixture")
	service.set_active_mode(&"danmaku")
	_write_event_fixture(FIXTURE_PATH, &"evt.fixture.hot_reload_v2", &"loc.hakurei_shrine")
	if service.check_for_source_changes():
		failures.append("ContentDB hot-reloaded changed sources during active danmaku")
	if not service.has_pending_hot_reload() or service.snapshot() != accepted_snapshot:
		failures.append("ContentDB did not defer the combat reload atomically")
	service.set_active_mode(&"exploration")
	if service.has_pending_hot_reload() or not service.is_loaded():
		failures.append("ContentDB did not complete its deferred reload after combat")
	if service.event(&"evt.fixture.hot_reload_v1") != null or service.event(&"evt.fixture.hot_reload_v2") == null:
		failures.append("ContentDB did not atomically expose the post-combat snapshot")
	var valid_snapshot: ContentRepository = service.snapshot()
	_write_event_fixture(FIXTURE_PATH, &"evt.fixture.hot_reload_invalid", &"loc.fixture.missing")
	if service.check_for_source_changes():
		failures.append("ContentDB accepted an invalid hot-reload candidate")
	if service.snapshot() != valid_snapshot or service.event(&"evt.fixture.hot_reload_v2") == null:
		failures.append("invalid hot reload replaced the last accepted snapshot")
	if service.last_report() == null or service.last_report().is_success():
		failures.append("invalid hot reload omitted its diagnostic report")
	_write_event_fixture(FIXTURE_PATH, &"evt.fixture.hot_reload_v3", &"loc.hakurei_shrine")
	if not service.check_for_source_changes() or service.event(&"evt.fixture.hot_reload_v3") == null:
		failures.append("ContentDB did not recover after the invalid source was repaired")
	if service.content_hash().length() != 64:
		failures.append("ContentDB query facade omitted content identity")
	if service.replay_header().content_hash != service.content_hash():
		failures.append("ContentDB replay header differs from the active snapshot")
	if not service.is_combat_mode(&"fighter.story") or service.is_combat_mode(&"dialogue"):
		failures.append("ContentDB combat-mode reload policy misclassified route IDs")
	service.free()
	_remove_fixture(FIXTURE_PATH)


func _write_event_fixture(path: String, event_id: StringName, location_id: StringName) -> bool:
	var absolute_path := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir()) != OK:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(
		(
			'{\n  "schema_version": 1,\n  "events": [\n    {\n      "id": "%s",\n      "legacy_id": "FIX-HOT-RELOAD",\n      "title_en": "Hot Reload Fixture",\n      "location_id": "%s",\n      "lead_character_ids": ["char.reimu_hakurei"],\n      "primary_mode": "dialogue",\n      "core_change": "none",\n      "status": "fixture",\n      "estimated_minutes": 1,\n      "comfort_tags": ["fixture"]\n    }\n  ]\n}\n'
			% [event_id, location_id]
		)
	)
	return true


func _remove_fixture(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)
