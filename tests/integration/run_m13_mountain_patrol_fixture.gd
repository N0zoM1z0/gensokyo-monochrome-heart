extends SceneTree
## Regression: the screenshot fixture reaches patrol and commits its checkpoint.

const FIXTURE_SCENE := preload("res://tests/ui/fixtures/MountainSlicePatrolFixture.tscn")
const PROFILE_ID: StringName = &"p133"

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_root := MountainSliceFixture.isolated_save_root("patrol", OS.get_process_id())
	_remove_tree(save_root)
	var fixture := FIXTURE_SCENE.instantiate() as MountainSliceFixture
	root.add_child(fixture)
	await process_frame
	fixture.configure_fixture(&"A", &"en")
	await process_frame
	var slice := fixture.get_node_or_null("%YoukaiMountainSliceMode") as VerticalSliceMode
	_expect(slice != null, "patrol fixture omitted its vertical-slice mode")
	if slice != null:
		_expect(slice.phase_id() == &"afterbeat", "patrol fixture entered an error instead of the afterbeat")
		_expect(slice.current_event_node_id() == &"n_after_01", "patrol fixture reached the wrong event node")
		_expect(slice.current_stage_component() == &"mountain_patrol", "patrol fixture omitted the mountain patrol stage")
		_expect(not slice.current_text().is_empty(), "patrol fixture rendered no dialogue")
	_expect(
		FileAccess.file_exists("%s/%s/auto_event.save" % [save_root, PROFILE_ID]),
		"patrol fixture did not atomically commit its event checkpoint"
	)
	fixture.free()
	_remove_tree(save_root)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)


func _finish() -> void:
	print("M13 mountain patrol screenshot fixture: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
