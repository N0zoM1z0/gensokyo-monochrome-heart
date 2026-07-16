class_name DialogueEventFixture
extends Control
## Interactive M04 slice for the Empty Cushion event and bilingual screenshot matrix.

signal checkpoint_requested(reason: StringName)

enum Phase {
	LINE,
	CHOICE,
	MODE,
	END,
	ERROR,
}

const ACTION_CONTRACT := [
	"move",
	"confirm",
	"cancel",
	"journal",
	"focus",
	"page_left",
	"page_right",
]
const TEA_MODE_RESULTS: Array[StringName] = [&"excellent", &"clear", &"loss"]
const DANMAKU_MODE_RESULTS: Array[StringName] = [&"clear", &"assist_clear", &"loss"]
const FIGHTER_MODE_RESULTS: Array[StringName] = [&"win", &"loss"]

@export var fixture_start_at_choice: bool = false
@export var fixture_event_id: StringName = &"evt.hkr.empty_cushion"

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _content: ContentRepository
var _state: GameState
var _interpreter := EventInterpreter.new()
var _result: EventInterpreterResult
var _dialogue: DialoguePresenter
var _phase: Phase = Phase.ERROR
var _instant_text := true
var _show_backlog := false
var _mode_result_index := 1
var _mode_results: Array[StringName] = TEA_MODE_RESULTS.duplicate()
var _checkpoint_reasons: Array[StringName] = []
var _resonance_views: Array[ResonanceCueView] = []
var _diagnostic := ""
var _catalog := UiTextCatalog.new()
var _resolver: LocalizedContentResolver
var _latin_font: Font
var _japanese_font: Font

@onready var choice_control: FourToneChoiceControl = %FourToneChoice
@onready var debug_overlay: EventDebugOverlayControl = %EventDebugOverlay


func _ready() -> void:
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_catalog.load_default()
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	_restart()


func _process(delta: float) -> void:
	if _phase != Phase.LINE or _dialogue == null:
		return
	_dialogue.tick(delta)
	if _dialogue.consume_auto_advance():
		_accept_interpreter_result(_interpreter.advance_line())
	queue_redraw()


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	_profile = PresentationProfileRegistry.resolve(
		forced_profile if forced_profile != &"" else requested_profile
	)
	_locale = locale if locale in [&"en", &"ja"] else &"en"
	# Motion and flash settings share the fixture interface but never alter outcomes.
	if is_reduced_motion or is_safe_flash:
		queue_redraw()
	_restart()


func set_instant_text_for_test(enabled: bool) -> void:
	_instant_text = enabled


func tick_dialogue_for_test(delta: float) -> void:
	if _dialogue != null:
		_dialogue.tick(delta)
	queue_redraw()


func switch_locale(next_locale: StringName) -> void:
	if next_locale not in [&"en", &"ja"]:
		return
	_locale = next_locale
	if _dialogue != null and _phase == Phase.LINE:
		_dialogue.switch_locale(next_locale)
	if choice_control != null:
		choice_control.set_locale(next_locale)
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if action in [GameInput.PAGE_LEFT, GameInput.PAGE_RIGHT]:
		switch_locale(&"ja" if _locale == &"en" else &"en")
		return true
	if action == GameInput.JOURNAL:
		_show_backlog = not _show_backlog
		queue_redraw()
		return true
	if action == GameInput.FOCUS and _dialogue != null:
		_dialogue.auto_mode = not _dialogue.auto_mode
		queue_redraw()
		return true
	match _phase:
		Phase.LINE:
			if action == GameInput.CONFIRM:
				if _dialogue.confirm():
					_accept_interpreter_result(_interpreter.advance_line())
				queue_redraw()
				return true
		Phase.CHOICE:
			return choice_control.handle_semantic_action(action)
		Phase.MODE:
			if action in [GameInput.MOVE_UP, GameInput.MOVE_LEFT]:
				_mode_result_index = posmod(_mode_result_index - 1, _mode_results.size())
				queue_redraw()
				return true
			if action in [GameInput.MOVE_DOWN, GameInput.MOVE_RIGHT]:
				_mode_result_index = posmod(_mode_result_index + 1, _mode_results.size())
				queue_redraw()
				return true
			if action == GameInput.CONFIRM:
				_accept_interpreter_result(_interpreter.resume_mode(ModeResult.new(_mode_results[_mode_result_index])))
				return true
	return false


