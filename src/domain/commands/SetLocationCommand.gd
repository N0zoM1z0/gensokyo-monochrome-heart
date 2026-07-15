class_name SetLocationCommand
extends GameCommand

var location_id: StringName


func _init(p_location_id: StringName) -> void:
	super(&"state.set_location")
	location_id = p_location_id
