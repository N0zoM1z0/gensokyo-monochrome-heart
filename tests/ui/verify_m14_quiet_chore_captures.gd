extends SceneTree
## Verifies that locale-specific captures retain the same essential Quiet Chore art.

const CAPTURE_ROOT := "res://tests/screenshots/generated"


func _initialize() -> void:
	var failures: Array[String] = []
	_check_region_pair(
		"tutorial",
		Rect2i(57, 102, 246, 45),
		600,
		failures
	)
	for state: String in ["story_pulse", "sit"]:
		_check_region_pair(state, Rect2i(71, 74, 28, 50), 400, failures)
		_check_region_pair(state, Rect2i(219, 60, 50, 65), 1000, failures)
	_check_region_pair("result", Rect2i(74, 75, 32, 62), 500, failures)
	_check_region_pair("result", Rect2i(207, 60, 48, 75), 1100, failures)
	if not failures.is_empty():
		for failure: String in failures:
			printerr("ERROR: %s" % failure)
		quit(1)
		return
	print("M14 Quiet Chore capture regression: PASS")
	quit(0)


func _check_region_pair(
	state: String,
	region: Rect2i,
	minimum_ink_pixels: int,
	failures: Array[String]
) -> void:
	var english_path := "%s/m14_reimu_quiet_%s_en.png" % [CAPTURE_ROOT, state]
	var japanese_path := "%s/m14_reimu_quiet_%s_ja.png" % [CAPTURE_ROOT, state]
	var english := _load_capture(english_path, failures)
	var japanese := _load_capture(japanese_path, failures)
	if english == null or japanese == null:
		return
	if not _contains_region(english, region) or not _contains_region(japanese, region):
		failures.append("%s capture does not contain required region %s" % [state, region])
		return
	var english_ink := _ink_pixels(english, region)
	var japanese_ink := _ink_pixels(japanese, region)
	if english_ink < minimum_ink_pixels:
		failures.append("%s EN essential art is missing (%d ink pixels)" % [state, english_ink])
	if japanese_ink < minimum_ink_pixels:
		failures.append("%s JA essential art is missing (%d ink pixels)" % [state, japanese_ink])
	var differing_pixels := _different_pixels(english, japanese, region)
	if differing_pixels > 0:
		failures.append(
			"%s EN/JA essential art differs in %d pixels within %s"
			% [state, differing_pixels, region]
		)


func _load_capture(path: String, failures: Array[String]) -> Image:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		failures.append("could not load %s (error %d)" % [path, error])
		return null
	return image


func _contains_region(image: Image, region: Rect2i) -> bool:
	return Rect2i(Vector2i.ZERO, image.get_size()).encloses(region)


func _ink_pixels(image: Image, region: Rect2i) -> int:
	var count := 0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			if image.get_pixel(x, y).r < 0.5:
				count += 1
	return count


func _different_pixels(english: Image, japanese: Image, region: Rect2i) -> int:
	var count := 0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			if english.get_pixel(x, y) != japanese.get_pixel(x, y):
				count += 1
	return count
