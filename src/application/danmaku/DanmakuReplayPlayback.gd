class_name DanmakuReplayPlayback
extends RefCounted
## Evidence returned by a replay run, including exact mismatch diagnostics.

var is_valid: bool = false
var diagnostic: String
var result: ModeResult
var checkpoints := PackedStringArray()
var final_hash: String
var runtime: BoundaryStainSimulation
