extends Node3D
## First walkable slice of Floor 404, laid out after the Level 4 office references.
## Rooms, in walk order: carpet corridor, door hall with night windows, closets,
## break room, cubicle bay, column room, service corridor, security room, stair landing.
## Modules are 4 m on a side. Walls are 3 m tall. The player starts in the corridor.

const CELL := 4.0
const EDGES: Array[String] = ["n", "s", "e", "w"]

const CARPET := preload("res://scenes/modular/carpet_4x4.tscn")
const CONCRETE := preload("res://scenes/modular/concrete_4x4.tscn")
const CEILING := preload("res://scenes/modular/ceiling_4x4.tscn")
const WALL := preload("res://scenes/modular/wall_4x3.tscn")
const WINDOW := preload("res://scenes/modular/window_wall.tscn")
const DOOR := preload("res://scenes/modular/door_frame.tscn")
const LIGHT := preload("res://scenes/modular/light_panel.tscn")
const CUBICLE := preload("res://models/office/cubicle.glb")
const COLUMN := preload("res://models/office/column.glb")
const TABLE := preload("res://models/office/table.glb")
const CHAIR := preload("res://models/office/chair.glb")

var _cells: Array[Vector2i] = []
var _cell_set: Dictionary = {}
var _concrete: Dictionary = {}
var _overrides: Dictionary = {}
var _door_flags: Dictionary = {}
var _geometry: Node3D
var _prop_index := 0

var _cubicle_mat: StandardMaterial3D
var _desk_mat: StandardMaterial3D
var _metal_mat: StandardMaterial3D
var _red_mat: StandardMaterial3D
var _monitor_mat: StandardMaterial3D
var _dead_lamp_mat: StandardMaterial3D
var _cooler_mat: StandardMaterial3D
var _bottle_mat: StandardMaterial3D


func _ready() -> void:
	_geometry = Node3D.new()
	_geometry.name = "Geometry"
	add_child(_geometry)
	_prepare_materials()
	_define_rooms()
	_mark_openings()
	_build_shell()
	_build_lights()
	_build_props()


func _prepare_materials() -> void:
	_cubicle_mat = _mat(Color(0.22, 0.22, 0.23), 0.8)
	_desk_mat = _mat(Color(0.28, 0.2, 0.14), 0.62)
	_metal_mat = _mat(Color(0.55, 0.56, 0.58), 0.35, 0.7)
	_red_mat = _mat(Color(0.45, 0.08, 0.07), 0.55)
	_monitor_mat = _mat(Color(0.05, 0.16, 0.18), 0.25, 0.0, Color(0.35, 0.85, 0.8), 3.5)
	_dead_lamp_mat = _mat(Color(0.16, 0.16, 0.15), 0.72)
	_cooler_mat = _mat(Color(0.75, 0.78, 0.8), 0.4, 0.15)
	_bottle_mat = _mat(Color(0.25, 0.45, 0.62), 0.25, 0.0, Color(0.2, 0.45, 0.7), 0.4)


func _define_rooms() -> void:
	_fill(0, 0, 0, 5) # Corridor.
	_fill(1, 1, 2, 2) # Open closet off the corridor.
	_fill(1, 1, 4, 4) # Second closet.
	_fill(-1, 1, 6, 9) # Door hall.
	_fill(2, 2, 9, 9) # Vestibule into the cubicles.
	_fill(-1, -1, 5, 5) # Closet under the window wall.
	_fill(1, 1, 5, 5) # Closet beside the hall.
	_fill(2, 3, 6, 8) # Break room.
	_fill(-1, 2, 10, 13) # Cubicle bay.
	_fill(-1, 1, 14, 16) # Column room.
	_fill(0, 0, 17, 18) # Stair room.
	_fill(-2, -2, 14, 17) # Service corridor.
	_fill(-4, -3, 15, 17) # Security room.
	for cell in _cells:
		if cell.x <= -2:
			_concrete[cell] = true


