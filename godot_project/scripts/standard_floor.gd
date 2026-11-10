extends Node3D
## Compact office floor. The layout is not Floor 4. Carpet or concrete, one hall,
## two shafts, two panel rooms, and a locked red EXIT.

const CELL := 4.0
const LIFT := 0.4

const CARPET := preload("res://scenes/modular/carpet_4x4.tscn")
const CONCRETE := preload("res://scenes/modular/concrete_4x4.tscn")
const CEILING := preload("res://scenes/modular/ceiling_4x4.tscn")
const WALL := preload("res://scenes/modular/wall_4x3.tscn")
const WINDOW := preload("res://scenes/modular/window_wall.tscn")
const DOOR := preload("res://scenes/modular/door_frame.tscn")
const PLAYER := preload("res://scenes/player.tscn")
const PANEL := preload("res://scripts/electrical_panel.gd")
const EXIT := preload("res://scripts/locked_exit.gd")
const TABLE := preload("res://models/blendkit/conference.glb")
const CHAIR := preload("res://models/blendkit/office_chair.glb")

@export var floor_id: String = "F05"

var _cells: Dictionary = {}
var _rooms: Dictionary = {}


func _ready() -> void:
	var spec: Dictionary = _spec(floor_id)
	_build(spec)
	FloorTransition.apply_pending_spawn(self)


func _spec(id: String) -> Dictionary:
	if id == "F03":
		return {
			"code": "03",
			"floor": CONCRETE,
			"rooms": {
				"1,0": "downcar", "1,5": "upcar",
				"1,1": "hall", "1,2": "hall", "1,3": "hall", "1,4": "hall",
				"2,4": "panel_up", "0,1": "panel_down",
				"2,2": "office", "3,2": "office", "3,1": "office",
				"0,3": "exit",
			},
			"overrides": {
				"1,4,n": "elevator",
				"1,0,n": "elevator",
				"1,4,e": "door",
				"0,1,e": "door",
				"1,2,e": "door",
				"0,3,e": "door",
				"0,3,w": "exit",
				"3,2,e": "window",
			},
			"down_id": "F03_DOWN",
			"down_caption": "2",
			"down_at": Vector3(6.0, 1.25, 0.4),
			"down_yaw": PI,
			"up_id": "F03_UP",
			"up_caption": "4",
			"up_at": Vector3(6.0, 1.25, 23.6),
			"up_yaw": 0.0,
			"panels": [
				{"id": "F03_UP_PANEL", "at": Vector3(11.6, 1.35, 18.0), "yaw": PI * 0.5},
				{"id": "F03_DOWN_PANEL", "at": Vector3(0.4, 1.35, 6.0), "yaw": -PI * 0.5},
			],
			"continue_at": Vector3(6.0, 0.05, 10.0),
			"continue_yaw": PI,
			"arrivals": {
				"FromF04": {"at": Vector3(6.0, 0.05, 18.0), "yaw": 0.0},
			},
		}
	return {
		"code": "05",
		"floor": CARPET,
		"rooms": {
			"2,0": "downcar", "2,7": "upcar",
			"2,1": "hall", "2,2": "hall", "2,3": "hall", "2,4": "hall", "2,5": "hall", "2,6": "hall",
			"1,1": "panel_down", "3,6": "panel_up",
			"0,3": "office", "0,4": "office", "1,3": "office", "1,4": "office",
			"3,2": "office_b", "3,3": "office_b", "4,2": "office_b", "4,3": "office_b",
			"3,1": "side", "4,1": "side",
			"0,6": "exit", "1,6": "exit",
		},
		"overrides": {
			"2,0,n": "elevator",
			"2,6,n": "elevator",
			"1,1,e": "door",
			"2,6,e": "door",
			"1,4,e": "door",
			"2,3,e": "door",
			"2,1,e": "door",
			"1,6,e": "door",
			"0,6,w": "exit",
			"0,3,w": "window",
			"0,4,w": "window",
		},
		"down_id": "F05_DOWN",
		"down_caption": "4",
		"down_at": Vector3(10.0, 1.25, 0.4),
		"down_yaw": PI,
		"up_id": "F05_UP",
		"up_caption": "6",
		"up_at": Vector3(10.0, 1.25, 31.6),
		"up_yaw": 0.0,
		"panels": [
			{"id": "F05_DOWN_PANEL", "at": Vector3(4.4, 1.35, 6.0), "yaw": -PI * 0.5},
			{"id": "F05_UP_PANEL", "at": Vector3(15.6, 1.35, 26.0), "yaw": PI * 0.5},
		],
		"continue_at": Vector3(10.0, 0.05, 14.0),
		"continue_yaw": PI,
		"arrivals": {
			"FromF04": {"at": Vector3(10.0, 0.05, 6.0), "yaw": PI},
		},
	}


