extends Node3D
## Walkable floor of Floor 404. The original rooms stay at the south end, and a
## larger wing of offices, a stairwell, and two elevators continues north.
## Modules are 4 m on a side. The shell is lifted a little above the 3 m kit so a
## 1.70 m player has the ceiling just overhead. The player starts in the corridor.

const CELL := 4.0
const CEILING_LIFT := 0.4
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
const BK_OFFICE_CHAIR := preload("res://models/blendkit/office_chair.glb")
const BK_SWIVEL := preload("res://models/blendkit/swivel_chair.glb")
const BK_WOOD_CHAIR := preload("res://models/blendkit/wooden_chair.glb")
const BK_FOLD_CHAIR := preload("res://models/blendkit/folding_chair.glb")
const BK_TABLE := preload("res://models/blendkit/conference.glb")
const BK_WORKPLACE := preload("res://models/blendkit/office_workplace.glb")
const BK_CRT := preload("res://models/blendkit/crt.glb")
const BK_KEYBOARD := preload("res://models/blendkit/keyboard.glb")
const BK_TOWER := preload("res://models/blendkit/tower.glb")
const BK_COOLER := preload("res://models/blendkit/cooler.glb")
const BK_FRIDGE := preload("res://models/blendkit/fridge.glb")
const BK_EXTINGUISHER := preload("res://models/blendkit/extinguisher.glb")
const BK_LADDER := preload("res://models/blendkit/ladder.glb")
const BK_PLANT := preload("res://models/blendkit/plant.glb")
const BK_TREE := preload("res://models/blendkit/tree.glb")
const BK_SHELF := preload("res://models/blendkit/shelf.glb")
const BK_COPIER := preload("res://models/blendkit/copier.glb")
const BK_CABINET := preload("res://models/blendkit/cabinet.glb")
const BK_CAMERA := preload("res://models/blendkit/camera.glb")
const BK_RACK := preload("res://models/blendkit/server_rack.glb")
const BK_PAPER_BIN := preload("res://models/blendkit/paper_bin.glb")
const BK_PEDAL_BIN := preload("res://models/blendkit/pedal_bin.glb")
const BK_PENCIL := preload("res://models/blendkit/pencil_cup.glb")
const BK_BOOKS := preload("res://models/blendkit/books.glb")
const BK_FOLDER := preload("res://models/blendkit/folder.glb")
const BK_PANEL := preload("res://models/blendkit/panel.glb")
const BK_PANEL_CABINET := preload("res://models/blendkit/panel_cabinet.glb")
const BK_WALL_TV := preload("res://models/blendkit/wall_tv.glb")
const BK_GLASS_BOARD := preload("res://models/blendkit/glass_board.glb")
const BK_WHITEBOARD := preload("res://models/blendkit/whiteboard.glb")
const BK_NOTES := preload("res://models/blendkit/sticky_notes.glb")
const BK_TOILET := preload("res://models/blendkit/toilet.glb")
const BK_SINK := preload("res://models/blendkit/sink.glb")
const BK_MIRROR := preload("res://models/blendkit/mirror.glb")
const BK_BATHROOM_SIGN := preload("res://models/blendkit/bathroom_sign.glb")
const TILE_TEX := preload("res://models/blendkit/white_tiles.jpg")
const ALARM_BEACON := preload("res://scripts/alarm_beacon.gd")
const ELEVATOR_DOORS := preload("res://scripts/elevator_doors.gd")
const ELEVATOR_PANEL := preload("res://scripts/elevator_panel.gd")
const FLOOR_PANEL := preload("res://scripts/electrical_panel.gd")
const CABINET_LINK := preload("res://scripts/cabinet_panel_link.gd")
const FLOOR_EXIT := preload("res://scripts/floor_exit.gd")
const DOOR_SCRIPT := preload("res://scripts/door.gd")
const OVERLAP := preload("res://scripts/overlap_resolver.gd")

var _cells: Array[Vector2i] = []
var _cell_set: Dictionary = {}
var _concrete: Dictionary = {}
var _expansion: Dictionary = {}
var _tall: Dictionary = {}
var _room_style: Dictionary = {}
var _flicker_cells: Dictionary = {}
var _flicker_lights: Array[OmniLight3D] = []
var _flicker_energy: Array[float] = []
var _overrides: Dictionary = {}
var _door_flags: Dictionary = {}
var _door_frames: Dictionary = {}
var _geometry: Node3D
var _prop_index := 0
var _table_serial := 0
var _desk_serial := 0
var _wall_paint: StandardMaterial3D

var _cubicle_mat: StandardMaterial3D
var _cubicle_spots: Array[Dictionary] = []
var _shelf_spots: Array[Dictionary] = []
var _cabinet_spots: Array[Vector3] = []
var _storage_cells: Dictionary = {}
var _workplace_cells: Dictionary = {}
var _crt_spots: Array[Dictionary] = []
var _tower_rects: Array[Rect2] = []
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
	_progression_hooks()


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


func _maybe_flicker(cell: Vector2i, glow: OmniLight3D) -> void:
	if not _flicker_cells.has(cell) or not glow.visible:
		return
	_flicker_lights.append(glow)
	_flicker_energy.append(glow.light_energy)


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
	_mark_door(Vector2i(0, 2), "e")
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
		var style: StringName = _room_style.get(cell, &"")
		if style == &"warm":
			_tint_rough(_add(CARPET, origin), Color(0.4, 0.26, 0.16))
		else:
			var floor_scene: PackedScene = CONCRETE if _concrete.has(cell) or style == &"concrete" else CARPET
			_add(floor_scene, origin)
		var ceiling := _add(CEILING, origin)
		_paint_ceiling(ceiling)
		if _tall.has(cell):
			ceiling.position.y += 2.6
		ceiling.position.y += CEILING_LIFT

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
					var wall := _place_module(WALL, canon_cell, canon_edge)
					_lift_shell(wall)
					_tint_edge(wall, canon_cell, canon_edge)
				"window":
					var window := _place_module(WINDOW, canon_cell, canon_edge)
					_lift_shell(window)
					_tint_edge(window, canon_cell, canon_edge)
				"door":
					var door := _place_door(canon_cell, canon_edge, key)
					_door_frames[key] = door
					_above_opening(door)
					_tint_edge(door, canon_cell, canon_edge)
				"elevator":
					pass
				_:
					pass


func _build_lights() -> void:
	for cell in _cells:
		if _is_elevator_car(cell):
			continue
		var fixture_y := (5.3 if _tall.has(cell) else 2.9) + CEILING_LIFT
		var panel := LIGHT.instantiate() as Node3D
		panel.position = Vector3(cell.x * CELL + 2.0, fixture_y, cell.y * CELL + 2.0)
		_geometry.add_child(panel)
		var glow := panel.get_node(^"Glow") as OmniLight3D
		glow.visible = true
		glow.shadow_enabled = false
		glow.light_color = Color(1.0, 0.97, 0.92)
		if _is_pantry(cell):
			glow.light_color = Color(1.0, 0.95, 0.86)
			glow.light_energy = 2.4
			glow.omni_range = 8.0
			continue
		if _is_restroom(cell):
			glow.light_color = Color(0.94, 0.96, 0.97)
			glow.light_energy = 2.1
			glow.omni_range = 9.0
			continue
		# Half the floor stays dim: a burnt tube, or one that flickers.
		var tone := posmod(cell.x * 5 + cell.y * 3, 4)
		if tone == 0:
			glow.visible = false
			_dim_emissive(panel)
			continue
		if tone == 1:
			glow.light_energy = 1.0
			glow.omni_range = 7.0
			_flicker_lights.append(glow)
			_flicker_energy.append(glow.light_energy)
			continue
		var corridor := _is_corridor_cell(cell) or _region_of(cell) == &"corridor"
		glow.light_energy = 1.65 if corridor else 1.3
		glow.omni_range = 9.5 if corridor else 8.0

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
	_extra_break_rooms()
	_cubicles()
	_columns()
	_place_more_cameras()
	_security_room()
	_stair()
	_stairwell()
	_extra_rooms()
	_server_room()
	_meeting_room()
	_crt_room()
	_build_elevators()
	_furnish_half()
	_scatter_corner_plants()
	_scatter_cabinets()
	_scatter_reference_props()
	_place_extinguishers()
	# East wall of the north corridor, beside the night windows. The old sign here read backwards.
	_alarm_beacon(Vector3(7.9, 2.85, 226.85), -PI * 0.5)
	_electrical_rooms()
	_build_restrooms()
	_place_towers()
	OVERLAP.resolve(get_tree(), Callable(self, "_inside_wall"))


func _break_room() -> void:
	_table(Vector3(10.2, 0.0, 27.5))
	_seat(Vector3(10.2, 0.0, 27.5), "n", 0.0, "wood")
	_table(Vector3(13.4, 0.0, 31.5))
	_seat(Vector3(13.4, 0.0, 31.5), "s", 0.0, "wood")
	# North wall, clear of the east and west doors around z = 30.
	_cooler(Vector3(9.7, 0.0, 35.75), PI)
	_fridge(Vector3(13.6, 0.0, 35.64), PI)
	_counter(Vector3(12.4, 0.0, 24.45))
	_extinguisher(Vector3(15.78, 0.0, 26.2))
	_folding_chair(Vector3(11.4, 0.0, 33.4), 0.4)
	_folding_chair(Vector3(12.5, 0.0, 33.9), -0.3)
	_folding_chair(Vector3(14.6, 0.0, 28.4), 1.2)
	_break_bins(Vector3(11.15, 0.0, 34.55), Vector3(14.85, 0.0, 25.35))
	# North wall, east of the fridge. The notes sit on the board.
	var board := _wall_hang(BK_WHITEBOARD, Vector3(15.15, 0.0, 35.9), PI, 1.84, 1.0)
	_notes_on(board)


func _extra_break_rooms() -> void:
	# West pantry. Counter faces into the room from the east wall.
	_table(Vector3(-8.0, 0.0, 117.2))
	_seat(Vector3(-8.0, 0.0, 117.2), "n", 0.0, "fold")
	_seat(Vector3(-8.0, 0.0, 117.2), "s", 0.0, "fold")
	_counter(Vector3(-4.4, 0.0, 116.5), -PI * 0.5)
	_cooler(Vector3(-5.2, 0.0, 121.2), -PI * 0.5)
	_folding_chair(Vector3(-9.4, 0.0, 119.2), 0.6)
	_break_bins(Vector3(-11.35, 0.0, 114.4), Vector3(-11.15, 0.0, 120.6))
	var west_board := _wall_hang(BK_WHITEBOARD, Vector3(-10.0, 0.0, 123.9), PI, 1.84, 1.0)
	_notes_on(west_board)
	# East pantry. Counter faces into the room from the north wall.
	_table(Vector3(28.2, 0.0, 213.4))
	_seat(Vector3(28.2, 0.0, 213.4), "n", 0.0, "fold")
	_seat(Vector3(28.2, 0.0, 213.4), "w", 0.0, "fold")
	_counter(Vector3(28.0, 0.0, 219.6), PI)
	_cooler(Vector3(30.6, 0.0, 218.4), PI)
	_folding_chair(Vector3(26.4, 0.0, 215.6), 0.8)
	_break_bins(Vector3(31.25, 0.0, 211.4), Vector3(31.05, 0.0, 216.2))
	var east_board := _wall_hang(BK_WHITEBOARD, Vector3(25.2, 0.0, 219.9), PI, 1.84, 1.0)
	_notes_on(east_board)


func _place_more_cameras() -> void:
	var placed := 0
	for cell in _cells:
		if placed >= 11:
			break
		if posmod(cell.x * 5 + cell.y * 2, 13) != 4:
			continue
		if _is_restroom(cell) or cell == Vector2i(6, 2) or cell == Vector2i(-6, 50):
			continue
		var edge := _camera_wall(cell)
		if edge == "":
			continue
		var along := 1.35 if posmod(cell.x, 2) == 0 else 2.65
		_mount_camera(cell, edge, along)
		placed += 1


func _camera_wall(cell: Vector2i) -> String:
	var windowed := ""
	var start := posmod(cell.x + cell.y, 4)
	for i in 4:
		var edge := EDGES[(start + i) % 4]
		var kind := _kind_on(cell, edge)
		if kind == "wall":
			return edge
		if kind == "window" and windowed == "":
			windowed = edge
	return windowed


func _mount_camera(cell: Vector2i, edge: String, along: float) -> void:
	# Back plate on the inner face, top of the housing against the ceiling.
	var at := _on_wall(cell, edge, along)
	at.y = _ceiling_under(cell) - 0.052
	_security_camera(at, _face_into_room(edge))


func _ceiling_under(cell: Vector2i) -> float:
	var y := 2.975 + CEILING_LIFT
	if _tall.has(cell):
		y += 2.6
	return y


func _place_extinguishers() -> void:
	var spots: Array[Vector3] = []
	for cell in _cells:
		var spot := _extinguisher_spot(cell)
		if spot.is_empty():
			continue
		spots.append(spot[0] as Vector3)
	var count := mini(30, spots.size())
	for i in count:
		var index := int(float(i) * float(spots.size()) / float(count))
		_extinguisher(spots[index])


