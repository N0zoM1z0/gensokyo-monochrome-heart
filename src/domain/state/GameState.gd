class_name GameState
extends RefCounted
## Complete locale-independent story snapshot shared by every gameplay mode.

const CURRENT_SCHEMA_VERSION := 2

var schema_version: int = CURRENT_SCHEMA_VERSION
var profile_id: StringName
var chapter_id: StringName = &"chapter.prologue"
var day: int = 1
var time_slot: StringName = &"morning"
var current_location: StringName = &"loc.outside_world"
var protagonist := ProtagonistState.new()
var characters: Dictionary[StringName, CharacterState] = {}
var regions: Dictionary[StringName, RegionState] = {}
var flags: Dictionary[StringName, FlagState] = {}
var inventory := InventoryState.new()
var rumors: Dictionary[StringName, RumorState] = {}
var journal := JournalState.new()
var rng := DeterministicRngState.new()
var route_intent_id: StringName = &"route.return_to_gensokyo"
var active_event_id: StringName = &""
var active_event_node_id: StringName = &""
var completed_event_ids: Array[StringName] = []
var route_completion_ids: Array[StringName] = []
var play_time_seconds: int = 0


func _init(p_profile_id: StringName = &"") -> void:
	profile_id = p_profile_id


func deep_copy() -> GameState:
	var copy := GameState.new(profile_id)
	copy.schema_version = schema_version
	copy.chapter_id = chapter_id
	copy.day = day
	copy.time_slot = time_slot
	copy.current_location = current_location
	copy.protagonist = protagonist.duplicate_state()
	for character_id: StringName in characters:
		copy.characters[character_id] = characters[character_id].duplicate_state()
	for region_id: StringName in regions:
		copy.regions[region_id] = regions[region_id].duplicate_state()
	for flag_id: StringName in flags:
		copy.flags[flag_id] = flags[flag_id].duplicate_state()
	copy.inventory = inventory.duplicate_state()
	for rumor_id: StringName in rumors:
		copy.rumors[rumor_id] = rumors[rumor_id].duplicate_state()
	copy.journal = journal.duplicate_state()
	copy.rng = rng.duplicate_state()
	copy.route_intent_id = route_intent_id
	copy.active_event_id = active_event_id
	copy.active_event_node_id = active_event_node_id
	copy.completed_event_ids = completed_event_ids.duplicate()
	copy.route_completion_ids = route_completion_ids.duplicate()
	copy.play_time_seconds = play_time_seconds
	return copy


func copy_from(source: GameState) -> void:
	var copy := source.deep_copy()
	schema_version = copy.schema_version
	profile_id = copy.profile_id
	chapter_id = copy.chapter_id
	day = copy.day
	time_slot = copy.time_slot
	current_location = copy.current_location
	protagonist = copy.protagonist
	characters = copy.characters
	regions = copy.regions
	flags = copy.flags
	inventory = copy.inventory
	rumors = copy.rumors
	journal = copy.journal
	rng = copy.rng
	route_intent_id = copy.route_intent_id
	active_event_id = copy.active_event_id
	active_event_node_id = copy.active_event_node_id
	completed_event_ids = copy.completed_event_ids
	route_completion_ids = copy.route_completion_ids
	play_time_seconds = copy.play_time_seconds
