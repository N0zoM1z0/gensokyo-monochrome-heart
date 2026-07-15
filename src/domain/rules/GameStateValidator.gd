class_name GameStateValidator
extends RefCounted
## Pure invariant validation used before commands, transactions, and persistence.


func validate(state: GameState) -> Array[String]:
	var errors: Array[String] = []
	if state == null:
		return ["game state is missing"]
	if state.schema_version != GameState.CURRENT_SCHEMA_VERSION:
		errors.append("schema version must be %d" % GameState.CURRENT_SCHEMA_VERSION)
	if not _matches(state.profile_id, "^p[0-9]{2,}$"):
		errors.append("invalid profile ID: %s" % state.profile_id)
	if not _matches(state.chapter_id, "^chapter\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
		errors.append("invalid chapter ID: %s" % state.chapter_id)
	if state.day < 1:
		errors.append("day must be positive")
	if not TimeSlotRules.is_valid(state.time_slot):
		errors.append("invalid time slot: %s" % state.time_slot)
	if not state.regions.has(state.current_location):
		errors.append("current location is absent from regions: %s" % state.current_location)
	if state.protagonist == null or state.protagonist.profile_seed <= 0:
		errors.append("protagonist profile seed must be positive")
	elif not _matches(state.protagonist.origin_id, "^origin\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
		errors.append("invalid protagonist origin: %s" % state.protagonist.origin_id)
	elif state.protagonist.comfort_profile_id not in ProtagonistState.COMFORT_PROFILE_IDS:
		errors.append("invalid comfort profile: %s" % state.protagonist.comfort_profile_id)
	_validate_characters(state, errors)
	_validate_regions(state, errors)
	_validate_flags(state, errors)
	_validate_inventory(state.inventory, errors)
	_validate_rumors(state, errors)
	_validate_journal(state.journal, errors)
	if state.rng == null or state.rng.current_state <= 0 or state.rng.draw_count < 0:
		errors.append("deterministic RNG state is invalid")
	if state.play_time_seconds < 0:
		errors.append("play time cannot be negative")
	if state.active_event_id != &"" and not _matches(state.active_event_id, "^evt\\."):
		errors.append("active event ID is invalid: %s" % state.active_event_id)
	_check_unique(state.completed_event_ids, "completed event", errors)
	_check_unique(state.route_completion_ids, "route completion", errors)
	return errors


func _validate_characters(state: GameState, errors: Array[String]) -> void:
	for character_id: StringName in state.characters:
		var character := state.characters[character_id]
		if character == null or character.character_id != character_id or not _matches(character_id, "^char\\."):
			errors.append("invalid character state: %s" % character_id)
			continue
		errors.append_array(RelationshipFacetRules.validate(character.relationship, character_id))
		if character.route_stage < 0:
			errors.append("%s route stage cannot be negative" % character_id)
		if character.route_intent not in CharacterState.ROUTE_INTENTS:
			errors.append("%s has invalid route intent %s" % [character_id, character.route_intent])
		_check_unique(character.memory_tags, "%s memory tag" % character_id, errors)
		_check_unique(character.completed_event_ids, "%s completed event" % character_id, errors)


func _validate_regions(state: GameState, errors: Array[String]) -> void:
	for region_id: StringName in state.regions:
		var region := state.regions[region_id]
		if region == null or region.region_id != region_id or not _matches(region_id, "^loc\\."):
			errors.append("invalid region state: %s" % region_id)
			continue
		if region.visit_count < 0 or region.last_visited_day < 0:
			errors.append("%s has negative visit metadata" % region_id)
		_check_unique(region.discovered_spot_ids, "%s discovered spot" % region_id, errors)


func _validate_flags(state: GameState, errors: Array[String]) -> void:
	for flag_id: StringName in state.flags:
		var flag := state.flags[flag_id]
		if flag == null or flag.flag_id != flag_id or not _matches(flag_id, "^flag\\."):
			errors.append("invalid flag state: %s" % flag_id)
		elif flag.kind == FlagState.Kind.STABLE_ID and flag.stable_id_value == &"":
			errors.append("%s has an empty stable-ID value" % flag_id)


func _validate_inventory(inventory: InventoryState, errors: Array[String]) -> void:
	if inventory == null:
		errors.append("inventory state is missing")
		return
	for item_id: StringName in inventory.items:
		var item := inventory.items[item_id]
		if item == null or item.item_id != item_id or not _matches(item_id, "^item\\.") or item.count < 1:
			errors.append("invalid inventory item: %s" % item_id)
	for keepsake_id: StringName in inventory.keepsakes:
		var keepsake := inventory.keepsakes[keepsake_id]
		if keepsake == null or keepsake.keepsake_id != keepsake_id or not _matches(keepsake_id, "^item\\.keepsake\\."):
			errors.append("invalid Keepsake: %s" % keepsake_id)
	for blend_id: StringName in inventory.tea_blends:
		var blend := inventory.tea_blends[blend_id]
		if blend == null or blend.blend_id != blend_id or not _matches(blend_id, "^tea\\."):
			errors.append("invalid Tea Blend: %s" % blend_id)
	if inventory.equipped_keepsake_ids.size() > InventoryState.MAX_EQUIPPED_KEEPSAKES:
		errors.append("more than two Keepsakes are equipped")
	_check_unique(inventory.equipped_keepsake_ids, "equipped Keepsake", errors)
	for equipped_id: StringName in inventory.equipped_keepsake_ids:
		if not inventory.keepsakes.has(equipped_id):
			errors.append("equipped Keepsake is not owned: %s" % equipped_id)
	if not inventory.tea_blends.has(inventory.selected_tea_blend_id):
		errors.append("selected Tea Blend is not unlocked: %s" % inventory.selected_tea_blend_id)


func _validate_rumors(state: GameState, errors: Array[String]) -> void:
	for rumor_id: StringName in state.rumors:
		var rumor := state.rumors[rumor_id]
		if rumor == null or rumor.rumor_id != rumor_id or rumor.claim_key == &"":
			errors.append("invalid rumor state: %s" % rumor_id)
			continue
		if rumor.reliability_milli < 0 or rumor.reliability_milli > 1000:
			errors.append("%s reliability must be within 0..1000" % rumor_id)
		if rumor.privacy not in RumorState.PRIVACY_VALUES or rumor.status not in RumorState.STATUS_VALUES:
			errors.append("%s has invalid privacy or status" % rumor_id)
		if rumor.mutation_count < 0 or rumor.acquired_day < 1:
			errors.append("%s has invalid mutation/day metadata" % rumor_id)


func _validate_journal(journal: JournalState, errors: Array[String]) -> void:
	if journal == null:
		errors.append("Journal state is missing")
		return
	for entry_id: StringName in journal.entries:
		var entry := journal.entries[entry_id]
		if entry == null or entry.entry_id != entry_id or entry.title_key == &"" or entry.discovered_day < 1:
			errors.append("invalid Journal entry: %s" % entry_id)
			continue
		_check_unique(entry.observation_keys, "%s observation" % entry_id, errors)
		_check_unique(entry.tags, "%s tag" % entry_id, errors)
	_check_unique(journal.replay_event_ids, "Journal replay event", errors)
	_check_unique(journal.glossary_entry_ids, "Journal glossary entry", errors)


func _check_unique(values: Array[StringName], label: String, errors: Array[String]) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for value: StringName in values:
		if value == &"" or seen.has(value):
			errors.append("%s list contains an empty or duplicate ID: %s" % [label, value])
		else:
			seen[value] = true


func _matches(value: StringName, pattern: String) -> bool:
	return RegEx.create_from_string(pattern).search(String(value)) != null
