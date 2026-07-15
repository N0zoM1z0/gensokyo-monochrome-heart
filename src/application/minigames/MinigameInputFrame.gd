class_name MinigameInputFrame
extends RefCounted
## One fixed-step input sample shared by runtime fixtures and presentation.

var heat_direction: int = 0
var patience_held: bool = false
var pour_pressed: bool = false
var confirm_pressed: bool = false
var grid_direction: Vector2i = Vector2i.ZERO
