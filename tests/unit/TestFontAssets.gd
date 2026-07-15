class_name TestFontAssets
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var kiri8 := UiFontRegistry.latin()
	if not kiri8.has_char("A".unicode_at(0)):
		failures.append("Kiri8 does not provide the Latin A glyph")
	var expected_width := 3 * 6
	var measured_width := int(kiri8.get_string_size("ABC", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
	if measured_width != expected_width:
		failures.append("Kiri8 ABC width expected %d, got %d" % [expected_width, measured_width])

	var japanese := UiFontRegistry.japanese()
	if not japanese.has_char("霊".unicode_at(0)):
		failures.append("DotGothic16 Japanese does not provide the specimen glyph 霊")
	if not japanese.has_char("A".unicode_at(0)):
		failures.append("Japanese font stack does not provide the Latin fallback A")

	for path: String in [
		"res://ui/fonts/DotGothic16-Japanese.woff2.import",
		"res://ui/fonts/DotGothic16-Latin.woff2.import",
	]:
		_validate_pixel_import(path, failures)
	return failures


func _validate_pixel_import(path: String, failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("missing reviewed font import settings: %s" % path)
		return
	var settings := file.get_as_text()
	for required: String in [
		"antialiasing=0",
		"generate_mipmaps=false",
		"allow_system_fallback=false",
		"hinting=0",
		"subpixel_positioning=0",
	]:
		if not settings.contains(required):
			failures.append("%s lacks %s" % [path, required])
