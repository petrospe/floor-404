class_name WireConnector
extends Control
## Left-hand conductor lug. The brass barrel sits on LUG in local space.

const BODY := Vector2(210, 40)
const LUG := Vector2(194, 20)

var wire_color := Color(0.7, 0.2, 0.16)
var phase := 0
var pulse := 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = BODY
	size = BODY


func set_phase(next: int) -> void:
	if phase == next:
		return
	phase = next
	queue_redraw()


func set_pulse(next: float) -> void:
	pulse = next
	if phase == 1:
		queue_redraw()


func _draw() -> void:
	var y := LUG.y
	var sheath := wire_color
	if phase == 0:
		sheath = Color(wire_color.r * 0.42, wire_color.g * 0.42, wire_color.b * 0.42)
	draw_line(Vector2(0.0, y), LUG, sheath.darkened(0.28), 12.0, true)
	draw_line(Vector2(0.0, y - 2.2), LUG + Vector2(-8.0, -2.2), sheath.lightened(0.28), 2.2, true)
	draw_circle(LUG + Vector2(-12.0, 0.0), 8.0, sheath.darkened(0.12))
	if phase == 1:
		draw_circle(LUG, 14.0 * pulse, Color(wire_color.r, wire_color.g, wire_color.b, 0.34))
	draw_circle(LUG, 7.2, Color(0.66, 0.54, 0.3))
	draw_circle(LUG, 5.4, Color(0.4, 0.32, 0.16))
	draw_line(LUG + Vector2(-3.4, -1.4), LUG + Vector2(3.4, 1.4), Color(0.14, 0.11, 0.07), 1.3, true)
	var led := Color(0.1, 0.09, 0.08)
	if phase == 1:
		led = Color(0.96, 0.58, 0.14)
	elif phase == 2:
		led = Color(0.28, 0.86, 0.42)
	var led_at := Vector2(LUG.x - 28.0, y - 11.0)
	draw_circle(led_at, 4.2, Color(0.02, 0.02, 0.02))
	draw_circle(led_at, 2.6, led)
