class_name TestEventInterpreter
extends RefCounted
## M04 graph execution, branches, transactions, resume, replay, predicates, and cycle tests.

const TEST_ROOT := "user://tests/m04_event_interpreter"
const T1 := "2026-07-15T16:00:00Z"

var _content: ContentRepository
var _graph: EventGraphRecord


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(TEST_ROOT)
	_content = ContentRepository.new()
	if not _content.load_sources().is_success():
		return ["could not load event interpreter content"]
	_graph = _content.graph(&"evt.hkr.empty_cushion")
	if _graph == null:
		return ["typed Empty Cushion graph is missing"]
	var graph_errors := EventGraphValidator.new().validate(_graph)
	if not graph_errors.is_empty():
		failures.append("authored Empty Cushion graph failed runtime validation: %s" % "; ".join(graph_errors))
	_expect_predicates_and_choice_resolution(failures)
	var replay_source: GameState
	for tone: StringName in EventGraphValidator.TONES:
		var completed := _expect_full_branch(tone, failures)
		if tone == &"patient":
			replay_source = completed
	_expect_transaction_rollback(failures)
	_expect_invalid_flag_validation(failures)
	_expect_step_limit_and_cycle_rejection(failures)
	_expect_read_only_replay(replay_source, failures)
	_remove_tree(TEST_ROOT)
	return failures


func _expect_predicates_and_choice_resolution(failures: Array[String]) -> void:
	var state := _create_event_state(&"p11")
	var evaluator := EventPredicateEvaluator.new()
	var availability := evaluator.evaluate_all(_graph.availability, state)
	if not evaluator.all_pass(availability):
		failures.append("valid event state did not pass authored availability")
	state.time_slot = &"night"
	if evaluator.all_pass(evaluator.evaluate_all(_graph.availability, state)):
		failures.append("event availability ignored its authored time window")
	state.time_slot = &"day"
	var choice := ChoiceRecord.new(&"choice.fixture.predicates", [])
	for tone: StringName in EventGraphValidator.TONES:
		var option := ChoiceOptionRecord.new(tone, StringName("choice.fixture.%s" % tone), &"n_end")
		choice.options.append(option)
	choice.options[0].visible_if.append(
		AvailabilityPredicateRecord.new(&"flag_true", &"", &"flag.fixture.secret", [])
	)
	choice.options[1].available_if.append(
		AvailabilityPredicateRecord.new(&"flag_true", &"", &"flag.fixture.joke_allowed", [])
	)
	choice.options[1].unavailable_reason_key = &"reason.fixture.promise"
	var resolved := EventChoiceResolver.new().resolve(choice, state)
	if resolved.options.size() != 3 or resolved.option_for_tone(&"direct") != null:
		failures.append("choice resolver did not hide a failed visibility predicate")
	var playful := resolved.option_for_tone(&"playful")
	if playful == null or playful.is_available or playful.unavailable_reason_key != &"reason.fixture.promise":
		failures.append("choice resolver did not preserve a disabled tone and in-world reason")
	var relationship_gate := AvailabilityPredicateRecord.new(
		&"relationship_band_at_least", &"", &"", [],
		&"char.reimu_hakurei", &"trust", &"high"
	)
	if evaluator.evaluate(relationship_gate, state).passed:
		failures.append("relationship predicate treated a low semantic band as high")
	RelationshipFacetRules.set_value(state.characters[&"char.reimu_hakurei"].relationship, &"trust", 3)
	if not evaluator.evaluate(relationship_gate, state).passed:
		failures.append("relationship predicate did not accept the high semantic band")
	var friendship_gate := AvailabilityPredicateRecord.new(
		&"route_intent_is", &"friendship", &"", [], &"char.reimu_hakurei"
	)
	if evaluator.evaluate(friendship_gate, state).passed:
		failures.append("route-intent predicate accepted an undecided route")
	state.characters[&"char.reimu_hakurei"].route_intent = &"friendship"
	if not evaluator.evaluate(friendship_gate, state).passed:
		failures.append("route-intent predicate rejected the matching declared route")


