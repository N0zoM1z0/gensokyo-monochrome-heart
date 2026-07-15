class_name PromptChip
extends Control
## World-anchored one-bit prompt with shape and verb parity across palette polarities.

var profile_id: StringName = &"A"
var locale: StringName = &"en"
var action_kind: StringName = &"observe"
var label_key: StringName = &"ui.exploration.observe"
var is_required: bool = false

var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font


func _ready() -> void:
	_catalog.load_default()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64, 14)
	queue_redraw()


func configure(
	kind: StringName,
	key: StringName,
	next_locale: StringName,
	next_profile_id: StringName,
	required: bool = false
) -> void:
	action_kind = kind
	label_key = key
	locale = next_locale
	profile_id = next_profile_id
	is_required = required
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(Vector2.ZERO, size), background)
	draw_rect(Rect2(Vector2.ZERO, size), foreground, false, 1.0)
	if is_required:
		draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), foreground, false, 1.0)
	_draw_shape(Vector2(8, size.y / 2), foreground, background)
	var font := _japanese_font if locale == &"ja" else _latin_font
	var font_size := 10 if locale == &"ja" else 8
	draw_string(font, Vector2(17, 11), _catalog.text(label_key, locale), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, font_size, foreground)


func _draw_shape(origin: Vector2, foreground: Color, background: Color) -> void:
	match action_kind:
		&"talk":
			draw_rect(Rect2(origin - Vector2(4, 3), Vector2(8, 6)), foreground, false, 1.0)
			draw_line(origin + Vector2(-2, 3), origin + Vector2(-4, 5), foreground, 1.0)
		&"use":
			draw_line(origin + Vector2(-4, 4), origin + Vector2(4, -4), foreground, 2.0)
			draw_circle(origin + Vector2(3, -3), 2.0, background)
		_:
			draw_colored_polygon(PackedVector2Array([origin + Vector2(0, -4), origin + Vector2(4, 0), origin + Vector2(0, 4), origin + Vector2(-4, 0)]), foreground)
			draw_circle(origin, 1.5, background)
