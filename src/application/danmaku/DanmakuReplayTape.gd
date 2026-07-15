class_name DanmakuReplayTape
extends RefCounted
## Versioned, locale-free fixed-tick input tape with reviewed golden expectations.

const CURRENT_VERSION := 1

var replay_version: int = CURRENT_VERSION
var pattern_id: StringName
var pattern_data_hash: String
var deterministic_seed: int = 1
var assist_signature: String
var encoded_frames := PackedInt32Array()
var expected_checkpoints := PackedStringArray()
var expected_result_tag: StringName
var expected_final_hash: String


static func load_path(path: String) -> DanmakuReplayTape:
	if not FileAccess.file_exists(path):
		return null
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		return null
	var tape := DanmakuReplayTape.new()
	tape.replay_version = int(raw.get("replay_version", 0))
	tape.pattern_id = StringName(raw.get("pattern_id", ""))
	tape.pattern_data_hash = String(raw.get("pattern_data_hash", ""))
	tape.deterministic_seed = int(raw.get("deterministic_seed", 1))
	tape.assist_signature = String(raw.get("assist_signature", ""))
	for run_raw: Variant in raw.get("runs", []):
		if not run_raw is Dictionary:
			return null
		var ticks := int(run_raw.get("ticks", 0))
		var input_code := int(run_raw.get("input_code", 0))
		if ticks <= 0:
			return null
		for _tick: int in range(ticks):
			tape.encoded_frames.append(input_code)
	for checkpoint: Variant in raw.get("expected_checkpoints", []):
		tape.expected_checkpoints.append(String(checkpoint))
	tape.expected_result_tag = StringName(raw.get("expected_result_tag", ""))
	tape.expected_final_hash = String(raw.get("expected_final_hash", ""))
	return tape
