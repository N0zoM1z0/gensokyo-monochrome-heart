class_name EquipKeepsakeCommand
extends GameCommand

var keepsake_id: StringName
var should_equip: bool


func _init(p_keepsake_id: StringName, p_should_equip: bool) -> void:
	super(&"state.equip_keepsake")
	keepsake_id = p_keepsake_id
	should_equip = p_should_equip
