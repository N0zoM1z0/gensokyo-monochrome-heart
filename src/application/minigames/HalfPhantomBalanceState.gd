class_name HalfPhantomBalanceState
extends RefCounted
## Serializable play state for Youmu and her half-phantom crossing one narrow bridge.

enum Phase { TUTORIAL, ACTIVE, RESULT }
enum Body { YOUMU, PHANTOM }

var phase: Phase = Phase.TUTORIAL
var selected_body: Body = Body.YOUMU
var youmu_column: int = 0
var phantom_column: int = 4
var steps: int = 0
var result_tag: StringName


func canonical_snapshot() -> Dictionary:
	return {
		"phase": phase,
		"selected_body": selected_body,
		"youmu_column": youmu_column,
		"phantom_column": phantom_column,
		"steps": steps,
		"result_tag": String(result_tag),
	}
