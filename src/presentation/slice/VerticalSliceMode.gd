class_name VerticalSliceMode
extends GameMode
## Reusable playable-day coordinator for a data-authored event slice.

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

const AFTERBEAT_RELEASE_FRAMES := 36
const ACTION_CONTRACT := [
	"move", "confirm", "cancel", "focus", "companion", "bomb", "journal", "map",
	"page_left", "page_right", "pause", "shot", "guard", "light", "heavy", "skill", "spell",
]

@export_enum("hakurei_shrine", "scarlet_devil_mansion", "youkai_mountain") var slice_component := "hakurei_shrine"

var _phase: Phase = Phase.ERROR
var _definition := EventSliceDefinitionFactory.build(&"hakurei_shrine")
var _mode_registry := EventModeSceneRegistry.new()
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
var _completion_emitted: bool = false
var _large_text_page: int = 0

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
	_definition = EventSliceDefinitionFactory.build(StringName(slice_component))
	_dialogue = DialoguePresenter.new(_content)
	_dialogue.instant_text = _instant_text_for_test
	choice_control.visible = false
	_apply_choice_scale()
	_connect_live_locale()
	_initialize_session()
	ready_for_input.emit()


func set_ui_scale_fixture(percent: int) -> void:
	super.set_ui_scale_fixture(percent)
	if choice_control != null:
		_apply_choice_scale()


func _apply_choice_scale() -> void:
	choice_control.set_ui_scale(ui_scale_percent())
	choice_control.position = Vector2(14, 31) if ui_scale_percent() > 100 else Vector2(14, 33)
	choice_control.size = Vector2(292, 134) if ui_scale_percent() > 100 else Vector2(292, 126)


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
	if _phase == Phase.JOURNAL and ui_scale_percent() > 100 and action in [GameInput.MOVE_UP, GameInput.MOVE_DOWN]:
		var page_count := _journal_large_page_count()
		_large_text_page = clampi(_large_text_page + (-1 if action == GameInput.MOVE_UP else 1), 0, page_count - 1)
		queue_redraw()
		return true
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
				_travel_to_event_location()
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
		Phase.COMPLETE:
			if action == GameInput.CONFIRM and not _completion_emitted:
				_completion_emitted = true
				mode_completed.emit(ModeResult.new(&"complete"))
				return true
	return false


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	if GameInput.PAUSE in candidates:
		return GameInput.PAUSE
	if _active_mode != null and _active_mode.has_method("resolve_input_candidates"):
		return StringName(_active_mode.call("resolve_input_candidates", candidates))
	match _phase:
		Phase.EVENT_LINE:
			return GameInput.first_matching(candidates, [
				GameInput.PAGE_LEFT, GameInput.PAGE_RIGHT, GameInput.JOURNAL,
				GameInput.FOCUS, GameInput.CONFIRM, GameInput.CANCEL,
			])
		Phase.EVENT_CHOICE:
			return GameInput.first_matching(candidates, [
				GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.MOVE_LEFT,
				GameInput.MOVE_RIGHT, GameInput.CONFIRM,
			])
		Phase.JOURNAL, Phase.REPLAY_COMPLETE:
			return GameInput.first_matching(candidates, [
				GameInput.PAGE_LEFT, GameInput.PAGE_RIGHT, GameInput.CONFIRM, GameInput.CANCEL,
			])
		_:
			return GameInput.first_matching(candidates, [
				GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.MOVE_LEFT,
				GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.CANCEL,
			])


func phase_id() -> StringName:
	match _phase:
		Phase.INVITATION:
			return &"invitation"
		Phase.WORLD_MAP:
			return &"world_map"
		Phase.EXPLORATION:
			return &"exploration"
		Phase.EVENT_LINE:
			return &"afterbeat" if _event_result != null and _definition.is_afterbeat_node(_event_result.node_id) else &"dialogue"
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


func slice_component_id() -> StringName:
	return _definition.component_id


func current_stage_component() -> StringName:
	return _definition.stage_component(current_event_node_id())


func telemetry_snapshot() -> Dictionary:
	return _telemetry.to_data()


func set_instant_text_for_test(enabled: bool) -> void:
	_instant_text_for_test = enabled
	if _dialogue != null:
		_dialogue.instant_text = enabled
		if enabled and _dialogue.current != null:
			_dialogue.current.revealed_count = _dialogue.current.graphemes.size()
			_dialogue.current.is_complete = true


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
	if _accessibility != null:
		_accessibility.apply_preset(
			AccessibilityState.Preset.LOW_MOTION if is_reduced_motion else AccessibilityState.Preset.STORY,
			false
		)
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
	for target_id: StringName in _definition.exploration_target_ids:
		if not exploration.interact_target_for_test(target_id):
			return false
	exploration.set_player_position_for_test(_definition.exploration_trigger_position)
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
	_definition = EventSliceDefinitionFactory.for_state(_working_state, StringName(slice_component))
	_telemetry.begin_session(
		_working_state.profile_id,
		_content.report.content_revision,
		_content.report.content_hash
	)
	if _working_state.active_event_id == _definition.event_id:
		_start_authored_event(false)
	elif _definition.event_id in _working_state.completed_event_ids:
		if _working_state.journal.entries.has(_definition.journal_id) and not _working_state.journal.entries[_definition.journal_id].is_read:
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


