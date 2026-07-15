class_name FocusMarker
extends Control
## Device-aware focus marker using a leading wedge and 2px inset corners.

@export var is_active: bool = false
@export var profile_id: StringName = &"A"
@export var device: StringName = &"keyboard"


func configure(active: bool, next_profile_id: StringName, next_device: StringName) -> void:
	is_active = active
	profile_id = next_profile_id
	device = next_device
	visible = active
	queue_redraw()


func _draw() -> void:
	if not is_active:
		return
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_line(Vector2(2, 2), Vector2(size.x - 3, 2), foreground, 2.0)
	draw_line(Vector2(2, size.y - 3), Vector2(size.x - 3, size.y - 3), foreground, 2.0)
	var wedge := PackedVector2Array([Vector2(3, 5), Vector2(7, size.y / 2), Vector2(3, size.y - 5)])
	draw_polyline(wedge, foreground, 1.0)
	if device == &"controller":
		draw_rect(Rect2(size.x - 7, 5, 3, 3), foreground)
	elif device == &"pointer":
		draw_line(Vector2(size.x - 7, 4), Vector2(size.x - 4, 7), foreground, 1.0)
