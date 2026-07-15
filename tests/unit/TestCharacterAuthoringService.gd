class_name TestCharacterAuthoringService
extends RefCounted
## M11 contracts for the roster browser, skill reader, and agent-output rules.


func run() -> Array[String]:
	var failures: Array[String] = []
	var service := CharacterAuthoringService.new()
	var catalog := service.render_catalog()
	if not catalog.is_valid():
		failures.append("character skills catalog failed: %s" % catalog.human_readable())
	else:
		for expected: String in ["- Characters: 71", "- Ready: 71", "- Invalid: 0", "`char.reimu_hakurei`", "`char.yuyuko_saigyouji`"]:
			if not catalog.output.contains(expected):
				failures.append("character catalog omitted %s" % expected)
	var skill := service.render_skill(&"char.reimu_hakurei")
	if not skill.is_valid():
		failures.append("Reimu skill document failed: %s" % skill.human_readable())
	else:
		for expected: String in ["# Reimu Hakurei — Character Agent Skills", "## 8. Agent runtime contract", "## 10. Source notes"]:
			if not skill.output.contains(expected):
				failures.append("Reimu skill browser omitted %s" % expected)
	var valid := service.validate_agent_output(
		&"char.reimu_hakurei",
		"res://tests/fixtures/authoring/valid_reimu_agent_output.json"
	)
	if not valid.is_valid() or not valid.output.contains("changed_facets=trust"):
		failures.append("valid Reimu agent output failed: %s" % valid.human_readable())
	_expect_failure(
		service,
		"res://tests/fixtures/invalid/authoring/multiple_agent_state_changes.json",
		"at most one state facet may change",
		failures
	)
	_expect_failure(
		service,
		"res://tests/fixtures/invalid/authoring/missing_agent_japanese.json",
		"missing required property spoken_line_ja",
		failures
	)
	var unknown := service.render_skill(&"char.unknown_fixture")
	if unknown.is_valid() or "unknown character ID" not in "; ".join(unknown.errors):
		failures.append("unknown skill ID was not rejected")
	return failures


func _expect_failure(
	service: CharacterAuthoringService,
	path: String,
	expected: String,
	failures: Array[String]
) -> void:
	var result := service.validate_agent_output(&"char.reimu_hakurei", path)
	if result.is_valid() or expected not in "; ".join(result.errors):
		failures.append("invalid agent fixture omitted '%s': %s" % [expected, result.human_readable()])
