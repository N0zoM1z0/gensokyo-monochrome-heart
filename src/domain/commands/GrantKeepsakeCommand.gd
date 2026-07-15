class_name GrantKeepsakeCommand
extends GameCommand

var keepsake: KeepsakeState


func _init(p_keepsake: KeepsakeState) -> void:
	super(&"state.grant_keepsake")
	keepsake = p_keepsake.duplicate_state() if p_keepsake != null else null
