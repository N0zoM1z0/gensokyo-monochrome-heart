class_name GameStateCodec
extends RefCounted
## The only boundary that converts complete GameState snapshots to/from Dictionaries.

const SCHEMA_PATH := "res://schemas/game_state_v2.schema.json"

var _schema: Dictionary = {}


func encode(state: GameState) -> Dictionary:
	return {
		"schema_version": state.schema_version,
		"profile_id": String(state.profile_id),
		"chapter_id": String(state.chapter_id),
		"day": state.day,
		"time_slot": String(state.time_slot),
		"current_location": String(state.current_location),
		"protagonist": _encode_protagonist(state.protagonist),
		"characters": _encode_characters(state.characters),
		"regions": _encode_regions(state.regions),
		"flags": _encode_flags(state.flags),
		"inventory": _encode_inventory(state.inventory),
		"rumors": _encode_rumors(state.rumors),
		"journal": _encode_journal(state.journal),
		"rng": {
			"initial_seed": state.rng.initial_seed,
			"current_state": state.rng.current_state,
			"draw_count": state.rng.draw_count,
		},
		"route_intent_id": String(state.route_intent_id),
		"active_event_id": String(state.active_event_id),
		"active_event_node_id": String(state.active_event_node_id),
		"completed_event_ids": _names(state.completed_event_ids, true),
		"route_completion_ids": _names(state.route_completion_ids, true),
		"play_time_seconds": state.play_time_seconds,
	}


func decode(payload: Variant) -> GameStateCodecResult:
	var result := GameStateCodecResult.new()
	if not payload is Dictionary:
		result.errors.append("GameState payload must be an object")
		return result
	var schema := _load_schema(result.errors)
	if schema.is_empty():
		return result
	for error: String in JsonSchemaValidator.new().validate(payload, schema):
		result.errors.append("schema: %s" % error)
	var raw: Dictionary = payload
	_validate_flag_kinds(raw.get("flags", {}), result.errors)
	if not result.errors.is_empty():
		return result
	var state := GameState.new(StringName(raw.profile_id))
	state.schema_version = int(raw.schema_version)
	state.chapter_id = StringName(raw.chapter_id)
	state.day = int(raw.day)
	state.time_slot = StringName(raw.time_slot)
	state.current_location = StringName(raw.current_location)
	state.protagonist = _decode_protagonist(raw.protagonist)
	state.characters = _decode_characters(raw.characters)
	state.regions = _decode_regions(raw.regions)
	state.flags = _decode_flags(raw.flags)
	state.inventory = _decode_inventory(raw.inventory)
	state.rumors = _decode_rumors(raw.rumors)
	state.journal = _decode_journal(raw.journal)
	state.rng = _decode_rng(raw.rng)
	state.route_intent_id = StringName(raw.route_intent_id)
	state.active_event_id = StringName(raw.active_event_id)
	state.active_event_node_id = StringName(raw.active_event_node_id)
	state.completed_event_ids = _name_array(raw.completed_event_ids)
	state.route_completion_ids = _name_array(raw.route_completion_ids)
	state.play_time_seconds = int(raw.play_time_seconds)
	result.errors.append_array(GameStateValidator.new().validate(state))
	if result.errors.is_empty():
		result.state = state
	return result


func canonical_state(state: GameState) -> String:
	return CanonicalJson.stringify(encode(state))


func _encode_protagonist(state: ProtagonistState) -> Dictionary:
	return {
		"origin_id": String(state.origin_id),
		"comfort_profile_id": String(state.comfort_profile_id),
		"profile_seed": state.profile_seed,
	}


