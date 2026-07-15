class_name FighterInputBuffer
extends RefCounted
## Five-frame attack buffer plus a closed, lenient down-toward motion reader.

const CAPACITY := 5

var frames: Array[FighterInputFrame] = []


func push(frame: FighterInputFrame) -> void:
	frames.append(frame.duplicate_frame() if frame != null else FighterInputFrame.new())
	while frames.size() > CAPACITY:
		frames.pop_front()


func clear() -> void:
	frames.clear()


func consume_action(facing: int, simple_inputs: bool) -> StringName:
	for index: int in range(frames.size() - 1, -1, -1):
		var action := resolve_action(frames[index], facing, simple_inputs)
		if action != &"":
			clear()
			return action
	return &""


func resolve_action(frame: FighterInputFrame, facing: int, simple_inputs: bool) -> StringName:
	if frame == null:
		return &""
	if frame.spell_pressed:
		return &"spell"
	if frame.heavy_pressed:
		return &"heavy"
	if frame.skill_pressed:
		if simple_inputs and frame.horizontal_axis * facing > 0:
			return &"skill_forward"
		if not simple_inputs and _has_down_toward_motion(facing):
			return &"skill_forward"
		return &"skill"
	if frame.light_pressed:
		return &"light"
	return &""


func _has_down_toward_motion(facing: int) -> bool:
	var saw_down := false
	for frame: FighterInputFrame in frames:
		if frame.vertical_axis > 0:
			saw_down = true
		elif saw_down and frame.horizontal_axis * facing > 0:
			return true
	return false
