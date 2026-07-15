class_name FighterReplayPlayback
extends RefCounted

var is_valid: bool = false
var diagnostic: String
var result: ModeResult
var checkpoints := PackedStringArray()
var final_hash: String
var runtime: FighterDuelSimulation
