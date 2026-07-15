class_name OneBitImageValidator
extends RefCounted
## Validates source PNGs against the strict black/white and binary-alpha contract.

const MAX_ERRORS_PER_IMAGE := 64
const PREVIEW_DIRECTORIES: Array[StringName] = [&"preview", &"previews"]


func validate_file(path: String) -> Array[String]:
	var image := Image.new()
	var load_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var error := image.load(load_path)
	if error != OK:
		return ["%s could not be loaded as PNG (error %d)" % [path, error]]
	return validate_image(image, path)


func validate_image(image: Image, source_name: String) -> Array[String]:
	var errors: Array[String] = []
	if image.is_empty():
		return ["%s is empty" % source_name]
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel := image.get_pixel(x, y)
			var alpha := pixel.a8
			if alpha != 0 and alpha != 255:
				errors.append(
					"%s:(%d,%d) alpha must be 0 or 255, got %d" % [source_name, x, y, alpha]
				)
			elif alpha == 255 and not _is_black_or_white(pixel):
				errors.append(
					"%s:(%d,%d) visible RGB must be #000000 or #ffffff, got #%02x%02x%02x"
					% [source_name, x, y, pixel.r8, pixel.g8, pixel.b8]
				)
			if errors.size() >= MAX_ERRORS_PER_IMAGE:
				errors.append("%s has additional palette violations; output capped at %d" % [source_name, MAX_ERRORS_PER_IMAGE])
				return errors
	return errors


func validate_roots(root_paths: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var png_paths: Array[String] = []
	for root_path: String in root_paths:
		_collect_png_paths(root_path, png_paths)
	png_paths.sort()
	for path: String in png_paths:
		errors.append_array(validate_file(path))
	return errors


func _collect_png_paths(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			if StringName(entry) not in PREVIEW_DIRECTORIES:
				_collect_png_paths(child_path, output)
		elif entry.get_extension().to_lower() == "png":
			output.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _is_black_or_white(pixel: Color) -> bool:
	var is_black := pixel.r8 == 0 and pixel.g8 == 0 and pixel.b8 == 0
	var is_white := pixel.r8 == 255 and pixel.g8 == 255 and pixel.b8 == 255
	return is_black or is_white
