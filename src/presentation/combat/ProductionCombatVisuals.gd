class_name ProductionCombatVisuals
extends RefCounted
## Production bullet masks and accessible character VFX cells for packed renderers.

const CELL_SIZE := Vector2i(16, 16)
const BULLET_MASK_SIZE := 9
const CHARACTER_CELL_SIZE := Vector2i(24, 32)
const CHARACTER_MARKER_SIZE := Vector2i(18, 24)
const BULLET_ATLAS: Texture2D = preload("res://assets/art/production/bullets/bul_core_shapes_12.png")
const VFX_STANDARD: Texture2D = preload("res://assets/art/production/vfx/vfx_launch_standard.png")
const VFX_REDUCED: Texture2D = preload("res://assets/art/production/vfx/vfx_launch_reduced_flash.png")
const BULLET_SHAPES: Array[StringName] = [
	&"amulet", &"needle", &"orb", &"star", &"knife", &"butterfly",
	&"leaf", &"arrow", &"shard", &"plate", &"spirit", &"keystone_chip",
]
const VFX_CHARACTERS: Array[StringName] = [
	&"char.reimu_hakurei",
	&"char.marisa_kirisame",
	&"char.sakuya_izayoi",
	&"char.remilia_scarlet",
	&"char.youmu_konpaku",
	&"char.aya_shameimaru",
	&"char.sanae_kochiya",
	&"char.tenshi_hinanawi",
]
const CHARACTER_SHEETS := {
	&"char.reimu_hakurei": preload("res://assets/art/production/characters/reimu_hakurei/chr_reimu_hakurei_m_core.png"),
	&"char.marisa_kirisame": preload("res://assets/art/production/characters/marisa_kirisame/chr_marisa_kirisame_m_core.png"),
	&"char.sakuya_izayoi": preload("res://assets/art/production/characters/sakuya_izayoi/chr_sakuya_izayoi_m_core.png"),
	&"char.remilia_scarlet": preload("res://assets/art/production/characters/remilia_scarlet/chr_remilia_scarlet_m_core.png"),
	&"char.youmu_konpaku": preload("res://assets/art/production/characters/youmu_konpaku/chr_youmu_konpaku_m_core.png"),
	&"char.aya_shameimaru": preload("res://assets/art/production/characters/aya_shameimaru/chr_aya_shameimaru_m_core.png"),
	&"char.sanae_kochiya": preload("res://assets/art/production/characters/sanae_kochiya/chr_sanae_kochiya_m_core.png"),
	&"char.tenshi_hinanawi": preload("res://assets/art/production/characters/tenshi_hinanawi/chr_tenshi_hinanawi_m_core.png"),
}

var _bullet_masks: Dictionary[String, Texture2D] = {}
var _vfx_textures: Dictionary[String, Texture2D] = {}
var _character_textures: Dictionary[String, Texture2D] = {}


func bullet_mask(shape: StringName, outline_only: bool = false) -> Texture2D:
	var shape_index := BULLET_SHAPES.find(shape)
	if shape_index < 0:
		return null
	var cache_key := "%s:%s" % [shape, "outline" if outline_only else "ink"]
	if _bullet_masks.has(cache_key):
		return _bullet_masks[cache_key]
	var source := BULLET_ATLAS.get_image()
	if source == null or source.is_empty() or source.get_size() != Vector2i(96, 32):
		return null
	var cell := source.get_region(Rect2i(
		Vector2i((shape_index % 6) * CELL_SIZE.x, floori(float(shape_index) / 6.0) * CELL_SIZE.y),
		CELL_SIZE
	))
	var mask := _area_sample_ink(cell, BULLET_MASK_SIZE)
	if outline_only:
		mask = _outline(mask)
		if shape == &"knife":
			_restore_knife_spine(mask)
	var texture := ImageTexture.create_from_image(mask)
	_bullet_masks[cache_key] = texture
	return texture


func vfx_texture(
	character_id: StringName,
	frame: int,
	reduced_flash: bool,
	inverted: bool
) -> Texture2D:
	var character_index := VFX_CHARACTERS.find(character_id)
	if character_index < 0 or frame < 0 or frame >= 4:
		return null
	var cache_key := "%s:%d:%s:%s" % [
		character_id, frame, "reduced" if reduced_flash else "standard", "D" if inverted else "A",
	]
	if _vfx_textures.has(cache_key):
		return _vfx_textures[cache_key]
	var atlas := VFX_REDUCED if reduced_flash else VFX_STANDARD
	var source := atlas.get_image()
	if source == null or source.is_empty() or source.get_size() != Vector2i(64, 128):
		return null
	var image := source.get_region(Rect2i(
		Vector2i(frame * CELL_SIZE.x, character_index * CELL_SIZE.y),
		CELL_SIZE
	))
	_apply_polarity(image, inverted)
	var texture := ImageTexture.create_from_image(image)
	_vfx_textures[cache_key] = texture
	return texture