func _travel_to_event_location() -> void:
	if _working_state.current_location != _definition.location_id:
		var traveled := GameCommandDispatcher.new().dispatch(_working_state, SetLocationCommand.new(_definition.location_id))
		if not traveled.is_success():
			_fail(traveled.message)
			return
	if not _commit_working_state(&"slice.travel", &"event_checkpoint"):
		return
	music_player.request_state(_definition.initial_music_id)
	_spawn_exploration()


func _spawn_exploration() -> void:
	_clear_active_mode()
	var context := ExplorationModeContext.new()
	context.mode_id = _definition.exploration_mode_id
	context.location_id = _definition.location_id
	context.spot_id = _definition.spot_id
	context.time_slot = _working_state.time_slot
	context.objective_id = _definition.objective_id
	context.companion_id = _definition.companion_id
	context.story_navigation_hints = true
	context.companion_skill_enabled = true
	var exploration_scene := ResourceLoader.load(_definition.exploration_scene_path, "PackedScene") as PackedScene
	if exploration_scene == null:
		_fail("slice exploration scene is unavailable: %s" % _definition.exploration_scene_path)
		return
	var exploration := exploration_scene.instantiate() as ExplorationMode
	if exploration == null:
		_fail("slice exploration scene does not provide ExplorationMode")
		return
	exploration.configure(context)
	exploration.configure_fixture(
		_profile.profile_id,
		_current_locale(),
		&"",
		_is_reduced_motion(),
		_is_safe_flash()
	)
	if _fixture_ui_scale_percent > 0:
		exploration.set_ui_scale_fixture(_fixture_ui_scale_percent)
	exploration.event_triggered.connect(_on_exploration_event_triggered)
	exploration.checkpoint_requested.connect(_on_child_checkpoint)
	_active_mode = exploration
	mode_host.add_child(exploration)
	_set_content_active_mode(context.mode_id)
	_set_phase(Phase.EXPLORATION, &"exploration")


