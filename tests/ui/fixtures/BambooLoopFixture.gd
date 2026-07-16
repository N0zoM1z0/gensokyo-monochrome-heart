class_name BambooLoopFixture
extends ExplorationMode
## Deterministic screenshot states for the four-dawn seam and its fair cue.

@export_range(0, 3) var fixture_dawn: int = 0
@export var fixture_prime_current_anchor: bool = false
@export var fixture_wrong_crossing: bool = false
@export var fixture_successful_crossing: bool = false
@export var fixture_player_x: float = 112.0


func _ready() -> void:
	super._ready()
	_apply_bamboo_fixture_state()


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	super.configure_fixture(requested_profile, locale, forced_profile, is_reduced_motion, is_safe_flash)
	_apply_bamboo_fixture_state()


func _apply_bamboo_fixture_state() -> void:
	if loop_topology == null:
		return
	for index: int in range(fixture_dawn):
		var anchor_id := BambooFourDawnsTopology.ANCHOR_SEQUENCE[index]
		loop_topology.observe_anchor(anchor_id)
		var transition := loop_topology.cross_exit()
		objective_tracker.observe(transition.accepted_anchor_id)
	if fixture_prime_current_anchor:
		interact_target_for_test(BambooFourDawnsTopology.ANCHOR_SEQUENCE[fixture_dawn])
	if fixture_successful_crossing:
		loop_topology.observe_anchor(BambooFourDawnsTopology.ANCHOR_SEQUENCE[fixture_dawn])
		set_player_position_for_test(Vector2(585, 140), Vector2.RIGHT)
		step_fixture(1.0, 2)
	elif fixture_wrong_crossing:
		set_player_position_for_test(Vector2(585, 140), Vector2.RIGHT)
		step_fixture(1.0, 2)
	else:
		set_player_position_for_test(Vector2(fixture_player_x, 140), Vector2.RIGHT)
	_refresh_text_cache()
