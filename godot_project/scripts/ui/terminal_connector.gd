class_name TerminalConnector
extends Control
## Numbered terminal block. The screw sits on SCREW in local space.
## Numbers are the puzzle. The blocks are not color-matched to the wires.

const BODY := Vector2(156, 46)
const SCREW := Vector2(24, 23)

var number := 1
var occupied := false
var reject := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = BODY
	size = BODY


func set_occupied(next: bool) -> void:
	if occupied == next:
		return
	occupied = next
	queue_redraw()


func set_reject(amount: float) -> void:
	reject = clampf(amount, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var body := Color(0.09, 0.09, 0.1)
	if reject > 0.0:
		body = body.lerp(Color(0.42, 0.13, 0.09), reject)
	draw_rect(Rect2(Vector2.ZERO, size), body)
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(size.x, 2.0)), Color(0.22, 0.22, 0.23))
	draw_rect(Rect2(Vector2(0.0, size.y - 2.0), Vector2(size.x, 2.0)), Color(0.03, 0.03, 0.03))
	draw_circle(SCREW, 10.0, Color(0.22, 0.2, 0.16))
	draw_circle(SCREW, 8.0, Color(0.62, 0.5, 0.28))
	draw_circle(SCREW, 6.2, Color(0.46, 0.36, 0.18))
	draw_line(SCREW + Vector2(-4.5, -1.6), SCREW + Vector2(4.5, 1.6), Color(0.12, 0.1, 0.07), 1.4, true)
	if occupied:
		draw_arc(SCREW, 11.5, 0.0, TAU, 24, Color(0.32, 0.72, 0.42, 0.85), 1.6, true)
	var font := ThemeDB.fallback_font
	var font_size := 22
	var text := str(number)
	var baseline := size.y * 0.5 + float(font_size) * 0.32
	draw_string(
		font,
		Vector2(52.0, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(0.8, 0.78, 0.72)
	)
