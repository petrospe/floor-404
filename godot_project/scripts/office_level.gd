extends Node3D
## Walkable floor of Floor 404. The original rooms stay at the south end, and a
## larger wing of offices, a stairwell, and two elevators continues north.
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
const ELEVATOR_DOORS := preload("res://scripts/elevator_doors.gd")
const ELEVATOR_PANEL := preload("res://scripts/elevator_panel.gd")

var _cells: Array[Vector2i] = []
var _cell_set: Dictionary = {}
var _concrete: Dictionary = {}
var _expansion: Dictionary = {}
var _tall: Dictionary = {}
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
	_expand_floor()
	for cell in _cells:
		if _expansion.has(cell):
			continue
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
		var ceiling := _add(CEILING, origin)
		if _tall.has(cell):
			ceiling.position.y += 2.6

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
				"elevator":
					pass
				_:
					pass


func _build_lights() -> void:
	for cell in _cells:
		var mode := _light_mode(cell)
		if mode == 0:
			continue
		var fixture_y := 5.3 if _tall.has(cell) else 2.9
		var panel := LIGHT.instantiate() as Node3D
		panel.position = Vector3(cell.x * CELL + 2.0, fixture_y, cell.y * CELL + 2.0)
		_geometry.add_child(panel)
		var glow := panel.get_node(^"Glow") as OmniLight3D
		if mode == 2:
			glow.visible = false
			_dim_emissive(panel)
			continue
		var on_grid := posmod(cell.x, 3) == 0 and posmod(cell.y, 3) == 0
		if mode != 3 and not _tall.has(cell) and not on_grid:
			glow.visible = false
			continue
		glow.omni_range = 14.0
		glow.light_energy = 1.8
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
	_stairwell()
	_extra_rooms()
	_server_room()
	_meeting_room()
	_crt_room()
	_build_elevators()
	_furnish_half()


func _break_room() -> void:
	_table(Vector3(10.2, 0.0, 27.5))
	_table(Vector3(13.4, 0.0, 31.5))
	_chair(Vector3(10.2, 0.0, 28.6))
	_chair(Vector3(13.4, 0.0, 30.4))
	# North wall, clear of the east and west doors around z = 30.
	_cooler(Vector3(9.7, 0.0, 35.75), PI)
	_fridge(Vector3(13.6, 0.0, 35.64), PI)
	_counter(Vector3(12.4, 0.0, 24.45))
	_extinguisher(Vector3(15.62, 0.0, 26.4))
	_folding_chair(Vector3(11.4, 0.0, 33.4), 0.4)
	_folding_chair(Vector3(12.5, 0.0, 33.9), -0.3)
	_solid("Books", Vector3(9.2, 0.08, 26.4), Vector3(0.28, 0.08, 0.2), _desk_mat)


func _cubicles() -> void:
	for row in range(3):
		for col in range(3):
			_cubicle(Vector3(-1.2 + float(col) * 3.3, 0.0, 43.5 + float(row) * 3.5))


func _columns() -> void:
	for point in [Vector3(-1.0, 0.0, 60.5), Vector3(5.0, 0.0, 60.5), Vector3(-1.0, 0.0, 65.0), Vector3(5.0, 0.0, 65.0)]:
		_prop(COLUMN, point)
	_office_chair(_geometry, Vector3(2.0, 0.0, 62.0), 0.6)


func _security_room() -> void:
	_solid("Desk", Vector3(-14.2, 0.78, 64.5), Vector3(3.4, 0.08, 0.8), _desk_mat)
	_solid("DeskLeg", Vector3(-14.2, 0.38, 64.5), Vector3(3.2, 0.72, 0.08), _metal_mat)
	_office_chair(_geometry, Vector3(-15.0, 0.0, 65.7), PI)
	_office_chair(_geometry, Vector3(-13.2, 0.0, 65.7), PI)
	for i in range(3):
		var x := -15.15 + float(i) * 0.95
		_crt(_geometry, Vector3(x, 0.82, 64.4), 0.0)
	_tower(_geometry, Vector3(-12.7, 0.0, 64.35), 0.0)
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
	var tread := _mat(Color(0.35, 0.35, 0.36), 0.7)
	for i in range(8):
		var top := rise * float(i + 1)
		var z := 69.2 + float(i) * depth
		_decor("Step", Vector3(2.0, top - rise * 0.5, z), Vector3(2.1, rise, depth), tread)
		_decor("StepSide", Vector3(0.475, top * 0.5, z), Vector3(0.95, top, depth), tread)
		_decor("StepSide", Vector3(3.525, top * 0.5, z), Vector3(0.95, top, depth), tread)
	# Slope, then a flat landing. No riser collision, so the capsule can walk up.
	_flight(0.2, 3.8, 69.0, 0.05, 71.55, 0.8, 75.94)
	_decor("Landing", Vector3(2.0, 0.4, 73.75), Vector3(4.0, 0.8, 4.4), _mat(Color(0.32, 0.32, 0.33), 0.65))
	_red_door(Vector3(2.0, 1.8, 75.94))


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
			return 1
		&"service":
			return 1
		&"security", &"expansion":
			return 1
		_:
			return 0


func _region_of(cell: Vector2i) -> StringName:
	if _expansion.has(cell):
		return &"expansion"
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


func _expand_floor() -> void:
	var before := _cell_set.duplicate()
	# Link off the first corridor, then a long east artery into the north wing.
	_fill(1, 1, 1, 1)
	_fill(2, 5, 0, 5)
	_fill(6, 6, 2, 2)
	_fill(4, 7, 6, 18)
	_fill(-6, 7, 19, 56)
	for cell in _cells:
		if not before.has(cell):
			_expansion[cell] = true
	_mark(Vector2i(0, 18), "n", "wall")
	_mark_door(Vector2i(0, 1), "e")
	_mark(Vector2i(1, 1), "n", "wall")
	_partition_south_offices()
	_partition_east_artery()
	_partition_north_wing()
	_carve_stairwell()
	_carve_cubicle_bay()
	_carve_server_room()
	_carve_meeting_room()
	_carve_crt_room()
	_mark_door(Vector2i(3, 7), "e")
	_mark(Vector2i(3, 6), "e", "wall")
	_mark(Vector2i(3, 8), "e", "wall")
	for z in [22, 23, 30, 31, 44, 45]:
		_mark(Vector2i(-6, z), "w", "window")
	for x in [5, 6]:
		for z in [40, 41, 42]:
			_tall[Vector2i(x, z)] = true
	_mark(Vector2i(-6, 49), "n", "wall")
	_mark(Vector2i(-6, 50), "n", "wall")
	_mark(Vector2i(-6, 50), "e", "elevator")


