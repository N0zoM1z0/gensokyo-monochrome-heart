class_name DanmakuReplayRecorder
extends RefCounted
## Records semantic inputs and deterministic encounter identity, never presentation frames.

var tape: DanmakuReplayTape


func begin(
	definition: DanmakuPatternDefinition,
	context: ModeContext,
	assists: DanmakuAssistSettings
) -> void:
	tape = DanmakuReplayTape.new()
	tape.pattern_id = definition.id
	tape.pattern_data_hash = definition.data_hash
	tape.deterministic_seed = context.deterministic_seed
	tape.assist_signature = assists.canonical_signature()


func record_frame(input: DanmakuInputFrame) -> void:
	if tape != null and input != null:
		tape.encoded_frames.append(input.encoded())


func finish(runtime: BoundaryStainSimulation, result: ModeResult) -> DanmakuReplayTape:
	if tape == null or runtime == null or result == null:
		return tape
	tape.expected_checkpoints = runtime.checkpoints.duplicate()
	tape.expected_result_tag = result.result_tag
	tape.expected_final_hash = result.telemetry.final_state_hash if result.telemetry != null else ""
	return tape
