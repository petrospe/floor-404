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
const CABIN := preload("res://scripts/elevator_cabin.gd")
const PANEL := preload("res://scripts/electrical_panel.gd")
const EXIT := preload("res://scripts/locked_exit.gd")
const TABLE := preload("res://models/blendkit/conference.glb")
const CHAIR := preload("res://models/blendkit/office_chair.glb")
const SWIVEL := preload("res://models/blendkit/swivel_chair.glb")
const FRIDGE := preload("res://models/blendkit/fridge.glb")
const COOLER := preload("res://models/blendkit/cooler.glb")
const CRT := preload("res://models/blendkit/crt.glb")
const SHELF := preload("res://models/blendkit/shelf.glb")
const CABINET := preload("res://models/blendkit/cabinet.glb")
const RACK := preload("res://models/blendkit/server_rack.glb")
const LADDER := preload("res://models/blendkit/ladder.glb")
const PLANT := preload("res://models/blendkit/plant.glb")
const EXTINGUISHER := preload("res://models/blendkit/extinguisher.glb")
const COPIER := preload("res://models/blendkit/copier.glb")
const TOILET_MODEL := preload("res://models/blendkit/toilet.glb")
const SINK := preload("res://models/blendkit/sink.glb")
const MIRROR := preload("res://models/blendkit/mirror.glb")
const BATHROOM_SIGN := preload("res://models/blendkit/bathroom_sign.glb")
const TILE_TEX := preload("res://models/blendkit/white_tiles.jpg")
const DOOR_SCRIPT := preload("res://scripts/door.gd")
const BIN := preload("res://models/blendkit/pedal_bin.glb")
const CONTROL_PANEL := preload("res://models/blendkit/electrical_control_panel.glb")
const WALL_PANEL := preload("res://models/blendkit/electrical_wall_panel.glb")
const CABINET_LINK := preload("res://scripts/cabinet_panel_link.gd")

@export var floor_id: String = "F05"

var _cells: Dictionary = {}
var _rooms: Dictionary = {}
var _car_doors: Dictionary = {}
var _door_frames: Dictionary = {}
var _wall_paint: StandardMaterial3D
var _flicker_lights: Array[OmniLight3D] = []
var _flicker_energy: Array[float] = []


func _ready() -> void:
	var spec: Dictionary = _spec(floor_id)
	_build(spec)
	FloorTransition.apply_pending_spawn(self)


func _process(_delta: float) -> void:
	if _flicker_lights.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	for i in _flicker_lights.size():
		var wave := sin(t * 17.0 + float(i) * 2.3) + sin(t * 5.5 + float(i) * 0.7)
		var factor := 1.0
		if wave < -1.15:
			factor = 0.08
		elif wave < -0.35:
			factor = 0.4
		_flicker_lights[i].light_energy = _flicker_energy[i] * factor


