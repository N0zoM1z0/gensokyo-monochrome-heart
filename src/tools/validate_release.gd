extends SceneTree
## Headless release-channel gate for placeholder assets and identifiers.

const PLACEHOLDER_FIXTURE := "res://tests/fixtures/release/ph_deliberate_placeholder.tres"


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var scanner := ReleasePlaceholderScanner.new()
	var errors: Array[String] = []
	if "--fixture-placeholder" in arguments:
		errors = scanner.scan_roots([PLACEHOLDER_FIXTURE])
	elif "--release" in arguments or BuildChannel.current() == BuildChannel.Kind.RELEASE:
		errors = scanner.scan_release_inputs()
	else:
		print("Release validation skipped outside the release channel; pass --release to force it.")
		quit(0)
		return
	print("Release validation: files=%d errors=%d" % [scanner.scanned_files, errors.size()])
	for error: String in errors:
		printerr("ERROR: %s" % error)
	quit(0 if errors.is_empty() else 1)
