class_name ActionHint
extends Control
## Localized semantic verb paired with a device glyph; the verb always remains visible.

const UI_SCALE_POLICY := preload("res://src/presentation/ui/UiScalePolicy.gd")

@export var action: StringName = &"confirm"
@export var verb_key: StringName = &"ui.common.confirm"
@export var profile_id: StringName = &"A"
@export var state: StringName = &"available"

var locale: StringName = &"en"
var glyph_key: StringName = &"input.glyph.keyboard.confirm"
var binding_label: String = ""
var ui_scale_percent: int = 100
var _catalog := UiTextCatalog.new()
var _font: Font


func _ready() -> void:
	_catalog.load_default()
	_font = UiFontRegistry.latin()
	queue_redraw()


func configure(next_action: StringName, next_verb_key: StringName, next_locale: StringName, next_profile: StringName, next_glyph_key: StringName, next_binding_label: String = "") -> void:
	action = next_action
	verb_key = next_verb_key
	locale = next_locale
	profile_id = next_profile
	glyph_key = next_glyph_key
	binding_label = next_binding_label
	_font = UiFontRegistry.japanese() if locale == &"ja" else UiFontRegistry.latin()
	queue_redraw()


func set_ui_scale(next_percent: int) -> void:
	ui_scale_percent = UI_SCALE_POLICY.normalize(next_percent)
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var foreground := profile.paper if profile.is_inverted else profile.ink
	var glyph := binding_label if not binding_label.is_empty() else _catalog.text(glyph_key, locale)
	var text := "%s %s" % [glyph, _catalog.text(verb_key, locale)]
	var font_size: int = UI_SCALE_POLICY.pixels(10 if locale == &"ja" else 8, ui_scale_percent)
	draw_string(_font, Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size, foreground)
	if state == &"blocked":
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), foreground, 1.0)
