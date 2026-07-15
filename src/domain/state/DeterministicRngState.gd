class_name DeterministicRngState
extends RefCounted
## Serialized xorshift32 state for reproducible event and combat seed derivation.

const MASK_32 := 0xffffffff
const ZERO_SEED_FALLBACK := 0x6d2b79f5

var initial_seed: int = 1
var current_state: int = 1
var draw_count: int = 0


func _init(seed: int = 1) -> void:
	reseed(seed)


func reseed(seed: int) -> void:
	initial_seed = seed & MASK_32
	if initial_seed == 0:
		initial_seed = ZERO_SEED_FALLBACK
	current_state = initial_seed
	draw_count = 0


func next_u32() -> int:
	var value := current_state & MASK_32
	value ^= (value << 13) & MASK_32
	value ^= value >> 17
	value ^= (value << 5) & MASK_32
	current_state = value & MASK_32
	draw_count += 1
	return current_state


func next_int(max_exclusive: int) -> int:
	assert(max_exclusive > 0, "max_exclusive must be positive")
	return next_u32() % max_exclusive


func next_range(minimum: int, maximum_exclusive: int) -> int:
	assert(maximum_exclusive > minimum, "range must contain at least one value")
	return minimum + next_int(maximum_exclusive - minimum)


func fork_seed(context_id: StringName) -> int:
	var digest := ("%d:%s" % [current_state, context_id]).sha256_text()
	var derived := digest.substr(0, 8).hex_to_int() & MASK_32
	return derived if derived != 0 else ZERO_SEED_FALLBACK


func duplicate_state() -> DeterministicRngState:
	var copy := DeterministicRngState.new(initial_seed)
	copy.current_state = current_state
	copy.draw_count = draw_count
	return copy
