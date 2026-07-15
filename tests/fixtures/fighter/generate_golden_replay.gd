extends SceneTree
## Maintainer helper: prints the reviewed M08 replay candidate; never writes files.


func _initialize() -> void:
	var loader := FighterDefinitionLoader.new()
	var definition := loader.load_path("res://content/fighter/reimu_marisa_duel.json")
	if definition == null or not loader.errors.is_empty():
		printerr("fighter definition failed: %s" % [loader.errors])
		quit(1)
		return
	var context := ModeContext.new()
	context.mode_type = &"start_duel"
	context.mode_id = definition.id
	context.event_id = &"evt.hkr.spell_card_terms"
	context.node_id = &"n_duel"
	context.deterministic_seed = 8088
	var assists := FighterAssistSettings.new()
	var runtime := FighterDuelSimulation.new()
	if not runtime.configure(definition, context, assists):
		printerr("fighter runtime rejected golden configuration")
		quit(1)
		return
	var recorder := FighterReplayRecorder.new()
	recorder.begin(definition, 8088, assists, &"fighter.reimu", &"fighter.marisa")
	for tick: int in range(900):
		var player := FighterInputFrame.new()
		player.skill_pressed = true
		var opponent := FighterInputFrame.new()
		recorder.record(player, opponent)
		runtime.step(player, opponent)
		if runtime.final_result != null:
			break
	var runs: Array[Dictionary] = []
	for index: int in range(recorder.tape.player_frames.size()):
		var player_code := recorder.tape.player_frames[index]
		var opponent_code := recorder.tape.opponent_frames[index]
		if (
			not runs.is_empty()
			and runs[-1].player_code == player_code
			and runs[-1].opponent_code == opponent_code
		):
			runs[-1].ticks = int(runs[-1].ticks) + 1
		else:
			runs.append({"ticks": 1, "player_code": player_code, "opponent_code": opponent_code})
	var output := {
		"replay_version": FighterReplayTape.CURRENT_VERSION,
		"duel_id": String(definition.id),
		"duel_data_hash": definition.data_hash,
		"deterministic_seed": 8088,
		"assist_signature": assists.signature(),
		"player_fighter_id": "fighter.reimu",
		"opponent_fighter_id": "fighter.marisa",
		"runs": runs,
		"expected_checkpoints": Array(runtime.checkpoints),
		"expected_result_tag": String(runtime.final_result.result_tag) if runtime.final_result != null else "",
		"expected_final_hash": runtime.final_result.telemetry.final_state_hash if runtime.final_result != null else runtime.canonical_snapshot().sha256_text(),
	}
	print(JSON.stringify(output, "  ", false))
	quit(0 if runtime.final_result != null else 1)
