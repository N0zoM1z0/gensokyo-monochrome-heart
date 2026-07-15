class_name ActionHint
extends Control
## Localized semantic verb paired with a device glyph; the verb always remains visible.

@export var action: StringName = &"confirm"
@export var verb_key: StringName = &"ui.common.confirm"
@export var profile_id: StringName = &"A"
@export var state: StringName = &"available"

var locale: StringName = &"en"
var glyph_key: StringName = &"input.glyph.keyboard.confirm"
var _catalog := UiTextCatalog.new()
var _font: Font


func _ready() -> void:
	_catalog.load_default()
	_font = UiFontRegistry.latin()
	queue_redraw()


func configure(next_action: StringName, next_verb_key: StringName, next_locale: StringName, next_profile: StringName, next_glyph_key: StringName) -> void:
	action = next_action
	verb_key = next_verb_key
	locale = next_locale
	profile_id = next_profile
	glyph_key = next_glyph_key
	_font = UiFontRegistry.japanese() if locale == &"ja" else UiFontRegistry.latin()
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var foreground := profile.paper if profile.is_inverted else profile.ink
	var text := "%s %s" % [_catalog.text(glyph_key, locale), _catalog.text(verb_key, locale)]
	draw_string(_font, Vector2(0, 9), text, HORIZONTAL_ALIGNMENT_LEFT, size.x, 8, foreground)
	if state == &"blocked":
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), foreground, 1.0)
