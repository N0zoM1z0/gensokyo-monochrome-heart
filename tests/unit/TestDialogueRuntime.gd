class_name TestDialogueRuntime
extends RefCounted
## M04 localization, grapheme reveal, backlog, auto/instant, tone focus, and safe cue tests.

var _content: ContentRepository


func run() -> Array[String]:
	var failures: Array[String] = []
	_content = ContentRepository.new()
	if not _content.load_sources().is_success():
		return ["could not load dialogue runtime content"]
	_expect_named_formatting(failures)
	_expect_grapheme_segmentation(failures)
	_expect_pixel_wrapping(failures)
	_expect_dialogue_presenter(failures)
	_expect_backlog_bound(failures)
	_expect_four_tone_focus(failures)
	_expect_route_intent_label_detection(failures)
	_expect_safe_resonance_and_debug_views(failures)
	return failures


func _expect_named_formatting(failures: Array[String]) -> void:
	var formatter := NamedTextFormatter.new()
	var english := formatter.format("Welcome, {name}. Day {day}.", {&"name": "Ren", &"day": 3})
	var japanese := formatter.format("{name}、{day}日目です。", {&"name": "レン", &"day": 3})
	if not english.is_success() or english.text != "Welcome, Ren. Day 3.":
		failures.append("named English formatting changed authored order")
	if not japanese.is_success() or japanese.text != "レン、3日目です。":
		failures.append("named Japanese formatting changed authored order")
	var missing := formatter.format("Hello, {name}; {missing}.", {&"name": "Ren"})
	if missing.is_success() or not missing.text.contains("{missing}"):
		failures.append("missing named formatting argument was not diagnosed in place")
	if formatter.format("Use {{name}} literally.").text != "Use {name} literally.":
		failures.append("escaped named formatting braces were not preserved")
	var resolver := LocalizedContentResolver.new(_content)
	if resolver.resolve(&"dlg.hkr.empty_cushion.reimu.001", &"en").text == resolver.resolve(&"dlg.hkr.empty_cushion.reimu.001", &"ja").text:
		failures.append("content resolver did not return parallel EN/JA performances")


func _expect_grapheme_segmentation(failures: Array[String]) -> void:
	if GraphemeSegmenter.segments("e\u0301").size() != 1:
		failures.append("grapheme segmenter split a combining-mark cluster")
	if GraphemeSegmenter.segments("👨‍👩‍👧").size() != 1:
		failures.append("grapheme segmenter split a zero-width-joiner family")
	if GraphemeSegmenter.segments("霊夢").size() != 2:
		failures.append("grapheme segmenter corrupted Japanese character boundaries")


func _expect_pixel_wrapping(failures: Array[String]) -> void:
	var latin := UiFontRegistry.latin()
	var english := PixelTextWrapper.wrap("SECOND CUP STILL WARM", latin, 96, 8, &"en")
	if english.size() < 2 or not english[0].contains(" "):
		failures.append("English pixel wrapper ignored word boundaries")
	var japanese := PixelTextWrapper.wrap("二つ目の湯呑みは、まだ温かい。", UiFontRegistry.japanese(), 48, 8, &"ja")
	for line: String in japanese:
		if not line.is_empty() and PixelTextWrapper.JA_FORBIDDEN_LINE_START.contains(GraphemeSegmenter.segments(line)[0]):
			failures.append("Japanese pixel wrapper orphaned closing punctuation")
			break


func _expect_dialogue_presenter(failures: Array[String]) -> void:
	var beat := _content.dialogue_beat(&"beat.hkr.empty_cushion.reimu.001")
	var presenter := DialoguePresenter.new(_content)
	var state := presenter.present(beat, &"evt.hkr.empty_cushion", &"n003", &"en")
	if state.full_text != "I didn't wait. I simply hadn't put the second cup away yet." or state.speaker_name != "Reimu Hakurei":
		failures.append("DialoguePresenter did not resolve the reviewed English beat and speaker")
	presenter.tick(0.1)
	if state.revealed_count <= 0 or state.is_complete:
		failures.append("DialoguePresenter did not reveal a partial grapheme sequence")
	var english_progress := state.revealed_count
	presenter.switch_locale(&"ja")
	if state.locale != &"ja" or state.speaker_name != "博麗 霊夢" or not state.full_text.contains("待ってない"):
		failures.append("locale switch mid-line did not rebuild Japanese text and speaker")
	if state.revealed_count <= 0 or english_progress <= 0:
		failures.append("locale switch mid-line discarded reveal progress")
	if presenter.confirm() or not state.is_complete:
		failures.append("first confirm did not complete the active line without advancing")
	if not presenter.confirm() or presenter.backlog.entries.size() != 1:
		failures.append("second confirm did not accept exactly one backlog entry")
	var rendered := presenter.backlog.render_lines(LocalizedContentResolver.new(_content), &"en")
	if rendered.size() != 2 or not rendered[0].contains("second cup") or rendered[1] != "[cue.reimu.look_at_cup]":
		failures.append("backlog omitted accepted text or its nonverbal cue")
	var instant := DialoguePresenter.new(_content)
	instant.instant_text = true
	if not instant.present(beat, &"evt.hkr.empty_cushion", &"n003", &"en").is_complete:
		failures.append("instant text did not reveal the complete grapheme sequence")
	var automatic := DialoguePresenter.new(_content)
	automatic.auto_mode = true
	automatic.present(beat, &"evt.hkr.empty_cushion", &"n003", &"en")
	automatic.tick(10.0)
	automatic.tick(10.0)
	if not automatic.can_auto_advance() or not automatic.consume_auto_advance():
		failures.append("auto mode did not wait for reveal plus locale-aware reading time")
	if automatic.backlog.entries.size() != 1 or automatic.consume_auto_advance():
		failures.append("auto mode accepted one line more than once")


