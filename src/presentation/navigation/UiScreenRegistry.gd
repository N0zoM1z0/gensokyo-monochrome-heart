class_name UiScreenRegistry
extends RefCounted
## Reviewed route IDs mapped to presentation scenes and persistent shell hosts.

const SCREEN_HOST: StringName = &"screen"
const MODE_HOST: StringName = &"mode"

const ROUTES := {
	&"title": {
		"path": "res://ui/screens/title_screen.tscn",
		"host": SCREEN_HOST,
	},
	&"profile_select": {
		"path": "res://ui/screens/profile_select.tscn",
		"host": SCREEN_HOST,
	},
	&"accessibility": {
		"path": "res://ui/screens/accessibility_screen.tscn",
		"host": SCREEN_HOST,
	},
	&"options": {
		"path": "res://ui/screens/options_screen.tscn",
		"host": SCREEN_HOST,
	},
	&"credits": {
		"path": "res://ui/screens/credits_screen.tscn",
		"host": SCREEN_HOST,
	},
	&"foundation_mode": {
		"path": "res://src/presentation/modes/FoundationMode.tscn",
		"host": MODE_HOST,
	},
	&"vertical_slice": {
		"path": "res://src/presentation/slice/VerticalSliceMode.tscn",
		"host": MODE_HOST,
	},
}


static func has_route(screen_id: StringName) -> bool:
	return ROUTES.has(screen_id)


static func scene_path(screen_id: StringName) -> String:
	return String(ROUTES.get(screen_id, {}).get("path", ""))


static func host_id(screen_id: StringName) -> StringName:
	return StringName(ROUTES.get(screen_id, {}).get("host", SCREEN_HOST))
