class_name SetFlagCommand
extends GameCommand

var flag: FlagState


func _init(p_flag: FlagState) -> void:
	super(&"state.set_flag")
	flag = p_flag.duplicate_state() if p_flag != null else null