func _mark_openings() -> void:
	_mark_door(Vector2i(0, 5), "n")
	_mark(Vector2i(0, 5), "e", "wall")
	_mark(Vector2i(-1, 5), "e", "wall")
	_mark_door(Vector2i(0, 2), "e", true)
	_mark_door(Vector2i(0, 4), "e")
	_mark_door(Vector2i(-1, 5), "n")
	_mark_door(Vector2i(1, 5), "n")
	_mark_door(Vector2i(1, 7), "e")
	_mark_door(Vector2i(-2, 15), "e")
	_mark_door(Vector2i(-4, 17), "n", false, true, Color(0.42, 0.07, 0.06))

	_mark(Vector2i(1, 6), "e", "wall")
	_mark(Vector2i(1, 8), "e", "wall")
	_mark(Vector2i(1, 9), "e", "wall")
	_mark(Vector2i(2, 8), "n", "wall")
	_mark(Vector2i(-2, 14), "e", "wall")
	_mark(Vector2i(-2, 16), "e", "wall")
	_mark(Vector2i(-3, 15), "e", "wall")
	_mark(Vector2i(-3, 17), "e", "wall")

	for z in range(6, 9):
		_mark(Vector2i(-1, z), "w", "window")
	_mark(Vector2i(-1, 11), "w", "window")
	_mark(Vector2i(-1, 12), "w", "window")


func _build_shell() -> void:
	for cell in _cells:
		var origin := Vector3(cell.x * CELL, 0.0, cell.y * CELL)
		var floor_scene: PackedScene = CONCRETE if _concrete.has(cell) else CARPET
		_add(floor_scene, origin)
		_add(CEILING, origin)

	var placed: Dictionary = {}
	for cell in _cells:
		for edge in EDGES:
			var key := _edge_key(cell, edge)
			if placed.has(key):
				continue
			placed[key] = true
			var canon_cell: Vector2i = _canonical_cell(cell, edge)
			var canon_edge: String = _canonical_edge(cell, edge)
			var kind := str(_overrides.get(key, ""))
			if kind.is_empty():
				var neighbor := cell + _delta(edge)
				kind = "none" if _cell_set.has(neighbor) else "wall"
			match kind:
				"wall":
					_place_module(WALL, canon_cell, canon_edge)
				"window":
					_place_module(WINDOW, canon_cell, canon_edge)
				"door":
					_place_door(canon_cell, canon_edge, key)
				_:
					pass


func _build_lights() -> void:
	for cell in _cells:
		var mode := _light_mode(cell)
		if mode == 0:
			continue
		var panel := LIGHT.instantiate() as Node3D
		panel.position = Vector3(cell.x * CELL + 2.0, 2.9, cell.y * CELL + 2.0)
		_geometry.add_child(panel)
		var glow := panel.get_node(^"Glow") as OmniLight3D
		if mode == 2:
			glow.visible = false
			_dim_emissive(panel)
			continue
		if mode == 3:
			glow.shadow_enabled = true
		if _region_of(cell) == &"service" or _region_of(cell) == &"security":
			glow.light_color = Color(0.72, 0.82, 0.9)
			glow.light_energy = 1.5

	_spot(Vector3(-2.2, 2.65, 30.0), Vector3(22.0, 90.0, 0.0), 8.0, Color(0.85, 0.95, 0.8), true)
	_spot(Vector3(6.4, 2.8, 59.2), Vector3(48.0, 20.0, 0.0), 10.0, Color(1.0, 0.94, 0.82), true)
	_spot(Vector3(-2.6, 2.8, 63.2), Vector3(50.0, -30.0, 0.0), 9.0, Color(1.0, 0.94, 0.82), true)

	var probe := ReflectionProbe.new()
	probe.name = "SecurityProbe"
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.55
	probe.interior = true
	probe.box_projection = true
	probe.size = Vector3(10, 3.2, 10)
	probe.position = Vector3(-12.0, 1.5, 66.0)
	_geometry.add_child(probe)


