class_name ElevatorDoors
extends StaticBody3D
## Stainless sliding doors. The root sits on a 4 m wall module, local +Z into the car.

var _open := false
var _left: MeshInstance3D
var _right: MeshInstance3D
var _left_hit: CollisionShape3D
var _right_hit: CollisionShape3D
var _left_closed := Vector3.ZERO
var _right_closed := Vector3.ZERO
var _indicator: MeshInstance3D
var _indicator_light: OmniLight3D
var _close_timer: Timer
var _motion: Tween
var _here := false
var _car_min := Vector2.ZERO
var _car_max := Vector2.ZERO
var other_doors: ElevatorDoors
var _floor_code := "00"
var _hall: Array = []
var _cabin: Array = []
var _calling := false
var _seg_on: StandardMaterial3D
var _seg_off: StandardMaterial3D

const IDLE_CLOSE := 5.0
const _DIGIT_MASKS := {
	"0": [1, 1, 1, 1, 1, 1, 0],
	"1": [0, 1, 1, 0, 0, 0, 0],
	"2": [1, 1, 0, 1, 1, 0, 1],
	"3": [1, 1, 1, 1, 0, 0, 1],
	"4": [0, 1, 1, 0, 0, 1, 1],
	"5": [1, 0, 1, 1, 0, 1, 1],
	"6": [1, 0, 1, 1, 1, 1, 1],
	"7": [1, 1, 1, 0, 0, 0, 0],
	"8": [1, 1, 1, 1, 1, 1, 1],
	"9": [1, 1, 1, 1, 0, 1, 1],
}

# Leaves run from the floor up into the header, and the header runs up to the raised ceiling.
const LEAF_CENTER_Y := 1.26
const LEAF_HEIGHT := 2.48
const FRAME_TOP := 3.4


func build(floor_number: String, outside_z: float) -> void:
	var steel := _material(Color(0.74, 0.75, 0.77), 0.22, 0.82)
	var trim := _material(Color(0.55, 0.56, 0.58), 0.4, 0.65)
	var wall := _material(Color(0.62, 0.63, 0.65), 0.7, 0.15)
	var lamp := _material(Color(0.9, 0.92, 0.9), 0.4, 0.0, Color(0.9, 0.95, 0.92), 4.0)
	var frame_center := FRAME_TOP * 0.5
	var header_bottom := 2.4
	var header_height := FRAME_TOP - header_bottom
	var header_center := header_bottom + header_height * 0.5

	_mesh(Vector3(0.58, frame_center, 0.0), Vector3(1.16, FRAME_TOP, 0.12), wall)
	_mesh(Vector3(3.42, frame_center, 0.0), Vector3(1.16, FRAME_TOP, 0.12), wall)
	_mesh(Vector3(2.0, header_center, 0.0), Vector3(1.7, header_height, 0.14), trim)
	_mesh(Vector3(2.0, 2.58, -0.06), Vector3(1.15, 0.06, 0.04), lamp)

	_left = _mesh(Vector3(1.6, LEAF_CENTER_Y, 0.0), Vector3(0.86, LEAF_HEIGHT, 0.05), steel)
	_right = _mesh(Vector3(2.4, LEAF_CENTER_Y, 0.02), Vector3(0.86, LEAF_HEIGHT, 0.05), steel)
	_left_closed = _left.position
	_right_closed = _right.position
	_left_hit = _shape(_left.position, Vector3(0.86, LEAF_HEIGHT, 0.12))
	_right_hit = _shape(_right.position, Vector3(0.86, LEAF_HEIGHT, 0.12))
	_shape(Vector3(0.58, frame_center, 0.0), Vector3(1.16, FRAME_TOP, 0.16))
	_shape(Vector3(3.42, frame_center, 0.0), Vector3(1.16, FRAME_TOP, 0.16))
	_shape(Vector3(2.0, header_center, 0.0), Vector3(1.7, header_height, 0.16))

	# One call button on the corridor face of the right jamb. The lamp reports the car.
	var proud := 0.02 if outside_z > 0.0 else -0.02
	_mesh(Vector3(3.18, 1.18, outside_z), Vector3(0.1, 0.16, 0.018), trim)
	_indicator = _mesh(Vector3(3.18, 1.18, outside_z + proud), Vector3(0.045, 0.045, 0.012), _material(Color(0.9, 0.08, 0.06), 0.35, 0.1, Color(0.9, 0.08, 0.06), 2.4))
	_indicator_light = OmniLight3D.new()
	_indicator_light.position = Vector3(3.18, 1.18, outside_z + proud)
	_indicator_light.omni_range = 0.45
	_indicator_light.shadow_enabled = false
	_indicator_light.light_energy = 0.35
	add_child(_indicator_light)
	set_car_here(false)
	_close_timer = Timer.new()
	_close_timer.one_shot = true
	_close_timer.wait_time = IDLE_CLOSE
	_close_timer.timeout.connect(_on_idle)
	add_child(_close_timer)
	var press := CollisionShape3D.new()
	var press_box := BoxShape3D.new()
	press_box.size = Vector3(0.12, 0.2, 0.06)
	press.shape = press_box
	press.position = Vector3(3.18, 1.18, outside_z)
	add_child(press)

	# Two small cyan readouts, above the header lamp so they do not sit on it.
	# The lamp bar is y 2.55–2.61. The plates are centered at y 2.90.
	_floor_code = floor_number
	_seg_on = _material(Color(0.2, 0.98, 1.0), 0.28, 0.04, Color(0.15, 0.95, 1.0), 2.4)
	_seg_off = _material(Color(0.02, 0.035, 0.04), 0.9, 0.0)
	var corridor := 1.0 if outside_z > 0.0 else -1.0
	_cabin = _readout(Vector3(2.0, 2.9, -corridor * 0.09), floor_number, -corridor)
	_hall = _readout(Vector3(2.0, 2.9, corridor * 0.09), floor_number, corridor)