func _expect_full_branch(tone: StringName, failures: Array[String]) -> GameState:
	var state := _create_event_state(StringName("p1%d" % (EventGraphValidator.TONES.find(tone) + 2)))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(_graph, state, _content)
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != &"n003" or result.beat == null:
		failures.append("%s branch did not yield the opening line: %s" % [tone, result.diagnostic])
		return state
	if result.checkpoint_reason != &"event_checkpoint" or _cue_kinds(result.presentation_cues) != [&"music", &"objective"]:
		failures.append("%s opening did not retain automatic cues and a safe dialogue checkpoint" % tone)
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != &"n004" or result.choice == null or result.choice.options.size() != 4:
		failures.append("%s branch did not yield the four-tone choice" % tone)
		return state
	result = interpreter.choose_tone(tone)
	var expected_tone_line: StringName = StringName("n_%s_line" % tone)
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != expected_tone_line or result.beat == null:
		failures.append("%s branch did not reach its authored response line: %s" % [tone, result.diagnostic])
		return state
	_expect_tone_effects(tone, state, failures)
	var once := GameStateCodec.new().canonical_state(state)
	if not interpreter.choose_tone(tone).is_error() or GameStateCodec.new().canonical_state(state) != once:
		failures.append("%s effects could be applied more than once while waiting on its response" % tone)
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_MODE or result.node_id != &"n005":
		failures.append("%s branch did not reach Tea Temperature: %s" % [tone, result.diagnostic])
		return state
	if result.checkpoint_reason != &"before_mode" or result.mode_context == null or result.mode_context.mode_id != &"mini.shrine.tea_temperature" or result.mode_context.deterministic_seed <= 0:
		failures.append("%s branch emitted an invalid Tea Temperature handoff" % tone)
	var result_tag: StringName = [&"excellent", &"clear", &"loss"][EventGraphValidator.TONES.find(tone) % 3]
	var expected_line: StringName = {
		&"excellent": &"n006a",
		&"clear": &"n006b",
		&"loss": &"n006c",
	}[result_tag]
	result = interpreter.resume_mode(ModeResult.new(result_tag))
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != expected_line:
		failures.append("%s branch mapped mode result %s to the wrong line" % [tone, result_tag])
		return state
	if tone == &"patient":
		var repository := SaveRepository.new(TEST_ROOT)
		var saved := repository.save(state, &"manual_01", null, T1)
		var loaded := repository.load(state.profile_id, &"manual_01")
		if not saved.is_success() or not loaded.is_success():
			failures.append("dialogue-boundary save fixture could not round trip")
		else:
			state = loaded.state
			interpreter = EventInterpreter.new()
			result = interpreter.start(_graph, state, _content)
			if result.node_id != expected_line or result.beat == null:
				failures.append("save/load did not resume the exact dialogue boundary")
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != &"n006d":
		failures.append("%s branch omitted the boundary-stain setup line" % tone)
		return state
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_MODE or result.node_id != &"n007" or result.mode_context == null or result.mode_context.mode_type != &"start_danmaku":
		failures.append("%s branch did not reach Boundary Stain" % tone)
		return state
	if _cue_kinds(result.presentation_cues) != [&"music"]:
		failures.append("%s Boundary Stain handoff omitted its authored music transition" % tone)
	var danmaku_tag: StringName = [&"clear", &"assist_clear", &"loss", &"clear"][EventGraphValidator.TONES.find(tone)]
	var expected_danmaku_line: StringName = {
		&"clear": &"n007a",
		&"assist_clear": &"n007b",
		&"loss": &"n007c",
	}[danmaku_tag]
	result = interpreter.resume_mode(ModeResult.new(danmaku_tag))
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != expected_danmaku_line:
		failures.append("%s branch mapped Boundary Stain result %s incorrectly" % [tone, danmaku_tag])
		return state
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != &"n007d" or result.beat == null or result.beat.speaker_id != &"char.marisa_kirisame":
		failures.append("%s branch omitted Marisa's duel introduction" % tone)
		return state
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_MODE or result.node_id != &"n008" or result.mode_context == null or result.mode_context.mode_type != &"start_duel":
		failures.append("%s branch did not reach the compact fighter" % tone)
		return state
	if _cue_kinds(result.presentation_cues) != [&"music"]:
		failures.append("%s fighter handoff omitted its authored music transition" % tone)
	var duel_tag: StringName = &"win" if EventGraphValidator.TONES.find(tone) % 2 == 0 else &"loss"
	var expected_duel_line: StringName = &"n008a" if duel_tag == &"win" else &"n008b"
	result = interpreter.resume_mode(ModeResult.new(duel_tag))
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != expected_duel_line:
		failures.append("%s branch mapped fighter result %s incorrectly" % [tone, duel_tag])
		return state
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != &"n_afterbeat_01" or _cue_kinds(result.presentation_cues) != [&"music"]:
		failures.append("%s branch did not enter the quiet afterbeat with its music transition" % tone)
		return state
	for expected_afterbeat: StringName in [&"n_afterbeat_02", &"n_afterbeat_03", &"n_afterbeat_04"]:
		result = interpreter.advance_line()
		if result.status != EventInterpreterResult.Status.WAIT_INPUT or result.node_id != expected_afterbeat:
			failures.append("%s branch omitted afterbeat %s" % [tone, expected_afterbeat])
			return state
	result = interpreter.advance_line()
	if result.status != EventInterpreterResult.Status.END or result.outcome != &"complete":
		failures.append("%s branch did not complete after the full vertical slice: %s" % [tone, result.diagnostic])
		return state
	if state.active_event_id != &"" or _graph.id not in state.completed_event_ids:
		failures.append("%s branch did not atomically close and record the event" % tone)
	if not state.inventory.keepsakes.has(&"item.keepsake.unpaired_cup"):
		failures.append("%s branch did not grant the authored Keepsake" % tone)
	elif state.inventory.keepsakes[&"item.keepsake.unpaired_cup"].dialogue_tags != [&"shrine.second_cup"]:
		failures.append("%s branch did not infer the keepsake memory tag from authored dialogue" % tone)
	if not state.journal.entries.has(&"journal.hkr.empty_cushion"):
		failures.append("%s branch did not add the authored Journal observation" % tone)
	if &"evt.hkr.empty_cushion" not in state.journal.replay_event_ids:
		failures.append("%s branch did not unlock the event's Journal replay" % tone)
	if not state.flags.has(&"evt.hkr.empty_cushion.complete") or state.flags[&"evt.hkr.empty_cushion.complete"].value() != true:
		failures.append("%s branch did not commit the authored completion flag" % tone)
	return state


