class_name DanmakuReplayPlayer
extends RefCounted
## Re-simulates a tape at fixed 60 Hz and compares authored golden checkpoints.


func play(
	tape: DanmakuReplayTape,
	definition: DanmakuPatternDefinition,
	pool_capacity: int = 512
) -> DanmakuReplayPlayback:
	var playback := DanmakuReplayPlayback.new()
	if tape == null or definition == null:
		playback.diagnostic = "replay tape and pattern definition are required"
		return playback
	if tape.replay_version != DanmakuReplayTape.CURRENT_VERSION:
		playback.diagnostic = "unsupported danmaku replay version: %d" % tape.replay_version
		return playback
	if tape.pattern_id != definition.id or tape.pattern_data_hash != definition.data_hash:
		playback.diagnostic = "danmaku replay pattern identity/hash mismatch"
		return playback
	var assists := DanmakuAssistSettings.from_signature(tape.assist_signature)
	if not assists.validation_errors().is_empty():
		playback.diagnostic = "danmaku replay contains invalid assists"
		return playback
	var context := ModeContext.new()
	context.mode_type = &"start_danmaku"
	context.mode_id = definition.id
	context.event_id = &"evt.hkr.boundary_stain"
	context.node_id = &"n_danmaku"
	context.deterministic_seed = tape.deterministic_seed
	var runtime := BoundaryStainSimulation.new()
	if not runtime.configure(definition, context, assists, pool_capacity):
		playback.diagnostic = "danmaku replay runtime rejected its configuration"
		return playback
	for encoded_frame: int in tape.encoded_frames:
		runtime.step(DanmakuInputFrame.decode(encoded_frame))
	playback.runtime = runtime
	playback.result = runtime.final_result
	playback.checkpoints = runtime.checkpoints.duplicate()
	playback.final_hash = (
		runtime.final_result.telemetry.final_state_hash
		if runtime.final_result != null and runtime.final_result.telemetry != null
		else runtime.canonical_snapshot().sha256_text()
	)
	var mismatches: Array[String] = []
	if playback.result == null:
		mismatches.append("replay ended before producing a result")
	elif tape.expected_result_tag != &"" and playback.result.result_tag != tape.expected_result_tag:
		mismatches.append("result expected %s, got %s" % [tape.expected_result_tag, playback.result.result_tag])
	if not tape.expected_checkpoints.is_empty() and playback.checkpoints != tape.expected_checkpoints:
		mismatches.append("phase checkpoints differ: %s" % [playback.checkpoints])
	if not tape.expected_final_hash.is_empty() and playback.final_hash != tape.expected_final_hash:
		mismatches.append("final state hash expected %s, got %s" % [tape.expected_final_hash, playback.final_hash])
	playback.is_valid = mismatches.is_empty()
	playback.diagnostic = "; ".join(mismatches)
	return playback
