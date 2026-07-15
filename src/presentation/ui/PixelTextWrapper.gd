class_name PixelTextWrapper
extends RefCounted
## Pixel-width wrapping with English word boundaries and basic Japanese kinsoku rules.

const JA_FORBIDDEN_LINE_START := "、。，．・：；？！゛゜ヽヾゝゞ々ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ）］｝〕〉》」』】〙〗〟’”｠»"
const JA_FORBIDDEN_LINE_END := "（［｛〔〈《「『【〘〖〝‘“｟«"


static func wrap(
	text: String,
	font: Font,
	maximum_width: float,
	font_size: int = 8,
	locale: StringName = &"en",
	maximum_lines: int = 0
) -> Array[String]:
	if text.is_empty():
		return [""]
	var lines := (
		_wrap_japanese(text, font, maximum_width, font_size)
		if locale == &"ja"
		else _wrap_words(text, font, maximum_width, font_size)
	)
	if maximum_lines > 0 and lines.size() > maximum_lines:
		var clipped := lines.slice(0, maximum_lines)
		clipped[maximum_lines - 1] = _ellipsize(clipped[maximum_lines - 1], font, maximum_width, font_size)
		return clipped
	return lines


static func _wrap_words(text: String, font: Font, width: float, font_size: int) -> Array[String]:
	var lines: Array[String] = []
	for paragraph: String in text.split("\n", true):
		if paragraph.is_empty():
			lines.append("")
			continue
		var current := ""
		for word: String in paragraph.split(" ", false):
			var candidate := word if current.is_empty() else "%s %s" % [current, word]
			if _fits(candidate, font, width, font_size):
				current = candidate
				continue
			if not current.is_empty():
				lines.append(current)
				current = ""
			if _fits(word, font, width, font_size):
				current = word
			else:
				var chunks := _break_clusters(word, font, width, font_size)
				for index: int in range(chunks.size() - 1):
					lines.append(chunks[index])
				current = chunks.back() if not chunks.is_empty() else ""
		if not current.is_empty():
			lines.append(current)
	return lines


static func _wrap_japanese(text: String, font: Font, width: float, font_size: int) -> Array[String]:
	var lines: Array[String] = []
	for paragraph: String in text.split("\n", true):
		if paragraph.is_empty():
			lines.append("")
			continue
		var current := ""
		for cluster: String in GraphemeSegmenter.segments(paragraph):
			var candidate := current + cluster
			if current.is_empty() or _fits(candidate, font, width, font_size):
				current = candidate
				continue
			var current_clusters := GraphemeSegmenter.segments(current)
			var carry := ""
			if JA_FORBIDDEN_LINE_START.contains(cluster) and not current_clusters.is_empty():
				# Keep closing punctuation and small kana with at least one leading
				# character without allowing the completed line to exceed its box.
				carry = current_clusters.pop_back()
				while not current_clusters.is_empty() and JA_FORBIDDEN_LINE_END.contains(current_clusters.back()):
					carry = current_clusters.pop_back() + carry
				current = "".join(current_clusters)
				if not current.is_empty():
					lines.append(current)
				current = carry + cluster
				continue
			if not current_clusters.is_empty() and JA_FORBIDDEN_LINE_END.contains(current_clusters.back()):
				carry = current_clusters.pop_back()
				current = "".join(current_clusters)
			if not current.is_empty():
				lines.append(current)
			current = carry + cluster
		if not current.is_empty():
			lines.append(current)
	return lines


static func _break_clusters(text: String, font: Font, width: float, font_size: int) -> Array[String]:
	var result: Array[String] = []
	var current := ""
	for cluster: String in GraphemeSegmenter.segments(text):
		if current.is_empty() or _fits(current + cluster, font, width, font_size):
			current += cluster
		else:
			result.append(current)
			current = cluster
	if not current.is_empty():
		result.append(current)
	return result


static func _ellipsize(text: String, font: Font, width: float, font_size: int) -> String:
	var clusters := GraphemeSegmenter.segments(text)
	while not clusters.is_empty() and not _fits("".join(clusters) + "...", font, width, font_size):
		clusters.pop_back()
	return "".join(clusters) + "..."


static func _fits(text: String, font: Font, width: float, font_size: int) -> bool:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width
