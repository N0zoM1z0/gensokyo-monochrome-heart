extends Control
## Minimal M00 boot surface. Gameplay and navigation arrive in later milestones.


func _ready() -> void:
	set_process_unhandled_input(false)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(320, 180)), Color.WHITE)
	draw_rect(Rect2(8, 8, 304, 164), Color.BLACK, false, 2.0)
	draw_rect(Rect2(16, 16, 288, 8), Color.BLACK)
	draw_rect(Rect2(16, 156, 288, 8), Color.BLACK)
