class_name TestCampaignBackbone
extends RefCounted
## M13 chapter definitions, guarded advancement, and route-independent reveal state.


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect_catalog(failures)
	_expect_guarded_command(failures)
	_expect_route_independent_reveals(failures)
	return failures


func _expect_catalog(failures: Array[String]) -> void:
	var catalog := CampaignChapterCatalog.build()
	if catalog.size() != 5:
		failures.append("campaign backbone does not define five headline chapters")
		return
	for index: int in range(catalog.size()):
		var definition := catalog[index]
		var errors := definition.validation_errors()
		if not errors.is_empty():
			failures.append("invalid chapter %d definition: %s" % [index + 1, errors])
		if definition.chapter_id != StringName("chapter.%d" % (index + 1)):
			failures.append("campaign chapter catalog order is unstable")


func _expect_guarded_command(failures: Array[String]) -> void:
	var state := _state(&"p136")
	state.chapter_id = &"chapter.1"
	var rejected := GameCommandDispatcher.new().dispatch(
		state,
		AdvanceChapterCommand.new(&"chapter.1", &"chapter.3")
	)
	if rejected.is_success() or state.chapter_id != &"chapter.1":
		failures.append("chapter command allowed a skipped or partial transition")
	var waiting := CampaignBackboneService.new().advance_ready_chapter(state)
	if not waiting.is_success() or waiting.did_change or state.chapter_id != &"chapter.1":
		failures.append("campaign backbone advanced before its required event")


func _expect_route_independent_reveals(failures: Array[String]) -> void:
	var baseline := ""
	for route_intent: StringName in [&"friendship", &"romance", &"postponed"]:
		var state := _state(StringName("p13%d" % (7 + [&"friendship", &"romance", &"postponed"].find(route_intent))))
		state.chapter_id = &"chapter.1"
		for character_id: StringName in _headline_leads():
			state.characters[character_id].route_intent = route_intent
		for definition: CampaignChapterDefinition in CampaignChapterCatalog.build():
			for event_id: StringName in definition.required_event_ids:
				_complete_event(state, event_id, failures)
			var advanced := CampaignBackboneService.new().advance_ready_chapter(state)
			if not advanced.is_success() or not advanced.did_change:
				failures.append("%s route could not advance %s: %s" % [route_intent, definition.chapter_id, advanced.message])
				break
			if state.chapter_id != definition.next_chapter_id:
				failures.append("%s route did not reach %s" % [route_intent, definition.next_chapter_id])
			var flag := state.flags.get(definition.reveal_flag_id) as FlagState
			if flag == null or flag.kind != FlagState.Kind.STABLE_ID or flag.stable_id_value != definition.reveal_id:
				failures.append("%s route lost the shared reveal for %s" % [route_intent, definition.chapter_id])
			if not state.journal.entries.has(definition.journal_entry_id):
				failures.append("%s route omitted the Journal reveal for %s" % [route_intent, definition.chapter_id])
			for region_id: StringName in definition.next_region_conditions:
				if state.regions[region_id].condition_id != definition.next_region_conditions[region_id]:
					failures.append("%s route did not open cross-region state at %s" % [route_intent, region_id])
		for character_id: StringName in _headline_leads():
			if state.characters[character_id].route_intent != route_intent:
				failures.append("campaign reveal rewrote %s route intent" % character_id)
		var signature := _backbone_signature(state)
		if baseline == "":
			baseline = signature
		elif signature != baseline:
			failures.append("chapter reveals differ by friendship, romance, or postponed intent")
		var decoded := GameStateCodec.new().decode(GameStateCodec.new().encode(state))
		if not decoded.is_success() or _backbone_signature(decoded.state) != signature:
			failures.append("campaign backbone did not survive the save codec for %s" % route_intent)


func _complete_event(state: GameState, event_id: StringName, failures: Array[String]) -> void:
	var dispatcher := GameCommandDispatcher.new()
	var positioned := dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_backbone_proof"))
	var completed := dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"clear"))
	if not positioned.is_success() or not completed.is_success():
		failures.append("could not record required campaign event %s" % event_id)


func _backbone_signature(state: GameState) -> String:
	var reveals: Array[String] = []
	for definition: CampaignChapterDefinition in CampaignChapterCatalog.build():
		var flag := state.flags.get(definition.reveal_flag_id) as FlagState
		reveals.append("%s=%s" % [definition.reveal_flag_id, flag.stable_id_value if flag != null else &""])
		for region_id: StringName in definition.next_region_conditions:
			reveals.append("%s=%s" % [region_id, state.regions[region_id].condition_id])
	var journal_ids: Array[StringName] = []
	journal_ids.assign(state.journal.entries.keys())
	journal_ids.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	var journal_strings: Array[String] = []
	for journal_id: StringName in journal_ids:
		journal_strings.append(String(journal_id))
	return "%s|%s|%s" % [state.chapter_id, ";".join(reveals), ",".join(journal_strings)]


func _headline_leads() -> Array[StringName]:
	return [
		&"char.reimu_hakurei",
		&"char.sakuya_izayoi",
		&"char.aya_shameimaru",
		&"char.kaguya_houraisan",
		&"char.youmu_konpaku",
	]


func _state(profile_id: StringName) -> GameState:
	var content := ContentRepository.new()
	content.load_sources()
	var characters: Array[StringName] = []
	for record: CharacterRecord in content.all_characters():
		characters.append(record.id)
	var regions: Array[StringName] = []
	for record: LocationRecord in content.all_locations():
		regions.append(record.id)
	return GameStateFactory.create_new(profile_id, characters, regions, 1316)
