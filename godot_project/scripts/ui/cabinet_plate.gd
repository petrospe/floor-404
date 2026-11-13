class_name CabinetPlate
extends Control
## Painted interior of the junction cabinet. Decals are drawn upright, never scaled below zero.

var _scratch_from: PackedVector2Array = PackedVector2Array()
var _scratch_to: PackedVector2Array = PackedVector2Array()
var _dirt: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 40491
	for _i in 16:
		var origin := Vector2(rng.randf_range(50.0, 1120.0), rng.randf_range(48.0, 690.0))
		_scratch_from.append(origin)
		_scratch_to.append(origin + Vector2(rng.randf_range(28.0, 110.0), rng.randf_range(-4.0, 4.0)))
	for _i in 7:
		_dirt.append(Vector2(rng.randf_range(40.0, 1140.0), rng.randf_range(40.0, 700.0)))


func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	draw_rect(full, Color(0.16, 0.165, 0.17))
	draw_rect(Rect2(Vector2(10, 10), size - Vector2(20, 20)), Color(0.11, 0.115, 0.12))
	draw_rect(Rect2(Vector2(22, 22), size - Vector2(44, 44)), Color(0.145, 0.15, 0.155))
	# Light from the upper left, so the top and left lips are brighter.
	draw_rect(Rect2(Vector2(22, 22), Vector2(size.x - 44.0, 3.0)), Color(0.28, 0.29, 0.3, 0.85))
	draw_rect(Rect2(Vector2(22, 22), Vector2(3.0, size.y - 44.0)), Color(0.24, 0.25, 0.26, 0.7))
	draw_rect(Rect2(Vector2(22, size.y - 25.0), Vector2(size.x - 44.0, 3.0)), Color(0.05, 0.05, 0.055, 0.9))
	draw_rect(Rect2(Vector2(size.x - 25.0, 22), Vector2(3.0, size.y - 44.0)), Color(0.05, 0.05, 0.055, 0.75))
	_draw_duct()
	_draw_rail()
	_draw_gutter()
	_draw_wear()
	_draw_warning(Vector2(78, 70))
	_screw(Vector2(40, 40))
	_screw(Vector2(size.x - 40.0, 40))
	_screw(Vector2(40, size.y - 40.0))
	_screw(Vector2(size.x - 40.0, size.y - 40.0))


func _draw_duct() -> void:
	var duct := Rect2(Vector2(48, 128), Vector2(58, 500))
	draw_rect(duct, Color(0.07, 0.072, 0.076))
	draw_rect(Rect2(duct.position, Vector2(3, duct.size.y)), Color(0.2, 0.21, 0.22))
	for i in 8:
		var y := 156.0 + float(i) * 62.0
		draw_rect(Rect2(Vector2(54, y - 8.0), Vector2(46, 16)), Color(0.05, 0.05, 0.054))


func _draw_rail() -> void:
	var rail := Rect2(Vector2(868, 124), Vector2(250, 512))
	draw_rect(rail, Color(0.28, 0.29, 0.31))
	draw_rect(Rect2(rail.position, Vector2(rail.size.x, 3)), Color(0.5, 0.51, 0.53))
	draw_rect(Rect2(Vector2(rail.position.x, rail.end.y - 3.0), Vector2(rail.size.x, 3)), Color(0.12, 0.12, 0.13))
	draw_rect(Rect2(Vector2(886, 140), Vector2(18, 480)), Color(0.2, 0.21, 0.22))
	for i in 8:
		var y := 156.0 + float(i) * 62.0
		draw_circle(Vector2(896, y), 3.2, Color(0.08, 0.08, 0.09))
		draw_circle(Vector2(1092, y), 3.2, Color(0.08, 0.08, 0.09))


func _draw_gutter() -> void:
	draw_rect(Rect2(Vector2(48, 648), Vector2(1084, 30)), Color(0.08, 0.082, 0.086))
	draw_rect(Rect2(Vector2(48, 648), Vector2(1084, 2)), Color(0.22, 0.23, 0.24, 0.8))


func _draw_wear() -> void:
	for i in _scratch_from.size():
		draw_line(_scratch_from[i], _scratch_to[i], Color(0.55, 0.56, 0.58, 0.13), 1.0, true)
	for spot in _dirt:
		draw_circle(spot, 10.0, Color(0.02, 0.02, 0.015, 0.16))
	draw_rect(Rect2(Vector2(30, 600), Vector2(90, 18)), Color(0.05, 0.04, 0.03, 0.18))
	draw_rect(Rect2(Vector2(980, 80), Vector2(70, 14)), Color(0.04, 0.035, 0.03, 0.16))


func _draw_warning(origin: Vector2) -> void:
	var top := origin + Vector2(0, -16)
	var right := origin + Vector2(15, 13)
	var left := origin + Vector2(-15, 13)
	draw_colored_polygon(PackedVector2Array([top, right, left]), Color(0.78, 0.6, 0.12, 0.92))
	draw_polyline(PackedVector2Array([
		origin + Vector2(3.5, -6.5),
		origin + Vector2(-2.2, 0.4),
		origin + Vector2(2.4, 0.4),
		origin + Vector2(-2.6, 8.5),
	]), Color(0.1, 0.08, 0.05), 2.2, true)


func _screw(at: Vector2) -> void:
	draw_circle(at, 8.0, Color(0.06, 0.06, 0.065))
	draw_circle(at, 6.2, Color(0.34, 0.35, 0.37))
	draw_circle(at, 4.6, Color(0.24, 0.25, 0.27))
	draw_line(at + Vector2(-3.2, -1.2), at + Vector2(3.2, 1.2), Color(0.08, 0.08, 0.08), 1.2, true)
