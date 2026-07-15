class_name TestReleasePlaceholderScanner
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var scanner := ReleasePlaceholderScanner.new()
	var valid_errors := scanner.scan_release_inputs()
	if not valid_errors.is_empty():
		failures.append("valid release roots contain placeholder records: %s" % "; ".join(valid_errors))
	var fixture_errors := scanner.scan_roots(
		["res://tests/fixtures/release/ph_deliberate_placeholder.tres"]
	)
	if fixture_errors.size() < 2:
		failures.append("placeholder fixture did not fail by filename and ID: %s" % fixture_errors)
	var has_path := false
	for error: String in fixture_errors:
		has_path = has_path or error.contains("ph_deliberate_placeholder.tres")
	if not has_path:
		failures.append("placeholder fixture error omitted the source path")
	return failures
