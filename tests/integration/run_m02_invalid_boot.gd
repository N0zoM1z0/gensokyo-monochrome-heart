extends SceneTree
## Expected-failure fixture proving invalid typed references stop before Title.

const CONTENT_DB_SCRIPT := preload("res://src/autoload/ContentDB.gd")

var shell: GameShell


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var installed_content_db := root.get_node_or_null("ContentDB")
	if installed_content_db != null:
		root.remove_child(installed_content_db)
	var invalid_sources := ContentSourceSet.new()
	invalid_sources.enforce_manifest_counts = false
	invalid_sources.supplemental_event_paths.append(
		"res://tests/fixtures/invalid/typed_content/missing_event_references.json"
	)
	var rejected_content_db := CONTENT_DB_SCRIPT.new()
	rejected_content_db.name = "ContentDB"
	rejected_content_db.write_runtime_cache = false
	if rejected_content_db.initialize(invalid_sources):
		printerr("Invalid boot fixture unexpectedly produced a valid ContentDB snapshot.")
		await _finish(2, installed_content_db, rejected_content_db)
		return
	root.add_child(rejected_content_db)
	var packed_shell := load("res://src/presentation/shell/Main.tscn") as PackedScene
	if packed_shell == null:
		printerr("Invalid boot fixture could not load the main shell.")
		await _finish(2, installed_content_db, rejected_content_db)
		return
	shell = packed_shell.instantiate() as GameShell
	root.add_child(shell)
	for _frame: int in range(12):
		await process_frame
	if shell.active_route_id() != &"" or shell.active_primary_screen() != null:
		printerr("Invalid authored references reached a presentation route: %s" % shell.active_route_id())
		packed_shell = null
		await _finish(2, installed_content_db, rejected_content_db)
		return
	printerr("Title route blocked by invalid ContentDB before presentation.")
	packed_shell = null
	await _finish(1, installed_content_db, rejected_content_db)


func _finish(code: int, installed_content_db: Node, rejected_content_db: Node) -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		shell = null
	await process_frame
	if rejected_content_db != null and is_instance_valid(rejected_content_db):
		rejected_content_db.queue_free()
	await process_frame
	if installed_content_db != null and is_instance_valid(installed_content_db):
		root.add_child(installed_content_db)
	await process_frame
	await process_frame
	quit(code)
