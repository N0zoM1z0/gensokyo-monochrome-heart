class_name DanmakuInputFrame
extends RefCounted
## One fixed-tick semantic input sample suitable for compact deterministic replay.

var horizontal_axis: int = 0
var vertical_axis: int = 0
var focus_held: bool = false
var shot_held: bool = false
var bomb_pressed: bool = false
var margin_pressed: bool = false


func encoded() -> int:
	var result := clampi(horizontal_axis, -1, 1) + 1
	result |= (clampi(vertical_axis, -1, 1) + 1) << 2
	result |= int(focus_held) << 4
	result |= int(shot_held) << 5
	result |= int(bomb_pressed) << 6
	result |= int(margin_pressed) << 7
	return result


func duplicate_frame() -> DanmakuInputFrame:
	return DanmakuInputFrame.decode(encoded())


static func decode(value: int) -> DanmakuInputFrame:
	var frame := DanmakuInputFrame.new()
	frame.horizontal_axis = (value & 3) - 1
	frame.vertical_axis = ((value >> 2) & 3) - 1
	frame.focus_held = ((value >> 4) & 1) != 0
	frame.shot_held = ((value >> 5) & 1) != 0
	frame.bomb_pressed = ((value >> 6) & 1) != 0
	frame.margin_pressed = ((value >> 7) & 1) != 0
	return frame