func _encode_characters(characters: Dictionary[StringName, CharacterState]) -> Dictionary:
	var result: Dictionary = {}
	for character_id: StringName in _sorted_ids(characters.keys()):
		var character := characters[character_id]
		result[String(character_id)] = {
			"character_id": String(character.character_id),
			"relationship": {
				"trust": character.relationship.trust,
				"ease": character.relationship.ease,
				"respect": character.relationship.respect,
				"spark": character.relationship.spark,
				"strain": character.relationship.strain,
			},
			"route_stage": character.route_stage,
			"route_intent": String(character.route_intent),
			"memory_tags": _names(character.memory_tags, true),
			"completed_event_ids": _names(character.completed_event_ids, true),
			"is_available": character.is_available,
		}
	return result


func _encode_regions(regions: Dictionary[StringName, RegionState]) -> Dictionary:
	var result: Dictionary = {}
	for region_id: StringName in _sorted_ids(regions.keys()):
		var region := regions[region_id]
		result[String(region_id)] = {
			"region_id": String(region.region_id),
			"condition_id": String(region.condition_id),
			"visit_count": region.visit_count,
			"last_visited_day": region.last_visited_day,
			"discovered_spot_ids": _names(region.discovered_spot_ids, true),
		}
	return result


func _encode_flags(flags: Dictionary[StringName, FlagState]) -> Dictionary:
	var result: Dictionary = {}
	for flag_id: StringName in _sorted_ids(flags.keys()):
		var flag := flags[flag_id]
		result[String(flag_id)] = {
			"flag_id": String(flag.flag_id),
			"kind": _flag_kind_name(flag.kind),
			"value": String(flag.value()) if flag.kind == FlagState.Kind.STABLE_ID else flag.value(),
		}
	return result


func _encode_inventory(inventory: InventoryState) -> Dictionary:
	var items: Dictionary = {}
	for item_id: StringName in _sorted_ids(inventory.items.keys()):
		items[String(item_id)] = {
			"item_id": String(item_id),
			"count": inventory.items[item_id].count,
		}
	var keepsakes: Dictionary = {}
	for keepsake_id: StringName in _sorted_ids(inventory.keepsakes.keys()):
		var keepsake := inventory.keepsakes[keepsake_id]
		keepsakes[String(keepsake_id)] = {
			"keepsake_id": String(keepsake.keepsake_id),
			"source_event_id": String(keepsake.source_event_id),
			"owner_character_id": String(keepsake.owner_character_id),
			"acquired_day": keepsake.acquired_day,
			"is_returnable": keepsake.is_returnable,
			"dialogue_tags": _names(keepsake.dialogue_tags, true),
		}
	var tea_blends: Dictionary = {}
	for blend_id: StringName in _sorted_ids(inventory.tea_blends.keys()):
		var blend := inventory.tea_blends[blend_id]
		tea_blends[String(blend_id)] = {
			"blend_id": String(blend.blend_id),
			"unlocked_day": blend.unlocked_day,
			"times_prepared": blend.times_prepared,
		}
	return {
		"items": items,
		"keepsakes": keepsakes,
		"tea_blends": tea_blends,
		"equipped_keepsake_ids": _names(inventory.equipped_keepsake_ids, true),
		"selected_tea_blend_id": String(inventory.selected_tea_blend_id),
	}


func _encode_rumors(rumors: Dictionary[StringName, RumorState]) -> Dictionary:
	var result: Dictionary = {}
	for rumor_id: StringName in _sorted_ids(rumors.keys()):
		var rumor := rumors[rumor_id]
		result[String(rumor_id)] = {
			"rumor_id": String(rumor.rumor_id),
			"claim_key": String(rumor.claim_key),
			"source_character_id": String(rumor.source_character_id),
			"reliability_milli": rumor.reliability_milli,
			"privacy": String(rumor.privacy),
			"mutation_count": rumor.mutation_count,
			"status": String(rumor.status),
			"acquired_day": rumor.acquired_day,
		}
	return result


