class_name GameInput
extends RefCounted
## Stable semantic actions shared by keyboard and controller bindings.

const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const CONFIRM: StringName = &"confirm"
const CANCEL: StringName = &"cancel"
const COMPANION: StringName = &"companion"
const BOMB: StringName = &"bomb"
const JOURNAL: StringName = &"journal"
const MAP: StringName = &"map"
const PAGE_LEFT: StringName = &"page_left"
const PAGE_RIGHT: StringName = &"page_right"
const PAUSE: StringName = &"pause"
const ACCESSIBILITY: StringName = &"accessibility"
const SHOT: StringName = &"shot"
const FOCUS: StringName = &"focus"
const GUARD: StringName = &"guard"
const LIGHT: StringName = &"light"
const HEAVY: StringName = &"heavy"
const SKILL: StringName = &"skill"
const SPELL: StringName = &"spell"
const MENU: StringName = &"menu"

const ALL_ACTIONS := [
	MOVE_UP,
	MOVE_DOWN,
	MOVE_LEFT,
	MOVE_RIGHT,
	CONFIRM,
	CANCEL,
	COMPANION,
	BOMB,
	JOURNAL,
	MAP,
	PAGE_LEFT,
	PAGE_RIGHT,
	PAUSE,
	ACCESSIBILITY,
	SHOT,
	FOCUS,
	GUARD,
	LIGHT,
	HEAVY,
	SKILL,
	SPELL,
	MENU,
]
