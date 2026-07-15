class_name VerticalSliceMode
extends GameMode
## M09 playable day coordinator for the data-authored Empty Cushion event.

enum Phase {
	INVITATION,
	WORLD_MAP,
	EXPLORATION,
	EVENT_LINE,
	EVENT_CHOICE,
	MECHANICAL_MODE,
	REWARD,
	DAY_END,
	JOURNAL,
	REPLAY_COMPLETE,
	COMPLETE,
	ERROR,
}

const EVENT_ID: StringName = &"evt.hkr.empty_cushion"
const LOCATION_ID: StringName = &"loc.hakurei_shrine"
const JOURNAL_ID: StringName = &"journal.hkr.empty_cushion"
const KEEPSAKE_ID: StringName = &"item.keepsake.unpaired_cup"
const AFTERBEAT_RELEASE_FRAMES := 8
const ACTION_CONTRACT := [
	"move", "confirm", "cancel", "focus", "companion", "bomb", "journal", "map",
	"page_left", "page_right", "pause", "shot", "guard", "light", "heavy", "skill", "spell",
]
const EXPLORATION_SCENE := preload("res://src/presentation/exploration/ExplorationMode.tscn")
const TEA_SCENE := preload("res://src/presentation/minigames/TeaTemperatureMode.tscn")
const DANMAKU_SCENE := preload("res://src/presentation/danmaku/BoundaryStainMode.tscn")
const FIGHTER_SCENE := preload("res://src/presentation/fighter/CompactFighterMode.tscn")

var _phase: Phase = Phase.ERROR
var _content: ContentRepository
var _working_state: GameState
var _interpreter := EventInterpreter.new()
var _event_result: EventInterpreterResult
var _dialogue: DialoguePresenter
var _resolver: LocalizedContentResolver
var _active_mode: GameMode
var _kernel: Node
var _save_service: Node
var _accessibility: Node
var _telemetry := VerticalSliceTelemetry.new()
var _telemetry_phase_id: StringName
var _is_replay: bool = false
var _replay_source_canonical := ""
var _mode_started_ms: int = 0
var _diagnostic := ""
var _show_backlog: bool = false
var _confirm_guard_frames: int = 0
var _instant_text_for_test: bool = false
var _fixture_comfort_override: bool = false
var _fixture_reduced_motion: bool = false
var _fixture_safe_flash: bool = false

var _profile := PresentationProfileRegistry.resolve(&"A")
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font

@onready var mode_host: Control = %ModeHost
@onready var choice_control: FourToneChoiceControl = %FourToneChoice
@onready var music_player: AdaptiveTestTonePlayer = %AdaptiveTestTonePlayer


func _ready() -> void:
	InputMapInstaller.install_defaults()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_catalog.load_default()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_kernel = get_node_or_null("/root/GameKernel")
	_save_service = get_node_or_null("/root/SaveService")
	_accessibility = get_node_or_null("/root/AccessibilityState")
	var content_db := get_node_or_null("/root/ContentDB")
	_content = content_db.snapshot() if content_db != null else null
	if _content == null:
		_content = ContentRepository.new()
		_content.load_sources()
	_resolver = LocalizedContentResolver.new(_content)
	_dialogue = DialoguePresenter.new(_content)
	_dialogue.instant_text = _instant_text_for_test
	choice_control.visible = false
	_connect_live_locale()
	_initialize_session()
	ready_for_input.emit()


