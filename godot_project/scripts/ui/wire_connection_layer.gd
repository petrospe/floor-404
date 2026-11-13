class_name WireConnectionLayer
extends Control
## Draws seated and in-progress cables in this control's local space.
## Connection points are the same local coordinates used to place the lugs.

signal pressed(at: Vector2)

var cables: Array[Dictionary] = []
var show_drag := false
var drag_from := Vector2.ZERO
var drag_to := Vector2.ZERO
var drag_color := Color.WHITE


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_cables(next: Array[Dictionary]) -> void:
	cables = next
	queue_redraw()


func set_drag(active: bool, from: Vector2, to: Vector2, color: Color) -> void:
	show_drag = active
	drag_from = from
	drag_to = to
	drag_color = color
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit(button.position)
			accept_event()


func _draw() -> void:
	for cable in cables:
		_cable(cable["from"], cable["to"], cable["color"], 7.0)
	if show_drag:
		_cable(drag_from, drag_to, drag_color, 6.0)
		draw_circle(drag_to, 5.0, Color(0.72, 0.58, 0.32, 0.95))


func _cable(start: Vector2, finish: Vector2, color: Color, width: float) -> void:
	var points := _curve(start, finish)
	var shadow := PackedVector2Array()
	shadow.resize(points.size())
	for i in points.size():
		shadow[i] = points[i] + Vector2(2.0, 5.0)
	draw_polyline(shadow, Color(0.0, 0.0, 0.0, 0.45), width + 2.0, true)
	draw_polyline(points, color.darkened(0.35), width + 2.4, true)
	draw_polyline(points, color, width, true)
	var highlight := PackedVector2Array()
	highlight.resize(points.size())
	for i in points.size():
		highlight[i] = points[i] + Vector2(0.0, -1.4)
	draw_polyline(highlight, color.lightened(0.42), 1.6, true)


func _curve(start: Vector2, finish: Vector2) -> PackedVector2Array:
	var span := absf(finish.x - start.x)
	var sag := clampf(span * 0.16, 16.0, 52.0)
	var control_a := Vector2(lerpf(start.x, finish.x, 0.33), start.y + sag)
	var control_b := Vector2(lerpf(start.x, finish.x, 0.67), finish.y + sag)
	var points := PackedVector2Array()
	var steps := 32
	points.resize(steps + 1)
	for i in steps + 1:
		var t := float(i) / float(steps)
		points[i] = _cubic(start, control_a, control_b, finish, t)
	return points


func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return (u * u * u) * a + (3.0 * u * u * t) * b + (3.0 * u * t * t) * c + (t * t * t) * d
