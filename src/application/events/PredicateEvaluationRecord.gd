class_name PredicateEvaluationRecord
extends RefCounted
## One predicate decision retained for choice reasons and the developer overlay.

var predicate: StringName
var passed: bool
var diagnostic: String


func _init(p_predicate: StringName, p_passed: bool, p_diagnostic: String) -> void:
	predicate = p_predicate
	passed = p_passed
	diagnostic = p_diagnostic
