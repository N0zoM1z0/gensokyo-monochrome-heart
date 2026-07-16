class_name ExplorationMode
extends GameMode
## Playable two-room Hakurei Shrine spot backed by typed, centrally queried interactions.

signal interaction_observed(target_id: StringName, observation_key: StringName)
signal event_triggered(event_id: StringName)

const ACTION_CONTRACT := [
	"move",
	"confirm",
	"cancel",
	"focus",
	"companion",
	"journal",
]

@export var fixture_show_focus: bool = false
@export var fixture_show_companion: bool = false
@export var fixture_complete_objective: bool = false
@export_enum("hakurei_veranda", "mansion_service", "mountain_trail") var spot_component := "hakurei_veranda"
@export var fixture_start_x: float = -1.0
var exploration_context: ExplorationModeContext
var spot_definition := HakureiVerandaSpotFactory.build()
var motor := ExplorationMotor.new()
var motor_state := ExplorationMotorState.new()
var interaction_registry := ExplorationInteractionRegistry.new()
var objective_tracker := ExplorationObjectiveTracker.new()
var trigger_registry := ExplorationTriggerRegistry.new()
var float_preview := IntuitiveFloatPreview.new()
var hint_timer := ExplorationHintTimer.new()

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _resolver: LocalizedContentResolver
var _latin_font: Font
var _japanese_font: Font
var _current_interactable: ExplorationInteractable
var _fixed_accumulator: float = 0.0
var _hop_queued: bool = false
var _focus_latched: bool = false
var _companion_latched: bool = false
var _camera_x: float = 0.0
var _note_seconds: float = 0.0
var _sfx_seconds: float = 0.0
var _note_text := ""
var _sfx_text := ""
var _header_text := ""
var _objective_text := ""
var _footer_text := ""
var _hint_text := ""
var _companion_text := ""
var _hint_visible: bool = false
var _marisa_entered: bool = false
var _triggered_event_id: StringName

@onready var prompt_chip: PromptChip = %PromptChip
@onready var sfx_player: ProceduralSfxPlayer = %ProceduralSfxPlayer


func _ready() -> void:
	InputMapInstaller.install_defaults()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_catalog.load_default()
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var content_db := get_node_or_null("/root/ContentDB")
	var content: ContentRepository = content_db.snapshot() if content_db != null else null
	if content == null:
		content = ContentRepository.new()
		content.load_sources()
	_resolver = LocalizedContentResolver.new(content)
	sfx_player.cue_played.connect(_on_sfx_cue_played)
	if exploration_context == null:
		spot_definition = _build_spot_definition()
		configure(_default_context())
	else:
		# Slice coordinators configure the mode before it enters the tree. Rebuild
		# once the resolver and onready presentation nodes are available.
		_reset_spot()
	ready_for_input.emit()


func configure(context: ModeContext) -> void:
	super.configure(context)
	if context is ExplorationModeContext:
		exploration_context = context
	else:
		exploration_context = _default_context()
	_reset_spot()


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
	# Reduced motion removes animated traces; safe flash retains the same static cues.
	if is_reduced_motion or is_safe_flash:
		_companion_latched = false
	_reset_spot()


func _physics_process(delta: float) -> void:
	if is_suspended or motor_state == null:
		return
	_fixed_accumulator = minf(_fixed_accumulator + delta, ExplorationMotor.FIXED_DELTA * 4.0)
	while _fixed_accumulator >= ExplorationMotor.FIXED_DELTA:
		var sample := ExplorationMotorInput.new()
		sample.horizontal_axis = Input.get_axis(GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT)
		sample.hop_pressed = _hop_queued
		sample.focus_held = Input.is_action_pressed(GameInput.FOCUS) or _focus_latched
		sample.float_held = (
			(Input.is_action_pressed(GameInput.COMPANION) or _companion_latched)
			and exploration_context.companion_skill_enabled
		)
		_hop_queued = false
		_step_motor(sample)
		_fixed_accumulator -= ExplorationMotor.FIXED_DELTA
	queue_redraw()


