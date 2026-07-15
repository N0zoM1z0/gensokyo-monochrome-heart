class_name ProfileSelectScreen
extends UiScreenBase
## Four visual-only profile cards; semantic actions and outcomes remain invariant.

const CARD_SCENE := preload("res://ui/components/choice_card.tscn")
const PROFILE_IDS: Array[StringName] = [&"A", &"B", &"C", &"D"]
const PROFILE_KEYS: Array[StringName] = [
	&"ui.profile.a",
	&"ui.profile.b",
	&"ui.profile.c",
	&"ui.profile.d",
]

var _opening_profile: StringName = &"A"


func _build_screen() -> void:
	screen_id = &"profile_select"
	var settings := get_node_or_null("/root/SettingsService")
	_opening_profile = settings.preferred_presentation_profile if settings != null else &"A"
	for index: int in range(PROFILE_IDS.size()):
		var card := CARD_SCENE.instantiate() as ChoiceCard
		card.label_key = PROFILE_KEYS[index]
		card.command_id = StringName("profile.%s" % String(PROFILE_IDS[index]).to_lower())
		card.focus_id = StringName("profile.%s" % String(PROFILE_IDS[index]).to_lower())
		card.position = Vector2(8 + index * 76, 36)
		card.size = Vector2(72, 96)
		card.locale = active_locale()
		card.profile_id = PROFILE_IDS[index]
		add_child(card)
		rows.append(card)


func _initial_focus_index() -> int:
	return maxi(0, PROFILE_IDS.find(_opening_profile))


func _move_horizontal(direction: int) -> void:
	_move_focus(direction)


func _focus_changed(_row: ListRow) -> void:
	if _fixture_mode or rows.is_empty():
		return
	var registry := get_node_or_null("/root/UiThemeRegistry")
	if registry != null:
		registry.set_native_profile(PROFILE_IDS[focused_index])


func _activate_row(_row: ListRow) -> void:
	var selected_profile := PROFILE_IDS[focused_index]
	if not _fixture_mode:
		var settings := get_node_or_null("/root/SettingsService")
		if settings != null:
			settings.set_preferred_presentation_profile(selected_profile)
		var registry := get_node_or_null("/root/UiThemeRegistry")
		if registry != null:
			registry.set_native_profile(selected_profile)
	command_requested.emit(&"profile_selected", {"profile_id": selected_profile})


func _handle_cancel() -> void:
	if not _fixture_mode:
		var registry := get_node_or_null("/root/UiThemeRegistry")
		if registry != null:
			registry.set_native_profile(_opening_profile)
	command_requested.emit(&"back", {})


func _refresh_screen() -> void:
	super._refresh_screen()
	for index: int in range(rows.size()):
		rows[index].set_profile(PROFILE_IDS[index])
		if ui_scale_percent() > 100:
			rows[index].custom_minimum_size = Vector2.ZERO
			rows[index].position = Vector2(10 + (index % 2) * 152, 31 + floori(index / 2.0) * 68)
			rows[index].size = Vector2(148, 64)
		else:
			rows[index].custom_minimum_size = Vector2(72, 96)
			rows[index].position = Vector2(8 + index * 76, 36)
			rows[index].size = Vector2(72, 96)


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(4, 4, 312, 172), foreground, false, 2.0)
	_draw_localized(&"ui.profile.title", Vector2(8, 24 if ui_scale_percent() > 100 else 22), 304, HORIZONTAL_ALIGNMENT_CENTER)
	var settings := get_node_or_null("/root/SettingsService")
	var forced_profile: StringName = _fixture_forced_profile_id if _fixture_mode else (settings.forced_presentation_profile if settings != null else &"")
	if forced_profile == &"A" and ui_scale_percent() == 100:
		_draw_localized(&"ui.profile.forced_a", Vector2(8, 156), 304, HORIZONTAL_ALIGNMENT_CENTER)
	elif ui_scale_percent() == 100:
		draw_line(Vector2(24, 152), Vector2(296, 152), foreground, 1.0)
