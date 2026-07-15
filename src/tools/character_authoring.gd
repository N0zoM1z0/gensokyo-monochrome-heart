extends SceneTree
## Headless M11 entry point for character skill browsing and agent-output validation.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		_fail(String(options.error), 2)
		return
	var service := CharacterAuthoringService.new()
	var action := String(options.get("action", ""))
	var result: CharacterAuthoringResult
	match action:
		"list":
			result = service.render_catalog()
		"show":
			result = service.render_skill(StringName(String(options.get("character-id", ""))))
		"validate-output":
			result = service.validate_agent_output(
				StringName(String(options.get("character-id", ""))),
				String(options.get("input", ""))
			)
		_:
			_fail("action must be list, show, or validate-output", 2)
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
		if key not in ["action", "character-id", "input"]:
			result.error = "unknown argument: --%s" % key
			return result
		result[key] = argument.substr(separator + 1)
	return result


func _fail(message: String, exit_code: int) -> void:
	printerr("CHARACTER AUTHORING FAILED: %s" % message)
	printerr("Usage:")
	printerr("  scripts/character_authoring.sh --action=list")
	printerr("  scripts/character_authoring.sh --action=show --character-id=char.<id>")
	printerr("  scripts/character_authoring.sh --action=validate-output --character-id=char.<id> --input=<json>")
	quit(exit_code)
