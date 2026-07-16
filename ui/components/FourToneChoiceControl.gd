class_name FourToneChoiceControl
extends Control
## One-bit four-tone selector whose focus identity survives localization changes.

const UI_SCALE_POLICY := preload("res://src/presentation/ui/UiScalePolicy.gd")

signal tone_confirmed(tone: StringName)

const TONE_LABEL_KEYS: Dictionary[StringName, StringName] = {
	&"direct": &"ui.dialogue.tone.direct",
	&"playful": &"ui.dialogue.tone.playful",
	&"patient": &"ui.dialogue.tone.patient",
	&"defiant": &"ui.dialogue.tone.defiant",
}
const ROUTE_INTENT_LABEL_KEYS: Dictionary[StringName, StringName] = {
	&"direct": &"ui.dialogue.intent.friendship",
	&"playful": &"ui.dialogue.intent.romance",
	&"patient": &"ui.dialogue.intent.postponed",
	&"defiant": &"ui.dialogue.intent.undecided",
}

var profile_id: StringName = &"A"
var locale: StringName = &"en"
var ui_scale_percent: int = 100
var presenter := FourToneChoicePresenter.new()

var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _uses_route_intent_labels: bool = false


func _ready() -> void:
	_catalog.load_default()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	custom_minimum_size = Vector2(292, 126)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func configure(
	choice: EventChoiceState,
	content: ContentRepository,
	next_locale: StringName,
	next_profile_id: StringName = &"A",
	preferred_tone: StringName = &"direct"
) -> void:
	presenter = FourToneChoicePresenter.new(content)
	presenter.configure(choice, next_locale, preferred_tone)
	_uses_route_intent_labels = choice != null and choice.choice_id in [
		&"choice.hkr.promise.intent",
		&"choice.mrs.promise.intent",
	]
	locale = next_locale
	profile_id = next_profile_id
	queue_redraw()


func set_locale(next_locale: StringName) -> void:
	locale = next_locale
	presenter.switch_locale(next_locale)
	queue_redraw()


func set_profile(next_profile_id: StringName) -> void:
	profile_id = next_profile_id
	queue_redraw()


func set_ui_scale(next_percent: int) -> void:
	ui_scale_percent = UI_SCALE_POLICY.normalize(next_percent)
	queue_redraw()


func focused_tone() -> StringName:
	return presenter.focused_tone


func handle_semantic_action(action: StringName) -> bool:
	match action:
		GameInput.MOVE_UP, GameInput.MOVE_LEFT:
			presenter.move(-1)
			queue_redraw()
			return true
		GameInput.MOVE_DOWN, GameInput.MOVE_RIGHT:
			presenter.move(1)
			queue_redraw()
			return true
		GameInput.CONFIRM:
			var tone := presenter.confirm()
			if tone != &"":
				tone_confirmed.emit(tone)
			return tone != &""
	return false


func _gui_input(event: InputEvent) -> void:
	for action: StringName in [
		GameInput.MOVE_UP,
		GameInput.MOVE_DOWN,
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.CONFIRM,
	]:
		if event.is_action_pressed(action) and handle_semantic_action(action):
			accept_event()
			return


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(Vector2.ZERO, size), background)
	var options := presenter.presentations()
	if options.is_empty():
		return
	var row_height := floori(size.y / float(options.size()))
	for index: int in range(options.size()):
		_draw_option(options[index], index, row_height, foreground, background)


func _draw_option(
	option: ChoiceOptionPresentation,
	index: int,
	row_height: int,
	foreground: Color,
	background: Color
) -> void:
	var top := index * row_height
	var row_rect := Rect2(0, top, size.x, row_height - 2)
	draw_rect(row_rect, foreground, false, 1.0)
	var focused := option.tone == presenter.focused_tone
	if focused:
		draw_rect(row_rect.grow(-2), foreground, false, 1.0)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(3, top + row_height / 2 - 3),
				Vector2(8, top + row_height / 2),
				Vector2(3, top + row_height / 2 + 3),
			]),
			foreground
		)
	if not option.is_available:
		for x: int in range(0, int(size.x), 8):
			draw_line(Vector2(x, top + row_height - 4), Vector2(x + 5, top + 1), foreground, 1.0)
	_draw_tone_mark(option.tone, Vector2(13, top + 8), foreground, background)
	var font := _japanese_font if locale == &"ja" else _latin_font
	var body_base := (10 if ui_scale_percent > 100 else 12) if locale == &"ja" else 8
	var body_size := UI_SCALE_POLICY.pixels(body_base, ui_scale_percent)
	var tone_size := UI_SCALE_POLICY.pixels(10 if locale == &"ja" else 8, ui_scale_percent)
	var line_height := body_size
	var label_keys := ROUTE_INTENT_LABEL_KEYS if _uses_route_intent_labels else TONE_LABEL_KEYS
	var tone_label := _catalog.text(label_keys.get(option.tone, &"ui.common.unavailable"), locale)
	var first_baseline := mini(row_height - 4, tone_size + 1)
	var is_reflow := ui_scale_percent > 100
	if not is_reflow:
		draw_string(font, Vector2(29, top + first_baseline), tone_label, HORIZONTAL_ALIGNMENT_LEFT, 54, tone_size, foreground)
	var action_x := 29 if is_reflow else 87
	var action_width := size.x - action_x - 8
	var action_text := "%s  %s" % [tone_label, option.text] if is_reflow else option.text
	var action_lines := PixelTextWrapper.wrap(action_text, font, action_width, body_size, locale, 2)
	var action_baseline := mini(row_height - 4, body_size - 2)
	if locale == &"ja" and ui_scale_percent == 100:
		# The Japanese font's ascent is taller than the Latin bitmap face. Give
		# both wrapped lines clearance from the one-pixel row rule.
		action_baseline += 3
	for line_index: int in range(action_lines.size()):
		draw_string(
			font,
			Vector2(action_x, top + action_baseline + line_index * line_height),
			action_lines[line_index],
			HORIZONTAL_ALIGNMENT_LEFT,
			action_width,
			body_size,
			foreground
		)


func _draw_tone_mark(tone: StringName, origin: Vector2, foreground: Color, background: Color) -> void:
	match tone:
		&"direct":
			draw_line(origin, origin + Vector2(9, 0), foreground, 2.0)
			draw_colored_polygon(PackedVector2Array([origin + Vector2(7, -3), origin + Vector2(12, 0), origin + Vector2(7, 3)]), foreground)
		&"playful":
			draw_colored_polygon(PackedVector2Array([origin + Vector2(5, -5), origin + Vector2(10, 0), origin + Vector2(5, 5), origin + Vector2(0, 0)]), foreground)
			draw_colored_polygon(PackedVector2Array([origin + Vector2(5, -2), origin + Vector2(7, 0), origin + Vector2(5, 2), origin + Vector2(3, 0)]), background)
		&"patient":
			draw_rect(Rect2(origin, Vector2(10, 6)), foreground, false, 1.0)
			draw_line(origin + Vector2(2, 8), origin + Vector2(8, 8), foreground, 1.0)
		&"defiant":
			draw_line(origin + Vector2(1, 5), origin + Vector2(1, -5), foreground, 2.0)
			draw_colored_polygon(PackedVector2Array([origin + Vector2(3, -5), origin + Vector2(11, -2), origin + Vector2(3, 1)]), foreground)
