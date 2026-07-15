class_name TestAuthoringWorkbench
extends RefCounted
## M11 registry contracts for scene, migration, and legal-tone debug targets.


func run() -> Array[String]:
	var failures: Array[String] = []
	var service := AuthoringWorkbenchService.new()
	var validation := service.validate_registry()
	if not validation.is_valid():
		failures.append("workbench registry failed: %s" % validation.human_readable())
	var targets := service.targets()
	if targets.size() != 19:
		failures.append("workbench expected 19 targets, got %d" % targets.size())
	var catalog := service.render_catalog()
	if not catalog.is_valid() or not catalog.output.contains("- Targets: 19"):
		failures.append("workbench catalog failed: %s" % catalog.human_readable())
	for expected: String in ["scene.tea.active", "scene.danmaku.stress", "scene.danmaku.lab", "scene.fighter.hitbox", "save.v1_route_affinity", "tone.reimu_private"]:
		if not catalog.output.contains(expected):
			failures.append("workbench catalog omitted %s" % expected)
	var save := service.inspect_target(&"save.v1_route_affinity")
	if not save.is_valid() or not save.output.contains("MIGRATION migrated=yes") or not save.output.contains("schema=2"):
		failures.append("migration target failed: %s" % save.human_readable())
	var tone := service.inspect_target(&"tone.shrine_day")
	if not tone.is_valid() or not tone.output.contains("pitch_hz=196.00"):
		failures.append("legal tone target failed: %s" % tone.human_readable())
	var hitbox := service.inspect_target(&"scene.fighter.hitbox")
	if not hitbox.is_valid() or hitbox.target.definition_path != AuthoringWorkbenchService.FIGHTER_DEFINITION:
		failures.append("fighter hitbox target lost its reviewed definition")
	var unknown := service.inspect_target(&"scene.unknown")
	if unknown.is_valid() or "unknown workbench target" not in "; ".join(unknown.errors):
		failures.append("unknown workbench target was not rejected")
	return failures