func _process(delta: float) -> void:
	_note_seconds = maxf(0.0, _note_seconds - maxf(0.0, delta))
	_sfx_seconds = maxf(0.0, _sfx_seconds - maxf(0.0, delta))
	if hint_timer.tick(delta):
		_hint_visible = true
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	match action:
		GameInput.CONFIRM:
			if _current_interactable != null:
				_interact(_current_interactable)
			else:
				_hop_queued = true
			return true
		GameInput.MOVE_UP:
			_hop_queued = true
			return true
		GameInput.FOCUS:
			_focus_latched = not _focus_latched
			queue_redraw()
			return true
		GameInput.COMPANION:
			if exploration_context.companion_skill_enabled:
				_companion_latched = not _companion_latched
				_refresh_float_preview()
				queue_redraw()
				return true
		GameInput.JOURNAL:
			_note_text = _objective_text
			_note_seconds = 2.0
			return true
	return false


func step_fixture(
	horizontal_axis: float,
	frames: int,
	focus_held: bool = false,
	float_held: bool = false
) -> void:
	for _frame: int in range(maxi(0, frames)):
		var sample := ExplorationMotorInput.new()
		sample.horizontal_axis = horizontal_axis
		sample.focus_held = focus_held
		sample.float_held = float_held and exploration_context.companion_skill_enabled
		_step_motor(sample)
	queue_redraw()


func interact_target_for_test(target_id: StringName) -> bool:
	var target := interaction_registry.by_id(target_id)
	if target == null:
		return false
	motor_state.position = Vector2(target.world_position.x - 22.0, motor.floor_y)
	motor_state.facing = Vector2.RIGHT
	_refresh_prompt()
	if _current_interactable == null or _current_interactable.interactable_id != target_id:
		return false
	_interact(_current_interactable)
	return true


func set_player_position_for_test(position: Vector2, facing: Vector2 = Vector2.RIGHT) -> void:
	motor_state.position = position
	motor_state.facing = facing
	_refresh_camera()
	_refresh_prompt()
	_resolve_trigger()
	queue_redraw()


func set_story_hint_delay_for_test(seconds: float) -> void:
	hint_timer.delay_seconds = maxf(0.0, seconds)


func set_companion_skill_enabled(enabled: bool) -> void:
	exploration_context.companion_skill_enabled = enabled
	float_preview.is_enabled = enabled
	if not enabled:
		_companion_latched = false
	_refresh_float_preview()


func switch_locale(next_locale: StringName) -> void:
	if next_locale not in [&"en", &"ja"]:
		return
	_locale = next_locale
	_refresh_text_cache()
	_refresh_prompt()
	queue_redraw()


func objective_complete() -> bool:
	return objective_tracker.is_complete()


func objective_step() -> int:
	return objective_tracker.current_step


func observed_ids() -> Array[StringName]:
	return objective_tracker.observed_ids.duplicate()


func current_prompt_id() -> StringName:
	return _current_interactable.interactable_id if _current_interactable != null else &""


func triggered_event_id() -> StringName:
	return _triggered_event_id


func player_position() -> Vector2:
	return motor_state.position


func hint_visible() -> bool:
	return _hint_visible


func companion_preview_visible() -> bool:
	return not float_preview.points.is_empty() and _companion_latched


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	return GameInput.first_matching(candidates, [
		GameInput.FOCUS,
		GameInput.COMPANION,
		GameInput.JOURNAL,
		GameInput.CONFIRM,
		GameInput.MOVE_UP,
		GameInput.MOVE_DOWN,
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.CANCEL,
	])


func capture_debug_state() -> Dictionary:
	var state := super.capture_debug_state()
	state.merge({
		"player_position": motor_state.position,
		"prompt_id": String(current_prompt_id()),
		"objective_step": objective_tracker.current_step,
		"objective_complete": objective_tracker.is_complete(),
		"triggered_event_id": String(_triggered_event_id),
		"registry_queries": interaction_registry.query_count,
	}, true)
	return state


func _default_context() -> ExplorationModeContext:
	var context := ExplorationModeContext.new()
	context.mode_id = spot_definition.mode_id
	context.location_id = spot_definition.location_id
	context.spot_id = spot_definition.spot_id
	context.time_slot = &"dusk"
	context.objective_id = spot_definition.objective_id
	context.companion_id = spot_definition.companion_id
	context.story_navigation_hints = true
	context.companion_skill_enabled = spot_definition.companion_id != &""
	return context


