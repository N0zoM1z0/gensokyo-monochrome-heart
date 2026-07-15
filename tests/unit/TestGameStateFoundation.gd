class_name TestGameStateFoundation
extends RefCounted
## M03 pure-state, semantic-band, invariant, clone, and deterministic RNG tests.


func run() -> Array[String]:
	var failures: Array[String] = []
	var repository := ContentRepository.new()
	if not repository.load_sources().is_success():
		return ["could not load ContentDB IDs for GameState factory"]
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in repository.all_characters():
		character_ids.append(character.id)
	var region_ids: Array[StringName] = []
	for location: LocationRecord in repository.all_locations():
		region_ids.append(location.id)
	var first := GameStateFactory.create_new(&"p01", character_ids, region_ids)
	var second := GameStateFactory.create_new(&"p01", character_ids, region_ids)
	_expect_deterministic_default(first, second, failures)
	_expect_relationship_bands(first, failures)
	_expect_deep_copy(first, failures)
	_expect_rng(failures)
	_expect_time_rules(first, failures)
	_expect_invariants(first, failures)
	_expect_restricted_flags(failures)
	return failures


func _expect_deterministic_default(first: GameState, second: GameState, failures: Array[String]) -> void:
	if first.profile_id != &"p01" or first.schema_version != 2:
		failures.append("new profile omitted its stable ID or current schema")
	if first.characters.size() != 71 or first.regions.size() != 19:
		failures.append("new profile expected 71 characters and 19 regions")
	if first.protagonist.profile_seed != second.protagonist.profile_seed:
		failures.append("same profile ID produced different deterministic seeds")
	if first.rng.current_state != second.rng.current_state or first.rng.draw_count != 0:
		failures.append("new profile RNG state is nondeterministic")
	if first.inventory.selected_tea_blend_id != InventoryState.PLAIN_TEA_ID:
		failures.append("new profile did not select the plain daily Tea Blend")
	if not first.inventory.tea_blends.has(InventoryState.PLAIN_TEA_ID):
		failures.append("new profile did not unlock the baseline Tea Blend")
	if not GameStateValidator.new().validate(first).is_empty():
		failures.append("deterministic new profile failed state invariants")


func _expect_relationship_bands(state: GameState, failures: Array[String]) -> void:
	var relationship := state.characters[&"char.reimu_hakurei"].relationship
	for value: int in [-3, -1, 0]:
		RelationshipFacetRules.set_value(relationship, &"trust", value)
		if RelationshipFacetRules.band_for(relationship, &"trust") != &"low":
			failures.append("trust=%d should resolve to the low semantic band" % value)
	for value: int in [1, 2]:
		RelationshipFacetRules.set_value(relationship, &"trust", value)
		if RelationshipFacetRules.band_for(relationship, &"trust") != &"open":
			failures.append("trust=%d should resolve to the open semantic band" % value)
	RelationshipFacetRules.set_value(relationship, &"trust", 99)
	if relationship.trust != 3 or RelationshipFacetRules.band_for(relationship, &"trust") != &"high":
		failures.append("relationship rules did not clamp or expose the high band")
	if not RelationshipFacetRules.is_at_least(relationship, &"trust", &"open"):
		failures.append("semantic at-least comparison rejected high trust")
	if RelationshipFacetRules.qualitative_key(relationship, &"trust") != &"resonance.trust.high":
		failures.append("relationship presentation key exposed the wrong semantic state")
	RelationshipFacetRules.set_value(relationship, &"trust", 0)


func _expect_deep_copy(state: GameState, failures: Array[String]) -> void:
	var copy := state.deep_copy()
	copy.day = 9
	copy.characters[&"char.reimu_hakurei"].relationship.ease = 2
	copy.inventory.tea_blends[InventoryState.PLAIN_TEA_ID].times_prepared = 4
	if state.day == copy.day:
		failures.append("GameState deep copy aliased scalar mutation")
	if state.characters[&"char.reimu_hakurei"].relationship.ease == 2:
		failures.append("GameState deep copy aliased nested relationship state")
	if state.inventory.tea_blends[InventoryState.PLAIN_TEA_ID].times_prepared == 4:
		failures.append("GameState deep copy aliased nested inventory state")


func _expect_rng(failures: Array[String]) -> void:
	var first := DeterministicRngState.new(123)
	var second := DeterministicRngState.new(123)
	var expected: Array[int] = [31682556, 4018661298, 2101636938, 3842487452, 1628673942]
	for expected_value: int in expected:
		var first_value := first.next_u32()
		var second_value := second.next_u32()
		if first_value != expected_value or second_value != expected_value:
			failures.append("xorshift32 golden sequence diverged at draw %d" % first.draw_count)
			break
	if first.fork_seed(&"evt.hkr.empty_cushion") != second.fork_seed(&"evt.hkr.empty_cushion"):
		failures.append("context seed derivation is nondeterministic")
	var cloned := first.duplicate_state()
	if cloned.next_u32() != first.next_u32():
		failures.append("serialized RNG clone did not resume the same sequence")


func _expect_time_rules(state: GameState, failures: Array[String]) -> void:
	var copy := state.deep_copy()
	copy.time_slot = &"night"
	copy.inventory.selected_tea_blend_id = InventoryState.PLAIN_TEA_ID
	if not TimeSlotRules.advance(copy) or copy.day != 2 or copy.time_slot != &"morning":
		failures.append("night-to-morning advancement did not start the next day")
	if TimeSlotRules.advance(copy, 0) or TimeSlotRules.advance(copy, 5):
		failures.append("time rules accepted an invalid slot count")


func _expect_invariants(state: GameState, failures: Array[String]) -> void:
	var invalid := state.deep_copy()
	invalid.current_location = &"loc.fixture.missing"
	invalid.characters[&"char.reimu_hakurei"].relationship.strain = 99
	var errors := GameStateValidator.new().validate(invalid)
	if not _contains(errors, "current location is absent"):
		failures.append("state validator missed an unknown current location")
	if not _contains(errors, "facet strain is outside"):
		failures.append("state validator missed an out-of-bounds hidden facet")


func _expect_restricted_flags(failures: Array[String]) -> void:
	if FlagState.from_value(&"flag.fixture.bool", true) == null:
		failures.append("boolean story flag was rejected")
	if FlagState.from_value(&"flag.fixture.integer", 3) == null:
		failures.append("integer story flag was rejected")
	if FlagState.from_value(&"flag.fixture.id", &"value.fixture") == null:
		failures.append("stable-ID story flag was rejected")
	if FlagState.from_value(&"flag.fixture.raw", {"nested": true}) != null:
		failures.append("story flags retained an arbitrary nested Dictionary")


func _contains(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false