func _process(delta: float) -> void:
	if _confirm_guard_frames > 0:
		if InputMap.has_action(GameInput.CONFIRM) and Input.is_action_pressed(GameInput.CONFIRM):
			_confirm_guard_frames = AFTERBEAT_RELEASE_FRAMES
		else:
			_confirm_guard_frames -= 1
	if _phase == Phase.EVENT_LINE and _dialogue != null:
		_dialogue.tick(delta)
		if _confirm_guard_frames == 0 and _dialogue.consume_auto_advance():
			_accept_event_result(_interpreter.advance_line())
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if action in [GameInput.PAGE_LEFT, GameInput.PAGE_RIGHT] and _phase in [
		Phase.EVENT_LINE, Phase.EVENT_CHOICE, Phase.JOURNAL, Phase.REPLAY_COMPLETE,
	]:
		_toggle_locale()
		return true
	if _active_mode != null and _phase in [Phase.EXPLORATION, Phase.MECHANICAL_MODE]:
		return bool(_active_mode.call("handle_semantic_action", action))
	match _phase:
		Phase.INVITATION:
			if action == GameInput.CONFIRM:
				_open_world_map()
				return true
		Phase.WORLD_MAP:
			if action == GameInput.CONFIRM:
				_travel_to_shrine()
				return true
		Phase.EVENT_LINE:
			if action == GameInput.JOURNAL:
				_show_backlog = not _show_backlog
				queue_redraw()
				return true
			if action == GameInput.FOCUS and _dialogue != null:
				_dialogue.auto_mode = not _dialogue.auto_mode
				queue_redraw()
				return true
			if action == GameInput.CONFIRM and _confirm_guard_frames == 0 and _dialogue != null:
				if _dialogue.confirm():
					_accept_event_result(_interpreter.advance_line())
				queue_redraw()
				return true
		Phase.EVENT_CHOICE:
			return choice_control.handle_semantic_action(action)
		Phase.REWARD:
			if action == GameInput.CONFIRM:
				_finish_day()
				return true
		Phase.DAY_END:
			if action == GameInput.CONFIRM:
				_set_phase(Phase.JOURNAL, &"journal")
				return true
		Phase.JOURNAL:
			if action == GameInput.CONFIRM:
				_start_journal_replay()
				return true
			if action == GameInput.CANCEL:
				_complete_without_replay()
				return true
		Phase.REPLAY_COMPLETE:
			if action == GameInput.CONFIRM:
				_is_replay = false
				_set_phase(Phase.JOURNAL, &"journal")
				return true
	return false


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func phase_id() -> StringName:
	match _phase:
		Phase.INVITATION:
			return &"invitation"
		Phase.WORLD_MAP:
			return &"world_map"
		Phase.EXPLORATION:
			return &"exploration"
		Phase.EVENT_LINE:
			return &"afterbeat" if _event_result != null and String(_event_result.node_id).begins_with("n_afterbeat") else &"dialogue"
		Phase.EVENT_CHOICE:
			return &"choice"
		Phase.MECHANICAL_MODE:
			return _active_mode_id()
		Phase.REWARD:
			return &"reward"
		Phase.DAY_END:
			return &"day_end"
		Phase.JOURNAL:
			return &"journal"
		Phase.REPLAY_COMPLETE:
			return &"replay_complete"
		Phase.COMPLETE:
			return &"complete"
		_:
			return &"error"


func active_child_mode() -> GameMode:
	return _active_mode


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func current_event_node_id() -> StringName:
	return _event_result.node_id if _event_result != null else &""


func current_text() -> String:
	return _dialogue.current.full_text if _dialogue != null and _dialogue.current != null else ""


func is_replay() -> bool:
	return _is_replay


func telemetry_snapshot() -> Dictionary:
	return _telemetry.to_data()


func set_instant_text_for_test(enabled: bool) -> void:
	_instant_text_for_test = enabled
	if _dialogue != null:
		_dialogue.instant_text = enabled


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
	_fixture_comfort_override = true
	_fixture_reduced_motion = is_reduced_motion
	_fixture_safe_flash = is_safe_flash
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null:
		localization.set_locale(locale if locale in [&"en", &"ja"] else &"en", false)
	queue_redraw()


func arm_input_for_test() -> void:
	_confirm_guard_frames = 0


func complete_exploration_for_test() -> bool:
	if not _active_mode is ExplorationMode:
		return false
	var exploration := _active_mode as ExplorationMode
	if not exploration.interact_target_for_test(&"prop.unpaired_cup"):
		return false
	if not exploration.interact_target_for_test(&"prop.empty_cushion"):
		return false
	exploration.set_player_position_for_test(Vector2(250, 130))
	return true


func submit_mode_result_for_test(result_tag: StringName, attempt_count: int = 1) -> bool:
	if _phase != Phase.MECHANICAL_MODE or _active_mode == null:
		return false
	var telemetry := ModeTelemetry.new()
	telemetry.attempt_count = attempt_count
	telemetry.elapsed_ticks = 1
	telemetry.deterministic_seed = _active_mode.mode_context.deterministic_seed
	var result := ModeResult.new(result_tag)
	result.telemetry = telemetry
	_on_mode_completed(result)
	return _phase != Phase.ERROR