func _spec(id: String) -> Dictionary:
	if id == "F03":
		# Concrete service floor. The hall is a cross, not Floor 4 or Floor 5.
		# Down car is southwest, up car is northeast. Both panel rooms open onto the hall.
		# Override keys are canonical: a west edge is stored on the cell to its west as "e",
		# and a south edge is stored on the cell to its south as "n".
		return {
			"code": "03",
			"cold": true,
			"floor": CONCRETE,
			"carpet_rooms": ["office_w", "office_e", "meeting", "break"],
			"rooms": {
				"1,0": "downcar",
				"0,1": "panel_down",
				"1,1": "hall", "2,1": "hall", "3,1": "hall",
				"1,2": "toilet",
				"3,2": "hall", "4,2": "storage", "5,2": "storage",
				"1,3": "break", "2,3": "break",
				"3,3": "hall", "4,3": "meeting", "5,3": "meeting", "6,3": "meeting",
				"0,4": "exit_w",
				"1,4": "hall", "2,4": "hall", "3,4": "hall", "4,4": "hall", "5,4": "hall",
				"6,4": "exit_e",
				"1,5": "office_w", "2,5": "office_w",
				"3,5": "hall", "4,5": "office_e", "5,5": "office_e",
				"2,6": "panel_up", "3,6": "hall",
				"4,6": "records", "5,6": "records", "6,6": "records",
				"3,7": "upcar",
			},
			"overrides": {
				"1,0,n": "elevator",
				"3,6,n": "elevator",
				"0,1,e": "door",
				"1,1,n": "door",
				"2,3,e": "door",
				"3,2,e": "door",
				"3,3,e": "door",
				"0,4,e": "door",
				"5,4,e": "door",
				"2,5,e": "door",
				"3,5,e": "door",
				"2,6,e": "door",
				"3,6,e": "door",
				"-1,4,e": "exit",
				"6,4,e": "exit",
				"-1,3,e": "window",
				"-1,5,e": "window",
				"1,5,n": "window",
				"2,0,n": "window",
				"3,0,n": "window",
				"6,2,n": "window",
				"6,3,e": "window",
				"4,6,n": "window",
				"5,6,n": "window",
				"6,6,n": "window",
				"6,6,e": "window",
			},
			"cars": [
				{"x": 1, "z": 0, "edge": "n", "id": "F03_DOWN", "lit": 2},
				{"x": 3, "z": 7, "edge": "s", "id": "F03_UP", "lit": 4},
			],
			"panels": [
				{"id": "F03_DOWN_PANEL", "at": Vector3(0.2, 2.22, 6.0), "yaw": -PI * 0.5, "plate": false},
				{"id": "F03_UP_PANEL", "at": Vector3(10.0, 2.22, 27.72), "yaw": 0.0, "plate": false},
			],
			"continue_at": Vector3(14.0, 0.05, 18.0),
			"continue_yaw": -PI * 0.5,
			"arrivals": {
				"FromF04": {"at": Vector3(14.0, 0.05, 25.2), "yaw": 0.0},
				"FromF02": {"at": Vector3(6.0, 0.05, 6.8), "yaw": PI},
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
			"-1,6,e": "exit",
			"-1,3,e": "window",
			"-1,4,e": "window",
		},
		"cars": [
			{"x": 2, "z": 0, "edge": "n", "id": "F05_DOWN", "lit": 4},
			{"x": 2, "z": 7, "edge": "s", "id": "F05_UP", "lit": 6},
		],
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
	if floor_id == "F03":
		_environment(true)
	var carpet_rooms: Array = spec.get("carpet_rooms", [])
	var rooms: Dictionary = spec["rooms"]
	for key in rooms.keys():
		var cell := _parse_cell(str(key))
		var room := str(rooms[key])
		_cells[cell] = true
		_rooms[cell] = room
		var tile: PackedScene = CARPET if carpet_rooms.has(room) else spec["floor"]
		_module(tile, cell)
		_module(CEILING, cell).position.y += LIFT
		_lamp(cell, room)
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
					var door := _place(DOOR, cell, edge)
					_door_frames[_canon_key(cell, edge)] = door
					# The frame stops at 3 m. This band closes the gap up to the raised ceiling.
					_above_opening(door)
				"elevator":
					_shaft(cell, edge, str(spec["code"]))
				"exit":
					_exit(cell, edge)
	for item in spec["cars"]:
		var car: Dictionary = item
		_finish_car(Vector2i(int(car["x"]), int(car["z"])), str(car["edge"]), str(car["id"]), int(car["lit"]))
	for item in spec["panels"]:
		var info: Dictionary = item
		var panel := PANEL.new()
		panel.panel_id = str(info["id"])
		panel.show_plate = bool(info.get("plate", true))
		panel.position = info["at"]
		panel.rotation.y = float(info["yaw"])
		add_child(panel)
	_marker("ContinueSpawn", spec["continue_at"], float(spec["continue_yaw"]))
	var arrivals: Dictionary = spec["arrivals"]
	for marker_name in arrivals.keys():
		var spot: Dictionary = arrivals[marker_name]
		_marker(str(marker_name), spot["at"], float(spot["yaw"]))
	if floor_id == "F03":
		_furnish_three()
	else:
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


func _furnish_three() -> void:
	# Break room. The door is the east wall, so the counter stays on the south wall.
	_prop(FRIDGE, Vector3(8.4, 0.0, 12.55), _face_into("s"), 1.9, 1.05)
	_prop(COOLER, Vector3(9.7, 0.0, 12.55), _face_into("s"), 1.6, 0.7)
	var break_table := _prop(TABLE, Vector3(7.2, 0.0, 14.15), 0.0, 0.78, 1.7)
	_prop(SWIVEL, Vector3(5.55, 0.0, 14.15), _face_into("e"), 1.05, 0.7)
	_prop(CHAIR, Vector3(8.85, 0.0, 14.15), _face_into("w"), 1.15, 0.75)
	_on_table(CRT, break_table, Vector3(0.0, 0.0, 0.05), PI * 0.5, 0.42, 0.55)
	# Meeting room is one cell deep. The table runs along the long axis, clear of the west door.
	var meeting := _prop(TABLE, Vector3(22.0, 0.0, 14.05), PI * 0.5, 0.78, 2.6)
	_prop(SWIVEL, Vector3(20.7, 0.0, 14.05), _face_into("e"), 1.05, 0.7)
	_prop(SWIVEL, Vector3(23.3, 0.0, 14.05), _face_into("w"), 1.05, 0.7)
	_prop(CHAIR, Vector3(22.0, 0.0, 12.85), PI, 1.15, 0.75)
	_on_table(CRT, meeting, Vector3(0.0, 0.0, 0.15), PI, 0.42, 0.55)
	# West office, desks on the window wall. The door is the east edge of x=12.
	var desk_a := _prop(TABLE, Vector3(5.15, 0.0, 21.15), _face_into("w"), 0.78, 1.6)
	var desk_b := _prop(TABLE, Vector3(5.15, 0.0, 22.85), _face_into("w"), 0.78, 1.6)
	_prop(CHAIR, Vector3(6.45, 0.0, 21.15), _face_into("w"), 1.15, 0.75)
	_prop(CHAIR, Vector3(6.45, 0.0, 22.85), _face_into("w"), 1.15, 0.75)
	# The CRT picture is the model's +Z face. This yaw turns it toward the chair.
	_on_table(CRT, desk_a, Vector3(-0.05, 0.0, 0.0), PI * 0.5, 0.42, 0.55)
	_on_table(CRT, desk_b, Vector3(-0.05, 0.0, 0.0), PI * 0.5, 0.42, 0.55)
	# East office. Door is the west edge, desks sit on the far wall.
	var desk_c := _prop(TABLE, Vector3(22.85, 0.0, 21.15), _face_into("e"), 0.78, 1.6)
	var desk_d := _prop(TABLE, Vector3(22.85, 0.0, 22.85), _face_into("e"), 0.78, 1.6)
	_prop(CHAIR, Vector3(21.55, 0.0, 21.15), _face_into("e"), 1.15, 0.75)
	_prop(CHAIR, Vector3(21.55, 0.0, 22.85), _face_into("e"), 1.15, 0.75)
	_on_table(CRT, desk_c, Vector3(0.05, 0.0, 0.0), -PI * 0.5, 0.42, 0.55)
	_on_table(CRT, desk_d, Vector3(0.05, 0.0, 0.0), -PI * 0.5, 0.42, 0.55)
	# Storage. The door is the west edge at z=10, so the aisle stays open there.
	_prop(SHELF, Vector3(23.35, 0.0, 10.7), _face_into("e"), 2.0, 1.15)
	_prop(CABINET, Vector3(21.6, 0.0, 8.55), _face_into("s"), 1.35, 0.7)
	_prop(COPIER, Vector3(18.3, 0.0, 8.7), _face_into("s"), 1.15, 0.9)
	_prop(LADDER, Vector3(18.4, 0.0, 11.25), 0.4, 2.15, 0.7)
	# Records. Rack faces are local +Z. Yaw PI turns that face south, into the room.
	_prop(RACK, Vector3(18.7, 0.0, 27.45), PI, 2.15, 2.4)
	_prop(RACK, Vector3(21.7, 0.0, 27.45), PI, 2.15, 2.4)
	_prop(RACK, Vector3(25.4, 0.0, 27.45), PI, 2.15, 2.4)
	var cool := OmniLight3D.new()
	cool.position = Vector3(22.0, 2.55, 26.2)
	cool.light_color = Color(0.45, 0.65, 0.95)
	cool.light_energy = 0.85
	cool.omni_range = 7.5
	cool.shadow_enabled = false
	add_child(cool)
	# One stall on the far wall, sink and mirror on the side wall, same build as Floor 4.
	_restroom()
	# Down closet: cabinet on the west wall, three wall panels on the north wall.
	_control_cabinet(Vector3(0.14, 0.0, 6.0), PI * 0.5)
	_wall_box(Vector3(0.9, 1.42, 7.88), PI)
	_wall_box(Vector3(2.0, 1.42, 7.88), PI)
	_wall_box(Vector3(3.1, 1.42, 7.88), PI)
	# Up closet: cabinet on the north wall, three wall panels on the west wall.
	_control_cabinet(Vector3(10.0, 0.0, 27.86), PI)
	_wall_box(Vector3(8.14, 1.42, 24.9), PI * 0.5)
	_wall_box(Vector3(8.14, 1.42, 26.0), PI * 0.5)
	_wall_box(Vector3(8.14, 1.42, 27.1), PI * 0.5)
	# Hall corners only. The cross itself stays empty.
	_prop(PLANT, Vector3(9.15, 0.0, 4.55), 0.0, 1.35, 0.7)
	_prop(EXTINGUISHER, Vector3(13.55, 0.0, 4.4), 0.0, 0.7, 0.35)
	_prop(BIN, Vector3(5.45, 0.0, 19.45), 0.3, 0.55, 0.4)


func _above_opening(node: Node3D) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "AboveOpening"
	var box := BoxMesh.new()
	box.size = Vector3(4.0, LIFT, 0.16)
	mesh_node.mesh = box
	mesh_node.position = Vector3(2.0, 3.0 + LIFT * 0.5, 0.0)
	mesh_node.material_override = _matching_wall_paint()
	node.add_child(mesh_node)


func _matching_wall_paint() -> Material:
	var source := _wall_paint_source()
	if source == null:
		return _flat(Color(0.73, 0.69, 0.6), 0.82)
	var paint := source.duplicate() as StandardMaterial3D
	# Same grain as the 3 m wall, so the strip does not read as a new color.
	paint.uv1_scale = Vector3(1.0, LIFT / 3.0, 1.0)
	return paint


func _wall_paint_source() -> StandardMaterial3D:
	if _wall_paint != null:
		return _wall_paint
	var sample := WALL.instantiate()
	_wall_paint = _find_textured_material(sample)
	sample.free()
	return _wall_paint


func _find_textured_material(node: Node) -> StandardMaterial3D:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var material := mesh_node.get_active_material(surface)
				if material is StandardMaterial3D and (material as StandardMaterial3D).albedo_texture != null:
					return material as StandardMaterial3D
	for child in node.get_children():
		var found := _find_textured_material(child)
		if found != null:
			return found
	return null


func _restroom() -> void:
	var cell := Vector2i(1, 2)
	var x0 := 4.0
	var x1 := 8.0
	var z0 := 8.0
	var z1 := 12.0
	_tile_floor(cell)
	# The south bay is the door. Tile the three solid walls.
	_tile_wall(cell, "n", false)
	_tile_wall(cell, "e", true)
	_tile_wall(cell, "w", true)
	# Stall centered on the north wall, clear of the south door.
	_toilet_stall("n", x0, x1, z0, z1, 6.0, 1.2)
	# Sink sits in the open half of the east wall, with the mirror above it.
	_sink_one("e", x0, x1, z0, z1, 9.4)
	_wc_symbol(Vector2i(1, 1), "n", "HOMEM")


func _toilet_stall(edge: String, x0: float, x1: float, z0: float, z1: float, along: float, pitch: float) -> void:
	# Same seat scale and wall clearance as the Floor 4 stalls. Back is local -Z.
	var scale := 1.48
	var back := 0.250 * scale
	var front := 0.369 * scale
	var origin_gap := back + 0.06
	var door_from_wall := origin_gap + front + 0.42
	var stall_depth := door_from_wall + 0.08
	var white := _flat(Color(0.95, 0.95, 0.94), 0.4)
	var toilet := TOILET_MODEL.instantiate() as Node3D
	toilet.position = _against(edge, x0, x1, z0, z1, along, origin_gap)
	toilet.rotation.y = _face_into(edge)
	toilet.scale = Vector3(scale, scale, scale)
	add_child(toilet)
	_box_around(toilet)
	_stall_front(edge, x0, x1, z0, z1, along, pitch, door_from_wall, white)
	for side in [-0.5, 0.5]:
		var split: float = along + float(side) * pitch
		var mid := _against(edge, x0, x1, z0, z1, split, 0.06 + stall_depth * 0.5)
		var size := Vector3(stall_depth, 1.92, 0.04) if edge == "e" or edge == "w" else Vector3(0.04, 1.92, stall_depth)
		_solid(Vector3(mid.x, 1.06, mid.z), size, white)


func _stall_front(edge: String, x0: float, x1: float, z0: float, z1: float, along: float, pitch: float, door_from_wall: float, white: Material) -> void:
	var opening := pitch - 0.04
	var door_width := minf(0.78, opening - 0.16)
	var side := (opening - door_width) * 0.5
	var bay0 := along - pitch * 0.5 + 0.02
	# Local +X is the leaf. On a west or north wall that axis runs back along the row.
	var hinge_along := bay0 + side
	if edge == "w" or edge == "n":
		hinge_along = bay0 + side + door_width
	var hinge := _against(edge, x0, x1, z0, z1, hinge_along, door_from_wall)
	_stall_door(hinge, _face_into(edge), door_width, white)
	_stall_fill(edge, x0, x1, z0, z1, bay0 + side * 0.5, side - 0.02, door_from_wall, white)
	var far := bay0 + side + door_width
	_stall_fill(edge, x0, x1, z0, z1, far + side * 0.5, side - 0.02, door_from_wall, white)


func _stall_fill(edge: String, x0: float, x1: float, z0: float, z1: float, along: float, width: float, door_from_wall: float, white: Material) -> void:
	if width < 0.04:
		return
	var at := _against(edge, x0, x1, z0, z1, along, door_from_wall)
	var size := Vector3(0.04, 1.80, width) if edge == "e" or edge == "w" else Vector3(width, 1.80, 0.04)
	_solid(Vector3(at.x, 1.02, at.z), size, white)


func _stall_door(at: Vector3, yaw: float, width: float, white: Material) -> void:
	var handle := _flat(Color(0.74, 0.75, 0.78), 0.28, 0.88)
	var body := AnimatableBody3D.new()
	body.name = "StallDoor"
	body.position = at
	body.rotation.y = yaw
	body.sync_to_physics = true
	body.set_script(DOOR_SCRIPT)
	# Negative swing opens into the room, away from the bowl.
	body.set("open_angle_degrees", -85.0)
	body.set("duration", 0.4)
	var height := 1.80
	var thick := 0.04
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, height, thick)
	mesh_node.mesh = box
	mesh_node.position = Vector3(width * 0.5, 0.12 + height * 0.5, 0.0)
	mesh_node.material_override = white
	body.add_child(mesh_node)
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = box.size
	shape.shape = collision
	shape.position = mesh_node.position
	body.add_child(shape)
	_bit(body, Vector3(width - 0.09, 0.98, thick * 0.5 + 0.012), Vector3(0.11, 0.028, 0.018), handle)
	add_child(body)


