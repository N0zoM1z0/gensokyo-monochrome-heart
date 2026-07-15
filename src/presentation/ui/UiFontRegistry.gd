class_name UiFontRegistry
extends RefCounted
## Loads the reviewed pixel-font assets without introducing system-font fallback.

const KIRI8_PATH := "res://ui/fonts/kiri8_latin.png"
const DOT_GOTHIC_JAPANESE_PATH := "res://ui/fonts/DotGothic16-Japanese.woff2"
const DOT_GOTHIC_LATIN_PATH := "res://ui/fonts/DotGothic16-Latin.woff2"


static func latin() -> Font:
	return _load_font(KIRI8_PATH)


static func japanese() -> Font:
	var font := _load_font(DOT_GOTHIC_JAPANESE_PATH).duplicate() as Font
	var fallback_fonts: Array[Font] = [_load_font(DOT_GOTHIC_LATIN_PATH), latin()]
	font.fallbacks = fallback_fonts
	return font


static func _load_font(path: String) -> Font:
	var font := ResourceLoader.load(path) as Font
	assert(font != null, "Approved font failed to load: %s" % path)
	return font