func force_open() -> void:
	_set_open(true)


func set_car_bounds(center: Vector3) -> void:
	_car_min = Vector2(center.x - 2.1, center.z - 2.1)
	_car_max = Vector2(center.x + 2.1, center.z + 2.1)


func set_car_here(here: bool) -> void:
	_here = here
	_paint_indicator()
	_show_hall()
	if other_doors != null:
		other_doors._show_hall()


func interact(_interactor: Node = null) -> void:
	call_here()


func call_here() -> void:
	if _calling:
		return
	if _here:
		_set_open(true)
		return
	_calling = true
	await get_tree().create_timer(1.8).timeout
	if not is_inside_tree():
		return
	if other_doors != null:
		if other_doors._open:
			other_doors._set_open(false)
		other_doors._here = false
		other_doors._paint_indicator()
	_here = true
	_paint_indicator()
	_show_hall()
	if other_doors != null:
		other_doors._show_hall()
	_set_open(true)
	_calling = false


func _paint_indicator() -> void:
	var color := Color(0.15, 0.9, 0.28) if _here else Color(0.9, 0.08, 0.06)
	var material := _indicator.material_override as StandardMaterial3D
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.4
	_indicator_light.light_color = color


func _set_open(open: bool) -> void:
	if _open == open:
		if open and (_motion == null or not _motion.is_valid()):
			_close_timer.start()
		return
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_open = open
	if open:
		_close_timer.start()
	else:
		_close_timer.stop()
	var distance := 0.74 if open else 0.0
	var left_target := _left_closed + Vector3(-distance, 0.0, 0.0)
	var right_target := _right_closed + Vector3(distance, 0.0, 0.0)
	_motion = create_tween()
	_motion.set_parallel(true)
	_motion.set_trans(Tween.TRANS_QUAD)
	_motion.set_ease(Tween.EASE_IN_OUT)
	_motion.tween_property(_left, "position", left_target, 0.7)
	_motion.tween_property(_right, "position", right_target, 0.7)
	_motion.tween_property(_left_hit, "position", left_target, 0.7)
	_motion.tween_property(_right_hit, "position", right_target, 0.7)


