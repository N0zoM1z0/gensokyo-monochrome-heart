class_name MinigameAssistSettings
extends RefCounted
## Mechanical accessibility only; these settings never change story rewards.

var slower_heat_change: bool = false
var wider_target_band: bool = false
var no_timer: bool = false
var slower_pace: bool = false
var wider_timing_window: bool = false


func any_enabled() -> bool:
	return slower_heat_change or wider_target_band or no_timer or slower_pace or wider_timing_window


func duplicate_settings() -> MinigameAssistSettings:
	var copy := MinigameAssistSettings.new()
	copy.slower_heat_change = slower_heat_change
	copy.wider_target_band = wider_target_band
	copy.no_timer = no_timer
	copy.slower_pace = slower_pace
	copy.wider_timing_window = wider_timing_window
	return copy
