class_name PanelFrame
extends Control
## Shared catalog frame with identical content margins across A/B/C/D skins.

@export var profile_id: StringName = &"A"
@export var state: StringName = &"idle"
@export var content_margin: int = 4
@export var fill_background: bool = false


func set_profile(next_profile_id: StringName) -> void:
	profile_id = next_profile_id
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	if fill_background:
		draw_rect(Rect2(Vector2.ZERO, size), background)
	match profile.profile_id:
		&"B":
			draw_rect(Rect2(0, 0, size.x, size.y), foreground, false, 1.0)
			draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), foreground, false, 1.0)
		&"C":
			draw_rect(Rect2(0, 0, size.x, size.y), foreground, false, 2.0)
			if size.x >= 16 and size.y >= 16:
				draw_colored_polygon(
					PackedVector2Array([Vector2(size.x - 12, 0), Vector2(size.x, 0), Vector2(size.x, 12)]),
					foreground
				)
		&"D":
			draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), foreground, false, 2.0)
		_:
			draw_line(Vector2(4, 0), Vector2(size.x - 4, 0), foreground, 2.0)
			draw_line(Vector2(0, 4), Vector2(0, size.y - 4), foreground, 2.0)
			draw_line(Vector2(4, size.y), Vector2(size.x - 4, size.y), foreground, 2.0)
			draw_line(Vector2(size.x, 4), Vector2(size.x, size.y - 4), foreground, 2.0)
	if state == &"urgent":
		draw_rect(Rect2(6, 6, 4, 4), foreground)
	elif state == &"disabled":
		draw_line(Vector2(6, size.y - 7), Vector2(size.x - 6, size.y - 7), foreground, 1.0)
