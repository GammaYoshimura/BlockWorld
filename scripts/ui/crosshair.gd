class_name Crosshair
extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	# Minecraft-style continuous plus: thin white arms with a dark outline.
	draw_rect(Rect2(center + Vector2(-1.5, -5.5), Vector2(3.0, 11.0)), Color.BLACK)
	draw_rect(Rect2(center + Vector2(-5.5, -1.5), Vector2(11.0, 3.0)), Color.BLACK)
	draw_rect(Rect2(center + Vector2(-0.5, -5.0), Vector2(1.0, 10.0)), Color.WHITE)
	draw_rect(Rect2(center + Vector2(-5.0, -0.5), Vector2(10.0, 1.0)), Color.WHITE)
