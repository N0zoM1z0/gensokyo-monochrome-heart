extends SceneTree
## Proves Tenshi's opening tremor distinguishes repairable public damage from rejection of Tenshi herself.

const EVENT_ID: StringName = &"evt.tsh.entrance_tremor"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Tenshi Entrance Tremor content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_expect(_content.localized_string(&"choice.tsh.entrance_tremor.defiant").japanese.contains("通りがかりの人々を次の揺れの観客にする"), "Japanese boundary text no longer says bystanders cannot be made into the next tremor's audience")
	_run(graph, &"direct", &"flag.route.tenshi.entrance.damage_named_without_rejecting_person", 0)
	_run(graph, &"playful", &"flag.route.tenshi.entrance.announcement_not_excuse", 1)
	_run(graph, &"patient", &"flag.route.tenshi.entrance.access_impact_heard", 2)
	_run(graph, &"defiant", &"flag.route.tenshi.entrance.unconsenting_audience_rejected", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, response_flag: StringName, index: int) -> void:
	var state := _state(StringName("p225%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.tsh.entrance_tremor.response" and result.choice.options.size() == 4, "%s did not reach the entrance response" % tone)
	result = interpreter.choose_tone(tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"entrance_damage_named_repaired_without_rejecting_tenshi", "%s did not complete the repair terms" % tone)
	_expect(state.characters[TENSHI].route_stage == 1 and state.journal.entries.has(&"journal.tsh.entrance_tremor"), "%s omitted Tenshi route evidence" % tone)
	_expect(state.flags.has(response_flag), "%s response lost its distinct boundary evidence" % tone)
	_expect(state.flags.has(&"flag.route.tenshi.entrance.damage_repaired_before_attention") and state.flags.has(&"flag.route.tenshi.entrance.repair_terms_accepted"), "%s let Tenshi receive attention before the route was repaired" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2251)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.heaven"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Entrance Tremor integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
