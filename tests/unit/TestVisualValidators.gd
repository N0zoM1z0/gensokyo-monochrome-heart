class_name TestVisualValidators
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	_validate_one_bit_contract(failures)
	_validate_pixel_alignment_contract(failures)
	_validate_production_ui_art(failures)
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


func _validate_production_ui_art(failures: Array[String]) -> void:
	var art := ProductionUiArt.new()
	var palette_a := art.texture_for(false)
	var palette_d := art.texture_for(true)
	if palette_a == null or palette_d == null:
		failures.append("production UI atlas did not resolve both runtime palettes")
		return
	var expected_size := Vector2(ProductionUiArt.ATLAS_SIZE)
	if palette_a.get_size() != expected_size or palette_d.get_size() != expected_size:
		failures.append("production UI atlas did not retain its reviewed 256x128 export size")
	if not _are_palette_inverses(palette_a.get_image(), palette_d.get_image()):
		failures.append("production UI atlas broke exact palette A/D reciprocity")
	for frame_index: int in range(ProductionUiArt.FRAME_RECTS.size()):
		var frame := art.frame_style(frame_index, false)
		if frame == null:
			failures.append("production UI frame %d did not resolve" % frame_index)
			continue
		for side: int in range(4):
			if not is_equal_approx(frame.get_texture_margin(side), 4.0):
				failures.append("production UI frame %d lost its four-pixel nine-patch margin" % frame_index)
				break
	for icon_id: StringName in ProductionUiArt.ICON_RECTS:
		var icon := art.icon_texture(icon_id, false)
		if icon == null or icon.get_size().x < 16 or icon.get_size().y != 16:
			failures.append("production semantic UI icon did not resolve: %s" % icon_id)
	if art.icon_texture(&"unsupported", false) != null or art.frame_style(-1, false) != null:
		failures.append("production UI resolver accepted unsupported regions")


func _are_palette_inverses(palette_a: Image, palette_d: Image) -> bool:
	if palette_a.get_size() != palette_d.get_size():
		return false
	var visible_pixels := 0
	for y: int in range(palette_a.get_height()):
		for x: int in range(palette_a.get_width()):
			var a := palette_a.get_pixel(x, y)
			var d := palette_d.get_pixel(x, y)
			if not is_equal_approx(a.a, d.a):
				return false
			if a.a <= 0.0:
				continue
			visible_pixels += 1
			if not is_equal_approx(a.r + d.r, 1.0):
				return false
	return visible_pixels > 0
