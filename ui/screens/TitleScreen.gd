class_name TitleScreen
extends UiScreenBase
## Save-aware title screen whose Continue row exists only for a valid card.

var _continue_card: SaveCardMetadata


func _build_screen() -> void:
	screen_id = &"title"
	var save_service := get_node_or_null("/root/SaveService")
	_continue_card = save_service.latest_story_card() if save_service != null else null
	if _continue_card != null:
		_add_frame(Rect2(172, 68, 140, 96))
		_add_row(&"ui.title.continue", &"continue_game", &"title.continue", Rect2(178, 73, 128, 15))
		_add_row(&"ui.title.new_profile", &"new_profile", &"title.new_profile", Rect2(178, 91, 128, 15))
		_add_row(&"ui.title.options", &"open_options", &"title.options", Rect2(178, 109, 128, 15))
		_add_row(&"ui.title.credits", &"open_credits", &"title.credits", Rect2(178, 127, 128, 15))
		_add_row(&"ui.title.quit", &"quit", &"title.quit", Rect2(178, 145, 128, 15))
	else:
		_add_frame(Rect2(172, 74, 140, 80))
		_add_row(&"ui.title.new_profile", &"new_profile", &"title.new_profile", Rect2(178, 80, 128, 15))
		_add_row(&"ui.title.options", &"open_options", &"title.options", Rect2(178, 98, 128, 15))
		_add_row(&"ui.title.credits", &"open_credits", &"title.credits", Rect2(178, 116, 128, 15))
		_add_row(&"ui.title.quit", &"quit", &"title.quit", Rect2(178, 134, 128, 15))


func _activate_row(row: ListRow) -> void:
	if row.command_id == &"continue_game" and _continue_card != null:
		command_requested.emit(&"continue_game", {
			"profile_id": _continue_card.profile_id,
			"slot_id": _continue_card.slot_id,
		})
		return
	super._activate_row(row)


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
