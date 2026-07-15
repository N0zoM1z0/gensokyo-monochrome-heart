class_name TransitionController
extends Node
## Drives transition visuals on fixed frame counts and exposes the selected variant.

const STANDARD_HALF_FRAMES := 3
const REDUCED_COVER_FRAMES := 1
const REDUCED_REVEAL_FRAMES := 2

@export var overlay_path: NodePath

var last_style: StringName = TransitionOverlay.STYLE_PAPER_FOLD

@onready var overlay: TransitionOverlay = get_node(overlay_path)


func style_for_reduced_motion(is_reduced_motion: bool) -> StringName:
	return (
		TransitionOverlay.STYLE_BORDER_TICK
		if is_reduced_motion
		else TransitionOverlay.STYLE_PAPER_FOLD
	)


func cover(is_reduced_motion: bool, profile_id: StringName) -> void:
	last_style = style_for_reduced_motion(is_reduced_motion)
	var frames := REDUCED_COVER_FRAMES if is_reduced_motion else STANDARD_HALF_FRAMES
	await _play_phase(&"cover", frames, profile_id)


func reveal(is_reduced_motion: bool, profile_id: StringName) -> void:
	last_style = style_for_reduced_motion(is_reduced_motion)
	var frames := REDUCED_REVEAL_FRAMES if is_reduced_motion else STANDARD_HALF_FRAMES
	await _play_phase(&"reveal", frames, profile_id)
	overlay.clear()


func _play_phase(phase: StringName, frames: int, profile_id: StringName) -> void:
	for frame: int in range(frames):
		overlay.configure(last_style, phase, frame, frames, profile_id)
		await get_tree().process_frame
