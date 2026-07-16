class_name RecordedStrategyLedger
extends RefCounted
## Stable flag-backed strategy evidence shared by Journal and the final Archive.

const GLOBAL_PREFIX := "flag.archive.strategy."
const EVENT_PREFIX := "flag.archive.event."


static func global_flag_id(strategy_tag: StringName) -> StringName:
	return StringName("%s%s" % [GLOBAL_PREFIX, String(strategy_tag).trim_prefix("strategy.")])


static func event_flag_id(event_id: StringName, strategy_tag: StringName) -> StringName:
	return StringName("%s%s.strategy.%s" % [
		EVENT_PREFIX,
		String(event_id).trim_prefix("evt."),
		String(strategy_tag).trim_prefix("strategy."),
	])


static func tags_for_event(state: GameState, event_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if state == null:
		return result
	var prefix := "%s%s.strategy." % [EVENT_PREFIX, String(event_id).trim_prefix("evt.")]
	for flag_id: StringName in state.flags:
		if not String(flag_id).begins_with(prefix):
			continue
		var flag := state.flags[flag_id] as FlagState
		if flag != null and flag.kind == FlagState.Kind.BOOLEAN and flag.boolean_value:
			result.append(StringName("strategy.%s" % String(flag_id).trim_prefix(prefix)))
	result.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	return result


static func ranked_tags(state: GameState) -> Array[StringName]:
	var weighted: Array[Dictionary] = []
	if state == null:
		return []
	for flag_id: StringName in state.flags:
		if not String(flag_id).begins_with(GLOBAL_PREFIX):
			continue
		var flag := state.flags[flag_id] as FlagState
		if flag == null or flag.kind != FlagState.Kind.INTEGER or flag.integer_value < 1:
			continue
		weighted.append({
			"tag": StringName("strategy.%s" % String(flag_id).trim_prefix(GLOBAL_PREFIX)),
			"count": flag.integer_value,
		})
	weighted.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.count) != int(right.count):
			return int(left.count) > int(right.count)
		return String(left.tag) < String(right.tag)
	)
	var result: Array[StringName] = []
	for record: Dictionary in weighted:
		result.append(record.tag)
	return result
