class_name VisualFoundationFixture
extends Control
## Deterministic VA00 specimen for profile, font, accessibility, and screenshot checks.

const ACTION_CONTRACT := [
	"move",
	"confirm",
	"cancel",
	"menu",
	"journal",
	"focus",
	"shot",
	"bomb",
	"light",
	"heavy",
	"skill",
	"spell",
	"companion",
	"page_left",
	"page_right",
]

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _is_reduced_motion := false
var _is_safe_flash := false
var _latin_font: Font
var _japanese_font: Font


func _ready() -> void:
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
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
	_is_reduced_motion = is_reduced_motion
	_is_safe_flash = is_safe_flash
	queue_redraw()


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	_draw_profile_frame(foreground, background)
	_draw_text_specimen(foreground)
	_draw_accessibility_state(foreground)


func _draw_profile_frame(foreground: Color, background: Color) -> void:
	match _profile.profile_id:
		&"B":
			draw_rect(Rect2(7, 7, 306, 166), foreground, false, 1.0)
			draw_rect(Rect2(10, 10, 300, 160), foreground, false, 1.0)
			for y: int in range(28, 52, 4):
				for x: int in range(12 + y % 8, 308, 8):
					draw_rect(Rect2(x, y, 1, 1), foreground)
		&"C":
			draw_rect(Rect2(8, 8, 304, 164), foreground, false, 2.0)
			draw_colored_polygon(
				PackedVector2Array([Vector2(296, 8), Vector2(312, 8), Vector2(312, 24)]),
				foreground
			)
			draw_colored_polygon(
				PackedVector2Array([Vector2(299, 11), Vector2(309, 11), Vector2(309, 21)]),
				background
			)
		&"D":
			draw_rect(Rect2(8, 8, 304, 164), foreground, false, 2.0)
			draw_rect(Rect2(14, 14, 292, 8), foreground)
		_:
			draw_line(Vector2(12, 8), Vector2(308, 8), foreground, 2.0)
			draw_line(Vector2(8, 12), Vector2(8, 168), foreground, 2.0)
			draw_line(Vector2(12, 172), Vector2(308, 172), foreground, 2.0)
			draw_line(Vector2(312, 12), Vector2(312, 168), foreground, 2.0)


func _draw_text_specimen(foreground: Color) -> void:
	draw_string(_latin_font, Vector2(16, 22), "PROFILE %s / %s" % [_profile.profile_id, _profile.display_name.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
	draw_line(Vector2(16, 28), Vector2(304, 28), foreground, 1.0)
	if _locale == &"ja":
		draw_string(_japanese_font, Vector2(16, 48), "博麗神社　空の座布団", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
		draw_string(_japanese_font, Vector2(16, 64), "霊夢：二つ目の湯呑みはまだ温かい。", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
		draw_string(_japanese_font, Vector2(16, 80), "魔理沙：なら、これは証拠だぜ。", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
	else:
		draw_string(_latin_font, Vector2(16, 48), "HAKUREI SHRINE / EMPTY CUSHION", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
		draw_string(_latin_font, Vector2(16, 64), "REIMU: THE SECOND CUP IS STILL WARM.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
		draw_string(_latin_font, Vector2(16, 80), "MARISA: THEN THIS COUNTS AS EVIDENCE.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
	draw_rect(Rect2(16, 96, 288, 36), foreground, false, 2.0)
	draw_string(_latin_font, Vector2(24, 112), "> CONFIRM   BACK   MENU", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
	draw_string(_latin_font, Vector2(24, 126), "ACTIONS 15 / OUTCOMES UNCHANGED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)


func _draw_accessibility_state(foreground: Color) -> void:
	var motion_label := "LOW MOTION" if _is_reduced_motion else "MOTION STANDARD"
	var flash_label := "SAFE FLASH" if _is_safe_flash else "LOCAL FLASH"
	draw_string(_latin_font, Vector2(16, 152), motion_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
	draw_string(_latin_font, Vector2(176, 152), flash_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, foreground)
	draw_rect(Rect2(16, 160, 288, 4), foreground)
