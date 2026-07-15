class_name ChoiceCard
extends ListRow
## Large profile/choice card retaining the same semantic focus contract as ListRow.


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(Vector2.ZERO, size), background)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), foreground, false, 2.0)
	var preview_rect := Rect2(8, 8, size.x - 16, 48)
	draw_rect(preview_rect, foreground, false, 1.0)
	match command_id:
		&"profile.a":
			draw_line(Vector2(14, 48), Vector2(size.x - 14, 20), foreground, 2.0)
		&"profile.b":
			for y: int in range(14, 50, 4):
				for x: int in range(12 + y % 8, int(size.x - 12), 8):
					draw_rect(Rect2(x, y, 1, 1), foreground)
		&"profile.c":
			draw_colored_polygon(PackedVector2Array([Vector2(12, 50), Vector2(size.x / 2, 14), Vector2(size.x - 12, 50)]), foreground)
		&"profile.d":
			draw_rect(Rect2(12, 14, size.x - 24, 36), foreground)
	var font := _japanese_font if locale == &"ja" else _latin_font
	var lines := _wrap_label(_catalog.text(label_key, locale), font, size.x - 12)
	var first_baseline := 80 if lines.size() == 1 else 72
	for index: int in range(lines.size()):
		draw_string(
			font,
			Vector2(6, first_baseline + index * 12),
			lines[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x - 12,
			8,
			foreground
		)


func _wrap_label(text: String, font: Font, maximum_width: float) -> Array[String]:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= maximum_width:
		return [text]
	var lines: Array[String] = []
	var current_line := ""
	for word: String in text.split(" "):
		var candidate := word if current_line.is_empty() else "%s %s" % [current_line, word]
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= maximum_width:
			current_line = candidate
		elif lines.is_empty():
			lines.append(current_line if not current_line.is_empty() else word)
			current_line = word if not current_line.is_empty() else ""
		else:
			current_line = candidate
	if not current_line.is_empty() and lines.size() < 2:
		lines.append(current_line)
	return lines