func phase() -> StringName:
	match _phase:
		Phase.LINE:
			return &"line"
		Phase.CHOICE:
			return &"choice"
		Phase.MODE:
			return &"mode"
		Phase.END:
			return &"end"
		_:
			return &"error"


func current_text() -> String:
	return _dialogue.current.full_text if _dialogue != null and _dialogue.current != null else ""


func current_visible_text() -> String:
	return _dialogue.current.visible_text() if _dialogue != null and _dialogue.current != null else ""


func revealed_count() -> int:
	return _dialogue.current.revealed_count if _dialogue != null and _dialogue.current != null else 0


func focused_tone() -> StringName:
	return choice_control.focused_tone() if choice_control != null else &""


func state_snapshot() -> GameState:
	return _state.deep_copy() if _state != null else null


func backlog_count() -> int:
	return _dialogue.backlog.entries.size() if _dialogue != null else 0


func backlog_lines() -> Array[String]:
	return _dialogue.backlog.render_lines(_resolver, _locale) if _dialogue != null else []


func checkpoint_reasons() -> Array[StringName]:
	return _checkpoint_reasons.duplicate()


func debug_snapshot() -> EventDebugSnapshot:
	return _interpreter.debug_snapshot()


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func _restart() -> void:
	if not is_node_ready() or choice_control == null:
		return
	var content_db := get_node_or_null("/root/ContentDB")
	_content = content_db.snapshot() if content_db != null else null
	if _content == null:
		_content = ContentRepository.new()
		_content.load_sources()
	_resolver = LocalizedContentResolver.new(_content)
	_state = _create_event_state()
	_interpreter = EventInterpreter.new()
	_dialogue = DialoguePresenter.new(_content)
	_dialogue.instant_text = _instant_text
	_checkpoint_reasons.clear()
	_resonance_views.clear()
	_show_backlog = false
	_mode_result_index = 1
	_mode_results = TEA_MODE_RESULTS.duplicate()
	_diagnostic = ""
	choice_control.visible = false
	choice_control.set_profile(_profile.profile_id)
	debug_overlay.set_overlay_enabled(false)
	_accept_interpreter_result(_interpreter.start(_content.graph(fixture_event_id), _state, _content))
	if fixture_start_at_choice:
		var guard := 0
		while _phase == Phase.LINE and guard < 8:
			_dialogue.confirm()
			_accept_interpreter_result(_interpreter.advance_line())
			guard += 1
	queue_redraw()


func _create_event_state() -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(&"p40", character_ids, location_ids, 4040)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	if fixture_event_id in [
		&"evt.hkr.offerings_without_owners",
		&"evt.hkr.day_nothing_happens",
		&"evt.hkr.promise",
	]:
		var dispatcher := GameCommandDispatcher.new()
		var predecessors: Array[StringName] = [&"evt.hkr.empty_cushion"]
		if fixture_event_id == &"evt.hkr.day_nothing_happens":
			predecessors.append(&"evt.hkr.offerings_without_owners")
		elif fixture_event_id == &"evt.hkr.promise":
			predecessors.append_array([
				&"evt.hkr.offerings_without_owners",
				&"evt.hkr.day_nothing_happens",
				&"evt.hkr.shrine_not_guesthouse",
				&"evt.hkr.unasked_rescue",
				&"evt.hkr.perfectly_recorded_tea",
			])
		for event_id: StringName in predecessors:
			dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_fixture_predecessor"))
			dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
		if fixture_event_id == &"evt.hkr.promise":
			dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.reimu_hakurei", 5))
	return state


