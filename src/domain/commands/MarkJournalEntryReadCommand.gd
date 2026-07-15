class_name MarkJournalEntryReadCommand
extends GameCommand

var entry_id: StringName


func _init(p_entry_id: StringName) -> void:
	super(&"state.mark_journal_read")
	entry_id = p_entry_id
