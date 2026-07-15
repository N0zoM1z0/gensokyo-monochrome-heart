class_name FighterReplayRecorder
extends RefCounted

var tape := FighterReplayTape.new()


func begin(
	definition: FighterDuelDefinition,
	seed: int,
	assists: FighterAssistSettings,
	player_id: StringName,
	opponent_id: StringName
) -> void:
	tape = FighterReplayTape.new()
	tape.duel_id = definition.id
	tape.duel_data_hash = definition.data_hash
	tape.deterministic_seed = seed
	tape.assist_signature = assists.signature()
	tape.player_fighter_id = player_id
	tape.opponent_fighter_id = opponent_id


func record(player_input: FighterInputFrame, opponent_input: FighterInputFrame) -> void:
	tape.player_frames.append(player_input.encoded())
	tape.opponent_frames.append(opponent_input.encoded())
