class_name DanmakuBulletBatchRenderer
extends RefCounted
## Ten texture batches over packed bullet data; never one Node or draw call per bullet.

enum Batch {
	TELEGRAPH,
	AMULET_INK,
	AMULET_PAPER,
	OFFERING_INK,
	OFFERING_PAPER,
	MEMORY_INK,
	MEMORY_PAPER,
	KNIFE_INK,
	KNIFE_PAPER,
	DISSOLVE,
	COUNT,
}

const TEXTURE_SIZE := 7
const TEXTURE_CENTER := 3

var rendered_bullet_count: int = 0
var _batch_capacity: int = 0
var _batch_color := Color(-1, -1, -1, -1)
var _meshes: Array[MultiMesh] = []
var _textures: Array[Texture2D] = []
var _quad_mesh: QuadMesh


func draw_field(
	canvas: CanvasItem,
	runtime: BoundaryStainSimulation,
	origin: Vector2,
	display_size: Vector2,
	foreground: Color,
	_background: Color
) -> void:
	rendered_bullet_count = 0
	if canvas == null or runtime == null:
		return
	var pool := runtime.pool
	_ensure_batches(pool.capacity, foreground)
	var scale_y := display_size.y / float(runtime.definition.arena_height)
	var counts := PackedInt32Array()
	counts.resize(Batch.COUNT)
	for index: int in range(pool.capacity):
		if pool.used[index] == 0:
			continue
		var position := Vector2(
			origin.x + roundi(pool.x_fp[index] / 256.0),
			origin.y + roundi(pool.y_fp[index] / 256.0 * scale_y)
		)
		if (
			position.x < origin.x - 8
			or position.x > origin.x + display_size.x + 8
			or position.y < origin.y - 8
			or position.y > origin.y + display_size.y + 8
		):
			continue
		var batch := _batch_for(pool, index)
		if batch >= 0:
			var batch_index := counts[batch]
			_meshes[batch].set_instance_transform_2d(batch_index, Transform2D(0.0, position))
			counts[batch] = batch_index + 1
		rendered_bullet_count += 1
	for batch: int in range(Batch.COUNT):
		_meshes[batch].visible_instance_count = counts[batch]
		if counts[batch] > 0:
			canvas.draw_multimesh(_meshes[batch], _textures[batch])


func draw_safe_lane(
	canvas: CanvasItem,
	runtime: BoundaryStainSimulation,
	origin: Vector2,
	display_size: Vector2,
	foreground: Color
) -> void:
	var safe_lane := runtime.safe_lane_preview()
	var phase := runtime.current_phase()
	if safe_lane < 0 or phase == null:
		return
	var slot_count := 0
	for emitter: DanmakuEmitterDefinition in phase.emitters:
		if emitter.pattern_type == &"safe_lane_grid":
			slot_count = emitter.slot_count
			break
	if slot_count <= 1:
		return
	var x := origin.x + 8 + roundi(safe_lane * (runtime.definition.arena_width - 16) / float(slot_count - 1))
	var lane_lines := PackedVector2Array()
	for y: int in range(roundi(origin.y), roundi(origin.y + display_size.y), 6):
		lane_lines.append(Vector2(x - 5, y))
		lane_lines.append(Vector2(x - 5, y + 2))
		lane_lines.append(Vector2(x + 5, y))
		lane_lines.append(Vector2(x + 5, y + 2))
	canvas.draw_multiline(lane_lines, foreground, 1.0, false)


func _batch_for(pool: DanmakuBulletPool, index: int) -> int:
	match pool.lifecycle[index]:
		DanmakuBulletPool.Lifecycle.TELEGRAPH:
			return Batch.TELEGRAPH
		DanmakuBulletPool.Lifecycle.DISSOLVE:
			return Batch.DISSOLVE if pool.dissolve_ticks[index] % 2 == 0 else -1
	var paper := pool.polarity[index] == DanmakuBulletSpec.Polarity.PAPER
	match pool.family[index]:
		DanmakuBulletSpec.Family.AMULET:
			return Batch.AMULET_PAPER if paper else Batch.AMULET_INK
		DanmakuBulletSpec.Family.OFFERING:
			return Batch.OFFERING_PAPER if paper else Batch.OFFERING_INK
		DanmakuBulletSpec.Family.MEMORY:
			return Batch.MEMORY_PAPER if paper else Batch.MEMORY_INK
		_:
			return Batch.KNIFE_PAPER if paper else Batch.KNIFE_INK


func _ensure_batches(capacity: int, foreground: Color) -> void:
	if _batch_capacity != capacity:
		_batch_capacity = capacity
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
		for index: int in range(_batch_capacity):
			multimesh.set_instance_color(index, foreground)


func _make_texture(batch: int) -> Texture2D:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match batch:
		Batch.TELEGRAPH:
			_draw_mask_box(image, 0, 6)
			_set_mask_pixel(image, TEXTURE_CENTER, TEXTURE_CENTER)
		Batch.AMULET_INK, Batch.AMULET_PAPER:
			for y: int in range(1, 6):
				for x: int in range(2, 5):
					if batch == Batch.AMULET_INK or x != TEXTURE_CENTER or y != TEXTURE_CENTER:
						_set_mask_pixel(image, x, y)
		Batch.OFFERING_INK, Batch.OFFERING_PAPER:
			_draw_mask_box(image, 1, 5)
			if batch == Batch.OFFERING_INK:
				_set_mask_pixel(image, TEXTURE_CENTER, TEXTURE_CENTER)
		Batch.MEMORY_INK, Batch.MEMORY_PAPER:
			for offset: int in range(1, 6):
				if batch == Batch.MEMORY_INK or offset != TEXTURE_CENTER:
					_set_mask_pixel(image, offset, TEXTURE_CENTER)
					_set_mask_pixel(image, TEXTURE_CENTER, offset)
		Batch.KNIFE_INK, Batch.KNIFE_PAPER:
			for offset: int in range(1, 6):
				if batch == Batch.KNIFE_INK or offset != 3:
					_set_mask_pixel(image, 5 - offset, offset)
			_set_mask_pixel(image, 1, 5)
			_set_mask_pixel(image, 2, 5)
		Batch.DISSOLVE:
			_set_mask_pixel(image, TEXTURE_CENTER, TEXTURE_CENTER)
	return ImageTexture.create_from_image(image)


func _draw_mask_box(image: Image, minimum: int, maximum: int) -> void:
	for offset: int in range(minimum, maximum + 1):
		_set_mask_pixel(image, offset, minimum)
		_set_mask_pixel(image, offset, maximum)
		_set_mask_pixel(image, minimum, offset)
		_set_mask_pixel(image, maximum, offset)


func _set_mask_pixel(image: Image, x: int, y: int) -> void:
	image.set_pixel(x, y, Color.WHITE)
