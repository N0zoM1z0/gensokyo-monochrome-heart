class_name FighterReplayTape
extends RefCounted
## Versioned fixed-tick duel tape with paired player/opponent inputs.

const CURRENT_VERSION := 1

var replay_version: int = CURRENT_VERSION
var duel_id: StringName
var duel_data_hash: String
var deterministic_seed: int = 1
var assist_signature: String
var player_fighter_id: StringName = &"fighter.reimu"
var opponent_fighter_id: StringName = &"fighter.marisa"
var player_frames := PackedInt32Array()
var opponent_frames := PackedInt32Array()
var expected_checkpoints := PackedStringArray()
var expected_result_tag: StringName
var expected_final_hash: String


static func load_path(path: String) -> FighterReplayTape:
	if not FileAccess.file_exists(path):
		return null
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		return null
	var tape := FighterReplayTape.new()
	tape.replay_version = int(raw.get("replay_version", 0))
	tape.duel_id = StringName(raw.get("duel_id", ""))
	tape.duel_data_hash = String(raw.get("duel_data_hash", ""))
	tape.deterministic_seed = int(raw.get("deterministic_seed", 1))
	tape.assist_signature = String(raw.get("assist_signature", ""))
	tape.player_fighter_id = StringName(raw.get("player_fighter_id", ""))
	tape.opponent_fighter_id = StringName(raw.get("opponent_fighter_id", ""))
	for run_raw: Variant in raw.get("runs", []):
		if not run_raw is Dictionary:
			return null
		var ticks := int(run_raw.get("ticks", 0))
		if ticks <= 0:
			return null
		for _tick: int in range(ticks):
			tape.player_frames.append(int(run_raw.get("player_code", 0)))
			tape.opponent_frames.append(int(run_raw.get("opponent_code", 0)))
	for checkpoint: Variant in raw.get("expected_checkpoints", []):
		tape.expected_checkpoints.append(String(checkpoint))
	tape.expected_result_tag = StringName(raw.get("expected_result_tag", ""))
	tape.expected_final_hash = String(raw.get("expected_final_hash", ""))
	return tape
