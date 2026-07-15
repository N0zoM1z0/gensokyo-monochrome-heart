class_name GameStateInspector
extends RefCounted
## Deterministic inspection projection for fixtures, migrations, and command debugging.


static func inspect(state: GameState, source_label: String = "runtime") -> GameStateInspectionReport:
	var report := GameStateInspectionReport.new()
	report.source_label = source_label.get_file()
	if state == null:
		report.errors.append("GameState is missing")
		return report
	report.profile_id = state.profile_id
	report.schema_version = state.schema_version
	report.errors = GameStateValidator.new().validate(state)
	report.is_valid = report.errors.is_empty()
	var protagonist_origin: StringName = state.protagonist.origin_id if state.protagonist != null else &"missing"
	var comfort_profile: StringName = state.protagonist.comfort_profile_id if state.protagonist != null else &"missing"
	var profile_seed := state.protagonist.profile_seed if state.protagonist != null else 0
	var journal_count := state.journal.entries.size() if state.journal != null else 0
	var item_count := state.inventory.items.size() if state.inventory != null else 0
	var keepsake_count := state.inventory.keepsakes.size() if state.inventory != null else 0
	var tea_count := state.inventory.tea_blends.size() if state.inventory != null else 0
	var rng_initial := state.rng.initial_seed if state.rng != null else 0
	var rng_current := state.rng.current_state if state.rng != null else 0
	var rng_draws := state.rng.draw_count if state.rng != null else 0
	report.summary_lines = [
		"STATE profile=%s schema=%d chapter=%s" % [state.profile_id, state.schema_version, state.chapter_id],
		"CLOCK day=%d slot=%s location=%s play_seconds=%d" % [state.day, state.time_slot, state.current_location, state.play_time_seconds],
		"PROTAGONIST origin=%s comfort=%s seed=%d" % [protagonist_origin, comfort_profile, profile_seed],
		"COUNTS characters=%d regions=%d flags=%d rumors=%d journal=%d items=%d keepsakes=%d tea=%d" % [
			state.characters.size(), state.regions.size(), state.flags.size(), state.rumors.size(),
			journal_count, item_count, keepsake_count, tea_count,
		],
		"RNG initial=%d current=%d draws=%d" % [rng_initial, rng_current, rng_draws],
		"EVENT active=%s node=%s completed=%d route_intent=%s" % [
			state.active_event_id if state.active_event_id != &"" else &"none",
			state.active_event_node_id if state.active_event_node_id != &"" else &"none",
			state.completed_event_ids.size(), state.route_intent_id,
		],
	]
	var character_ids := _sorted_ids(state.characters.keys())
	for character_id: StringName in character_ids:
		var character := state.characters[character_id]
		if character == null or character.relationship == null:
			continue
		var facets: PackedStringArray = []
		for facet: StringName in RelationshipFacetRules.FACETS:
			var value := RelationshipFacetRules.value_for(character.relationship, facet)
			facets.append("%s=%d(%s)" % [facet, value, RelationshipFacetRules.band_for_value(value)])
		report.hidden_facet_lines.append(
			"%s route_stage=%d route_intent=%s %s" % [
				character_id, character.route_stage, character.route_intent, " ".join(facets),
			]
		)
	return report


static func _sorted_ids(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in values:
		result.append(StringName(value))
	result.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	return result