func _accept_interpreter_result(next_result: EventInterpreterResult) -> void:
	_result = next_result
	if next_result == null or next_result.is_error():
		_phase = Phase.ERROR
		_diagnostic = "missing interpreter result" if next_result == null else next_result.diagnostic
		choice_control.visible = false
		queue_redraw()
		return
	if next_result.checkpoint_reason != &"":
		_checkpoint_reasons.append(next_result.checkpoint_reason)
		checkpoint_requested.emit(next_result.checkpoint_reason)
	_resonance_views = ResonanceCueViewBuilder.build(next_result.presentation_cues)
	debug_overlay.configure(_interpreter.debug_snapshot(), _profile.profile_id)
	match next_result.status:
		EventInterpreterResult.Status.WAIT_INPUT:
			if next_result.beat != null:
				_phase = Phase.LINE
				choice_control.visible = false
				_dialogue.present(next_result.beat, next_result.event_id, next_result.node_id, _locale)
			elif next_result.choice != null:
				_phase = Phase.CHOICE
				choice_control.visible = true
				choice_control.configure(next_result.choice, _content, _locale, _profile.profile_id, focused_tone())
		EventInterpreterResult.Status.WAIT_MODE:
			_phase = Phase.MODE
			choice_control.visible = false
			_mode_results = _results_for_context(next_result.mode_context)
			_mode_result_index = mini(_mode_result_index, _mode_results.size() - 1)
		EventInterpreterResult.Status.END:
			_phase = Phase.END
			choice_control.visible = false
	queue_redraw()


func _on_tone_confirmed(tone: StringName) -> void:
	_accept_interpreter_result(_interpreter.choose_tone(tone))


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	_draw_shrine_stage(foreground, background)
	if _show_backlog:
		_draw_backlog(foreground, background)
		return
	match _phase:
		Phase.LINE:
			_draw_dialogue(foreground, background)
		Phase.CHOICE:
			_draw_choice_header(foreground, background)
		Phase.MODE:
			_draw_mock_mode(foreground, background)
		Phase.END:
			_draw_end(foreground, background)
		Phase.ERROR:
			_draw_error(foreground, background)


func _draw_shrine_stage(foreground: Color, background: Color) -> void:
	for y: int in range(4, 92, 6):
		for x: int in range(2 + floori(y / 6.0) % 2 * 3, 320, 6):
			draw_rect(Rect2(x, y, 1, 1), foreground)
	# Roof, veranda, and pillars echo the reviewed shrine sample without gray pixels.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 42), Vector2(47, 14), Vector2(126, 34), Vector2(151, 48), Vector2(0, 48)]), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 40), Vector2(49, 20), Vector2(117, 38), Vector2(127, 42)]), background)
	draw_rect(Rect2(5, 49, 132, 4), foreground)
	draw_rect(Rect2(15, 52, 5, 47), foreground)
	draw_rect(Rect2(118, 52, 5, 47), foreground)
	draw_line(Vector2(0, 99), Vector2(320, 99), foreground, 2.0)
	_draw_reimu_portrait(Rect2(5, 47, 76, 112), foreground, background)


func _draw_reimu_portrait(rect: Rect2, foreground: Color, background: Color) -> void:
	draw_rect(rect, background)
	draw_rect(rect, foreground, false, 2.0)
	# Hair and oversized ribbon silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(20, 70), Vector2(43, 54), Vector2(68, 70), Vector2(61, 111), Vector2(27, 111)]), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(14, 57), Vector2(35, 48), Vector2(33, 68)]), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(73, 57), Vector2(52, 48), Vector2(54, 68)]), foreground)
	# Face is paper cut from hair, with restrained working-neutral eyes.
	draw_colored_polygon(PackedVector2Array([Vector2(30, 69), Vector2(57, 69), Vector2(59, 92), Vector2(44, 103), Vector2(28, 92)]), background)
	draw_line(Vector2(34, 81), Vector2(40, 80), foreground, 1.0)
	draw_line(Vector2(48, 80), Vector2(54, 81), foreground, 1.0)
	draw_line(Vector2(41, 91), Vector2(48, 91), foreground, 1.0)
	# Shrine-maiden sleeves and apron blocks keep the portrait readable at native size.
	draw_colored_polygon(PackedVector2Array([Vector2(27, 103), Vector2(9, 132), Vector2(25, 156), Vector2(63, 156), Vector2(78, 132), Vector2(59, 103)]), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(35, 106), Vector2(52, 106), Vector2(57, 156), Vector2(30, 156)]), background)
	draw_line(Vector2(35, 110), Vector2(52, 110), foreground, 2.0)


