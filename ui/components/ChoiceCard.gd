class_name ChoiceCard
extends ListRow
## Large profile/choice card retaining the same semantic focus contract as ListRow.


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(Vector2.ZERO, size), background)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), foreground, false, 2.0)
	var is_reflow := UI_SCALE_POLICY.is_reflow(ui_scale_percent)
	var preview_rect := Rect2(8, 6, size.x - 16, 24) if is_reflow else Rect2(8, 8, size.x - 16, 48)
	draw_rect(preview_rect, foreground, false, 1.0)
	var preview_bottom := preview_rect.end.y - 4
	var preview_top := preview_rect.position.y + 4
	match command_id:
		&"profile.a":
			draw_line(Vector2(14, preview_bottom), Vector2(size.x - 14, preview_top), foreground, 2.0)
		&"profile.b":
			for y: int in range(roundi(preview_top), roundi(preview_bottom), 4):
				for x: int in range(12 + y % 8, int(size.x - 12), 8):
					draw_rect(Rect2(x, y, 1, 1), foreground)
		&"profile.c":
			draw_colored_polygon(PackedVector2Array([Vector2(12, preview_bottom), Vector2(size.x / 2, preview_top), Vector2(size.x - 12, preview_bottom)]), foreground)
		&"profile.d":
			draw_rect(Rect2(12, preview_top, size.x - 24, preview_bottom - preview_top), foreground)
	var font := _japanese_font if locale == &"ja" else _latin_font
	var font_size: int = UI_SCALE_POLICY.pixels(12 if locale == &"ja" else 8, ui_scale_percent)
	var lines := PixelTextWrapper.wrap(_catalog.text(label_key, locale), font, size.x - 12, font_size, locale, 2)
	var first_baseline: float = (size.y - 8 if lines.size() == 1 else size.y - font_size - 5) if is_reflow else (80 if lines.size() == 1 else 72)
	var line_height: int = font_size + 1 if is_reflow else 12
	for index: int in range(lines.size()):
		draw_string(
			font,
			Vector2(6, first_baseline + index * line_height),
			lines[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x - 12,
			font_size,
			foreground
		)
