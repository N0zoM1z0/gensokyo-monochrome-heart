class_name TransitionOverlay
extends Control
## Integer-frame paper fold or accessibility-safe border tick.

const STYLE_PAPER_FOLD: StringName = &"paper_fold"
const STYLE_BORDER_TICK: StringName = &"border_tick"

var style: StringName = STYLE_PAPER_FOLD
var phase: StringName = &"idle"
var frame_index: int = 0
var frame_count: int = 3
var profile_id: StringName = &"A"


func configure(
	next_style: StringName,
	next_phase: StringName,
	next_frame_index: int,
	next_frame_count: int,
	next_profile_id: StringName
) -> void:
	style = next_style
	phase = next_phase
	frame_index = next_frame_index
	frame_count = maxi(1, next_frame_count)
	profile_id = next_profile_id
	visible = phase != &"idle"
	queue_redraw()


func clear() -> void:
	phase = &"idle"
	visible = false
	queue_redraw()


func _draw() -> void:
	if phase == &"idle":
		return
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var foreground := profile.paper if profile.is_inverted else profile.ink
	if style == STYLE_BORDER_TICK:
		_draw_border_tick(foreground)
	else:
		_draw_paper_fold(foreground)


func _draw_border_tick(foreground: Color) -> void:
	var inset := maxi(0, frame_count - frame_index - 1)
	draw_rect(Rect2(inset, inset, size.x - inset * 2, size.y - inset * 2), foreground, false, 2.0)
	var tick_width := mini(32, 8 + frame_index * 12)
	draw_rect(Rect2(4, 4, tick_width, 2), foreground)
	draw_rect(Rect2(size.x - tick_width - 4, size.y - 6, tick_width, 2), foreground)


func _draw_paper_fold(foreground: Color) -> void:
	var progress_frame := frame_index + 1 if phase == &"cover" else frame_count - frame_index - 1
	var covered_width := clampi((int(size.x) * progress_frame) / frame_count, 0, int(size.x))
	if covered_width <= 0:
		return
	draw_rect(Rect2(0, 0, covered_width, size.y), foreground)
	var seam_x := mini(int(size.x) - 1, covered_width)
	for y: int in range(0, int(size.y), 4):
		var tooth := 2 if (y / 4) % 2 == 0 else 0
		draw_rect(Rect2(seam_x - tooth, y, 1 + tooth, 2), foreground)
