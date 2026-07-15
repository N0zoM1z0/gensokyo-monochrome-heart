class_name GraphemeSegmenter
extends RefCounted
## Small dependency-free extended-cluster segmenter for reveal timing and tests.


static func segments(text: String) -> Array[String]:
	var result: Array[String] = []
	var regional_count := 0
	for index: int in range(text.length()):
		var character := text.substr(index, 1)
		var code := character.unicode_at(0)
		var should_join := (
			not result.is_empty()
			and (
				_is_combining(code)
				or _is_variation_selector(code)
				or _is_emoji_modifier(code)
				or code == 0x200d
				or result[-1].ends_with(String.chr(0x200d))
				or (_is_regional_indicator(code) and regional_count % 2 == 1)
			)
		)
		if should_join:
			result[-1] += character
		else:
			result.append(character)
		if _is_regional_indicator(code):
			regional_count += 1
		else:
			regional_count = 0
	return result


static func _is_combining(code: int) -> bool:
	return (
		(code >= 0x0300 and code <= 0x036f)
		or (code >= 0x1ab0 and code <= 0x1aff)
		or (code >= 0x1dc0 and code <= 0x1dff)
		or (code >= 0x20d0 and code <= 0x20ff)
		or (code >= 0xfe20 and code <= 0xfe2f)
	)


static func _is_variation_selector(code: int) -> bool:
	return (code >= 0xfe00 and code <= 0xfe0f) or (code >= 0xe0100 and code <= 0xe01ef)


static func _is_emoji_modifier(code: int) -> bool:
	return code >= 0x1f3fb and code <= 0x1f3ff


static func _is_regional_indicator(code: int) -> bool:
	return code >= 0x1f1e6 and code <= 0x1f1ff