func _draw_dialogue(foreground: Color, background: Color) -> void:
	if _dialogue == null or _dialogue.current == null:
		return
	var panel := Rect2(83, 96, 231, 76)
	draw_rect(panel, background)
	draw_rect(panel, foreground, false, 2.0)
	draw_rect(Rect2(91, 88, 84, 12), background)
	draw_rect(Rect2(91, 88, 84, 12), foreground, false, 1.0)
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(font, Vector2(95, 97), _dialogue.current.speaker_name, HORIZONTAL_ALIGNMENT_LEFT, 76, 8, foreground)
	var maximum_lines := 4 if _locale == &"ja" else 3
	var lines := PixelTextWrapper.wrap(_dialogue.current.visible_text(), font, 211, 8, _locale, maximum_lines)
	for index: int in range(lines.size()):
		draw_string(font, Vector2(93, 113 + index * 11), lines[index], HORIZONTAL_ALIGNMENT_LEFT, 211, 8, foreground)
	var auto_key := &"ui.dialogue.auto_on" if _dialogue.auto_mode else &"ui.dialogue.auto_off"
	draw_string(font, Vector2(91, 166), _catalog.text(auto_key, _locale), HORIZONTAL_ALIGNMENT_LEFT, 100, 8, foreground)
	draw_string(font, Vector2(244, 166), _catalog.text(&"ui.dialogue.backlog", _locale), HORIZONTAL_ALIGNMENT_RIGHT, 62, 8, foreground)
	if _dialogue.current.is_complete:
		draw_colored_polygon(PackedVector2Array([Vector2(304, 157), Vector2(310, 157), Vector2(307, 161)]), foreground)


func _draw_choice_header(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(23, 4, 292, 30), background)
	draw_rect(Rect2(23, 4, 292, 30), foreground, false, 2.0)
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(font, Vector2(30, 17), _catalog.text(&"ui.dialogue.choose_intent", _locale), HORIZONTAL_ALIGNMENT_LEFT, 78, 8, foreground)
	var objective_key := _event_objective_key()
	var cue := _resolver.resolve(objective_key, _locale).text if objective_key != &"" else ""
	var cue_text := cue.to_upper() if _locale == &"en" else cue
	var cue_lines := PixelTextWrapper.wrap(cue_text, font, 194, 8, _locale, 2)
	for index: int in range(cue_lines.size()):
		draw_string(font, Vector2(113, 15 + index * 10), cue_lines[index], HORIZONTAL_ALIGNMENT_RIGHT, 194, 8, foreground)
	draw_string(font, Vector2(28, 176), _catalog.text(&"ui.dialogue.backlog", _locale), HORIZONTAL_ALIGNMENT_LEFT, 48, 8, foreground)


func _event_objective_key() -> StringName:
	var graph := _content.graph(fixture_event_id) if _content != null else null
	if graph == null:
		return &""
	for node: EventNodeRecord in graph.nodes:
		if node.objective_key != &"":
			return node.objective_key
	return &""


