class_name RumorPropagationService
extends RefCounted
## Applies authored rumor rewrites and cross-region conditions as one transaction.


func propagate(state: GameState, rules: Array[RumorPropagationRule]) -> CommandResult:
	if state == null:
		return CommandResult.failure(CommandResult.Code.NO_STATE, &"campaign.rumor_propagation", "GameState is missing")
	var transaction := GameStateTransaction.new(state)
	var command_count := 0
	for rule: RumorPropagationRule in rules:
		var working := transaction.working_state()
		if rule == null or working == null or not working.rumors.has(rule.rumor_id):
			continue
		var rumor := working.rumors[rule.rumor_id] as RumorState
		# Exact-claim matching makes a repeated day-end or resumed shell a no-op.
		if rumor == null or rumor.claim_key != rule.expected_claim_key:
			continue
		var mutated := transaction.apply(MutateRumorCommand.new(
			rule.rumor_id,
			rule.next_claim_key,
			rule.reliability_delta_milli,
			rule.next_privacy
		))
		if not mutated.is_success():
			transaction.rollback()
			return mutated
		command_count += 1
		var region_ids: Array[StringName] = []
		region_ids.assign(rule.region_conditions.keys())
		region_ids.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
		for region_id: StringName in region_ids:
			working = transaction.working_state()
			if (
				working != null
				and working.regions.has(region_id)
				and working.regions[region_id].condition_id == rule.region_conditions[region_id]
			):
				continue
			var changed := transaction.apply(SetRegionConditionCommand.new(
				region_id,
				rule.region_conditions[region_id]
			))
			if not changed.is_success():
				transaction.rollback()
				return changed
			command_count += 1
	if command_count == 0:
		return CommandResult.new(
			CommandResult.Code.OK,
			&"campaign.rumor_propagation",
			"no eligible rumor rewrites",
			false
		)
	var committed := transaction.commit()
	if not committed.is_success():
		return committed
	return CommandResult.success(&"campaign.rumor_propagation", "%d campaign consequences committed" % command_count)