func _build_props() -> void:
	_ladder(Vector3(6.2, 0.0, 10.2))
	_break_room()
	_cubicles()
	_columns()
	_security_camera(Vector3(7.55, 2.45, 62.0))
	_security_room()
	_stair()


func _break_room() -> void:
	_table(Vector3(10.2, 0.0, 27.5))
	_table(Vector3(13.4, 0.0, 31.5))
	_chair(Vector3(10.2, 0.0, 28.6))
	_chair(Vector3(13.4, 0.0, 30.4))
	_solid("Vending", Vector3(15.35, 0.95, 30.0), Vector3(0.85, 1.9, 0.75), _metal_mat)
	_solid("VendingGlass", Vector3(14.9, 1.15, 30.0), Vector3(0.04, 1.1, 0.55), _monitor_mat)
	_solid("Cooler", Vector3(11.6, 0.55, 34.4), Vector3(0.38, 1.1, 0.38), _cooler_mat)
	_solid("Bottle", Vector3(11.6, 1.25, 34.4), Vector3(0.28, 0.36, 0.28), _bottle_mat)
	_solid("Books", Vector3(9.2, 0.08, 26.4), Vector3(0.28, 0.08, 0.2), _desk_mat)


func _cubicles() -> void:
	for row in range(3):
		for col in range(3):
			_cubicle(Vector3(-1.2 + float(col) * 3.3, 0.0, 43.5 + float(row) * 3.5))


func _columns() -> void:
	for point in [Vector3(-1.0, 0.0, 60.5), Vector3(5.0, 0.0, 60.5), Vector3(-1.0, 0.0, 65.0), Vector3(5.0, 0.0, 65.0)]:
		_prop(COLUMN, point)


func _security_room() -> void:
	_solid("Desk", Vector3(-14.2, 0.78, 64.5), Vector3(3.4, 0.08, 0.8), _desk_mat)
	_solid("DeskLeg", Vector3(-14.2, 0.38, 64.5), Vector3(3.2, 0.72, 0.08), _metal_mat)
	_chair(Vector3(-15.0, 0.0, 65.8))
	_chair(Vector3(-13.2, 0.0, 65.8))
	for i in range(4):
		var x := -15.3 + float(i) * 0.75
		_solid("Monitor", Vector3(x, 1.25, 64.15), Vector3(0.62, 0.36, 0.05), _monitor_mat)
	var screen_light := OmniLight3D.new()
	screen_light.name = "MonitorGlow"
	screen_light.position = Vector3(-14.2, 1.3, 64.8)
	screen_light.light_color = Color(0.45, 0.8, 0.85)
	screen_light.light_energy = 1.2
	screen_light.omni_range = 4.5
	_geometry.add_child(screen_light)
	_exit_sign(Vector3(-14.0, 2.45, 71.7))


func _stair() -> void:
	var rise := 0.1
	var depth := 0.32
	for i in range(8):
		var top := rise * float(i + 1)
		_solid(
			"Step",
			Vector3(2.0, top - rise * 0.5, 69.2 + float(i) * depth),
			Vector3(2.1, rise, depth),
			_mat(Color(0.35, 0.35, 0.36), 0.7)
		)
	_solid("Landing", Vector3(2.0, 0.7, 73.5), Vector3(3.4, 0.2, 4.0), _mat(Color(0.32, 0.32, 0.33), 0.65))
	_solid("RedDoor", Vector3(2.0, 1.8, 75.55), Vector3(1.15, 2.0, 0.08), _red_mat)
	_solid("RedHandle", Vector3(2.42, 1.74, 75.48), Vector3(0.08, 0.08, 0.06), _metal_mat)


func _light_mode(cell: Vector2i) -> int:
	# 0 none, 1 lit, 2 dead fixture, 3 lit with shadow.
	match _region_of(cell):
		&"corridor":
			return 3 if cell.y == 0 or cell.y == 4 else 1
		&"hall":
			return 1 if (cell.x + cell.y) % 2 == 0 else 2
		&"break", &"closet":
			return 1
		&"cubicle":
			return 1 if cell.x % 2 == 0 and cell.y % 2 == 0 else 2
		&"pillar":
			return 1 if cell == Vector2i(0, 15) else 0
		&"stair":
			return 1 if cell.y == 17 else 0
		&"service":
			return 1
		&"security":
			return 1 if cell == Vector2i(-3, 16) else 0
		_:
			return 0


