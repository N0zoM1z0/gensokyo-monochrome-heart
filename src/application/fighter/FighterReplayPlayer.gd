class_name FighterReplayPlayer
extends RefCounted
## Re-simulates a paired tape and reports exact checkpoint/hash divergence.


func play(tape: FighterReplayTape, definition: FighterDuelDefinition) -> FighterReplayPlayback:
	var playback := FighterReplayPlayback.new()
	if tape == null or definition == null:
		playback.diagnostic = "fighter replay tape and definition are required"
		return playback
	if tape.replay_version != FighterReplayTape.CURRENT_VERSION:
		playback.diagnostic = "unsupported fighter replay version: %d" % tape.replay_version
		return playback
	if tape.duel_id != definition.id or tape.duel_data_hash != definition.data_hash:
		playback.diagnostic = "fighter replay definition identity/hash mismatch"
		return playback
	if tape.player_frames.size() != tape.opponent_frames.size():
		playback.diagnostic = "fighter replay input tracks have different lengths"
		return playback
	var assists := FighterAssistSettings.from_signature(tape.assist_signature)
	if not assists.validation_errors().is_empty():
		playback.diagnostic = "fighter replay contains invalid assists"
		return playback
	var context := ModeContext.new()
	context.mode_type = &"start_duel"
	context.mode_id = definition.id
	context.event_id = &"evt.hkr.spell_card_terms"
	context.node_id = &"n_duel"
	context.deterministic_seed = tape.deterministic_seed
	var runtime := FighterDuelSimulation.new()
	if not runtime.configure(
		definition,
		context,
		assists,
		tape.player_fighter_id,
		tape.opponent_fighter_id
	):
		playback.diagnostic = "fighter replay runtime rejected its configuration"
		return playback
	for index: int in range(tape.player_frames.size()):
		runtime.step(
			FighterInputFrame.decode(tape.player_frames[index]),
			FighterInputFrame.decode(tape.opponent_frames[index])
		)
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
		mismatches.append("fighter replay ended before producing a result")
	elif tape.expected_result_tag != &"" and playback.result.result_tag != tape.expected_result_tag:
		mismatches.append("result expected %s, got %s" % [tape.expected_result_tag, playback.result.result_tag])
	if not tape.expected_checkpoints.is_empty() and playback.checkpoints != tape.expected_checkpoints:
		mismatches.append("spell-break checkpoints differ: %s" % [playback.checkpoints])
	if not tape.expected_final_hash.is_empty() and playback.final_hash != tape.expected_final_hash:
		mismatches.append("final state hash expected %s, got %s" % [tape.expected_final_hash, playback.final_hash])
	playback.is_valid = mismatches.is_empty()
	playback.diagnostic = "; ".join(mismatches)
	return playback
