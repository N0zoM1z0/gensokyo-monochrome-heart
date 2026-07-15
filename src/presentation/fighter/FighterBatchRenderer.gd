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

const TEXTURE_SIZE := 7
const CENTER := 3

var _capacity: int = 0
var _batch_color := Color(-1, -1, -1, -1)
var _meshes: Array[MultiMesh] = []
var _textures: Array[Texture2D] = []
var _quad_mesh: QuadMesh


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


func draw_effects(canvas: CanvasItem, count: int, foreground: Color) -> void:
	if canvas == null or count <= 0:
		return
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
		_quad_mesh = QuadMesh.new()
		_quad_mesh.size = Vector2(TEXTURE_SIZE, TEXTURE_SIZE)
		for batch: int in range(Batch.COUNT):
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_2D
			multimesh.use_colors = true
			multimesh.mesh = _quad_mesh
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
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match batch:
		Batch.AMULET:
			_draw_box(image, 2, 1, 4, 5)
		Batch.STAR:
			for offset: int in range(1, 6):
				_set_pixel(image, offset, CENTER)
				_set_pixel(image, CENTER, offset)
		Batch.LASER:
			_draw_box(image, 0, 2, 6, 4)
		Batch.EFFECT:
			_draw_box(image, 2, 2, 4, 4)
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