func _sink_one(edge: String, x0: float, x1: float, z0: float, z1: float, along: float) -> void:
	var sink := SINK.instantiate() as Node3D
	sink.position = _against(edge, x0, x1, z0, z1, along, 0.30)
	sink.rotation.y = _face_into(edge)
	add_child(sink)
	_box_around(sink)
	var face := _against(edge, x0, x1, z0, z1, along, 0.0)
	var mirror := _wall_hang(MIRROR, face, _face_into(edge), 1.62, 1.6)
	_paint_black_glass(mirror)


func _wall_hang(packed: PackedScene, at: Vector3, yaw: float, lift: float, scale: float) -> Node3D:
	var root := Node3D.new()
	root.name = "WallHang"
	root.position = Vector3(at.x, lift, at.z)
	root.rotation.y = yaw
	add_child(root)
	var node := packed.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	node.scale = Vector3(scale, scale, scale)
	root.add_child(node)
	_box_around(root)
	return root


func _wc_symbol(cell: Vector2i, edge: String, token: String) -> void:
	# The Blendkit set is three plates lying flat. Stand the men's plate on the corridor face.
	var frame := _door_frames.get(_canon_key(cell, edge)) as Node3D
	if frame == null:
		return
	var door := frame.find_child("Door", true, false) as Node3D
	if door == null:
		return
	var room := cell + _delta(edge)
	var corridor := -_edge_dir(edge) if room == Vector2i(1, 2) else _edge_dir(edge)
	var outward := corridor.dot(door.global_transform.basis.z) > 0.0
	var mount := Node3D.new()
	mount.name = "WcSymbol"
	mount.position = Vector3(0.6, 1.52, 0.016 if outward else -0.066)
	mount.rotation.y = 0.0 if outward else PI
	door.add_child(mount)
	var sign := BATHROOM_SIGN.instantiate() as Node3D
	mount.add_child(sign)
	var plate := _find_plate(sign, token)
	if plate == null:
		mount.queue_free()
		return
	_keep_plate(sign, plate)
	_cull_sign_back(plate)
	# Imported plate faces +Y, head toward -Z. This stands it up, face toward +Z.
	sign.rotation.x = PI * 0.5
	var fit := 1.55
	sign.scale = Vector3(fit, fit, fit)
	sign.position = -mount.to_local(plate.global_position)