func _on_exploration_event_triggered(event_id: StringName) -> void:
	if _phase != Phase.EXPLORATION or event_id != _definition.event_id:
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
	var graph := _content.graph(_definition.event_id)
	if graph == null:
		_fail("the authored slice graph is unavailable: %s" % _definition.event_id)
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
				var is_afterbeat := _definition.is_afterbeat_node(result.node_id)
				if is_afterbeat:
					_confirm_guard_frames = AFTERBEAT_RELEASE_FRAMES
				_set_phase(
					Phase.EVENT_LINE,
					&"replay_afterbeat" if _is_replay and is_afterbeat else (
						&"afterbeat" if is_afterbeat else (&"replay_dialogue" if _is_replay else &"dialogue")
					)
				)
			elif result.choice != null:
				choice_control.visible = true
				_apply_choice_scale()
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
	var packed := _mode_registry.scene_for(context.mode_id)
	if packed == null:
		_fail("no presentation scene is registered for mode: %s" % context.mode_id)
		return
	var mode := packed.instantiate() as GameMode
	if mode == null:
		_fail("registered mode scene does not provide GameMode: %s" % context.mode_id)
		return
	mode.configure(context)
	mode.call(
		"configure_fixture",
		_profile.profile_id,
		_current_locale(),
		&"",
		_is_reduced_motion(),
		_is_safe_flash()
	)
	if _fixture_ui_scale_percent > 0:
		mode.set_ui_scale_fixture(_fixture_ui_scale_percent)
	if mode is TimeGridServiceMode:
		(mode as TimeGridServiceMode).configure_assists(_tea_assists())
	elif mode is TeaTemperatureMode:
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
	if _working_state.journal.entries.has(_definition.journal_id) and not _working_state.journal.entries[_definition.journal_id].is_read:
		var marked := GameCommandDispatcher.new().dispatch(
			_working_state,
			MarkJournalEntryReadCommand.new(_definition.journal_id)
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
	if not source is GameState or _definition.event_id not in source.journal.replay_event_ids:
		_fail("the completed event is not unlocked for Journal replay")
		return
	_working_state = source
	_replay_source_canonical = GameStateCodec.new().canonical_state(source)
	# A Journal replay is its own acceptance session. Reusing the day-session record
	# array here retained every phase record across repeated replays.
	_telemetry.begin_session(
		source.profile_id,
		_content.report.content_revision,
		_content.report.content_hash
	)
	_start_authored_event(true)


func _finish_replay() -> void:
	var current: Variant = _kernel.call("state_snapshot")
	if not current is GameState or GameStateCodec.new().canonical_state(current) != _replay_source_canonical:
		_fail("Journal replay mutated the active save")
		return
	_telemetry.complete_session(-1, true)
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
	context.visible_character_ids = _definition.visible_character_ids.duplicate()
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
	if next_phase != _phase and next_phase == Phase.JOURNAL:
		_large_text_page = 0
	_phase = next_phase
	if music_player != null:
		music_player.set_dialogue_ducked(next_phase in [Phase.EVENT_LINE, Phase.EVENT_CHOICE])
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
	_large_text_page = 0
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
	_draw_header(_definition.invitation_header_key, foreground, background)
	if ui_scale_percent() > 100:
		_draw_invitation_art(Rect2(24, 58, 70, 34), foreground, background)
		_draw_wrapped(_definition.invitation_body_key, Rect2(105, 45, 190, 105), 6)
		_draw_footer(_definition.invitation_confirm_key, foreground, background)
		return
	_draw_invitation_art(Rect2(24, 55, 118, 62), foreground, background)
	_draw_wrapped(_definition.invitation_body_key, Rect2(158, 56, 136, 55), 4)
	_draw_footer(_definition.invitation_confirm_key, foreground, background)


func _draw_world_map(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(_definition.map_header_key, foreground, background)
	if ui_scale_percent() > 100:
		draw_rect(Rect2(16, 45, 122, 96), foreground, false, 1.0)
		for point: Vector2 in [Vector2(35, 73), Vector2(55, 119), Vector2(78, 61), Vector2(106, 108), Vector2(124, 76)]:
			draw_rect(Rect2(point, Vector2(3, 3)), foreground)
		draw_line(Vector2(36, 74), Vector2(78, 62), foreground, 1.0)
		draw_line(Vector2(78, 62), Vector2(106, 109), foreground, 1.0)
		var large_marker := Vector2(78, 62) if _definition.map_marker.x < 130.0 else Vector2(106, 109)
		draw_circle(large_marker, 7, foreground)
		draw_circle(large_marker, 4, background)
		var large_location := _content.location(_definition.location_id)
		var large_location_name := large_location.display_name(_current_locale()) if large_location != null else ""
		_draw_text(large_location_name, Vector2(146, 61), 158, HORIZONTAL_ALIGNMENT_CENTER, _body_font_size())
		_draw_wrapped(_definition.map_body_key, Rect2(146, 68, 158, 70), 4)
		_draw_footer(_definition.map_confirm_key, foreground, background)
		return
	draw_rect(Rect2(14, 39, 190, 114), foreground, false, 1.0)
	for point: Vector2 in [Vector2(42, 71), Vector2(72, 121), Vector2(109, 57), Vector2(155, 105), Vector2(190, 73)]:
		draw_rect(Rect2(point, Vector2(3, 3)), foreground)
	draw_line(Vector2(43, 72), Vector2(109, 58), foreground, 1.0)
	draw_line(Vector2(109, 58), Vector2(156, 106), foreground, 1.0)
	draw_line(Vector2(156, 106), Vector2(191, 74), foreground, 1.0)
	draw_circle(_definition.map_marker, 8, foreground)
	draw_circle(_definition.map_marker, 5, background)
	draw_line(_definition.map_marker + Vector2(0, -9), _definition.map_marker + Vector2(0, 9), foreground, 1.0)
	draw_line(_definition.map_marker + Vector2(-9, 0), _definition.map_marker + Vector2(9, 0), foreground, 1.0)
	var location := _content.location(_definition.location_id)
	var location_name := location.display_name(_current_locale()) if location != null else ""
	_draw_text(location_name, Vector2(207, 58), 98, HORIZONTAL_ALIGNMENT_CENTER, 6)
	_draw_wrapped(_definition.map_body_key, Rect2(206, 72, 100, 62), 5)
	_draw_footer(_definition.map_confirm_key, foreground, background)


func _draw_event(foreground: Color, background: Color) -> void:
	var is_afterbeat := _event_result != null and _definition.is_afterbeat_node(_event_result.node_id)
	var node_id := _event_result.node_id if _event_result != null else &""
	_draw_event_stage(_definition.stage_component(node_id), foreground, background)
	if _show_backlog:
		_draw_backlog(foreground, background)
		return
	if _phase == Phase.EVENT_CHOICE:
		draw_rect(Rect2(14, 5, 292, 25), background)
		draw_rect(Rect2(14, 5, 292, 25), foreground, false, 2.0)
		_draw_text(_ui(&"ui.dialogue.choose_intent"), Vector2(22, 21), 276, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
		var choice_footer := "%s %s  %s" % [
			input_axis_binding(GameInput.MOVE_UP, GameInput.MOVE_DOWN),
			_ui(&"ui.common.select"),
			input_hint(GameInput.CONFIRM, _ui(&"ui.common.confirm")),
		]
		draw_rect(Rect2(14, 160, 292, 16), background)
		draw_rect(Rect2(14, 160, 292, 16), foreground, false, 1.0)
		_draw_text(choice_footer, Vector2(18, 172), 284, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
		return
	if _dialogue == null or _dialogue.current == null:
		return
	var panel := (
		Rect2(8, 54, 304, 119)
		if ui_scale_percent() > 100
		else (Rect2(55, 78, 259, 95) if _current_locale() == &"ja" else Rect2(83, 95, 231, 78))
	)
	draw_rect(panel, background)
	draw_rect(panel, foreground, false, 2.0)
	var name_tag := Rect2(panel.position.x + 8, panel.position.y - 14, minf(140.0, panel.size.x - 16.0), 16)
	draw_rect(name_tag, background)
	draw_rect(name_tag, foreground, false, 1.0)
	_draw_text(
		_dialogue.current.speaker_name,
		name_tag.position + Vector2(4, 12),
		name_tag.size.x - 8,
		HORIZONTAL_ALIGNMENT_LEFT,
		_body_font_size()
	)
	var text_width := panel.size.x - 20
	var lines := PixelTextWrapper.wrap(
		_dialogue.current.visible_text(),
		_font(),
		text_width,
		_body_font_size(),
		_current_locale(),
		4 if ui_scale_percent() > 100 or _current_locale() == &"ja" else 3
	)
	for index: int in range(lines.size()):
		_draw_text(
			lines[index],
			panel.position + Vector2(10, 25 + index * _body_line_height()),
			text_width,
			HORIZONTAL_ALIGNMENT_LEFT,
			_body_font_size()
		)
	var control_y := panel.position.y + panel.size.y - 5
	if is_afterbeat:
		_draw_text(input_hint(GameInput.CONFIRM, _ui(&"ui.common.next")), Vector2(panel.position.x + 8, control_y), panel.size.x - 16, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
	else:
		var auto_key := &"ui.dialogue.auto_on" if _dialogue.auto_mode else &"ui.dialogue.auto_off"
		var inner_width := floori(panel.size.x - 16)
		var auto_width := floori(inner_width * 0.35)
		var next_width := floori(inner_width * 0.27)
		var log_width := inner_width - auto_width - next_width
		var control_x := floori(panel.position.x + 8)
		_draw_text(input_hint(GameInput.FOCUS, _ui(auto_key)), Vector2(control_x, control_y), auto_width, HORIZONTAL_ALIGNMENT_LEFT, _chrome_font_size())
		_draw_text(input_hint(GameInput.CONFIRM, _ui(&"ui.common.next")), Vector2(control_x + auto_width, control_y), next_width, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
		_draw_text(input_hint(GameInput.JOURNAL, _ui(&"ui.dialogue.backlog")), Vector2(control_x + auto_width + next_width, control_y), log_width, HORIZONTAL_ALIGNMENT_RIGHT, _chrome_font_size())


func _draw_reward(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(_definition.reward_header_key, foreground, background)
	if ui_scale_percent() > 100:
		draw_rect(Rect2(22, 48, 276, 46), foreground, false, 1.0)
		_draw_reward_icon(Vector2(34, 60), foreground)
		_draw_text(_ui(&"ui.slice.reward.keepsake"), Vector2(72, 63), 214, HORIZONTAL_ALIGNMENT_LEFT, _chrome_font_size())
		_draw_wrapped(_definition.reward_item_name_key, Rect2(72, 64, 214, 27), 1)
		draw_rect(Rect2(22, 98, 276, 44), foreground, false, 1.0)
		_draw_journal_mark(Vector2(34, 106), foreground)
		_draw_text(_ui(&"ui.slice.reward.journal_added"), Vector2(72, 112), 214, HORIZONTAL_ALIGNMENT_LEFT, _chrome_font_size())
		var large_title := _resolver.resolve(_journal_key("title"), _current_locale()).text
		_draw_text(large_title, Vector2(72, 135), 214, HORIZONTAL_ALIGNMENT_LEFT, _body_font_size())
		_draw_footer(_definition.reward_confirm_key, foreground, background)
		return
	draw_rect(Rect2(22, 49, 130, 92), foreground, false, 1.0)
	_draw_reward_icon(Vector2(72, 64), foreground)
	_draw_text(_ui(&"ui.slice.reward.keepsake"), Vector2(30, 105), 114, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
	_draw_wrapped(_definition.reward_item_name_key, Rect2(30, 109, 114, 28), 2)
	draw_rect(Rect2(160, 49, 138, 92), foreground, false, 1.0)
	_draw_journal_mark(Vector2(209, 60), foreground)
	_draw_text(_ui(&"ui.slice.reward.journal_added"), Vector2(168, 103), 122, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
	var title_lines := PixelTextWrapper.wrap(
		_resolver.resolve(_journal_key("title"), _current_locale()).text,
		_font(),
		122,
		_body_font_size(),
		_current_locale(),
		2
	)
	for index: int in range(title_lines.size()):
		_draw_text(title_lines[index], Vector2(168, 119 + index * _body_line_height()), 122, HORIZONTAL_ALIGNMENT_CENTER, _body_font_size())
	_draw_footer(_definition.reward_confirm_key, foreground, background)


func _draw_day_end(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.day_end.header", foreground, background)
	for x: int in range(18, 302, 14):
		draw_line(Vector2(x, 116), Vector2(x + 8, 105), foreground, 1.0)
	draw_circle(Vector2(160, 77), 19, foreground)
	draw_circle(Vector2(160, 77), 14, background)
	_draw_wrapped(&"ui.slice.day_end.body", Rect2(30, 119, 260, 30), 2)
	_draw_footer(&"ui.slice.day_end.confirm", foreground, background)


func _draw_journal(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.journal.header", foreground, background)
	draw_rect(Rect2(18, 44, 284, 100), foreground, false, 2.0)
	_draw_text(_resolver.resolve(_journal_key("title"), _current_locale()).text, Vector2(30, 61), 260, HORIZONTAL_ALIGNMENT_CENTER, _body_font_size())
	var journal_body := _resolver.resolve(_journal_key("body"), _current_locale()).text
	var maximum_lines := 12 if ui_scale_percent() > 100 else 4
	var lines := PixelTextWrapper.wrap(journal_body, _font(), 260, _body_font_size(), _current_locale(), maximum_lines)
	var first_line := _large_text_page * 3 if ui_scale_percent() > 100 else 0
	var visible_lines: Array[String] = []
	if ui_scale_percent() > 100:
		for line_index: int in range(first_line, mini(first_line + 3, lines.size())):
			visible_lines.append(lines[line_index])
	else:
		visible_lines.assign(lines)
	for index: int in range(visible_lines.size()):
		_draw_text(visible_lines[index], Vector2(30, (80 if ui_scale_percent() > 100 else 79) + index * _body_line_height()), 260, HORIZONTAL_ALIGNMENT_CENTER, _body_font_size())
	if ui_scale_percent() > 100:
		var pages := maxi(1, ceili(lines.size() / 3.0))
		_large_text_page = clampi(_large_text_page, 0, pages - 1)
		var page_hint := "%s %s  %d/%d" % [
			input_axis_binding(GameInput.MOVE_UP, GameInput.MOVE_DOWN),
			_ui(&"ui.input.page"),
			_large_text_page + 1,
			pages,
		]
		_draw_text(_ui(&"ui.slice.journal.read_only_short"), Vector2(30, 127), 260, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
		_draw_text(page_hint, Vector2(30, 141), 260, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
	if ui_scale_percent() == 100:
		draw_rect(Rect2(27, 125, 266, 15), foreground, false, 1.0)
		_draw_text(_ui(&"ui.slice.journal.replay_body"), Vector2(32, 137), 256, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())
	_draw_footer(&"ui.slice.journal.confirm", foreground, background)


func _draw_replay_complete(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(&"ui.slice.replay_complete.header", foreground, background)
	_draw_reward_icon(Vector2(145, 69), foreground)
	_draw_wrapped(&"ui.slice.replay_complete.body", Rect2(50, 112, 220, 24), 2)
	_draw_footer(&"ui.slice.replay_complete.confirm", foreground, background)


func _draw_complete(foreground: Color, background: Color) -> void:
	_draw_frame(foreground)
	_draw_header(_definition.complete_header_key, foreground, background)
	_draw_wrapped(_definition.complete_body_key, Rect2(44, 78, 232, 45), 4)
	_draw_footer(_definition.complete_confirm_key, foreground, background)


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
	var first := maxi(0, entries.size() - (6 if _current_locale() == &"ja" else 10))
	for index: int in range(first, entries.size()):
		var text := entries[index].render(_resolver, _current_locale())
		for line: String in PixelTextWrapper.wrap(text, _font(), 286, _body_font_size(), _current_locale(), 2):
			_draw_text(line, Vector2(17, y), 286, HORIZONTAL_ALIGNMENT_LEFT, _body_font_size())
			y += _body_line_height()
			if y > 157:
				break
	_draw_text(_ui(&"ui.slice.backlog.close"), Vector2(13, 169), 294)


func _draw_event_stage(component_id: StringName, foreground: Color, background: Color) -> void:
	match component_id:
		&"shrine_afterbeat":
			_draw_afterbeat_stage(foreground, background)
		&"mansion_clock":
			_draw_mansion_clock_stage(foreground, background)
		&"mansion_afterbeat":
			_draw_mansion_afterbeat_stage(foreground, background)
		&"mansion_library":
			_draw_mansion_library_stage(foreground, background)
		&"mansion_balcony_public", &"mansion_balcony_private":
			_draw_mansion_balcony_stage(component_id == &"mansion_balcony_private", foreground, background)
		&"mountain_report", &"mountain_boundary", &"mountain_route", &"mountain_new_frame":
			_draw_mountain_report_stage(component_id, foreground, background)
		&"mountain_patrol":
			_draw_mountain_patrol_stage(foreground, background)
		&"mountain_camera_lowered":
			_draw_mountain_camera_lowered_stage(foreground, background)
		_:
			_draw_shrine_stage(foreground, background)


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


func _draw_afterbeat_stage(foreground: Color, background: Color) -> void:
	draw_line(Vector2(0, 99), Vector2(320, 99), foreground, 1.0)
	draw_rect(Rect2(13, 71, 34, 19), foreground, false, 2.0)
	draw_line(Vector2(18, 94), Vector2(42, 94), foreground, 1.0)
	_draw_unpaired_cup(Vector2(92, 74), foreground)
	draw_line(Vector2(132, 84), Vector2(150, 84), foreground, 1.0)


func _draw_mansion_clock_stage(foreground: Color, background: Color) -> void:
	for y: int in range(8, 93, 16):
		for x: int in range(8 + posmod(y / 16, 2) * 12, 320, 24):
			draw_rect(Rect2(x, y, 12, 8), foreground, false, 1.0)
	draw_line(Vector2(0, 99), Vector2(320, 99), foreground, 2.0)
	draw_rect(Rect2(18, 42, 5, 58), foreground)
	draw_rect(Rect2(137, 42, 5, 58), foreground)
	draw_circle(Vector2(80, 52), 19, foreground)
	draw_circle(Vector2(80, 52), 15, background)
	draw_line(Vector2(80, 52), Vector2(80, 40), foreground, 2.0)
	draw_line(Vector2(80, 52), Vector2(91, 57), foreground, 2.0)
	draw_rect(Rect2(164, 78, 62, 16), foreground, false, 2.0)
	draw_circle(Vector2(181, 72), 5, foreground, false, 1.0)
	draw_rect(Rect2(204, 66, 10, 11), foreground, false, 1.0)


func _draw_mansion_afterbeat_stage(foreground: Color, background: Color) -> void:
	draw_line(Vector2(0, 99), Vector2(320, 99), foreground, 1.0)
	draw_circle(Vector2(55, 61), 15, foreground)
	draw_circle(Vector2(55, 61), 12, background)
	draw_line(Vector2(55, 61), Vector2(55, 51), foreground, 1.0)
	draw_rect(Rect2(93, 62, 58, 30), foreground, false, 2.0)
	for y: int in [69, 76, 83]:
		draw_line(Vector2(101, y), Vector2(142 if y < 83 else 129, y), foreground, 1.0)
	draw_rect(Rect2(162, 79, 46, 14), foreground, false, 1.0)
	draw_line(Vector2(166, 86), Vector2(204, 86), foreground, 1.0)


func _draw_mansion_library_stage(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(7, 13, 306, 87), foreground, false, 2.0)
	for shelf_y: int in [38, 65, 92]:
		draw_line(Vector2(13, shelf_y), Vector2(307, shelf_y), foreground, 2.0)
	for book_x: int in range(17, 305, 9):
		var height := 15 + posmod(book_x, 4) * 3
		draw_rect(Rect2(book_x, 37 - height, 5, height), foreground, false, 1.0)
	draw_circle(Vector2(242, 65), 27, foreground)
	draw_circle(Vector2(242, 67), 21, background)
	draw_rect(Rect2(218, 67, 49, 33), background)
	draw_rect(Rect2(218, 67, 49, 33), foreground, false, 1.0)


func _draw_mansion_balcony_stage(is_private: bool, foreground: Color, background: Color) -> void:
	draw_circle(Vector2(252, 30), 18, foreground)
	draw_circle(Vector2(246, 25), 18, background)
	draw_line(Vector2(0, 100), Vector2(320, 100), foreground, 2.0)
	for x: int in range(10, 320, 22):
		draw_rect(Rect2(x, 82, 3, 18), foreground)
	draw_line(Vector2(0, 81), Vector2(320, 81), foreground, 2.0)
	var figure_x := 72.0 if is_private else 152.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(figure_x - 11, 81), Vector2(figure_x - 8, 52), Vector2(figure_x, 42),
		Vector2(figure_x + 8, 52), Vector2(figure_x + 11, 81),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(figure_x - 18, 46), Vector2(figure_x - 7, 39), Vector2(figure_x - 5, 51),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(figure_x + 18, 46), Vector2(figure_x + 7, 39), Vector2(figure_x + 5, 51),
	]), foreground)
	if is_private:
		draw_line(Vector2(116, 56), Vector2(212, 56), foreground, 1.0)
	else:
		draw_rect(Rect2(27, 18, 54, 45), foreground, false, 2.0)
		draw_rect(Rect2(239, 18, 54, 45), foreground, false, 2.0)


func _draw_mountain_report_stage(component_id: StringName, foreground: Color, background: Color) -> void:
	_draw_mountain_depths(foreground, background)
	_draw_aya_reporter(Vector2(39, 45), component_id == &"mountain_report", foreground, background)
	match component_id:
		&"mountain_boundary":
			draw_rect(Rect2(11, 15, 29, 19), foreground, false, 1.0)
			draw_line(Vector2(16, 21), Vector2(35, 21), foreground, 1.0)
			draw_line(Vector2(16, 27), Vector2(29, 27), foreground, 1.0)
		&"mountain_route":
			for index: int in range(4):
				var start := Vector2(10, 18 + index * 7)
				draw_line(start, start + Vector2(27, 5 if index % 2 == 0 else -4), foreground, 1.0)
		&"mountain_new_frame":
			draw_rect(Rect2(8, 12, 33, 25), foreground, false, 2.0)
			draw_line(Vector2(14, 31), Vector2(35, 18), foreground, 1.0)
			draw_circle(Vector2(30, 20), 3, foreground, false, 1.0)


func _draw_mountain_patrol_stage(foreground: Color, background: Color) -> void:
	_draw_mountain_depths(foreground, background)
	# Aya keeps the frame raised while Momiji's shield marks the closed printed route.
	_draw_aya_reporter(Vector2(38, 45), true, foreground, background)
	draw_circle(Vector2(15, 25), 10, foreground)
	draw_circle(Vector2(15, 25), 7, background)
	draw_line(Vector2(9, 19), Vector2(21, 31), foreground, 1.0)
	draw_line(Vector2(21, 19), Vector2(9, 31), foreground, 1.0)
	draw_rect(Rect2(66, 48, 4, 50), foreground)
	draw_rect(Rect2(109, 48, 4, 50), foreground)
	draw_line(Vector2(68, 57), Vector2(111, 76), foreground, 3.0)
	draw_line(Vector2(68, 76), Vector2(111, 57), foreground, 3.0)


func _draw_mountain_camera_lowered_stage(foreground: Color, background: Color) -> void:
	_draw_mountain_depths(foreground, background)
	_draw_aya_reporter(Vector2(39, 45), false, foreground, background)
	# Silent regional network: Hatate's frame, Momiji's shield,
	# Nitori's pipe, and Sanae's gohei. These are context, not speakers.
	draw_rect(Rect2(116, 21, 19, 14), foreground, false, 1.0)
	draw_circle(Vector2(126, 28), 3, foreground, false, 1.0)
	draw_circle(Vector2(151, 28), 8, foreground, false, 1.0)
	draw_line(Vector2(147, 22), Vector2(155, 34), foreground, 1.0)
	draw_line(Vector2(155, 22), Vector2(147, 34), foreground, 1.0)
	draw_line(Vector2(170, 19), Vector2(170, 36), foreground, 3.0)
	draw_line(Vector2(170, 20), Vector2(185, 20), foreground, 3.0)
	draw_line(Vector2(183, 20), Vector2(183, 31), foreground, 3.0)
	draw_line(Vector2(204, 17), Vector2(204, 37), foreground, 2.0)
	draw_line(Vector2(198, 22), Vector2(210, 22), foreground, 1.0)
	draw_line(Vector2(198, 28), Vector2(210, 28), foreground, 1.0)


func _draw_mountain_depths(foreground: Color, background: Color) -> void:
	# FAR summit, MID waterfall, PLAY ledge, and FRONT rope line.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 65), Vector2(45, 25), Vector2(76, 46), Vector2(119, 12),
		Vector2(164, 57), Vector2(215, 23), Vector2(272, 63), Vector2(320, 34),
		Vector2(320, 101), Vector2(0, 101),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, 65), Vector2(46, 33), Vector2(77, 54), Vector2(119, 21),
		Vector2(162, 66), Vector2(215, 32), Vector2(271, 72), Vector2(320, 44),
		Vector2(320, 93), Vector2(0, 93),
	]), background)
	for x: int in [224, 229, 236, 242]:
		draw_line(Vector2(x, 31), Vector2(x, 94), foreground, 2.0 if x in [224, 242] else 1.0)
	for x: int in range(6, 318, 13):
		draw_line(Vector2(x, 95), Vector2(x + 8, 88), foreground, 1.0)
	draw_line(Vector2(0, 99), Vector2(320, 99), foreground, 2.0)
	draw_line(Vector2(3, 72), Vector2(111, 50), foreground, 1.0)
	draw_line(Vector2(111, 50), Vector2(177, 72), foreground, 1.0)


func _draw_aya_reporter(origin: Vector2, camera_raised: bool, foreground: Color, background: Color) -> void:
	draw_circle(origin, 10, foreground)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-13, -7), origin + Vector2(0, -16), origin + Vector2(13, -7),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-8, 9), origin + Vector2(-15, 43), origin + Vector2(15, 43), origin + Vector2(8, 9),
	]), foreground)
	for side: int in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(side * 7, 15), origin + Vector2(side * 23, 7),
			origin + Vector2(side * 16, 31),
		]), foreground)
	var camera_origin := origin + (Vector2(-8, -2) if camera_raised else Vector2(-22, 29))
	draw_rect(Rect2(camera_origin, Vector2(16, 11)), background)
	draw_rect(Rect2(camera_origin, Vector2(16, 11)), foreground, false, 2.0)
	draw_circle(camera_origin + Vector2(8, 5), 3, foreground, false, 1.0)
	if not camera_raised:
		draw_line(origin + Vector2(-8, 10), camera_origin + Vector2(2, 1), foreground, 1.0)


