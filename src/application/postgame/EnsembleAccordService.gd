class_name EnsembleAccordService
extends RefCounted
## Pure M15 Accord evaluator; it never mutates route or relationship state.


func evaluate(
	state: GameState,
	characters: Array[CharacterRecord],
	rules: EnsembleAccordRulesRecord
) -> EnsembleAccordEvaluation:
	var result := EnsembleAccordEvaluation.new()
	if state == null or rules == null:
		result.blockers.append(&"missing_state_or_rules")
		return result
	result.fallback_ending_id = rules.fallback_ending_id
	for character: CharacterRecord in characters:
		if character.relationship_scope != &"deep_route":
			continue
		var character_state: CharacterState = state.characters.get(character.id)
		if character_state == null:
			continue
		if character_state.relationship.strain >= rules.severe_strain_threshold:
			result.severe_strain_character_ids.append(character.id)
		if character_state.route_stage < 7:
			continue
		result.completed_deep_routes += 1
		if character_state.route_intent == &"friendship":
			result.friendship_endings += 1
		elif character_state.route_intent == &"postponed":
			result.postponed_promises += 1
	result.cross_faction_repairs = _integer_flag(state, &"flag.ensemble.cross_faction_repairs")
	if result.completed_deep_routes < rules.minimum_completed_deep_routes:
		result.blockers.append(&"deep_routes")
	if result.friendship_endings < rules.minimum_friendship_endings:
		result.blockers.append(&"friendship_endings")
	if result.postponed_promises < rules.minimum_postponed_promises:
		result.blockers.append(&"postponed_promise")
	if not result.severe_strain_character_ids.is_empty():
		result.blockers.append(&"severe_strain")
	if result.cross_faction_repairs < rules.minimum_cross_faction_repairs:
		result.blockers.append(&"cross_faction_repairs")
	if not _boolean_flag(state, rules.rank_spectacle_refused_flag):
		result.blockers.append(&"rank_spectacle")
	if not _boolean_flag(state, rules.intent_audit_flag):
		result.blockers.append(&"intent_audit")
	if not _boolean_flag(state, rules.boundaries_established_flag):
		result.blockers.append(&"boundaries")
	if _stable_id_flag(state, rules.home_responsibility_flag) == &"":
		result.blockers.append(&"home_responsibility")
	result.eligible = result.blockers.is_empty()
	return result


func _boolean_flag(state: GameState, flag_id: StringName) -> bool:
	var flag: FlagState = state.flags.get(flag_id)
	return flag != null and flag.kind == FlagState.Kind.BOOLEAN and flag.boolean_value


func _integer_flag(state: GameState, flag_id: StringName) -> int:
	var flag: FlagState = state.flags.get(flag_id)
	return flag.integer_value if flag != null and flag.kind == FlagState.Kind.INTEGER else 0


func _stable_id_flag(state: GameState, flag_id: StringName) -> StringName:
	var flag: FlagState = state.flags.get(flag_id)
	return flag.stable_id_value if flag != null and flag.kind == FlagState.Kind.STABLE_ID else &""
