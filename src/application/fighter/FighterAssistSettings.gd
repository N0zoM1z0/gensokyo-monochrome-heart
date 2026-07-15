class_name FighterAssistSettings
extends RefCounted
## Locale-free fighter accessibility settings captured in replay identity.

const SPEED_TIERS := [100, 90, 80, 70]

var story_mode: bool = true
var simple_inputs: bool = true
var hold_to_guard: bool = true
var speed_percent: int = 100
var auto_face: bool = true
var no_flash: bool = false
var reduced_motion: bool = false


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if speed_percent not in SPEED_TIERS:
		errors.append("fighter speed must use a reviewed tier: %d" % speed_percent)
	return errors


func signature() -> String:
	return "%d|%d|%d|%d|%d|%d|%d" % [
		int(story_mode),
		int(simple_inputs),
		int(hold_to_guard),
		speed_percent,
		int(auto_face),
		int(no_flash),
		int(reduced_motion),
	]


func duplicate_settings() -> FighterAssistSettings:
	return FighterAssistSettings.from_signature(signature())


static func from_signature(value: String) -> FighterAssistSettings:
	var settings := FighterAssistSettings.new()
	var parts := value.split("|")
	if parts.size() != 7:
		settings.speed_percent = -1
		return settings
	settings.story_mode = int(parts[0]) != 0
	settings.simple_inputs = int(parts[1]) != 0
	settings.hold_to_guard = int(parts[2]) != 0
	settings.speed_percent = int(parts[3])
	settings.auto_face = int(parts[4]) != 0
	settings.no_flash = int(parts[5]) != 0
	settings.reduced_motion = int(parts[6]) != 0
	return settings