func _extinguisher_spot(cell: Vector2i) -> Array:
	if _is_restroom(cell):
		return []
	var inset := 0.22
	var along := 0.42
	var origin := Vector3(cell.x * CELL, 0.0, cell.y * CELL)
	for edge in EDGES:
		var kind := _kind_on(cell, edge)
		if kind != "wall" and kind != "window":
			continue
		var at := origin
		match edge:
			"w":
				at += Vector3(inset, 0.0, along)
			"e":
				at += Vector3(CELL - inset, 0.0, CELL - along)
			"s":
				at += Vector3(CELL - along, 0.0, inset)
			_:
				at += Vector3(along, 0.0, CELL - inset)
		return [at]
	return []


func _cubicles() -> void:
	for row in range(3):
		for col in range(3):
			_cubicle(Vector3(-1.2 + float(col) * 3.3, 0.0, 43.5 + float(row) * 3.5))


func _columns() -> void:
	for point in [Vector3(-1.0, 0.0, 60.5), Vector3(5.0, 0.0, 60.5), Vector3(-1.0, 0.0, 65.0), Vector3(5.0, 0.0, 65.0)]:
		_prop(COLUMN, point)
	_office_chair(_geometry, Vector3(2.0, 0.0, 62.0), 0.6)


func _security_room() -> void:
	_solid("Desk", Vector3(-14.2, 0.86, 64.5), Vector3(3.4, 0.08, 0.8), _desk_mat)
	_solid("DeskLeg", Vector3(-14.2, 0.42, 64.5), Vector3(3.2, 0.80, 0.08), _metal_mat)
	_office_chair(_geometry, Vector3(-15.0, 0.0, 65.22), PI)
	_office_chair(_geometry, Vector3(-13.2, 0.0, 65.22), PI)
	for i in range(3):
		var x := -15.15 + float(i) * 0.95
		_crt(_geometry, Vector3(x, 0.90, 64.4), 0.0)
	_maybe_pencil(_geometry, Vector3(-13.55, 0.90, 64.62))
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


func _is_elevator_car(cell: Vector2i) -> bool:
	return cell == Vector2i(6, 2) or cell == Vector2i(-6, 50)


func _is_pantry(cell: Vector2i) -> bool:
	if cell.x >= 2 and cell.x <= 3 and cell.y >= 6 and cell.y <= 8:
		return true
	if cell.x >= -3 and cell.x <= -2 and cell.y >= 28 and cell.y <= 30:
		return true
	if cell.x >= 6 and cell.x <= 7 and cell.y >= 52 and cell.y <= 54:
		return true
	return false


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
	_carve_break_rooms()
	_carve_electrical()
	_carve_restrooms()
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
	_mark_perimeter_windows()
	_close_interior_windows()
	# The car sits in these cells. A night window here reads as a window inside the elevator.
	_mark(Vector2i(6, 2), "n", "wall")
	_mark(Vector2i(6, 2), "s", "wall")
	_mark(Vector2i(-6, 50), "w", "wall")
	_assign_room_styles()


func _mark_perimeter_windows() -> void:
	# Pairs of night windows along the outer walls, same module as the office hall.
	for cell in _cells:
		if cell.x >= -6 and cell.x <= -5 and cell.y >= 24 and cell.y <= 26:
			continue
		# Spawn is the south end of the x = 0 corridor. Those walls stay solid.
		if cell.x == 0 and cell.y <= 5:
			continue
		for edge in EDGES:
			if _cell_set.has(cell + _delta(edge)):
				continue
			var kind := _kind_on(cell, edge)
			if kind == "door" or kind == "elevator" or kind == "window":
				continue
			var along := cell.y if edge == "e" or edge == "w" else cell.x
			if posmod(along, 5) > 1:
				continue
			if not _is_outer_edge(cell, edge):
				continue
			_mark(cell, edge, "window")


func _is_outer_edge(cell: Vector2i, edge: String) -> bool:
	var step := _delta(edge)
	var probe := cell + step
	if _cell_set.has(probe):
		return false
	for _i in 48:
		probe += step
		if _cell_set.has(probe):
			return false
	return true


func _close_interior_windows() -> void:
	for cell in _cells:
		for edge in EDGES:
			if _kind_on(cell, edge) != "window":
				continue
			if _is_outer_edge(cell, edge):
				continue
			_mark(cell, edge, "wall")


func _assign_room_styles() -> void:
	var seen: Dictionary = {}
	for cell in _cells:
		if _skip_furnish(cell) or seen.has(cell):
			continue
		var room: Array[Vector2i] = []
		var stack: Array[Vector2i] = [cell]
		seen[cell] = true
		var open_to_plain := false
		while not stack.is_empty():
			var here: Vector2i = stack.pop_back()
			room.append(here)
			for edge in EDGES:
				var nxt: Vector2i = here + _delta(edge)
				if not _cell_set.has(nxt):
					continue
				if _kind_on(here, edge) != "none":
					continue
				if _skip_furnish(nxt):
					open_to_plain = true
					continue
				if seen.has(nxt):
					continue
				seen[nxt] = true
				stack.append(nxt)
		if open_to_plain:
			continue
		var origin := _room_min(room)
		if posmod(origin.x + origin.y * 3, 10) == 0:
			for item in room:
				var lamp_cell: Vector2i = item
				_flicker_cells[lamp_cell] = true
		var band := posmod(origin.x * 3 + origin.y, 7)
		var style := &""
		if band == 0:
			style = &"concrete"
		elif band == 3:
			style = &"warm"
		if style == &"":
			continue
		for item in room:
			var here: Vector2i = item
			_room_style[here] = style
			if style == &"concrete":
				_concrete[here] = true


func _is_corridor_cell(cell: Vector2i) -> bool:
	return _cell_set.has(cell) and (cell.x == 0 or cell.x == 1 or cell.x == 4)


func _lift_shell(node: Node3D) -> void:
	node.scale.y = (3.0 + CEILING_LIFT) / 3.0


func _above_opening(node: Node3D) -> void:
	# The casing stays at the door height. This band only closes the gap up to the ceiling.
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "AboveOpening"
	var box := BoxMesh.new()
	box.size = Vector3(4.0, CEILING_LIFT, 0.16)
	mesh_node.mesh = box
	mesh_node.position = Vector3(2.0, 3.0 + CEILING_LIFT * 0.5, 0.0)
	mesh_node.material_override = _matching_wall_paint()
	node.add_child(mesh_node)


func _matching_wall_paint() -> Material:
	var source := _wall_paint_source()
	if source == null:
		return _mat(Color(0.73, 0.69, 0.6), 0.82)
	var paint := source.duplicate() as StandardMaterial3D
	# Keep the same grain size as the 3 m wall, so the strip does not read as a new color.
	paint.uv1_scale = Vector3(1.0, CEILING_LIFT / 3.0, 1.0)
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


func _tint_edge(node: Node, cell: Vector2i, edge: String) -> void:
	# Paint a wall only when both rooms share the color, so the change shows up past the door.
	var style: StringName = _room_style.get(cell, &"")
	var other: StringName = _room_style.get(cell + _delta(edge), &"")
	if style == &"" or style != other:
		return
	if style == &"concrete":
		_tint_rough(node, Color(0.58, 0.64, 0.7))
	elif style == &"warm":
		_tint_rough(node, Color(0.78, 0.66, 0.48))


func _paint_ceiling(node: Node) -> void:
	# #F5F5DC, the same beige on every tile.
	var beige := Color(0.961, 0.961, 0.863)
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var source := mesh_node.get_active_material(surface)
				if source is StandardMaterial3D:
					var painted := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
					painted.albedo_color = beige
					painted.albedo_texture = null
					painted.emission_enabled = false
					mesh_node.set_surface_override_material(surface, painted)
	for child in node.get_children():
		_paint_ceiling(child)


