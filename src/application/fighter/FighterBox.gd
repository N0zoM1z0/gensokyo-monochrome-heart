class_name FighterBox
extends RefCounted
## Integer local combat box; sprite bounds never participate in combat rules.

var x: int = 0
var y: int = 0
var width: int = 1
var height: int = 1


func _init(p_x: int = 0, p_y: int = 0, p_width: int = 1, p_height: int = 1) -> void:
	x = p_x
	y = p_y
	width = p_width
	height = p_height


func global_rect(origin: Vector2i, facing: int) -> Rect2i:
	var mirrored_x := x if facing >= 0 else -x - width
	return Rect2i(origin.x + mirrored_x, origin.y + y, width, height)


func validation_errors(label: String) -> Array[String]:
	var errors: Array[String] = []
	if width <= 0 or height <= 0:
		errors.append("%s combat box must have positive size" % label)
	return errors
