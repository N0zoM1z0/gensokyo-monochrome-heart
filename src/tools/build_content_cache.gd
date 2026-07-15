extends SceneTree
## Generates or verifies the deterministic, reviewable runtime content index.

const DEFAULT_OUTPUT_PATH := "res://content/indexes/runtime_content_index.json"
const SCHEMA_PATH := "res://schemas/content_runtime_index.schema.json"


func _initialize() -> void:
	var output_path := DEFAULT_OUTPUT_PATH
	var check_only := false
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--check":
			check_only = true
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	var repository := ContentRepository.new()
	var report := repository.load_sources()
	if not report.is_success():
		printerr(report.human_readable())
		quit(1)
		return
	var schema: Variant = _load_json(SCHEMA_PATH)
	var generated: Variant = JSON.parse_string(repository.runtime_index_json())
	if not schema is Dictionary or not generated is Dictionary:
		printerr("Runtime content index or schema could not be parsed.")
		quit(1)
		return
	var schema_errors := JsonSchemaValidator.new().validate(generated, schema)
	if not schema_errors.is_empty():
		printerr("Runtime content index schema errors: %s" % "; ".join(schema_errors))
		quit(1)
		return
	if check_only:
		if not repository.runtime_index_matches(output_path):
			printerr("Runtime content index is missing or stale: %s" % output_path)
			quit(1)
			return
		print("Runtime content index is current: %s (%s)" % [output_path, repository.diagnostic_header()])
		quit(0)
		return
	var write_error := repository.write_runtime_index(output_path)
	if write_error != OK:
		printerr("Could not write runtime content index %s (error %d)" % [output_path, write_error])
		quit(1)
		return
	print("Generated runtime content index: %s (%s)" % [output_path, repository.diagnostic_header()])
	quit(0)


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())
