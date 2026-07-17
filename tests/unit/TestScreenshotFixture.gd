class_name TestScreenshotFixture
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect_parallel_mountain_fixture_isolation(failures)
	_expect_safe_slice_error_page(failures)
	var packed_scene := load("res://tests/ui/fixtures/VisualFoundationFixture.tscn") as PackedScene
	var fixture := packed_scene.instantiate() as VisualFoundationFixture
	var expected_actions := fixture.action_contract()
	for profile_id: StringName in [&"A", &"B", &"C", &"D"]:
		fixture.configure_fixture(profile_id, &"en")
		if fixture.resolved_profile_id() != profile_id:
			failures.append("fixture did not resolve profile %s" % profile_id)
		if fixture.action_contract() != expected_actions:
			failures.append("profile %s changed the fixture action contract" % profile_id)
	fixture.configure_fixture(&"D", &"ja", &"A", true, true)
	if fixture.resolved_profile_id() != &"A":
		failures.append("forced Profile A did not override the native fixture profile")
	if fixture.action_contract().size() != 15:
		failures.append("fixture action contract does not match the 15 UI token actions")
	fixture.free()
	return failures


func _expect_parallel_mountain_fixture_isolation(failures: Array[String]) -> void:
	var first := MountainSliceFixture.isolated_save_root("patrol", 1001)
	var second := MountainSliceFixture.isolated_save_root("patrol", 1002)
	if first == second or not first.ends_with("/patrol/process_1001"):
		failures.append("parallel mountain screenshot fixtures do not isolate atomic save roots")


func _expect_safe_slice_error_page(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(
		"res://src/presentation/slice/VerticalSliceMode.gd"
	)
	if source.contains("_draw_text(_diagnostic"):
		failures.append("vertical-slice recovery page exposes raw diagnostics to players")
	if not source.contains("push_error(\"Vertical slice stopped: %s\" % message)"):
		failures.append("vertical-slice failures no longer preserve diagnostics in the engine log")