func _initialize_session() -> void:
	if _kernel == null or not _kernel.has_method("state_snapshot"):
		_fail("GameKernel is unavailable for the vertical slice")
		return
	var snapshot: Variant = _kernel.call("state_snapshot")
	if not snapshot is GameState:
		_fail("an active profile is required for the vertical slice")
		return
	_working_state = snapshot
	_telemetry.begin_session(
		_working_state.profile_id,
		_content.report.content_revision,
		_content.report.content_hash
	)
	if _working_state.active_event_id == EVENT_ID:
		_start_authored_event(false)
	elif EVENT_ID in _working_state.completed_event_ids:
		if _working_state.journal.entries.has(JOURNAL_ID) and not _working_state.journal.entries[JOURNAL_ID].is_read:
			_set_phase(Phase.REWARD, &"reward")
		else:
			_set_phase(Phase.JOURNAL, &"journal")
	else:
		_set_phase(Phase.INVITATION, &"invitation")


func _open_world_map() -> void:
	if _working_state.chapter_id == &"chapter.prologue":
		_working_state.chapter_id = &"chapter.1"
	if _working_state.time_slot == &"morning":
		var advanced := GameCommandDispatcher.new().dispatch(_working_state, AdvanceTimeCommand.new(1))
		if not advanced.is_success():
			_fail(advanced.message)
			return
	if not _commit_working_state(&"slice.day_desk"):
		return
	_set_phase(Phase.WORLD_MAP, &"world_map")


func _travel_to_shrine() -> void:
	if _working_state.current_location != LOCATION_ID:
		var traveled := GameCommandDispatcher.new().dispatch(_working_state, SetLocationCommand.new(LOCATION_ID))
		if not traveled.is_success():
			_fail(traveled.message)
			return
	if not _commit_working_state(&"slice.travel", &"event_checkpoint"):
		return
	music_player.request_state(&"mus_shrine_day")
	_spawn_exploration()


func _spawn_exploration() -> void:
	_clear_active_mode()
	var context := ExplorationModeContext.new()
	context.mode_id = &"explore.hakurei_shrine.veranda"
	context.location_id = LOCATION_ID
	context.spot_id = &"loc.hakurei_shrine.veranda"
	context.time_slot = _working_state.time_slot
	context.objective_id = &"obj.hkr.find_second_cup"
	context.companion_id = &"char.reimu_hakurei"
	context.story_navigation_hints = true
	context.companion_skill_enabled = true
	var exploration := EXPLORATION_SCENE.instantiate() as ExplorationMode
	exploration.configure(context)
	exploration.configure_fixture(
		_profile.profile_id,
		_current_locale(),
		&"",
		_is_reduced_motion(),
		_is_safe_flash()
	)
	exploration.event_triggered.connect(_on_exploration_event_triggered)
	exploration.checkpoint_requested.connect(_on_child_checkpoint)
	_active_mode = exploration
	mode_host.add_child(exploration)
	_set_content_active_mode(context.mode_id)
	_set_phase(Phase.EXPLORATION, &"exploration")


func _on_exploration_event_triggered(event_id: StringName) -> void:
	if _phase != Phase.EXPLORATION or event_id != EVENT_ID:
		return
	_clear_active_mode()
	_working_state = _kernel.call("state_snapshot")
	_start_authored_event(false)


func _start_authored_event(replay: bool) -> void:
	_set_content_active_mode(&"vertical_slice")
	_is_replay = replay
	_interpreter = EventInterpreter.new()
	_dialogue = DialoguePresenter.new(_content)
	_dialogue.instant_text = _instant_text_for_test
	_show_backlog = false
	var graph := _content.graph(EVENT_ID)
	if graph == null:
		_fail("the authored Empty Cushion graph is unavailable")
		return
	_accept_event_result(_interpreter.start(graph, _working_state, _content, replay))


func _accept_event_result(result: EventInterpreterResult) -> void:
	_event_result = result
	if result == null or result.is_error():
		_fail("event interpreter error" if result == null else result.diagnostic)
		return
	_apply_presentation_cues(result.presentation_cues)
	if not _is_replay and not _commit_working_state(
		&"slice.event_checkpoint",
		result.checkpoint_reason
	):
		return
	match result.status:
		EventInterpreterResult.Status.WAIT_INPUT:
			if result.beat != null:
				choice_control.visible = false
				_dialogue.present(result.beat, result.event_id, result.node_id, _current_locale())
				if String(result.node_id).begins_with("n_afterbeat"):
					_confirm_guard_frames = AFTERBEAT_RELEASE_FRAMES
				_set_phase(
					Phase.EVENT_LINE,
					&"replay_afterbeat" if _is_replay and String(result.node_id).begins_with("n_afterbeat") else (
						&"afterbeat" if String(result.node_id).begins_with("n_afterbeat") else (&"replay_dialogue" if _is_replay else &"dialogue")
					)
				)
			elif result.choice != null:
				choice_control.visible = true
				choice_control.configure(
					result.choice,
					_content,
					_current_locale(),
					_profile.profile_id,
					choice_control.focused_tone()
				)
				_set_phase(Phase.EVENT_CHOICE, &"replay_choice" if _is_replay else &"choice")
		EventInterpreterResult.Status.WAIT_MODE:
			choice_control.visible = false
			_spawn_mechanical_mode(result.mode_context)
		EventInterpreterResult.Status.END:
			choice_control.visible = false
			if _is_replay:
				_finish_replay()
			else:
				_working_state = _kernel.call("state_snapshot")
				_set_phase(Phase.REWARD, &"reward")


