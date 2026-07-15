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
	var font_size := 12 if locale == &"ja" else 8
	var lines := PixelTextWrapper.wrap(_catalog.text(label_key, locale), font, size.x - 12, font_size, locale, 2)
	var first_baseline := 80 if lines.size() == 1 else 72
	for index: int in range(lines.size()):
		draw_string(
			font,
			Vector2(6, first_baseline + index * 12),
			lines[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x - 12,
			font_size,
			foreground
		)
