class_name MinigameRuntime
extends RefCounted
## Interface-like base for deterministic minigames hosted by MinigameHost.

var definition: MinigameDefinition
var mode_context: ModeContext
var assists := MinigameAssistSettings.new()
var is_paused: bool = false


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	mode_context = context
	assists = assist_settings.duplicate_settings() if assist_settings != null else MinigameAssistSettings.new()


func reset_attempt() -> void:
	is_paused = false


func step(_input: MinigameInputFrame) -> ModeResult:
	return null


func toggle_pause() -> void:
	is_paused = not is_paused


func accept_loss() -> ModeResult:
	return null
