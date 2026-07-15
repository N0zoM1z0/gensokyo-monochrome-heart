extends SceneTree
## M11 CLI for pattern draft lifecycle and interactive deterministic preview.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		_fail(String(options.error), 2)
		return
	var service := BulletPatternLabService.new()
	var action := String(options.get("action", ""))
	var result: BulletPatternLabResult
	match action:
		"duplicate":
			result = service.duplicate_template(StringName(String(options.get("pattern-id", ""))), String(options.get("output", "")))
		"validate":
			result = service.validate_pattern(String(options.get("input", "")))
		"report":
			result = service.render_report(String(options.get("input", "")))
		"smoke":
			result = service.run_simulation_smoke(String(options.get("input", "")), int(options.get("density", "100")), int(options.get("speed", "100")))
		"launch":
			var packed := ResourceLoader.load("res://src/presentation/tools/BulletPatternLab.tscn") as PackedScene
			if packed == null:
				_fail("Bullet Pattern Lab scene could not load", 1)
				return
			var lab := packed.instantiate() as BulletPatternLab
			lab.configure_pattern(String(options.get("input", BulletPatternLabService.TEMPLATE_PATH)))
			root.add_child(lab)
			return
		_:
			_fail("action must be duplicate, validate, report, smoke, or launch", 2)
			return
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
		if key not in ["action", "pattern-id", "output", "input", "density", "speed"]:
			result.error = "unknown argument: --%s" % key
			return result
		result[key] = argument.substr(separator + 1)
	return result


func _fail(message: String, exit_code: int) -> void:
	printerr("BULLET PATTERN LAB FAILED: %s" % message)
	printerr("Usage: scripts/bullet_pattern_lab.sh --action=duplicate --pattern-id=danmaku.<id> --output=<json>")
	printerr("       scripts/bullet_pattern_lab.sh --action=validate|report|smoke --input=<json> [--density=100 --speed=100]")
	printerr("       scripts/bullet_pattern_lab.sh --action=launch --input=<json>")
	quit(exit_code)