func _draw_frame(foreground: Color) -> void:
	draw_rect(Rect2(8, 8, 304, 164), foreground, false, 2.0)


func _draw_header(key: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(17, 18, 286, 23), background)
	draw_rect(Rect2(17, 18, 286, 23), foreground, false, 1.0)
	_draw_text(_ui(key), Vector2(23, 34), 274, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())


func _draw_footer(key: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(16, 149, 288, 18), background)
	draw_rect(Rect2(16, 149, 288, 18), foreground, false, 1.0)
	var footer := input_hint(GameInput.CONFIRM, _ui(key))
	if key == &"ui.slice.journal.confirm":
		footer = "%s   %s" % [
			footer,
			input_hint(GameInput.CANCEL, _ui(&"ui.slice.journal.finish")),
		]
	_draw_text(footer, Vector2(21, 163), 278, HORIZONTAL_ALIGNMENT_CENTER, _chrome_font_size())


func _draw_wrapped(key: StringName, rect: Rect2, maximum_lines: int) -> void:
	var lines := PixelTextWrapper.wrap(_ui(key), _font(), rect.size.x, _body_font_size(), _current_locale(), maximum_lines)
	for index: int in range(lines.size()):
		_draw_text(
			lines[index],
			rect.position + Vector2(0, _body_font_size() + index * _body_line_height()),
			rect.size.x,
			HORIZONTAL_ALIGNMENT_CENTER,
			_body_font_size()
		)


