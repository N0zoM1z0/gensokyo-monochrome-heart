class_name PauseScreen
extends UiScreenBase
## Synchronous modal pause with ordered mask and a three-frame resume cue.

const RESUME_CUE_FRAMES := 3

var resume_cue_frame: int = -1


func _build_screen() -> void:
	screen_id = &"pause"
	_add_frame(Rect2(180, 16, 136, 148))
	_add_row(&"ui.pause.resume", &"resume", &"pause.resume", Rect2(186, 48, 124, 18))
	_add_row(&"ui.pause.options", &"pause_options", &"pause.options", Rect2(186, 72, 124, 18))
	_add_row(&"ui.pause.return_title", &"return_title", &"pause.return_title", Rect2(186, 96, 124, 18))
	_add_action_hint(GameInput.CANCEL, &"ui.common.cancel", Rect2(190, 140, 116, 12))


func handle_semantic_action(action: StringName) -> void:
	if action == GameInput.PAUSE:
		_handle_cancel()
	else:
		super.handle_semantic_action(action)


func _handle_cancel() -> void:
	command_requested.emit(&"resume", {})


func _refresh_screen() -> void:
	super._refresh_screen()
	var percent := ui_scale_percent()
	if percent == 100:
		var positions := [48, 72, 96]
		for index: int in range(rows.size()):
			rows[index].position = Vector2(186, positions[index])
			rows[index].size = Vector2(124, 18)
		if not frames.is_empty():
			frames[0].position = Vector2(180, 16)
			frames[0].size = Vector2(136, 148)
		if not action_hints.is_empty():
			action_hints[0].position = Vector2(190, 140)
			action_hints[0].size = Vector2(116, 12)
		return
	var row_height := 22 if percent == 125 else 27
	var step := 28 if percent == 125 else 34
	for index: int in range(rows.size()):
		rows[index].position = Vector2(134, 48 + index * step)
		rows[index].size = Vector2(174, row_height)
	if not frames.is_empty():
		frames[0].position = Vector2(126, 12)
		frames[0].size = Vector2(190, 156)
	if not action_hints.is_empty():
		action_hints[0].position = Vector2(134, 145)
		action_hints[0].size = Vector2(174, 22)


func play_resume_cue() -> void:
	interaction_enabled = false
	for frame: int in range(RESUME_CUE_FRAMES):
		resume_cue_frame = frame
		queue_redraw()
		await get_tree().process_frame
	resume_cue_frame = -1
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(_active_profile_id())
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	if _fixture_mode:
		draw_rect(Rect2(0, 0, 320, 180), background)
	for y: int in range(0, 180, 2):
		for x: int in range((y % 4) / 2, 180, 2):
			draw_rect(Rect2(x, y, 1, 1), foreground)
	var panel := Rect2(126, 12, 190, 156) if ui_scale_percent() > 100 else Rect2(180, 16, 136, 148)
	draw_rect(panel, background)
	_draw_localized(&"ui.pause.title", Vector2(panel.position.x + 4, 38), panel.size.x - 8, HORIZONTAL_ALIGNMENT_CENTER)
	if resume_cue_frame >= 0:
		var inset := 2 + resume_cue_frame * 2
		draw_rect(Rect2(inset, inset, 320 - inset * 2, 180 - inset * 2), foreground, false, 2.0)
