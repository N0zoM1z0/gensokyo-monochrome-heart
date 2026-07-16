class_name RecordStrategyUseCommand
extends GameCommand
## Records a locale-free strategy once for an event and counts campaign-wide use.

var event_id: StringName
var strategy_tag: StringName


func _init(p_event_id: StringName, p_strategy_tag: StringName) -> void:
	super(&"state.record_strategy_use")
	event_id = p_event_id
	strategy_tag = p_strategy_tag
