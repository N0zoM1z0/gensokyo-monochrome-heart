extends SceneTree
## Proves five headline chapters, route-independent reveals, save continuity, and finale evidence.

const ARCHIVE_MODE := preload("res://src/presentation/danmaku/ArchivePrototypeMode.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var friendship := _run_headline_route(&"p136", &"friendship")
	var romance := _run_headline_route(&"p137", &"romance")
	_expect(friendship != null and romance != null, "headline route fixtures could not be created")
	if friendship != null and romance != null:
		_expect(friendship.chapter_id == &"chapter.6" and romance.chapter_id == &"chapter.6", "five chapters did not open the final campaign chapter")
		_expect(_backbone_signature(friendship) == _backbone_signature(romance), "shared chapter reveals changed with route intent")
		_expect(ArchivePatternComposer.strategies_for_state(friendship)[0] == &"strategy.photo_frame", "five-region strategy evidence did not rank for the Archive")

		var kernel := root.get_node("GameKernel")
		kernel.clear_state()
		var accepted: CommandResult = kernel.call("replace_state", friendship, &"test.m13_campaign_backbone")
		_expect(accepted.is_success(), "completed backbone could not enter the active kernel")
		var archive := ARCHIVE_MODE.instantiate() as ArchivePrototypeMode
		root.add_child(archive)
		await process_frame
		_expect(archive.indexed_strategy_tags()[0] == &"strategy.photo_frame", "live final Archive did not consume cross-chapter strategy evidence")
		archive.queue_free()
		await process_frame

	print("M13 campaign backbone integration: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)


func _run_headline_route(profile_id: StringName, route_intent: StringName) -> GameState:
	var state := _state(profile_id)
	state.chapter_id = &"chapter.1"
	for character_id: StringName in _headline_leads():
		state.characters[character_id].route_intent = route_intent
	var dispatcher := GameCommandDispatcher.new()
	for definition: CampaignChapterDefinition in CampaignChapterCatalog.build():
		for event_id: StringName in definition.required_event_ids:
			var positioned := dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_backbone_proof"))
			var completed := dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"clear"))
			var recorded := dispatcher.dispatch(state, RecordStrategyUseCommand.new(event_id, _strategy_for(event_id)))
			_expect(positioned.is_success() and completed.is_success() and recorded.is_success(), "could not commit %s evidence" % event_id)
		var advanced := CampaignBackboneService.new().advance_ready_chapter(state)
		_expect(advanced.is_success() and advanced.did_change, "%s did not advance atomically" % definition.chapter_id)
		if definition.chapter_id == &"chapter.3":
			var decoded := GameStateCodec.new().decode(GameStateCodec.new().encode(state))
			_expect(decoded.is_success(), "chapter-three save boundary could not decode")
			if decoded.is_success():
				state = decoded.state
	return state


func _strategy_for(event_id: StringName) -> StringName:
	match event_id:
		&"evt.hkr.empty_cushion":
			return &"strategy.neutral_guard"
		&"evt.sdm.late_by_three_minutes":
			return &"strategy.margin_corridor"
		&"evt.ein.four_dawns":
			return &"strategy.focus_lane"
		_:
			return &"strategy.photo_frame"


func _backbone_signature(state: GameState) -> String:
	var parts: Array[String] = [String(state.chapter_id)]
	for definition: CampaignChapterDefinition in CampaignChapterCatalog.build():
		var flag := state.flags.get(definition.reveal_flag_id) as FlagState
		parts.append("%s=%s" % [definition.reveal_flag_id, flag.stable_id_value if flag != null else &""])
		parts.append(String(definition.journal_entry_id) if state.journal.entries.has(definition.journal_entry_id) else "missing")
		for region_id: StringName in definition.next_region_conditions:
			parts.append("%s=%s" % [region_id, state.regions[region_id].condition_id])
	return "|".join(parts)


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
	return GameStateFactory.create_new(profile_id, characters, regions, 1317)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
