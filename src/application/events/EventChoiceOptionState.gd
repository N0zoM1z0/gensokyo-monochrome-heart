class_name EventChoiceOptionState
extends RefCounted
## Resolved option state; presentation receives semantic tone and reason, never facet values.

var tone: StringName
var text_key: StringName
var next_node_id: StringName
var is_available: bool = true
var unavailable_reason_key: StringName
var predicate_results: Array[PredicateEvaluationRecord] = []