func _reset_spot() -> void:
	if exploration_context == null:
		return
	spot_definition = _build_spot_definition()
	motor = ExplorationMotor.new()
	motor.world_bounds = spot_definition.world_bounds
	motor.floor_y = spot_definition.floor_y
	motor.solid_obstacles = spot_definition.solid_obstacles.duplicate()
	motor_state = ExplorationMotorState.new()
	motor_state.position = spot_definition.start_position
	if fixture_start_x >= 0.0:
		motor_state.position.x = fixture_start_x
	interaction_registry = ExplorationInteractionRegistry.new()
	objective_tracker = ExplorationObjectiveTracker.new()
	objective_tracker.configure(exploration_context.objective_id, spot_definition.required_sequence)
	if fixture_complete_objective:
		for target_id: StringName in spot_definition.required_sequence:
			objective_tracker.observe(target_id)
	trigger_registry = ExplorationTriggerRegistry.new()
	for trigger: ExplorationEventTrigger in spot_definition.event_triggers:
		trigger_registry.register(trigger)
	float_preview = IntuitiveFloatPreview.new()
	float_preview.is_enabled = exploration_context.companion_skill_enabled
	hint_timer = ExplorationHintTimer.new()
	hint_timer.story_hints_enabled = exploration_context.story_navigation_hints
	_build_registry()
	_fixed_accumulator = 0.0
	_hop_queued = false
	_focus_latched = fixture_show_focus
	_companion_latched = fixture_show_companion and exploration_context.companion_skill_enabled
	_note_seconds = 0.0
	_sfx_seconds = 0.0
	_hint_visible = false
	_marisa_entered = false
	_triggered_event_id = &""
	_refresh_camera()
	_refresh_text_cache()
	_refresh_prompt()
	_refresh_float_preview()
	queue_redraw()


func _build_spot_definition() -> ExplorationSpotDefinition:
	return ExplorationSpotRegistry.build(StringName(spot_component))


func _build_registry() -> void:
	for interactable: ExplorationInteractable in spot_definition.interactables:
		interaction_registry.register(interactable)


func _step_motor(sample: ExplorationMotorInput) -> void:
	motor.step(motor_state, sample)
	if motor.consume_footstep(motor_state):
		sfx_player.play_cue(_sfx_cue(spot_definition.footstep_sfx_id))
	_refresh_camera()
	_refresh_prompt()
	_refresh_float_preview()
	_resolve_trigger()


func _interact(interactable: ExplorationInteractable) -> void:
	var action := interactable.action
	var progress := objective_tracker.observe(action.target_id)
	if progress.accepted_step:
		hint_timer.reset_after_progress()
		_hint_visible = false
	if progress.completed_now:
		_marisa_entered = true
		_note_text = _catalog.text(spot_definition.complete_key, _locale)
	else:
		_note_text = _catalog.text(action.observation_key, _locale)
	_note_seconds = 3.0
	interaction_observed.emit(action.target_id, action.observation_key)
	sfx_player.play_cue(_sfx_cue(action.sfx_id))
	_refresh_text_cache()
	_refresh_prompt()
	_resolve_trigger()
	queue_redraw()


func _resolve_trigger() -> void:
	var completed_id := objective_tracker.objective_id if objective_tracker.is_complete() else &""
	var trigger := trigger_registry.resolve(motor_state.position, completed_id)
	if trigger == null:
		return
	_triggered_event_id = trigger.event_id
	checkpoint_requested.emit(&"event_checkpoint")
	event_triggered.emit(trigger.event_id)


func _refresh_camera() -> void:
	_camera_x = clampf(motor_state.position.x - 160.0, 0.0, 320.0)
	_refresh_text_cache()