func _partition_south_offices() -> void:
	for z in [0, 1, 3, 4, 5]:
		_mark(Vector2i(2, z), "e", "wall")
	for x in [2, 3, 4]:
		_mark(Vector2i(x, 2), "e", "none")
	_mark(Vector2i(5, 2), "e", "elevator")
	for z in [1, 3, 4]:
		for x in [3, 4, 5]:
			_mark(Vector2i(x, z), "n", "wall")
	for x in [2, 3, 5]:
		_mark(Vector2i(x, 5), "n", "wall")


func _partition_east_artery() -> void:
	for z in range(6, 19):
		if (z + 1) % 3 == 0:
			for x in [5, 6, 7]:
				_mark(Vector2i(x, z), "n", "wall")
		if z % 3 == 0:
			_mark_door(Vector2i(4, z), "e")
		else:
			_mark(Vector2i(4, z), "e", "wall")
		if z % 3 == 1:
			_mark_door(Vector2i(5, z), "e")
		else:
			_mark(Vector2i(5, z), "e", "wall")


func _partition_north_wing() -> void:
	for z in range(19, 56):
		if (z + 1) % 4 == 0:
			for x in range(-6, 8):
				if x == 0 or x == 1 or x == 4:
					continue
				_mark(Vector2i(x, z), "n", "wall")
	for z in range(19, 57):
		if z % 4 == 1:
			_mark_door(Vector2i(1, z), "e")
		else:
			_mark(Vector2i(1, z), "e", "wall")
		if z % 4 == 3:
			_mark_door(Vector2i(-1, z), "e")
			_mark_door(Vector2i(3, z), "e")
		else:
			_mark(Vector2i(-1, z), "e", "wall")
			_mark(Vector2i(3, z), "e", "wall")
		if z % 4 == 1:
			_mark_door(Vector2i(4, z), "e")
		else:
			_mark(Vector2i(4, z), "e", "wall")
		if z % 4 == 2:
			_mark_door(Vector2i(-4, z), "e")
		else:
			_mark(Vector2i(-4, z), "e", "wall")
		if z % 5 == 0:
			_mark_door(Vector2i(5, z), "e")
		else:
			_mark(Vector2i(5, z), "e", "wall")


func _carve_stairwell() -> void:
	_mark_door(Vector2i(4, 40), "e")
	_mark(Vector2i(4, 41), "e", "wall")
	_mark(Vector2i(4, 42), "e", "wall")
	for z in [40, 41, 42]:
		_mark(Vector2i(5, z), "e", "none")
		_mark(Vector2i(6, z), "e", "wall")
	_mark(Vector2i(5, 42), "n", "wall")
	_mark(Vector2i(6, 42), "n", "wall")
	_mark(Vector2i(5, 39), "n", "wall")
	_mark(Vector2i(6, 39), "n", "wall")


func _carve_cubicle_bay() -> void:
	_mark_door(Vector2i(4, 47), "e")
	for z in range(46, 50):
		_mark(Vector2i(5, z), "e", "none")
		_mark(Vector2i(6, z), "e", "none")
		for x in [5, 6, 7]:
			_mark(Vector2i(x, z), "n", "none")
	for x in [5, 6, 7]:
		_mark(Vector2i(x, 45), "n", "wall")
		_mark(Vector2i(x, 49), "n", "wall")


func _carve_server_room() -> void:
	# West band, x -24..-16, z 96..108. Door on the east side, away from the racks.
	_mark(Vector2i(-5, 24), "e", "wall")
	_mark(Vector2i(-5, 25), "e", "wall")
	_mark_door(Vector2i(-5, 26), "e")
	_mark(Vector2i(-6, 26), "n", "wall")
	_mark(Vector2i(-5, 26), "n", "wall")
	for x in [-6, -5]:
		for z in [24, 25, 26]:
			_concrete[Vector2i(x, z)] = true


func _carve_meeting_room() -> void:
	# x 8..16, z 128..140. The west door is the existing opening on cell (1, 33).
	_mark(Vector2i(2, 34), "n", "wall")
	_mark(Vector2i(3, 34), "n", "wall")
	for z in [32, 33]:
		_mark(Vector2i(2, z), "n", "none")
		_mark(Vector2i(3, z), "n", "none")
	for z in [32, 33, 34]:
		_mark(Vector2i(2, z), "e", "none")


func _carve_crt_room() -> void:
	# x -12..-4, z 144..152. One desk against the north wall.
	_mark(Vector2i(-3, 36), "e", "none")
	_mark(Vector2i(-3, 37), "e", "none")
	_mark_door(Vector2i(-2, 36), "e")
	_mark(Vector2i(-2, 37), "e", "wall")
	_mark(Vector2i(-3, 37), "n", "wall")
	_mark(Vector2i(-2, 37), "n", "wall")


func _stairwell() -> void:
	var concrete := _mat(Color(0.78, 0.77, 0.74), 0.62)
	var beige := _mat(Color(0.73, 0.69, 0.6), 0.78)
	var rail := _mat(Color(0.16, 0.16, 0.17), 0.4, 0.65)
	var x0 := 20.45
	var x1 := 23.7
	var z0 := 164.2
	var z1 := 169.4
	var rise := 2.2
	var count := 11
	var depth := (z1 - z0) / float(count)
	for i in range(count):
		var top := rise * float(i + 1) / float(count)
		var z := z0 + (float(i) + 0.5) * depth
		_decor("WellStep", Vector3((x0 + x1) * 0.5, top - rise / float(count) * 0.5, z), Vector3(x1 - x0, rise / float(count), depth), concrete)
	var land_end := 171.94
	var land_z := (z1 + land_end) * 0.5
	var land_depth := land_end - z1
	_decor("WellLanding", Vector3((x0 + x1) * 0.5, rise * 0.5, land_z), Vector3(x1 - x0, rise, land_depth), concrete)
	_solid("WellLanding", Vector3((x1 + 27.8) * 0.5, rise * 0.5, land_z), Vector3(27.8 - x1, rise, land_depth), concrete)
	_flight(x0, x1, z0, 0.05, z1, rise, land_end)
	_red_door(Vector3(24.0, rise + 1.0, 171.94))
	_rail_run(x1 + 0.08, z0, 0.15, z1, rise + 0.15, rail)
	_solid("WellRailPost", Vector3(x1 + 0.08, rise + 0.55, 170.6), Vector3(0.05, 1.1, 0.05), rail)
	_solid("WellRail", Vector3(25.6, rise + 0.95, 169.45), Vector3(3.6, 0.04, 0.04), rail)
	_solid("WellUpper", Vector3(24.0, 4.3, 159.98), Vector3(8.0, 2.6, 0.16), beige)
	_solid("WellUpper", Vector3(24.0, 4.3, 172.02), Vector3(8.0, 2.6, 0.16), beige)
	_solid("WellUpper", Vector3(20.08, 4.3, 166.0), Vector3(0.16, 2.6, 12.0), beige)
	_solid("WellUpper", Vector3(27.92, 4.3, 166.0), Vector3(0.16, 2.6, 12.0), beige)


