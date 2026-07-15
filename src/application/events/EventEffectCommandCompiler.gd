class_name EventEffectCommandCompiler
extends RefCounted
## Converts closed authored effects to existing validated GameCommands.


func compile(effects: Array[EventEffectRecord]) -> EventCommandCompileResult:
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
			&"set_flag":
				var flag := FlagState.from_value(effect.key, effect.boolean_value)
				if flag == null:
					result.errors.append("flag effect %s could not produce a typed value" % effect.key)
				else:
					result.commands.append(SetFlagCommand.new(flag))
			_:
				result.errors.append("unsupported effect operation: %s" % effect.operation)
	return result
