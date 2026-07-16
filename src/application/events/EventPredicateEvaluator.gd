class_name EventPredicateEvaluator
extends RefCounted
## Pure state predicates used by event availability and tone visibility/availability.

const SUPPORTED: Array[StringName] = [
	&"chapter_at_least",
	&"flag_true",
	&"flag_false",
	&"time_in",
	&"event_completed",
	&"event_not_completed",
	&"has_item",
	&"relationship_band_at_least",
	&"route_intent_is",
]


func evaluate(predicate: AvailabilityPredicateRecord, state: GameState) -> PredicateEvaluationRecord:
	if predicate == null or state == null:
		return PredicateEvaluationRecord.new(&"missing", false, "predicate or GameState is missing")
	match predicate.predicate:
		&"chapter_at_least":
			var passed := _chapter_rank(state.chapter_id) >= _chapter_rank(predicate.value)
			return _result(predicate, passed, "chapter %s >= %s" % [state.chapter_id, predicate.value])
		&"flag_true":
			var is_true := _boolean_flag(state, predicate.key, false)
			return _result(predicate, is_true, "flag %s is true" % predicate.key)
		&"flag_false":
			var is_false := not _boolean_flag(state, predicate.key, false)
			return _result(predicate, is_false, "flag %s is absent or false" % predicate.key)
		&"time_in":
			var in_time := state.time_slot in predicate.values
			return _result(predicate, in_time, "time %s in %s" % [state.time_slot, predicate.values])
		&"event_completed":
			var completed := predicate.value in state.completed_event_ids
			return _result(predicate, completed, "event %s completed" % predicate.value)
		&"event_not_completed":
			var pending := predicate.value not in state.completed_event_ids
			return _result(predicate, pending, "event %s not completed" % predicate.value)
		&"has_item":
			var has_item := state.inventory.items.has(predicate.value) or state.inventory.keepsakes.has(predicate.value)
			return _result(predicate, has_item, "inventory contains %s" % predicate.value)
		&"relationship_band_at_least":
			if not state.characters.has(predicate.character_id):
				return _result(predicate, false, "character %s is absent" % predicate.character_id)
			var character := state.characters[predicate.character_id]
			var at_least := RelationshipFacetRules.is_at_least(character.relationship, predicate.facet, predicate.band)
			return _result(
				predicate,
				at_least,
				"%s %s band is %s; requires %s" % [
					predicate.character_id,
					predicate.facet,
					RelationshipFacetRules.band_for(character.relationship, predicate.facet),
					predicate.band,
				]
			)
		&"route_intent_is":
			if not state.characters.has(predicate.character_id):
				return _result(predicate, false, "character %s is absent" % predicate.character_id)
			var intent_matches := state.characters[predicate.character_id].route_intent == predicate.value
			return _result(predicate, intent_matches, "%s route intent is %s; requires %s" % [predicate.character_id, state.characters[predicate.character_id].route_intent, predicate.value])
		_:
			return _result(predicate, false, "unsupported predicate %s" % predicate.predicate)


func evaluate_all(
	predicates: Array[AvailabilityPredicateRecord],
	state: GameState
) -> Array[PredicateEvaluationRecord]:
	var result: Array[PredicateEvaluationRecord] = []
	for predicate: AvailabilityPredicateRecord in predicates:
		result.append(evaluate(predicate, state))
	return result


func all_pass(records: Array[PredicateEvaluationRecord]) -> bool:
	for record: PredicateEvaluationRecord in records:
		if not record.passed:
			return false
	return true


func _boolean_flag(state: GameState, flag_id: StringName, default_value: bool) -> bool:
	if not state.flags.has(flag_id):
		return default_value
	var flag := state.flags[flag_id]
	return flag.kind == FlagState.Kind.BOOLEAN and flag.boolean_value


func _chapter_rank(chapter_id: StringName) -> int:
	var value := String(chapter_id).trim_prefix("chapter.")
	if value == "prologue":
		return 0
	return value.to_int() if value.is_valid_int() else -1


func _result(
	predicate: AvailabilityPredicateRecord,
	passed: bool,
	diagnostic: String
) -> PredicateEvaluationRecord:
	return PredicateEvaluationRecord.new(predicate.predicate, passed, diagnostic)
