extends SceneTree
## Exercises the real M04 fixture through locale switching, choice, mode, and completion.

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://tests/ui/fixtures/DialogueEventFixture.tscn") as PackedScene
	if packed == null:
		_finish(["dialogue event fixture could not be loaded"])
		return
	var fixture := packed.instantiate() as DialogueEventFixture
	get_root().add_child(fixture)
	await process_frame
	fixture.set_instant_text_for_test(false)
	fixture.configure_fixture(&"A", &"en")
	await process_frame

	_expect(fixture.phase() == &"line", "fixture did not open on a dialogue line")
	_expect(fixture.current_text().contains("second cup"), "reviewed English opening line was not presented")
	fixture.tick_dialogue_for_test(0.12)
	var english_progress := fixture.revealed_count()
	_expect(english_progress > 0 and fixture.current_visible_text() != fixture.current_text(), "opening line did not reveal incrementally")
	fixture.switch_locale(&"ja")
	_expect(fixture.current_text().contains("湯呑み"), "mid-line locale switch did not resolve Japanese text")
	_expect(fixture.revealed_count() > 0, "mid-line locale switch discarded reveal progress")

	fixture.handle_semantic_action(GameInput.CONFIRM)
	_expect(fixture.phase() == &"line", "first confirm skipped a partially revealed line")
	fixture.handle_semantic_action(GameInput.CONFIRM)
	_expect(fixture.phase() == &"choice", "accepted opening line did not reach the four-tone choice")
	_expect(fixture.focused_tone() == &"direct", "four-tone choice did not start on Direct")
	fixture.handle_semantic_action(GameInput.MOVE_DOWN)
	_expect(fixture.focused_tone() == &"playful", "semantic choice focus did not move to Playful")
	fixture.switch_locale(&"en")
	fixture.switch_locale(&"ja")
	_expect(fixture.focused_tone() == &"playful", "choice focus changed during repeated locale switches")

	fixture.handle_semantic_action(GameInput.CONFIRM)
	_expect(fixture.phase() == &"line", "Playful choice did not present its authored response line")
	var after_choice := fixture.state_snapshot()
	var relationship := after_choice.characters[&"char.reimu_hakurei"].relationship
	_expect(relationship.spark == 1 and relationship.strain == 1, "Playful relationship transaction did not apply exactly once")
	_expect(relationship.trust == 0 and relationship.ease == 0 and relationship.respect == 0, "Playful choice leaked another tone's effects")
	_accept_line(fixture)
	_expect(fixture.phase() == &"mode", "Playful response did not suspend at Tea Temperature")

	fixture.handle_semantic_action(GameInput.CONFIRM)
	_expect(fixture.phase() == &"line", "mock Tea Clear did not resume the authored result line")
	var after_mode := fixture.state_snapshot().characters[&"char.reimu_hakurei"].relationship
	_expect(after_mode.spark == 1 and after_mode.strain == 1, "mode resume reapplied the tone transaction")
	_expect(fixture.current_text().contains("湯呑み"), "Clear result did not remain in the selected Japanese locale")
	_accept_line(fixture)
	_expect(fixture.phase() == &"line", "Tea result did not continue to the boundary-stain setup")
	_accept_line(fixture)
	_expect(fixture.phase() == &"mode", "boundary-stain setup did not suspend at the danmaku handoff")
	fixture.handle_semantic_action(GameInput.CONFIRM)
	_expect(fixture.phase() == &"line", "mock Assist Clear did not resume its authored danmaku line")
	_accept_line(fixture)
	_expect(fixture.phase() == &"line", "danmaku response did not continue to Marisa's duel introduction")
	_accept_line(fixture)
	_expect(fixture.phase() == &"mode", "Marisa's introduction did not suspend at the duel handoff")
	fixture.handle_semantic_action(GameInput.CONFIRM)
	_expect(fixture.phase() == &"line", "mock duel Loss did not resume its authored response")
	for _line: int in range(5):
		_accept_line(fixture)
	_expect(fixture.phase() == &"end", "accepted vertical-slice afterbeat did not complete the event")

	var completed := fixture.state_snapshot()
	_expect(&"evt.hkr.empty_cushion" in completed.completed_event_ids, "event completion was not recorded")
	_expect(completed.active_event_id == &"", "completed event retained an active cursor")
	_expect(completed.inventory.keepsakes.has(&"item.keepsake.unpaired_cup"), "completion did not grant the unpaired cup Keepsake")
	_expect(completed.journal.entries.has(&"journal.hkr.empty_cushion"), "completion did not grant the Journal observation")
	_expect(fixture.backlog_count() == 11, "backlog did not contain all eleven accepted branch dialogue beats")
	var backlog := fixture.backlog_lines()
	_expect(backlog.size() == 22, "backlog did not retain text and nonverbal cues for the full branch")
	_expect(
		_contains(backlog, "cue.reimu.look_at_cup")
		and _contains(backlog, "cue.reimu_take_cup")
		and _contains(backlog, "cue.marisa.broom_arrival")
		and _contains(backlog, "cue.reimu.look_away"),
		"backlog omitted authored nonverbal evidence from a vertical-slice phase"
	)
	_expect(not _contains(backlog, "spark=") and not _contains(backlog, "strain="), "backlog exposed hidden state deltas")

	var checkpoints := fixture.checkpoint_reasons()
	_expect(&"event_checkpoint" in checkpoints, "dialogue boundary did not request a checkpoint")
	_expect(&"before_mode" in checkpoints, "mode handoff did not request a checkpoint")
	_expect(&"event_completion" in checkpoints, "event completion did not request a checkpoint")
	var debug := fixture.debug_snapshot()
	_expect(debug.event_id == &"evt.hkr.empty_cushion" and debug.node_id == &"n010", "debug snapshot lost the final event/node identity")
	_expect(fixture.action_contract().has("confirm") and fixture.action_contract().has("page_left"), "fixture omitted dialogue input parity actions")

	fixture.queue_free()
	_finish(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _accept_line(fixture: DialogueEventFixture) -> void:
	fixture.handle_semantic_action(GameInput.CONFIRM)
	fixture.handle_semantic_action(GameInput.CONFIRM)


func _contains(lines: Array[String], needle: String) -> bool:
	for line: String in lines:
		if line.contains(needle):
			return true
	return false


func _finish(failures: Array[String]) -> void:
	print("M04 dialogue integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
