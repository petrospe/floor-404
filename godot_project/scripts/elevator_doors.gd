class_name ElevatorDoors
extends StaticBody3D
## Stainless sliding doors. The root sits on a 4 m wall module, local +Z into the car.

var _open := false
var _left: MeshInstance3D
var _right: MeshInstance3D
var _blocker: CollisionShape3D
var _left_closed := Vector3.ZERO
var _right_closed := Vector3.ZERO


func build(floor_number: String) -> void:
	var steel := _material(Color(0.74, 0.75, 0.77), 0.22, 0.82)
	var trim := _material(Color(0.55, 0.56, 0.58), 0.4, 0.65)
	var wall := _material(Color(0.62, 0.63, 0.65), 0.7, 0.15)
	var dark := _material(Color(0.12, 0.13, 0.14), 0.45, 0.3)
	var lamp := _material(Color(0.9, 0.92, 0.9), 0.4, 0.0, Color(0.9, 0.95, 0.92), 4.0)
	var display := _material(Color(0.05, 0.2, 0.12), 0.4, 0.0, Color(0.2, 0.85, 0.4), 2.2)

	_mesh(Vector3(0.58, 1.5, 0.0), Vector3(1.16, 3.0, 0.12), wall)
	_mesh(Vector3(3.42, 1.5, 0.0), Vector3(1.16, 3.0, 0.12), wall)
	_mesh(Vector3(2.0, 2.72, 0.0), Vector3(1.7, 0.56, 0.14), trim)
	_mesh(Vector3(2.0, 2.58, -0.06), Vector3(1.15, 0.06, 0.04), lamp)

	_left = _mesh(Vector3(1.6, 1.18, 0.0), Vector3(0.86, 2.32, 0.05), steel)
	_right = _mesh(Vector3(2.4, 1.18, 0.02), Vector3(0.86, 2.32, 0.05), steel)
	_left_closed = _left.position
	_right_closed = _right.position
	_shape(Vector3(0.58, 1.5, 0.0), Vector3(1.16, 3.0, 0.16))
	_shape(Vector3(3.42, 1.5, 0.0), Vector3(1.16, 3.0, 0.16))
	_shape(Vector3(2.0, 2.72, 0.0), Vector3(1.7, 0.56, 0.16))

	_blocker = CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(1.62, 2.32, 0.1)
	_blocker.shape = block
	_blocker.position = Vector3(2.0, 1.18, 0.0)
	add_child(_blocker)

	var button := CollisionShape3D.new()
	var plate := BoxShape3D.new()
	plate.size = Vector3(0.22, 0.46, 0.08)
	button.shape = plate
	button.position = Vector3(3.28, 1.28, -0.08)
	add_child(button)
	_mesh(Vector3(3.28, 1.28, -0.09), Vector3(0.18, 0.42, 0.03), trim)
	_mesh(Vector3(3.28, 1.42, -0.11), Vector3(0.1, 0.05, 0.012), display)
	for row in range(3):
		for col in range(2):
			_mesh(
				Vector3(3.24 + float(col) * 0.07, 1.16 + float(row) * 0.08, -0.11),
				Vector3(0.035, 0.035, 0.012),
				dark
			)

	var number := Label3D.new()
	number.text = floor_number
	number.position = Vector3(2.0, 2.62, -0.09)
	number.pixel_size = 0.004
	number.font_size = 48
	number.modulate = Color(0.55, 0.95, 0.7)
	number.outline_size = 0
	number.rotation.y = PI
	add_child(number)


func force_open() -> void:
	_set_open(true)


func interact(_interactor: Node = null) -> void:
	_set_open(not _open)


func _set_open(open: bool) -> void:
	_open = open
	_blocker.disabled = open
	var distance := 0.74 if open else 0.0
	var left_target := _left_closed + Vector3(-distance, 0.0, 0.0)
	var right_target := _right_closed + Vector3(distance, 0.0, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_left, "position", left_target, 0.7)
	tween.tween_property(_right, "position", right_target, 0.7)


func _shape(origin: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = origin
	add_child(collision)


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