func _spawn_mechanical_mode(context: ModeContext) -> void:
	if context == null:
		_fail("event mode handoff omitted its typed context")
		return
	_clear_active_mode()
	var packed: PackedScene
	match context.mode_type:
		&"start_minigame":
			packed = TEA_SCENE
		&"start_danmaku":
			packed = DANMAKU_SCENE
		&"start_duel":
			packed = FIGHTER_SCENE
		_:
			_fail("unsupported event mode type: %s" % context.mode_type)
			return
	var mode := packed.instantiate() as GameMode
	mode.configure(context)
	mode.call(
		"configure_fixture",
		_profile.profile_id,
		_current_locale(),
		&"",
		_is_reduced_motion(),
		_is_safe_flash()
	)
	if mode is TeaTemperatureMode:
		(mode as TeaTemperatureMode).configure_assists(_tea_assists())
	elif mode is BoundaryStainMode:
		(mode as BoundaryStainMode).configure_assists(_danmaku_assists())
	elif mode is CompactFighterMode:
		(mode as CompactFighterMode).configure_assists(_fighter_assists())
	mode.mode_completed.connect(_on_mode_completed)
	mode.checkpoint_requested.connect(_on_child_checkpoint)
	_active_mode = mode
	mode_host.add_child(mode)
	_set_content_active_mode(context.mode_id)
	_mode_started_ms = Time.get_ticks_msec()
	_set_phase(
		Phase.MECHANICAL_MODE,
		StringName("replay.%s" % context.mode_id) if _is_replay else context.mode_id
	)


func _on_mode_completed(result: ModeResult) -> void:
	if _phase != Phase.MECHANICAL_MODE or _active_mode == null or result == null:
		return
	var completed_mode_id := _active_mode.mode_context.mode_id
	_telemetry.record_mode_result(
		completed_mode_id,
		result,
		maxi(0, Time.get_ticks_msec() - _mode_started_ms),
		_is_replay
	)
	_clear_active_mode()
	_set_content_active_mode(&"vertical_slice")
	var resumed := _interpreter.resume_mode(result)
	if not _is_replay and not _commit_working_state(&"slice.after_mode", &"after_mode"):
		return
	_accept_event_result(resumed)


func _on_child_checkpoint(reason: StringName) -> void:
	checkpoint_requested.emit(reason)


func _on_tone_confirmed(tone: StringName) -> void:
	if _phase == Phase.EVENT_CHOICE:
		_accept_event_result(_interpreter.choose_tone(tone))


func _apply_presentation_cues(cues: Array[EventPresentationCue]) -> void:
	for cue: EventPresentationCue in cues:
		if cue.kind == &"music":
			music_player.request_state(cue.cue_id)


func _finish_day() -> void:
	_working_state = _kernel.call("state_snapshot")
	if _working_state.journal.entries.has(JOURNAL_ID) and not _working_state.journal.entries[JOURNAL_ID].is_read:
		var marked := GameCommandDispatcher.new().dispatch(
			_working_state,
			MarkJournalEntryReadCommand.new(JOURNAL_ID)
		)
		if not marked.is_success():
			_fail(marked.message)
			return
	var slot_count := 4 - TimeSlotRules.SLOTS.find(_working_state.time_slot)
	var advanced := GameCommandDispatcher.new().dispatch(
		_working_state,
		AdvanceTimeCommand.new(slot_count)
	)
	if not advanced.is_success():
		_fail(advanced.message)
		return
	if not _commit_working_state(&"slice.day_end", &"day_start"):
		return
	if _save_service != null:
		var saved: Variant = _save_service.call("save_manual", 1, _save_context())
		if not saved is SaveOperationResult or not saved.is_success():
			_fail("manual day-end save failed")
			return
	_set_phase(Phase.DAY_END, &"day_end")


