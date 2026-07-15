class_name TestScreenshotFixture
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
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
