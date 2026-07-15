class_name TestGameCommands
extends RefCounted
## Positive/negative coverage for every M03 command and transaction atomicity.

var _base_state: GameState
var _dispatcher := GameCommandDispatcher.new()


func run() -> Array[String]:
	var failures: Array[String] = []
	_base_state = _create_base_state()
	if _base_state == null:
		return ["could not construct command fixture state"]
	_test_flags(failures)
	_test_relationships(failures)
	_test_rumors(failures)
	_test_journal(failures)
	_test_items(failures)
	_test_keepsakes(failures)
	_test_tea_blends(failures)
	_test_comfort_profile(failures)
	_test_time_location_route(failures)
	_test_event_cursor(failures)
	_test_unsupported_and_invariant_rejection(failures)
	_test_transactions(failures)
	_test_player_safe_relationship_view(failures)
	return failures


func _test_flags(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_success("SetFlagCommand positive", _dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.fixture.ready", true))), failures)
	if not state.flags.has(&"flag.fixture.ready") or state.flags[&"flag.fixture.ready"].value() != true:
		failures.append("SetFlagCommand did not store the typed value")
	_expect_failure("SetFlagCommand negative", _dispatcher.dispatch(state, SetFlagCommand.new(null)), failures)
	if state.flags.size() != 1:
		failures.append("rejected SetFlagCommand changed state")


func _test_relationships(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_success(
		"AdjustRelationshipCommand positive",
		_dispatcher.dispatch(state, AdjustRelationshipCommand.new(&"char.reimu_hakurei", &"trust", 2)),
		failures
	)
	var opening := state.characters[&"char.reimu_hakurei"].relationship.trust
	_expect_failure(
		"AdjustRelationshipCommand negative",
		_dispatcher.dispatch(state, AdjustRelationshipCommand.new(&"char.reimu_hakurei", &"affection", 1)),
		failures
	)
	if opening != 2 or state.characters[&"char.reimu_hakurei"].relationship.trust != opening:
		failures.append("rejected relationship command changed hidden facets")


func _test_rumors(failures: Array[String]) -> void:
	var state := _fresh()
	var rumor := _rumor_fixture()
	_expect_success("AddRumorCommand positive", _dispatcher.dispatch(state, AddRumorCommand.new(rumor)), failures)
	_expect_failure("AddRumorCommand negative", _dispatcher.dispatch(state, AddRumorCommand.new(rumor)), failures)
	_expect_success(
		"SetRumorStatusCommand positive",
		_dispatcher.dispatch(state, SetRumorStatusCommand.new(rumor.rumor_id, &"corrected")),
		failures
	)
	_expect_failure(
		"SetRumorStatusCommand negative",
		_dispatcher.dispatch(state, SetRumorStatusCommand.new(rumor.rumor_id, &"invented")),
		failures
	)
	if state.rumors[rumor.rumor_id].status != &"corrected":
		failures.append("rejected rumor status command changed the accepted status")


func _test_journal(failures: Array[String]) -> void:
	var state := _fresh()
	var entry := _journal_fixture()
	_expect_success("AddJournalEntryCommand positive", _dispatcher.dispatch(state, AddJournalEntryCommand.new(entry)), failures)
	_expect_failure("AddJournalEntryCommand negative", _dispatcher.dispatch(state, AddJournalEntryCommand.new(entry)), failures)
	_expect_success(
		"MarkJournalEntryReadCommand positive",
		_dispatcher.dispatch(state, MarkJournalEntryReadCommand.new(entry.entry_id)),
		failures
	)
	_expect_failure(
		"MarkJournalEntryReadCommand negative",
		_dispatcher.dispatch(state, MarkJournalEntryReadCommand.new(entry.entry_id)),
		failures
	)
	if not state.journal.entries[entry.entry_id].is_read:
		failures.append("Journal read command did not preserve its committed fact")
	_expect_success(
		"UnlockJournalReplayCommand positive",
		_dispatcher.dispatch(state, UnlockJournalReplayCommand.new(&"evt.hkr.empty_cushion")),
		failures
	)
	_expect_failure(
		"UnlockJournalReplayCommand duplicate",
		_dispatcher.dispatch(state, UnlockJournalReplayCommand.new(&"evt.hkr.empty_cushion")),
		failures
	)
	_expect_failure(
		"UnlockJournalReplayCommand invalid",
		_dispatcher.dispatch(state, UnlockJournalReplayCommand.new(&"journal.not_an_event")),
		failures
	)
	if state.journal.replay_event_ids != [&"evt.hkr.empty_cushion"]:
		failures.append("Journal replay command did not preserve its stable event index")


func _test_items(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_success(
		"AddInventoryItemCommand positive",
		_dispatcher.dispatch(state, AddInventoryItemCommand.new(&"item.fixture.leaf", 2)),
		failures
	)
	_expect_failure(
		"AddInventoryItemCommand negative",
		_dispatcher.dispatch(state, AddInventoryItemCommand.new(&"item.fixture.leaf", 0)),
		failures
	)
	_expect_success(
		"RemoveInventoryItemCommand positive",
		_dispatcher.dispatch(state, RemoveInventoryItemCommand.new(&"item.fixture.leaf", 1)),
		failures
	)
	_expect_failure(
		"RemoveInventoryItemCommand negative",
		_dispatcher.dispatch(state, RemoveInventoryItemCommand.new(&"item.fixture.leaf", 4)),
		failures
	)
	if state.inventory.items[&"item.fixture.leaf"].count != 1:
		failures.append("rejected item mutation changed the accepted count")


func _test_keepsakes(failures: Array[String]) -> void:
	var state := _fresh()
	var keepsake := _keepsake_fixture()
	_expect_success("GrantKeepsakeCommand positive", _dispatcher.dispatch(state, GrantKeepsakeCommand.new(keepsake)), failures)
	_expect_failure("GrantKeepsakeCommand negative", _dispatcher.dispatch(state, GrantKeepsakeCommand.new(keepsake)), failures)
	_expect_success(
		"EquipKeepsakeCommand positive",
		_dispatcher.dispatch(state, EquipKeepsakeCommand.new(keepsake.keepsake_id, true)),
		failures
	)
	_expect_failure(
		"EquipKeepsakeCommand negative",
		_dispatcher.dispatch(state, EquipKeepsakeCommand.new(&"item.keepsake.not_owned", true)),
		failures
	)
	if state.inventory.equipped_keepsake_ids != [keepsake.keepsake_id]:
		failures.append("Keepsake equipment changed after rejected command")


func _test_tea_blends(failures: Array[String]) -> void:
	var state := _fresh()
	var blend := TeaBlendState.new(&"tea.roasted")
	_expect_success("UnlockTeaBlendCommand positive", _dispatcher.dispatch(state, UnlockTeaBlendCommand.new(blend)), failures)
	_expect_failure("UnlockTeaBlendCommand negative", _dispatcher.dispatch(state, UnlockTeaBlendCommand.new(blend)), failures)
	_expect_success("SelectTeaBlendCommand positive", _dispatcher.dispatch(state, SelectTeaBlendCommand.new(blend.blend_id)), failures)
	_expect_failure(
		"SelectTeaBlendCommand negative",
		_dispatcher.dispatch(state, SelectTeaBlendCommand.new(&"tea.not_unlocked")),
		failures
	)
	if state.inventory.selected_tea_blend_id != blend.blend_id or state.inventory.tea_blends[blend.blend_id].times_prepared != 1:
		failures.append("Tea Blend selection did not persist its daily preparation")


func _test_comfort_profile(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_success(
		"SetComfortProfileCommand positive",
		_dispatcher.dispatch(state, SetComfortProfileCommand.new(&"accessibility.low_motion")),
		failures
	)
	_expect_failure(
		"SetComfortProfileCommand negative",
		_dispatcher.dispatch(state, SetComfortProfileCommand.new(&"accessibility.unbounded")),
		failures
	)
	if state.protagonist.comfort_profile_id != &"accessibility.low_motion":
		failures.append("rejected comfort profile replaced the accepted preset")


func _test_time_location_route(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_success("AdvanceTimeCommand positive", _dispatcher.dispatch(state, AdvanceTimeCommand.new(1)), failures)
	_expect_failure("AdvanceTimeCommand negative", _dispatcher.dispatch(state, AdvanceTimeCommand.new(0)), failures)
	if state.time_slot != &"day":
		failures.append("time command did not preserve the accepted slot")
	_expect_success(
		"SetLocationCommand positive",
		_dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine")),
		failures
	)
	_expect_failure(
		"SetLocationCommand negative",
		_dispatcher.dispatch(state, SetLocationCommand.new(&"loc.fixture.missing")),
		failures
	)
	if state.current_location != &"loc.hakurei_shrine" or state.regions[&"loc.hakurei_shrine"].visit_count != 1:
		failures.append("location command did not retain accepted visit metadata")
	_expect_success(
		"SetRouteIntentCommand positive",
		_dispatcher.dispatch(state, SetRouteIntentCommand.new(&"char.reimu_hakurei", &"friendship")),
		failures
	)
	_expect_failure(
		"SetRouteIntentCommand negative",
		_dispatcher.dispatch(state, SetRouteIntentCommand.new(&"char.reimu_hakurei", &"ownership")),
		failures
	)
	if state.characters[&"char.reimu_hakurei"].route_intent != &"friendship":
		failures.append("rejected route intent changed the accepted player choice")


func _test_event_cursor(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_success(
		"SetEventPositionCommand positive",
		_dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.hkr.empty_cushion", &"n001")),
		failures
	)
	_expect_failure(
		"SetEventPositionCommand negative",
		_dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.hkr.empty_cushion", &"")),
		failures
	)
	if state.active_event_node_id != &"n001":
		failures.append("rejected event cursor command changed the accepted position")
	_expect_success(
		"CompleteEventCommand positive",
		_dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.hkr.empty_cushion", &"complete")),
		failures
	)
	_expect_failure(
		"CompleteEventCommand negative",
		_dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.hkr.empty_cushion", &"complete")),
		failures
	)
	if state.active_event_id != &"" or state.completed_event_ids != [&"evt.hkr.empty_cushion"]:
		failures.append("event completion did not atomically clear and record the cursor")


func _test_unsupported_and_invariant_rejection(failures: Array[String]) -> void:
	var state := _fresh()
	_expect_failure("unsupported GameCommand", _dispatcher.dispatch(state, GameCommand.new(&"state.fixture_unknown")), failures)
	var empty_id_flag := FlagState.from_value(&"flag.fixture.empty_id", &"")
	_expect_failure("post-command invariant", _dispatcher.dispatch(state, SetFlagCommand.new(empty_id_flag)), failures)
	if state.flags.has(empty_id_flag.flag_id):
		failures.append("post-command invariant failure leaked candidate state")


func _test_transactions(failures: Array[String]) -> void:
	var success_state := _fresh()
	var success := GameStateTransaction.new(success_state)
	_expect_success(
		"transaction first effect",
		success.apply(SetFlagCommand.new(FlagState.from_value(&"flag.fixture.transaction", true))),
		failures
	)
	_expect_success(
		"transaction second effect",
		success.apply(AddInventoryItemCommand.new(&"item.fixture.transaction", 1)),
		failures
	)
	_expect_success("transaction commit", success.commit(), failures)
	if not success_state.flags.has(&"flag.fixture.transaction") or not success_state.inventory.items.has(&"item.fixture.transaction"):
		failures.append("successful multi-effect transaction did not commit every effect")
	var failure_state := _fresh()
	var failed := GameStateTransaction.new(failure_state)
	_expect_success(
		"failed transaction opening effect",
		failed.apply(SetFlagCommand.new(FlagState.from_value(&"flag.fixture.must_rollback", true))),
		failures
	)
	_expect_failure(
		"failed transaction invalid effect",
		failed.apply(RemoveInventoryItemCommand.new(&"item.fixture.missing", 1)),
		failures
	)
	_expect_failure("failed transaction commit", failed.commit(), failures)
	if failure_state.flags.has(&"flag.fixture.must_rollback"):
		failures.append("failed multi-effect transaction partially mutated the target")
	_expect_failure(
		"closed transaction command",
		failed.apply(SetFlagCommand.new(FlagState.from_value(&"flag.fixture.after_close", true))),
		failures
	)
	var rolled_back_state := _fresh()
	var rolled_back := GameStateTransaction.new(rolled_back_state)
	rolled_back.apply(SetFlagCommand.new(FlagState.from_value(&"flag.fixture.discard", true)))
	if not rolled_back.rollback().is_success() or rolled_back_state.flags.has(&"flag.fixture.discard"):
		failures.append("explicit transaction rollback changed the target")


func _test_player_safe_relationship_view(failures: Array[String]) -> void:
	var character := _fresh().characters[&"char.reimu_hakurei"]
	var view := RelationshipViewBuilder.build(character)
	if view.summary_key != &"resonance.summary.still_measuring":
		failures.append("initial relationship view did not use a qualitative summary")
	for property: Dictionary in view.get_property_list():
		if (int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and int(property.type) in [TYPE_INT, TYPE_FLOAT]:
			failures.append("player relationship view exposed a numeric property: %s" % property.name)
	for facet: RelationshipBandView in view.facets:
		for property: Dictionary in facet.get_property_list():
			if (int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and int(property.type) in [TYPE_INT, TYPE_FLOAT]:
				failures.append("player facet view exposed a numeric property: %s" % property.name)
	RelationshipFacetRules.set_value(character.relationship, &"ease", 3)
	if RelationshipViewBuilder.build(character).summary_key != &"resonance.summary.allows_silence":
		failures.append("relationship view did not update its qualitative summary")


func _create_base_state() -> GameState:
	var repository := ContentRepository.new()
	if not repository.load_sources().is_success():
		return null
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in repository.all_characters():
		character_ids.append(character.id)
	var region_ids: Array[StringName] = []
	for location: LocationRecord in repository.all_locations():
		region_ids.append(location.id)
	return GameStateFactory.create_new(&"p01", character_ids, region_ids, 123)


func _fresh() -> GameState:
	return _base_state.deep_copy()


func _rumor_fixture() -> RumorState:
	var rumor := RumorState.new(&"rumor.fixture.missing_minute")
	rumor.claim_key = &"rumor.fixture.missing_minute.claim"
	rumor.source_character_id = &"char.reimu_hakurei"
	rumor.reliability_milli = 550
	rumor.privacy = &"public"
	return rumor


func _journal_fixture() -> JournalEntryState:
	var entry := JournalEntryState.new(&"journal.fixture.empty_cushion")
	entry.title_key = &"evt.hkr.empty_cushion.title"
	entry.source_event_id = &"evt.hkr.empty_cushion"
	entry.observation_keys = [&"dlg.hkr.empty_cushion.reimu.001"]
	return entry


func _keepsake_fixture() -> KeepsakeState:
	var keepsake := KeepsakeState.new(&"item.keepsake.unpaired_cup")
	keepsake.source_event_id = &"evt.hkr.empty_cushion"
	keepsake.owner_character_id = &"char.reimu_hakurei"
	keepsake.dialogue_tags = [&"shrine.second_cup"]
	return keepsake


func _expect_success(label: String, result: CommandResult, failures: Array[String]) -> void:
	if result == null or not result.is_success() or not result.did_change:
		failures.append("%s expected success, got %s" % [label, result.message if result != null else "null"])


func _expect_failure(label: String, result: CommandResult, failures: Array[String]) -> void:
	if result == null or result.is_success() or result.did_change:
		failures.append("%s expected a non-mutating failure" % label)
