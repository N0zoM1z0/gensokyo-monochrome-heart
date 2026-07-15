extends SceneTree
## Headless entry point for strict 1-bit source-PNG validation.

const DEFAULT_ROOTS: Array[String] = ["res://assets/art/raw", "res://ui"]


func _initialize() -> void:
	var validator := OneBitImageValidator.new()
	var arguments := OS.get_cmdline_user_args()
	var errors: Array[String]
	if "--fixture-gray" in arguments:
		errors = validator.validate_image(_gray_fixture(), "fixture://deliberate_gray.png")
	else:
		var roots: Array[String] = []
		for argument: String in arguments:
			if argument.begins_with("--path="):
				roots.append(argument.trim_prefix("--path="))
		errors = validator.validate_roots(roots if not roots.is_empty() else DEFAULT_ROOTS)
	print("One-bit validation: errors=%d" % errors.size())
	for error: String in errors:
		printerr("ERROR: %s" % error)
	quit(0 if errors.is_empty() else 1)


func _gray_fixture() -> Image:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	image.set_pixel(1, 0, Color8(128, 128, 128, 255))
	return image
