class_name FoundationMode
extends UiScreenBase
## Non-gameplay M01 mode proving shell persistence and pause handoff.


func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _build_screen() -> void:
	screen_id = &"foundation_mode"
	_add_frame(Rect2(8, 8, 304, 164))
	_add_action_hint(GameInput.PAUSE, &"ui.mode.pause_hint", Rect2(48, 152, 224, 12))


func _handle_cancel() -> void:
	pass


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	_draw_localized(&"ui.mode.title", Vector2(16, 28), 288, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(32, 38), Vector2(288, 38), foreground, 2.0)
	draw_rect(Rect2(60, 52, 200, 72), foreground, false, 2.0)
	draw_line(Vector2(80, 72), Vector2(240, 72), foreground, 2.0)
	draw_rect(Rect2(124, 84, 72, 22), foreground, false, 2.0)
	draw_line(Vector2(126, 104), Vector2(194, 86), foreground, 1.0)
	_draw_localized(&"ui.mode.body", Vector2(24, 140), 272, HORIZONTAL_ALIGNMENT_CENTER)
