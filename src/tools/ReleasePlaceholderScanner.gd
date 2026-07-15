class_name ReleasePlaceholderScanner
extends RefCounted
## Rejects placeholder filenames and IDs from every release-included source root.

const RELEASE_ROOTS: Array[String] = [
	"res://assets",
	"res://content",
	"res://ui",
	"res://src/autoload",
	"res://src/application",
	"res://src/domain",
	"res://src/infrastructure",
	"res://src/presentation",
]
const EXCLUDED_DIRECTORIES: Array[StringName] = [
	&"placeholders",
	&"previews",
	&"test_tones",
]
const TEXT_EXTENSIONS: Array[StringName] = [
	&"cfg",
	&"csv",
	&"gd",
	&"gdshader",
	&"json",
	&"tscn",
	&"tres",
	&"yaml",
	&"yml",
]

var scanned_files: int = 0


func scan_release_inputs() -> Array[String]:
	return scan_roots(RELEASE_ROOTS)


func scan_roots(root_paths: Array[String]) -> Array[String]:
	scanned_files = 0
	var files: Array[String] = []
	for root_path: String in root_paths:
		_collect_files(root_path, files)
	files.sort()
	var errors: Array[String] = []
	var forbidden_prefix := "ph" + "_"
	var identifier_pattern := RegEx.create_from_string(
		"(?i)(^|[^a-z0-9])%s[a-z0-9]" % forbidden_prefix
	)
	for path: String in files:
		scanned_files += 1
		if path.get_file().to_lower().begins_with(forbidden_prefix):
			errors.append("placeholder filename is forbidden in release input: %s" % path)
		if StringName(path.get_extension().to_lower()) in TEXT_EXTENSIONS:
			errors.append_array(_scan_text_file(path, identifier_pattern))
	return errors


func _collect_files(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		if FileAccess.file_exists(path):
			output.append(path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			if StringName(entry) not in EXCLUDED_DIRECTORIES:
				_collect_files(child_path, output)
		elif not entry.ends_with(".import") and not entry.ends_with(".uid"):
			output.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _scan_text_file(path: String, identifier_pattern: RegEx) -> Array[String]:
	var errors: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ["release scanner could not read text input: %s" % path]
	var line_number := 0
	while not file.eof_reached():
		line_number += 1
		var line := file.get_line()
		if identifier_pattern.search(line) != null:
			errors.append("placeholder ID is forbidden at %s:%d" % [path, line_number])
	return errors
