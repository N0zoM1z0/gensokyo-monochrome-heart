class_name MinigameHost
extends RefCounted
## Shared lifecycle boundary: configure, fixed step, pause, retry, result, no story mutation.

signal result_ready(result: ModeResult)

var runtime: MinigameRuntime
var attempt_count: int = 0
var _result_emitted: bool = false


func load_minigame(
	next_runtime: MinigameRuntime,
	context: ModeContext,
	assist_settings: MinigameAssistSettings = null
) -> bool:
	if next_runtime == null or context == null:
		return false
	runtime = next_runtime
	attempt_count = 1
	_result_emitted = false
	runtime.configure(context, assist_settings)
	return runtime.definition != null and runtime.definition.validation_errors().is_empty()


func step(input: MinigameInputFrame) -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.step(input)
	_emit_once(result)
	return result


func toggle_pause() -> void:
	if runtime != null:
		runtime.toggle_pause()


func retry() -> void:
	if runtime == null:
		return
	attempt_count += 1
	_result_emitted = false
	runtime.reset_attempt()


func accept_loss() -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.accept_loss()
	_emit_once(result)
	return result


func _emit_once(result: ModeResult) -> void:
	if result == null or _result_emitted:
		return
	_result_emitted = true
	if result.telemetry != null:
		result.telemetry.attempt_count = attempt_count
	result_ready.emit(result)