func _rail_run(x: float, z0: float, y0: float, z1: float, y1: float, material: Material) -> void:
	var posts := 7
	for i in range(posts + 1):
		var t := float(i) / float(posts)
		var z := lerpf(z0, z1, t)
		var y := lerpf(y0, y1, t)
		_solid("RailPost", Vector3(x, y + 0.45, z), Vector3(0.045, 0.9, 0.045), material)
	_sloped_bar(x, z0, y0 + 0.42, z1, y1 + 0.42, material)
	_sloped_bar(x, z0, y0 + 0.88, z1, y1 + 0.88, material)


func _sloped_bar(x: float, z0: float, y0: float, z1: float, y1: float, material: Material) -> void:
	_prop_index += 1
	var body := StaticBody3D.new()
	body.name = "Rail_%d" % _prop_index
	var dz := z1 - z0
	var dy := y1 - y0
	body.position = Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
	body.rotation.x = -atan2(dy, dz)
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, sqrt(dz * dz + dy * dy))
	mesh_node.mesh = box
	mesh_node.material_override = material
	body.add_child(mesh_node)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	body.add_child(collision)
	_geometry.add_child(body)


func _extra_rooms() -> void:
	_table(Vector3(27.1, 0.0, 102.8))
	_office_chair(_geometry, Vector3(27.1, 0.0, 103.7), PI)
	_office_chair(_geometry, Vector3(26.2, 0.0, 102.2), PI * 0.5)
	_table(Vector3(-14.0, 0.0, 114.0))
	_office_chair(_geometry, Vector3(-14.0, 0.0, 114.9), PI)
	_office_chair(_geometry, Vector3(-13.3, 0.0, 113.5), -PI * 0.5)
	# Bay interior is x 20.1–31.9, z 184.1–199.9. The west door swings to about x 21.1.
	var bay_x: Array[float] = [22.3, 24.6, 26.9, 29.2]
	var bay_z: Array[float] = [184.7, 187.5, 191.6, 194.9, 198.0]
	for z in bay_z:
		for x in bay_x:
			_cubicle(Vector3(x, 0.0, z))


func _build_elevators() -> void:
	var first = ELEVATOR_DOORS.new()
	first.name = "ElevatorA"
	first.build("04")
	_place_node(first, Vector2i(5, 2), "e")
	var second = ELEVATOR_DOORS.new()
	second.name = "ElevatorB"
	second.build("05")
	_place_node(second, Vector2i(-6, 50), "e")
	var marker_a := _elevator_marker("RideA", Vector3(26.5, 0.05, 10.0), PI * 0.5)
	var marker_b := _elevator_marker("RideB", Vector3(-22.5, 0.05, 202.0), -PI * 0.5)
	_dress_car(Vector3(26.0, 0.0, 10.0), true)
	_dress_car(Vector3(-22.0, 0.0, 202.0), false)
	var panel_a = _elevator_panel(Vector3(27.67, 1.25, 10.35), -1.0, 4)
	var panel_b = _elevator_panel(Vector3(-23.67, 1.25, 202.35), 1.0, 5)
	panel_a.partner_marker = marker_b
	panel_a.partner_doors = second
	panel_b.partner_marker = marker_a
	panel_b.partner_doors = first


func _elevator_marker(label: String, at: Vector3, yaw: float) -> Node3D:
	var marker := Node3D.new()
	marker.name = label
	marker.position = at
	marker.rotation.y = yaw
	_geometry.add_child(marker)
	return marker


func _elevator_panel(at: Vector3, face: float, lit_floor: int):
	var panel = ELEVATOR_PANEL.new()
	panel.position = at
	var steel := _mat(Color(0.62, 0.63, 0.66), 0.35, 0.7)
	var button := _mat(Color(0.16, 0.16, 0.17), 0.4, 0.35)
	var lit := _mat(Color(0.15, 0.45, 0.28), 0.35, 0.1, Color(0.2, 0.85, 0.45), 1.8)
	_part(panel, Vector3(0.0, 0.0, 0.0), Vector3(0.04, 0.58, 0.26), steel)
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = Vector3(0.06, 0.62, 0.3)
	shape.shape = collision
	panel.add_child(shape)
	for index in range(15):
		var column := index % 3
		var row := 4 - int(index / 3.0)
		var floor_number := 15 - index
		var local := Vector3(face * 0.03, -0.2 + float(row) * 0.09, -0.07 + float(column) * 0.07)
		_part(panel, local, Vector3(0.018, 0.045, 0.045), lit if floor_number == lit_floor else button)
		var label := Label3D.new()
		label.text = str(floor_number)
		label.position = local + Vector3(face * 0.012, 0.0, 0.0)
		label.rotation.y = face * PI * 0.5
		label.pixel_size = 0.0012
		label.font_size = 28
		label.modulate = Color(0.92, 0.93, 0.9) if floor_number != lit_floor else Color(0.7, 1.0, 0.8)
		label.outline_size = 0
		panel.add_child(label)
	_geometry.add_child(panel)
	return panel


