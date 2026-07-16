class_name CampaignBackboneService
extends RefCounted
## Atomically commits a shared reveal, next-region condition, and chapter advance.


func advance_ready_chapter(state: GameState) -> CommandResult:
	if state == null:
		return CommandResult.failure(CommandResult.Code.NO_STATE, &"campaign.advance_ready_chapter", "GameState is missing")
	var definition := CampaignChapterCatalog.for_chapter(state.chapter_id)
	if definition == null:
		return _no_change("no headline transition is defined for %s" % state.chapter_id)
	var definition_errors := definition.validation_errors()
	if not definition_errors.is_empty():
		return CommandResult.failure(
			CommandResult.Code.INVALID_ARGUMENT,
			&"campaign.advance_ready_chapter",
			"invalid chapter definition: %s" % "; ".join(definition_errors)
		)
	for event_id: StringName in definition.required_event_ids:
		if event_id not in state.completed_event_ids:
			return _no_change("chapter waits for %s" % event_id)

	var transaction := GameStateTransaction.new(state)
	var working := transaction.working_state()
	var reveal_flag := working.flags.get(definition.reveal_flag_id) as FlagState
	if (
		reveal_flag == null
		or reveal_flag.kind != FlagState.Kind.STABLE_ID
		or reveal_flag.stable_id_value != definition.reveal_id
	):
		var flagged := transaction.apply(SetFlagCommand.new(FlagState.from_value(
			definition.reveal_flag_id,
			definition.reveal_id
		)))
		if not flagged.is_success():
			return _rollback(transaction, flagged)

	working = transaction.working_state()
	if not working.journal.entries.has(definition.journal_entry_id):
		var entry := JournalEntryState.new(definition.journal_entry_id)
		entry.title_key = definition.journal_title_key
		entry.entry_type = &"chapter_reveal"
		entry.source_event_id = definition.required_event_ids[-1]
		entry.discovered_day = working.day
		entry.observation_keys = [definition.journal_observation_key]
		entry.tags = [&"campaign", definition.reveal_id]
		var journaled := transaction.apply(AddJournalEntryCommand.new(entry))
		if not journaled.is_success():
			return _rollback(transaction, journaled)

	var region_ids: Array[StringName] = []
	region_ids.assign(definition.next_region_conditions.keys())
	region_ids.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	for region_id: StringName in region_ids:
		working = transaction.working_state()
		var next_condition: StringName = definition.next_region_conditions[region_id]
		if working.regions.has(region_id) and working.regions[region_id].condition_id == next_condition:
			continue
		var conditioned := transaction.apply(SetRegionConditionCommand.new(region_id, next_condition))
		if not conditioned.is_success():
			return _rollback(transaction, conditioned)

	var advanced := transaction.apply(AdvanceChapterCommand.new(
		definition.chapter_id,
		definition.next_chapter_id
	))
	if not advanced.is_success():
		return _rollback(transaction, advanced)
	var committed := transaction.commit()
	if not committed.is_success():
		return committed
	return CommandResult.success(
		&"campaign.advance_ready_chapter",
		"%s revealed and %s opened" % [definition.reveal_id, definition.next_chapter_id]
	)


func _rollback(transaction: GameStateTransaction, failure: CommandResult) -> CommandResult:
	transaction.rollback()
	return failure


func _no_change(message: String) -> CommandResult:
	return CommandResult.new(CommandResult.Code.OK, &"campaign.advance_ready_chapter", message, false)
