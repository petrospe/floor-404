class_name PanelPowerLamp
extends Control
## Cabinet power lamp. Dark until the circuit is complete, then green.
## Named apart from Godot 4.7's native StatusIndicator node.


var lit := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(28, 28)
	size = Vector2(28, 28)


func set_lit(next: bool) -> void:
	if lit == next:
		return
	lit = next
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 12.0, Color(0.04, 0.04, 0.045))
	draw_circle(center, 9.0, Color(0.015, 0.015, 0.018))
	var lamp := Color(0.28, 0.12, 0.05)
	if lit:
		lamp = Color(0.22, 0.9, 0.4)
	draw_circle(center, 5.5, lamp)
	if lit:
		draw_circle(center, 8.0, Color(0.35, 1.0, 0.5, 0.28))
		draw_circle(center + Vector2(-1.6, -1.6), 1.6, Color(0.85, 1.0, 0.85, 0.7))