func _tint_rough(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var source := mesh_node.get_active_material(surface)
				if source is StandardMaterial3D:
					var material := source as StandardMaterial3D
					if material.metallic < 0.45 and material.roughness > 0.4 and not material.emission_enabled:
						var painted := material.duplicate() as StandardMaterial3D
						painted.albedo_color = color
						painted.albedo_texture = null
						mesh_node.set_surface_override_material(surface, painted)
	for child in node.get_children():
		_tint_rough(child, color)


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


func _carve_break_rooms() -> void:
	# West pantry, x -12..-4, z 112..124. The door is the existing opening on (-4, 30).
	for z in [28, 29, 30]:
		_mark(Vector2i(-3, z), "e", "none")
		_mark(Vector2i(-2, z), "e", "wall")
	_mark(Vector2i(-3, 30), "n", "wall")
	_mark(Vector2i(-2, 30), "n", "wall")
	# East pantry, x 24..32, z 208..220. Door from the side corridor.
	_mark_door(Vector2i(5, 53), "e")
	for z in [52, 53, 54]:
		_mark(Vector2i(6, z), "e", "none")
	_mark(Vector2i(6, 54), "n", "wall")
	_mark(Vector2i(7, 54), "n", "wall")


func _carve_electrical() -> void:
	# One cell on floor 5, west of the outer rooms, with a door off cell (5, 22).
	_mark_door(Vector2i(5, 22), "e")
	_mark(Vector2i(6, 21), "n", "wall")
	_mark(Vector2i(6, 22), "n", "wall")
	_mark(Vector2i(6, 22), "e", "wall")


func _carve_restrooms() -> void:
	# Two suites on the east side of the central corridor. Each suite is split
	# into a south room (door off the west corridor) and a north room (door off
	# the east corridor). The cross-walls of the wing already close the ends.
	_mark(Vector2i(2, 21), "n", "wall")
	_mark(Vector2i(3, 21), "n", "wall")
	_mark(Vector2i(2, 45), "n", "wall")
	_mark(Vector2i(3, 45), "n", "wall")


func _is_restroom(cell: Vector2i) -> bool:
	if cell.x < 2 or cell.x > 3:
		return false
	if cell.y >= 20 and cell.y <= 23:
		return true
	return cell.y >= 44 and cell.y <= 47


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
	# Handrail stays 0.90 m above the treads, then turns level along the open edge of the landing.
	var rail_z := z1 + 0.05
	var rail_y := rise + 0.90
	_flight_balustrade(x0 + 0.07, z0, rail_z, count, rise, 1.10, rail_y, rail)
	_flight_balustrade(x1 - 0.07, z0, rail_z, count, rise, 1.10, rail_y, rail)
	_solid("Handrail", Vector3((20.18 + x0 + 0.07) * 0.5, rail_y, rail_z), Vector3(x0 + 0.07 - 20.18, 0.045, 0.04), rail)
	_landing_guard(x1 - 0.07, 27.55, rail_z, rise, rail_y, rail)
	var band_h := 2.6 + CEILING_LIFT
	var band_y := 3.0 + band_h * 0.5
	_solid("WellUpper", Vector3(24.0, band_y, 159.98), Vector3(8.0, band_h, 0.16), beige)
	_solid("WellUpper", Vector3(24.0, band_y, 172.02), Vector3(8.0, band_h, 0.16), beige)
	_solid("WellUpper", Vector3(20.08, band_y, 166.0), Vector3(0.16, band_h, 12.0), beige)
	_solid("WellUpper", Vector3(27.92, band_y, 166.0), Vector3(0.16, band_h, 12.0), beige)


func _flight_balustrade(
	x: float,
	step_z0: float,
	rail_z1: float,
	steps: int,
	rise: float,
	y_rail0: float,
	y_rail1: float,
	material: Material
) -> void:
	var depth := (rail_z1 - 0.05 - step_z0) / float(steps)
	var z_bottom := step_z0 - 0.04
	_newel(x, z_bottom, 0.0, y_rail0 + 0.08, material)
	_newel(x, rail_z1, rise, y_rail1 + 0.08, material)
	for i in range(steps):
		var tread := rise * float(i + 1) / float(steps)
		var front := step_z0 + depth * float(i)
		for k in range(3):
			var z := front + depth * (0.25 + 0.25 * float(k))
			var rail_at := lerpf(y_rail0, y_rail1, (z - z_bottom) / (rail_z1 - z_bottom))
			var height := rail_at - tread
			_decor("Baluster", Vector3(x, tread + height * 0.5, z), Vector3(0.02, height, 0.02), material)
	_sloped_bar(x, z_bottom, y_rail0, rail_z1, y_rail1, material, 0.045)


func _landing_guard(x0: float, x1: float, z: float, floor_y: float, rail_y: float, material: Material) -> void:
	_newel(x1, z, floor_y, rail_y + 0.08, material)
	var span := x1 - x0
	var gaps := maxi(int(span / 0.14), 2)
	for i in range(1, gaps):
		var x := x0 + span * float(i) / float(gaps)
		var height := rail_y - floor_y
		_decor("Baluster", Vector3(x, floor_y + height * 0.5, z), Vector3(0.02, height, 0.02), material)
	_solid("Handrail", Vector3((x0 + x1) * 0.5, rail_y, z), Vector3(span, 0.045, 0.04), material)


func _newel(x: float, z: float, y_base: float, y_top: float, material: Material) -> void:
	var height := y_top - y_base
	_solid("Newel", Vector3(x, y_base + height * 0.5, z), Vector3(0.05, height, 0.05), material)


func _sloped_bar(x: float, z0: float, y0: float, z1: float, y1: float, material: Material, thickness: float = 0.04) -> void:
	_prop_index += 1
	var body := StaticBody3D.new()
	body.name = "Rail_%d" % _prop_index
	var dz := z1 - z0
	var dy := y1 - y0
	body.position = Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
	body.rotation.x = -atan2(dy, dz)
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(thickness, thickness, sqrt(dz * dz + dy * dy))
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
	_seat(Vector3(27.1, 0.0, 102.8), "n", 0.0, "swivel")
	_seat(Vector3(27.1, 0.0, 102.8), "w", 0.0, "swivel")
	_table(Vector3(-14.0, 0.0, 114.0))
	_seat(Vector3(-14.0, 0.0, 114.0), "n", 0.0, "swivel")
	_seat(Vector3(-14.0, 0.0, 114.0), "w", 0.0, "swivel")
	# Bay interior is x 20.1–31.9, z 184.1–199.9. The west door swings to about x 21.1.
	var bay_x: Array[float] = [22.3, 24.6, 26.9, 29.2]
	var bay_z: Array[float] = [184.7, 187.5, 191.6, 194.9, 198.0]
	for z in bay_z:
		for x in bay_x:
			_cubicle(Vector3(x, 0.0, z))


func _build_elevators() -> void:
	var first = ELEVATOR_DOORS.new()
	first.name = "ElevatorA"
	first.build("04", -0.12)
	_place_node(first, Vector2i(5, 2), "e")
	var second = ELEVATOR_DOORS.new()
	second.name = "ElevatorB"
	second.build("05", 0.12)
	_place_node(second, Vector2i(-6, 50), "e")
	first.other_doors = second
	second.other_doors = first
	first.set_car_bounds(Vector3(26.0, 0.0, 10.0))
	second.set_car_bounds(Vector3(-22.0, 0.0, 202.0))
	var at_first := randi() % 2 == 0
	first.set_car_here(at_first)
	second.set_car_here(not at_first)
	var marker_a := _elevator_marker("RideA", Vector3(26.5, 0.05, 10.0), PI * 0.5)
	var marker_b := _elevator_marker("RideB", Vector3(-22.5, 0.05, 202.0), -PI * 0.5)
	_dress_car(Vector3(26.0, 0.0, 10.0), true)
	_dress_car(Vector3(-22.0, 0.0, 202.0), false)
	var panel_a = _elevator_panel(Vector3(27.67, 1.25, 10.35), -1.0, 3, "F04_DOWN")
	var panel_b = _elevator_panel(Vector3(-23.67, 1.25, 202.35), 1.0, 5, "F04_UP")
	panel_a.partner_marker = marker_b
	panel_a.partner_doors = second
	panel_a.home_doors = first
	panel_b.partner_marker = marker_a
	panel_b.partner_doors = first
	panel_b.home_doors = second


func _elevator_marker(label: String, at: Vector3, yaw: float) -> Node3D:
	var marker := Node3D.new()
	marker.name = label
	marker.position = at
	marker.rotation.y = yaw
	_geometry.add_child(marker)
	return marker


func _elevator_panel(at: Vector3, face: float, lit_floor: int, elevator_id: String = ""):
	var panel = ELEVATOR_PANEL.new()
	panel.position = at
	var steel := _mat(Color(0.62, 0.63, 0.66), 0.35, 0.7)
	var button := _mat(Color(0.16, 0.16, 0.17), 0.4, 0.35)
	var lit := _mat(Color(0.35, 0.06, 0.05), 0.35, 0.1, Color(0.85, 0.08, 0.05), 1.4)
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
		label.modulate = Color(0.92, 0.93, 0.9)
		label.outline_size = 0
		panel.add_child(label)
	_geometry.add_child(panel)
	if elevator_id != "":
		panel.configure(elevator_id, lit)
	return panel


func _progression_hooks() -> void:
	_spawn_marker("ContinueSpawn", Vector3(2.0, 0.05, 2.0), PI)
	_spawn_marker("FromF03", Vector3(21.2, 0.05, 10.0), PI * 0.5)
	_spawn_marker("FromF05", Vector3(-18.2, 0.05, 202.0), -PI * 0.5)
	# Small status lamp on the wall, centered above each floor cabinet.
	_floor_panel("F04_DOWN_PANEL", Vector3(-0.12, 2.1, 20.9), PI * 0.5, false)
	_floor_panel("F04_UP_PANEL", Vector3(25.05, 2.1, 88.12), PI, false)
	FloorTransition.apply_pending_spawn(self)


func _spawn_marker(marker_name: String, at: Vector3, yaw: float) -> void:
	var marker := Node3D.new()
	marker.name = marker_name
	marker.position = at
	marker.rotation.y = yaw
	_geometry.add_child(marker)


func _floor_panel(panel_id: String, at: Vector3, yaw: float, plate: bool) -> void:
	var panel := FLOOR_PANEL.new()
	panel.panel_id = panel_id
	panel.show_plate = plate
	panel.position = at
	panel.rotation.y = yaw
	_geometry.add_child(panel)


func _dress_car(center: Vector3, door_on_west: bool) -> void:
	var wood := _mat(Color(0.66, 0.54, 0.38), 0.58)
	var tile := _mat(Color(0.82, 0.82, 0.8), 0.35, 0.08)
	_decor("CarFloor", center + Vector3(0.0, 0.02, 0.0), Vector3(3.5, 0.04, 3.5), tile)
	_decor("CarSide", center + Vector3(0.0, 1.2, 1.72), Vector3(3.2, 2.35, 0.06), wood)
	_decor("CarSide", center + Vector3(0.0, 1.2, -1.72), Vector3(3.2, 2.35, 0.06), wood)
	var back := 1.72 if door_on_west else -1.72
	_decor("CarBack", center + Vector3(back, 1.2, 0.0), Vector3(0.06, 2.35, 3.2), wood)
	var lamp := OmniLight3D.new()
	lamp.position = center + Vector3(0.0, 3.2, 0.0)
	lamp.light_color = Color(0.95, 0.94, 0.88)
	lamp.light_energy = 1.6
	lamp.omni_range = 5.0
	lamp.shadow_enabled = false
	_geometry.add_child(lamp)
	_decor("CarLamp", lamp.position, Vector3(0.9, 0.04, 0.28), _mat(Color(0.9, 0.9, 0.86), 0.4, 0.0, Color(0.95, 0.93, 0.85), 3.0))


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
	_bk(BK_COOLER, _geometry, at, yaw)
	return
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
	_bk(BK_FRIDGE, _geometry, at, yaw)
	return
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


func _counter(at: Vector3, yaw: float = 0.0) -> void:
	var root := Node3D.new()
	root.name = "Counter"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var cabinet := _mat(Color(0.93, 0.93, 0.9), 0.48)
	var seam := _mat(Color(0.22, 0.22, 0.23), 0.55)
	var top := _mat(Color(0.1, 0.1, 0.11), 0.32, 0.08)
	_part(root, Vector3(0.0, 0.42, 0.0), Vector3(3.2, 0.82, 0.56), cabinet)
	_part(root, Vector3(0.0, 0.86, 0.0), Vector3(3.36, 0.045, 0.64), top)
	for i in 4:
		var x := -1.2 + float(i) * 0.8
		_bit(root, Vector3(x, 0.42, 0.292), Vector3(0.018, 0.72, 0.012), seam)
		_bit(root, Vector3(x + 0.22, 0.55, 0.3), Vector3(0.08, 0.016, 0.012), seam)


func _extinguisher(at: Vector3) -> void:
	_bk(BK_EXTINGUISHER, _geometry, at, 0.0)
	return
	var root := Node3D.new()
	_prop_index += 1
	root.name = "Extinguisher%d" % _prop_index
	root.position = at
	_geometry.add_child(root)
	var red := _mat(Color(0.7, 0.08, 0.06), 0.4, 0.1)
	_cylinder(root, Vector3(0.0, 0.38, 0.0), 0.09, 0.09, 0.55, red)
	_cylinder(root, Vector3(0.0, 0.7, 0.0), 0.04, 0.04, 0.1, _metal_mat)
	_bit(root, Vector3(0.08, 0.62, 0.0), Vector3(0.08, 0.02, 0.02), _metal_mat)


func _folding_chair(at: Vector3, yaw: float) -> void:
	if _chair_hits_wall(at, yaw, 0.28, 0.25):
		return
	var node := _bk(BK_FOLD_CHAIR, _geometry, at, yaw)
	node.add_to_group("overlap_movable")
	return
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
	_bk(BK_CRT, parent, at, yaw, 0.42)
	var world_at := at
	var world_yaw := yaw
	if parent != _geometry:
		world_at = parent.to_global(at)
		world_yaw += parent.global_rotation.y
	_crt_spots.append({"at": world_at, "yaw": world_yaw})
	return
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
	_bk(BK_KEYBOARD, parent, at, 0.0)


func _tower(parent: Node3D, at: Vector3, yaw: float) -> Node3D:
	var node := _bk(BK_TOWER, parent, at, yaw)
	node.add_to_group("overlap_fixed")
	return node


# One tower on the floor under each CRT. The spot stays beside the screen,
# inside the desk footprint, and clear of walls, chairs, and other towers.
func _place_towers() -> void:
	var blocks := _floor_blocks()
	for spot in _crt_spots:
		var at: Vector3 = spot["at"]
		var yaw: float = spot["yaw"]
		_tower_under(at, yaw, blocks)


func _tower_under(crt_at: Vector3, crt_yaw: float, blocks: Array[AABB]) -> void:
	var offsets: Array[Vector3] = [
		Vector3(0.40, 0.0, 0.0),
		Vector3(-0.40, 0.0, 0.0),
		Vector3(0.40, 0.0, 0.30),
		Vector3(-0.40, 0.0, 0.30),
		Vector3(0.0, 0.0, 0.32),
		Vector3(0.40, 0.0, -0.18),
		Vector3(-0.40, 0.0, -0.18),
	]
	var spins: Array[float] = [0.0, 0.0, PI * 0.5, PI * 0.5, PI * 0.5, 0.0, 0.0]
	var co := cos(crt_yaw)
	var si := sin(crt_yaw)
	for i in offsets.size():
		var off := offsets[i]
		var at := Vector3(
			crt_at.x + off.x * co + off.z * si,
			0.0,
			crt_at.z - off.x * si + off.z * co
		)
		var yaw := crt_yaw + spins[i]
		var foot := _tower_foot(at, yaw)
		if not _tower_fits(foot, crt_at, blocks):
			continue
		_tower(_geometry, at, yaw)
		_tower_rects.append(foot.grow(0.04))
		return


func _tower_foot(at: Vector3, yaw: float) -> Rect2:
	var c := absf(cos(yaw))
	var s := absf(sin(yaw))
	var hx := 0.10 * c + 0.22 * s
	var hz := 0.10 * s + 0.22 * c
	return Rect2(at.x - hx, at.z - hz, hx * 2.0, hz * 2.0)


func _tower_fits(foot: Rect2, crt_at: Vector3, blocks: Array[AABB]) -> bool:
	if _rect_hits_wall(foot):
		return false
	for prev in _tower_rects:
		if foot.intersects(prev):
			return false
	var box := AABB(Vector3(foot.position.x, 0.02, foot.position.y), Vector3(foot.size.x, 0.42, foot.size.y))
	var crt_flat := Vector2(crt_at.x, crt_at.z)
	for block in blocks:
		if not box.intersects(block):
			continue
		var area := block.size.x * block.size.z
		var cover := Rect2(block.position.x, block.position.z, block.size.x, block.size.z)
		if area > 0.75 and cover.has_point(crt_flat):
			continue
		return false
	return true


func _rect_hits_wall(foot: Rect2) -> bool:
	var center := Vector3(foot.get_center().x, 0.0, foot.get_center().y)
	var nx := maxi(1, int(ceil(foot.size.x / 0.12)))
	var nz := maxi(1, int(ceil(foot.size.y / 0.12)))
	for ix in nx + 1:
		for iz in nz + 1:
			var p := Vector3(
				foot.position.x + foot.size.x * float(ix) / float(nx),
				0.0,
				foot.position.y + foot.size.y * float(iz) / float(nz)
			)
			if _segment_hits_wall(center, p):
				return true
	return false


func _floor_blocks() -> Array[AABB]:
	var out: Array[AABB] = []
	var pending: Array[Node] = [_geometry]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				var ab := _mesh_world_aabb(mesh_node)
				var top := ab.position.y + ab.size.y
				if top > 0.08 and ab.position.y < 0.50 and ab.size.x > 0.02 and ab.size.z > 0.02:
					out.append(ab)
		for child in node.get_children():
			pending.append(child)
	return out


func _mesh_world_aabb(mesh_node: MeshInstance3D) -> AABB:
	var ab := mesh_node.get_aabb()
	var xf := mesh_node.global_transform
	var merged := AABB()
	var has := false
	for i in 8:
		var corner := Vector3(
			ab.position.x if (i & 1) == 0 else ab.end.x,
			ab.position.y if (i & 2) == 0 else ab.end.y,
			ab.position.z if (i & 4) == 0 else ab.end.z
		)
		var world: Vector3 = xf * corner
		if not has:
			merged = AABB(world, Vector3.ZERO)
			has = true
		else:
			merged = merged.expand(world)
	return merged


func _swivel_chair(parent: Node3D, at: Vector3, yaw: float) -> void:
	var world_at := at
	var world_yaw := yaw
	if parent != _geometry and parent.is_inside_tree():
		world_at = parent.to_global(at)
		world_yaw += parent.global_rotation.y
	# The source model is 0.72 m tall, with the seat near 0.45 m. These desks
	# are 0.84 m, so the chair is scaled until the backrest clears the top.
	var scale := 1.0 / 0.716
	if _chair_hits_wall(world_at, world_yaw, 0.30 * scale, 0.28 * scale, 0.26 * scale):
		return
	var node := _bk(BK_SWIVEL, parent, at, yaw, 1.0)
	node.add_to_group("overlap_movable")


func _office_chair(parent: Node3D, at: Vector3, yaw: float) -> void:
	var world_at := at
	var world_yaw := yaw
	if parent != _geometry and parent.is_inside_tree():
		world_at = parent.to_global(at)
		world_yaw += parent.global_rotation.y
	if _chair_hits_wall(world_at, world_yaw, 0.82, 0.52, 0.25):
		return
	var node := _bk(BK_OFFICE_CHAIR, parent, at, yaw)
	node.add_to_group("overlap_movable")
	return
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
	# Each Blendkit row is 2.31 m wide and 0.66 m deep, with the faces on local +Z.
	# Five lines pack the west room. The door is the north-east wall, so that bay stays open.
	var xs: Array[float] = [-23.511, -21.705, -21.037, -19.231, -18.563]
	var yaws: Array[float] = [PI * 0.5, -PI * 0.5, PI * 0.5, -PI * 0.5, PI * 0.5]
	var zs: Array[float] = [97.385, 100.025, 102.665]
	for i in xs.size():
		for j in zs.size():
			_bk(BK_RACK, _geometry, Vector3(xs[i], 0.0, zs[j]), yaws[i])
		if i < 2:
			_bk(BK_RACK, _geometry, Vector3(xs[i], 0.0, 105.12), yaws[i])
	var cool := OmniLight3D.new()
	cool.position = Vector3(-22.6, 2.35, 100.0)
	cool.light_color = Color(0.55, 0.7, 0.95)
	cool.light_energy = 1.3
	cool.omni_range = 8.0
	cool.shadow_enabled = false
	_geometry.add_child(cool)
	var cool_east := OmniLight3D.new()
	cool_east.position = Vector3(-19.9, 2.35, 102.0)
	cool_east.light_color = Color(0.55, 0.7, 0.95)
	cool_east.light_energy = 1.2
	cool_east.omni_range = 8.0
	cool_east.shadow_enabled = false
	_geometry.add_child(cool_east)


func _alarm_beacon(at: Vector3, yaw: float) -> void:
	var root := ALARM_BEACON.new() as Node3D
	root.name = "AlarmBeacon"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var mount := _mat(Color(0.08, 0.03, 0.03), 0.4, 0.55)
	var rib := _mat(Color(0.42, 0.01, 0.02), 0.28, 0.1, Color(0.9, 0.02, 0.02), 0.35)
	var lens := _mat(Color(0.95, 0.04, 0.03, 0.42), 0.06, 0.0, Color(1.0, 0.08, 0.03), 1.2)
	lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens.cull_mode = BaseMaterial3D.CULL_DISABLED
	var core := _mat(Color(1.0, 0.62, 0.08), 0.25, 0.0, Color(1.0, 0.42, 0.02), 3.4)
	_beacon_cylinder(root, Vector3(0.0, 0.0, 0.012), 0.082, 0.024, mount)
	_beacon_cylinder(root, Vector3(0.0, 0.0, 0.04), 0.034, 0.032, mount)
	_beacon_cylinder(root, Vector3(0.0, 0.0, 0.115), 0.058, 0.13, lens)
	_beacon_cylinder(root, Vector3(0.0, 0.0, 0.112), 0.03, 0.1, core)
	_beacon_cylinder(root, Vector3(0.0, 0.0, 0.178), 0.05, 0.012, rib)
	for i in 7:
		_beacon_ring(root, Vector3(0.0, 0.0, 0.058 + float(i) * 0.017), rib)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 0.0, 0.16)
	lamp.light_color = Color(1.0, 0.07, 0.04)
	lamp.light_energy = 2.4
	lamp.omni_range = 6.5
	lamp.shadow_enabled = false
	root.add_child(lamp)
	root.set("lamp", lamp)
	root.set("lens", lens)
	root.set("core", core)


