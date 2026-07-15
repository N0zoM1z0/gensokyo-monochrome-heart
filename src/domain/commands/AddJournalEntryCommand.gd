class_name AddJournalEntryCommand
extends GameCommand

var entry: JournalEntryState


func _init(p_entry: JournalEntryState) -> void:
	super(&"state.add_journal_entry")
	entry = p_entry.duplicate_state() if p_entry != null else null
