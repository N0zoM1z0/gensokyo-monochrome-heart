extends SceneTree
## Headless entry point for Control and Sprite2D pixel-position validation.

const DEFAULT_SCENES: Array[String] = ["res://src/presentation/shell/Main.tscn"]
const FRACTIONAL_FIXTURE := "res://tests/fixtures/visual/FractionalPosition.tscn"


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var scene_paths: Array[String] = []
	if "--fixture-fractional" in arguments:
		scene_paths.append(FRACTIONAL_FIXTURE)
	else:
		for argument: String in arguments:
			if argument.begins_with("--scene="):
				scene_paths.append(argument.trim_prefix("--scene="))
		if scene_paths.is_empty():
			scene_paths.assign(DEFAULT_SCENES)
	var errors: Array[String] = []
	for scene_path: String in scene_paths:
		errors.append_array(_validate_scene(scene_path))
	print("Pixel alignment validation: scenes=%d errors=%d" % [scene_paths.size(), errors.size()])
	for error: String in errors:
		printerr("ERROR: %s" % error)
	quit(0 if errors.is_empty() else 1)


func _validate_scene(path: String) -> Array[String]:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return ["%s could not be loaded as a PackedScene" % path]
	var instance := packed_scene.instantiate()
	var errors := PixelAlignmentValidator.new().validate_tree(instance, path)
	instance.free()
	return errors