func _refresh_prompt() -> void:
	if prompt_chip == null:
		return
	_current_interactable = interaction_registry.nearest(
		motor_state.position - Vector2(0, 10),
		motor_state.facing
	)
	if _current_interactable == null or (_current_interactable.interactable_id == &"char.marisa_kirisame" and not _marisa_entered):
		_current_interactable = null
		prompt_chip.visible = false
		_refresh_footer_text()
		return
	var screen_position := _current_interactable.world_position - Vector2(_camera_x, 32)
	prompt_chip.position = Vector2(
		clampf(roundf(screen_position.x - 32), 4.0, 252.0),
		clampf(roundf(screen_position.y), 20.0, 142.0)
	)
	prompt_chip.size = Vector2(64, 14)
	var required := _current_interactable.interactable_id == objective_tracker.next_target_id()
	prompt_chip.configure(
		_current_interactable.action.kind,
		_current_interactable.action.prompt_key,
		_locale,
		_profile.profile_id,
		required
	)
	prompt_chip.visible = true
	_refresh_footer_text()


func _refresh_float_preview() -> void:
	float_preview.rebuild(motor_state.position, motor_state.facing)


func _refresh_text_cache() -> void:
	if _resolver == null:
		return
	var in_room := _camera_x > 180.0
	_header_text = _catalog.text(
		spot_definition.header_secondary_key if in_room else spot_definition.header_primary_key,
		_locale
	)
	var objective_key := spot_definition.complete_key if objective_tracker.is_complete() else objective_tracker.objective_id
	_objective_text = (
		_catalog.text(objective_key, _locale)
		if objective_tracker.is_complete()
		else _resolver.resolve(objective_key, _locale).text
	)
	_refresh_footer_text()
	_hint_text = _catalog.text(spot_definition.hint_key, _locale)
	_companion_text = _catalog.text(spot_definition.companion_key, _locale)


func _refresh_footer_text() -> void:
	var confirm_label_key := (
		_current_interactable.action.prompt_key
		if _current_interactable != null
		else &"ui.input.observe"
	)
	_footer_text = "  ".join([
		"%s %s" % [input_axis_binding(GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT), _catalog.text(&"ui.input.move", _locale)],
		input_hint(GameInput.CONFIRM, _catalog.text(confirm_label_key, _locale)),
		input_hint(GameInput.JOURNAL, _catalog.text(&"ui.input.journal", _locale)),
	])


func _sfx_cue(cue_id: StringName) -> ExplorationSfxCue:
	match cue_id:
		&"sfx.prop.cup":
			return ExplorationSfxCue.new(cue_id, &"ui.sfx.cup", 420.0, 0.09)
		&"sfx.door.wood":
			return ExplorationSfxCue.new(cue_id, &"ui.sfx.door", 210.0, 0.14)
		&"sfx.paper.rustle":
			return ExplorationSfxCue.new(cue_id, &"ui.sfx.paper", 520.0, 0.07)
		&"sfx.wind.gust":
			return ExplorationSfxCue.new(cue_id, &"ui.sfx.wind", 175.0, 0.18)
		&"sfx.camera.shutter":
			return ExplorationSfxCue.new(cue_id, &"ui.sfx.shutter", 840.0, 0.05)
		&"sfx.step.stone":
			return ExplorationSfxCue.new(cue_id, &"ui.sfx.stone_step", 110.0, 0.05)
		_:
			return ExplorationSfxCue.new(&"sfx.step.wood", &"ui.sfx.wood_step", 140.0, 0.06)


func _on_sfx_cue_played(_cue_id: StringName, visual_key: StringName) -> void:
	_sfx_text = _catalog.text(visual_key, _locale)
	_sfx_seconds = 0.8


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	_draw_world(foreground, background)
	_draw_hud(foreground, background)
	_draw_player(foreground, background)
	if _focus_latched or Input.is_action_pressed(GameInput.FOCUS):
		_draw_focus_traces(foreground, background)
	if _companion_latched and exploration_context.companion_skill_enabled:
		_draw_float_preview(foreground)
	_draw_feedback(foreground, background)


func _draw_world(foreground: Color, background: Color) -> void:
	match spot_definition.environment_style:
		&"mansion_service":
			_draw_mansion_world(foreground, background)
		&"mountain_trail":
			_draw_mountain_world(foreground, background)
		_:
			_draw_shrine_world(foreground, background)