func _draw_text(
	text: String,
	position: Vector2,
	width: float,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	font_size: int = 0
) -> void:
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	var resolved_size := _body_font_size() if font_size <= 0 else font_size
	if _current_locale() == &"ja":
		resolved_size = maxi(10, resolved_size)
	draw_string(_font(), position, text, alignment, width, resolved_size, foreground)


func _draw_invitation_art(rect: Rect2, foreground: Color, background: Color) -> void:
	draw_rect(rect, foreground, false, 2.0)
	if _definition.invitation_component == &"newspaper":
		var paper := Rect2(rect.position + Vector2(9, 6), rect.size - Vector2(18, 12))
		draw_rect(paper, foreground, false, 1.0)
		draw_line(paper.position + Vector2(4, 6), Vector2(paper.end.x - 4, paper.position.y + 6), foreground, 2.0)
		var photo := Rect2(paper.position + Vector2(4, 11), Vector2(paper.size.x * 0.43, paper.size.y - 15))
		draw_rect(photo, foreground, false, 1.0)
		draw_line(photo.position + Vector2(3, photo.size.y - 3), photo.end - Vector2(3, 3), foreground, 1.0)
		for line_index: int in range(3):
			var y := paper.position.y + 14 + line_index * 6
			draw_line(Vector2(photo.end.x + 5, y), Vector2(paper.end.x - 4, y), foreground, 1.0)
		return
	if _definition.invitation_component == &"schedule":
		var sheet := Rect2(rect.position + Vector2(18, 7), rect.size - Vector2(36, 14))
		draw_rect(sheet, foreground, false, 1.0)
		for line_index: int in range(3):
			var y := sheet.position.y + 6 + line_index * 7
			draw_rect(Rect2(sheet.position.x + 4, y - 2, 3, 3), foreground, false, 1.0)
			draw_line(Vector2(sheet.position.x + 11, y), Vector2(sheet.end.x - 4, y), foreground, 1.0)
		return
	var left := rect.position + Vector2(10, rect.size.y * 0.28)
	var right := rect.end - Vector2(10, rect.size.y * 0.28)
	var center := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.7)
	draw_line(left, right, foreground, 1.0)
	draw_colored_polygon(PackedVector2Array([left, center, right]), foreground)
	draw_colored_polygon(PackedVector2Array([left + Vector2(4, 2), center - Vector2(0, 3), right + Vector2(-4, 2)]), background)


