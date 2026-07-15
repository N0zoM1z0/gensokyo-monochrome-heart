extends SceneTree
## Profiles the complete 320x180 HUD draw with exactly 2,500 visible bullets.

const STRESS_SCENE := preload("res://tests/ui/fixtures/BoundaryStainStressFixture.tscn")
const CANVAS_SIZE := Vector2i(320, 180)
const BULLET_COUNT := 2500
const WARMUP_FRAMES := 12
const MEASURED_FRAMES := 120
const FULL_FRAME_BUDGET_MS := 16.67


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = CANVAS_SIZE
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var mode := STRESS_SCENE.instantiate() as BoundaryStainMode
	viewport.add_child(mode)
	mode.configure_fixture(&"D", &"en")
	for _frame: int in range(WARMUP_FRAMES):
		mode.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
	var timings := PackedInt64Array()
	var total_usec: int = 0
	for _frame: int in range(MEASURED_FRAMES):
		var started := Time.get_ticks_usec()
		mode.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		var elapsed := Time.get_ticks_usec() - started
		timings.append(elapsed)
		total_usec += elapsed
	timings.sort()
	var p95_index := clampi(ceili(timings.size() * 0.95) - 1, 0, timings.size() - 1)
	var average_ms := total_usec / float(MEASURED_FRAMES) / 1000.0
	var p95_ms := timings[p95_index] / 1000.0
	var maximum_ms := timings[-1] / 1000.0
	var visible_bullets := mode.rendered_bullet_count()
	var source_bullets := int(mode.capture_debug_state().get("bullets", -1))
	var within_budget := p95_ms <= FULL_FRAME_BUDGET_MS
	print(JSON.stringify({
		"fixture": "m07_render_2500",
		"renderer": RenderingServer.get_video_adapter_name(),
		"canvas": "%dx%d" % [CANVAS_SIZE.x, CANVAS_SIZE.y],
		"bullets": source_bullets,
		"rendered_bullets": visible_bullets,
		"frames": MEASURED_FRAMES,
		"average_ms": snappedf(average_ms, 0.001),
		"p95_ms": snappedf(p95_ms, 0.001),
		"maximum_ms": snappedf(maximum_ms, 0.001),
		"budget_p95_ms": FULL_FRAME_BUDGET_MS,
		"within_budget": within_budget,
	}))
	var structurally_valid := (
		source_bullets == BULLET_COUNT
		and visible_bullets == BULLET_COUNT
		and mode.runtime.pool.dropped_spawn_count == 0
	)
	viewport.free()
	quit(0 if structurally_valid else 1)