func _beacon_cylinder(parent: Node3D, at: Vector3, radius: float, length: float, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = 24
	mesh_node.mesh = cylinder
	mesh_node.material_override = material
	mesh_node.position = at
	mesh_node.rotation.x = PI * 0.5
	parent.add_child(mesh_node)


func _beacon_ring(parent: Node3D, at: Vector3, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.052
	torus.outer_radius = 0.064
	torus.rings = 8
	torus.ring_segments = 16
	mesh_node.mesh = torus
	mesh_node.material_override = material
	mesh_node.position = at
	mesh_node.rotation.x = PI * 0.5
	parent.add_child(mesh_node)


func _meeting_room() -> void:
	var meet := Vector3(12.0, 0.0, 134.0)
	_conference_eight(meet)
	# East wall, screen facing the table. North wall, the glass project board.
	_wall_hang(BK_WALL_TV, Vector3(15.9, 0.0, 134.0), -PI * 0.5, 1.55, 1.0)
	_wall_hang(BK_GLASS_BOARD, Vector3(12.0, 0.0, 139.9), PI, 1.55, 1.5)
	var wash := OmniLight3D.new()
	wash.position = Vector3(12.0, 2.5, 134.0)
	wash.light_color = Color(0.9, 0.92, 0.88)
	wash.light_energy = 1.1
	wash.omni_range = 8.0
	_geometry.add_child(wash)


func _crt_room() -> void:
	var crt_desk := Vector3(-8.0, 0.0, 151.15)
	_table(crt_desk)
	_crt(_geometry, Vector3(-8.0, 0.82, 151.05), PI)
	_keyboard(_geometry, Vector3(-8.05, 0.82, 150.75))
	_maybe_pencil(_geometry, Vector3(-7.35, 0.82, 151.25))
	_printer(_geometry, Vector3(-8.35, 0.82, 151.15))
	_seat(crt_desk, "s", 0.0, "swivel")
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


func _place_door(cell: Vector2i, edge: String, key: String) -> Node3D:
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
	return node


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
	_spawn_table(at)


# The conference top is offset: it runs from local x -0.60 to 1.44 and z -0.54 to 0.62.
# Chair models face +Z, and the front of the seat is at the origin, so the origin sits just outside the top.
func _seat(table: Vector3, side: String, along: float, kind: String, clear: float = 0.32) -> void:
	var at := table
	var yaw := 0.0
	match side:
		"n":
			at += Vector3(0.42 + along, 0.0, 0.64 + clear)
			yaw = PI
		"s":
			at += Vector3(0.42 + along, 0.0, -0.56 - clear)
			yaw = 0.0
		"e":
			at += Vector3(1.46 + clear, 0.0, 0.04 + along)
			yaw = -PI * 0.5
		_:
			at += Vector3(-0.62 - clear, 0.0, 0.04 + along)
			yaw = PI * 0.5
	var reach := 0.82 if kind == "swivel" else 0.36
	var wide := 0.5 if kind == "swivel" else 0.26
	if _chair_hits_wall(at, yaw, reach, wide):
		return
	if kind == "swivel":
		_office_chair(_geometry, at, yaw)
	elif kind == "fold":
		_folding_chair(at, yaw)
	else:
		_chair(at, yaw)


func _spawn_table(at: Vector3) -> void:
	var node := _bk(BK_TABLE, _geometry, at, 0.0)
	_paint_table(node, _table_serial % 3)
	var keep_folder := _table_serial % 2 == 0
	_table_serial += 1
	if not keep_folder:
		return
	var top := _mesh_max_y(node)
	# Laid flat. The spine stays at this point and the cover runs toward -X, inside the top.
	_flat_folder(node, Vector3(0.58, top - node.global_position.y, 0.04))


func _paint_table(root: Node, kind: int) -> void:
	var albedo := Color(0.74, 0.75, 0.77)
	var metal := 0.78
	var rough := 0.28
	if kind == 1:
		albedo = Color(0.43, 0.26, 0.14)
		metal = 0.0
		rough = 0.6
	elif kind == 2:
		albedo = Color(0.07, 0.07, 0.075)
		metal = 0.22
		rough = 0.42
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.material_override is StandardMaterial3D:
				mesh_node.material_override = _table_finish(mesh_node.material_override as StandardMaterial3D, albedo, metal, rough)
			if mesh_node.mesh != null:
				for surface in mesh_node.mesh.get_surface_count():
					var current := mesh_node.get_active_material(surface)
					if current is StandardMaterial3D:
						mesh_node.set_surface_override_material(surface, _table_finish(current as StandardMaterial3D, albedo, metal, rough))
		for child in node.get_children():
			pending.append(child)


func _table_finish(source: StandardMaterial3D, albedo: Color, metal: float, rough: float) -> StandardMaterial3D:
	var copy := source.duplicate() as StandardMaterial3D
	copy.albedo_texture = null
	copy.albedo_color = albedo
	copy.metallic = metal
	copy.roughness = rough
	return copy


func _chair_hits_wall(at: Vector3, yaw: float, reach: float, wide: float, front: float = -1.0) -> bool:
	var nose := reach if front < 0.0 else front
	var co := cos(yaw)
	var si := sin(yaw)
	var locals: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.0, -reach),
		Vector3(0.0, 0.0, nose),
		Vector3(-wide, 0.0, -reach),
		Vector3(wide, 0.0, -reach),
		Vector3(-wide, 0.0, 0.0),
		Vector3(wide, 0.0, 0.0),
	]
	for local in locals:
		var world := at + Vector3(local.x * co + local.z * si, 0.0, -local.x * si + local.z * co)
		# The backrest can pass through a thin wall and land in the next room.
		if _segment_hits_wall(at, world):
			return true
	return false


func _segment_hits_wall(a: Vector3, b: Vector3) -> bool:
	var span := a.distance_to(b)
	var steps := maxi(1, int(ceil(span / 0.12)))
	var prev := Vector2i(int(floor(a.x / CELL)), int(floor(a.z / CELL)))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		if _inside_wall(p):
			return true
		var cell := Vector2i(int(floor(p.x / CELL)), int(floor(p.z / CELL)))
		if cell == prev:
			continue
		var edge := ""
		if cell.x > prev.x:
			edge = "e"
		elif cell.x < prev.x:
			edge = "w"
		elif cell.y > prev.y:
			edge = "n"
		elif cell.y < prev.y:
			edge = "s"
		if edge != "" and _is_solid_edge(_kind_on(prev, edge)):
			return true
		if not _cell_set.has(cell):
			return true
		prev = cell
	return false


func _inside_wall(at: Vector3) -> bool:
	var cell := Vector2i(int(floor(at.x / CELL)), int(floor(at.z / CELL)))
	if not _cell_set.has(cell):
		return true
	var lx := at.x - float(cell.x) * CELL
	var lz := at.z - float(cell.y) * CELL
	var limit := 0.12
	if _is_solid_edge(_kind_on(cell, "w")) and lx < limit:
		return true
	if _is_solid_edge(_kind_on(cell, "e")) and lx > CELL - limit:
		return true
	if _is_solid_edge(_kind_on(cell, "s")) and lz < limit:
		return true
	if _is_solid_edge(_kind_on(cell, "n")) and lz > CELL - limit:
		return true
	return false


func _chair(at: Vector3, yaw: float = 0.0) -> void:
	if _chair_hits_wall(at, yaw, 0.32, 0.22):
		return
	var node := _bk(BK_WOOD_CHAIR, _geometry, at, yaw)
	node.add_to_group("overlap_movable")
	return
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
	_cubicle_spots.append({"x": at.x, "z": at.z, "yaw": yaw})
	# Back, sides, and the desk block the walk. The front of the stall stays open.
	for block in [
		[Vector3(0.0, 0.7, 0.0), Vector3(1.9, 1.4, 0.1)],
		[Vector3(-0.9, 0.76, 0.75), Vector3(0.1, 1.28, 1.52)],
		[Vector3(0.9, 0.76, 0.75), Vector3(0.1, 1.28, 1.52)],
		[Vector3(0.0, 0.42, 0.52), Vector3(1.42, 0.84, 0.7)],
	]:
		var body := StaticBody3D.new()
		body.position = block[0]
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = block[1]
		collision.shape = shape
		body.add_child(collision)
		node.add_child(body)
	_crt(node, Vector3(0.0, 0.84, 0.46), 0.0)
	_keyboard(node, Vector3(0.02, 0.84, 0.7))
	_maybe_pencil(node, Vector3(0.48, 0.84, 0.38))
	# The task chair's origin is the middle of the base. Yaw PI points the seat at the desk.
	# Pulled forward of the 0.84 m top so the larger seat stays clear of it.
	_swivel_chair(node, Vector3(0.0, 0.0, 1.42), PI)


func _prop(packed: PackedScene, at: Vector3) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = at
	_geometry.add_child(node)
	return node


