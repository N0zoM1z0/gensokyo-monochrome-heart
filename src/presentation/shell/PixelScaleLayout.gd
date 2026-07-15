class_name PixelScaleLayout
extends RefCounted
## Exact integer-scale placement of the logical canvas inside a physical window.

var scale: int
var content_size: Vector2i
var letterbox_offset: Vector2i
var content_rect: Rect2i


func _init(p_scale: int, p_content_size: Vector2i, p_letterbox_offset: Vector2i) -> void:
	scale = p_scale
	content_size = p_content_size
	letterbox_offset = p_letterbox_offset
	content_rect = Rect2i(letterbox_offset, content_size)