func _encode_journal(journal: JournalState) -> Dictionary:
	var entries: Dictionary = {}
	for entry_id: StringName in _sorted_ids(journal.entries.keys()):
		var entry := journal.entries[entry_id]
		entries[String(entry_id)] = {
			"entry_id": String(entry.entry_id),
			"title_key": String(entry.title_key),
			"entry_type": String(entry.entry_type),
			"source_event_id": String(entry.source_event_id),
			"discovered_day": entry.discovered_day,
			"observation_keys": _names(entry.observation_keys, false),
			"tags": _names(entry.tags, true),
			"is_read": entry.is_read,
		}
	return {
		"entries": entries,
		"replay_event_ids": _names(journal.replay_event_ids, true),
		"glossary_entry_ids": _names(journal.glossary_entry_ids, true),
	}


func _decode_protagonist(raw: Dictionary) -> ProtagonistState:
	var state := ProtagonistState.new()
	state.origin_id = StringName(raw.origin_id)
	state.comfort_profile_id = StringName(raw.comfort_profile_id)
	state.profile_seed = int(raw.profile_seed)
	return state


func _decode_characters(raw: Dictionary) -> Dictionary[StringName, CharacterState]:
	var result: Dictionary[StringName, CharacterState] = {}
	for raw_id: Variant in raw:
		var record: Dictionary = raw[raw_id]
		var character := CharacterState.new(StringName(record.character_id))
		var relationship: Dictionary = record.relationship
		character.relationship.trust = int(relationship.trust)
		character.relationship.ease = int(relationship.ease)
		character.relationship.respect = int(relationship.respect)
		character.relationship.spark = int(relationship.spark)
		character.relationship.strain = int(relationship.strain)
		character.route_stage = int(record.route_stage)
		character.route_intent = StringName(record.route_intent)
		character.memory_tags = _name_array(record.memory_tags)
		character.completed_event_ids = _name_array(record.completed_event_ids)
		character.is_available = bool(record.is_available)
		result[StringName(raw_id)] = character
	return result


func _decode_regions(raw: Dictionary) -> Dictionary[StringName, RegionState]:
	var result: Dictionary[StringName, RegionState] = {}
	for raw_id: Variant in raw:
		var record: Dictionary = raw[raw_id]
		var region := RegionState.new(StringName(record.region_id))
		region.condition_id = StringName(record.condition_id)
		region.visit_count = int(record.visit_count)
		region.last_visited_day = int(record.last_visited_day)
		region.discovered_spot_ids = _name_array(record.discovered_spot_ids)
		result[StringName(raw_id)] = region
	return result


func _decode_flags(raw: Dictionary) -> Dictionary[StringName, FlagState]:
	var result: Dictionary[StringName, FlagState] = {}
	for raw_id: Variant in raw:
		var record: Dictionary = raw[raw_id]
		var value: Variant = record.value
		# JSON numbers may arrive as floats even after the schema accepted an
		# integer-valued token. Restore the declared closed flag kind explicitly.
		if String(record.kind) == "int":
			value = int(record.value)
		elif String(record.kind) == "id":
			value = StringName(record.value)
		var flag := FlagState.from_value(StringName(record.flag_id), value)
		result[StringName(raw_id)] = flag
	return result


func _decode_inventory(raw: Dictionary) -> InventoryState:
	var state := InventoryState.new()
	for raw_id: Variant in raw.items:
		var record: Dictionary = raw.items[raw_id]
		state.items[StringName(raw_id)] = InventoryItemState.new(StringName(record.item_id), int(record.count))
	for raw_id: Variant in raw.keepsakes:
		var record: Dictionary = raw.keepsakes[raw_id]
		var keepsake := KeepsakeState.new(StringName(record.keepsake_id))
		keepsake.source_event_id = StringName(record.source_event_id)
		keepsake.owner_character_id = StringName(record.owner_character_id)
		keepsake.acquired_day = int(record.acquired_day)
		keepsake.is_returnable = bool(record.is_returnable)
		keepsake.dialogue_tags = _name_array(record.dialogue_tags)
		state.keepsakes[StringName(raw_id)] = keepsake
	for raw_id: Variant in raw.tea_blends:
		var record: Dictionary = raw.tea_blends[raw_id]
		var blend := TeaBlendState.new(StringName(record.blend_id))
		blend.unlocked_day = int(record.unlocked_day)
		blend.times_prepared = int(record.times_prepared)
		state.tea_blends[StringName(raw_id)] = blend
	state.equipped_keepsake_ids = _name_array(raw.equipped_keepsake_ids)
	state.selected_tea_blend_id = StringName(raw.selected_tea_blend_id)
	return state


