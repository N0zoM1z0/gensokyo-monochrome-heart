class_name GameCommandDispatcher
extends RefCounted
## Validates and commits each typed command atomically through a candidate snapshot.

const MAX_ITEM_COUNT := 999

var _validator := GameStateValidator.new()


func dispatch(state: GameState, command: GameCommand) -> CommandResult:
	if state == null:
		return CommandResult.failure(CommandResult.Code.NO_STATE, _command_id(command), "active GameState is missing")
	if command == null:
		return CommandResult.failure(CommandResult.Code.INVALID_COMMAND, &"command.null", "command is missing")
	var opening_errors := _validator.validate(state)
	if not opening_errors.is_empty():
		return CommandResult.failure(
			CommandResult.Code.INVARIANT_FAILURE,
			command.command_id,
			"opening state is invalid: %s" % "; ".join(opening_errors)
		)
	var candidate := state.deep_copy()
	var result := _apply(candidate, command)
	if not result.is_success():
		return result
	var errors := _validator.validate(candidate)
	if not errors.is_empty():
		return CommandResult.failure(
			CommandResult.Code.INVARIANT_FAILURE,
			command.command_id,
			"command violated state invariants: %s" % "; ".join(errors)
		)
	state.copy_from(candidate)
	return result


func _apply(state: GameState, command: GameCommand) -> CommandResult:
	if command is SetFlagCommand:
		return _set_flag(state, command)
	if command is AdjustRelationshipCommand:
		return _adjust_relationship(state, command)
	if command is AddRumorCommand:
		return _add_rumor(state, command)
	if command is SetRumorStatusCommand:
		return _set_rumor_status(state, command)
	if command is AddJournalEntryCommand:
		return _add_journal_entry(state, command)
	if command is MarkJournalEntryReadCommand:
		return _mark_journal_read(state, command)
	if command is AddInventoryItemCommand:
		return _add_inventory_item(state, command)
	if command is RemoveInventoryItemCommand:
		return _remove_inventory_item(state, command)
	if command is GrantKeepsakeCommand:
		return _grant_keepsake(state, command)
	if command is EquipKeepsakeCommand:
		return _equip_keepsake(state, command)
	if command is UnlockTeaBlendCommand:
		return _unlock_tea_blend(state, command)
	if command is SelectTeaBlendCommand:
		return _select_tea_blend(state, command)
	if command is AdvanceTimeCommand:
		return _advance_time(state, command)
	if command is SetLocationCommand:
		return _set_location(state, command)
	if command is SetRouteIntentCommand:
		return _set_route_intent(state, command)
	if command is SetComfortProfileCommand:
		return _set_comfort_profile(state, command)
	if command is SetEventPositionCommand:
		return _set_event_position(state, command)
	if command is CompleteEventCommand:
		return _complete_event(state, command)
	return CommandResult.failure(
		CommandResult.Code.INVALID_COMMAND,
		command.command_id,
		"unsupported command type: %s" % command.get_script().resource_path
	)


