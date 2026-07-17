class_name ProductionPortraitResolver
extends RefCounted
## Resolves authored emotion tokens to reviewed nine-state production portraits.

const CELL_SIZE := Vector2i(80, 104)
const COMPACT_SIZE := Vector2i(40, 52)
const EXPRESSIONS: Array[StringName] = [
	&"work_neutral",
	&"social_neutral",
	&"amused",
	&"irritated",
	&"focused",
	&"startled",
	&"tired_private",
	&"sincere_restrained",
	&"route_vulnerable",
]
const PACKS := {
	&"char.reimu_hakurei": preload("res://assets/art/production/characters/reimu_hakurei/portrait_reimu_hakurei_nine_states.png"),
	&"char.marisa_kirisame": preload("res://assets/art/production/characters/marisa_kirisame/portrait_marisa_kirisame_nine_states.png"),
	&"char.sakuya_izayoi": preload("res://assets/art/production/characters/sakuya_izayoi/portrait_sakuya_izayoi_nine_states.png"),
	&"char.remilia_scarlet": preload("res://assets/art/production/characters/remilia_scarlet/portrait_remilia_scarlet_nine_states.png"),
	&"char.youmu_konpaku": preload("res://assets/art/production/characters/youmu_konpaku/portrait_youmu_konpaku_nine_states.png"),
	&"char.aya_shameimaru": preload("res://assets/art/production/characters/aya_shameimaru/portrait_aya_shameimaru_nine_states.png"),
	&"char.sanae_kochiya": preload("res://assets/art/production/characters/sanae_kochiya/portrait_sanae_kochiya_nine_states.png"),
	&"char.tenshi_hinanawi": preload("res://assets/art/production/characters/tenshi_hinanawi/portrait_tenshi_hinanawi_nine_states.png"),
}

var _textures: Dictionary[String, Texture2D] = {}


func has_pack(character_id: StringName) -> bool:
	return PACKS.has(character_id)


func texture_for(
	character_id: StringName,
	authored_expression: StringName,
	inverted: bool
) -> Texture2D:
	if not PACKS.has(character_id):
		return null
	var expression := resolve_expression(authored_expression)
	var cache_key := "native:%s:%s:%s" % [character_id, expression, "D" if inverted else "A"]
	if _textures.has(cache_key):
		return _textures[cache_key]
	var image := _source_cell(character_id, expression)
	if image == null:
		return null
	_apply_polarity(image, inverted)
	var texture := ImageTexture.create_from_image(image)
	_textures[cache_key] = texture
	return texture


func compact_texture_for(
	character_id: StringName,
	authored_expression: StringName,
	inverted: bool
) -> Texture2D:
	if not PACKS.has(character_id):
		return null
	var expression := resolve_expression(authored_expression)
	var cache_key := "compact:%s:%s:%s" % [character_id, expression, "D" if inverted else "A"]
	if _textures.has(cache_key):
		return _textures[cache_key]
	var source := _source_cell(character_id, expression)
	if source == null:
		return null
	var compact := Image.create(COMPACT_SIZE.x, COMPACT_SIZE.y, false, Image.FORMAT_RGBA8)
	for target_y: int in range(COMPACT_SIZE.y):
		for target_x: int in range(COMPACT_SIZE.x):
			var has_visible := false
			var has_ink := false
			var alpha := 0.0
			for offset_y: int in range(2):
				for offset_x: int in range(2):
					var pixel := source.get_pixel(target_x * 2 + offset_x, target_y * 2 + offset_y)
					if pixel.a <= 0.0:
						continue
					has_visible = true
					has_ink = has_ink or pixel.r < 0.5
					alpha = maxf(alpha, pixel.a)
			if has_visible:
				var value := 1.0 if has_ink == inverted else 0.0
				compact.set_pixel(target_x, target_y, Color(value, value, value, alpha))
	var texture := ImageTexture.create_from_image(compact)
	_textures[cache_key] = texture
	return texture


func _source_cell(character_id: StringName, expression: StringName) -> Image:
	var source := PACKS[character_id] as Texture2D
	var source_image := source.get_image()
	if source_image == null or source_image.is_empty():
		return null
	var expression_index := EXPRESSIONS.find(expression)
	var image := source_image.get_region(Rect2i(
		Vector2i(expression_index * CELL_SIZE.x, 0),
		CELL_SIZE
	))
	if image == null or image.is_empty() or image.get_size() != CELL_SIZE:
		return null
	return image


func _apply_polarity(image: Image, inverted: bool) -> void:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			var is_source_ink := pixel.r < 0.5
			var value := 1.0 if is_source_ink == inverted else 0.0
			image.set_pixel(x, y, Color(value, value, value, pixel.a))


static func resolve_expression(authored_expression: StringName) -> StringName:
	if authored_expression in EXPRESSIONS:
		return authored_expression
	var token := String(authored_expression).to_lower()
	if _contains_any(token, ["vulnerable", "hurt", "open", "embarrassed", "hesitation", "unsettled", "accountable"]):
		return &"route_vulnerable"
	if _contains_any(token, ["tired", "strained", "weary", "exhausted"]):
		return &"tired_private"
	if _contains_any(token, ["amused", "grin", "playful", "pleased", "bright", "joyful", "triumphant"]):
		return &"amused"
	if _contains_any(token, ["irritated", "angry", "defiant", "annoyed"]):
		return &"irritated"
	if _contains_any(token, ["startled", "surprised", "puzzled", "concern", "uncertain", "fascinated"]):
		return &"startled"
	if _contains_any(token, ["resolved", "focused", "serious", "precise", "sharp", "measured", "commanding", "guarded", "professional", "regal"]):
		return &"focused"
	if _contains_any(token, ["gentle", "warm", "earnest", "grateful", "approv", "relieved", "listening", "attentive", "thoughtful", "curious"]):
		return &"sincere_restrained"
	if _contains_any(token, ["private", "social", "public", "quiet"]):
		return &"social_neutral"
	return &"work_neutral"


static func _contains_any(token: String, fragments: Array[String]) -> bool:
	for fragment: String in fragments:
		if token.contains(fragment):
			return true
	return false