func _region_of(cell: Vector2i) -> StringName:
	if cell.x <= -3:
		return &"security"
	if cell.x == -2:
		return &"service"
	if cell.y >= 17:
		return &"stair"
	if cell.y >= 14:
		return &"pillar"
	if cell.y >= 10:
		return &"cubicle"
	if cell.y >= 6 and cell.x >= 2 and cell.y <= 8:
		return &"break"
	if cell.y >= 6:
		return &"hall"
	if cell.x == 0:
		return &"corridor"
	return &"closet"


func _fill(x0: int, x1: int, z0: int, z1: int) -> void:
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var cell := Vector2i(x, z)
			if _cell_set.has(cell):
				continue
			_cells.append(cell)
			_cell_set[cell] = true


func _mark(cell: Vector2i, edge: String, kind: String) -> void:
	_overrides[_edge_key(cell, edge)] = kind


func _mark_door(
	cell: Vector2i,
	edge: String,
	starts_open: bool = false,
	locked: bool = false,
	color: Color = Color(0.32, 0.18, 0.12)
) -> void:
	var key := _edge_key(cell, edge)
	_overrides[key] = "door"
	_door_flags[key] = {
		"open": starts_open,
		"locked": locked,
		"color": color,
	}


func _place_module(packed: PackedScene, cell: Vector2i, edge: String, height: float = 0.0) -> Node3D:
	var node := packed.instantiate() as Node3D
	var pos := Vector3(cell.x * CELL, height, cell.y * CELL)
	var rot := 0.0
	match edge:
		"n":
			pos.z += CELL
		"s":
			pos.x += CELL
			rot = PI
		"e":
			pos.x += CELL
			rot = PI * 0.5
		"w":
			pos.z += CELL
			rot = -PI * 0.5
	node.position = pos
	node.rotation.y = rot
	_geometry.add_child(node)
	return node


func _place_door(cell: Vector2i, edge: String, key: String) -> void:
	var node := DOOR.instantiate() as Node3D
	var flags: Dictionary = _door_flags.get(key, {})
	var leaf := node.find_child("Door", true, false) as Door
	if leaf != null:
		leaf.starts_open = bool(flags.get("open", false))
		leaf.locked = bool(flags.get("locked", false))
	var color: Color = flags.get("color", Color(0.32, 0.18, 0.12))
	if leaf != null and not color.is_equal_approx(Color(0.32, 0.18, 0.12)):
		_tint_painted_surfaces(leaf, color)
	var pos := Vector3(cell.x * CELL, 0.0, cell.y * CELL)
	var rot := 0.0
	match edge:
		"n":
			pos.z += CELL
		"s":
			pos.x += CELL
			rot = PI
		"e":
			pos.x += CELL
			rot = PI * 0.5
		"w":
			pos.z += CELL
			rot = -PI * 0.5
	node.position = pos
	node.rotation.y = rot
	_geometry.add_child(node)


func _add(packed: PackedScene, origin: Vector3) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = origin
	_geometry.add_child(node)
	return node


