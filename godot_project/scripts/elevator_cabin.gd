extends RefCounted
## One passenger cabin, matching the stainless-and-cream reference.
## door_dir points from the cabin center toward the open doors.
## The button plate is the same 15-floor column in every car.

const HALF := 1.72


static func install(parent: Node3D, center: Vector3, door_dir: Vector3, lit_floor: int, elevator_id: String) -> ElevatorPanel:
	var forward := door_dir.normalized()
	var side := Vector3.UP.cross(forward).normalized()
	_dress(parent, center, forward, side)
	var built: Array = _panel(lit_floor)
	var panel: ElevatorPanel = built[0]
	var lit: StandardMaterial3D = built[1]
	# On the side wall, beside the doors, facing into the cabin.
	var inward := -side
	panel.position = center + side * 1.66 + Vector3(0.0, 1.22, 0.0) + forward * 0.95
	panel.rotation.y = atan2(-inward.x, -inward.z)
	parent.add_child(panel)
	if elevator_id != "":
		panel.configure(elevator_id, lit)
	return panel


static func _dress(parent: Node3D, center: Vector3, forward: Vector3, side: Vector3) -> void:
	var steel := _mat(Color(0.58, 0.59, 0.61), 0.32, 0.78)
	var cream := _mat(Color(0.80, 0.76, 0.68), 0.78, 0.0)
	var dark := _mat(Color(0.10, 0.10, 0.11), 0.42, 0.55)
	var rail := _mat(Color(0.72, 0.73, 0.75), 0.22, 0.85)
	var light := _mat(Color(0.95, 0.93, 0.86), 0.3, 0.0, Color(1.0, 0.96, 0.88), 2.4)
	var carpet_a := _mat(Color(0.46, 0.44, 0.41), 0.92, 0.0)
	var carpet_b := _mat(Color(0.40, 0.39, 0.37), 0.92, 0.0)
	# Carpet squares. The two tones are the woven tiles in the reference.
	for ix in 8:
		for iz in 8:
			var tone: Material = carpet_a if (ix + iz) % 2 == 0 else carpet_b
			var offset := side * (-1.4 + float(ix) * 0.4) + forward * (-1.4 + float(iz) * 0.4)
			_box(parent, center + offset + Vector3(0.0, 0.025, 0.0), side, forward, Vector3(0.38, 0.03, 0.38), tone)
	# Side walls: brushed steel with one cream insert and a waist rail.
	var sides: Array[float] = [-1.0, 1.0]
	for sign in sides:
		var wall_at: Vector3 = center + side * sign * HALF + Vector3(0.0, 1.18, 0.0)
		_box(parent, wall_at, side, forward, Vector3(0.05, 2.32, 3.2), steel)
		_box(parent, wall_at - side * sign * 0.03 + Vector3(0.0, 0.12, 0.0), side, forward, Vector3(0.02, 1.55, 1.15), cream)
		_box(parent, wall_at - side * sign * 0.045 + Vector3(0.0, -0.22, 0.0), side, forward, Vector3(0.025, 0.035, 2.5), rail)
	# Back wall, opposite the doors: cream field, steel border, one rail.
	var back_at := center - forward * HALF + Vector3(0.0, 1.18, 0.0)
	_box(parent, back_at, side, forward, Vector3(3.2, 2.32, 0.05), steel)
	_box(parent, back_at + forward * 0.035 + Vector3(0.0, 0.48, 0.0), side, forward, Vector3(2.35, 1.05, 0.02), cream)
	_box(parent, back_at + forward * 0.035 + Vector3(0.0, -0.55, 0.0), side, forward, Vector3(2.35, 0.72, 0.02), cream)
	_box(parent, back_at + forward * 0.05 + Vector3(0.0, -0.22, 0.0), side, forward, Vector3(2.55, 0.04, 0.03), rail)
	# Dark ceiling and three recessed spots, in a row across the cabin.
	_box(parent, center + Vector3(0.0, 2.38, 0.0), side, forward, Vector3(3.15, 0.05, 3.15), dark)
	var spots: Array[float] = [-0.72, 0.0, 0.72]
	for spot in spots:
		var at: Vector3 = center + side * spot + Vector3(0.0, 2.34, 0.0)
		_box(parent, at, side, forward, Vector3(0.16, 0.02, 0.16), light)
		var lamp := OmniLight3D.new()
		lamp.position = at - Vector3(0.0, 0.08, 0.0)
		lamp.light_color = Color(1.0, 0.95, 0.86)
		lamp.light_energy = 0.55
		lamp.omni_range = 3.2
		lamp.shadow_enabled = false
		parent.add_child(lamp)


static func _panel(lit_floor: int) -> Array:
	var panel := ElevatorPanel.new()
	var steel := _mat(Color(0.62, 0.63, 0.66), 0.28, 0.8)
	var button := _mat(Color(0.14, 0.14, 0.15), 0.4, 0.35)
	var lit := _mat(Color(0.35, 0.06, 0.05), 0.35, 0.1, Color(0.85, 0.08, 0.05), 1.4)
	_box_local(panel, Vector3(0.0, 0.0, 0.0), Vector3(0.28, 0.64, 0.035), steel)
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = Vector3(0.32, 0.7, 0.06)
	shape.shape = collision
	panel.add_child(shape)
	for index in range(15):
		var column := index % 3
		var row := 4 - int(index / 3.0)
		var floor_number := 15 - index
		var local := Vector3(-0.07 + float(column) * 0.07, -0.2 + float(row) * 0.09, -0.028)
		var face: Material = lit if floor_number == lit_floor else button
		_box_local(panel, local, Vector3(0.046, 0.046, 0.012), face)
		var label := Label3D.new()
		label.text = str(floor_number)
		label.position = local + Vector3(0.0, 0.0, -0.01)
		# The plate's -Z points into the cabin, and Label3D's readable face is +Z.
		label.rotation.y = PI
		label.pixel_size = 0.0011
		label.font_size = 28
		label.modulate = Color(0.93, 0.93, 0.9)
		label.outline_size = 0
		panel.add_child(label)
	return [panel, lit]


static func _box(parent: Node3D, origin: Vector3, side: Vector3, forward: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = origin
	mesh.basis = Basis(side, Vector3.UP, forward)
	mesh.material_override = material
	parent.add_child(mesh)


static func _box_local(parent: Node3D, origin: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = origin
	mesh.material_override = material
	parent.add_child(mesh)


static func _mat(color: Color, rough: float, metal: float, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.metallic = metal
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