func _set_flag(state: GameState, command: SetFlagCommand) -> CommandResult:
	if command.flag == null or not _matches(command.flag.flag_id, "^(?:flag|evt)\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
		return _invalid(command, "flag must have a valid stable ID")
	state.flags[command.flag.flag_id] = command.flag.duplicate_state()
	return CommandResult.success(command.command_id)


func _adjust_relationship(state: GameState, command: AdjustRelationshipCommand) -> CommandResult:
	if not state.characters.has(command.character_id):
		return _not_found(command, "unknown character: %s" % command.character_id)
	if command.facet not in RelationshipFacetRules.FACETS or command.delta == 0 or absi(command.delta) > 3:
		return _invalid(command, "facet or delta is invalid")
	RelationshipFacetRules.apply_delta(
		state.characters[command.character_id].relationship,
		command.facet,
		command.delta
	)
	return CommandResult.success(command.command_id)


func _add_rumor(state: GameState, command: AddRumorCommand) -> CommandResult:
	var rumor := command.rumor
	if rumor == null or rumor.rumor_id == &"" or rumor.claim_key == &"":
		return _invalid(command, "rumor ID and claim key are required")
	if state.rumors.has(rumor.rumor_id):
		return _already_exists(command, "rumor already exists: %s" % rumor.rumor_id)
	if rumor.source_character_id != &"" and not state.characters.has(rumor.source_character_id):
		return _not_found(command, "unknown rumor source: %s" % rumor.source_character_id)
	if rumor.reliability_milli < 0 or rumor.reliability_milli > 1000:
		return _invalid(command, "rumor reliability must be within 0..1000")
	if rumor.privacy not in RumorState.PRIVACY_VALUES or rumor.status not in RumorState.STATUS_VALUES:
		return _invalid(command, "rumor privacy or status is invalid")
	if rumor.acquired_day < 1 or rumor.acquired_day > state.day:
		return _invalid(command, "rumor acquisition day is invalid")
	state.rumors[rumor.rumor_id] = rumor.duplicate_state()
	return CommandResult.success(command.command_id)


func _set_rumor_status(state: GameState, command: SetRumorStatusCommand) -> CommandResult:
	if not state.rumors.has(command.rumor_id):
		return _not_found(command, "unknown rumor: %s" % command.rumor_id)
	if command.status not in RumorState.STATUS_VALUES:
		return _invalid(command, "unknown rumor status: %s" % command.status)
	if state.rumors[command.rumor_id].status == command.status:
		return _already_exists(command, "rumor already has status %s" % command.status)
	state.rumors[command.rumor_id].status = command.status
	return CommandResult.success(command.command_id)


func _add_journal_entry(state: GameState, command: AddJournalEntryCommand) -> CommandResult:
	var entry := command.entry
	if entry == null or not _matches(entry.entry_id, "^journal\\.") or entry.title_key == &"":
		return _invalid(command, "Journal entry ID and title key are required")
	if state.journal.entries.has(entry.entry_id):
		return _already_exists(command, "Journal entry already exists: %s" % entry.entry_id)
	if entry.discovered_day < 1 or entry.discovered_day > state.day:
		return _invalid(command, "Journal discovery day is invalid")
	state.journal.entries[entry.entry_id] = entry.duplicate_state()
	return CommandResult.success(command.command_id)


func _mark_journal_read(state: GameState, command: MarkJournalEntryReadCommand) -> CommandResult:
	if not state.journal.entries.has(command.entry_id):
		return _not_found(command, "unknown Journal entry: %s" % command.entry_id)
	if state.journal.entries[command.entry_id].is_read:
		return _already_exists(command, "Journal entry is already read: %s" % command.entry_id)
	state.journal.entries[command.entry_id].is_read = true
	return CommandResult.success(command.command_id)


func _add_inventory_item(state: GameState, command: AddInventoryItemCommand) -> CommandResult:
	if not _matches(command.item_id, "^item\\.") or command.count < 1:
		return _invalid(command, "item ID and positive count are required")
	var opening_count := state.inventory.items[command.item_id].count if state.inventory.items.has(command.item_id) else 0
	if opening_count + command.count > MAX_ITEM_COUNT:
		return _invalid(command, "item count would exceed %d" % MAX_ITEM_COUNT)
	state.inventory.items[command.item_id] = InventoryItemState.new(command.item_id, opening_count + command.count)
	return CommandResult.success(command.command_id)


func _remove_inventory_item(state: GameState, command: RemoveInventoryItemCommand) -> CommandResult:
	if command.count < 1:
		return _invalid(command, "removal count must be positive")
	if not state.inventory.items.has(command.item_id):
		return _not_found(command, "item is not owned: %s" % command.item_id)
	var item := state.inventory.items[command.item_id]
	if item.count < command.count:
		return _invalid(command, "cannot remove %d from owned count %d" % [command.count, item.count])
	item.count -= command.count
	if item.count == 0:
		state.inventory.items.erase(command.item_id)
	return CommandResult.success(command.command_id)


func _grant_keepsake(state: GameState, command: GrantKeepsakeCommand) -> CommandResult:
	var keepsake := command.keepsake
	if keepsake == null or not _matches(keepsake.keepsake_id, "^item\\.keepsake\\."):
		return _invalid(command, "Keepsake must have a valid stable ID")
	if state.inventory.keepsakes.has(keepsake.keepsake_id):
		return _already_exists(command, "Keepsake already owned: %s" % keepsake.keepsake_id)
	if keepsake.owner_character_id != &"" and not state.characters.has(keepsake.owner_character_id):
		return _not_found(command, "unknown Keepsake owner: %s" % keepsake.owner_character_id)
	if keepsake.source_event_id != &"" and not _matches(keepsake.source_event_id, "^evt\\."):
		return _invalid(command, "Keepsake source event ID is invalid")
	if keepsake.acquired_day < 1 or keepsake.acquired_day > state.day:
		return _invalid(command, "Keepsake acquisition day is invalid")
	state.inventory.keepsakes[keepsake.keepsake_id] = keepsake.duplicate_state()
	return CommandResult.success(command.command_id)


func _equip_keepsake(state: GameState, command: EquipKeepsakeCommand) -> CommandResult:
	if not state.inventory.keepsakes.has(command.keepsake_id):
		return _not_found(command, "Keepsake is not owned: %s" % command.keepsake_id)
	var is_equipped := command.keepsake_id in state.inventory.equipped_keepsake_ids
	if command.should_equip:
		if is_equipped:
			return _already_exists(command, "Keepsake is already equipped")
		if state.inventory.equipped_keepsake_ids.size() >= InventoryState.MAX_EQUIPPED_KEEPSAKES:
			return CommandResult.failure(CommandResult.Code.CAPACITY_REACHED, command.command_id, "two Keepsakes are already equipped")
		state.inventory.equipped_keepsake_ids.append(command.keepsake_id)
		state.inventory.equipped_keepsake_ids.sort_custom(_id_less)
	else:
		if not is_equipped:
			return _not_found(command, "Keepsake is not equipped")
		state.inventory.equipped_keepsake_ids.erase(command.keepsake_id)
	return CommandResult.success(command.command_id)


func _unlock_tea_blend(state: GameState, command: UnlockTeaBlendCommand) -> CommandResult:
	var blend := command.blend
	if blend == null or not _matches(blend.blend_id, "^tea\\."):
		return _invalid(command, "Tea Blend must have a valid stable ID")
	if state.inventory.tea_blends.has(blend.blend_id):
		return _already_exists(command, "Tea Blend is already unlocked: %s" % blend.blend_id)
	if blend.unlocked_day < 1 or blend.unlocked_day > state.day:
		return _invalid(command, "Tea Blend unlock day is invalid")
	state.inventory.tea_blends[blend.blend_id] = blend.duplicate_state()
	return CommandResult.success(command.command_id)


func _select_tea_blend(state: GameState, command: SelectTeaBlendCommand) -> CommandResult:
	if not state.inventory.tea_blends.has(command.blend_id):
		return _not_found(command, "Tea Blend is not unlocked: %s" % command.blend_id)
	if state.inventory.selected_tea_blend_id == command.blend_id:
		return _already_exists(command, "Tea Blend is already selected")
	state.inventory.selected_tea_blend_id = command.blend_id
	state.inventory.tea_blends[command.blend_id].times_prepared += 1
	return CommandResult.success(command.command_id)


func _advance_time(state: GameState, command: AdvanceTimeCommand) -> CommandResult:
	if not TimeSlotRules.advance(state, command.slot_count):
		return _invalid(command, "slot count must be within 1..4")
	return CommandResult.success(command.command_id)


func _set_location(state: GameState, command: SetLocationCommand) -> CommandResult:
	if not state.regions.has(command.location_id):
		return _not_found(command, "unknown location: %s" % command.location_id)
	if state.current_location == command.location_id:
		return _already_exists(command, "profile is already at %s" % command.location_id)
	state.current_location = command.location_id
	state.regions[command.location_id].visit_count += 1
	state.regions[command.location_id].last_visited_day = state.day
	return CommandResult.success(command.command_id)


func _set_route_intent(state: GameState, command: SetRouteIntentCommand) -> CommandResult:
	if not state.characters.has(command.character_id):
		return _not_found(command, "unknown character: %s" % command.character_id)
	if command.route_intent not in CharacterState.ROUTE_INTENTS or command.route_intent == &"undecided":
		return _invalid(command, "route intent must be friendship, romance, or postponed")
	if state.characters[command.character_id].route_intent == command.route_intent:
		return _already_exists(command, "route intent is already %s" % command.route_intent)
	state.characters[command.character_id].route_intent = command.route_intent
	return CommandResult.success(command.command_id)


func _set_comfort_profile(state: GameState, command: SetComfortProfileCommand) -> CommandResult:
	if command.comfort_profile_id not in ProtagonistState.COMFORT_PROFILE_IDS:
		return _invalid(command, "unknown comfort profile: %s" % command.comfort_profile_id)
	if state.protagonist.comfort_profile_id == command.comfort_profile_id:
		return _already_exists(command, "comfort profile is already %s" % command.comfort_profile_id)
	state.protagonist.comfort_profile_id = command.comfort_profile_id
	return CommandResult.success(command.command_id)


func _set_event_position(state: GameState, command: SetEventPositionCommand) -> CommandResult:
	var is_clear := command.event_id == &"" and command.node_id == &""
	if not is_clear and (
		not _matches(command.event_id, "^evt\\.")
		or not _matches(command.node_id, "^[a-z][a-z0-9_]*$")
	):
		return _invalid(command, "event and node IDs must both be valid or both be empty")
	if (command.event_id == &"") != (command.node_id == &""):
		return _invalid(command, "event and node cursor fields cannot be partially empty")
	if state.active_event_id == command.event_id and state.active_event_node_id == command.node_id:
		return _already_exists(command, "event cursor is already at %s/%s" % [command.event_id, command.node_id])
	state.active_event_id = command.event_id
	state.active_event_node_id = command.node_id
	return CommandResult.success(command.command_id)


func _complete_event(state: GameState, command: CompleteEventCommand) -> CommandResult:
	if not _matches(command.event_id, "^evt\\.") or command.outcome == &"":
		return _invalid(command, "event ID and outcome are required")
	if state.active_event_id != command.event_id or state.active_event_node_id == &"":
		return _invalid(command, "only the active event can complete")
	if command.event_id in state.completed_event_ids:
		return _already_exists(command, "event is already complete: %s" % command.event_id)
	state.completed_event_ids.append(command.event_id)
	state.completed_event_ids.sort_custom(_id_less)
	state.active_event_id = &""
	state.active_event_node_id = &""
	return CommandResult.success(command.command_id)


func _invalid(command: GameCommand, message: String) -> CommandResult:
	return CommandResult.failure(CommandResult.Code.INVALID_ARGUMENT, command.command_id, message)


func _not_found(command: GameCommand, message: String) -> CommandResult:
	return CommandResult.failure(CommandResult.Code.NOT_FOUND, command.command_id, message)


func _already_exists(command: GameCommand, message: String) -> CommandResult:
	return CommandResult.failure(CommandResult.Code.ALREADY_EXISTS, command.command_id, message)


func _matches(value: StringName, pattern: String) -> bool:
	return RegEx.create_from_string(pattern).search(String(value)) != null


func _id_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


func _command_id(command: GameCommand) -> StringName:
	return command.command_id if command != null else &"command.null"
