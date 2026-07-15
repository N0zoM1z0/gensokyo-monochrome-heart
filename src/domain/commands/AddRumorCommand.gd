class_name AddRumorCommand
extends GameCommand

var rumor: RumorState


func _init(p_rumor: RumorState) -> void:
	super(&"state.add_rumor")
	rumor = p_rumor.duplicate_state() if p_rumor != null else null
