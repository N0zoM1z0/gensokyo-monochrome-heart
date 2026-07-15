class_name DanmakuAssistSettings
extends RefCounted
## Mechanical bullet-field assists; story rewards never depend on these values.

const DENSITY_TIERS := [100, 85, 70, 55]
const SPEED_TIERS := [100, 90, 80, 70]

var story_mode: bool = true
var bullet_speed_percent: int = 100
var density_percent: int = 100
var larger_graze_radius: bool = false
var safe_lane_preview: bool = false
var auto_bomb: bool = false
var background_dim_percent: int = 40
var no_flash: bool = false


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if density_percent not in DENSITY_TIERS:
		errors.append("danmaku density must be one of %s" % [DENSITY_TIERS])
	if bullet_speed_percent not in SPEED_TIERS:
		errors.append("danmaku speed must be one of %s" % [SPEED_TIERS])
	if background_dim_percent < 0 or background_dim_percent > 100:
		errors.append("background dim must remain within 0..100")
	return errors


func any_enabled() -> bool:
	return (
		bullet_speed_percent < 100
		or density_percent < 100
		or larger_graze_radius
		or safe_lane_preview
		or auto_bomb
		or background_dim_percent > 40
		or no_flash
	)


func duplicate_settings() -> DanmakuAssistSettings:
	var copy := DanmakuAssistSettings.new()
	copy.story_mode = story_mode
	copy.bullet_speed_percent = bullet_speed_percent
	copy.density_percent = density_percent
	copy.larger_graze_radius = larger_graze_radius
	copy.safe_lane_preview = safe_lane_preview
	copy.auto_bomb = auto_bomb
	copy.background_dim_percent = background_dim_percent
	copy.no_flash = no_flash
	return copy


func canonical_signature() -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d" % [
		int(story_mode),
		bullet_speed_percent,
		density_percent,
		int(larger_graze_radius),
		int(safe_lane_preview),
		int(auto_bomb),
		background_dim_percent,
		int(no_flash),
	]


static func from_signature(signature: String) -> DanmakuAssistSettings:
	var settings := DanmakuAssistSettings.new()
	var parts := signature.split("|")
	if parts.size() != 8:
		return settings
	settings.story_mode = int(parts[0]) != 0
	settings.bullet_speed_percent = int(parts[1])
	settings.density_percent = int(parts[2])
	settings.larger_graze_radius = int(parts[3]) != 0
	settings.safe_lane_preview = int(parts[4]) != 0
	settings.auto_bomb = int(parts[5]) != 0
	settings.background_dim_percent = int(parts[6])
	settings.no_flash = int(parts[7]) != 0
	return settings
