class_name FighterBatchRenderer
extends RefCounted
## Four texture batches over packed fighter projectiles/effects; no per-item draw calls.

enum Batch {
	AMULET,
	STAR,
	LASER,
	EFFECT,
	COUNT,
}

const TEXTURE_SIZE := ProductionCombatVisuals.BULLET_MASK_SIZE
const EFFECT_SIZE := 15

var _capacity: int = 0
var _batch_color := Color(-1, -1, -1, -1)
var _meshes: Array[MultiMesh] = []
var _textures: Array[Texture2D] = []
var _reduced_effects: bool = false
var _production := ProductionCombatVisuals.new()


func draw_projectiles(
	canvas: CanvasItem,
	pool: FighterProjectilePool,
	ground_y: int,
	foreground: Color
) -> void:
	if canvas == null or pool == null:
		return
	_ensure_batches(pool.capacity, foreground)
	var counts := PackedInt32Array()
	counts.resize(Batch.COUNT)
	for index: int in range(pool.capacity):
		if pool.used[index] == 0:
			continue
		var batch := _projectile_batch(StringName(pool.family[index]))
		var instance_index := counts[batch]
		var position := Vector2(
			roundi(pool.x_fp[index] / 256.0),
			ground_y - roundi(pool.y_fp[index] / 256.0)
		)
		_meshes[batch].set_instance_transform_2d(instance_index, Transform2D(0.0, position))
		counts[batch] = instance_index + 1
	for batch: int in range(Batch.EFFECT):
		_draw_batch(canvas, batch, counts[batch])


func draw_effects(canvas: CanvasItem, count: int, foreground: Color, reduced_flash: bool = false) -> void:
	if canvas == null or count <= 0:
		return
	if _reduced_effects != reduced_flash:
		_reduced_effects = reduced_flash
		_capacity = 0
	_ensure_batches(maxi(128, count), foreground)
	for index: int in range(count):
		var position := Vector2(
			9 + posmod(index * 37, 302),
			49 + posmod(index * 19, 82)
		)
		_meshes[Batch.EFFECT].set_instance_transform_2d(index, Transform2D(0.0, position))
	_draw_batch(canvas, Batch.EFFECT, count)


func _draw_batch(canvas: CanvasItem, batch: int, count: int) -> void:
	_meshes[batch].visible_instance_count = count
	if count > 0:
		canvas.draw_multimesh(_meshes[batch], _textures[batch])


func _projectile_batch(family: StringName) -> int:
	match family:
		&"star":
			return Batch.STAR
		&"laser":
			return Batch.LASER
		_:
			return Batch.AMULET


func _ensure_batches(capacity: int, foreground: Color) -> void:
	if _capacity != capacity:
		_capacity = capacity
		_batch_color = Color(-1, -1, -1, -1)
		_meshes.clear()
		_textures.clear()
		for batch: int in range(Batch.COUNT):
			var quad_mesh := QuadMesh.new()
			var texture_size := EFFECT_SIZE if batch == Batch.EFFECT else TEXTURE_SIZE
			quad_mesh.size = Vector2(texture_size, texture_size)
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_2D
			multimesh.use_colors = true
			multimesh.mesh = quad_mesh
			multimesh.instance_count = capacity
			multimesh.visible_instance_count = 0
			_meshes.append(multimesh)
			_textures.append(_make_texture(batch))
	if _batch_color == foreground:
		return
	_batch_color = foreground
	for multimesh: MultiMesh in _meshes:
		for index: int in range(_capacity):
			multimesh.set_instance_color(index, foreground)


func _make_texture(batch: int) -> Texture2D:
	var production_texture: Texture2D
	match batch:
		Batch.AMULET:
			production_texture = _production.bullet_mask(&"amulet")
		Batch.STAR:
			production_texture = _production.bullet_mask(&"star")
		Batch.LASER:
			production_texture = _production.bullet_mask(&"needle")
		Batch.EFFECT:
			production_texture = _production.vfx_mask(&"char.reimu_hakurei", 2, _reduced_effects, EFFECT_SIZE)
	if production_texture != null:
		return production_texture
	var texture_size := EFFECT_SIZE if batch == Batch.EFFECT else TEXTURE_SIZE
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match batch:
		Batch.AMULET:
			_draw_box(image, 3, 1, 5, 7)
		Batch.STAR:
			for offset: int in range(1, 8):
				_set_pixel(image, offset, 4)
				_set_pixel(image, 4, offset)
		Batch.LASER:
			_draw_box(image, 0, 3, 8, 5)
		Batch.EFFECT:
			_draw_box(image, 2, 2, 12, 12)
	return ImageTexture.create_from_image(image)


func _draw_box(image: Image, left: int, top: int, right: int, bottom: int) -> void:
	for x: int in range(left, right + 1):
		_set_pixel(image, x, top)
		_set_pixel(image, x, bottom)
	for y: int in range(top, bottom + 1):
		_set_pixel(image, left, y)
		_set_pixel(image, right, y)


func _set_pixel(image: Image, x: int, y: int) -> void:
	image.set_pixel(x, y, Color.WHITE)