func _bk(packed: PackedScene, parent: Node, at: Vector3, yaw: float, fit_height: float = -1.0) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	parent.add_child(node)
	if fit_height > 0.0:
		var box := _local_aabb(node)
		if box.size.y > 0.001:
			var fitted := fit_height / box.size.y
			node.scale = Vector3(fitted, fitted, fitted)
			node.position.y = at.y - box.position.y * fitted
	_box_around(node)
	if packed == BK_TABLE or packed == BK_SHELF or packed == BK_CABINET or packed == BK_PLANT or packed == BK_TREE:
		node.add_to_group("overlap_fixed")
	return node


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
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
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
		for child in node.get_children():
			pending.append(child)
	return merged


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
	var storage_index := _storage_index(rooms)
	var workplaces := _workplace_picks(rooms, storage_index)
	var placed := 0
	for index in rooms.size():
		if workplaces.has(index):
			var desk_cell: Vector2i = workplaces[index]
			_workplace_cells[desk_cell] = true
			_place_workplace(desk_cell)
			if index % 2 == 0:
				placed += 1
			continue
		if index == storage_index:
			_storage_room(rooms[index])
			if index % 2 == 0:
				placed += 1
			continue
		if index % 2 == 1:
			# A share of the bare rooms becomes an office with a computer.
			# The rest gets a table: conference (photo 25) or a plain table (photo 18).
			if posmod(index, 4) == 1:
				_furnish_room(rooms[index], 2 if posmod(index, 8) == 1 else 3)
			else:
				_furnish_room(rooms[index], 6 if posmod(index, 8) == 3 else 7)
			continue
		_furnish_room(rooms[index], placed)
		placed += 1


func _storage_index(rooms: Array) -> int:
	var best := -1
	var best_size := 99
	for index in rooms.size():
		var room: Array = rooms[index]
		if room.size() > 3 or _room_has_elevator(room) or not _room_has_door(room):
			continue
		var few := posmod(index, 8) == 7 or (index % 2 == 0 and room.size() <= 2)
		if not few:
			continue
		if room.size() < best_size:
			best = index
			best_size = room.size()
	if best >= 0:
		return best
	for index in rooms.size():
		var room: Array = rooms[index]
		if room.size() <= 2 and _room_has_door(room) and not _room_has_elevator(room):
			return index
	return -1


func _room_has_door(room: Array) -> bool:
	return _room_has_kind(room, "door")


func _room_has_elevator(room: Array) -> bool:
	return _room_has_kind(room, "elevator")


func _room_has_kind(room: Array, wanted: String) -> bool:
	for item in room:
		var cell: Vector2i = item
		for edge in EDGES:
			if _kind_on(cell, edge) == wanted:
				return true
	return false


func _storage_room(room: Array) -> void:
	for item in room:
		_storage_cells[item] = true
	if room.size() <= 2:
		for item in room:
			var cell: Vector2i = item
			_fill_storage(cell)
		return
	_fill_storage(_anchor_cell(room))


func _fill_storage(cell: Vector2i) -> void:
	var door := ""
	for edge in EDGES:
		var kind := _kind_on(cell, edge)
		if kind == "door" or kind == "elevator":
			door = edge
			break
	var far := _back_wall(cell)
	if door != "":
		far = _opposite(door)
	for edge in EDGES:
		if edge == door or not _is_solid_edge(_kind_on(cell, edge)):
			continue
		var yaw := _face_into_room(edge)
		if edge == far:
			_metal_shelf(_shelf_against(cell, edge, 1.2), yaw)
			_metal_shelf(_shelf_against(cell, edge, 2.8), yaw)
		else:
			_metal_shelf(_shelf_against(cell, edge, 2.0), yaw)
	if door != "":
		_storage_cabinet(cell, door, 0.7)
		_storage_cabinet(cell, door, 3.3)
	_storage_boxes(cell, door)


func _shelf_against(cell: Vector2i, edge: String, along: float) -> Vector3:
	return _on_wall(cell, edge, along) - _edge_dir(edge) * 0.30


func _storage_cabinet(cell: Vector2i, edge: String, along: float) -> void:
	var at := _on_wall(cell, edge, along) - _edge_dir(edge) * 0.37
	_filing_cabinet(at, _face_into_room(edge))
	_cabinet_spots.append(at)


func _storage_boxes(cell: Vector2i, door: String) -> void:
	var at := Vector3(cell.x * CELL + 2.0, 0.0, cell.y * CELL + 2.0)
	if door != "":
		at -= _edge_dir(door) * 0.45
	_cardboard_box(at + Vector3(-0.55, 0.0, -0.15), Vector3(0.46, 0.34, 0.38))
	_cardboard_box(at + Vector3(-0.55, 0.34, -0.15), Vector3(0.40, 0.28, 0.32))
	_cardboard_box(at + Vector3(0.48, 0.0, 0.05), Vector3(0.52, 0.38, 0.42))
	_cardboard_box(at + Vector3(-0.02, 0.0, 0.48), Vector3(0.36, 0.30, 0.34))


func _cardboard_box(at: Vector3, size: Vector3) -> void:
	var cardboard := _mat(Color(0.58, 0.42, 0.27), 0.78)
	var body := _solid("Box", at + Vector3(0.0, size.y * 0.5, 0.0), size, cardboard)
	var tape := _mat(Color(0.76, 0.66, 0.42), 0.62)
	_bit(body, Vector3(0.0, size.y * 0.5 + 0.002, 0.0), Vector3(size.x * 0.14, 0.004, size.z * 0.98), tape)
	_bit(body, Vector3(0.0, 0.0, size.z * 0.5 + 0.002), Vector3(size.x * 0.14, size.y * 0.96, 0.004), tape)


func _workplace_picks(rooms: Array, storage_index: int) -> Dictionary:
	var picked: Dictionary = {}
	for limit in [2, 4]:
		if picked.size() >= 7:
			break
		for index in rooms.size():
			if picked.size() >= 7 or index == storage_index or picked.has(index):
				continue
			var room: Array = rooms[index]
			if room.size() > limit or _room_has_elevator(room) or not _room_has_door(room):
				continue
			if not _workplace_room_ok(room):
				continue
			var cell := _workplace_cell(room)
			if not _workplace_fits(cell, room):
				continue
			picked[index] = cell
	return picked


func _workplace_room_ok(room: Array) -> bool:
	for item in room:
		var cell: Vector2i = item
		if _is_restroom(cell) or cell == Vector2i(-1, 5) or cell == Vector2i(6, 22):
			return false
	return true


func _workplace_cell(room: Array) -> Vector2i:
	for item in room:
		var cell: Vector2i = item
		var has_door := false
		for edge in EDGES:
			if _kind_on(cell, edge) == "door":
				has_door = true
				break
		if not has_door:
			return cell
	return room[0]


func _workplace_entry(cell: Vector2i) -> String:
	for edge in EDGES:
		if _kind_on(cell, edge) == "door":
			return edge
	for edge in EDGES:
		if _kind_on(cell, edge) == "none":
			return edge
	return "s"


func _workplace_yaw(entry: String) -> float:
	# Local +Z is the monitor side. A quarter turn counterclockwise from the
	# wall opposite the entrance, so the set sits sideways in the room.
	match entry:
		"s":
			return -PI * 0.5
		"n":
			return PI * 0.5
		"e":
			return PI
		_:
			return 0.0


func _workplace_foot(at: Vector3, yaw: float) -> Rect2:
	var c := absf(cos(yaw))
	var s := absf(sin(yaw))
	var hx := 1.18 * c + 0.84 * s
	var hz := 1.18 * s + 0.84 * c
	return Rect2(at.x - hx, at.z - hz, hx * 2.0, hz * 2.0)


func _workplace_pose(cell: Vector2i) -> Dictionary:
	var entry := _workplace_entry(cell)
	var yaw := _workplace_yaw(entry)
	var at := Vector3(float(cell.x) * CELL + 2.0, 0.0, float(cell.y) * CELL + 2.0)
	at += _edge_dir(_opposite(entry)) * 0.35
	return {"at": at, "yaw": yaw, "foot": _workplace_foot(at, yaw)}


func _workplace_fits(cell: Vector2i, room: Array) -> bool:
	var pose := _workplace_pose(cell)
	var foot: Rect2 = pose["foot"]
	if _rect_hits_wall(foot):
		return false
	var allowed: Dictionary = {}
	for item in room:
		allowed[item] = true
	var points: Array[Vector3] = [
		Vector3(foot.position.x, 0.0, foot.position.y),
		Vector3(foot.position.x + foot.size.x, 0.0, foot.position.y),
		Vector3(foot.position.x, 0.0, foot.position.y + foot.size.y),
		Vector3(foot.position.x + foot.size.x, 0.0, foot.position.y + foot.size.y),
		Vector3(foot.get_center().x, 0.0, foot.get_center().y),
	]
	for point in points:
		var here := Vector2i(int(floor(point.x / CELL)), int(floor(point.z / CELL)))
		if not allowed.has(here):
			return false
	return true


func _place_workplace(cell: Vector2i) -> void:
	var pose := _workplace_pose(cell)
	var node := _bk(BK_WORKPLACE, _geometry, pose["at"], float(pose["yaw"]))
	node.add_to_group("overlap_fixed")


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
	if cell.x >= -3 and cell.x <= -2 and cell.y >= 28 and cell.y <= 30:
		return true
	if cell.x >= 6 and cell.x <= 7 and cell.y >= 52 and cell.y <= 54:
		return true
	if cell == Vector2i(6, 22) or _is_restroom(cell):
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
	if variant == 6:
		_small_conference(pos)
		_conference_wall(cell)
		return
	if variant == 7:
		_table(pos)
		_seat(pos, "n", 0.0, "fold")
		_seat(pos, "s", 0.0, "fold")
		return
	match variant % 6:
		0:
			_office_chair(_geometry, pos, _into_room_yaw(cell))
			_office_chair(_geometry, pos + Vector3(0.75, 0.0, 0.35), _into_room_yaw(cell) + 0.4)
			_folding_chair(pos + Vector3(-0.55, 0.0, 0.4), 0.8)
			_room_shelf(cell)
		1:
			_table(pos)
			_seat(pos, "n", 0.0, "wood")
			_seat(pos, "s", 0.0, "wood")
			_seat(pos, "w", 0.0, "wood")
		2:
			_table(pos)
			_crt(_geometry, pos + Vector3(-0.1, 0.82, -0.12), 0.0)
			_keyboard(_geometry, pos + Vector3(-0.05, 0.82, 0.18))
			_maybe_pencil(_geometry, pos + Vector3(0.55, 0.82, 0.28))
			_seat(pos, "n", 0.0, "swivel")
		3:
			var edge := _back_wall(cell)
			if edge == "":
				_table(pos)
				_seat(pos, "n", 0.0, "swivel")
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
				_room_shelf(cell)
			else:
				_folding_chair(pos + Vector3(-0.4, 0.0, 0.15), 0.4)
				_folding_chair(pos + Vector3(0.35, 0.0, -0.2), 2.6)
				_folding_chair(pos + Vector3(0.1, 0.0, 0.7), 1.4)
				_room_shelf(cell)
				var spot := _extinguisher_spot(cell)
				if not spot.is_empty():
					_extinguisher(spot[0] as Vector3)
		_:
			_table(pos)
			_seat(pos, "n", 0.0, "swivel")
			_seat(pos, "s", 0.0, "swivel")
			_seat(pos, "w", 0.0, "swivel")


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


func _room_shelf(cell: Vector2i) -> void:
	var edge := _back_wall(cell)
	var at := Vector3(cell.x * CELL + 2.0, 0.0, cell.y * CELL + 2.0)
	var yaw := 0.0
	match edge:
		"n":
			at.z = (cell.y + 1) * CELL - 0.4
			yaw = PI
		"s":
			at.z = cell.y * CELL + 0.4
			yaw = 0.0
		"e":
			at.x = (cell.x + 1) * CELL - 0.4
			yaw = -PI * 0.5
		"w":
			at.x = cell.x * CELL + 0.4
			yaw = PI * 0.5
		_:
			at = _corner_pos(cell)
	_metal_shelf(at, yaw)


func _maybe_pencil(parent: Node, at: Vector3) -> void:
	_desk_serial += 1
	if _desk_serial % 10 >= 7:
		return
	_bk(BK_PENCIL, parent, at, 0.15)


func _flat_folder(parent: Node3D, at: Vector3) -> void:
	var node := BK_FOLDER.instantiate() as Node3D
	node.position = at
	node.rotation.z = PI * 0.5
	parent.add_child(node)
	_sit_on_floor(node, parent.global_position.y + at.y)
	_box_around(node)


func _break_bins(paper: Vector3, pedal: Vector3) -> void:
	_bk(BK_PAPER_BIN, _geometry, paper, 0.4)
	_bk(BK_PEDAL_BIN, _geometry, pedal, 1.1)


func _electrical_rooms() -> void:
	# Floor 4 closet, cell (-1, 5). Door is the north wall.
	_metal_shelf(Vector3(-2.5, 0.0, 20.4), 0.0)
	_metal_shelf(Vector3(-3.65, 0.0, 22.3), PI * 0.5)
	_ladder(Vector3(-1.35, 0.0, 21.6))
	_wall_panel(Vector3(-0.14, 1.25, 21.75), -PI * 0.5)
	_wall_panel(Vector3(-0.14, 1.25, 22.45), -PI * 0.5)
	_wall_panel(Vector3(-0.14, 1.25, 23.1), -PI * 0.5)
	# Back of the tall panel on the east wall. Its face points into the room.
	_panel_cabinet(Vector3(-0.12, 0.0, 20.9), -PI * 0.5)
	# Floor 5 cell (6, 22). Door is the west wall.
	_metal_shelf(Vector3(27.6, 0.0, 90.1), -PI * 0.5)
	_metal_shelf(Vector3(26.6, 0.0, 88.5), PI)
	_ladder(Vector3(26.7, 0.0, 89.6))
	_wall_panel(Vector3(25.15, 1.25, 91.86), PI)
	_wall_panel(Vector3(25.9, 1.25, 91.86), PI)
	_wall_panel(Vector3(26.65, 1.25, 91.86), PI)
	# Back on the south wall, face toward the door.
	_panel_cabinet(Vector3(25.05, 0.0, 88.12), 0.0)


