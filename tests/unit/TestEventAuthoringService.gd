class_name TestEventAuthoringService
extends RefCounted
## M11 contract test for the nonprogrammer event duplicate/edit/validate/preview loop.

const BUNDLE_PATH := "user://tests/m11_event_authoring/writer_fixture"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(ProjectSettings.globalize_path(BUNDLE_PATH).get_base_dir())
	var service := EventAuthoringService.new()
	var duplicated := service.duplicate_empty_cushion(&"evt.hkr.writer_fixture", BUNDLE_PATH)
	if not duplicated.is_valid():
		failures.append("valid Empty Cushion duplication failed: %s" % duplicated.human_readable())
		return failures
	_expect_isolated_remap(failures)
	_edit_authored_data(failures)
	var edited := service.validate_bundle(BUNDLE_PATH)
	if not edited.is_valid():
		failures.append("data-only event edits failed validation: %s" % edited.human_readable())
	else:
		_expect_bilingual_preview(service, edited, failures)
		_expect_authoring_reports(service, edited, failures)
	_expect_missing_reference_failure(service, failures)
	_remove_tree(ProjectSettings.globalize_path(BUNDLE_PATH).get_base_dir())
	return failures


func _expect_isolated_remap(failures: Array[String]) -> void:
	for file_name: String in ["manifest.json", "event.json", "dialogue.json", "strings.csv"]:
		var path := BUNDLE_PATH.path_join(file_name)
		if not FileAccess.file_exists(path):
			failures.append("duplicated bundle omitted %s" % file_name)
			continue
		var contents := FileAccess.get_file_as_string(path)
		# The manifest intentionally records provenance; authored payloads must be isolated.
		if file_name != "manifest.json" and contents.contains("hkr.empty_cushion"):
			failures.append("duplicated bundle retained the template namespace in %s" % file_name)
	if FileAccess.get_file_as_string(BUNDLE_PATH.path_join("event.json")).contains("evt.hkr.writer_fixture.complete") == false:
		failures.append("event-private completion flag was not remapped")


func _edit_authored_data(failures: Array[String]) -> void:
	var event_path := BUNDLE_PATH.path_join("event.json")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(event_path))
	if not raw is Dictionary:
		failures.append("could not parse duplicated event for writer edit")
		return
	raw.nodes.n002.interactable_ids[0] = "prop.writer_fixture_cup"
	raw.nodes.n010.outcome = "writer_complete"
	_write_text(event_path, JSON.stringify(raw, "  ", false) + "\n", failures)
	var strings_path := BUNDLE_PATH.path_join("strings.csv")
	var csv := FileAccess.get_file_as_string(strings_path)
	csv = csv.replace("The Empty Cushion", "A Writer's Cushion")
	csv = csv.replace("空いたままの座布団", "書き手の座布団")
	_write_text(strings_path, csv, failures)


func _expect_bilingual_preview(
	service: EventAuthoringService,
	bundle: EventAuthoringBundle,
	failures: Array[String]
) -> void:
	var english := service.render_preview(bundle, &"en")
	var japanese := service.render_preview(bundle, &"ja")
	for expected: String in ["A Writer's Cushion", "prop.writer_fixture_cup", "Outcome: **writer_complete**"]:
		if not english.contains(expected):
			failures.append("English preview omitted edited data: %s" % expected)
	if not japanese.contains("書き手の座布団"):
		failures.append("Japanese preview omitted the edited localized title")
	if english.contains("書き手の座布団") or japanese.contains("A Writer's Cushion"):
		failures.append("bilingual previews leaked the opposite locale")


func _expect_authoring_reports(
	service: EventAuthoringService,
	bundle: EventAuthoringBundle,
	failures: Array[String]
) -> void:
	var dependencies := service.render_dependency_report(bundle)
	for expected: String in [
		"| `evt.hkr.writer_fixture` | location | `loc.hakurei_shrine` |",
		"| `evt.hkr.writer_fixture.node.n002` | interactable | `prop.writer_fixture_cup` |",
		"| `beat.hkr.writer_fixture.reimu.001` | localization | `dlg.hkr.writer_fixture.reimu.001` |",
	]:
		if not dependencies.contains(expected):
			failures.append("dependency report omitted edge: %s" % expected)
	if dependencies != service.render_dependency_report(bundle):
		failures.append("dependency report is nondeterministic")
	for locale: StringName in [&"en", &"ja"]:
		for scale: int in [100, 150]:
			var widths := service.render_width_report(bundle, locale, scale)
			for expected: String in [
				"- Locale: `%s`" % locale,
				"- UI scale: `%d%%`" % scale,
				"- Strings: 27",
				"| `event.hkr.writer_fixture.title` | event title |",
			]:
				if not widths.contains(expected):
					failures.append("width report omitted %s/%d evidence: %s" % [locale, scale, expected])
			if widths != service.render_width_report(bundle, locale, scale):
				failures.append("width report is nondeterministic for %s/%d" % [locale, scale])


func _expect_missing_reference_failure(service: EventAuthoringService, failures: Array[String]) -> void:
	var event_path := BUNDLE_PATH.path_join("event.json")
	var valid_contents := FileAccess.get_file_as_string(event_path)
	var raw: Variant = JSON.parse_string(valid_contents)
	raw.nodes.n003.beat_id = "beat.hkr.writer_fixture.missing"
	_write_text(event_path, JSON.stringify(raw, "  ", false) + "\n", failures)
	var invalid := service.validate_bundle(BUNDLE_PATH)
	var found := false
	for error: String in invalid.errors:
		if error.contains("n003 references missing beat beat.hkr.writer_fixture.missing"):
			found = true
			break
	if invalid.is_valid() or not found:
		failures.append("missing authored beat did not produce a source-specific validation failure")
	_write_text(event_path, valid_contents, failures)


func _write_text(path: String, contents: String, failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write test fixture %s" % path)
		return
	file.store_string(contents)


func _remove_tree(absolute_path: String) -> void:
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := absolute_path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute_path)
