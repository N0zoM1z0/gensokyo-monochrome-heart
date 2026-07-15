class_name ListRow
extends Control
## One semantic focus target with localized label and optional textual status.

const UI_SCALE_POLICY := preload("res://src/presentation/ui/UiScalePolicy.gd")

@export var label_key: StringName
@export var value_key: StringName
@export var command_id: StringName
@export var focus_id: StringName
@export var state: StringName = &"idle"
@export var profile_id: StringName = &"A"

var locale: StringName = &"en"
var is_focused: bool = false
var ui_scale_percent: int = 100
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font

@onready var focus_marker: FocusMarker = get_node_or_null("FocusMarker")


func _ready() -> void:
	_catalog.load_default()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func configure_focus(focused: bool, input_device: StringName = &"keyboard") -> void:
	is_focused = focused
	state = &"focused" if focused else &"idle"
	if focus_marker != null:
		focus_marker.configure(focused, profile_id, input_device)
	queue_redraw()


func set_locale(next_locale: StringName) -> void:
	locale = next_locale
	queue_redraw()


func set_profile(next_profile_id: StringName) -> void:
	profile_id = next_profile_id
	if focus_marker != null:
		focus_marker.configure(is_focused, profile_id, &"keyboard")
	queue_redraw()


func set_value_key(next_value_key: StringName) -> void:
	value_key = next_value_key
	queue_redraw()


func set_ui_scale(next_percent: int) -> void:
	ui_scale_percent = UI_SCALE_POLICY.normalize(next_percent)
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	draw_rect(Rect2(Vector2.ZERO, size), background)
	if state == &"selected":
		draw_rect(Rect2(2, size.y - 4, size.x - 4, 2), foreground)
	elif state == &"disabled":
		draw_line(Vector2(10, size.y - 3), Vector2(size.x - 4, size.y - 3), foreground, 1.0)
	var font := _japanese_font if locale == &"ja" else _latin_font
	var base_font_size := 12 if locale == &"ja" else 8
	var font_size: int = UI_SCALE_POLICY.pixels(base_font_size, ui_scale_percent)
	var baseline := mini(size.y - 3.0, font_size + 1.0)
	var label := _catalog.text(label_key, locale)
	var label_width := size.x - 20
	if value_key != &"":
		var value := _catalog.text(value_key, locale)
		var value_width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		label_width = maxf(24.0, size.x - value_width - 24.0)
		draw_string(font, Vector2(size.x - value_width - 6, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, foreground)
	draw_string(font, Vector2(12, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, label_width, font_size, foreground)