func _expect_backlog_bound(failures: Array[String]) -> void:
	var backlog := DialogueBacklog.new()
	for index: int in range(205):
		var entry := DialogueBacklogEntry.new()
		entry.event_id = &"evt.fixture.backlog"
		entry.node_id = StringName("n%03d" % index)
		entry.text_key = &"dlg.hkr.empty_cushion.reimu.001"
		backlog.add(entry)
	if backlog.entries.size() != 200 or backlog.entries[0].node_id != &"n005":
		failures.append("dialogue backlog did not retain exactly the latest 200 accepted lines")
	for property: Dictionary in DialogueBacklogEntry.new().get_property_list():
		if String(property.name).contains("delta") or String(property.name).contains("relationship"):
			failures.append("backlog entry exposed hidden relationship mutation data")


func _expect_four_tone_focus(failures: Array[String]) -> void:
	var state := _event_state()
	var graph := _content.graph(&"evt.hkr.empty_cushion")
	var choice := EventChoiceResolver.new().resolve(graph.node(&"n004").choice, state)
	var presenter := FourToneChoicePresenter.new(_content)
	presenter.configure(choice, &"en")
	var english := presenter.presentations()
	if english.size() != 4 or english[0].tone != &"direct" or english[0].text != "Say: You fixed that for me.":
		failures.append("four-tone presenter did not use stable semantic ordering")
	presenter.move(1)
	if presenter.focused_tone != &"playful":
		failures.append("four-tone focus did not move by semantic tone")
	presenter.switch_locale(&"ja")
	var japanese := presenter.presentations()
	if presenter.focused_tone != &"playful" or japanese[1].text != "「客にはみんな指定席があるの？」と冗談を言う。":
		failures.append("locale switch changed choice focus or failed to re-resolve Japanese")
	if presenter.confirm() != &"playful":
		failures.append("four-tone confirm returned localized text instead of stable intent")
	choice.option_for_tone(&"playful").is_available = false
	if presenter.confirm() != &"":
		failures.append("four-tone presenter confirmed a disabled authored option")


func _expect_route_intent_label_detection(failures: Array[String]) -> void:
	for choice_id: StringName in [
		&"choice.hkr.promise.intent",
		&"choice.aya.promise.intent",
		&"choice.ein.promise.intent",
		&"choice.pch.promise.intent",
		&"choice.rml.promise.intent",
		&"choice.sne.promise.intent",
	]:
		if not FourToneChoiceControl.uses_route_intent_labels(choice_id):
			failures.append("Promise choice did not request route-intent labels: %s" % choice_id)
	for choice_id: StringName in [
		&"choice.rml.the_audience.response",
		&"choice.aya.promise.romance_consent",
		&"choice.sne.promise.romance_consent",
	]:
		if FourToneChoiceControl.uses_route_intent_labels(choice_id):
			failures.append("ordinary or consent choice was mislabeled as route intent: %s" % choice_id)


func _expect_safe_resonance_and_debug_views(failures: Array[String]) -> void:
	var cue := EventPresentationCue.new(
		&"resonance",
		&"cue.resonance.reimu_hakurei.trust",
		&"char.reimu_hakurei",
		&"resonance.trust.open"
	)
	var views := ResonanceCueViewBuilder.build([cue])
	if views.size() != 1 or views[0].qualitative_key != &"resonance.trust.open":
		failures.append("Resonance cue did not retain its qualitative observation")
	for property: Dictionary in ResonanceCueView.new().get_property_list():
		if (int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and int(property.type) in [TYPE_INT, TYPE_FLOAT]:
			failures.append("player Resonance cue exposed a numeric property: %s" % property.name)
	var snapshot := EventDebugSnapshot.new()
	snapshot.event_id = &"evt.hkr.empty_cushion"
	snapshot.node_id = &"n004"
	snapshot.waiting_for = &"choice"
	snapshot.total_steps = 4
	snapshot.deterministic_seed = 77
	snapshot.pending_checkpoint = &"event_checkpoint"
	snapshot.localization_key = &"choice.hkr.empty_cushion.direct"
	snapshot.last_command_ids = [&"event.set_position"]
	var debug_text := "\n".join(EventDebugOverlayModel.build(snapshot).lines)
	if not debug_text.contains("evt.hkr.empty_cushion / n004") or not debug_text.contains("event.set_position"):
		failures.append("developer overlay model omitted event position or recent commands")
	if debug_text.contains("trust=") or debug_text.contains("spark="):
		failures.append("developer event overlay accidentally became a raw relationship panel")


func _event_state() -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(&"p30", character_ids, location_ids)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	return state