func _draw_mock_mode(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(88, 26, 226, 140), background)
	draw_rect(Rect2(88, 26, 226, 140), foreground, false, 2.0)
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(font, Vector2(96, 41), _catalog.text(&"ui.dialogue.mock_mode", _locale), HORIZONTAL_ALIGNMENT_CENTER, 210, 8, foreground)
	_draw_two_cups(Vector2(154, 62), foreground)
	for index: int in range(_mode_results.size()):
		var rect := Rect2(111, 104 + index * 18, 176, 15)
		draw_rect(rect, foreground, false, 1.0)
		if index == _mode_result_index:
			draw_rect(rect.grow(-2), foreground, false, 1.0)
		var key := _result_label_key(_mode_results[index])
		draw_string(font, Vector2(118, rect.position.y + 11), _catalog.text(key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 162, 8, foreground)
	if not _resonance_views.is_empty():
		draw_string(font, Vector2(94, 94), _catalog.text(&"ui.dialogue.resonance.cup_closer", _locale), HORIZONTAL_ALIGNMENT_CENTER, 214, 8, foreground)


func _results_for_context(context: ModeContext) -> Array[StringName]:
	if context != null:
		match context.mode_type:
			&"start_danmaku":
				return DANMAKU_MODE_RESULTS.duplicate()
			&"start_duel":
				return FIGHTER_MODE_RESULTS.duplicate()
	return TEA_MODE_RESULTS.duplicate()


func _result_label_key(result_tag: StringName) -> StringName:
	match result_tag:
		&"assist_clear":
			return &"ui.danmaku.result.assist_clear.title"
		&"win":
			return &"ui.fighter.result.win.title"
		&"loss":
			if _result != null and _result.mode_context != null and _result.mode_context.mode_type == &"start_duel":
				return &"ui.fighter.result.loss.title"
	return StringName("ui.dialogue.result.%s" % result_tag)


func _draw_two_cups(origin: Vector2, foreground: Color) -> void:
	for offset: Vector2 in [Vector2(0, 0), Vector2(45, 0)]:
		draw_rect(Rect2(origin + offset, Vector2(22, 14)), foreground, false, 2.0)
		draw_rect(Rect2(origin + offset + Vector2(21, 3), Vector2(7, 7)), foreground, false, 2.0)
		draw_line(origin + offset + Vector2(3, 18), origin + offset + Vector2(19, 18), foreground, 2.0)
	draw_line(origin + Vector2(29, 7), origin + Vector2(39, 7), foreground, 1.0)
	draw_colored_polygon(PackedVector2Array([origin + Vector2(36, 4), origin + Vector2(41, 7), origin + Vector2(36, 10)]), foreground)


func _draw_end(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(88, 52, 226, 92), background)
	draw_rect(Rect2(88, 52, 226, 92), foreground, false, 2.0)
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(font, Vector2(96, 70), _catalog.text(&"ui.dialogue.complete", _locale), HORIZONTAL_ALIGNMENT_CENTER, 210, 8, foreground)
	_draw_two_cups(Vector2(158, 84), foreground)
	draw_rect(Rect2(136, 119, 130, 14), foreground, false, 1.0)
	draw_string(font, Vector2(141, 129), _resolver.resolve(&"journal.hkr.empty_cushion.title", _locale).text, HORIZONTAL_ALIGNMENT_CENTER, 120, 8, foreground)


func _draw_backlog(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(5, 5, 310, 170), background)
	draw_rect(Rect2(5, 5, 310, 170), foreground, false, 2.0)
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(font, Vector2(13, 20), _catalog.text(&"ui.dialogue.backlog", _locale), HORIZONTAL_ALIGNMENT_LEFT, 294, 8, foreground)
	var y := 35
	for record: String in backlog_lines():
		for line: String in PixelTextWrapper.wrap(record, font, 286, 8, _locale, 2):
			draw_string(font, Vector2(17, y), line, HORIZONTAL_ALIGNMENT_LEFT, 286, 8, foreground)
			y += 11
		if y > 157:
			break
	draw_string(font, Vector2(13, 169), _catalog.text(&"ui.common.cancel", _locale), HORIZONTAL_ALIGNMENT_LEFT, 294, 8, foreground)


func _draw_error(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(84, 72, 230, 48), background)
	draw_rect(Rect2(84, 72, 230, 48), foreground, false, 2.0)
	draw_string(_latin_font, Vector2(91, 91), "EVENT ERROR", HORIZONTAL_ALIGNMENT_LEFT, 214, 8, foreground)
	draw_string(_latin_font, Vector2(91, 106), _diagnostic, HORIZONTAL_ALIGNMENT_LEFT, 214, 8, foreground)
