extends SceneTree
## Headless M11 entry point for event draft duplication, validation, and preview.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		_fail(String(options.error), 2)
		return
	var action := String(options.get("action", ""))
	var service := EventAuthoringService.new()
	match action:
		"duplicate":
			var event_id := StringName(String(options.get("event-id", "")))
			var output := String(options.get("output", ""))
			var duplicated := service.duplicate_empty_cushion(event_id, output)
			print(duplicated.human_readable())
			if not duplicated.is_valid():
				quit(1)
				return
			print("CREATED %s" % output)
			quit(0)
		"validate":
			var validated := service.validate_bundle(String(options.get("bundle", "")))
			print(validated.human_readable())
			quit(0 if validated.is_valid() else 1)
		"preview":
			var bundle_path := String(options.get("bundle", ""))
			var locale := StringName(String(options.get("locale", "en")))
			var output_path := String(options.get("output", "-"))
			var previewed := service.write_preview(bundle_path, locale, output_path)
			if output_path != "-" or not previewed.is_valid():
				print(previewed.human_readable())
			if previewed.is_valid() and output_path != "-":
				print("WROTE %s" % output_path)
			quit(0 if previewed.is_valid() else 1)
		_:
			_fail("action must be duplicate, validate, or preview", 2)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	for argument: String in arguments:
		if not argument.begins_with("--") or not argument.contains("="):
			result.error = "arguments must use --name=value: %s" % argument
			return result
		var separator := argument.find("=")
		var key := argument.substr(2, separator - 2)
		if key not in ["action", "event-id", "output", "bundle", "locale"]:
			result.error = "unknown argument: --%s" % key
			return result
		result[key] = argument.substr(separator + 1)
	return result


func _fail(message: String, exit_code: int) -> void:
	printerr("EVENT AUTHORING FAILED: %s" % message)
	printerr("Usage:")
	printerr("  scripts/author_event.sh --action=duplicate --event-id=evt.<namespace> --output=<directory>")
	printerr("  scripts/author_event.sh --action=validate --bundle=<directory>")
	printerr("  scripts/author_event.sh --action=preview --bundle=<directory> --locale=en|ja --output=<file|->")
	quit(exit_code)