func _on_idle() -> void:
	if not _open:
		return
	if _occupied():
		_close_timer.start()
		return
	_set_open(false)
	if _here:
		_park_random()


func _occupied() -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return false
	var at := player.global_position
	return at.x >= _car_min.x and at.x <= _car_max.x and at.z >= _car_min.y and at.z <= _car_max.y


func _park_random() -> void:
	var stay := randi() % 2 == 0
	set_car_here(stay)
	if other_doors != null:
		other_doors.set_car_here(not stay)


func _show_hall() -> void:
	if _hall.is_empty():
		return
	var where := _floor_code
	if not _here and other_doors != null and other_doors._here:
		where = other_doors._floor_code
	_paint_readout(_hall, where)
	if not _cabin.is_empty():
		_paint_readout(_cabin, _floor_code if _here else where)


func _readout(at: Vector3, text: String, face: float) -> Array:
	var black := _material(Color(0.008, 0.01, 0.012), 0.75, 0.02)
	_mesh(at, Vector3(0.15, 0.105, 0.006), black)
	var shown := text if text.length() >= 2 else "0" + text
	var mirror := face < 0.0
	var digits: Array = []
	for i in 2:
		var slot := -0.032 if i == 0 else 0.032
		if mirror:
			slot = -slot
		digits.append(_digit(Vector3(at.x + slot, at.y, at.z + face * 0.007), mirror))
	_paint_readout(digits, shown)
	return digits


func _digit(center: Vector3, mirror: bool) -> Array:
	var w := 0.042
	var h := 0.072
	var bar := 0.008
	var depth := 0.004
	var bars := [
		[Vector3(0.0, h * 0.40, 0.0), Vector3(w * 0.56, bar, depth)],
		[Vector3(w * 0.30, h * 0.20, 0.0), Vector3(bar, h * 0.32, depth)],
		[Vector3(w * 0.30, -h * 0.20, 0.0), Vector3(bar, h * 0.32, depth)],
		[Vector3(0.0, -h * 0.40, 0.0), Vector3(w * 0.56, bar, depth)],
		[Vector3(-w * 0.30, -h * 0.20, 0.0), Vector3(bar, h * 0.32, depth)],
		[Vector3(-w * 0.30, h * 0.20, 0.0), Vector3(bar, h * 0.32, depth)],
		[Vector3(0.0, 0.0, 0.0), Vector3(w * 0.56, bar, depth)],
	]
	var xsign := -1.0 if mirror else 1.0
	var segments: Array = []
	for bar_def in bars:
		var offset: Vector3 = bar_def[0]
		offset.x *= xsign
		var size: Vector3 = bar_def[1]
		segments.append(_mesh(center + offset, size, _seg_off))
	return segments


func _paint_readout(digits: Array, text: String) -> void:
	var shown := text if text.length() >= 2 else "0" + text
	for i in mini(2, digits.size()):
		var glyph := shown[i]
		var mask: Array = _DIGIT_MASKS.get(glyph, _DIGIT_MASKS["0"])
		var segments: Array = digits[i]
		for s in mini(7, segments.size()):
			var mesh := segments[s] as MeshInstance3D
			mesh.material_override = _seg_on if int(mask[s]) == 1 else _seg_off


func _shape(origin: Vector3, size: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = origin
	add_child(collision)
	return collision


func _mesh(origin: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = material
	mesh_node.position = origin
	add_child(mesh_node)
	return mesh_node


func _material(
	color: Color,
	roughness: float,
	metallic: float,
	emission: Color = Color(0, 0, 0),
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material
