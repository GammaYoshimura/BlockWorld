class_name Crosshair
extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var white: Color = Color.WHITE
	var outline: Color = Color.BLACK
	# Four short bars leave the center pixel open, making the target easy to see.
	for rect: Rect2 in [
		Rect2(center + Vector2(-5.0, -1.0), Vector2(4.0, 2.0)),
		Rect2(center + Vector2(1.0, -1.0), Vector2(4.0, 2.0)),
		Rect2(center + Vector2(-1.0, -5.0), Vector2(2.0, 4.0)),
		Rect2(center + Vector2(-1.0, 1.0), Vector2(2.0, 4.0))
	]:
		draw_rect(rect.grow(1.0), outline)
		draw_rect(rect, white)
