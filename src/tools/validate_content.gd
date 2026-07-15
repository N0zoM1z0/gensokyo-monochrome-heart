extends SceneTree
## Headless entry point for project content validation.


func _initialize() -> void:
	var validator := ContentValidator.new()
	var report: ContentValidationReport
	var user_args := OS.get_cmdline_user_args()
	if "--fixture-duplicate-ids" in user_args:
		report = validator.validate_duplicate_fixture(
			[
				"res://tests/fixtures/invalid/duplicate_ids/characters_a.json",
				"res://tests/fixtures/invalid/duplicate_ids/characters_b.json",
			]
		)
	else:
		report = validator.validate_project()
	_print_report(report)
	quit(0 if report.is_valid() else 1)


func _print_report(report: ContentValidationReport) -> void:
	print("Content validation: checks=%d errors=%d warnings=%d" % [report.checks, report.errors.size(), report.warnings.size()])
	for note: String in report.notes:
		print("NOTE: %s" % note)
	for warning: String in report.warnings:
		print("WARNING: %s" % warning)
	for error: String in report.errors:
		printerr("ERROR: %s" % error)
