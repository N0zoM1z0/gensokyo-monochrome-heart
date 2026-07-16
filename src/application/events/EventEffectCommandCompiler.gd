class_name EventEffectCommandCompiler
extends RefCounted
## Converts closed authored effects to existing validated GameCommands.


func compile(effects: Array[EventEffectRecord], acquired_day: int = 1) -> EventCommandCompileResult:
	var result := EventCommandCompileResult.new()
	for effect: EventEffectRecord in effects:
		if effect == null:
			result.errors.append("event effect is missing")
			continue
		match effect.operation:
			&"relationship":
				result.commands.append(
					AdjustRelationshipCommand.new(effect.character_id, effect.facet, effect.delta)
				)
			&"route_stage":
				result.commands.append(AdvanceRouteStageCommand.new(effect.character_id, effect.stage))
			&"route_intent":
				result.commands.append(SetRouteIntentCommand.new(effect.character_id, effect.route_intent))
			&"set_flag":
				var flag := FlagState.from_value(effect.key, effect.boolean_value)
				if flag == null:
					result.errors.append("flag effect %s could not produce a typed value" % effect.key)
				else:
					result.commands.append(SetFlagCommand.new(flag))
			&"add_rumor":
				var rumor := RumorState.new(effect.rumor_id)
				rumor.claim_key = effect.claim_key
				rumor.source_character_id = effect.source_character_id
				rumor.reliability_milli = effect.reliability_milli
				rumor.privacy = effect.privacy
				rumor.status = effect.status
				rumor.acquired_day = acquired_day
				result.commands.append(AddRumorCommand.new(rumor))
			_:
				result.errors.append("unsupported effect operation: %s" % effect.operation)
	return result
