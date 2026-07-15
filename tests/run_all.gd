extends SceneTree
## Minimal deterministic headless test runner. Later milestones register more suites here.


func _initialize() -> void:
	var suites: Array[RefCounted] = [
		TestAuthoringWorkbench.new(),
		TestCharacterAuthoringService.new(),
		TestContentDB.new(),
		TestContentRepository.new(),
		TestContentValidator.new(),
		TestDanmakuFoundation.new(),
		TestDialogueRuntime.new(),
		TestEventAuthoringService.new(),
		TestEventInterpreter.new(),
		TestExplorationFoundation.new(),
		TestFighterFoundation.new(),
		TestFontAssets.new(),
		TestGameCommands.new(),
		TestGameKernelServices.new(),
		TestGameStateCodec.new(),
		TestGameStateFoundation.new(),
		TestGameStateInspector.new(),
		TestInputFoundation.new(),
		TestJsonSchemaValidator.new(),
		TestLocalizationFoundation.new(),
		TestMinigameFoundation.new(),
		TestNavigationFoundation.new(),
		TestPresentationFoundation.new(),
		TestReleasePlaceholderScanner.new(),
		TestSaveMigrations.new(),
		TestSaveRepository.new(),
		TestScreenshotFixture.new(),
		TestVisualValidators.new(),
		TestVerticalSliceServices.new(),
	]
	var failures: Array[String] = []
	var executed := 0
	for suite: RefCounted in suites:
		executed += 1
		for failure: String in suite.run():
			failures.append("%s: %s" % [suite.get_script().resource_path, failure])
	print("Test run: suites=%d failures=%d" % [executed, failures.size()])
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
