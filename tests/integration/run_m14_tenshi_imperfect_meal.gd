extends SceneTree
## Proves Tenshi can enjoy ordinary ground-level food without turning criticism into contempt.

const EVENT_ID: StringName = &"evt.tsh.imperfect_meal"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Tenshi Imperfect Meal content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_expect(graph.location_id == &"loc.human_village" and graph.spot_id == &"loc.human_village.market_side_step", "the ground-level meal remained staged in Heaven")
	_expect(_content.event(EVENT_ID).location_id == &"loc.human_village", "the meal index and playable event disagree about its ground location")
	for tone: StringName in [&"direct", &"playful", &"patient", &"defiant"]: _run(graph, tone)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName) -> void:
	var state := _state(StringName("p227_%s" % tone))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the meal response" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"ordinary_meal_enjoyed_without_contempt_or_performance", "%s did not complete the quiet meal" % tone)
	_expect(state.characters[TENSHI].route_stage == 3 and state.journal.entries.has(&"journal.tsh.imperfect_meal"), "%s omitted meal route evidence" % tone)
	_expect(state.flags.has(&"flag.route.tenshi.meal.imperfection_enjoyed_without_spectacle") and state.flags.has(&"flag.route.tenshi.meal.ground_level_meal_chosen"), "%s treated ground level or imperfection as a punishment" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2271)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.human_village"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.tsh.keystone_construction", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.tsh.keystone_construction", &"complete"))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Imperfect Meal integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