func _build(spec: Dictionary) -> void:
	var rooms: Dictionary = spec["rooms"]
	for key in rooms.keys():
		var cell := _parse_cell(str(key))
		_cells[cell] = true
		_rooms[cell] = str(rooms[key])
		_module(spec["floor"], cell)
		_module(CEILING, cell).position.y += LIFT
		_lamp(cell)
	var seen: Dictionary = {}
	for key in _cells.keys():
		var cell: Vector2i = key
		for edge in ["n", "s", "e", "w"]:
			var id := _canon_key(cell, edge)
			if seen.has(id):
				continue
			seen[id] = true
			var kind := _kind(cell, edge, spec["overrides"])
			match kind:
				"wall":
					_lift(_place(WALL, cell, edge))
				"window":
					_lift(_place(WINDOW, cell, edge))
				"door":
					_place(DOOR, cell, edge)
				"elevator":
					_shaft(cell, edge, str(spec["code"]))
				"exit":
					_exit(cell, edge)
	_call_plate(spec["down_at"], float(spec["down_yaw"]), str(spec["down_id"]), str(spec["down_caption"]))
	_call_plate(spec["up_at"], float(spec["up_yaw"]), str(spec["up_id"]), str(spec["up_caption"]))
	for item in spec["panels"]:
		var info: Dictionary = item
		var panel := PANEL.new()
		panel.panel_id = str(info["id"])
		panel.position = info["at"]
		panel.rotation.y = float(info["yaw"])
		add_child(panel)
	_marker("ContinueSpawn", spec["continue_at"], float(spec["continue_yaw"]))
	var arrivals: Dictionary = spec["arrivals"]
	for marker_name in arrivals.keys():
		var spot: Dictionary = arrivals[marker_name]
		_marker(str(marker_name), spot["at"], float(spot["yaw"]))
	_furnish()
	var player := PLAYER.instantiate() as Node3D
	player.position = spec["continue_at"]
	player.rotation.y = float(spec["continue_yaw"])
	add_child(player)


func _kind(cell: Vector2i, edge: String, overrides: Dictionary) -> String:
	var key := _canon_key(cell, edge)
	if overrides.has(key):
		return str(overrides[key])
	var other := cell + _delta(edge)
	if not _cells.has(other):
		return "wall"
	if str(_rooms[cell]) != str(_rooms[other]):
		return "wall"
	return "none"


func _furnish() -> void:
	var used: Dictionary = {}
	for key in _rooms.keys():
		var room := str(_rooms[key])
		if not room.begins_with("office") or used.has(room):
			continue
		used[room] = true
		var cell: Vector2i = key
		var at := Vector3(cell.x * CELL + 2.0, 0.0, cell.y * CELL + 2.0)
		var table := TABLE.instantiate() as Node3D
		table.position = at
		add_child(table)
		var chair := CHAIR.instantiate() as Node3D
		chair.position = at + Vector3(0.0, 0.0, 1.5)
		chair.rotation.y = PI
		add_child(chair)


func _shaft(cell: Vector2i, edge: String, code: String) -> void:
	var doors := ElevatorDoors.new()
	doors.build(code, -0.12)
	_place_node(doors, cell, edge)
	doors.set_car_here(true)


