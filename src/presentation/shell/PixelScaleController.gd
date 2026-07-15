class_name PixelScaleController
extends Node
## Applies the fixed logical canvas and reports deterministic integer letterboxing.

signal layout_changed(layout: PixelScaleLayout)

const DEFAULT_BASE_SIZE := Vector2i(320, 180)
const DEFAULT_MAX_SCALE := 6

@export var base_size: Vector2i = DEFAULT_BASE_SIZE
@export_range(1, 6, 1) var max_integer_scale: int = DEFAULT_MAX_SCALE

var current_layout: PixelScaleLayout


func _ready() -> void:
	var window := get_window()
	window.min_size = base_size
	window.content_scale_size = base_size
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	window.size_changed.connect(_refresh_layout)
	_refresh_layout()


func calculate_layout(window_size: Vector2i) -> PixelScaleLayout:
	var horizontal_scale := window_size.x / base_size.x
	var vertical_scale := window_size.y / base_size.y
	var integer_scale := clampi(mini(horizontal_scale, vertical_scale), 1, max_integer_scale)
	var content_size := base_size * integer_scale
	var letterbox_offset := (window_size - content_size) / 2
	return PixelScaleLayout.new(integer_scale, content_size, letterbox_offset)


func _refresh_layout() -> void:
	current_layout = calculate_layout(get_window().size)
	layout_changed.emit(current_layout)