func _dress_car(center: Vector3, door_on_west: bool) -> void:
	var wood := _mat(Color(0.66, 0.54, 0.38), 0.58)
	var tile := _mat(Color(0.82, 0.82, 0.8), 0.35, 0.08)
	_decor("CarFloor", center + Vector3(0.0, 0.02, 0.0), Vector3(3.5, 0.04, 3.5), tile)
	_decor("CarSide", center + Vector3(0.0, 1.2, 1.72), Vector3(3.2, 2.35, 0.06), wood)
	_decor("CarSide", center + Vector3(0.0, 1.2, -1.72), Vector3(3.2, 2.35, 0.06), wood)
	var back := 1.72 if door_on_west else -1.72
	_decor("CarBack", center + Vector3(back, 1.2, 0.0), Vector3(0.06, 2.35, 3.2), wood)
	var lamp := OmniLight3D.new()
	lamp.position = center + Vector3(0.0, 2.55, 0.0)
	lamp.light_color = Color(0.95, 0.94, 0.88)
	lamp.light_energy = 1.6
	lamp.omni_range = 5.0
	_geometry.add_child(lamp)
	_decor("CarLamp", lamp.position, Vector3(1.2, 0.05, 0.35), _mat(Color(0.9, 0.9, 0.86), 0.4, 0.0, Color(0.95, 0.93, 0.85), 3.0))


func _place_node(node: Node3D, cell: Vector2i, edge: String) -> void:
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
			pos.z += CELL
			rot = PI * 0.5
		"w":
			rot = -PI * 0.5
	node.position = pos
	node.rotation.y = rot
	_geometry.add_child(node)


func _flight(x0: float, x1: float, z0: float, y0: float, z_top: float, y_top: float, z_end: float) -> void:
	_prop_index += 1
	var body := StaticBody3D.new()
	body.name = "Ramp_%d" % _prop_index
	var shape := ConvexPolygonShape3D.new()
	var bottom := minf(y0, y_top) - 0.25
	shape.points = PackedVector3Array([
		Vector3(x0, y0, z0), Vector3(x1, y0, z0),
		Vector3(x0, y_top, z_top), Vector3(x1, y_top, z_top),
		Vector3(x0, y_top, z_end), Vector3(x1, y_top, z_end),
		Vector3(x0, bottom, z0), Vector3(x1, bottom, z0),
		Vector3(x0, bottom, z_end), Vector3(x1, bottom, z_end),
	])
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_geometry.add_child(body)


func _decor(label: String, origin: Vector3, size: Vector3, material: Material) -> void:
	_prop_index += 1
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "%s_%d" % [label, _prop_index]
	mesh_node.position = origin
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = material
	_geometry.add_child(mesh_node)


func _red_door(wall_face: Vector3) -> void:
	# wall_face sits on the room side of the wall. The room is toward -Z.
	var frame := _mat(Color(0.32, 0.28, 0.25), 0.55, 0.12)
	var depth := 0.05
	_solid("RedFrame", wall_face + Vector3(0.0, 0.0, 0.01), Vector3(1.5, 2.28, 0.04), frame)
	var center := wall_face + Vector3(0.0, 0.0, -depth * 0.5)
	_solid("RedDoor", center, Vector3(1.2, 2.04, depth), _red_mat)
	_solid("RedHandle", center + Vector3(0.46, -0.04, -depth * 0.5 - 0.025), Vector3(0.14, 0.035, 0.035), _metal_mat)