func _expect_tone_effects(tone: StringName, state: GameState, failures: Array[String]) -> void:
	var relationship := state.characters[&"char.reimu_hakurei"].relationship
	var expected: Array = {
		&"direct": [0, 0, 1, 0, 0],
		&"playful": [0, 0, 0, 1, 1],
		&"patient": [1, 1, 0, 0, 0],
		&"defiant": [0, 0, 1, 0, 1],
	}[tone]
	var actual := [relationship.trust, relationship.ease, relationship.respect, relationship.spark, relationship.strain]
	if actual != expected:
		failures.append("%s tone committed the wrong transactional relationship effects: %s" % [tone, actual])


func _expect_transaction_rollback(failures: Array[String]) -> void:
	var graph := EventGraphRecord.new(1, &"evt.fixture.rollback", &"event.fixture.title", &"loc.hakurei_shrine", &"", [&"char.reimu_hakurei"], &"n_effect", [])
	var effects := EventNodeRecord.new(&"n_effect", &"effects")
	effects.next_node_id = &"n_end"
	var accepted := EventEffectRecord.new(&"relationship")
	accepted.character_id = &"char.reimu_hakurei"
	accepted.facet = &"trust"
	accepted.delta = 1
	var rejected := EventEffectRecord.new(&"relationship")
	rejected.character_id = &"char.reimu_hakurei"
	rejected.facet = &"affection"
	rejected.delta = 1
	effects.effects = [accepted, rejected]
	var end := EventNodeRecord.new(&"n_end", &"end_event")
	end.outcome = &"complete"
	graph.nodes = [effects, end]
	var state := _create_event_state(&"p20")
	var result := EventInterpreter.new().start(graph, state, _content)
	if not result.is_error():
		failures.append("forced effect failure did not stop the event")
	if state.characters[&"char.reimu_hakurei"].relationship.trust != 0:
		failures.append("forced effect failure leaked an earlier command from its transaction")