func _wall_panel(at: Vector3, yaw: float) -> void:
	_bk(BK_PANEL, _geometry, at, yaw)


# The Blendkit boards and the 60" TV lie flat. Pitch stands them up, back on local z = 0, face toward +Z.
func _wall_hang(packed: PackedScene, at: Vector3, yaw: float, lift: float, scale: float) -> Node3D:
	var root := Node3D.new()
	root.name = "WallHang"
	root.position = Vector3(at.x, lift, at.z)
	root.rotation.y = yaw
	_geometry.add_child(root)
	var node := packed.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	if scale != 1.0:
		node.scale = Vector3(scale, scale, scale)
	root.add_child(node)
	_box_around(root)
	return root


func _notes_on(root: Node3D) -> void:
	var node := BK_NOTES.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	node.scale = Vector3(0.65, 0.65, 0.65)
	# Just in front of the whiteboard face, on the lower right.
	node.position = Vector3(0.32, -0.22, 0.045)
	root.add_child(node)


func _face_into_room(edge: String) -> float:
	match edge:
		"n":
			return PI
		"s":
			return 0.0
		"e":
			return -PI * 0.5
		_:
			return PI * 0.5


func _on_wall(cell: Vector2i, edge: String, along: float) -> Vector3:
	var x0 := cell.x * CELL
	var z0 := cell.y * CELL
	var inset := 0.10
	match edge:
		"n":
			return Vector3(x0 + along, 0.0, z0 + CELL - inset)
		"s":
			return Vector3(x0 + along, 0.0, z0 + inset)
		"e":
			return Vector3(x0 + CELL - inset, 0.0, z0 + along)
		_:
			return Vector3(x0 + inset, 0.0, z0 + along)


func _mount_edge(cell: Vector2i) -> String:
	var back := _back_wall(cell)
	if back != "" and _kind_on(cell, back) == "wall":
		return back
	for edge in EDGES:
		if _kind_on(cell, edge) == "wall":
			return edge
	return back


func _other_wall(cell: Vector2i, skip: String) -> String:
	var window := ""
	for edge in EDGES:
		if edge == skip:
			continue
		var kind := _kind_on(cell, edge)
		if kind == "wall":
			return edge
		if kind == "window" and window == "":
			window = edge
	return window


func _conference_wall(cell: Vector2i) -> void:
	var screen_edge := _mount_edge(cell)
	if screen_edge == "":
		return
	var board_edge := _other_wall(cell, screen_edge)
	if board_edge == "":
		_wall_hang(BK_WALL_TV, _on_wall(cell, screen_edge, 1.15), _face_into_room(screen_edge), 1.55, 1.0)
		_wall_hang(BK_GLASS_BOARD, _on_wall(cell, screen_edge, 3.05), _face_into_room(screen_edge), 1.55, 1.45)
		return
	_wall_hang(BK_WALL_TV, _on_wall(cell, screen_edge, 2.0), _face_into_room(screen_edge), 1.55, 1.0)
	_wall_hang(BK_GLASS_BOARD, _on_wall(cell, board_edge, 2.0), _face_into_room(board_edge), 1.55, 1.45)


func _panel_cabinet(at: Vector3, yaw: float) -> void:
	# Pitch first, then yaw, so the 1.9 m face stands on the floor and turns toward the room.
	# The link only forwards E. Position, yaw, and the imported mesh stay as they were.
	var root := Node3D.new()
	root.name = "PanelCabinet"
	root.set_script(CABINET_LINK)
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var node := BK_PANEL_CABINET.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	root.add_child(node)
	_sit_on_floor(node, at.y)
	_box_around(root)


func _mesh_max_y(node: Node3D) -> float:
	var max_y := -1000.0
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var item: Node = pending.pop_back()
		if item is MeshInstance3D:
			var mesh_node := item as MeshInstance3D
			if mesh_node.mesh != null:
				var ab := mesh_node.get_aabb()
				for i in 8:
					var corner := Vector3(
						ab.position.x if (i & 1) == 0 else ab.end.x,
						ab.position.y if (i & 2) == 0 else ab.end.y,
						ab.position.z if (i & 4) == 0 else ab.end.z
					)
					max_y = maxf(max_y, (mesh_node.global_transform * corner).y)
		for child in item.get_children():
			pending.append(child)
	return max_y


func _sit_on_floor(node: Node3D, floor_y: float) -> void:
	var min_y := 1000.0
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var item: Node = pending.pop_back()
		if item is MeshInstance3D:
			var mesh_node := item as MeshInstance3D
			if mesh_node.mesh != null:
				var ab := mesh_node.get_aabb()
				for i in 8:
					var corner := Vector3(
						ab.position.x if (i & 1) == 0 else ab.end.x,
						ab.position.y if (i & 2) == 0 else ab.end.y,
						ab.position.z if (i & 4) == 0 else ab.end.z
					)
					min_y = minf(min_y, (mesh_node.global_transform * corner).y)
		for child in item.get_children():
			pending.append(child)
	if min_y < 500.0:
		node.position.y += floor_y - min_y


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
	_bk(BK_LADDER, _geometry, at, 0.0)
	return
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


func _security_camera(at: Vector3, yaw: float) -> void:
	# The mount sits on local Y. Pitching it puts that plate on the wall and the lens into the room.
	var root := Node3D.new()
	root.name = "SecurityCamera"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var node := BK_CAMERA.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	root.add_child(node)
	_box_around(root)
	var led := OmniLight3D.new()
	led.name = "CameraLedLight"
	led.position = Vector3(0.0, -0.04, 0.1)
	led.light_color = Color(1.0, 0.12, 0.08)
	led.light_energy = 0.35
	led.omni_range = 0.8
	root.add_child(led)


func _scatter_corner_plants() -> void:
	# One plant per closed corner, then a spread of about thirty across the rooms.
	var spots: Array[Vector3] = []
	var trees: Array[bool] = []
	var seen: Dictionary = {}
	var serial := 0
	for cell in _cells:
		if not _plant_room(cell):
			continue
		var pairs: Array[String] = ["sw", "se", "nw", "ne"]
		for pair in pairs:
			var a := pair.substr(0, 1)
			var b := pair.substr(1, 1)
			if not _is_solid_edge(_kind_on(cell, a)) or not _is_solid_edge(_kind_on(cell, b)):
				continue
			var use_tree := posmod(serial, 3) == 0
			serial += 1
			# The broadleaf leaves reach 0.36 m. The palm canopy reaches 0.95 m.
			var gap := 1.05 if use_tree else 0.46
			var at := _corner_spot(cell, pair, gap)
			var key := Vector2i(int(at.x * 2.0), int(at.z * 2.0))
			if seen.has(key):
				continue
			seen[key] = true
			spots.append(at)
			trees.append(use_tree)
	if spots.is_empty():
		return
	var step := maxi(1, int(spots.size() / 30.0))
	var placed := 0
	var index := 0
	var used: Dictionary = {}
	while placed < 30 and index < spots.size():
		var tree := trees[index]
		var radius := 1.15 if tree else 0.45
		var at := _clear_plant_spot(spots[index], radius)
		var key := Vector2i(int(at.x * 2.0), int(at.z * 2.0))
		if not used.has(key):
			used[key] = true
			var yaw := float(placed) * 0.9
			if tree:
				_bk(BK_TREE, _geometry, at, yaw)
			else:
				_bk(BK_PLANT, _geometry, at, yaw)
			placed += 1
		index += step


func _plant_room(cell: Vector2i) -> bool:
	if not _cell_set.has(cell) or _is_elevator_car(cell) or _is_corridor_cell(cell):
		return false
	if not _expansion.has(cell) and cell.y >= 17:
		return false
	if cell.x >= 5 and cell.x <= 7 and cell.y >= 40 and cell.y <= 43:
		return false
	if cell.x >= -6 and cell.x <= -5 and cell.y >= 24 and cell.y <= 26:
		return false
	if cell == Vector2i(6, 22) or cell == Vector2i(-1, 5) or _is_restroom(cell):
		return false
	if _storage_cells.has(cell) or _workplace_cells.has(cell):
		return false
	return true


func _plant_hits_cubicle(at: Vector3, radius: float) -> bool:
	for spot in _cubicle_spots:
		var yaw := float(spot["yaw"])
		var dx := at.x - float(spot["x"])
		var dz := at.z - float(spot["z"])
		var co := cos(yaw)
		var si := sin(yaw)
		var lx := dx * co - dz * si
		var lz := dx * si + dz * co
		if lx >= -1.08 - radius and lx <= 1.08 + radius and lz >= -0.25 - radius and lz <= 1.75 + radius:
			return true
	return false


func _clear_plant_spot(at: Vector3, radius: float) -> Vector3:
	if not _plant_hits_cubicle(at, radius):
		return at
	var best := at
	var best_d := 100000.0
	var found := false
	var origin := Vector2i(int(floor(at.x / CELL)), int(floor(at.z / CELL)))
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var cell := origin + Vector2i(dx, dz)
			if not _cell_set.has(cell):
				continue
			var inset := radius + 0.2
			var corners: Array[Vector3] = [
				Vector3(cell.x * CELL + inset, 0.0, cell.y * CELL + inset),
				Vector3((cell.x + 1) * CELL - inset, 0.0, cell.y * CELL + inset),
				Vector3(cell.x * CELL + inset, 0.0, (cell.y + 1) * CELL - inset),
				Vector3((cell.x + 1) * CELL - inset, 0.0, (cell.y + 1) * CELL - inset),
			]
			for spot in corners:
				if _plant_hits_cubicle(spot, radius):
					continue
				var dist := spot.distance_squared_to(at)
				if dist < best_d:
					best = spot
					best_d = dist
					found = true
	for spot in _cubicle_spots:
		var yaw := float(spot["yaw"])
		var co := cos(yaw)
		var si := sin(yaw)
		var offsets: Array[Vector2] = [
			Vector2(0.0, 1.9 + radius),
			Vector2(1.35 + radius, 0.7),
			Vector2(-(1.35 + radius), 0.7),
		]
		for off in offsets:
			var wx := float(spot["x"]) + off.x * co + off.y * si
			var wz := float(spot["z"]) - off.x * si + off.y * co
			var candidate := Vector3(wx, 0.0, wz)
			if not _point_in_cell(candidate, radius) or _plant_hits_cubicle(candidate, radius):
				continue
			var dist := candidate.distance_squared_to(at)
			if dist < best_d:
				best = candidate
				best_d = dist
				found = true
	return best if found else at


func _point_in_cell(at: Vector3, margin: float) -> bool:
	var cell := Vector2i(int(floor(at.x / CELL)), int(floor(at.z / CELL)))
	if not _cell_set.has(cell):
		return false
	var lx := at.x - float(cell.x) * CELL
	var lz := at.z - float(cell.y) * CELL
	return lx > margin and lx < CELL - margin and lz > margin and lz < CELL - margin


func _corner_spot(cell: Vector2i, pair: String, gap: float) -> Vector3:
	var x0 := cell.x * CELL
	var z0 := cell.y * CELL
	var x := x0 + gap
	var z := z0 + gap
	if pair.contains("e"):
		x = x0 + CELL - gap
	if pair.contains("n"):
		z = z0 + CELL - gap
	return Vector3(x, 0.0, z)


func _scatter_reference_props() -> void:
	_potted_tree(_clear_plant_spot(Vector3(6.2, 0.0, 63.6), 1.15))
	_broadleaf_plant(_clear_plant_spot(Vector3(8.75, 0.0, 26.3), 0.45))
	_metal_shelf(Vector3(-7.72, 0.0, 66.2), PI * 0.5)
	_office_copier(Vector3(15.52, 0.0, 26.5), -PI * 0.5)
	_filing_cabinet(Vector3(-15.62, 0.0, 67.4), PI * 0.5)


func _potted_tree(at: Vector3) -> void:
	_bk(BK_TREE, _geometry, at, 0.0)
	return
	var root := Node3D.new()
	root.name = "PottedTree"
	root.position = at
	_geometry.add_child(root)
	var pot := _mat(Color(0.07, 0.07, 0.08), 0.55)
	var bark := _mat(Color(0.4, 0.25, 0.14), 0.78)
	var leaf := _mat(Color(0.15, 0.4, 0.14), 0.72)
	var shade := _mat(Color(0.1, 0.28, 0.1), 0.75)
	_cylinder(root, Vector3(0.0, 0.16, 0.0), 0.16, 0.13, 0.32, pot)
	_cylinder(root, Vector3(0.0, 0.85, 0.0), 0.04, 0.065, 1.2, bark)
	_sphere(root, Vector3(0.0, 1.72, 0.0), 0.42, leaf)
	_sphere(root, Vector3(0.3, 1.55, 0.1), 0.28, shade)
	_sphere(root, Vector3(-0.28, 1.58, -0.08), 0.3, leaf)
	_sphere(root, Vector3(0.06, 1.98, -0.14), 0.24, shade)
	_sphere(root, Vector3(-0.08, 1.86, 0.24), 0.22, leaf)


