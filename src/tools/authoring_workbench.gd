extends SceneTree
## M11 executable registry for fixture launch, migration inspection, and tone audition.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		_fail(String(options.error), 2)
		return
	var service := AuthoringWorkbenchService.new()
	var action := String(options.get("action", "list"))
	var target_id := StringName(String(options.get("target", "")))
	match action:
		"list":
			_finish(service.render_catalog(StringName(String(options.get("category", "")))))
		"inspect":
			_finish(service.inspect_target(target_id))
		"smoke", "launch":
			await _run_scene_or_tone(service, target_id, action == "launch")
		"screenshot":
			_capture_screenshot(service, target_id, options)
		_:
			_fail("action must be list, inspect, smoke, launch, or screenshot", 2)


func _capture_screenshot(service: AuthoringWorkbenchService, target_id: StringName, options: Dictionary) -> void:
	var inspected := service.inspect_target(target_id)
	if not inspected.is_valid():
		_finish(inspected)
		return
	if inspected.target.kind != &"scene":
		inspected.errors.append("screenshot target must be a scene: %s" % target_id)
		_finish(inspected)
		return
	var output_path := String(options.get("output", ""))
	if output_path.is_empty():
		inspected.errors.append("screenshot requires --output=<png>")
		_finish(inspected)
		return
	var arguments := PackedStringArray([
		"--display-driver", "x11",
		"--rendering-driver", "opengl3",
		"--audio-driver", "Dummy",
		"--disable-vsync",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/screenshot_runner.gd",
		"--",
		"--scene=%s" % inspected.target.resource_path,
		"--output=%s" % output_path,
		"--profile=%s" % String(options.get("profile", "A")),
		"--locale=%s" % String(options.get("locale", "en")),
		"--ui-scale=%s" % String(options.get("ui-scale", "100")),
	])
	var captured: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), arguments, captured, true)
	for line: String in captured:
		print(line)
	if exit_code != 0:
		inspected.errors.append("screenshot runner exited with code %d" % exit_code)
		_finish(inspected)
		return
	print("WORKBENCH SCREENSHOT target=%s output=%s" % [target_id, output_path])
	quit(0)


func _run_scene_or_tone(service: AuthoringWorkbenchService, target_id: StringName, keep_running: bool) -> void:
	var inspected := service.inspect_target(target_id)
	if not inspected.is_valid():
		_finish(inspected)
		return
	var target := inspected.target
	if target.kind == &"save":
		_finish(inspected)
		return
	if target.kind == &"tone":
		var player := AdaptiveTestTonePlayer.new()
		root.add_child(player)
		if not player.request_state(target.fixture_state):
			inspected.errors.append("tone player rejected %s" % target.fixture_state)
			_finish(inspected)
			return
		print(inspected.output)
		print("TONE AUDITION state=%s transition_count=%d" % [player.current_state_id, player.transition_count])
		if keep_running:
			return
		player.free()
		quit(0)
		return
	var packed := ResourceLoader.load(target.resource_path) as PackedScene
	if packed == null:
		inspected.errors.append("could not load scene %s" % target.resource_path)
		_finish(inspected)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	for _frame: int in range(4):
		await process_frame
	print(inspected.output)
	print("SCENE %s target=%s nodes=%d" % ["LAUNCHED" if keep_running else "SMOKE PASSED", target.id, _node_count(instance)])
	if not keep_running:
		instance.free()
		quit(0)


func _node_count(node: Node) -> int:
	var count := 1
	for child: Node in node.get_children():
		count += _node_count(child)
	return count


func _finish(result: WorkbenchResult) -> void:
	if not result.output.is_empty():
		print(result.output)
	print(result.human_readable())
	quit(0 if result.is_valid() else 1)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	for argument: String in arguments:
		if not argument.begins_with("--") or not argument.contains("="):
			result.error = "arguments must use --name=value: %s" % argument
			return result
		var separator := argument.find("=")
		var key := argument.substr(2, separator - 2)
		if key not in ["action", "target", "category", "output", "profile", "locale", "ui-scale"]:
			result.error = "unknown argument: --%s" % key
			return result
		result[key] = argument.substr(separator + 1)
	return result


func _fail(message: String, exit_code: int) -> void:
	printerr("M11 WORKBENCH FAILED: %s" % message)
	printerr("Usage: scripts/authoring_workbench.sh --action=list [--category=<category>]")
	printerr("       scripts/authoring_workbench.sh --action=inspect|smoke|launch --target=<stable-id>")
	printerr("       scripts/authoring_workbench.sh --action=screenshot --target=<scene-id> --output=<png> [--profile=A --locale=en --ui-scale=100]")
	quit(exit_code)
