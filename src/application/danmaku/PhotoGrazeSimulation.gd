class_name PhotoGrazeSimulation
extends BoundaryStainSimulation
## Margin becomes a movable camera frame that records nearby committed bullets.

const FRAME_HALF_WIDTH_FP := 18 * FP
const FRAME_HALF_HEIGHT_FP := 14 * FP

var photo_attempt_count := 0
var captured_bullet_count := 0
var empty_frame_count := 0
var last_capture_count := 0

var _phase_open_photo_attempt_count := 0
var _phase_open_captured_bullet_count := 0
var _phase_open_empty_frame_count := 0
var _phase_open_last_capture_count := 0


func reset_encounter() -> void:
	photo_attempt_count = 0
	captured_bullet_count = 0
	empty_frame_count = 0
	last_capture_count = 0
	super.reset_encounter()


func retry_phase() -> void:
	super.retry_phase()
	photo_attempt_count = _phase_open_photo_attempt_count
	captured_bullet_count = _phase_open_captured_bullet_count
	empty_frame_count = _phase_open_empty_frame_count
	last_capture_count = _phase_open_last_capture_count


func canonical_snapshot() -> String:
	return "%s||photo:%d,%d,%d,%d" % [
		super.canonical_snapshot(),
		photo_attempt_count,
		captured_bullet_count,
		empty_frame_count,
		last_capture_count,
	]


func interaction_component_id() -> StringName:
	return &"photo_frame"


func interaction_count() -> int:
	return photo_attempt_count


func interaction_cue_key() -> StringName:
	return (
		&"ui.danmaku.photo.visual.captured"
		if last_capture_count > 0
		else &"ui.danmaku.photo.visual.empty"
	)


func interaction_cue_value() -> int:
	return last_capture_count


func interaction_frame_size_pixels() -> Vector2i:
	return Vector2i(37, 29)


func _move_player(input: DanmakuInputFrame) -> void:
	super._move_player(input)
	# The camera is the interaction boundary, so all four edges must remain visible.
	state.player_x_fp = clampi(
		state.player_x_fp,
		FRAME_HALF_WIDTH_FP,
		definition.arena_width * FP - FRAME_HALF_WIDTH_FP
	)
	state.player_y_fp = clampi(
		state.player_y_fp,
		FRAME_HALF_HEIGHT_FP,
		definition.arena_height * FP - FRAME_HALF_HEIGHT_FP
	)


func _spend_margin_corridor() -> void:
	if state.margin < MARGIN_ACTION_COST:
		return
	state.margin -= MARGIN_ACTION_COST
	state.margin_spent += MARGIN_ACTION_COST
	state.inactive_margin_ticks = 0
	photo_attempt_count += 1
	var captured := 0
	for index: int in range(pool.capacity):
		if (
			pool.used[index] == 0
			or pool.lifecycle[index] != DanmakuBulletPool.Lifecycle.COMMITTED
			or absi(pool.x_fp[index] - state.player_x_fp) > FRAME_HALF_WIDTH_FP
			or absi(pool.y_fp[index] - state.player_y_fp) > FRAME_HALF_HEIGHT_FP
		):
			continue
		pool.begin_dissolve(index)
		captured += 1
	last_capture_count = captured
	captured_bullet_count += captured
	empty_frame_count += int(captured == 0)
	state.score += captured * 75
	state.boss_integrity = maxi(0, state.boss_integrity - mini(24, captured * 2))


func _enter_phase(index: int) -> void:
	super._enter_phase(index)
	_phase_open_photo_attempt_count = photo_attempt_count
	_phase_open_captured_bullet_count = captured_bullet_count
	_phase_open_empty_frame_count = empty_frame_count
	_phase_open_last_capture_count = last_capture_count


func _finish(result_tag: StringName) -> ModeResult:
	var is_new := final_result == null
	var result := super._finish(result_tag)
	if result == null or not is_new:
		return result
	result.outcome_tags.append(&"strategy.photo_frame")
	result.outcome_tags.append(
		&"photo.capture.decisive" if captured_bullet_count >= 18
		else (&"photo.capture.composed" if captured_bullet_count >= 6 else &"photo.capture.sparse")
	)
	return result