func _start_journal_replay() -> void:
	var source: Variant = _kernel.call("state_snapshot")
	if not source is GameState or EVENT_ID not in source.journal.replay_event_ids:
		_fail("the completed event is not unlocked for Journal replay")
		return
	_working_state = source
	_replay_source_canonical = GameStateCodec.new().canonical_state(source)
	_start_authored_event(true)


func _finish_replay() -> void:
	var current: Variant = _kernel.call("state_snapshot")
	if not current is GameState or GameStateCodec.new().canonical_state(current) != _replay_source_canonical:
		_fail("Journal replay mutated the active save")
		return
	_telemetry.complete_session()
	var write_result := _telemetry.write_local()
	if not write_result.is_success():
		_fail("local acceptance telemetry could not be committed")
		return
	_set_phase(Phase.REPLAY_COMPLETE, &"replay_complete")


func _complete_without_replay() -> void:
	_telemetry.complete_session()
	var write_result := _telemetry.write_local()
	if not write_result.is_success():
		_fail("local acceptance telemetry could not be committed")
		return
	_set_phase(Phase.COMPLETE, &"complete")
	mode_completed.emit(ModeResult.new(&"complete"))


func _commit_working_state(source_id: StringName, autosave_reason: StringName = &"") -> bool:
	if _is_replay:
		return true
	var accepted: Variant = _kernel.call("replace_state", _working_state, source_id)
	if not accepted is CommandResult or not accepted.is_success():
		_fail("GameKernel rejected the vertical-slice state checkpoint")
		return false
	if autosave_reason != &"" and _save_service != null:
		var saved: Variant = _save_service.call("autosave", autosave_reason, _save_context())
		if not saved is SaveOperationResult or not saved.is_success():
			_fail("autosave failed at %s" % autosave_reason)
			return false
	if autosave_reason != &"":
		checkpoint_requested.emit(autosave_reason)
	return true


func _save_context() -> SaveCardContext:
	var context := SaveCardContext.new()
	context.visible_character_ids = [&"char.reimu_hakurei", &"char.marisa_kirisame"]
	context.accessibility_preset_id = _working_state.protagonist.comfort_profile_id
	return context


func _tea_assists() -> MinigameAssistSettings:
	var settings := MinigameAssistSettings.new()
	if _accessibility != null and _accessibility.preset == AccessibilityState.Preset.STORY:
		settings.slower_heat_change = true
		settings.wider_target_band = true
		settings.no_timer = true
	return settings


func _danmaku_assists() -> DanmakuAssistSettings:
	var settings := DanmakuAssistSettings.new()
	settings.story_mode = true
	settings.no_flash = _is_safe_flash()
	if _accessibility != null:
		settings.density_percent = _accessibility.bullet_density_percent
		settings.bullet_speed_percent = _accessibility.game_speed_percent
		if _accessibility.preset == AccessibilityState.Preset.STORY:
			settings.larger_graze_radius = true
			settings.safe_lane_preview = true
			settings.auto_bomb = true
			settings.background_dim_percent = 70
	return settings


func _fighter_assists() -> FighterAssistSettings:
	var settings := FighterAssistSettings.new()
	settings.simple_inputs = false
	settings.hold_to_guard = false
	settings.auto_face = false
	settings.no_flash = _is_safe_flash()
	settings.reduced_motion = _is_reduced_motion()
	if _accessibility != null:
		settings.speed_percent = _accessibility.game_speed_percent
		if _accessibility.preset == AccessibilityState.Preset.STORY:
			settings.simple_inputs = true
			settings.hold_to_guard = true
			settings.auto_face = true
	return settings


func _set_phase(next_phase: Phase, telemetry_phase_id: StringName) -> void:
	_phase = next_phase
	if telemetry_phase_id != &"" and telemetry_phase_id != _telemetry_phase_id:
		_telemetry_phase_id = telemetry_phase_id
		_telemetry.enter_phase(telemetry_phase_id, -1, _is_replay)
	queue_redraw()


func _clear_active_mode() -> void:
	if _active_mode == null:
		return
	var prior := _active_mode
	_active_mode = null
	if prior.get_parent() != null:
		prior.get_parent().remove_child(prior)
	prior.queue_free()


func _active_mode_id() -> StringName:
	return _active_mode.mode_context.mode_id if _active_mode != null and _active_mode.mode_context != null else &""


