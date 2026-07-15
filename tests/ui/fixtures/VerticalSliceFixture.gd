class_name VerticalSliceFixture
extends Control
## QA wrapper that drives the production M09 coordinator to a reviewed still state.

@export_enum(
	"invitation",
	"world_map",
	"exploration",
	"dialogue",
	"choice",
	"tea",
	"danmaku",
	"fighter",
	"afterbeat",
	"reward",
	"day_end",
	"journal",
	"replay_complete",
	"complete"
) var fixture_phase: String = "invitation"

@onready var slice: VerticalSliceMode = %VerticalSliceMode


func _enter_tree() -> void:
	var kernel := get_node_or_null("/root/GameKernel")
	if kernel == null:
		return
	kernel.clear_state()
	var created: Variant = kernel.create_new_profile(&"p98", &"accessibility.story")
	if not created is CommandResult or not created.is_success():
		push_error("Vertical slice screenshot profile could not be created")
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	var save_service := get_node_or_null("/root/SaveService")
	if save_service != null:
		save_service.configure_for_test(kernel, "user://tests/m09_screenshot_fixture")


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	if slice == null:
		return
	slice.configure_fixture(
		requested_profile,
		locale,
		forced_profile,
		is_reduced_motion,
		is_safe_flash
	)
	slice.set_instant_text_for_test(true)
	_drive_to_fixture_phase()


func resolved_profile_id() -> StringName:
	return slice.resolved_profile_id() if slice != null else &"A"


func handle_semantic_action(action: StringName) -> bool:
	return slice.handle_semantic_action(action) if slice != null else false


func _drive_to_fixture_phase() -> void:
	if fixture_phase == "invitation":
		return
	_confirm()
	if fixture_phase == "world_map":
		return
	_confirm()
	if fixture_phase == "exploration":
		return
	if not slice.complete_exploration_for_test():
		push_error("Vertical slice screenshot exploration setup failed")
		return
	if fixture_phase == "dialogue":
		return
	_confirm()
	if fixture_phase == "choice":
		return
	_confirm()
	_confirm()
	if fixture_phase == "tea":
		return
	if not slice.submit_mode_result_for_test(&"excellent"):
		push_error("Vertical slice screenshot Tea result failed")
		return
	_confirm()
	_confirm()
	if fixture_phase == "danmaku":
		return
	if not slice.submit_mode_result_for_test(&"assist_clear"):
		push_error("Vertical slice screenshot danmaku result failed")
		return
	_confirm()
	_confirm()
	if fixture_phase == "fighter":
		return
	if not slice.submit_mode_result_for_test(&"win"):
		push_error("Vertical slice screenshot fighter result failed")
		return
	_confirm()
	if fixture_phase == "afterbeat":
		return
	for _line: int in range(4):
		slice.arm_input_for_test()
		_confirm()
	if fixture_phase == "reward":
		return
	_confirm()
	if fixture_phase == "day_end":
		return
	_confirm()
	if fixture_phase == "journal":
		return
	_confirm()
	_drive_replay()
	if fixture_phase == "replay_complete":
		return
	_confirm()
	slice.handle_semantic_action(GameInput.CANCEL)


func _drive_replay() -> void:
	_confirm()
	_confirm()
	_confirm()
	if not slice.submit_mode_result_for_test(&"loss"):
		return
	_confirm()
	_confirm()
	if not slice.submit_mode_result_for_test(&"loss"):
		return
	_confirm()
	_confirm()
	if not slice.submit_mode_result_for_test(&"loss"):
		return
	_confirm()
	for _line: int in range(4):
		slice.arm_input_for_test()
		_confirm()


func _confirm() -> void:
	slice.handle_semantic_action(GameInput.CONFIRM)
