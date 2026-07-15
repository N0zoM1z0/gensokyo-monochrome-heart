class_name AccessibilityScreen
extends UiScreenBase
## First-run preset choice that remains presentation/gameplay-assist only.


func _build_screen() -> void:
	screen_id = &"accessibility"
	_add_frame(Rect2(36, 18, 248, 144))
	_add_row(&"accessibility.preset.original", &"preset_original", &"accessibility.original", Rect2(52, 54, 216, 18))
	_add_row(&"accessibility.preset.story", &"preset_story", &"accessibility.story", Rect2(52, 78, 216, 18))
	_add_row(&"accessibility.preset.low_motion", &"preset_low_motion", &"accessibility.low_motion", Rect2(52, 102, 216, 18))
	_add_action_hint(GameInput.CONFIRM, &"ui.common.confirm", Rect2(52, 146, 92, 12))


func _activate_row(row: ListRow) -> void:
	var preset_id: StringName = &"original"
	match row.command_id:
		&"preset_story":
			preset_id = &"story"
		&"preset_low_motion":
			preset_id = &"low_motion"
	command_requested.emit(&"accessibility_selected", {"preset_id": preset_id})


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	_draw_localized(&"ui.accessibility.title", Vector2(40, 40), 240, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(52, 126), Vector2(268, 126), foreground, 1.0)
	_draw_localized_wrapped(&"ui.accessibility.help", Rect2(44, 129, 232, 18), 2)
