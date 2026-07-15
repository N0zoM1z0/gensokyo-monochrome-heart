class_name PixelToggle
extends Control
## Binary setting indicator with position, shape, and localized text redundancy.

@export var is_on: bool = false
@export var profile_id: StringName = &"A"


func set_value(next_value: bool, next_profile_id: StringName) -> void:
	is_on = next_value
	profile_id = next_profile_id
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(0, 1, size.x, size.y - 2), foreground, false, 1.0)
	var marker_x: float = size.x - 9 if is_on else 3.0
	draw_rect(Rect2(marker_x, 4, 6, size.y - 8), foreground)
	if is_on:
		draw_line(Vector2(3, size.y / 2), Vector2(8, size.y / 2), foreground, 2.0)
