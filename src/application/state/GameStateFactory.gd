class_name GameStateFactory
extends RefCounted
## Deterministic new-profile construction from validated ContentDB stable IDs.


static func create_new(
	profile_id: StringName,
	character_ids: Array[StringName],
	region_ids: Array[StringName],
	seed_override: int = -1
) -> GameState:
	var state := GameState.new(profile_id)
	var seed := seed_override if seed_override >= 0 else _seed_for_profile(profile_id)
	if seed == 0:
		seed = DeterministicRngState.ZERO_SEED_FALLBACK
	state.protagonist.profile_seed = seed
	state.rng = DeterministicRngState.new(seed)
	var sorted_characters := character_ids.duplicate()
	sorted_characters.sort_custom(_id_less)
	for character_id: StringName in sorted_characters:
		state.characters[character_id] = CharacterState.new(character_id)
	var sorted_regions := region_ids.duplicate()
	sorted_regions.sort_custom(_id_less)
	for region_id: StringName in sorted_regions:
		state.regions[region_id] = RegionState.new(region_id)
	var plain_tea := TeaBlendState.new(InventoryState.PLAIN_TEA_ID)
	plain_tea.unlocked_day = 1
	state.inventory.tea_blends[plain_tea.blend_id] = plain_tea
	state.inventory.selected_tea_blend_id = plain_tea.blend_id
	return state


static func _seed_for_profile(profile_id: StringName) -> int:
	var digest := String(profile_id).sha256_text()
	return digest.substr(0, 8).hex_to_int() & DeterministicRngState.MASK_32


static func _id_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
