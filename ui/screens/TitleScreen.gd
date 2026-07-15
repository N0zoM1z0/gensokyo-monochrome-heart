class_name TitleScreen
extends UiScreenBase
## M01 no-save title fixture using shared rows and localized catalog keys.


func _build_screen() -> void:
	screen_id = &"title"
	_add_frame(Rect2(172, 80, 140, 68))
	_add_row(&"ui.title.new_profile", &"new_profile", &"title.new_profile", Rect2(178, 88, 128, 16))
	_add_row(&"ui.title.options", &"open_options", &"title.options", Rect2(178, 108, 128, 16))
	_add_row(&"ui.title.quit", &"quit", &"title.quit", Rect2(178, 128, 128, 16))


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(8, 8, 304, 164), foreground, false, 2.0)
	draw_rect(Rect2(16, 18, 144, 50), foreground, false, 2.0)
	draw_line(Vector2(30, 56), Vector2(66, 28), foreground, 2.0)
	draw_line(Vector2(66, 28), Vector2(102, 56), foreground, 2.0)
	draw_line(Vector2(42, 56), Vector2(90, 56), foreground, 2.0)
	draw_rect(Rect2(62, 38, 8, 18), foreground, false, 2.0)
	draw_rect(Rect2(118, 34, 8, 8), foreground)
	draw_rect(Rect2(126, 34, 8, 8), foreground)
	draw_rect(Rect2(122, 42, 8, 8), foreground)
	_draw_localized(&"ui.title.logo", Vector2(16, 78), 288, HORIZONTAL_ALIGNMENT_LEFT)
	_draw_localized(&"ui.title.unofficial", Vector2(16, 158), 288, HORIZONTAL_ALIGNMENT_LEFT)
	_draw_localized(&"ui.title.version", Vector2(176, 170), 128, HORIZONTAL_ALIGNMENT_RIGHT)