func _draw_shrine_world(foreground: Color, background: Color) -> void:
	for y: int in range(22, 88, 6):
		for x: int in range(2 + floori(y / 6.0) % 2 * 3, 320, 6):
			draw_rect(Rect2(x, y, 1, 1), foreground)
	var offset := -_camera_x
	# Far tree and low shrine silhouette establish the veranda.
	_draw_tree(Vector2(28 + offset, 104), foreground, background)
	draw_colored_polygon(PackedVector2Array([
		Vector2(48 + offset, 66), Vector2(170 + offset, 29), Vector2(326 + offset, 65), Vector2(309 + offset, 73), Vector2(66 + offset, 73),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(75 + offset, 64), Vector2(171 + offset, 38), Vector2(293 + offset, 65),
	]), background)
	for pillar_x: float in [70.0, 124.0, 238.0, 292.0, 347.0, 462.0, 584.0]:
		draw_rect(Rect2(pillar_x + offset, 72, 5, 68), foreground)
	draw_rect(Rect2(48 + offset, 136, 576, 5), foreground)
	for plank_x: int in range(50, 625, 16):
		draw_line(Vector2(plank_x + offset, 137), Vector2(plank_x + offset, 140), background, 1.0)
	# Adjacent room has paper panels and a dense eave, but shares the traversable floor.
	draw_rect(Rect2(320 + offset, 54, 320, 18), foreground)
	for panel_x: int in range(328, 632, 40):
		draw_rect(Rect2(panel_x + offset, 77, 32, 55), foreground, false, 1.0)
		draw_line(Vector2(panel_x + 16 + offset, 77), Vector2(panel_x + 16 + offset, 132), foreground, 1.0)
		draw_line(Vector2(panel_x + offset, 104), Vector2(panel_x + 32 + offset, 104), foreground, 1.0)
	_draw_donation_box(Vector2(79 + offset, 129), foreground, background)
	_draw_cup(Vector2(154 + offset, 112), foreground, background)
	_draw_cushion(Vector2(205 + offset, 136), foreground, background)
	_draw_door(Vector2(300 + offset, 120), foreground, background)
	_draw_broom(Vector2(410 + offset, 129), foreground)
	_draw_reimu(Vector2(252 + offset, 130), foreground, background)
	if _marisa_entered:
		_draw_marisa(Vector2(536 + offset, 130), foreground, background)


func _draw_mansion_world(foreground: Color, background: Color) -> void:
	var offset := -_camera_x
	for tile_y: int in range(26, 137, 16):
		for tile_x: int in range(8, 632, 24):
			if posmod(floori(tile_x / 24.0) + floori(tile_y / 16.0), 2) == 0:
				draw_rect(Rect2(tile_x + offset, tile_y, 12, 8), foreground, false, 1.0)
	draw_rect(Rect2(8 + offset, 136, 616, 5), foreground)
	draw_rect(Rect2(320 + offset, 42, 304, 22), foreground)
	for pillar_x: int in [24, 174, 310, 338, 470, 610]:
		draw_rect(Rect2(pillar_x + offset, 62, 6, 76), foreground)
	_draw_clock(Vector2(118 + offset, 91), foreground, background)
	_draw_service_tray(Vector2(220 + offset, 130), foreground, background)
	_draw_door(Vector2(306 + offset, 136), foreground, background)
	draw_rect(Rect2(374 + offset, 110, 76, 28), foreground, false, 2.0)
	draw_line(Vector2(374 + offset, 118), Vector2(450 + offset, 118), foreground, 1.0)
	_draw_service_tray(Vector2(410 + offset, 112), foreground, background)
	draw_rect(Rect2(478 + offset, 112, 18, 24), foreground, false, 1.0)
	for line_y: int in [117, 122, 127]:
		draw_line(Vector2(481 + offset, line_y), Vector2(493 + offset, line_y), foreground, 1.0)
	_draw_sakuya(Vector2(552 + offset, 130), foreground, background)


