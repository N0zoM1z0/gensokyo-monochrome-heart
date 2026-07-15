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


func _focus_changed(_row: ListRow) -> void:
	_apply_scale_layout()


func _refresh_screen() -> void:
	super._refresh_screen()
	_apply_scale_layout()


func _apply_scale_layout() -> void:
	if rows.is_empty() or frames.is_empty():
		return
	var percent := ui_scale_percent()
	if percent == 100:
		var start_y := 73 if _continue_card != null else 80
		for index: int in range(rows.size()):
			rows[index].visible = true
			rows[index].position = Vector2(178, start_y + index * 18)
			rows[index].size = Vector2(128, 15)
		frames[0].position = Vector2(172, 68 if _continue_card != null else 74)
		frames[0].size = Vector2(140, 96 if _continue_card != null else 80)
		return
	frames[0].position = Vector2(12, 37)
	frames[0].size = Vector2(296, 112)
	var visible_count := mini(rows.size(), 5 if percent == 125 else 4)
	var row_height := 20 if percent == 125 else 25
	var row_step := 22 if percent == 125 else 27
	var first := clampi(focused_index - 1, 0, rows.size() - visible_count)
	for index: int in range(rows.size()):
		var slot := index - first
		rows[index].visible = slot >= 0 and slot < visible_count
		if rows[index].visible:
			rows[index].position = Vector2(18, 41 + slot * row_step)
			rows[index].size = Vector2(284, row_height)


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(8, 8, 304, 164), foreground, false, 2.0)
	if ui_scale_percent() > 100:
		_draw_localized(&"ui.title.logo", Vector2(16, 29), 288, HORIZONTAL_ALIGNMENT_CENTER, 7)
		_draw_localized_wrapped(&"ui.title.unofficial", Rect2(16, 151, 288, 20), 1, 7)
		return
	draw_rect(Rect2(16, 18, 144, 50), foreground, false, 2.0)
	draw_line(Vector2(30, 56), Vector2(66, 28), foreground, 2.0)
	draw_line(Vector2(66, 28), Vector2(102, 56), foreground, 2.0)
	draw_line(Vector2(42, 56), Vector2(90, 56), foreground, 2.0)
	draw_rect(Rect2(62, 38, 8, 18), foreground, false, 2.0)
	draw_rect(Rect2(118, 34, 8, 8), foreground)
	draw_rect(Rect2(126, 34, 8, 8), foreground)
	draw_rect(Rect2(122, 42, 8, 8), foreground)
	_draw_localized_wrapped(&"ui.title.logo", Rect2(16, 72, 144, 30), 2)
	_draw_localized_wrapped(&"ui.title.unofficial", Rect2(16, 126, 144, 28), 2, 10 if active_locale() == &"ja" else 7)
	_draw_localized(&"ui.title.version", Vector2(16, 168), 144, HORIZONTAL_ALIGNMENT_RIGHT, 10 if active_locale() == &"ja" else 7)