func vfx_mask(
	character_id: StringName,
	frame: int,
	reduced_flash: bool,
	target_size: int = BULLET_MASK_SIZE
) -> Texture2D:
	var source_texture := vfx_texture(character_id, frame, reduced_flash, false)
	if source_texture == null or target_size <= 0:
		return null
	var cache_key := "mask:%s:%d:%s:%d" % [character_id, frame, reduced_flash, target_size]
	if _vfx_textures.has(cache_key):
		return _vfx_textures[cache_key]
	var source := source_texture.get_image()
	var mask := _area_sample_ink(source, target_size)
	var texture := ImageTexture.create_from_image(mask)
	_vfx_textures[cache_key] = texture
	return texture


func character_marker(character_id: StringName, frame: int, inverted: bool) -> Texture2D:
	if not CHARACTER_SHEETS.has(character_id) or frame < 0 or frame >= 16:
		return null
	var cache_key := "%s:%d:%s" % [character_id, frame, "D" if inverted else "A"]
	if _character_textures.has(cache_key):
		return _character_textures[cache_key]
	var source_texture := CHARACTER_SHEETS[character_id] as Texture2D
	var source := source_texture.get_image()
	if source == null or source.is_empty() or source.get_size() != Vector2i(384, 32):
		return null
	var cell := source.get_region(Rect2i(
		Vector2i(frame * CHARACTER_CELL_SIZE.x, 0),
		CHARACTER_CELL_SIZE
	))
	var compact := _area_sample_palette(cell, CHARACTER_MARKER_SIZE, inverted)
	var texture := ImageTexture.create_from_image(compact)
	_character_textures[cache_key] = texture
	return texture


static func _area_sample_ink(source: Image, target_size: int) -> Image:
	var target := Image.create(target_size, target_size, false, Image.FORMAT_RGBA8)
	for target_y: int in range(target_size):
		for target_x: int in range(target_size):
			var source_left := floori(target_x * source.get_width() / float(target_size))
			var source_right := ceili((target_x + 1) * source.get_width() / float(target_size))
			var source_top := floori(target_y * source.get_height() / float(target_size))
			var source_bottom := ceili((target_y + 1) * source.get_height() / float(target_size))
			var has_ink := false
			for source_y: int in range(source_top, source_bottom):
				for source_x: int in range(source_left, source_right):
					var pixel := source.get_pixel(source_x, source_y)
					if pixel.a > 0.0 and pixel.r < 0.5:
						has_ink = true
			if has_ink:
				target.set_pixel(target_x, target_y, Color.WHITE)
	return target


static func _outline(source: Image) -> Image:
	var outlined := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y: int in range(source.get_height()):
		for x: int in range(source.get_width()):
			if source.get_pixel(x, y).a <= 0.0:
				continue
			var edge := false
			for neighbor: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var point := Vector2i(x, y) + neighbor
				if point.x < 0 or point.y < 0 or point.x >= source.get_width() or point.y >= source.get_height() or source.get_pixelv(point).a <= 0.0:
					edge = true
			if edge:
				outlined.set_pixel(x, y, Color.WHITE)
	return outlined


static func _restore_knife_spine(image: Image) -> void:
	# The authored knife is only two source pixels thick. Preserve its connected
	# diagonal gesture after the generic paper-outline reduction.
	for x: int in range(2, 8):
		image.set_pixel(x, 9 - x, Color.WHITE)


static func _area_sample_palette(source: Image, target_size: Vector2i, inverted: bool) -> Image:
	var target := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	for target_y: int in range(target_size.y):
		for target_x: int in range(target_size.x):
			var source_left := floori(target_x * source.get_width() / float(target_size.x))
			var source_right := ceili((target_x + 1) * source.get_width() / float(target_size.x))
			var source_top := floori(target_y * source.get_height() / float(target_size.y))
			var source_bottom := ceili((target_y + 1) * source.get_height() / float(target_size.y))
			var has_visible := false
			var has_ink := false
			for source_y: int in range(source_top, source_bottom):
				for source_x: int in range(source_left, source_right):
					var pixel := source.get_pixel(source_x, source_y)
					if pixel.a <= 0.0:
						continue
					has_visible = true
					has_ink = has_ink or pixel.r < 0.5
			if has_visible:
				var value := 1.0 if has_ink == inverted else 0.0
				target.set_pixel(target_x, target_y, Color(value, value, value, 1.0))
	return target


static func _apply_polarity(image: Image, inverted: bool) -> void:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			var is_source_ink := pixel.r < 0.5
			var value := 1.0 if is_source_ink == inverted else 0.0
			image.set_pixel(x, y, Color(value, value, value, pixel.a))
