class_name TestVisualValidators
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	_validate_one_bit_contract(failures)
	_validate_pixel_alignment_contract(failures)
	return failures


func _validate_one_bit_contract(failures: Array[String]) -> void:
	var validator := OneBitImageValidator.new()
	var valid_errors := validator.validate_file("res://ui/fonts/kiri8_latin.png")
	if not valid_errors.is_empty():
		failures.append("Kiri8 atlas violated 1-bit policy: %s" % "; ".join(valid_errors))
	var gray_image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	gray_image.fill(Color.WHITE)
	gray_image.set_pixel(1, 0, Color8(128, 128, 128, 255))
	var gray_errors := validator.validate_image(gray_image, "fixture_gray.png")
	if gray_errors.size() != 1 or not gray_errors[0].contains("fixture_gray.png:(1,0)"):
		failures.append("gray fixture did not report its exact file and coordinate: %s" % gray_errors)
	var alpha_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	alpha_image.set_pixel(0, 0, Color(0.0, 0.0, 0.0, 0.5))
	var alpha_errors := validator.validate_image(alpha_image, "fixture_alpha.png")
	if alpha_errors.size() != 1 or not alpha_errors[0].contains("alpha must be 0 or 255"):
		failures.append("partial-alpha fixture was not rejected: %s" % alpha_errors)


func _validate_pixel_alignment_contract(failures: Array[String]) -> void:
	var validator := PixelAlignmentValidator.new()
	var packed_scene := load("res://tests/fixtures/visual/FractionalPosition.tscn") as PackedScene
	var fixture := packed_scene.instantiate()
	var errors := validator.validate_tree(fixture, "FractionalPosition.tscn")
	fixture.free()
	if errors.size() != 1 or not errors[0].contains("BadControl") or not errors[0].contains("10.500"):
		failures.append("fractional Control fixture was not reported precisely: %s" % errors)
	var aligned := Sprite2D.new()
	aligned.position = Vector2(10, 12)
	if not validator.validate_tree(aligned, "aligned Sprite2D").is_empty():
		failures.append("integer-aligned Sprite2D was rejected")
	aligned.free()