func _draw_mountain_world(foreground: Color, background: Color) -> void:
	var offset := -_camera_x
	# Two large silhouettes preserve quiet sky while establishing steep elevation.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0 + offset, 136), Vector2(0 + offset, 74), Vector2(42 + offset, 31),
		Vector2(98 + offset, 136),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(356 + offset, 136), Vector2(430 + offset, 48), Vector2(508 + offset, 136),
	]), foreground)
	# The waterfall is a solid white column inside the dark cliff, never dithered.
	draw_rect(Rect2(36 + offset, 45, 13, 83), background)
	for y: int in range(49, 126, 11):
		draw_line(Vector2(39 + offset, y), Vector2(46 + offset, y + 5), foreground, 1.0)
	draw_rect(Rect2(8 + offset, 136, 616, 5), foreground)
	for x: int in range(70, 620, 42):
		draw_line(Vector2(x + offset, 137), Vector2(x + 12 + offset, 137), background, 1.0)
	# Paper, intact guardrail, rope bridge, patrol notice, and camera perch mirror
	# the typed interaction anchors in the spot packet.
	_draw_newspaper(Vector2(118 + offset, 130), foreground, background)
	for rail_x: int in [204, 222, 240]:
		draw_line(Vector2(rail_x + offset, 109), Vector2(rail_x + offset, 137), foreground, 2.0)
	draw_line(Vector2(200 + offset, 112), Vector2(244 + offset, 112), foreground, 2.0)
	for bridge_x: int in range(274, 343, 10):
		draw_line(Vector2(bridge_x + offset, 132), Vector2(bridge_x + 7 + offset, 134), foreground, 1.0)
	draw_line(Vector2(270 + offset, 113), Vector2(348 + offset, 119), foreground, 1.0)
	draw_line(Vector2(270 + offset, 132), Vector2(348 + offset, 136), foreground, 2.0)
	draw_rect(Rect2(382 + offset, 91, 25, 33), background)
	draw_rect(Rect2(382 + offset, 91, 25, 33), foreground, false, 2.0)
	for line_y: int in [98, 104, 110]:
		draw_line(Vector2(387 + offset, line_y), Vector2(402 + offset, line_y), foreground, 1.0)
	draw_line(Vector2(470 + offset, 91), Vector2(470 + offset, 137), foreground, 3.0)
	draw_rect(Rect2(456 + offset, 91, 29, 5), foreground)
	_draw_aya(Vector2(552 + offset, 130), foreground, background)
	var name_font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(
		name_font,
		Vector2(534 + offset, 88),
		_catalog.text(&"ui.exploration.mtn.aya_name", _locale),
		HORIZONTAL_ALIGNMENT_CENTER,
		36,
		_hud_font_size(),
		foreground
	)
	# Distant crow silhouettes use broad spacing and stay out of the HUD bands.
	for crow: Vector2 in [Vector2(174, 48), Vector2(202, 62), Vector2(532, 55)]:
		draw_line(crow + Vector2(offset, 0), crow + Vector2(offset - 4, -3), foreground, 1.0)
		draw_line(crow + Vector2(offset, 0), crow + Vector2(offset + 4, -3), foreground, 1.0)


func _draw_newspaper(position: Vector2, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(position + Vector2(-9, -13), Vector2(18, 14)), background)
	draw_rect(Rect2(position + Vector2(-9, -13), Vector2(18, 14)), foreground, false, 1.0)
	draw_rect(Rect2(position + Vector2(-6, -10), Vector2(5, 5)), foreground, false, 1.0)
	for y: int in [-9, -5, -1]:
		draw_line(position + Vector2(2, y), position + Vector2(7, y), foreground, 1.0)


func _draw_aya(position: Vector2, foreground: Color, background: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-9, 0), position + Vector2(-7, -23), position + Vector2(0, -32),
		position + Vector2(7, -23), position + Vector2(9, 0),
	]), foreground)
	draw_rect(Rect2(position + Vector2(-3, -27), Vector2(6, 7)), background)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-12, -30), position + Vector2(0, -38), position + Vector2(13, -30),
	]), foreground)
	# A lowered camera makes the event hook readable without implying consent.
	draw_rect(Rect2(position + Vector2(8, -17), Vector2(10, 7)), foreground, false, 2.0)
	draw_circle(position + Vector2(13, -14), 2.0, foreground, false, 1.0)
	draw_line(position + Vector2(6, -18), position + Vector2(10, -15), foreground, 1.0)


func _draw_clock(position: Vector2, foreground: Color, background: Color) -> void:
	draw_circle(position, 14, foreground)
	draw_circle(position, 11, background)
	draw_line(position, position + Vector2(0, -8), foreground, 2.0)
	draw_line(position, position + Vector2(7, 4), foreground, 2.0)


