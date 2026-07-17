class_name ProductionRegionTiles
extends RefCounted
## Palette-safe access and data-only metadata for the five production region atlases.

const TILE_SIZE := Vector2i(16, 16)
const ATLAS_SIZE := Vector2i(128, 128)
const TILES_PER_ROW := 8
const TILE_COUNT := 64
const ROW_NAMES: Array[StringName] = [
	&"terrain",
	&"collision_edges",
	&"architecture",
	&"props",
	&"calm",
	&"incident",
	&"route_season",
	&"after",
]
const REGIONS := {
	&"loc.hakurei_shrine": preload("res://assets/art/production/regions/loc_hakurei_shrine_tiles_64.png"),
	&"loc.scarlet_devil_mansion": preload("res://assets/art/production/regions/loc_scarlet_devil_mansion_tiles_64.png"),
	&"loc.youkai_mountain": preload("res://assets/art/production/regions/loc_youkai_mountain_tiles_64.png"),
	&"loc.eientei_bamboo_forest": preload("res://assets/art/production/regions/loc_eientei_bamboo_forest_tiles_64.png"),
	&"loc.hakugyokurou": preload("res://assets/art/production/regions/loc_hakugyokurou_tiles_64.png"),
}
const REGION_ALIASES := {
	&"loc.eientei": &"loc.eientei_bamboo_forest",
}
const COLLISION_SHAPES: Array[StringName] = [
	&"solid",
	&"floor",
	&"ceiling",
	&"wall_left",
	&"wall_right",
	&"slope_up",
	&"slope_down",
	&"one_way_floor",
]
const INTERACTION_SHAPES: Array[StringName] = [
	&"observe",
	&"carry",
	&"repair",
	&"danger",
	&"rumor",
	&"memory",
	&"companion",
	&"landmark",
]
const MATERIAL_SFX := {
	&"loc.hakurei_shrine": &"material.wood",
	&"loc.scarlet_devil_mansion": &"material.stone",
	&"loc.youkai_mountain": &"material.earth",
	&"loc.eientei_bamboo_forest": &"material.bamboo",
	&"loc.hakugyokurou": &"material.grass",
}

var _palette_textures: Dictionary[String, Texture2D] = {}


func canonical_region_id(region_id: StringName) -> StringName:
	return REGION_ALIASES.get(region_id, region_id) as StringName


func has_region(region_id: StringName) -> bool:
	return REGIONS.has(canonical_region_id(region_id))


func texture_for(region_id: StringName, inverted: bool) -> Texture2D:
	var canonical_id := canonical_region_id(region_id)
	if not REGIONS.has(canonical_id):
		return null
	var source := REGIONS[canonical_id] as Texture2D
	var cache_key := "%s:%s" % [canonical_id, "D" if inverted else "A"]
	if _palette_textures.has(cache_key):
		return _palette_textures[cache_key]
	var image := source.get_image()
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
	_palette_textures[cache_key] = texture
	return texture


func source_rect(tile_index: int) -> Rect2:
	if tile_index < 0 or tile_index >= TILE_COUNT:
		return Rect2()
	return Rect2(
		Vector2((tile_index % TILES_PER_ROW) * TILE_SIZE.x, floori(float(tile_index) / TILES_PER_ROW) * TILE_SIZE.y),
		Vector2(TILE_SIZE)
	)


func metadata_for(region_id: StringName, tile_index: int) -> Dictionary:
	var canonical_id := canonical_region_id(region_id)
	if not REGIONS.has(canonical_id) or tile_index < 0 or tile_index >= TILE_COUNT:
		return {}
	var row := floori(float(tile_index) / TILES_PER_ROW)
	var column := tile_index % TILES_PER_ROW
	var row_name := ROW_NAMES[row]
	var collision_shape := COLLISION_SHAPES[column] if row_name == &"collision_edges" else &"none"
	var interaction_shape := INTERACTION_SHAPES[column] if row_name == &"props" else &"none"
	return {
		"tile_id": StringName("tile.%s.%s.%02d" % [String(canonical_id).trim_prefix("loc."), row_name, column]),
		"region_id": canonical_id,
		"collision_shape": collision_shape,
		"collision_polygon": _collision_polygon(collision_shape),
		"occlusion_band": _occlusion_band(row_name),
		"interaction_shape": interaction_shape,
		"material_sfx": MATERIAL_SFX[canonical_id],
		"profile_safe": true,
		"state_tags": _state_tags(row_name, column),
	}


static func _occlusion_band(row_name: StringName) -> StringName:
	if row_name == &"architecture":
		return &"mid"
	if row_name in [&"terrain", &"collision_edges", &"props"]:
		return &"play"
	return &"far"


static func _state_tags(row_name: StringName, column: int) -> Array[StringName]:
	match row_name:
		&"calm":
			return [&"calm"]
		&"incident":
			return [&"incident"]
		&"route_season":
			return [&"route"] if column < 4 else [&"season"]
		&"after":
			return [&"after"]
		_:
			return []


static func _collision_polygon(shape: StringName) -> PackedVector2Array:
	match shape:
		&"solid":
			return PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)])
		&"floor", &"one_way_floor":
			return PackedVector2Array([Vector2(0, 12), Vector2(16, 12), Vector2(16, 16), Vector2(0, 16)])
		&"ceiling":
			return PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(16, 4), Vector2(0, 4)])
		&"wall_left":
			return PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 16), Vector2(0, 16)])
		&"wall_right":
			return PackedVector2Array([Vector2(12, 0), Vector2(16, 0), Vector2(16, 16), Vector2(12, 16)])
		&"slope_up":
			return PackedVector2Array([Vector2(0, 16), Vector2(16, 0), Vector2(16, 16)])
		&"slope_down":
			return PackedVector2Array([Vector2(0, 0), Vector2(16, 16), Vector2(0, 16)])
		_:
			return PackedVector2Array()
