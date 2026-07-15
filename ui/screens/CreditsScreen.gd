class_name CreditsScreen
extends UiScreenBase
## Title-accessible legal and asset credits with a readable default scroll rate.

const DEFAULT_SCROLL_SPEED := 18.0
const FAST_SCROLL_SPEED := 48.0
const CREDIT_KEYS: Array[StringName] = [
	&"ui.credits.fanwork",
	&"ui.credits.touhou",
	&"ui.credits.production",
	&"ui.credits.engine",
	&"ui.credits.font",
	&"ui.credits.audio",
	&"ui.credits.assets",
]

var scroll_offset: float = 0.0
var is_paused: bool = false
var is_fast: bool = false
var is_complete: bool = false


func _build_screen() -> void:
	screen_id = &"credits"
	_add_frame(Rect2(8, 8, 304, 164))
	_add_action_hint(GameInput.CANCEL, &"ui.common.cancel", Rect2(224, 157, 78, 10))


func _process(delta: float) -> void:
	super._process(delta)
	if is_paused or is_complete:
		return
	var speed := FAST_SCROLL_SPEED if is_fast else DEFAULT_SCROLL_SPEED
	scroll_offset += maxf(0.0, delta) * speed
	var final_offset := CREDIT_KEYS.size() * 18.0 + 42.0
	if scroll_offset >= final_offset:
		scroll_offset = final_offset
		is_complete = true
	queue_redraw()


func handle_semantic_action(action: StringName) -> void:
	match action:
		GameInput.CONFIRM:
			if is_complete:
				scroll_offset = 0.0
				is_complete = false
				is_paused = false
			else:
				is_paused = not is_paused
			queue_redraw()
		GameInput.PAGE_LEFT, GameInput.PAGE_RIGHT:
			is_fast = not is_fast
			queue_redraw()
		GameInput.CANCEL:
			command_requested.emit(&"back", {})


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	var background := profile.ink if profile.is_inverted else profile.paper
	_draw_localized(&"ui.credits.title", Vector2(16, 25), 288, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(Rect2(12, 32, 296, 119), background)
	draw_rect(Rect2(12, 32, 296, 119), foreground, false, 1.0)
	for index: int in range(CREDIT_KEYS.size()):
		var y := 60.0 + index * 18.0 - scroll_offset
		if y < 42.0 or y > 145.0:
			continue
		_draw_localized(CREDIT_KEYS[index], Vector2(20, y), 280, HORIZONTAL_ALIGNMENT_CENTER, 7)
	if is_complete:
		draw_rect(Rect2(28, 79, 264, 24), background)
		draw_rect(Rect2(28, 79, 264, 24), foreground, false, 1.0)
		_draw_localized(&"ui.credits.complete", Vector2(34, 94), 252, HORIZONTAL_ALIGNMENT_CENTER, 7)
	_draw_localized(&"ui.credits.controls", Vector2(18, 165), 198, HORIZONTAL_ALIGNMENT_LEFT, 6)