func _broadleaf_plant(at: Vector3) -> void:
	_bk(BK_PLANT, _geometry, at, 0.0)
	return
	var root := Node3D.new()
	root.name = "Broadleaf"
	root.position = at
	_geometry.add_child(root)
	var pot := _mat(Color(0.07, 0.07, 0.08), 0.55)
	var leaf := _mat(Color(0.2, 0.5, 0.2), 0.55)
	var stripe := _mat(Color(0.78, 0.84, 0.55), 0.5)
	_cylinder(root, Vector3(0.0, 0.1, 0.0), 0.11, 0.09, 0.2, pot)
	for i in 7:
		var stem := Node3D.new()
		stem.rotation.y = float(i) * TAU / 7.0
		stem.rotation.z = deg_to_rad(-16.0 - float(i % 3) * 7.0)
		root.add_child(stem)
		_bit(stem, Vector3(0.0, 0.52, 0.0), Vector3(0.11, 0.72, 0.012), leaf)
		_bit(stem, Vector3(0.0, 0.52, 0.008), Vector3(0.03, 0.55, 0.006), stripe)


func _metal_shelf(at: Vector3, yaw: float) -> void:
	_shelf_spots.append({"x": at.x, "z": at.z, "yaw": yaw})
	var node := _bk(BK_SHELF, _geometry, at, yaw)
	# Board tops are 0.614, 0.958 and 1.303. Two millimetres of sink keeps the stacks on the wood.
	_bk(BK_BOOKS, node, Vector3(-0.28, 0.612, 0.0), 0.2)
	_flat_folder(node, Vector3(0.22, 0.612, 0.0))
	_bk(BK_BOOKS, node, Vector3(0.02, 0.956, 0.0), -0.3)
	_bk(BK_BOOKS, node, Vector3(-0.08, 1.301, 0.0), 0.15)
	return
	var root := Node3D.new()
	root.name = "MetalShelf"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var steel := _mat(Color(0.76, 0.77, 0.79), 0.28, 0.86)
	var board := _mat(Color(0.62, 0.46, 0.28), 0.62)
	for side in [-0.44, 0.44]:
		for depth in [-0.16, 0.16]:
			_part(root, Vector3(side, 0.9, depth), Vector3(0.028, 1.8, 0.028), steel)
	for i in 5:
		_part(root, Vector3(0.0, 0.08 + float(i) * 0.4, 0.0), Vector3(0.9, 0.022, 0.36), board)


func _office_copier(at: Vector3, yaw: float) -> void:
	_bk(BK_COPIER, _geometry, at, yaw)
	return
	var root := Node3D.new()
	root.name = "Copier"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var body := _mat(Color(0.9, 0.91, 0.92), 0.38)
	var dark := _mat(Color(0.16, 0.18, 0.22), 0.45)
	var screen := _mat(Color(0.04, 0.08, 0.12), 0.2, 0.0, Color(0.25, 0.5, 0.75), 0.9)
	_part(root, Vector3(0.0, 0.48, 0.0), Vector3(0.72, 0.9, 0.64), body)
	_part(root, Vector3(0.0, 1.02, -0.04), Vector3(0.66, 0.2, 0.5), dark)
	_bit(root, Vector3(0.16, 1.08, 0.24), Vector3(0.18, 0.12, 0.012), screen)
	_bit(root, Vector3(-0.2, 0.92, 0.3), Vector3(0.3, 0.02, 0.18), body)
	for i in 3:
		_bit(root, Vector3(0.2, 0.22 + float(i) * 0.16, 0.33), Vector3(0.28, 0.01, 0.008), dark)


func _scatter_cabinets() -> void:
	# The reference shelf is placed later, on this same wall.
	_shelf_spots.append({"x": -7.72, "z": 66.2, "yaw": PI * 0.5})
	var cells: Array[Vector2i] = []
	var edges: Array[String] = []
	var prefers: Array[float] = []
	var seen: Dictionary = {}
	for cell in _cells:
		if not _plant_room(cell):
			continue
		var edge := _cabinet_wall(cell)
		if edge == "":
			continue
		var along := 2.15 if posmod(cell.x + cell.y, 2) == 0 else 1.55
		var at := _on_wall(cell, edge, along)
		var key := Vector2i(int(at.x * 2.0), int(at.z * 2.0))
		if seen.has(key):
			continue
		seen[key] = true
		cells.append(cell)
		edges.append(edge)
		prefers.append(along)
	if cells.is_empty():
		return
	var step := maxi(1, int(cells.size() / 20.0))
	var placed := 0
	var index := 0
	while placed < 20 and index < cells.size():
		var along := _clear_cabinet_along(cells[index], edges[index], prefers[index])
		if along >= 0.0:
			var spot := _on_wall(cells[index], edges[index], along) - _edge_dir(edges[index]) * 0.37
			_filing_cabinet(spot, _face_into_room(edges[index]))
			_cabinet_spots.append(spot)
			placed += 1
			index += step
		else:
			index += 1


func _clear_cabinet_along(cell: Vector2i, edge: String, prefer: float) -> float:
	var options: Array[float] = [prefer, 0.7, 3.3, 1.05, 2.95, 1.55, 2.45]
	for along in options:
		var at := _on_wall(cell, edge, along) - _edge_dir(edge) * 0.37
		if not _cabinet_blocked(at):
			return along
	return -1.0


func _cabinet_blocked(at: Vector3) -> bool:
	for spot in _shelf_spots:
		var yaw := float(spot["yaw"])
		var dx := at.x - float(spot["x"])
		var dz := at.z - float(spot["z"])
		var co := cos(yaw)
		var si := sin(yaw)
		var lx := dx * co - dz * si
		var lz := dx * si + dz * co
		# Shelf is 1.16 m wide. Keep the cabinet body clear of the uprights.
		if absf(lx) < 1.08 and absf(lz) < 0.85:
			return true
	for other in _cabinet_spots:
		if at.distance_to(other) < 0.85:
			return true
	return false


func _cabinet_wall(cell: Vector2i) -> String:
	var back := _back_wall(cell)
	if back != "" and _kind_on(cell, back) == "wall":
		return back
	for edge in EDGES:
		if _kind_on(cell, edge) == "wall":
			return edge
	return ""


func _paint_white_cabinet(root: Node3D) -> void:
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			var albedo := Color(0.75, 0.76, 0.77) if _is_drawer_face(root, mesh_node) else Color(0.94, 0.94, 0.95)
			if mesh_node.mesh != null:
				for surface in mesh_node.mesh.get_surface_count():
					var current := mesh_node.get_active_material(surface)
					if current is BaseMaterial3D:
						mesh_node.set_surface_override_material(surface, _cabinet_finish(current as BaseMaterial3D, albedo))
			if mesh_node.material_override is BaseMaterial3D:
				mesh_node.material_override = _cabinet_finish(mesh_node.material_override as BaseMaterial3D, albedo)
		for child in node.get_children():
			pending.append(child)


func _is_drawer_face(cabinet: Node3D, mesh_node: MeshInstance3D) -> bool:
	if mesh_node.mesh == null:
		return false
	var ab := mesh_node.get_aabb()
	var to_cabinet := cabinet.global_transform.affine_inverse() * mesh_node.global_transform
	var min_z := 1000.0
	var max_z := -1000.0
	for i in 8:
		var corner := Vector3(
			ab.position.x if (i & 1) == 0 else ab.end.x,
			ab.position.y if (i & 2) == 0 else ab.end.y,
			ab.position.z if (i & 4) == 0 else ab.end.z
		)
		var z := (to_cabinet * corner).z
		min_z = minf(min_z, z)
		max_z = maxf(max_z, z)
	# The drawer fronts are the thin sheets on the +Z side. The label texture on them is transparent.
	return max_z - min_z < 0.05 and max_z > 0.25


func _cabinet_finish(source: BaseMaterial3D, albedo: Color) -> BaseMaterial3D:
	var copy := source.duplicate() as BaseMaterial3D
	copy.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	copy.albedo_color = albedo
	copy.albedo_texture = null
	copy.metallic = 0.06
	copy.roughness = 0.48
	if copy is StandardMaterial3D:
		var std := copy as StandardMaterial3D
		std.metallic_texture = null
		std.roughness_texture = null
	return copy


func _close_drawers(cabinet: Node3D) -> void:
	# The cabinet front is an open frame. These sheets close the three drawers.
	var face := _mat(Color(0.78, 0.79, 0.80), 0.52, 0.02)
	var pull := _mat(Color(0.38, 0.39, 0.41), 0.35, 0.55)
	var height := 0.385
	var gap := 0.015
	for i in 3:
		var bottom := 0.09 + float(i) * (height + gap)
		var y := bottom + height * 0.5
		_bit(cabinet, Vector3(0.0, y, 0.382), Vector3(0.40, height - 0.008, 0.016), face)
		_bit(cabinet, Vector3(0.0, bottom + height - 0.045, 0.394), Vector3(0.16, 0.016, 0.008), pull)


func _filing_cabinet(at: Vector3, yaw: float) -> void:
	var node := _bk(BK_CABINET, _geometry, at, yaw)
	_paint_white_cabinet(node)
	_close_drawers(node)
	return
	var root := Node3D.new()
	root.name = "FilingCabinet"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var grey := _mat(Color(0.68, 0.69, 0.71), 0.38, 0.12)
	var line := _mat(Color(0.32, 0.33, 0.35), 0.45)
	_part(root, Vector3(0.0, 0.52, 0.0), Vector3(0.46, 1.02, 0.58), grey)
	for i in 3:
		_bit(root, Vector3(0.0, 0.28 + float(i) * 0.3, 0.3), Vector3(0.36, 0.012, 0.008), line)
	_bit(root, Vector3(0.16, 0.9, 0.3), Vector3(0.025, 0.018, 0.01), _metal_mat)


func _conference_eight(at: Vector3) -> void:
	var cell := Vector2i(int(floor(at.x / CELL)), int(floor(at.z / CELL)))
	var spot := at
	# The table sits in a corner. Slide it into the open floor so the chairs fit beside it.
	if _is_solid_edge(_kind_on(cell, "e")) and _kind_on(cell, "w") == "none":
		spot.x -= 1.15
	elif _is_solid_edge(_kind_on(cell, "w")) and _kind_on(cell, "e") == "none":
		spot.x += 1.15
	if _is_solid_edge(_kind_on(cell, "n")) and _kind_on(cell, "s") == "none":
		spot.z -= 0.45
	elif _is_solid_edge(_kind_on(cell, "s")) and _kind_on(cell, "n") == "none":
		spot.z += 0.45
	_conference_table(spot)
	# Grey top from the reference photo, centred on spot. Chairs that meet a wall are dropped.
	var alongs: Array[float] = [-0.9, 0.0, 0.9]
	for along in alongs:
		_seat_photo(spot, "n", along)
		_seat_photo(spot, "s", along)
	_seat_photo(spot, "e", 0.0)
	_seat_photo(spot, "w", 0.0)


func _small_conference(at: Vector3) -> void:
	_conference_eight(at)
	return
	var root := Node3D.new()
	root.name = "SmallConference"
	root.position = at
	_geometry.add_child(root)
	var grey := _mat(Color(0.62, 0.64, 0.66), 0.38, 0.04)
	var stripe := _mat(Color(0.46, 0.28, 0.16), 0.5)
	var leg := _mat(Color(0.34, 0.36, 0.38), 0.32, 0.65)
	_part(root, Vector3(0.0, 0.76, 0.0), Vector3(1.2, 0.05, 2.2), grey)
	_part(root, Vector3(0.0, 0.79, 0.0), Vector3(0.12, 0.012, 1.8), stripe)
	for end_z in [-0.85, 0.85]:
		_splayed_leg(root, Vector3(-0.16, 0.0, end_z), -0.42, leg)
		_splayed_leg(root, Vector3(0.16, 0.0, end_z), 0.42, leg)
	_task_chair(at + Vector3(0.85, 0.0, 0.0), -PI * 0.5)
	_task_chair(at + Vector3(-0.85, 0.0, 0.0), PI * 0.5)
	_task_chair(at + Vector3(0.0, 0.0, 1.25), PI)
	_task_chair(at + Vector3(0.0, 0.0, -1.25), 0.0)


func _seat_photo(table: Vector3, side: String, along: float) -> void:
	var gap := 0.4
	var at := table
	var yaw := 0.0
	match side:
		"n":
			at += Vector3(along, 0.0, 0.6 + gap)
			yaw = PI
		"s":
			at += Vector3(along, 0.0, -0.6 - gap)
			yaw = 0.0
		"e":
			at += Vector3(1.2 + gap, 0.0, along)
			yaw = -PI * 0.5
		_:
			at += Vector3(-1.2 - gap, 0.0, along)
			yaw = PI * 0.5
	_office_chair(_geometry, at, yaw)