func _expect_invalid_flag_validation(failures: Array[String]) -> void:
	var graph := EventGraphRecord.new(1, &"evt.fixture.flag", &"event.fixture.title", &"loc.hakurei_shrine", &"", [], &"n_effect", [])
	var effects := EventNodeRecord.new(&"n_effect", &"effects")
	effects.next_node_id = &"n_end"
	var invalid_flag := EventEffectRecord.new(&"set_flag")
	invalid_flag.key = &"fixture.missing_prefix"
	invalid_flag.boolean_value = true
	effects.effects = [invalid_flag]
	var end := EventNodeRecord.new(&"n_end", &"end_event")
	end.outcome = &"complete"
	graph.nodes = [effects, end]
	if not _contains(EventGraphValidator.new().validate(graph), "invalid flag ID"):
		failures.append("event validation did not reject a runtime-invalid flag ID")


func _expect_step_limit_and_cycle_rejection(failures: Array[String]) -> void:
	var cyclic := EventGraphRecord.new(1, &"evt.fixture.cycle", &"event.fixture.title", &"loc.hakurei_shrine", &"", [], &"n1", [])
	var n1 := EventNodeRecord.new(&"n1", &"music_state")
	n1.music_state_id = &"mus.fixture"
	n1.next_node_id = &"n2"
	var n2 := EventNodeRecord.new(&"n2", &"music_state")
	n2.music_state_id = &"mus.fixture"
	n2.next_node_id = &"n1"
	cyclic.nodes = [n1, n2]
	var cycle_errors := EventGraphValidator.new().validate(cyclic)
	if not _contains(cycle_errors, "unbounded event cycle"):
		failures.append("deliberately cyclic event graph was not rejected")
	var long_graph := EventGraphRecord.new(1, &"evt.fixture.long", &"event.fixture.title", &"loc.hakurei_shrine", &"", [], &"n000", [])
	for index: int in range(65):
		var node := EventNodeRecord.new(StringName("n%03d" % index), &"music_state")
		node.music_state_id = &"mus.fixture"
		node.next_node_id = StringName("n%03d" % (index + 1)) if index < 64 else &"n_end"
		long_graph.nodes.append(node)
	var long_end := EventNodeRecord.new(&"n_end", &"end_event")
	long_end.outcome = &"complete"
	long_graph.nodes.append(long_end)
	var limited := EventInterpreter.new().start(long_graph, _create_event_state(&"p21"), _content)
	if not limited.is_error() or not limited.diagnostic.contains("exceeded 64"):
		failures.append("step-limited interpreter did not stop a long automatic chain")


func _expect_read_only_replay(source: GameState, failures: Array[String]) -> void:
	if source == null:
		failures.append("read-only replay source was not produced")
		return
	var opening := GameStateCodec.new().canonical_state(source)
	var replay := EventInterpreter.new()
	var result := replay.start(_graph, source, _content, true)
	result = replay.advance_line()
	result = replay.choose_tone(&"direct")
	result = replay.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_MODE or not result.mode_context.is_replay:
		failures.append("replay did not reach an explicitly read-only mode handoff")
		return
	result = replay.resume_mode(ModeResult.new(&"clear"))
	result = replay.advance_line()
	result = replay.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_MODE or not result.mode_context.is_replay:
		failures.append("replay did not preserve read-only context for Boundary Stain")
		return
	result = replay.resume_mode(ModeResult.new(&"clear"))
	result = replay.advance_line()
	result = replay.advance_line()
	if result.status != EventInterpreterResult.Status.WAIT_MODE or not result.mode_context.is_replay:
		failures.append("replay did not preserve read-only context for the compact fighter")
		return
	result = replay.resume_mode(ModeResult.new(&"win"))
	for _line: int in range(5):
		result = replay.advance_line()
	if result.status != EventInterpreterResult.Status.END:
		failures.append("read-only replay did not traverse the completed graph")
	if GameStateCodec.new().canonical_state(source) != opening:
		failures.append("read-only replay mutated the main save state")


func _create_event_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	return state


func _cue_kinds(cues: Array[EventPresentationCue]) -> Array[StringName]:
	var result: Array[StringName] = []
	for cue: EventPresentationCue in cues:
		result.append(cue.kind)
	return result


func _contains(values: Array[String], needle: String) -> bool:
	for value: String in values:
		if value.contains(needle):
			return true
	return false


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