func _call_plate(at: Vector3, yaw: float, elevator_id: String, caption: String) -> void:
	var plate := ElevatorPanel.new()
	plate.position = at
	plate.rotation.y = yaw
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.62, 0.63, 0.66)
	steel.roughness = 0.35
	steel.metallic = 0.7
	var lamp := StandardMaterial3D.new()
	lamp.emission_enabled = true
	_mesh(plate, Vector3(0.0, 0.0, -0.02), Vector3(0.28, 0.42, 0.04), steel)
	_mesh(plate, Vector3(0.0, 0.04, -0.045), Vector3(0.12, 0.12, 0.015), lamp)
	var label := Label3D.new()
	label.text = caption
	label.position = Vector3(0.0, -0.08, -0.05)
	label.pixel_size = 0.002
	label.font_size = 48
	label.modulate = Color(0.92, 0.93, 0.9)
	label.outline_size = 0
	plate.add_child(label)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.32, 0.5, 0.08)
	shape.shape = box
	shape.position = Vector3(0.0, 0.0, -0.03)
	plate.add_child(shape)
	add_child(plate)
	plate.configure(elevator_id, lamp)


func _exit(cell: Vector2i, edge: String) -> void:
	var sign := EXIT.new()
	sign.position = _inner(cell, edge, 2.0, 0.02)
	sign.rotation.y = _yaw_into(edge)
	add_child(sign)


func _lamp(cell: Vector2i) -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(cell.x * CELL + 2.0, 3.05, cell.y * CELL + 2.0)
	light.omni_range = 9.0
	light.shadow_enabled = false
	if posmod(cell.x + cell.y, 5) == 0:
		light.light_energy = 0.18
		light.light_color = Color(0.45, 0.42, 0.32)
	else:
		light.light_energy = 1.15
		light.light_color = Color(0.92, 0.9, 0.82)
	add_child(light)


func _marker(marker_name: String, at: Vector3, yaw: float) -> void:
	var marker := Node3D.new()
	marker.name = marker_name
	marker.position = at
	marker.rotation.y = yaw
	add_child(marker)


func _module(packed: PackedScene, cell: Vector2i) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = Vector3(cell.x * CELL, 0.0, cell.y * CELL)
	add_child(node)
	return node


func _place(packed: PackedScene, cell: Vector2i, edge: String) -> Node3D:
	var node := packed.instantiate() as Node3D
	_place_node(node, cell, edge)
	return node


func _place_node(node: Node3D, cell: Vector2i, edge: String) -> void:
	var owner := cell
	var side := edge
	var other := cell + _delta(edge)
	if _cells.has(other) and (other.x < cell.x or (other.x == cell.x and other.y < cell.y)):
		owner = other
		side = _opposite(edge)
	var pos := Vector3(owner.x * CELL, 0.0, owner.y * CELL)
	var rot := 0.0
	match side:
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
	add_child(node)


func _lift(node: Node3D) -> void:
	node.scale.y = (3.0 + LIFT) / 3.0


func _inner(cell: Vector2i, edge: String, along: float, inset: float) -> Vector3:
	var origin := Vector3(cell.x * CELL, 0.0, cell.y * CELL)
	var face := 0.1 + inset
	match edge:
		"n":
			return origin + Vector3(along, 0.0, CELL - face)
		"s":
			return origin + Vector3(along, 0.0, face)
		"e":
			return origin + Vector3(CELL - face, 0.0, along)
		_:
			return origin + Vector3(face, 0.0, along)


func _yaw_into(edge: String) -> float:
	match edge:
		"n":
			return 0.0
		"s":
			return PI
		"e":
			return PI * 0.5
		_:
			return -PI * 0.5


func _mesh(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = material
	parent.add_child(mesh)


func _canon_key(cell: Vector2i, edge: String) -> String:
	var owner := cell
	var side := edge
	var other := cell + _delta(edge)
	if other.x < cell.x or (other.x == cell.x and other.y < cell.y):
		owner = other
		side = _opposite(edge)
	return "%d,%d,%s" % [owner.x, owner.y, side]


func _parse_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func _delta(edge: String) -> Vector2i:
	match edge:
		"n":
			return Vector2i(0, 1)
		"s":
			return Vector2i(0, -1)
		"e":
			return Vector2i(1, 0)
		_:
			return Vector2i(-1, 0)


func _opposite(edge: String) -> String:
	match edge:
		"n":
			return "s"
		"s":
			return "n"
		"e":
			return "w"
		_:
			return "e"