func _set_content_active_mode(active_id: StringName) -> void:
	var content_db := get_node_or_null("/root/ContentDB")
	if content_db != null:
		content_db.set_active_mode(active_id)


func _connect_live_locale() -> void:
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null and not localization.locale_changed.is_connected(_on_locale_changed):
		localization.locale_changed.connect(_on_locale_changed)
	var theme := get_node_or_null("/root/UiThemeRegistry")
	if theme != null:
		_profile = PresentationProfileRegistry.resolve(theme.effective_profile_id())


func _toggle_locale() -> void:
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null:
		localization.set_locale(&"ja" if localization.locale == &"en" else &"en")


func _on_locale_changed(locale: StringName) -> void:
	if _dialogue != null and _phase == Phase.EVENT_LINE:
		_dialogue.switch_locale(locale)
	choice_control.set_locale(locale)
	if _active_mode != null and _active_mode.has_method("switch_locale"):
		_active_mode.call("switch_locale", locale)
	queue_redraw()


func _current_locale() -> StringName:
	var localization := get_node_or_null("/root/LocalizationService")
	return localization.locale if localization != null else &"en"


func _is_reduced_motion() -> bool:
	if _fixture_comfort_override:
		return _fixture_reduced_motion
	return bool(_accessibility.is_reduced_motion) if _accessibility != null else false


func _is_safe_flash() -> bool:
	if _fixture_comfort_override:
		return _fixture_safe_flash
	return bool(_accessibility.is_safe_flash) if _accessibility != null else false


func _fail(message: String) -> void:
	_diagnostic = message
	_clear_active_mode()
	choice_control.visible = false
	_phase = Phase.ERROR
	push_error("Vertical slice stopped: %s" % message)
	queue_redraw()


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	if _active_mode != null:
		return
	match _phase:
		Phase.INVITATION:
			_draw_invitation(foreground, background)
		Phase.WORLD_MAP:
			_draw_world_map(foreground, background)
		Phase.EVENT_LINE, Phase.EVENT_CHOICE:
			_draw_event(foreground, background)
		Phase.REWARD:
			_draw_reward(foreground, background)
		Phase.DAY_END:
			_draw_day_end(foreground, background)
		Phase.JOURNAL:
			_draw_journal(foreground, background)
		Phase.REPLAY_COMPLETE:
			_draw_replay_complete(foreground, background)
		Phase.COMPLETE:
			_draw_complete(foreground, background)
		Phase.ERROR:
			_draw_error(foreground, background)


func _draw_invitation(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.invitation.header", foreground, background)
	draw_rect(Rect2(24, 55, 118, 62), foreground, false, 2.0)
	draw_line(Vector2(35, 73), Vector2(130, 73), foreground, 1.0)
	draw_rect(Rect2(49, 80, 68, 24), foreground, false, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(49, 80), Vector2(83, 96), Vector2(117, 80)]), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(53, 82), Vector2(83, 94), Vector2(113, 82)]), background)
	_draw_wrapped(&"ui.slice.invitation.body", Rect2(158, 56, 136, 55), 4)
	_draw_footer(&"ui.slice.invitation.confirm", foreground, background)


