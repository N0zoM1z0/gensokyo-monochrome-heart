class_name UnlockJournalReplayCommand
extends GameCommand
## Adds one completed event to the Journal's stable replay index.

var event_id: StringName


func _init(p_event_id: StringName) -> void:
	super(&"state.unlock_journal_replay")
	event_id = p_event_id
