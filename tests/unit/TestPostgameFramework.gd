class_name TestPostgameFramework
extends RefCounted
## M15 contracts for seasonal continuity, Dream Theatre, and Ensemble Accord.


func run() -> Array[String]:
	var failures: Array[String] = []
	var repository := ContentRepository.new()
	var report := repository.load_sources()
	if not report.is_success():
		failures.append("postgame framework failed typed loading: %s" % report.human_readable())
		return failures
	_expect_catalog(repository, failures)
	_expect_accord(repository, failures)
	return failures


func _expect_catalog(repository: ContentRepository, failures: Array[String]) -> void:
	var framework := repository.postgame_framework
	if framework == null or framework.id != &"postgame.framework.v1":
		failures.append("typed postgame framework is missing")
		return
	var dream := framework.dream_theatre
	if dream == null or dream.continuity_scope != &"non_main_continuity" or not dream.postgame_only or dream.route_progression:
		failures.append("Dream Theatre is not explicitly isolated from main continuity and route progression")
	elif not dream.label(&"en").contains("NON-MAIN-CONTINUITY") or not dream.label(&"ja").contains("本編とは異なる世界線"):
		failures.append("Dream Theatre omitted its bilingual continuity label")
	if framework.seasonal_events.size() != 8:
		failures.append("seasonal framework expected 8 reviewed hooks")
	if repository.seasonal_events_by_season(&"summer").size() != 2:
		failures.append("summer scheduling query expected Tanabata and festival hooks")
	if repository.seasonal_events_by_season(&"autumn").size() != 3:
		failures.append("autumn scheduling query expected three hooks")
	for event: SeasonalEventRecord in framework.seasonal_events:
		if event.relationship_progression != &"none":
			failures.append("seasonal hook %s makes an unsupported route promise" % event.id)
	var dream_event := framework.seasonal_event(&"season.reitaisai_dream")
	if dream_event == null or dream_event.continuity_scope != &"dream_theatre":
		failures.append("high-fanon seasonal seed is not confined to Dream Theatre")


func _expect_accord(repository: ContentRepository, failures: Array[String]) -> void:
	var state := GameStateFactory.create_new(&"p1501", _character_ids(repository), _location_ids(repository), 1501)
	var deep := repository.characters_by_route_depth(&"deep")
	for index: int in 6:
		var character_state: CharacterState = state.characters[deep[index].id]
		character_state.route_stage = 7
		character_state.route_intent = &"friendship" if index < 3 else &"postponed" if index == 3 else &"romance"
	state.characters[&"char.alice_margatroid"].route_stage = 7
	state.characters[&"char.alice_margatroid"].route_intent = &"romance"
	state.flags[&"flag.ensemble.cross_faction_repairs"] = FlagState.from_value(&"flag.ensemble.cross_faction_repairs", 3)
	state.flags[&"flag.ensemble.rank_spectacle_refused"] = FlagState.from_value(&"flag.ensemble.rank_spectacle_refused", true)
	state.flags[&"flag.ensemble.intent_audit_complete"] = FlagState.from_value(&"flag.ensemble.intent_audit_complete", true)
	state.flags[&"flag.ensemble.boundaries_established"] = FlagState.from_value(&"flag.ensemble.boundaries_established", true)
	state.flags[&"flag.ensemble.home_responsibility"] = FlagState.from_value(&"flag.ensemble.home_responsibility", &"loc.hakurei_shrine")
	var service := EnsembleAccordService.new()
	var rules := repository.postgame_framework.ensemble_accord
	var eligible := service.evaluate(state, repository.all_characters(), rules)
	if not eligible.eligible or not eligible.blockers.is_empty():
		failures.append("valid Ensemble Accord state was blocked: %s" % eligible.blockers)
	if eligible.completed_deep_routes != 6:
		failures.append("support route stages were incorrectly counted as deep-route completions")

	state.characters[deep[0].id].relationship.strain = 3
	var strained := service.evaluate(state, repository.all_characters(), rules)
	if strained.eligible or &"severe_strain" not in strained.blockers:
		failures.append("active severe Strain did not block the Accord")
	state.characters[deep[0].id].relationship.strain = 0
	state.flags.erase(&"flag.ensemble.rank_spectacle_refused")
	var ranked := service.evaluate(state, repository.all_characters(), rules)
	if ranked.eligible or &"rank_spectacle" not in ranked.blockers:
		failures.append("ranking spectacle acceptance did not block the Accord")
	if ranked.fallback_ending_id != &"ending.ensemble.community":
		failures.append("failed Accord did not preserve the non-punitive community ending")


func _character_ids(repository: ContentRepository) -> Array[StringName]:
	var result: Array[StringName] = []
	for character: CharacterRecord in repository.all_characters():
		result.append(character.id)
	return result


func _location_ids(repository: ContentRepository) -> Array[StringName]:
	var result: Array[StringName] = []
	for location: LocationRecord in repository.all_locations():
		result.append(location.id)
	return result
