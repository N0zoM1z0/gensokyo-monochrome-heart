class_name EventDebugOverlayControl
extends Control
## Developer/QA-only visual projection of the typed event debug snapshot.

var profile_id: StringName = &"A"
var overlay_enabled: bool = false
var model := EventDebugOverlayModel.new()

var _font: Font


func _ready() -> void:
	_font = UiFontRegistry.latin()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(snapshot: EventDebugSnapshot, next_profile_id: StringName = &"A") -> void:
	profile_id = next_profile_id
	model = EventDebugOverlayModel.build(snapshot)
	queue_redraw()


func set_overlay_enabled(enabled: bool) -> void:
	overlay_enabled = enabled and BuildChannel.allows_debug_tools()
	queue_redraw()


func _draw() -> void:
	if not overlay_enabled or not BuildChannel.allows_debug_tools() or model.lines.is_empty():
		return
	var profile := PresentationProfileRegistry.resolve(profile_id)
	var background := profile.ink if profile.is_inverted else profile.paper
	var foreground := profile.paper if profile.is_inverted else profile.ink
	var panel_height := mini(76, 8 + model.lines.size() * 10)
	draw_rect(Rect2(2, 2, 316, panel_height), background)
	draw_rect(Rect2(2, 2, 316, panel_height), foreground, false, 1.0)
	for index: int in range(mini(model.lines.size(), 7)):
		draw_string(_font, Vector2(6, 11 + index * 10), model.lines[index], HORIZONTAL_ALIGNMENT_LEFT, 308, 8, foreground)
