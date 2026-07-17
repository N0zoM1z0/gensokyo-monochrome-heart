class_name ProductionUiArt
extends RefCounted
## Palette-safe frames and semantic marks from the reviewed production UI export.

const ATLAS_SIZE := Vector2i(256, 128)
const ATLAS: Texture2D = preload("res://assets/art/production/ui/ui_one_bit_export_atlas.png")
const FRAME_RECTS: Array[Rect2] = [
	Rect2(4, 4, 72, 28),
	Rect2(84, 4, 72, 28),
	Rect2(164, 4, 72, 28),
]
const ICON_RECTS := {
	&"confirm": Rect2(4, 110, 16, 16),
	&"cancel": Rect2(32, 110, 20, 16),
	&"assist": Rect2(64, 110, 16, 16),
	&"neutral": Rect2(88, 110, 16, 16),
	&"status": Rect2(114, 110, 18, 16),
}

var _palettes: Dictionary[String, Texture2D] = {}
var _regions: Dictionary[String, Texture2D] = {}
var _styles: Dictionary[String, StyleBoxTexture] = {}


func texture_for(inverted: bool) -> Texture2D:
	var cache_key := "D" if inverted else "A"
	if _palettes.has(cache_key):
		return _palettes[cache_key]
	var image := ATLAS.get_image()
	if image == null or image.is_empty() or image.get_size() != ATLAS_SIZE:
		return null
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			var is_source_ink := pixel.r < 0.5
			var value := 1.0 if is_source_ink == inverted else 0.0
			image.set_pixel(x, y, Color(value, value, value, pixel.a))
	var texture := ImageTexture.create_from_image(image)
	_palettes[cache_key] = texture
	return texture


func frame_style(frame_index: int, inverted: bool) -> StyleBoxTexture:
	if frame_index < 0 or frame_index >= FRAME_RECTS.size():
		return null
	var cache_key := "%d:%s" % [frame_index, "D" if inverted else "A"]
	if _styles.has(cache_key):
		return _styles[cache_key]
	var region := _region_texture(FRAME_RECTS[frame_index], cache_key, inverted)
	if region == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = region
	for side: int in range(4):
		style.set_texture_margin(side, 4.0)
	_styles[cache_key] = style
	return style


func icon_texture(icon_id: StringName, inverted: bool) -> Texture2D:
	if not ICON_RECTS.has(icon_id):
		return null
	return _region_texture(ICON_RECTS[icon_id], "icon:%s:%s" % [icon_id, inverted], inverted)


func _region_texture(rect: Rect2, cache_key: String, inverted: bool) -> Texture2D:
	if _regions.has(cache_key):
		return _regions[cache_key]
	var atlas := texture_for(inverted)
	if atlas == null:
		return null
	var region := AtlasTexture.new()
	region.atlas = atlas
	region.region = rect
	_regions[cache_key] = region
	return region