func _draw_service_tray(position: Vector2, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(position - Vector2(16, 5), Vector2(32, 6)), foreground, false, 2.0)
	draw_circle(position + Vector2(-7, -8), 4, foreground, false, 1.0)
	draw_rect(Rect2(position + Vector2(3, -13), Vector2(9, 9)), background)
	draw_rect(Rect2(position + Vector2(3, -13), Vector2(9, 9)), foreground, false, 1.0)


func _draw_sakuya(position: Vector2, foreground: Color, background: Color) -> void:
	draw_colored_polygon(PackedVector2Array([position + Vector2(-9, 0), position + Vector2(-6, -24), position + Vector2(0, -32), position + Vector2(7, -24), position + Vector2(9, 0)]), foreground)
	draw_rect(Rect2(position + Vector2(-3, -27), Vector2(6, 7)), background)
	draw_line(position + Vector2(-8, -17), position + Vector2(8, -17), background, 1.0)


func _draw_hud(foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	var font_size := _hud_font_size()
	var header_frame := Rect2(4, 3, 312, 19) if ui_scale_percent() > 100 else Rect2(4, 3, 312, 14)
	draw_rect(header_frame, background)
	draw_rect(header_frame, foreground, false, 1.0)
	var labeled_counter := spot_definition.counter_label_key != &""
	draw_string(font, Vector2(8, header_frame.position.y + font_size + 1), _header_text, HORIZONTAL_ALIGNMENT_LEFT, 198 if labeled_counter else 238, font_size, foreground)
	var counter := "%d/%d" % [objective_tracker.current_step, objective_tracker.required_sequence.size()]
	if labeled_counter:
		counter = "%s %s" % [_catalog.text(spot_definition.counter_label_key, _locale), counter]
	draw_string(font, Vector2(208 if labeled_counter else 252, header_frame.position.y + font_size + 1), counter, HORIZONTAL_ALIGNMENT_RIGHT, 102 if labeled_counter else 58, font_size, foreground)
	var footer_frame := Rect2(4, 151, 312, 26) if ui_scale_percent() > 100 else Rect2(4, 162, 312, 15)
	draw_rect(footer_frame, background)
	draw_rect(footer_frame, foreground, false, 1.0)
	var controls := PixelTextWrapper.wrap(_footer_text, font, 304, font_size, _locale, 2)
	for index: int in range(controls.size()):
		draw_string(font, Vector2(8, footer_frame.position.y + font_size + index * (font_size + 1)), controls[index], HORIZONTAL_ALIGNMENT_LEFT, 304, font_size, foreground)


func _draw_feedback(foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	var text := ""
	if _note_seconds > 0.0:
		text = _note_text
	elif _hint_visible:
		text = _hint_text
	elif _companion_latched and exploration_context.companion_skill_enabled:
		text = _companion_text
	else:
		text = _objective_text
	if not text.is_empty():
		var feedback_frame := Rect2(6, 128, 308, 20) if ui_scale_percent() > 100 else Rect2(6, 143, 308, 16)
		draw_rect(feedback_frame, background)
		draw_rect(feedback_frame, foreground, false, 1.0)
		draw_string(font, Vector2(10, feedback_frame.position.y + _hud_font_size() + 2), text, HORIZONTAL_ALIGNMENT_CENTER, 300, _hud_font_size(), foreground)
	if _sfx_seconds > 0.0:
		draw_string(font, Vector2(215, 28), _sfx_text, HORIZONTAL_ALIGNMENT_RIGHT, 96, _hud_font_size(), foreground)


func _hud_font_size() -> int:
	var base_size := (9 if ui_scale_percent() > 100 else 10) if _locale == &"ja" else (7 if ui_scale_percent() > 100 else 8)
	return scaled_ui_pixels(base_size)


func _draw_player(foreground: Color, background: Color) -> void:
	var position := motor_state.position - Vector2(_camera_x, 0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-6, 0), position + Vector2(-7, -13), position + Vector2(-3, -22), position + Vector2(3, -22), position + Vector2(7, -13), position + Vector2(6, 0),
	]), foreground)
	draw_rect(Rect2(position + Vector2(-3, -19), Vector2(6, 7)), background)
	draw_line(position + Vector2(-2, -16), position + Vector2(2, -16), foreground, 1.0)
	draw_line(position + Vector2(-4, 0), position + Vector2(-4, 4), foreground, 2.0)
	draw_line(position + Vector2(4, 0), position + Vector2(4, 4), foreground, 2.0)


