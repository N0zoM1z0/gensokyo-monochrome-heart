class_name EventDebugSnapshot
extends RefCounted
## Read-only dev overlay data with semantic predicates and no player-facing raw facets.

var event_id: StringName
var node_id: StringName
var waiting_for: StringName
var total_steps: int
var deterministic_seed: int
var pending_checkpoint: StringName
var localization_key: StringName
var origin_canon: int
var origin_fanon: int
var origin_original: int
var predicate_results: Array[PredicateEvaluationRecord] = []
var last_command_ids: Array[StringName] = []
