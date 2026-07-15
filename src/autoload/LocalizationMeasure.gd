extends Node
## Provides deterministic width checks without changing text or shrinking fonts.


func measure(text: String, locale: StringName, font_size: int = 8) -> Vector2:
	var font := UiFontRegistry.japanese() if locale == &"ja" else UiFontRegistry.latin()
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


func fits(text: String, locale: StringName, maximum_width: int, font_size: int = 8) -> bool:
	return measure(text, locale, font_size).x <= maximum_width


func overflow_pixels(text: String, locale: StringName, maximum_width: int, font_size: int = 8) -> int:
	return maxi(0, ceili(measure(text, locale, font_size).x) - maximum_width)
