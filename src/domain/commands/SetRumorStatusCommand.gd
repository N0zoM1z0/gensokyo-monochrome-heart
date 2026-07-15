class_name SetRumorStatusCommand
extends GameCommand

var rumor_id: StringName
var status: StringName


func _init(p_rumor_id: StringName, p_status: StringName) -> void:
	super(&"state.set_rumor_status")
	rumor_id = p_rumor_id
	status = p_status
