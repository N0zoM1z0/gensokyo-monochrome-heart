class_name FighterInputFrame
extends RefCounted
## One 60 Hz semantic fighter input sample suitable for deterministic replay.

var horizontal_axis: int = 0
var vertical_axis: int = 0
var light_pressed: bool = false
var heavy_pressed: bool = false
var skill_pressed: bool = false
var spell_pressed: bool = false
var guard_held: bool = false


func encoded() -> int:
	var result := clampi(horizontal_axis, -1, 1) + 1
	result |= (clampi(vertical_axis, -1, 1) + 1) << 2
	result |= int(light_pressed) << 4
	result |= int(heavy_pressed) << 5
	result |= int(skill_pressed) << 6
	result |= int(spell_pressed) << 7
	result |= int(guard_held) << 8
	return result


func duplicate_frame() -> FighterInputFrame:
	return FighterInputFrame.decode(encoded())


static func decode(value: int) -> FighterInputFrame:
	var frame := FighterInputFrame.new()
	frame.horizontal_axis = (value & 3) - 1
	frame.vertical_axis = ((value >> 2) & 3) - 1
	frame.light_pressed = ((value >> 4) & 1) != 0
	frame.heavy_pressed = ((value >> 5) & 1) != 0
	frame.skill_pressed = ((value >> 6) & 1) != 0
	frame.spell_pressed = ((value >> 7) & 1) != 0
	frame.guard_held = ((value >> 8) & 1) != 0
	return frame
