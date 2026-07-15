class_name DanmakuBulletBatchRenderer
extends RefCounted
## One CanvasItem custom-draw pass over packed bullet data; never one Node per bullet.

var rendered_bullet_count: int = 0


func draw_field(
	canvas: CanvasItem,
	runtime: BoundaryStainSimulation,
	origin: Vector2,
	display_size: Vector2,
	foreground: Color,
	background: Color
) -> void:
	rendered_bullet_count = 0
	if canvas == null or runtime == null:
		return
	var pool := runtime.pool
	var scale_y := display_size.y / float(runtime.definition.arena_height)
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
		match pool.lifecycle[index]:
			DanmakuBulletPool.Lifecycle.TELEGRAPH:
				_draw_telegraph(canvas, position, foreground)
			DanmakuBulletPool.Lifecycle.COMMITTED:
				_draw_committed(
					canvas,
					position,
					pool.family[index],
					pool.polarity[index],
					foreground,
					background
				)
			DanmakuBulletPool.Lifecycle.DISSOLVE:
				if pool.dissolve_ticks[index] % 2 == 0:
					canvas.draw_rect(Rect2(position, Vector2.ONE), foreground)
		rendered_bullet_count += 1


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
	for y: int in range(roundi(origin.y), roundi(origin.y + display_size.y), 6):
		canvas.draw_rect(Rect2(x - 5, y, 1, 3), foreground)
		canvas.draw_rect(Rect2(x + 5, y, 1, 3), foreground)


func _draw_telegraph(canvas: CanvasItem, position: Vector2, foreground: Color) -> void:
	canvas.draw_rect(Rect2(position - Vector2(3, 3), Vector2(7, 7)), foreground, false, 1.0)
	canvas.draw_rect(Rect2(position, Vector2.ONE), foreground)


func _draw_committed(
	canvas: CanvasItem,
	position: Vector2,
	family: int,
	polarity: int,
	foreground: Color,
	background: Color
) -> void:
	match family:
		DanmakuBulletSpec.Family.AMULET:
			canvas.draw_rect(Rect2(position - Vector2(1, 2), Vector2(3, 5)), foreground)
			if polarity == DanmakuBulletSpec.Polarity.PAPER:
				canvas.draw_rect(Rect2(position, Vector2.ONE), background)
		DanmakuBulletSpec.Family.OFFERING:
			canvas.draw_rect(Rect2(position - Vector2(2, 2), Vector2(5, 5)), foreground, false, 1.0)
			canvas.draw_rect(Rect2(position, Vector2.ONE), foreground)
			if polarity == DanmakuBulletSpec.Polarity.PAPER:
				canvas.draw_rect(Rect2(position + Vector2(-1, 0), Vector2(3, 1)), foreground)
		_:
			canvas.draw_rect(Rect2(position + Vector2(-2, 0), Vector2(5, 1)), foreground)
			canvas.draw_rect(Rect2(position + Vector2(0, -2), Vector2(1, 5)), foreground)
			if polarity == DanmakuBulletSpec.Polarity.PAPER:
				canvas.draw_rect(Rect2(position, Vector2.ONE), background)
