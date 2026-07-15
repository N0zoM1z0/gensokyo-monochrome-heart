class_name IntuitiveFloatPreview
extends RefCounted
## Nonnumeric traversal diagnostic for Reimu's Intuitive Float companion skill.

var is_enabled: bool = true
var points: PackedVector2Array = PackedVector2Array()


func rebuild(origin: Vector2, facing: Vector2) -> void:
	points.clear()
	if not is_enabled:
		return
	var direction := signf(facing.x) if not is_zero_approx(facing.x) else 1.0
	for index: int in range(1, 7):
		var t := float(index) / 6.0
		points.append(origin + Vector2(direction * index * 9, -sin(t * PI) * 22))
