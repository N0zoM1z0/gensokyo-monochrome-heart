extends SceneTree
## Proves every authored audience response preserves a voluntary entrance.

const EVENT_ID: StringName = &"evt.rml.the_audience"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Audience content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(StringName("p193%d" % index), characters, locations, 1931)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the audience responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"foretold_entrance_performed_by_choice", "%s did not finish the voluntary audience" % tone)
	_expect(state.characters[REMILIA].route_stage == 1 and state.journal.entries.has(&"journal.rml.the_audience"), "%s did not preserve the audience evidence" % tone)
	_expect(state.flags.has(&"flag.route.remilia.audience.choice_preserved"), "%s allowed the performance to erase choice" % tone)
	if tone == &"direct": _expect(state.flags.has(&"flag.route.remilia.audience.arrival_voluntary"), "direct did not name the voluntary arrival")
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.remilia.audience.fate_claim_challenged"), "defiant did not challenge the advance claim")


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia The Audience integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