func _solid(label: String, origin: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	_prop_index += 1
	var body := StaticBody3D.new()
	body.name = "%s_%d" % [label, _prop_index]
	body.position = origin
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_geometry.add_child(body)
	return body


func _table(at: Vector3) -> void:
	_prop(TABLE, at)


func _chair(at: Vector3) -> void:
	_prop(CHAIR, at)


func _cubicle(at: Vector3) -> void:
	_prop(CUBICLE, at)


func _prop(packed: PackedScene, at: Vector3) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = at
	_geometry.add_child(node)
	return node


func _dim_emissive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var source := mesh_node.get_active_material(surface)
				if source is StandardMaterial3D and (source as StandardMaterial3D).emission_enabled:
					mesh_node.set_surface_override_material(surface, _dead_lamp_mat)
	for child in node.get_children():
		_dim_emissive(child)


func _tint_painted_surfaces(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var source := mesh_node.get_active_material(surface)
				if source is StandardMaterial3D and (source as StandardMaterial3D).metallic < 0.5:
					var painted := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
					painted.albedo_color = color
					painted.albedo_texture = null
					mesh_node.set_surface_override_material(surface, painted)
	for child in node.get_children():
		_tint_painted_surfaces(child, color)


func _ladder(at: Vector3) -> void:
	_solid("Rail", at + Vector3(-0.24, 1.15, 0.0), Vector3(0.04, 2.2, 0.04), _metal_mat)
	_solid("Rail", at + Vector3(0.24, 1.15, 0.0), Vector3(0.04, 2.2, 0.04), _metal_mat)
	for i in range(5):
		_solid("Rung", at + Vector3(0.0, 0.35 + float(i) * 0.4, 0.0), Vector3(0.48, 0.035, 0.035), _metal_mat)


func _security_camera(at: Vector3) -> void:
	_solid("CameraBody", at, Vector3(0.16, 0.12, 0.28), _metal_mat)
	_solid("CameraLed", at + Vector3(0.0, -0.02, 0.12), Vector3(0.035, 0.035, 0.03), _red_mat)
	var led := OmniLight3D.new()
	led.name = "CameraLedLight"
	led.position = at
	led.light_color = Color(1.0, 0.12, 0.08)
	led.light_energy = 0.35
	led.omni_range = 0.8
	_geometry.add_child(led)


func _exit_sign(at: Vector3) -> void:
	var sign := Label3D.new()
	sign.name = "ExitSign"
	sign.text = "EXIT"
	sign.position = at
	sign.pixel_size = 0.004
	sign.font_size = 96
	sign.modulate = Color(1.0, 0.18, 0.12)
	sign.outline_modulate = Color(0.2, 0.0, 0.0)
	sign.outline_size = 12
	_geometry.add_child(sign)
	var glow := OmniLight3D.new()
	glow.position = at
	glow.light_color = Color(1.0, 0.2, 0.12)
	glow.light_energy = 0.6
	glow.omni_range = 1.6
	_geometry.add_child(glow)


func _spot(at: Vector3, angles: Vector3, energy: float, color: Color, shadows: bool) -> void:
	var spot := SpotLight3D.new()
	spot.position = at
	spot.rotation_degrees = angles
	spot.light_color = color
	spot.light_energy = energy
	spot.spot_range = 12.0
	spot.spot_angle = 32.0
	spot.shadow_enabled = shadows
	_geometry.add_child(spot)


func _mat(
	color: Color,
	roughness: float,
	metallic: float = 0.0,
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


func _delta(edge: String) -> Vector2i:
	match edge:
		"n":
			return Vector2i(0, 1)
		"s":
			return Vector2i(0, -1)
		"e":
			return Vector2i(1, 0)
		"w":
			return Vector2i(-1, 0)
	return Vector2i.ZERO


func _opposite(edge: String) -> String:
	match edge:
		"n":
			return "s"
		"s":
			return "n"
		"e":
			return "w"
		"w":
			return "e"
	return edge


func _edge_key(cell: Vector2i, edge: String) -> String:
	var owner := _canonical_cell(cell, edge)
	var side := _canonical_edge(cell, edge)
	return "%d,%d,%s" % [owner.x, owner.y, side]


func _canonical_cell(cell: Vector2i, edge: String) -> Vector2i:
	var other := cell + _delta(edge)
	if other.x < cell.x or (other.x == cell.x and other.y < cell.y):
		return other
	return cell


func _canonical_edge(cell: Vector2i, edge: String) -> String:
	var other := cell + _delta(edge)
	if other.x < cell.x or (other.x == cell.x and other.y < cell.y):
		return _opposite(edge)
	return edge