func _draw_reward_icon(origin: Vector2, foreground: Color) -> void:
	match _definition.reward_component:
		&"checklist":
			_draw_checklist(origin, foreground)
		&"caption":
			_draw_unprinted_caption(origin, foreground)
		_:
			_draw_unpaired_cup(origin, foreground)


func _draw_unpaired_cup(origin: Vector2, foreground: Color) -> void:
	draw_rect(Rect2(origin, Vector2(22, 14)), foreground, false, 2.0)
	draw_rect(Rect2(origin + Vector2(21, 3), Vector2(7, 7)), foreground, false, 2.0)
	draw_line(origin + Vector2(3, 18), origin + Vector2(19, 18), foreground, 2.0)


func _draw_checklist(origin: Vector2, foreground: Color) -> void:
	draw_rect(Rect2(origin, Vector2(27, 31)), foreground, false, 2.0)
	for index: int in range(3):
		var y := origin.y + 8 + index * 7
		draw_rect(Rect2(origin.x + 5, y - 3, 4, 4), foreground, false, 1.0)
		if index < 2:
			draw_line(Vector2(origin.x + 6, y - 1), Vector2(origin.x + 8, y + 1), foreground, 1.0)
		draw_line(Vector2(origin.x + 12, y - 1), Vector2(origin.x + 22, y - 1), foreground, 1.0)


