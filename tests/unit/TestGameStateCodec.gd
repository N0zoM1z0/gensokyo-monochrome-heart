class_name TestGameStateCodec
extends RefCounted
## Typed v2 persistence boundary, canonical JSON, and corruption rejection tests.


func run() -> Array[String]:
	var failures: Array[String] = []
	var state := _create_rich_state()
	if state == null:
		return ["could not create rich codec fixture"]
	var codec := GameStateCodec.new()
	var payload := codec.encode(state)
	var decoded := codec.decode(payload)
	if not decoded.is_success():
		failures.append("valid v2 payload failed typed decode: %s" % "; ".join(decoded.errors))
	else:
		var before := codec.canonical_state(state)
		var after := codec.canonical_state(decoded.state)
		if before != after:
			failures.append("GameState encode/decode round trip is not deep-equal")
		if decoded.state.rng.next_u32() != state.rng.next_u32():
			failures.append("codec did not resume deterministic RNG state")
	_expect_canonical_json(failures)
	_expect_schema_rejection(payload, codec, failures)
	return failures


func _expect_canonical_json(failures: Array[String]) -> void:
	var first := {"z": 3, "a": {"y": 2, "x": 1}, "list": [&"b", &"a"]}
	var second := {"list": [&"b", &"a"], "a": {"x": 1, "y": 2}, "z": 3}
	if CanonicalJson.stringify(first) != CanonicalJson.stringify(second):
		failures.append("canonical JSON depends on Dictionary insertion order")
	if CanonicalJson.sha256(first).length() != 64 or CanonicalJson.sha256(first) != CanonicalJson.sha256(second):
		failures.append("canonical JSON SHA-256 is absent or nondeterministic")
	var parsed: Variant = JSON.parse_string(JSON.stringify(first))
	if not parsed is Dictionary or CanonicalJson.stringify(first) != CanonicalJson.stringify(parsed):
		failures.append("canonical JSON changes when Godot parses integer tokens as integral floats")
	if CanonicalJson.stringify({"fraction": 0.5}) == CanonicalJson.stringify({"fraction": 0}):
		failures.append("canonical JSON collapsed a genuine fractional value")


func _expect_schema_rejection(payload: Dictionary, codec: GameStateCodec, failures: Array[String]) -> void:
	var out_of_bounds := payload.duplicate(true)
	out_of_bounds.characters["char.reimu_hakurei"].relationship.trust = 99
	var result := codec.decode(out_of_bounds)
	if result.is_success() or not _contains(result.errors, "must be <= 3"):
		failures.append("v2 schema accepted an out-of-bounds hidden facet")
	var missing_required := payload.duplicate(true)
	missing_required.erase("rng")
	result = codec.decode(missing_required)
	if result.is_success() or not _contains(result.errors, "missing required property rng"):
		failures.append("v2 schema accepted a missing RNG state")
	var extra_property := payload.duplicate(true)
	extra_property["raw_node_path"] = "../../World"
	result = codec.decode(extra_property)
	if result.is_success() or not _contains(result.errors, "unsupported property"):
		failures.append("v2 schema retained an unsupported persistence field")
	var mismatched_flag := payload.duplicate(true)
	mismatched_flag.flags["flag.fixture.ready"].kind = "bool"
	mismatched_flag.flags["flag.fixture.ready"].value = 3
	result = codec.decode(mismatched_flag)
	if result.is_success() or not _contains(result.errors, "does not match"):
		failures.append("codec accepted a flag kind/value mismatch")


func _create_rich_state() -> GameState:
	var repository := ContentRepository.new()
	if not repository.load_sources().is_success():
		return null
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in repository.all_characters():
		character_ids.append(character.id)
	var region_ids: Array[StringName] = []
	for location: LocationRecord in repository.all_locations():
		region_ids.append(location.id)
	var state := GameStateFactory.create_new(&"p03", character_ids, region_ids, 987654)
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.fixture.ready", &"state.ready")))
	dispatcher.dispatch(state, AdjustRelationshipCommand.new(&"char.reimu_hakurei", &"trust", 2))
	dispatcher.dispatch(state, AddInventoryItemCommand.new(&"item.fixture.leaf", 3))
	var keepsake := KeepsakeState.new(&"item.keepsake.unpaired_cup")
	keepsake.source_event_id = &"evt.hkr.empty_cushion"
	keepsake.owner_character_id = &"char.reimu_hakurei"
	keepsake.dialogue_tags = [&"shrine.second_cup"]
	dispatcher.dispatch(state, GrantKeepsakeCommand.new(keepsake))
	dispatcher.dispatch(state, EquipKeepsakeCommand.new(keepsake.keepsake_id, true))
	var blend := TeaBlendState.new(&"tea.roasted")
	dispatcher.dispatch(state, UnlockTeaBlendCommand.new(blend))
	dispatcher.dispatch(state, SelectTeaBlendCommand.new(blend.blend_id))
	var rumor := RumorState.new(&"rumor.fixture.missing_minute")
	rumor.claim_key = &"rumor.fixture.missing_minute.claim"
	rumor.source_character_id = &"char.reimu_hakurei"
	rumor.reliability_milli = 550
	rumor.privacy = &"public"
	dispatcher.dispatch(state, AddRumorCommand.new(rumor))
	var entry := JournalEntryState.new(&"journal.fixture.empty_cushion")
	entry.title_key = &"evt.hkr.empty_cushion.title"
	entry.source_event_id = &"evt.hkr.empty_cushion"
	entry.observation_keys = [&"dlg.hkr.empty_cushion.reimu.001", &"cue.reimu.look_at_cup"]
	dispatcher.dispatch(state, AddJournalEntryCommand.new(entry))
	dispatcher.dispatch(state, SetRouteIntentCommand.new(&"char.reimu_hakurei", &"friendship"))
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	state.active_event_id = &"evt.hkr.empty_cushion"
	state.active_event_node_id = &"n004"
	state.completed_event_ids = [&"evt.pro.phone_no_signal"]
	state.route_completion_ids = [&"route.prologue.returned"]
	state.play_time_seconds = 371
	state.rng.next_u32()
	state.rng.next_u32()
	return state


func _contains(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false
