class_name ScreenRouteResult
extends RefCounted
## Explicit route outcome used by shell code and integration tests.

enum Code {
	OK,
	BUSY,
	UNKNOWN_ROUTE,
	HOST_MISSING,
	LOAD_REQUEST_FAILED,
	LOAD_FAILED,
	INSTANTIATION_FAILED,
}

var code: Code
var screen_id: StringName
var screen: Node
var diagnostic: String


func _init(
	p_code: Code,
	p_screen_id: StringName,
	p_screen: Node = null,
	p_diagnostic: String = ""
) -> void:
	code = p_code
	screen_id = p_screen_id
	screen = p_screen
	diagnostic = p_diagnostic


func is_success() -> bool:
	return code == Code.OK


static func success(p_screen_id: StringName, p_screen: Node) -> ScreenRouteResult:
	return ScreenRouteResult.new(Code.OK, p_screen_id, p_screen)


static func failure(
	p_code: Code,
	p_screen_id: StringName,
	p_diagnostic: String
) -> ScreenRouteResult:
	return ScreenRouteResult.new(p_code, p_screen_id, null, p_diagnostic)