func _find_plate(root: Node, token: String) -> MeshInstance3D:
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D and str(node.name).to_upper().contains(token):
			return node as MeshInstance3D
		for child in node.get_children():
			pending.append(child)
	return null


func _keep_plate(root: Node, plate: MeshInstance3D) -> void:
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D and node != plate:
			node.visible = false
		for child in node.get_children():
			pending.append(child)


func _cull_sign_back(plate: MeshInstance3D) -> void:
	# The plate is two skins. Local +Z is the readable side; the other skin is mirrored.
	var source := plate.mesh
	if source == null:
		return
	var cleaned := ArrayMesh.new()
	for surface in source.get_surface_count():
		var tool := MeshDataTool.new()
		if tool.create_from_surface(source, surface) != OK:
			continue
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var format: int = source.surface_get_format(surface)
		var has_uv := (format & Mesh.ARRAY_FORMAT_TEX_UV) != 0
		var has_uv2 := (format & Mesh.ARRAY_FORMAT_TEX_UV2) != 0
		var has_tangent := (format & Mesh.ARRAY_FORMAT_TANGENT) != 0
		var has_color := (format & Mesh.ARRAY_FORMAT_COLOR) != 0
		for face in tool.get_face_count():
			if tool.get_face_normal(face).z < 0.5:
				continue
			for corner in 3:
				var idx := tool.get_face_vertex(face, corner)
				builder.set_normal(tool.get_vertex_normal(idx))
				if has_uv:
					builder.set_uv(tool.get_vertex_uv(idx))
				if has_uv2:
					builder.set_uv2(tool.get_vertex_uv2(idx))
				if has_tangent:
					builder.set_tangent(tool.get_vertex_tangent(idx))
				if has_color:
					builder.set_color(tool.get_vertex_color(idx))
				builder.add_vertex(tool.get_vertex(idx))
		var material := plate.get_active_material(surface)
		if material is BaseMaterial3D:
			var front := material.duplicate() as BaseMaterial3D
			front.cull_mode = BaseMaterial3D.CULL_BACK
			builder.set_material(front)
		elif material != null:
			builder.set_material(material)
		builder.commit(cleaned)
	plate.mesh = cleaned


