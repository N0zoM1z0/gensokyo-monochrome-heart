extends SceneTree
## Proves Tenshi rejects the frictionless Archive before the player chooses a response.

const EVENT_ID: StringName = &"evt.tsh.heaven_without_friction"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Tenshi Heaven Without Friction content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(graph, EventGraphValidator.TONES[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p230%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(state.flags.has(&"flag.route.tenshi.archive.frictionless_offer_rejected_by_tenshi"), "%s reached player choice before Tenshi rejected the Archive" % tone)
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the post-rejection response" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"frictionless_archive_rejected_for_surprise_refusal_and_otherness", "%s did not complete frictionless refusal" % tone)
	_expect(state.characters[TENSHI].route_stage == 6 and state.flags.has(&"flag.route.tenshi.archive.surprise_not_calibrated") and state.flags.has(&"flag.route.tenshi.archive.refusal_remains_possible") and state.flags.has(&"flag.route.tenshi.archive.irregular_future_chosen"), "%s omitted final Archive evidence" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2301)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.heaven"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.tsh.repair_she_finishes", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.tsh.repair_she_finishes", &"complete"))
	dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.route.tenshi.repair.boundary_strain_repaired_through_practice", true)))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Heaven Without Friction integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
