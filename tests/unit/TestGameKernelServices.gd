class_name TestGameKernelServices
extends RefCounted
## Active-state ownership plus SaveService use-case integration tests.

const GAME_KERNEL_SCRIPT := preload("res://src/autoload/GameKernel.gd")
const SAVE_SERVICE_SCRIPT := preload("res://src/autoload/SaveService.gd")
const TEST_ROOT := "user://tests/m03_kernel_services"
const T1 := "2026-07-15T13:00:00Z"
const T2 := "2026-07-15T14:00:00Z"


func run() -> Array[String]:
	var failures: Array[String] = []
	_remove_tree(TEST_ROOT)
	var content := ContentRepository.new()
	if not content.load_sources().is_success():
		return ["could not load typed content for GameKernel"]
	var kernel := GAME_KERNEL_SCRIPT.new()
	kernel.configure_content_for_test(content)
	_expect_profile_lifecycle(kernel, failures)
	_expect_command_gateway(kernel, failures)
	_expect_save_service(kernel, failures)
	kernel.free()
	_remove_tree(TEST_ROOT)
	return failures


func _expect_profile_lifecycle(kernel: Node, failures: Array[String]) -> void:
	for presentation_id: StringName in [&"A", &"B", &"C", &"D"]:
		var expected_number := [&"A", &"B", &"C", &"D"].find(presentation_id) + 1
		if ProfileIdentityRules.story_profile_id(presentation_id) != StringName("p%02d" % expected_number):
			failures.append("presentation profile %s mapped to the wrong story profile" % presentation_id)
	if ProfileIdentityRules.story_profile_id(&"unknown") != &"" or ProfileIdentityRules.is_valid_story_profile(&"profile_1"):
		failures.append("profile identity rules accepted an unstable identity")
	var invalid: CommandResult = kernel.create_new_profile(&"profile_2")
	if invalid.is_success() or kernel.has_active_state():
		failures.append("GameKernel accepted an invalid profile ID")
	var created: CommandResult = kernel.create_new_profile(&"p02", &"accessibility.low_motion")
	if not created.is_success() or not kernel.has_active_state() or kernel.revision() != 1:
		failures.append("GameKernel could not create its deterministic active state")
		return
	var first := kernel.state_snapshot() as GameState
	var first_canonical := GameStateCodec.new().canonical_state(first)
	if first.profile_id != &"p02" or first.protagonist.comfort_profile_id != &"accessibility.low_motion":
		failures.append("new profile lost identity or comfort metadata")
	first.day = 99
	if kernel.state_snapshot().day != 1:
		failures.append("GameKernel leaked mutable ownership through state_snapshot")
	kernel.clear_state()
	kernel.create_new_profile(&"p02", &"accessibility.low_motion")
	if GameStateCodec.new().canonical_state(kernel.state_snapshot()) != first_canonical:
		failures.append("recreating one profile produced a nondeterministic default state")


func _expect_command_gateway(kernel: Node, failures: Array[String]) -> void:
	var opening_revision: int = kernel.revision()
	var changed: CommandResult = kernel.dispatch(
		SetFlagCommand.new(FlagState.from_value(&"flag.fixture.kernel", true))
	)
	if not changed.is_success() or kernel.revision() != opening_revision + 1:
		failures.append("GameKernel did not commit and revision a valid command")
	var rejected: CommandResult = kernel.dispatch(
		RemoveInventoryItemCommand.new(&"item.fixture.missing", 1)
	)
	if rejected.is_success() or kernel.revision() != opening_revision + 1:
		failures.append("GameKernel revisioned a rejected command")
	var success_commands: Array[GameCommand] = [
		SetFlagCommand.new(FlagState.from_value(&"flag.fixture.kernel_transaction", true)),
		AddInventoryItemCommand.new(&"item.fixture.kernel_transaction", 1),
	]
	var transaction: CommandResult = kernel.dispatch_transaction(success_commands)
	var committed := kernel.state_snapshot() as GameState
	if not transaction.is_success() or not committed.flags.has(&"flag.fixture.kernel_transaction") or not committed.inventory.items.has(&"item.fixture.kernel_transaction"):
		failures.append("GameKernel did not expose an atomic multi-command gateway")
	var failure_commands: Array[GameCommand] = [
		SetFlagCommand.new(FlagState.from_value(&"flag.fixture.kernel_rollback", true)),
		RemoveInventoryItemCommand.new(&"item.fixture.still_missing", 1),
	]
	var before_failure := GameStateCodec.new().canonical_state(kernel.state_snapshot())
	if kernel.dispatch_transaction(failure_commands).is_success():
		failures.append("GameKernel accepted a failing multi-command transaction")
	if GameStateCodec.new().canonical_state(kernel.state_snapshot()) != before_failure:
		failures.append("GameKernel leaked a partial transaction mutation")


func _expect_save_service(kernel: Node, failures: Array[String]) -> void:
	var service := SAVE_SERVICE_SCRIPT.new()
	service.configure_for_test(kernel, TEST_ROOT)
	var context := SaveCardContext.new()
	context.visible_character_ids = [&"char.reimu_hakurei"]
	var opening := GameStateCodec.new().canonical_state(kernel.state_snapshot())
	var saved: SaveOperationResult = service.save_manual(1, context, T1)
	if not saved.is_success():
		failures.append("SaveService could not persist an active manual slot: %s" % saved.message)
		return
	kernel.dispatch(AdvanceTimeCommand.new(1))
	if kernel.state_snapshot().time_slot == &"morning":
		failures.append("SaveService fixture did not diverge before load")
	var loaded: SaveOperationResult = service.load_slot(&"p02", &"manual_01")
	if not loaded.is_success() or GameStateCodec.new().canonical_state(kernel.state_snapshot()) != opening:
		failures.append("SaveService load did not atomically activate the saved snapshot")
	for reason: StringName in [&"day_start", &"event_completion", &"before_mode"]:
		var autosaved: SaveOperationResult = service.autosave(reason, null, T2)
		if not autosaved.is_success():
			failures.append("SaveService rejected safe autosave boundary %s" % reason)
	if service.list_cards(&"p02").size() != 4:
		failures.append("SaveService did not expose one manual and three rolling cards")
	if service.autosave(&"inside_collision").code != SaveOperationResult.Code.INVALID_SLOT:
		failures.append("SaveService accepted an unsafe autosave boundary")
	if service.save_manual(4).code != SaveOperationResult.Code.INVALID_SLOT:
		failures.append("SaveService accepted a fourth manual slot")
	kernel.clear_state()
	if service.save_manual(1).code != SaveOperationResult.Code.INVALID_STATE:
		failures.append("SaveService saved without an active GameState")
	service.free()


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
