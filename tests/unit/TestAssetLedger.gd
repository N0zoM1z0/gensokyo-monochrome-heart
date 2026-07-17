class_name TestAssetLedger
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var ledger := ReleaseAssetLedger.new()
	var errors := ledger.validate_release_assets()
	if not errors.is_empty():
		failures.append("runtime asset ledger rejected the release tree: %s" % "; ".join(errors))
	if ledger.registered_files != ledger.discovered_files or ledger.registered_files < 34:
		failures.append(
			"runtime asset coverage expected an exact registered/discovered match with the M16 audio batch, got %d/%d"
			% [ledger.registered_files, ledger.discovered_files]
		)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ReleaseAssetLedger.LEDGER_PATH))
	if not raw is Dictionary:
		failures.append("runtime asset ledger could not be independently parsed")
	else:
		var paired := 0
		var licensed := 0
		for record: Dictionary in raw.get("records", []):
			paired += int(not String(record.get("accessibility_pair", "")).is_empty())
			licensed += int(String(record.get("rights_basis", "")) == "licensed")
		if paired != 0:
			failures.append("runtime recoloring should replace duplicate polarity files, got %d paired records" % paired)
		if licensed != 2:
			failures.append("expected two explicitly licensed font files, got %d" % licensed)
	return failures