func _photo_conference_table(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "PhotoConference"
	root.position = at
	_geometry.add_child(root)
	root.add_to_group("overlap_fixed")
	var top := _mat(Color(0.62, 0.64, 0.66), 0.4, 0.08)
	var wood := _mat(Color(0.42, 0.26, 0.15), 0.52)
	var metal := _mat(Color(0.4, 0.42, 0.44), 0.32, 0.7)
	_part(root, Vector3(0.0, 0.74, 0.0), Vector3(2.4, 0.045, 1.2), top)
	_bit(root, Vector3(0.0, 0.766, 0.0), Vector3(2.2, 0.008, 0.11), wood)
	var ends: Array[float] = [-0.95, 0.95]
	for x in ends:
		_photo_leg(root, x, metal)


func _photo_leg(parent: Node3D, x: float, material: Material) -> void:
	var sides: Array[float] = [-1.0, 1.0]
	for side in sides:
		var top := Vector3(x, 0.7, side * 0.18)
		var foot := Vector3(x, 0.02, side * 0.52)
		var delta := foot - top
		var mesh_node := MeshInstance3D.new()
		mesh_node.position = (top + foot) * 0.5
		mesh_node.rotation.x = atan2(delta.z, delta.y)
		var box := BoxMesh.new()
		box.size = Vector3(0.04, delta.length(), 0.04)
		mesh_node.mesh = box
		mesh_node.material_override = material
		parent.add_child(mesh_node)
	_part(parent, Vector3(x, 0.025, 0.0), Vector3(0.045, 0.03, 1.04), material)


func _conference_table(at: Vector3) -> void:
	_photo_conference_table(at)
	return
	var root := Node3D.new()
	root.name = "ConferenceTable"
	root.position = at
	_geometry.add_child(root)
	var grey := _mat(Color(0.62, 0.64, 0.66), 0.38, 0.04)
	var stripe := _mat(Color(0.46, 0.28, 0.16), 0.5)
	var leg := _mat(Color(0.34, 0.36, 0.38), 0.32, 0.65)
	_part(root, Vector3(0.0, 0.76, 0.0), Vector3(1.4, 0.05, 6.2), grey)
	_part(root, Vector3(0.0, 0.79, 0.0), Vector3(0.14, 0.012, 5.5), stripe)
	for end_z in [-2.55, 2.55]:
		_splayed_leg(root, Vector3(-0.18, 0.0, end_z), -0.55, leg)
		_splayed_leg(root, Vector3(0.18, 0.0, end_z), 0.55, leg)


func _splayed_leg(parent: Node3D, foot: Vector3, top_x: float, material: Material) -> void:
	var top := Vector3(top_x, 0.74, foot.z)
	var delta := top - foot
	var mesh_node := MeshInstance3D.new()
	mesh_node.position = (top + foot) * 0.5
	mesh_node.rotation.z = atan2(-delta.x, delta.y)
	var box := BoxMesh.new()
	box.size = Vector3(0.04, delta.length(), 0.05)
	mesh_node.mesh = box
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _task_chair(at: Vector3, yaw: float) -> void:
	_bk(BK_OFFICE_CHAIR, _geometry, at, yaw)
	return
	var root := Node3D.new()
	root.name = "TaskChair"
	root.position = at
	root.rotation.y = yaw
	_geometry.add_child(root)
	var cloth := _mat(Color(0.12, 0.13, 0.15), 0.72)
	var base := _mat(Color(0.2, 0.21, 0.22), 0.32, 0.7)
	_part(root, Vector3(0.0, 0.48, 0.02), Vector3(0.46, 0.07, 0.46), cloth)
	_part(root, Vector3(0.0, 0.74, -0.16), Vector3(0.44, 0.4, 0.06), cloth)
	_part(root, Vector3(-0.24, 0.58, 0.02), Vector3(0.03, 0.18, 0.04), base)
	_part(root, Vector3(0.24, 0.58, 0.02), Vector3(0.03, 0.18, 0.04), base)
	_bit(root, Vector3(-0.24, 0.68, 0.04), Vector3(0.05, 0.025, 0.24), cloth)
	_bit(root, Vector3(0.24, 0.68, 0.04), Vector3(0.05, 0.025, 0.24), cloth)
	_part(root, Vector3(0.0, 0.28, 0.0), Vector3(0.06, 0.32, 0.06), base)
	for i in range(5):
		var caster := Node3D.new()
		caster.rotation.y = float(i) * TAU / 5.0
		root.add_child(caster)
		_bit(caster, Vector3(0.0, 0.08, 0.16), Vector3(0.03, 0.02, 0.28), base)
		_bit(caster, Vector3(0.0, 0.045, 0.28), Vector3(0.045, 0.04, 0.05), base)


func _sphere(parent: Node3D, origin: Vector3, radius: float, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.position = origin
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_node.mesh = sphere
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _upside_down_exit(at: Vector3) -> void:
	var sign = FLOOR_EXIT.new()
	sign.name = "UpsideDownExit"
	sign.position = at
	var label := Label3D.new()
	label.text = "EXIT"
	label.pixel_size = 0.006
	label.font_size = 120
	label.modulate = Color(0.92, 0.03, 0.04)
	label.outline_modulate = Color(0.4, 0.0, 0.0)
	label.outline_size = 12
	label.rotation = Vector3(0.0, PI, PI)
	sign.add_child(label)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.35, 0.42, 0.1)
	collision.shape = box
	sign.add_child(collision)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.12, 0.08)
	glow.light_energy = 0.8
	glow.omni_range = 2.4
	sign.add_child(glow)
	_geometry.add_child(sign)


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
	# Face back into the room. The other way reads EXIT backwards, as TIXE.
	sign.rotation.y = PI
	sign.position.y = 3.12
	_geometry.add_child(sign)
	var glow := OmniLight3D.new()
	glow.position = sign.position
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


func _build_restrooms() -> void:
	# White square sheet from Blendkit: ten tiles across. Walls use the medium
	# size, floors the large size.
	var wall_ns := _square_tile_material(0.20, CELL, 3.2)
	var wall_ew := _square_tile_material(0.20, 3.2, CELL)
	var floor_tile := _square_tile_material(0.40, 3.78, 3.78)
	var bands: Array[int] = [20, 44]
	for band in bands:
		_dress_restroom(2, 3, band, band + 1, wall_ns, wall_ew, floor_tile)
		_dress_restroom(2, 3, band + 2, band + 3, wall_ns, wall_ew, floor_tile)
		var x0 := 8.0
		var x1 := 16.0
		var south0 := float(band) * CELL
		var south1 := float(band + 2) * CELL
		var north1 := float(band + 4) * CELL
		# South room opens west, off the central corridor. Toilets line the far wall,
		# clear of the sinks on the south wall.
		_toilet_bank("e", x0, x1, south0, south1, "s")
		_sink_bank("s", x0, x1, south0, south1)
		_wc_symbol(Vector2i(1, band + 1), "e", "HOMEM")
		# North room opens east. Toilets stay clear of the sinks on the north wall.
		_toilet_bank("w", x0, x1, south1, north1, "n")
		_sink_bank("n", x0, x1, south1, north1)
		_wc_symbol(Vector2i(3, band + 3), "e", "MULHER")


func _dress_restroom(x0: int, x1: int, z0: int, z1: int, wall_ns: Material, wall_ew: Material, floor_tile: Material) -> void:
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var cell := Vector2i(x, z)
			_tile_floor(cell, floor_tile)
			for edge in EDGES:
				var kind := _kind_on(cell, edge)
				if kind != "wall" and kind != "window":
					continue
				var mat := wall_ew if edge == "e" or edge == "w" else wall_ns
				_tile_wall(cell, edge, mat)


func _tile_floor(cell: Vector2i, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "TileFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.78, 3.78)
	mesh_node.mesh = plane
	mesh_node.position = Vector3(cell.x * CELL + 2.0, 0.02, cell.y * CELL + 2.0)
	mesh_node.material_override = material
	_geometry.add_child(mesh_node)


func _tile_wall(cell: Vector2i, edge: String, material: Material) -> void:
	var face := _on_wall(cell, edge, 2.0) - _edge_dir(edge) * 0.012
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "TileWall"
	var plane := PlaneMesh.new()
	# North and south walls run along X. East and west walls stand by rolling
	# the plane onto its side, so the long axis has to start on local Z.
	if edge == "e" or edge == "w":
		plane.size = Vector2(3.2, CELL)
		mesh_node.rotation.z = PI * 0.5
	else:
		plane.size = Vector2(CELL, 3.2)
		mesh_node.rotation.x = -PI * 0.5
	mesh_node.mesh = plane
	mesh_node.position = Vector3(face.x, 1.6, face.z)
	mesh_node.material_override = material
	_geometry.add_child(mesh_node)


func _square_tile_material(tile: float, span_u: float, span_v: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TILE_TEX
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.roughness = 0.34
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(span_u / tile / 10.0, span_v / tile / 10.0, 1.0)
	return mat


func _toilet_bank(edge: String, x0: float, x1: float, z0: float, z1: float, sink_end: String) -> void:
	# The bowl sits near the floor in the source model. A uniform scale lifts the seat
	# without stretching it. Back and front are the scaled local Z extents.
	var scale := 1.48
	var back := 0.250 * scale
	var front := 0.369 * scale
	var wall_clear := 0.06
	var origin_gap := back + wall_clear
	var front_gap := origin_gap + front
	# Closed door stays this far in front of the bowl, so the leaf does not touch it.
	var door_gap := 0.42
	var door_from_wall := front_gap + door_gap
	var stall_depth := door_from_wall + 0.08
	var white := _mat(Color(0.95, 0.95, 0.94), 0.4)
	var low_pad := 0.96 if sink_end == "s" or sink_end == "w" else 0.24
	var high_pad := 0.96 if sink_end == "n" or sink_end == "e" else 0.24
	var run0 := z0 + low_pad
	var run1 := z1 - high_pad
	if edge == "n" or edge == "s":
		run0 = x0 + low_pad
		run1 = x1 - high_pad
	var count := 5
	var pitch := (run1 - run0) / float(count)
	var yaw := _face_into_room(edge)
	for i in count:
		var along := run0 + (float(i) + 0.5) * pitch
		var at := _against(edge, x0, x1, z0, z1, along, origin_gap)
		var toilet := _bk(BK_TOILET, _geometry, at, yaw)
		toilet.scale = Vector3(scale, scale, scale)
		_stall_front(edge, x0, x1, z0, z1, along, pitch, door_from_wall, white)
	for i in count + 1:
		var along := run0 + float(i) * pitch
		var mid := _against(edge, x0, x1, z0, z1, along, wall_clear + stall_depth * 0.5)
		var size := Vector3(stall_depth, 1.92, 0.04)
		if edge == "n" or edge == "s":
			size = Vector3(0.04, 1.92, stall_depth)
		_solid("Stall", Vector3(mid.x, 1.06, mid.z), size, white)


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
	_stall_door(hinge, _face_into_room(edge), door_width, white)
	_stall_fill(edge, x0, x1, z0, z1, bay0 + side * 0.5, side - 0.02, door_from_wall, white)
	var far := bay0 + side + door_width
	_stall_fill(edge, x0, x1, z0, z1, far + side * 0.5, side - 0.02, door_from_wall, white)


func _stall_fill(edge: String, x0: float, x1: float, z0: float, z1: float, along: float, width: float, door_from_wall: float, white: Material) -> void:
	if width < 0.04:
		return
	var at := _against(edge, x0, x1, z0, z1, along, door_from_wall)
	var size := Vector3(0.04, 1.80, width)
	if edge == "n" or edge == "s":
		size = Vector3(width, 1.80, 0.04)
	_solid("StallFill", Vector3(at.x, 1.02, at.z), size, white)


func _stall_door(at: Vector3, yaw: float, width: float, white: Material) -> void:
	var handle := _mat(Color(0.74, 0.75, 0.78), 0.28, 0.88)
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
	_geometry.add_child(body)


func _wc_symbol(cell: Vector2i, edge: String, token: String) -> void:
	# The Blendkit set is three plates lying flat. Stand one on the corridor face.
	var frame := _door_frames.get(_edge_key(cell, edge)) as Node3D
	if frame == null:
		return
	var door := frame.find_child("Door", true, false) as Node3D
	if door == null:
		return
	var room := cell + _delta(edge)
	var corridor := -_edge_dir(edge) if _is_restroom(room) else _edge_dir(edge)
	var outward := corridor.dot(door.global_transform.basis.z) > 0.0
	var mount := Node3D.new()
	mount.name = "WcSymbol"
	# Leaf collision is centered near z -0.025. Sit the plaque just off that face.
	mount.position = Vector3(0.6, 1.52, 0.016 if outward else -0.066)
	mount.rotation.y = 0.0 if outward else PI
	door.add_child(mount)
	var sign := BK_BATHROOM_SIGN.instantiate() as Node3D
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


func _sink_bank(edge: String, x0: float, x1: float, z0: float, z1: float) -> void:
	var run0 := z0 + 1.15
	var run1 := z1 - 1.15
	if edge == "n" or edge == "s":
		run0 = x0 + 1.15
		run1 = x1 - 1.15
	var count := 3
	var pitch := (run1 - run0) / float(count)
	for i in count:
		var along := run0 + (float(i) + 0.5) * pitch
		var at := _against(edge, x0, x1, z0, z1, along, 0.30)
		_bk(BK_SINK, _geometry, at, _face_into_room(edge))
		var face := _against(edge, x0, x1, z0, z1, along, 0.0)
		var mirror := _wall_hang(BK_MIRROR, face, _face_into_room(edge), 1.62, 1.6)
		_paint_black_glass(mirror)


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


func _paint_black_glass(root: Node3D) -> void:
	var glass := _mat(Color(0.012, 0.012, 0.014), 0.07, 0.62)
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = glass
		for child in node.get_children():
			pending.append(child)


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
