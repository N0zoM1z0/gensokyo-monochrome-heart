class_name MountainSliceFixture
extends Control
## QA wrapper that drives the production mountain slice to reviewed story stages.

const SAVE_ROOT_BASE := "user://tests/m13_mountain_screenshot_fixture"

@export_enum("invitation", "choice", "patrol", "camera_lowered", "reward", "journal")
var fixture_phase := "invitation"

@onready var slice: VerticalSliceMode = %YoukaiMountainSliceMode


func _enter_tree() -> void:
	var kernel := get_node_or_null("/root/GameKernel")
	if kernel == null:
		return
	kernel.clear_state()
	var created: Variant = kernel.create_new_profile(&"p133", &"accessibility.story")
	if not created is CommandResult or not created.is_success():
		push_error("M13 mountain screenshot profile could not be created")
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	var save_service := get_node_or_null("/root/SaveService")
	if save_service != null:
		save_service.configure_for_test(
			kernel,
			isolated_save_root(fixture_phase, OS.get_process_id())
		)


static func isolated_save_root(phase: String, process_id: int) -> String:
	# Screenshot jobs may run in parallel. AtomicFileWriter intentionally uses a
	# stable `<slot>.tmp` name, so sharing one test root across OS processes can
	# make an otherwise valid checkpoint lose its commit race.
	return "%s/%s/process_%d" % [SAVE_ROOT_BASE, phase, process_id]


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	if slice == null:
		return
	slice.configure_fixture(requested_profile, locale, forced_profile, is_reduced_motion, is_safe_flash)
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
	_confirm()
	if not slice.complete_exploration_for_test():
		push_error("M13 mountain screenshot exploration setup failed")
		return
	_confirm()
	_confirm()
	if fixture_phase == "choice":
		return
	_confirm()
	_confirm()
	_confirm()
	if not slice.submit_mode_result_for_test(&"clear"):
		push_error("M13 mountain screenshot Wind-Frame result failed")
		return
	_confirm()
	if fixture_phase == "patrol":
		return
	slice.arm_input_for_test()
	_confirm()
	if fixture_phase == "camera_lowered":
		return
	slice.arm_input_for_test()
	_confirm()
	if fixture_phase == "reward":
		return
	_confirm()
	_confirm()


func _confirm() -> void:
	slice.handle_semantic_action(GameInput.CONFIRM)