func _draw_focus_traces(foreground: Color, background: Color) -> void:
	for interactable: ExplorationInteractable in interaction_registry.all():
		if interactable.interactable_id == &"char.marisa_kirisame" and not _marisa_entered:
			continue
		var center := interactable.world_position - Vector2(_camera_x, 8)
		if center.x < -10 or center.x > 330:
			continue
		draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 16)), background)
		draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 16)), foreground, false, 1.0)
		draw_rect(Rect2(center + Vector2(-1, -11), Vector2(2, 2)), foreground)


func _draw_float_preview(foreground: Color) -> void:
	for point: Vector2 in float_preview.points:
		var screen := point - Vector2(_camera_x, 0)
		draw_rect(Rect2(roundf(screen.x), roundf(screen.y), 2, 2), foreground)


func _draw_tree(position: Vector2, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(position.x - 5, position.y - 28, 10, 37), foreground)
	for center: Vector2 in [position + Vector2(-10, -32), position + Vector2(5, -40), position + Vector2(16, -29)]:
		draw_circle(center, 13, foreground)
		draw_circle(center, 8, background)


func _draw_donation_box(position: Vector2, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(position - Vector2(13, 8), Vector2(27, 19)), foreground)
	for x: int in range(-9, 11, 5):
		draw_line(position + Vector2(x, -6), position + Vector2(x, 8), background, 1.0)
	draw_rect(Rect2(position + Vector2(-15, -11), Vector2(31, 4)), foreground)


func _draw_cup(position: Vector2, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(position - Vector2(5, 5), Vector2(10, 7)), foreground, false, 2.0)
	draw_rect(Rect2(position + Vector2(4, -3), Vector2(4, 4)), foreground, false, 1.0)
	draw_line(position + Vector2(-6, 4), position + Vector2(6, 4), foreground, 1.0)
	draw_line(position + Vector2(-2, -8), position + Vector2(-1, -11), foreground, 1.0)


func _draw_cushion(position: Vector2, foreground: Color, background: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-16, 0), position + Vector2(-12, -8), position + Vector2(12, -8), position + Vector2(16, 0),
	]), foreground)
	draw_rect(Rect2(position + Vector2(-10, -6), Vector2(20, 4)), background)


func _draw_door(position: Vector2, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(position + Vector2(-10, -47), Vector2(21, 48)), background)
	draw_rect(Rect2(position + Vector2(-10, -47), Vector2(21, 48)), foreground, false, 2.0)
	draw_line(position + Vector2(0, -46), position + Vector2(0, 0), foreground, 1.0)
	draw_circle(position + Vector2(6, -23), 1.5, foreground)


func _draw_broom(position: Vector2, foreground: Color) -> void:
	draw_line(position + Vector2(-6, 0), position + Vector2(7, -39), foreground, 2.0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-13, 0), position + Vector2(0, -12), position + Vector2(9, 0),
	]), foreground)


func _draw_reimu(position: Vector2, foreground: Color, background: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-8, 0), position + Vector2(-7, -20), position + Vector2(-4, -30), position + Vector2(4, -30), position + Vector2(8, -20), position + Vector2(8, 0),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([position + Vector2(-13, -31), position + Vector2(-4, -37), position + Vector2(-3, -27)]), foreground)
	draw_colored_polygon(PackedVector2Array([position + Vector2(13, -31), position + Vector2(4, -37), position + Vector2(3, -27)]), foreground)
	draw_rect(Rect2(position + Vector2(-3, -25), Vector2(6, 7)), background)


func _draw_marisa(position: Vector2, foreground: Color, background: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-8, 0), position + Vector2(-6, -23), position + Vector2(0, -31), position + Vector2(7, -22), position + Vector2(9, 0),
	]), foreground)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-16, -30), position + Vector2(2, -43), position + Vector2(17, -29),
	]), foreground)
	draw_rect(Rect2(position + Vector2(-3, -26), Vector2(6, 6)), background)