func _tile_floor(cell: Vector2i) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "TileFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.78, 3.78)
	mesh_node.mesh = plane
	mesh_node.position = Vector3(cell.x * CELL + 2.0, 0.02, cell.y * CELL + 2.0)
	mesh_node.material_override = _square_tile_material(0.40, 3.78, 3.78)
	add_child(mesh_node)


func _tile_wall(cell: Vector2i, edge: String, rolled: bool) -> void:
	var face := _inner(cell, edge, 2.0, 0.012)
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "TileWall"
	var plane := PlaneMesh.new()
	# North and south walls run along X. East and west walls stand by rolling the plane.
	if rolled:
		plane.size = Vector2(3.2, CELL)
		mesh_node.rotation.z = PI * 0.5
	else:
		plane.size = Vector2(CELL, 3.2)
		mesh_node.rotation.x = -PI * 0.5
	mesh_node.mesh = plane
	mesh_node.position = Vector3(face.x, 1.6, face.z)
	var span_u := 3.2 if rolled else CELL
	var span_v := CELL if rolled else 3.2
	mesh_node.material_override = _square_tile_material(0.20, span_u, span_v)
	add_child(mesh_node)


func _square_tile_material(tile: float, span_u: float, span_v: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TILE_TEX
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.roughness = 0.34
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(span_u / tile / 10.0, span_v / tile / 10.0, 1.0)
	return mat


func _against(edge: String, x0: float, x1: float, z0: float, z1: float, along: float, gap: float) -> Vector3:
	match edge:
		"e":
			return Vector3(x1 - 0.10 - gap, 0.0, along)
		"w":
			return Vector3(x0 + 0.10 + gap, 0.0, along)
		"s":
			return Vector3(along, 0.0, z0 + 0.10 + gap)
		_:
			return Vector3(along, 0.0, z1 - 0.10 - gap)


func _solid(origin: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
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
	add_child(body)


func _bit(parent: Node3D, origin: Vector3, size: Vector3, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.position = origin
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _paint_black_glass(root: Node3D) -> void:
	var glass := _flat(Color(0.012, 0.012, 0.014), 0.07, 0.62)
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = glass
		for child in node.get_children():
			pending.append(child)


func _flat(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _edge_dir(edge: String) -> Vector3:
	var step := _delta(edge)
	return Vector3(step.x, 0.0, step.y)


func _shaft(cell: Vector2i, edge: String, code: String) -> void:
	var doors := ElevatorDoors.new()
	doors.build(code, _outside_z(cell, edge))
	_place_node(doors, cell, edge)
	doors.set_car_here(true)
	_car_doors[_car_beside(cell, edge)] = doors


func _finish_car(cell: Vector2i, edge: String, elevator_id: String, lit_floor: int) -> void:
	var center := Vector3(float(cell.x) * CELL + 2.0, 0.0, float(cell.y) * CELL + 2.0)
	var door_dir := Vector3(_delta(edge).x, 0.0, _delta(edge).y)
	var doors := _car_doors.get(cell) as ElevatorDoors
	if doors != null:
		doors.set_car_bounds(center)
	else:
		push_error("Floor 404 elevator %s has no shaft" % elevator_id)
	var panel := CABIN.install(self, center, door_dir, lit_floor, elevator_id)
	panel.home_doors = doors


func _exit(cell: Vector2i, edge: String) -> void:
	# The red leaf does not span the 4 m bay. The wall behind it seals the gaps.
	_lift(_place(WALL, cell, edge))
	var sign := EXIT.new()
	sign.position = _inner(cell, edge, 2.0, 0.08)
	# LockedExit text reads from the node's +Z, so +Z points back into the room.
	sign.rotation.y = _yaw_into(edge) + PI
	add_child(sign)


func _lamp(cell: Vector2i, room: String) -> void:
	if room.ends_with("car"):
		return
	var light := OmniLight3D.new()
	light.position = Vector3(cell.x * CELL + 2.0, 3.05, cell.y * CELL + 2.0)
	light.omni_range = 8.5
	light.shadow_enabled = false
	if floor_id != "F03":
		light.omni_range = 9.0
		if posmod(cell.x + cell.y, 5) == 0:
			light.light_energy = 0.18
			light.light_color = Color(0.45, 0.42, 0.32)
		else:
			light.light_energy = 1.15
			light.light_color = Color(0.92, 0.9, 0.82)
		add_child(light)
		return
	light.light_color = Color(0.92, 0.9, 0.82)
	light.light_energy = 1.05
	if room == "hall":
		light.light_color = Color(0.78, 0.84, 0.9)
		light.light_energy = 1.25
	elif room == "storage" or room == "records":
		light.light_color = Color(0.55, 0.68, 0.78)
		light.light_energy = 0.28
		_flicker_lights.append(light)
		_flicker_energy.append(light.light_energy)
	elif room.begins_with("exit"):
		light.light_color = Color(0.55, 0.28, 0.24)
		light.light_energy = 0.32
	elif room.begins_with("panel"):
		light.light_energy = 0.7
	add_child(light)


func _environment(cold: bool) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.016) if cold else Color(0.012, 0.013, 0.015)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.42) if cold else Color(0.42, 0.4, 0.36)
	env.ambient_light_energy = 0.1
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_strength = 0.9
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.028, 0.032, 0.038)
	env.fog_density = 0.011
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


func _outside_z(cell: Vector2i, edge: String) -> float:
	# Door local +Z follows the placed edge. The call button belongs in the hall.
	var owner := cell
	var side := edge
	var other := cell + _delta(edge)
	if _cells.has(other) and (other.x < cell.x or (other.x == cell.x and other.y < cell.y)):
		owner = other
		side = _opposite(edge)
	var ahead := owner + _delta(side)
	var into_car := str(_rooms.get(ahead, "")).ends_with("car")
	return -0.12 if into_car else 0.12


func _car_beside(cell: Vector2i, edge: String) -> Vector2i:
	if str(_rooms.get(cell, "")).ends_with("car"):
		return cell
	var other := cell + _delta(edge)
	if str(_rooms.get(other, "")).ends_with("car"):
		return other
	return cell


func _control_cabinet(at: Vector3, yaw: float) -> void:
	# Same mount as Floor 4: pitch the lying cabinet up, then yaw its face into the room.
	# E on the mesh opens the nearest panel. The mesh itself is not replaced.
	var root := Node3D.new()
	root.name = "PanelCabinet"
	root.set_script(CABINET_LINK)
	root.position = at
	root.rotation.y = yaw
	add_child(root)
	var node := CONTROL_PANEL.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	root.add_child(node)
	_sit_world(node)
	_box_around(root)


func _wall_box(at: Vector3, yaw: float) -> void:
	# This model already stands. Local +Z is the door, so yaw turns that face into the room.
	var node := WALL_PANEL.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	_box_around(node)


func _sit_world(node: Node3D) -> void:
	var box := _world_bounds(node)
	if box.size.y < 0.001:
		return
	node.position.y -= box.position.y


func _world_bounds(node: Node3D) -> AABB:
	var merged := AABB()
	var has := false
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var item: Node = pending.pop_back()
		for child in item.get_children():
			pending.append(child)
		if item is MeshInstance3D and (item as MeshInstance3D).mesh != null:
			var mesh_node := item as MeshInstance3D
			var ab := mesh_node.get_aabb()
			for i in 8:
				var corner := Vector3(
					ab.position.x if (i & 1) == 0 else ab.end.x,
					ab.position.y if (i & 2) == 0 else ab.end.y,
					ab.position.z if (i & 4) == 0 else ab.end.z
				)
				var point := mesh_node.global_transform * corner
				if not has:
					merged = AABB(point, Vector3.ZERO)
					has = true
				else:
					merged = merged.expand(point)
	return merged


func _face_into(edge: String) -> float:
	# Local +Z turns toward the room, matching the Floor 4 wall props.
	match edge:
		"n":
			return PI
		"s":
			return 0.0
		"e":
			return -PI * 0.5
		_:
			return PI * 0.5


func _prop(packed: PackedScene, at: Vector3, yaw: float, max_height: float, max_span: float) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	var box := _local_aabb(node)
	var factor := 1.0
	if max_height > 0.0 and box.size.y > max_height:
		factor = minf(factor, max_height / box.size.y)
	var span := maxf(box.size.x, box.size.z)
	if max_span > 0.0 and span > max_span:
		factor = minf(factor, max_span / span)
	if factor < 0.999:
		node.scale = Vector3.ONE * factor
	_sit(node)
	_box_around(node)
	return node


func _on_table(packed: PackedScene, table: Node3D, local_offset: Vector3, yaw: float, max_height: float, max_span: float) -> void:
	var top := _local_aabb(table)
	var at := table.position + local_offset
	at.y = table.position.y + top.position.y + top.size.y
	var node := packed.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	var box := _local_aabb(node)
	var factor := 1.0
	if max_height > 0.0 and box.size.y > max_height:
		factor = minf(factor, max_height / box.size.y)
	var span := maxf(box.size.x, box.size.z)
	if max_span > 0.0 and span > max_span:
		factor = minf(factor, max_span / span)
	if factor < 0.999:
		node.scale = Vector3.ONE * factor
		box = _local_aabb(node)
	node.position.y = at.y - box.position.y
	_box_around(node)


func _sit(node: Node3D) -> void:
	var box := _local_aabb(node)
	if box.size.y < 0.001:
		return
	node.position.y -= box.position.y


func _box_around(root: Node3D) -> void:
	var box := _local_aabb(root)
	if box.size.length() < 0.001:
		return
	var body := StaticBody3D.new()
	body.position = box.get_center()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)


func _local_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var has := false
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			var ab := mesh_node.get_aabb()
			var to_root := root.global_transform.affine_inverse() * mesh_node.global_transform
			for i in 8:
				var corner := Vector3(
					ab.position.x if (i & 1) == 0 else ab.end.x,
					ab.position.y if (i & 2) == 0 else ab.end.y,
					ab.position.z if (i & 4) == 0 else ab.end.z
				)
				var point := to_root * corner
				if not has:
					merged = AABB(point, Vector3.ZERO)
					has = true
				else:
					merged = merged.expand(point)
	return merged


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