func _draw_unprinted_caption(origin: Vector2, foreground: Color) -> void:
	draw_rect(Rect2(origin, Vector2(31, 24)), foreground, false, 2.0)
	draw_rect(Rect2(origin + Vector2(4, 4), Vector2(10, 8)), foreground, false, 1.0)
	draw_line(origin + Vector2(17, 5), origin + Vector2(27, 5), foreground, 1.0)
	draw_line(origin + Vector2(17, 10), origin + Vector2(25, 10), foreground, 1.0)
	draw_line(origin + Vector2(4, 18), origin + Vector2(27, 18), foreground, 2.0)
	draw_line(origin + Vector2(6, 16), origin + Vector2(25, 20), foreground, 1.0)


func _draw_journal_mark(origin: Vector2, foreground: Color) -> void:
	draw_rect(Rect2(origin, Vector2(28, 28)), foreground, false, 2.0)
	draw_line(origin + Vector2(6, 7), origin + Vector2(22, 7), foreground, 1.0)
	draw_line(origin + Vector2(6, 13), origin + Vector2(22, 13), foreground, 1.0)
	draw_line(origin + Vector2(6, 19), origin + Vector2(18, 19), foreground, 1.0)


func _body_font_size() -> int:
	return scaled_ui_pixels(12 if _current_locale() == &"ja" else 8)


func _chrome_font_size() -> int:
	return scaled_ui_pixels(10 if _current_locale() == &"ja" else 7)


func _body_line_height() -> int:
	return _body_font_size() + (4 if ui_scale_percent() > 100 else 2)


func _font() -> Font:
	return _japanese_font if _current_locale() == &"ja" else _latin_font


func _journal_large_page_count() -> int:
	if _resolver == null:
		return 1
	var body := _resolver.resolve(_journal_key("body"), _current_locale()).text
	var lines := PixelTextWrapper.wrap(body, _font(), 260, _body_font_size(), _current_locale(), 12)
	return maxi(1, ceili(lines.size() / 3.0))


func large_text_page_for_test() -> int:
	return _large_text_page


func _journal_key(suffix: String) -> StringName:
	return StringName("%s.%s" % [_definition.journal_id, suffix])


func _ui(key: StringName, arguments: Dictionary = {}) -> String:
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null:
		return localization.formatted_text(key, arguments)
	return NamedTextFormatter.new().format(_catalog.text(key, _current_locale()), arguments).text
