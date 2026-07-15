class_name DanmakuHost
extends RefCounted
## Shared encounter lifecycle: pause, phase retry, assists, and typed result emission.

signal result_ready(result: ModeResult)
signal phase_checkpoint(checkpoint: String)

var runtime: BoundaryStainSimulation
var attempt_count: int = 0
var defeat_count: int = 0
var _result_emitted: bool = false


func load_encounter(
	next_runtime: BoundaryStainSimulation,
	pattern: DanmakuPatternDefinition,
	context: ModeContext,
	assists: DanmakuAssistSettings = null,
	pool_capacity: int = 512
) -> bool:
	if next_runtime == null:
		return false
	runtime = next_runtime
	attempt_count = 1
	defeat_count = 0
	_result_emitted = false
	if not runtime.configure(pattern, context, assists, pool_capacity):
		return false
	runtime.phase_checkpoint.connect(_on_phase_checkpoint)
	return true


func step(input: DanmakuInputFrame) -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.step(input)
	_emit_once(result)
	return result


func toggle_pause() -> void:
	if runtime != null:
		runtime.toggle_pause()


func retry_phase() -> void:
	if runtime == null:
		return
	attempt_count += 1
	_result_emitted = false
	runtime.retry_phase()


func accept_loss() -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.accept_loss()
	_emit_once(result)
	return result


func can_assist_clear() -> bool:
	return defeat_count >= 3


func assist_clear() -> ModeResult:
	if runtime == null or not can_assist_clear():
		return null
	var result := runtime.assist_clear()
	_emit_once(result)
	return result


func _emit_once(result: ModeResult) -> void:
	if result == null or _result_emitted:
		return
	_result_emitted = true
	if result.result_tag == &"loss":
		defeat_count += 1
	if result.telemetry != null:
		result.telemetry.attempt_count = attempt_count
	result_ready.emit(result)


func _on_phase_checkpoint(checkpoint: String) -> void:
	phase_checkpoint.emit(checkpoint)