func _draw_world_map(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.map.header", foreground, background)
	draw_rect(Rect2(14, 39, 204, 114), foreground, false, 1.0)
	for point: Vector2 in [Vector2(42, 71), Vector2(72, 121), Vector2(109, 57), Vector2(155, 105), Vector2(190, 73)]:
		draw_rect(Rect2(point, Vector2(3, 3)), foreground)
	draw_line(Vector2(43, 72), Vector2(109, 58), foreground, 1.0)
	draw_line(Vector2(109, 58), Vector2(156, 106), foreground, 1.0)
	draw_line(Vector2(156, 106), Vector2(191, 74), foreground, 1.0)
	draw_circle(Vector2(109, 58), 8, foreground)
	draw_circle(Vector2(109, 58), 5, background)
	draw_line(Vector2(109, 49), Vector2(109, 67), foreground, 1.0)
	draw_line(Vector2(100, 58), Vector2(118, 58), foreground, 1.0)
	var location := _content.location(LOCATION_ID)
	var location_name := location.display_name(_current_locale()) if location != null else ""
	_draw_text(location_name, Vector2(229, 58), 76, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_wrapped(&"ui.slice.map.body", Rect2(228, 72, 78, 62), 5)
	_draw_footer(&"ui.slice.map.confirm", foreground, background)


func _draw_event(foreground: Color, background: Color) -> void:
	_draw_shrine_stage(foreground, background)
	if _show_backlog:
		_draw_backlog(foreground, background)
		return
	if _phase == Phase.EVENT_CHOICE:
		draw_rect(Rect2(83, 5, 231, 25), background)
		draw_rect(Rect2(83, 5, 231, 25), foreground, false, 2.0)
		_draw_text(_ui(&"ui.dialogue.choose_intent"), Vector2(91, 20), 215, HORIZONTAL_ALIGNMENT_CENTER)
		return
	if _dialogue == null or _dialogue.current == null:
		return
	var panel := Rect2(83, 95, 231, 78)
	draw_rect(panel, background)
	draw_rect(panel, foreground, false, 2.0)
	draw_rect(Rect2(91, 87, 76, 12), background)
	draw_rect(Rect2(91, 87, 76, 12), foreground, false, 1.0)
	_draw_text(_dialogue.current.speaker_name, Vector2(95, 97), 68)
	var lines := PixelTextWrapper.wrap(
		_dialogue.current.visible_text(), _font(), 211, 8, _current_locale(), 4 if _current_locale() == &"ja" else 3
	)
	for index: int in range(lines.size()):
		_draw_text(lines[index], Vector2(93, 113 + index * 11), 211)
	var auto_key := &"ui.dialogue.auto_on" if _dialogue.auto_mode else &"ui.dialogue.auto_off"
	_draw_text(_ui(auto_key), Vector2(91, 168), 102)
	_draw_text(_ui(&"ui.dialogue.backlog"), Vector2(244, 168), 62, HORIZONTAL_ALIGNMENT_RIGHT)
	if _confirm_guard_frames > 0:
		_draw_text(_ui(&"ui.slice.afterbeat.settle"), Vector2(172, 89), 136, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_reward(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.reward.header", foreground, background)
	_draw_two_cups(Vector2(54, 62), foreground)
	draw_rect(Rect2(29, 105, 126, 19), foreground, false, 2.0)
	_draw_text(_resolver.resolve(&"journal.hkr.empty_cushion.title", _current_locale()).text, Vector2(35, 118), 114, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_wrapped(&"ui.slice.reward.body", Rect2(172, 55, 123, 31), 3)
	_draw_text(_resolver.resolve(&"journal.hkr.empty_cushion.body", _current_locale()).text, Vector2(170, 101), 128, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_footer(&"ui.slice.reward.confirm", foreground, background)


func _draw_day_end(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.day_end.header", foreground, background)
	for x: int in range(18, 302, 14):
		draw_line(Vector2(x, 116), Vector2(x + 8, 105), foreground, 1.0)
	draw_circle(Vector2(160, 77), 19, foreground)
	draw_circle(Vector2(160, 77), 14, background)
	_draw_wrapped(&"ui.slice.day_end.body", Rect2(46, 128, 228, 22), 2)
	_draw_footer(&"ui.slice.day_end.confirm", foreground, background)


func _draw_journal(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.journal.header", foreground, background)
	draw_rect(Rect2(18, 44, 284, 100), foreground, false, 2.0)
	draw_line(Vector2(160, 45), Vector2(160, 143), foreground, 1.0)
	_draw_text(_resolver.resolve(&"journal.hkr.empty_cushion.title", _current_locale()).text, Vector2(27, 60), 124, HORIZONTAL_ALIGNMENT_CENTER)
	var journal_body := _resolver.resolve(&"journal.hkr.empty_cushion.body", _current_locale()).text
	var lines := PixelTextWrapper.wrap(journal_body, _font(), 116, 8, _current_locale(), 5)
	for index: int in range(lines.size()):
		_draw_text(lines[index], Vector2(31, 77 + index * 11), 116, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_two_cups(Vector2(198, 62), foreground)
	_draw_wrapped(&"ui.slice.journal.replay_body", Rect2(177, 99, 108, 30), 3)
	_draw_footer(&"ui.slice.journal.confirm", foreground, background)


func _draw_replay_complete(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.replay_complete.header", foreground, background)
	_draw_two_cups(Vector2(118, 72), foreground)
	_draw_wrapped(&"ui.slice.replay_complete.body", Rect2(50, 112, 220, 24), 2)
	_draw_footer(&"ui.slice.replay_complete.confirm", foreground, background)


func _draw_complete(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.complete.header", foreground, background)
	_draw_wrapped(&"ui.slice.complete.body", Rect2(44, 78, 232, 45), 4)


func _draw_error(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.error.header", foreground, background)
	_draw_wrapped(&"ui.slice.error.body", Rect2(44, 76, 232, 45), 4)
	if BuildChannel.allows_debug_tools():
		_draw_text(_diagnostic, Vector2(28, 142), 264, HORIZONTAL_ALIGNMENT_CENTER, 6)


func _draw_backlog(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(5, 5, 310, 170), background)
	draw_rect(Rect2(5, 5, 310, 170), foreground, false, 2.0)
	_draw_text(_ui(&"ui.dialogue.backlog"), Vector2(13, 20), 294)
	var y := 35
	var entries := _dialogue.backlog.entries if _dialogue != null else []
	var first := maxi(0, entries.size() - 10)
	for index: int in range(first, entries.size()):
		var text := entries[index].render(_resolver, _current_locale())
		for line: String in PixelTextWrapper.wrap(text, _font(), 286, 8, _current_locale(), 2):
			_draw_text(line, Vector2(17, y), 286)
			y += 11
			if y > 157:
				break
	_draw_text(_ui(&"ui.slice.backlog.close"), Vector2(13, 169), 294)


func _draw_shrine_stage(foreground: Color, background: Color) -> void:
	for y: int in range(4, 92, 6):
		for x: int in range(2 + floori(y / 6.0) % 2 * 3, 320, 6):
			draw_rect(Rect2(x, y, 1, 1), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 42), Vector2(47, 14), Vector2(126, 34), Vector2(151, 48), Vector2(0, 48)]), foreground)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 40), Vector2(49, 20), Vector2(117, 38), Vector2(127, 42)]), background)
	draw_rect(Rect2(5, 49, 132, 4), foreground)
	draw_rect(Rect2(15, 52, 5, 47), foreground)
	draw_rect(Rect2(118, 52, 5, 47), foreground)
	draw_line(Vector2(0, 99), Vector2(320, 99), foreground, 2.0)
	draw_circle(Vector2(44, 75), 22, foreground)
	draw_circle(Vector2(44, 77), 14, background)
	draw_line(Vector2(33, 82), Vector2(39, 81), foreground, 1.0)
	draw_line(Vector2(49, 81), Vector2(55, 82), foreground, 1.0)


func _draw_frame(foreground: Color) -> void:
	draw_rect(Rect2(8, 8, 304, 164), foreground, false, 2.0)


func _draw_header(key: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(17, 18, 286, 23), background)
	draw_rect(Rect2(17, 18, 286, 23), foreground, false, 1.0)
	_draw_text(_ui(key), Vector2(23, 33), 274, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_footer(key: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(16, 151, 288, 15), background)
	draw_rect(Rect2(16, 151, 288, 15), foreground, false, 1.0)
	_draw_text(_ui(key), Vector2(21, 162), 278, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_wrapped(key: StringName, rect: Rect2, maximum_lines: int) -> void:
	var lines := PixelTextWrapper.wrap(_ui(key), _font(), rect.size.x, 8, _current_locale(), maximum_lines)
	for index: int in range(lines.size()):
		_draw_text(lines[index], rect.position + Vector2(0, 8 + index * 11), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_text(
	text: String,
	position: Vector2,
	width: float,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	font_size: int = 8
) -> void:
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_string(_font(), position, text, alignment, width, font_size, foreground)


func _draw_two_cups(origin: Vector2, foreground: Color) -> void:
	for offset: Vector2 in [Vector2(0, 0), Vector2(45, 0)]:
		draw_rect(Rect2(origin + offset, Vector2(22, 14)), foreground, false, 2.0)
		draw_rect(Rect2(origin + offset + Vector2(21, 3), Vector2(7, 7)), foreground, false, 2.0)
		draw_line(origin + offset + Vector2(3, 18), origin + offset + Vector2(19, 18), foreground, 2.0)
	draw_line(origin + Vector2(29, 7), origin + Vector2(39, 7), foreground, 1.0)
	draw_colored_polygon(PackedVector2Array([origin + Vector2(36, 4), origin + Vector2(41, 7), origin + Vector2(36, 10)]), foreground)


func _font() -> Font:
	return _japanese_font if _current_locale() == &"ja" else _latin_font


func _ui(key: StringName, arguments: Dictionary = {}) -> String:
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null:
		return localization.formatted_text(key, arguments)
	return NamedTextFormatter.new().format(_catalog.text(key, _current_locale()), arguments).text
