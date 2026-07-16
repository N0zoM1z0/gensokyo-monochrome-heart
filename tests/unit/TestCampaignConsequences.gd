class_name TestCampaignConsequences
extends RefCounted
## Persistent strategy evidence and atomic cross-region rumor propagation.


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_strategy_ledger(failures)
	_test_rumor_propagation(failures)
	return failures


func _test_strategy_ledger(failures: Array[String]) -> void:
	var state := _state(&"p131")
	var dispatcher := GameCommandDispatcher.new()
	_expect_success(dispatcher.dispatch(
		state,
		RecordStrategyUseCommand.new(&"evt.mtn.tomorrows_headline", &"strategy.photo_frame")
	), "first strategy use was rejected", failures)
	var opening := GameStateCodec.new().canonical_state(state)
	var duplicate := dispatcher.dispatch(
		state,
		RecordStrategyUseCommand.new(&"evt.mtn.tomorrows_headline", &"strategy.photo_frame")
	)
	if not duplicate.is_success() or duplicate.did_change or GameStateCodec.new().canonical_state(state) != opening:
		failures.append("duplicate event strategy use was not an idempotent no-op")
	_expect_success(dispatcher.dispatch(
		state,
		RecordStrategyUseCommand.new(&"evt.fixture.second", &"strategy.photo_frame")
	), "second event strategy use was rejected", failures)
	_expect_success(dispatcher.dispatch(
		state,
		RecordStrategyUseCommand.new(&"evt.fixture.third", &"strategy.focus_lane")
	), "alternate strategy use was rejected", failures)
	if RecordedStrategyLedger.tags_for_event(state, &"evt.mtn.tomorrows_headline") != [&"strategy.photo_frame"]:
		failures.append("event strategy index did not recover the photo-frame tag")
	if RecordedStrategyLedger.ranked_tags(state) != [&"strategy.photo_frame", &"strategy.focus_lane"]:
		failures.append("Archive strategy ledger did not rank by count with a stable tie break")
	var count_flag := state.flags.get(&"flag.archive.strategy.photo_frame") as FlagState
	if count_flag == null or count_flag.kind != FlagState.Kind.INTEGER or count_flag.integer_value != 2:
		failures.append("campaign strategy count did not preserve two event uses")
	var decoded := GameStateCodec.new().decode(GameStateCodec.new().encode(state))
	if not decoded.is_success() or RecordedStrategyLedger.ranked_tags(decoded.state) != [&"strategy.photo_frame", &"strategy.focus_lane"]:
		failures.append("integer strategy counts did not survive the JSON codec boundary: %s" % decoded.errors)


func _test_rumor_propagation(failures: Array[String]) -> void:
	var state := _state(&"p132")
	var rumor := RumorState.new(&"rumor.mtn.tomorrows_headline")
	rumor.claim_key = &"rumor.mtn.tomorrows_headline.withheld_correction"
	rumor.source_character_id = &"char.aya_shameimaru"
	rumor.reliability_milli = 820
	rumor.privacy = &"shared"
	_expect_success(
		GameCommandDispatcher.new().dispatch(state, AddRumorCommand.new(rumor)),
		"campaign rumor fixture was rejected",
		failures
	)
	var rule := RumorPropagationRule.new(
		rumor.rumor_id,
		rumor.claim_key,
		&"rumor.mtn.tomorrows_headline.reporter_prevented_accident",
		-210,
		&"public"
	)
	rule.region_conditions = {
		&"loc.hakurei_shrine": &"region.rumor.future_headline_arrived",
		&"loc.scarlet_devil_mansion": &"region.rumor.future_headline_arrived",
	}
	var rules: Array[RumorPropagationRule] = [rule]
	_expect_success(
		RumorPropagationService.new().propagate(state, rules),
		"eligible campaign rumor did not propagate",
		failures
	)
	var propagated := state.rumors[rumor.rumor_id]
	if (
		propagated.claim_key != rule.next_claim_key
		or propagated.mutation_count != 1
		or propagated.reliability_milli != 610
		or propagated.privacy != &"public"
		or propagated.confidence_label() != &"reported"
	):
		failures.append("propagated rumor did not expose the authored public retelling")
	for region_id: StringName in rule.region_conditions:
		if state.regions[region_id].condition_id != rule.region_conditions[region_id]:
			failures.append("propagated rumor did not change %s" % region_id)
	var once := GameStateCodec.new().canonical_state(state)
	var repeated := RumorPropagationService.new().propagate(state, rules)
	if not repeated.is_success() or repeated.did_change or GameStateCodec.new().canonical_state(state) != once:
		failures.append("repeated rumor propagation was not an idempotent no-op")

	var rollback_state := _state(&"p133")
	GameCommandDispatcher.new().dispatch(rollback_state, AddRumorCommand.new(rumor))
	var broken := RumorPropagationRule.new(
		rumor.rumor_id,
		rumor.claim_key,
		rule.next_claim_key,
		-210,
		&"public"
	)
	broken.region_conditions = {&"loc.missing": &"region.rumor.future_headline_arrived"}
	var broken_rules: Array[RumorPropagationRule] = [broken]
	var rejected := RumorPropagationService.new().propagate(rollback_state, broken_rules)
	if rejected.is_success() or rollback_state.rumors[rumor.rumor_id].claim_key != rumor.claim_key:
		failures.append("invalid cross-region target did not roll back the rumor rewrite")


func _state(profile_id: StringName) -> GameState:
	var content := ContentRepository.new()
	content.load_sources()
	var characters: Array[StringName] = []
	for record: CharacterRecord in content.all_characters():
		characters.append(record.id)
	var regions: Array[StringName] = []
	for record: LocationRecord in content.all_locations():
		regions.append(record.id)
	return GameStateFactory.create_new(profile_id, characters, regions, 1313)


func _expect_success(result: CommandResult, message: String, failures: Array[String]) -> void:
	if result == null or not result.is_success() or not result.did_change:
		failures.append("%s: %s" % [message, result.message if result != null else "null"])