func _decode_rumors(raw: Dictionary) -> Dictionary[StringName, RumorState]:
	var result: Dictionary[StringName, RumorState] = {}
	for raw_id: Variant in raw:
		var record: Dictionary = raw[raw_id]
		var rumor := RumorState.new(StringName(record.rumor_id))
		rumor.claim_key = StringName(record.claim_key)
		rumor.source_character_id = StringName(record.source_character_id)
		rumor.reliability_milli = int(record.reliability_milli)
		rumor.privacy = StringName(record.privacy)
		rumor.mutation_count = int(record.mutation_count)
		rumor.status = StringName(record.status)
		rumor.acquired_day = int(record.acquired_day)
		result[StringName(raw_id)] = rumor
	return result


func _decode_journal(raw: Dictionary) -> JournalState:
	var state := JournalState.new()
	for raw_id: Variant in raw.entries:
		var record: Dictionary = raw.entries[raw_id]
		var entry := JournalEntryState.new(StringName(record.entry_id))
		entry.title_key = StringName(record.title_key)
		entry.entry_type = StringName(record.entry_type)
		entry.source_event_id = StringName(record.source_event_id)
		entry.discovered_day = int(record.discovered_day)
		entry.observation_keys = _name_array(record.observation_keys)
		entry.tags = _name_array(record.tags)
		entry.is_read = bool(record.is_read)
		state.entries[StringName(raw_id)] = entry
	state.replay_event_ids = _name_array(raw.replay_event_ids)
	state.glossary_entry_ids = _name_array(raw.glossary_entry_ids)
	return state


func _decode_rng(raw: Dictionary) -> DeterministicRngState:
	var state := DeterministicRngState.new(int(raw.initial_seed))
	state.current_state = int(raw.current_state)
	state.draw_count = int(raw.draw_count)
	return state


func _load_schema(errors: Array[String]) -> Dictionary:
	if not _schema.is_empty():
		return _schema
	if not FileAccess.file_exists(SCHEMA_PATH):
		errors.append("missing GameState schema: %s" % SCHEMA_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCHEMA_PATH))
	if not parsed is Dictionary:
		errors.append("GameState schema is not a JSON object")
		return {}
	_schema = parsed
	return _schema


func _validate_flag_kinds(raw_flags: Variant, errors: Array[String]) -> void:
	if not raw_flags is Dictionary:
		return
	for raw_id: Variant in raw_flags:
		var record: Variant = raw_flags[raw_id]
		if not record is Dictionary or not record.has("kind") or not record.has("value"):
			continue
		var expected_kind := ""
		match typeof(record.value):
			TYPE_BOOL:
				expected_kind = "bool"
			TYPE_INT, TYPE_FLOAT:
				expected_kind = "int"
			TYPE_STRING, TYPE_STRING_NAME:
				expected_kind = "id"
		if String(record.kind) != expected_kind:
			errors.append("flag %s kind %s does not match its %s value" % [raw_id, record.kind, expected_kind])


func _flag_kind_name(kind: FlagState.Kind) -> String:
	match kind:
		FlagState.Kind.INTEGER:
			return "int"
		FlagState.Kind.STABLE_ID:
			return "id"
		_:
			return "bool"


func _names(values: Array[StringName], should_sort: bool) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	if should_sort:
		result.sort()
	return result


func _name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in values:
		result.append(StringName(value))
	return result


func _sorted_ids(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in values:
		result.append(StringName(value))
	result.sort_custom(_id_less)
	return result


func _id_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
