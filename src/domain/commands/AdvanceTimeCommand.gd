class_name AdvanceTimeCommand
extends GameCommand

var slot_count: int


func _init(p_slot_count: int = 1) -> void:
	super(&"state.advance_time")
	slot_count = p_slot_count