func _cooler(at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "Cooler"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var cabinet := _mat(Color(0.9, 0.91, 0.92), 0.28, 0.08)
	var trim := _mat(Color(0.18, 0.19, 0.2), 0.4, 0.45)
	_part(root, Vector3(0.0, 0.55, 0.0), Vector3(0.4, 1.05, 0.36), cabinet)
	_part(root, Vector3(0.0, 0.05, 0.0), Vector3(0.44, 0.1, 0.4), trim)
	_part(root, Vector3(0.0, 1.04, 0.0), Vector3(0.34, 0.05, 0.32), trim)
	_part(root, Vector3(0.0, 0.72, 0.19), Vector3(0.18, 0.02, 0.06), trim)
	_part(root, Vector3(0.0, 0.78, 0.2), Vector3(0.04, 0.045, 0.05), _metal_mat)
	_cylinder(root, Vector3(0.0, 1.32, 0.0), 0.1, 0.15, 0.46, _bottle_mat)
	_cylinder(root, Vector3(0.0, 1.08, 0.0), 0.045, 0.045, 0.08, _bottle_mat)


func _monitor(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Monitor"
	root.position = at
	_geometry.add_child(root)
	var bezel := _mat(Color(0.06, 0.06, 0.07), 0.38, 0.3)
	var neck := _mat(Color(0.14, 0.14, 0.15), 0.32, 0.55)
	_part(root, Vector3(0.0, 0.012, 0.03), Vector3(0.22, 0.02, 0.16), bezel)
	_part(root, Vector3(0.0, 0.1, 0.0), Vector3(0.04, 0.16, 0.04), neck)
	var housing := Node3D.new()
	housing.position = Vector3(0.0, 0.3, -0.015)
	housing.rotation.x = deg_to_rad(-8.0)
	root.add_child(housing)
	_part(housing, Vector3(0.0, 0.0, -0.012), Vector3(0.52, 0.34, 0.028), bezel)
	_part(housing, Vector3(0.0, 0.155, 0.01), Vector3(0.52, 0.03, 0.018), bezel)
	_part(housing, Vector3(0.0, -0.155, 0.01), Vector3(0.52, 0.03, 0.018), bezel)
	_part(housing, Vector3(-0.245, 0.0, 0.01), Vector3(0.03, 0.28, 0.018), bezel)
	_part(housing, Vector3(0.245, 0.0, 0.01), Vector3(0.03, 0.28, 0.018), bezel)
	_part(housing, Vector3(0.0, 0.006, 0.008), Vector3(0.44, 0.25, 0.008), _monitor_mat)
	var led := _mat(Color(0.15, 0.55, 0.25), 0.3, 0.0, Color(0.3, 0.9, 0.4), 1.4)
	_part(housing, Vector3(0.2, -0.155, 0.022), Vector3(0.012, 0.008, 0.006), led)


func _cylinder(
	parent: Node3D,
	origin: Vector3,
	bottom_radius: float,
	top_radius: float,
	height: float,
	material: Material
) -> void:
	var body := StaticBody3D.new()
	body.position = origin
	var mesh_node := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.bottom_radius = bottom_radius
	cylinder.top_radius = top_radius
	cylinder.height = height
	cylinder.radial_segments = 20
	mesh_node.mesh = cylinder
	mesh_node.material_override = material
	body.add_child(mesh_node)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = maxf(bottom_radius, top_radius)
	shape.height = height
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _bit(parent: Node3D, origin: Vector3, size: Vector3, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.position = origin
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _bit_cylinder(parent: Node3D, origin: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.position = origin
	var cylinder := CylinderMesh.new()
	cylinder.bottom_radius = radius
	cylinder.top_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 12
	mesh_node.mesh = cylinder
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _fridge(at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "Fridge"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var shell := _mat(Color(0.9, 0.91, 0.92), 0.28, 0.08)
	var inside := _mat(Color(0.82, 0.86, 0.88), 0.4)
	var glass := _mat(Color(0.75, 0.88, 0.92, 0.16), 0.05, 0.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_part(root, Vector3(0.0, 0.95, -0.28), Vector3(0.9, 1.9, 0.05), shell)
	_part(root, Vector3(-0.44, 0.95, 0.0), Vector3(0.04, 1.9, 0.6), shell)
	_part(root, Vector3(0.44, 0.95, 0.0), Vector3(0.04, 1.9, 0.6), shell)
	_part(root, Vector3(0.0, 1.88, 0.0), Vector3(0.9, 0.06, 0.6), shell)
	_part(root, Vector3(0.0, 0.05, 0.0), Vector3(0.94, 0.1, 0.64), shell)
	for shelf_y in [0.42, 0.82, 1.22, 1.58]:
		_part(root, Vector3(0.0, shelf_y, 0.0), Vector3(0.82, 0.02, 0.5), inside)
	_bit(root, Vector3(0.0, 1.02, 0.3), Vector3(0.78, 1.55, 0.015), glass)
	var cola := _mat(Color(0.72, 0.08, 0.07), 0.35, 0.15)
	var sprite := _mat(Color(0.16, 0.62, 0.22), 0.35, 0.15)
	var beer := _mat(Color(0.55, 0.32, 0.1), 0.25, 0.05)
	var bread := _mat(Color(0.86, 0.75, 0.5), 0.7)
	var lettuce := _mat(Color(0.35, 0.55, 0.22), 0.6)
	var chocolate := _mat(Color(0.28, 0.13, 0.07), 0.45)
	for i in range(4):
		var x := -0.24 + float(i) * 0.14
		_bit_cylinder(root, Vector3(x, 1.7, -0.05), 0.032, 0.12, cola if i < 2 else sprite)
	for i in range(3):
		var x := -0.18 + float(i) * 0.18
		_bit_cylinder(root, Vector3(x, 1.36, 0.0), 0.03, 0.2, beer)
		_bit_cylinder(root, Vector3(x, 1.47, 0.0), 0.016, 0.03, _metal_mat)
	for i in range(3):
		var x := -0.22 + float(i) * 0.2
		_bit(root, Vector3(x, 0.9, 0.0), Vector3(0.14, 0.07, 0.12), bread)
		_bit(root, Vector3(x, 0.9, 0.02), Vector3(0.12, 0.02, 0.08), lettuce)
	for i in range(5):
		var x := -0.28 + float(i) * 0.13
		_bit(root, Vector3(x, 0.48, -0.02 + float(i % 2) * 0.08), Vector3(0.1, 0.035, 0.08), chocolate)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 1.5, 0.05)
	lamp.light_color = Color(0.9, 0.95, 1.0)
	lamp.light_energy = 0.45
	lamp.omni_range = 1.4
	root.add_child(lamp)


func _counter(at: Vector3) -> void:
	var cabinet := _mat(Color(0.9, 0.9, 0.88), 0.45)
	var top := _mat(Color(0.12, 0.12, 0.13), 0.35, 0.05)
	_solid("Counter", at + Vector3(0.0, 0.42, 0.0), Vector3(3.4, 0.84, 0.58), cabinet)
	_solid("CounterTop", at + Vector3(0.0, 0.86, 0.0), Vector3(3.5, 0.04, 0.62), top)


func _extinguisher(at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	_geometry.add_child(root)
	var red := _mat(Color(0.7, 0.08, 0.06), 0.4, 0.1)
	_cylinder(root, Vector3(0.0, 0.38, 0.0), 0.09, 0.09, 0.55, red)
	_cylinder(root, Vector3(0.0, 0.7, 0.0), 0.04, 0.04, 0.1, _metal_mat)
	_bit(root, Vector3(0.08, 0.62, 0.0), Vector3(0.08, 0.02, 0.02), _metal_mat)


func _folding_chair(at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var pad := _mat(Color(0.82, 0.82, 0.8), 0.6)
	_part(root, Vector3(0.0, 0.46, 0.0), Vector3(0.42, 0.03, 0.4), pad)
	_part(root, Vector3(0.0, 0.7, -0.18), Vector3(0.42, 0.38, 0.02), pad)
	_part(root, Vector3(0.16, 0.24, 0.0), Vector3(0.02, 0.48, 0.36), _metal_mat)
	_part(root, Vector3(-0.16, 0.24, 0.0), Vector3(0.02, 0.48, 0.36), _metal_mat)


func _crt(parent: Node3D, at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "Crt"
	root.position = at
	root.rotation.y = yaw
	parent.add_child(root)
	var beige := _mat(Color(0.72, 0.68, 0.56), 0.55)
	var glass := _mat(Color(0.04, 0.08, 0.12), 0.08, 0.0, Color(0.15, 0.35, 0.7), 0.7)
	_part(root, Vector3(0.0, 0.015, 0.04), Vector3(0.24, 0.03, 0.18), beige)
	_part(root, Vector3(0.0, 0.07, 0.0), Vector3(0.07, 0.08, 0.07), beige)
	_part(root, Vector3(0.0, 0.28, -0.02), Vector3(0.46, 0.38, 0.4), beige)
	_bit(root, Vector3(0.0, 0.3, 0.19), Vector3(0.32, 0.24, 0.02), glass)


func _keyboard(parent: Node3D, at: Vector3) -> void:
	var beige := _mat(Color(0.75, 0.72, 0.62), 0.6)
	_bit(parent, at, Vector3(0.4, 0.02, 0.14), beige)
	_bit(parent, at + Vector3(0.22, 0.01, 0.08), Vector3(0.06, 0.02, 0.09), beige)


func _tower(parent: Node3D, at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "Tower"
	root.position = at
	root.rotation.y = yaw
	parent.add_child(root)
	var case_mat := _mat(Color(0.68, 0.66, 0.62), 0.4, 0.15)
	var bay := _mat(Color(0.2, 0.2, 0.22), 0.45, 0.2)
	_part(root, Vector3(0.0, 0.22, 0.0), Vector3(0.2, 0.44, 0.46), case_mat)
	_bit(root, Vector3(0.0, 0.34, 0.23), Vector3(0.16, 0.04, 0.01), bay)
	_bit(root, Vector3(0.0, 0.28, 0.23), Vector3(0.16, 0.04, 0.01), bay)
	_bit(root, Vector3(0.06, 0.12, 0.23), Vector3(0.03, 0.03, 0.01), _mat(Color(0.2, 0.7, 0.3), 0.4, 0.0, Color(0.2, 0.8, 0.3), 1.2))


func _office_chair(parent: Node3D, at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "OfficeChair"
	root.position = at
	root.rotation.y = yaw
	parent.add_child(root)
	var cloth := _mat(Color(0.16, 0.18, 0.22), 0.7)
	var base := _mat(Color(0.25, 0.26, 0.28), 0.35, 0.6)
	_part(root, Vector3(0.0, 0.48, 0.02), Vector3(0.46, 0.07, 0.46), cloth)
	_part(root, Vector3(0.0, 0.74, -0.18), Vector3(0.44, 0.42, 0.06), cloth)
	_part(root, Vector3(0.0, 0.28, 0.0), Vector3(0.06, 0.32, 0.06), base)
	for i in range(5):
		var arm := Node3D.new()
		arm.rotation.y = float(i) * TAU / 5.0
		root.add_child(arm)
		_bit(arm, Vector3(0.0, 0.08, 0.14), Vector3(0.03, 0.02, 0.26), base)
		_bit(arm, Vector3(0.0, 0.05, 0.26), Vector3(0.04, 0.04, 0.05), base)


func _server_room() -> void:
	var blue := _mat(Color(0.05, 0.2, 0.45), 0.3, 0.0, Color(0.2, 0.45, 1.0), 2.2)
	var red := _mat(Color(0.4, 0.05, 0.08), 0.3, 0.0, Color(0.9, 0.08, 0.12), 2.4)
	var zs: Array[float] = [97.4, 98.6, 99.8, 101.0, 102.2]
	for z in zs:
		_rack(Vector3(-22.7, 0.0, z), PI * 0.5, false, blue, red)
		_rack(Vector3(-20.3, 0.0, z), -PI * 0.5, z == 99.8, blue, red)
	var cool := OmniLight3D.new()
	cool.position = Vector3(-21.5, 2.1, 99.5)
	cool.light_color = Color(0.35, 0.55, 1.0)
	cool.light_energy = 1.4
	cool.omni_range = 7.0
	_geometry.add_child(cool)
	var alarm := OmniLight3D.new()
	alarm.position = Vector3(-20.3, 1.5, 99.8)
	alarm.light_color = Color(1.0, 0.15, 0.18)
	alarm.light_energy = 0.8
	alarm.omni_range = 3.5
	_geometry.add_child(alarm)


func _rack(at: Vector3, yaw: float, alarm: bool, blue: Material, red: Material) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var black := _mat(Color(0.04, 0.045, 0.05), 0.4, 0.35)
	_part(root, Vector3(0.0, 1.05, 0.0), Vector3(0.66, 2.1, 0.9), black)
	for i in range(7):
		var y := 0.28 + float(i) * 0.26
		var lit: Material = red if alarm and i >= 4 else blue
		_bit(root, Vector3(0.0, y, 0.46), Vector3(0.52, 0.035, 0.012), lit)


func _meeting_room() -> void:
	var wood := _mat(Color(0.45, 0.32, 0.2), 0.55)
	_solid("MeetTable", Vector3(12.0, 0.76, 134.0), Vector3(1.3, 0.06, 6.4), wood)
	_solid("MeetLeg", Vector3(12.0, 0.38, 131.4), Vector3(0.08, 0.76, 0.08), _metal_mat)
	_solid("MeetLeg", Vector3(12.0, 0.38, 136.6), Vector3(0.08, 0.76, 0.08), _metal_mat)
	for z in [131.2, 134.0, 136.8]:
		_office_chair(_geometry, Vector3(10.85, 0.0, z), PI * 0.5)
		_office_chair(_geometry, Vector3(13.15, 0.0, z), -PI * 0.5)
	var bezel := _mat(Color(0.05, 0.05, 0.06), 0.4, 0.3)
	var screen := _mat(Color(0.01, 0.02, 0.03), 0.12, 0.0, Color(0.05, 0.08, 0.12), 0.35)
	_solid("MeetScreen", Vector3(15.9, 1.65, 134.0), Vector3(0.06, 1.15, 2.3), bezel)
	_decor("MeetGlass", Vector3(15.86, 1.68, 134.0), Vector3(0.02, 0.95, 2.05), screen)
	var poster := _mat(Color(0.12, 0.42, 0.38), 0.6)
	var poster_b := _mat(Color(0.16, 0.48, 0.32), 0.6)
	for i in range(4):
		var x := 9.6 + float(i) * 1.5
		_decor("Poster", Vector3(x, 1.7, 139.9), Vector3(0.7, 0.5, 0.02), poster if i % 2 == 0 else poster_b)
	var wash := OmniLight3D.new()
	wash.position = Vector3(12.0, 2.5, 134.0)
	wash.light_color = Color(0.9, 0.92, 0.88)
	wash.light_energy = 1.1
	wash.omni_range = 8.0
	_geometry.add_child(wash)


func _crt_room() -> void:
	_table(Vector3(-8.0, 0.0, 151.15))
	_crt(_geometry, Vector3(-8.0, 0.78, 151.05), PI)
	_keyboard(_geometry, Vector3(-8.05, 0.8, 150.75))
	_tower(_geometry, Vector3(-6.95, 0.0, 151.2), PI)
	_printer(_geometry, Vector3(-9.15, 0.78, 151.1))
	_office_chair(_geometry, Vector3(-8.0, 0.0, 150.15), 0.0)
	var tube := OmniLight3D.new()
	tube.position = Vector3(-8.0, 2.55, 150.4)
	tube.light_color = Color(0.95, 0.94, 0.85)
	tube.light_energy = 1.3
	tube.omni_range = 6.0
	_geometry.add_child(tube)


func _printer(parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	var beige := _mat(Color(0.74, 0.72, 0.64), 0.55)
	_bit(root, Vector3(0.0, 0.08, 0.0), Vector3(0.48, 0.16, 0.38), beige)
	_bit(root, Vector3(0.0, 0.2, -0.04), Vector3(0.4, 0.1, 0.22), beige)
	_bit(root, Vector3(-0.05, 0.02, 0.16), Vector3(0.32, 0.02, 0.1), beige)


func _part(parent: Node3D, origin: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = origin
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = material
	body.add_child(mesh_node)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


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
			# The module extends 4 m toward -Z from its origin, so the origin sits
			# on the north end of this cell's east edge.
			pos.x += CELL
			pos.z += CELL
			rot = PI * 0.5
		"w":
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
			pos.z += CELL
			rot = PI * 0.5
		"w":
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


func _chair(at: Vector3, yaw: float = 0.0) -> void:
	var root := Node3D.new()
	root.name = "Chair"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var black := _mat(Color(0.07, 0.07, 0.08), 0.55)
	_part(root, Vector3(0.0, 0.47, 0.0), Vector3(0.44, 0.05, 0.42), black)
	_part(root, Vector3(0.0, 0.74, -0.19), Vector3(0.44, 0.48, 0.045), black)
	for x in [-0.17, 0.17]:
		for z in [-0.16, 0.16]:
			_part(root, Vector3(x, 0.23, z), Vector3(0.028, 0.46, 0.028), _metal_mat)


func _cubicle(at: Vector3, yaw: float = 0.0) -> void:
	var node := _prop(CUBICLE, at)
	node.rotation.y = yaw
	# Back, sides, and the desk block the walk. The front of the stall stays open.
	for block in [
		[Vector3(0.0, 0.7, 0.0), Vector3(1.9, 1.4, 0.1)],
		[Vector3(-0.9, 0.76, 0.75), Vector3(0.1, 1.28, 1.52)],
		[Vector3(0.9, 0.76, 0.75), Vector3(0.1, 1.28, 1.52)],
		[Vector3(0.0, 0.38, 0.52), Vector3(1.42, 0.76, 0.7)],
	]:
		var body := StaticBody3D.new()
		body.position = block[0]
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = block[1]
		collision.shape = shape
		body.add_child(collision)
		node.add_child(body)
	_crt(node, Vector3(0.0, 0.76, 0.46), 0.0)
	_keyboard(node, Vector3(0.02, 0.775, 0.7))
	_office_chair(node, Vector3(0.1, 0.0, 1.32), PI)


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


func _furnish_half() -> void:
	# Corridors stay bare. Of the remaining rooms, every other one stays empty
	# and the rest gets one cluster from the reference set.
	var seen: Dictionary = {}
	var rooms: Array = []
	for cell in _cells:
		if _skip_furnish(cell) or seen.has(cell):
			continue
		var room: Array[Vector2i] = []
		var stack: Array[Vector2i] = [cell]
		seen[cell] = true
		while not stack.is_empty():
			var here: Vector2i = stack.pop_back()
			room.append(here)
			for edge in EDGES:
				if _kind_on(here, edge) != "none":
					continue
				var nxt: Vector2i = here + _delta(edge)
				if _skip_furnish(nxt) or seen.has(nxt) or not _cell_set.has(nxt):
					continue
				seen[nxt] = true
				stack.append(nxt)
		rooms.append(room)
	rooms.sort_custom(_room_before)
	var placed := 0
	for index in rooms.size():
		if index % 2 == 1:
			continue
		_furnish_room(rooms[index], placed)
		placed += 1


func _room_before(a: Array, b: Array) -> bool:
	var aa := _room_min(a)
	var bb := _room_min(b)
	if aa.y == bb.y:
		return aa.x < bb.x
	return aa.y < bb.y


func _room_min(room: Array) -> Vector2i:
	var best: Vector2i = room[0]
	for item in room:
		var here: Vector2i = item
		if here.y < best.y or (here.y == best.y and here.x < best.x):
			best = here
	return best


func _skip_furnish(cell: Vector2i) -> bool:
	if not _cell_set.has(cell) or not _expansion.has(cell):
		return true
	if cell.x == 0 or cell.x == 1 or cell.x == 4:
		return true
	if cell == Vector2i(6, 2) or cell == Vector2i(-6, 50):
		return true
	if cell.x >= 5 and cell.x <= 6 and cell.y >= 40 and cell.y <= 42:
		return true
	if cell.x >= 5 and cell.x <= 7 and cell.y >= 46 and cell.y <= 49:
		return true
	if cell.x >= -6 and cell.x <= -5 and cell.y >= 24 and cell.y <= 26:
		return true
	if cell.x >= 2 and cell.x <= 3 and cell.y >= 32 and cell.y <= 34:
		return true
	if cell.x >= -3 and cell.x <= -2 and cell.y >= 36 and cell.y <= 37:
		return true
	return false


func _kind_on(cell: Vector2i, edge: String) -> String:
	var key := _edge_key(cell, edge)
	var kind := str(_overrides.get(key, ""))
	if kind.is_empty():
		var neighbor := cell + _delta(edge)
		kind = "none" if _cell_set.has(neighbor) else "wall"
	return kind


func _is_solid_edge(kind: String) -> bool:
	return kind == "wall" or kind == "window"


func _furnish_room(room: Array, variant: int) -> void:
	var cell := _anchor_cell(room)
	var pos := _anchor_pos(cell)
	match variant % 6:
		0:
			_office_chair(_geometry, pos, _into_room_yaw(cell))
		1:
			_table(pos)
			_chair(pos + Vector3(0.0, 0.0, 0.7), PI)
			_chair(pos + Vector3(0.7, 0.0, 0.0), -PI * 0.5)
		2:
			_table(pos)
			_crt(_geometry, pos + Vector3(-0.1, 0.78, -0.12), 0.0)
			_keyboard(_geometry, pos + Vector3(-0.05, 0.8, 0.18))
			_tower(_geometry, pos + Vector3(0.85, 0.0, -0.1), 0.0)
			_office_chair(_geometry, pos + Vector3(-0.15, 0.0, 0.75), PI)
		3:
			var edge := _back_wall(cell)
			if edge == "":
				_table(pos)
				_office_chair(_geometry, pos + Vector3(0.0, 0.0, 0.7), PI)
			else:
				_cubicle_against(cell, edge)
		4:
			if room.size() <= 3:
				var corner := _corner_pos(cell)
				var center := Vector3(cell.x * CELL + 2.0, 0.0, cell.y * CELL + 2.0)
				var inward := center - corner
				if inward.length() > 0.01:
					corner += inward.normalized() * 0.4
				_ladder(corner)
			else:
				_folding_chair(pos + Vector3(-0.4, 0.0, 0.15), 0.4)
				_folding_chair(pos + Vector3(0.35, 0.0, -0.2), 2.6)
				_extinguisher(_corner_pos(cell))
		_:
			_table(pos)
			_office_chair(_geometry, pos + Vector3(-0.65, 0.0, 0.1), PI * 0.5)
			_office_chair(_geometry, pos + Vector3(0.65, 0.0, 0.1), -PI * 0.5)


func _anchor_cell(room: Array) -> Vector2i:
	var best: Vector2i = room[0]
	var best_score := -9999
	for item in room:
		var cell: Vector2i = item
		var score := 0
		for edge in EDGES:
			var kind := _kind_on(cell, edge)
			if _is_solid_edge(kind):
				score += 3
			elif kind == "door" or kind == "elevator":
				score -= 5
		if score > best_score:
			best_score = score
			best = cell
		elif score == best_score and (cell.y < best.y or (cell.y == best.y and cell.x < best.x)):
			best = cell
	return best


func _anchor_pos(cell: Vector2i) -> Vector3:
	var pos := Vector3(cell.x * CELL + 2.0, 0.0, cell.y * CELL + 2.0)
	for edge in EDGES:
		if _kind_on(cell, edge) == "door" or _kind_on(cell, edge) == "elevator":
			pos -= _edge_dir(edge) * 0.4
	return pos


func _edge_dir(edge: String) -> Vector3:
	match edge:
		"n":
			return Vector3(0.0, 0.0, 1.0)
		"s":
			return Vector3(0.0, 0.0, -1.0)
		"e":
			return Vector3(1.0, 0.0, 0.0)
		_:
			return Vector3(-1.0, 0.0, 0.0)


func _into_room_yaw(cell: Vector2i) -> float:
	var edge := _back_wall(cell)
	match edge:
		"n":
			return PI
		"s":
			return 0.0
		"e":
			return -PI * 0.5
		"w":
			return PI * 0.5
	return 0.0


func _back_wall(cell: Vector2i) -> String:
	var fallback := ""
	for edge in EDGES:
		if not _is_solid_edge(_kind_on(cell, edge)):
			continue
		if _kind_on(cell, _opposite(edge)) != "door":
			return edge
		fallback = edge
	return fallback


func _cubicle_against(cell: Vector2i, edge: String) -> void:
	var along := 2.0
	if _kind_on(cell, "e") == "door":
		along = 1.5
	elif _kind_on(cell, "w") == "door":
		along = 2.5
	var depth := 2.0
	if _kind_on(cell, "n") == "door":
		depth = 1.5
	elif _kind_on(cell, "s") == "door":
		depth = 2.5
	var pos := Vector3(cell.x * CELL + along, 0.0, cell.y * CELL + depth)
	var yaw := 0.0
	match edge:
		"n":
			pos.z = (cell.y + 1) * CELL - 0.45
			yaw = PI
		"s":
			pos.z = cell.y * CELL + 0.45
			yaw = 0.0
		"e":
			pos.x = (cell.x + 1) * CELL - 0.45
			yaw = -PI * 0.5
		"w":
			pos.x = cell.x * CELL + 0.45
			yaw = PI * 0.5
	_cubicle(pos, yaw)


func _corner_pos(cell: Vector2i) -> Vector3:
	var x := cell.x * CELL + 2.0
	var z := cell.y * CELL + 2.0
	if _is_solid_edge(_kind_on(cell, "w")):
		x = cell.x * CELL + 0.5
	elif _is_solid_edge(_kind_on(cell, "e")):
		x = (cell.x + 1) * CELL - 0.5
	if _is_solid_edge(_kind_on(cell, "s")):
		z = cell.y * CELL + 0.5
	elif _is_solid_edge(_kind_on(cell, "n")):
		z = (cell.y + 1) * CELL - 0.5
	return Vector3(x, 0.0, z)


func _ladder(at: Vector3) -> void:
	# Aluminum A-frame: two sloping sides, rungs, top cap, spreaders, rubber feet.
	var root := Node3D.new()
	root.name = "StepLadder"
	root.position = at
	_geometry.add_child(root)
	var aluminum := _mat(Color(0.8, 0.81, 0.83), 0.22, 0.92)
	var rubber := _mat(Color(0.07, 0.07, 0.08), 0.9)
	var height := 1.85
	var half_w := 0.25
	var foot := 0.46
	var top := 0.13
	for side_sign in [-1.0, 1.0]:
		var side := float(side_sign)
		var z0 := side * foot
		var z1 := side * top
		for x_sign in [-half_w, half_w]:
			var x := float(x_sign)
			_ladder_rail(root, Vector3(x, 0.0, z0), Vector3(x, height, z1), aluminum)
			_bit(root, Vector3(x, 0.02, z0), Vector3(0.05, 0.04, 0.065), rubber)
		for step in range(1, 7):
			var t := float(step) / 7.0
			_bit(root, Vector3(0.0, height * t, lerpf(z0, z1, t)), Vector3(half_w * 2.0 - 0.04, 0.022, 0.04), aluminum)
	_bit(root, Vector3(0.0, height + 0.02, 0.0), Vector3(half_w * 2.0 + 0.08, 0.035, top * 2.0 + 0.1), aluminum)
	var brace_z := lerpf(foot, top, 0.48)
	for brace_x in [-half_w, half_w]:
		_bit(root, Vector3(float(brace_x), height * 0.48, 0.0), Vector3(0.018, 0.018, brace_z * 2.0), aluminum)
	var body := StaticBody3D.new()
	body.position = Vector3(0.0, height * 0.45, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_w * 2.0, height * 0.9, foot * 1.7)
	shape.shape = box
	body.add_child(shape)
	root.add_child(body)


func _ladder_rail(parent: Node3D, a: Vector3, b: Vector3, material: Material) -> void:
	var delta := b - a
	var mesh_node := MeshInstance3D.new()
	mesh_node.position = (a + b) * 0.5
	mesh_node.rotation.x = atan2(delta.z, delta.y)
	var box := BoxMesh.new()
	box.size = Vector3(0.03, delta.length(), 0.02)
	mesh_node.mesh = box
	mesh_node.material_override = material
	parent.add_child(mesh_node)


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
