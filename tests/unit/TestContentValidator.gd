class_name TestContentValidator
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var validator := ContentValidator.new()
	var valid_report := validator.validate_project()
	if not valid_report.is_valid():
		failures.append("valid starter content failed: %s" % "; ".join(valid_report.errors))
	var duplicate_report := validator.validate_duplicate_fixture(
		[
			"res://tests/fixtures/invalid/duplicate_ids/characters_a.json",
			"res://tests/fixtures/invalid/duplicate_ids/characters_b.json",
		]
	)
	if duplicate_report.errors.size() != 1:
		failures.append("duplicate fixture expected exactly one error, got %d" % duplicate_report.errors.size())
	elif not duplicate_report.errors[0].contains("characters_a.json") or not duplicate_report.errors[0].contains("characters_b.json"):
		failures.append("duplicate error must report both source paths: %s" % duplicate_report.errors[0])
	return failures
