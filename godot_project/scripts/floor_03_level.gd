extends Node3D
## Floor 3 labyrinth. Corridors are an irregular street network. Rooms hang off
## that network on the same 4 m kit as Floor 4. Floor 4 itself is not touched.

const CELL := 4.0
const LIFT := 0.4
const TARGET := 85

const CARPET := preload("res://scenes/modular/carpet_4x4.tscn")
const CONCRETE := preload("res://scenes/modular/concrete_4x4.tscn")
const CEILING := preload("res://scenes/modular/ceiling_4x4.tscn")
const WALL := preload("res://scenes/modular/wall_4x3.tscn")
const WINDOW := preload("res://scenes/modular/window_wall.tscn")
const DOOR := preload("res://scenes/modular/door_frame.tscn")
const LIGHT := preload("res://scenes/modular/light_panel.tscn")
const PLAYER := preload("res://scenes/player.tscn")
const CABIN := preload("res://scripts/elevator_cabin.gd")
const CABINET_LINK := preload("res://scripts/cabinet_panel_link.gd")
const TABLE := preload("res://models/blendkit/conference.glb")
const CHAIR := preload("res://models/blendkit/office_chair.glb")
const SWIVEL := preload("res://models/blendkit/swivel_chair.glb")
const WOOD := preload("res://models/blendkit/wooden_chair.glb")
const FOLD := preload("res://models/blendkit/folding_chair.glb")
const WORK := preload("res://models/blendkit/office_workplace.glb")
const CRT := preload("res://models/blendkit/crt.glb")
const KEYBOARD := preload("res://models/blendkit/keyboard.glb")
const TOWER := preload("res://models/blendkit/tower.glb")
const FRIDGE := preload("res://models/blendkit/fridge.glb")
const COOLER := preload("res://models/blendkit/cooler.glb")
const SHELF := preload("res://models/blendkit/shelf.glb")
const CABINET := preload("res://models/blendkit/cabinet.glb")
const COPIER := preload("res://models/blendkit/copier.glb")
const RACK := preload("res://models/blendkit/server_rack.glb")
const PLANT := preload("res://models/blendkit/plant.glb")
const TREE := preload("res://models/blendkit/tree.glb")
const LADDER := preload("res://models/blendkit/ladder.glb")
const EXTINGUISHER := preload("res://models/blendkit/extinguisher.glb")
const BIN := preload("res://models/blendkit/pedal_bin.glb")
const PAPER := preload("res://models/blendkit/paper_bin.glb")
const BOOKS := preload("res://models/blendkit/books.glb")
const FOLDER := preload("res://models/blendkit/folder.glb")
const BOARD := preload("res://models/blendkit/whiteboard.glb")
const TV := preload("res://models/blendkit/wall_tv.glb")
const PENCIL := preload("res://models/blendkit/pencil_cup.glb")
const CAM_MODEL := preload("res://models/blendkit/camera.glb")
const GLASS := preload("res://models/blendkit/glass_board.glb")
const NOTES := preload("res://models/blendkit/sticky_notes.glb")
const TOILET_MODEL := preload("res://models/blendkit/toilet.glb")
const SINK := preload("res://models/blendkit/sink.glb")
const MIRROR := preload("res://models/blendkit/mirror.glb")
const BATHROOM_SIGN := preload("res://models/blendkit/bathroom_sign.glb")
const TILE_TEX := preload("res://models/blendkit/white_tiles.jpg")
const DOOR_SCRIPT := preload("res://scripts/door.gd")
const CONTROL_PANEL := preload("res://models/blendkit/electrical_control_panel.glb")
const WALL_PANEL := preload("res://models/blendkit/electrical_wall_panel.glb")
const EXIT := preload("res://scripts/locked_exit.gd")

const EDGES: Array[String] = ["n", "s", "e", "w"]

var _cells: Dictionary = {}
var _kind: Dictionary = {}
var _door: Dictionary = {}
var _size: Dictionary = {}
var _overrides: Dictionary = {}
var _campus: Dictionary = {}
var _flicker_lights: Array[OmniLight3D] = []
var _flicker_energy: Array[float] = []
var _asset_counts: Dictionary = {}
var _density_counts: Array[int] = [0, 0, 0, 0, 0]
var _rank: Dictionary = {}
var _multi_work := 0
var _wall_paint: StandardMaterial3D
var _grown := 0
var _report: PackedStringArray = PackedStringArray()
var _cab_body: StandardMaterial3D
var _cab_drawer: StandardMaterial3D
var _cab_pull: StandardMaterial3D
var _exit_red: StandardMaterial3D
var _exit_frame: StandardMaterial3D
var _exit_metal: StandardMaterial3D
var _stall_white: StandardMaterial3D
var _stall_handle: StandardMaterial3D
var _mirror_glass: StandardMaterial3D
var _tile_floor: StandardMaterial3D
var _tile_ns: StandardMaterial3D
var _tile_ew: StandardMaterial3D


func _ready() -> void:
	_environment()
	_carve_halls()
	_reserve_anchors()
	_mark_campus()
	_grow_rooms()
	_fill_pockets()
	_merge_excess()
	_place_doors()
	_repair_graph()
	_assign_remaining()
	_place_openings()
	_extra_doors()
	_build_shell()
	_furnish()
	_spawn_player()
	_write_report()
	FloorTransition.apply_pending_spawn(self)


func _process(_delta: float) -> void:
	if _flicker_lights.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	for i in _flicker_lights.size():
		var wave := sin(t * 17.0 + float(i) * 2.3) + sin(t * 5.5 + float(i))
		var factor := 1.0
		if wave < -1.15:
			factor = 0.08
		elif wave < -0.35:
			factor = 0.45
		_flicker_lights[i].light_energy = _flicker_energy[i] * factor


func _segments() -> Array:
	# Irregular streets. A jog, a narrow slot, and a spur keep the plan off a grid.
	# Long streets step sideways so a corridor cannot run the length of the floor.
	return [
		[1, 9, 1, 1],
		[9, 14, 2, 2],
		[14, 20, 1, 1],
		[1, 14, 4, 4],
		[16, 22, 5, 5],
		[3, 8, 8, 8],
		[8, 12, 7, 7],
		[12, 20, 8, 8],
		[1, 6, 12, 12],
		[6, 10, 11, 11],
		[10, 18, 12, 12],
		[6, 12, 15, 15],
		[12, 16, 16, 16],
		[16, 22, 15, 15],
		[1, 16, 18, 18],
		[16, 22, 19, 19],
		[1, 1, 1, 4],
		[0, 0, 4, 7],
		[1, 1, 7, 12],
		[2, 2, 15, 19],
		[6, 6, 1, 8],
		[6, 6, 12, 18],
		[10, 10, 4, 6],
		[11, 11, 6, 8],
		[10, 10, 8, 15],
		[14, 14, 1, 5],
		[15, 15, 5, 8],
		[14, 14, 8, 12],
		[15, 15, 15, 19],
		[18, 18, 5, 10],
		[17, 17, 10, 13],
		[18, 18, 13, 18],
		[22, 22, 5, 6],
		[21, 21, 6, 9],
		[22, 22, 9, 19],
		[13, 13, 9, 11],
		[16, 20, 2, 2],
	]


func _carve_halls() -> void:
	for seg in _segments():
		var x0: int = int(seg[0])
		var x1: int = int(seg[1])
		var z0: int = int(seg[2])
		var z1: int = int(seg[3])
		for z in range(mini(z0, z1), maxi(z0, z1) + 1):
			for x in range(mini(x0, x1), maxi(x0, x1) + 1):
				var cell := Vector2i(x, z)
				_cells[cell] = "hall"
				_kind["hall"] = "hall"


func _reserve_anchors() -> void:
	_reserve(Vector2i(8, 0), "downcar", "car")
	_reserve(Vector2i(20, 20), "upcar", "car")
	_reserve(Vector2i(7, 2), "panel_down", "utility")
	_reserve(Vector2i(19, 18), "panel_up", "utility")
	_force_door("panel_down", Vector2i(7, 2), "s")
	_force_door("panel_up", Vector2i(19, 18), "n")
	_reserve_rect(2, 3, 2, 3, "open_a", "open", Vector2i(2, 2), "s")
	_reserve_rect(11, 12, 9, 10, "open_b", "open", Vector2i(12, 9), "e")
	_reserve_rect(7, 8, 13, 14, "open_c", "open", Vector2i(7, 13), "w")
	_reserve_rect(3, 4, 16, 17, "open_d", "open", Vector2i(3, 16), "w")
	_reserve_rect(2, 3, 9, 10, "server", "server", Vector2i(2, 9), "w")
	_reserve_rect(21, 21, 10, 11, "restroom", "restroom", Vector2i(21, 10), "e")
	_mark("8,0,n", "elevator")
	_mark("20,19,n", "elevator")


func _reserve(cell: Vector2i, id: String, kind: String) -> void:
	if str(_cells.get(cell, "")) == "hall":
		push_error("Floor 3 anchor %s landed on a corridor" % id)
		return
	_cells[cell] = id
	_kind[id] = kind
	_size[id] = int(_size.get(id, 0)) + 1


func _reserve_rect(x0: int, x1: int, z0: int, z1: int, id: String, kind: String, door_cell: Vector2i, edge: String) -> void:
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			_reserve(Vector2i(x, z), id, kind)
	_force_door(id, door_cell, edge)


func _force_door(id: String, cell: Vector2i, edge: String) -> void:
	_door[id] = {"cell": cell, "edge": edge}


func _mark_campus() -> void:
	var dist: Dictionary = {}
	var queue: Array[Vector2i] = []
	for key in _cells.keys():
		if str(_cells[key]) != "hall":
			continue
		var cell: Vector2i = key
		dist[cell] = 0
		queue.append(cell)
	var head := 0
	while head < queue.size():
		var here: Vector2i = queue[head]
		head += 1
		var depth: int = int(dist[here])
		if depth >= 2:
			continue
		for edge in EDGES:
			var nxt: Vector2i = here + _delta(edge)
			if dist.has(nxt) or not _inside(nxt):
				continue
			dist[nxt] = depth + 1
			queue.append(nxt)
	_campus = dist


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x <= 23 and cell.y >= 0 and cell.y <= 21


func _grow_rooms() -> void:
	var halls: Array[Vector2i] = []
	for key in _cells.keys():
		if str(_cells[key]) == "hall":
			halls.append(key)
	halls.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	var need := TARGET - _counted_rooms()
	for hall in halls:
		if _grown >= need:
			break
		for edge in EDGES:
			if _grown >= need:
				break
			var nxt: Vector2i = hall + _delta(edge)
			if not _free(nxt):
				continue
			var id := "r%d" % _grown
			var away := nxt - hall
			if _claim(nxt, away, _pattern(_grown), id):
				_door[id] = {"cell": nxt, "edge": _opposite(edge)}
				_grown += 1


func _pattern(n: int) -> int:
	var roll := _roll(n, 3) % 10
	if roll <= 4:
		return 0
	if roll <= 7:
		return 1
	if roll == 8:
		return 2
	return 3


func _claim(at: Vector2i, away: Vector2i, pattern: int, id: String) -> bool:
	var shapes: Array[int] = [pattern]
	if pattern != 0:
		shapes.append(0)
	for shape in shapes:
		var cells := _shape(at, away, shape)
		var ok := true
		for cell in cells:
			if not _free(cell):
				ok = false
				break
		if not ok:
			continue
		for cell in cells:
			_cells[cell] = id
		_size[id] = cells.size()
		return true
	return false


func _shape(at: Vector2i, away: Vector2i, pattern: int) -> Array[Vector2i]:
	var side := Vector2i(-away.y, away.x)
	var cells: Array[Vector2i] = [at]
	if pattern == 1:
		cells.append(at + away)
	elif pattern == 2:
		cells.append(at + side)
	elif pattern == 3:
		cells.append(at + away)
		cells.append(at + side)
		cells.append(at + away + side)
	return cells


func _free(cell: Vector2i) -> bool:
	return _campus.has(cell) and not _cells.has(cell)


func _fill_pockets() -> void:
	var pending: Array[Vector2i] = []
	for key in _campus.keys():
		var cell: Vector2i = key
		if not _cells.has(cell):
			pending.append(cell)
	pending.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	var need := TARGET - _counted_rooms()
	for cell in pending:
		if _cells.has(cell):
			continue
		if need > 0 and _touches_hall(cell):
			var id := "r%d" % _grown
			_cells[cell] = id
			_size[id] = 1
			for edge in EDGES:
				var nxt: Vector2i = cell + _delta(edge)
				if str(_cells.get(nxt, "")) == "hall":
					_door[id] = {"cell": cell, "edge": edge}
					break
			_grown += 1
			need -= 1
			continue
		var host := _annex_host(cell)
		if host == "":
			var id := "r%d" % _grown
			_cells[cell] = id
			_size[id] = 1
			for edge in EDGES:
				var nxt: Vector2i = cell + _delta(edge)
				if str(_cells.get(nxt, "")) == "hall":
					_door[id] = {"cell": cell, "edge": edge}
					break
			_grown += 1
			continue
		_cells[cell] = host
		_size[host] = int(_size.get(host, 1)) + 1


func _touches_hall(cell: Vector2i) -> bool:
	for edge in EDGES:
		if str(_cells.get(cell + _delta(edge), "")) == "hall":
			return true
	return false


func _annex_host(cell: Vector2i) -> String:
	var best := ""
	var best_size := 999
	for edge in EDGES:
		var id := str(_cells.get(cell + _delta(edge), ""))
		if not id.begins_with("r"):
			continue
		var size := int(_size.get(id, 1))
		if size >= 4 or size >= best_size:
			continue
		best = id
		best_size = size
	return best


func _merge_excess() -> void:
	var guard := 0
	while _counted_rooms() > TARGET and guard < 500:
		guard += 1
		var victim := _smallest_mergeable()
		if victim == "":
			break
		var host := _merge_neighbor(victim)
		if host == "":
			break
		for cell in _room_cells(victim):
			_cells[cell] = host
		_size[host] = int(_size.get(host, 0)) + int(_size.get(victim, 0))
		_size.erase(victim)
		_door.erase(victim)


func _smallest_mergeable() -> String:
	var best := ""
	var best_size := 999
	for key in _cells.keys():
		var id := str(_cells[key])
		if not id.begins_with("r"):
			continue
		var size := int(_size.get(id, 1))
		if size >= best_size:
			continue
		if _merge_neighbor(id) == "":
			continue
		best = id
		best_size = size
	return best


func _merge_neighbor(id: String) -> String:
	var best := ""
	var best_size := 999
	for cell in _room_cells(id):
		for edge in EDGES:
			var other := str(_cells.get(cell + _delta(edge), ""))
			if other == "" or other == id or other == "hall" or other.ends_with("car") or other.begins_with("panel"):
				continue
			var size := int(_size.get(other, 1))
			if size >= 6 or size >= best_size:
				continue
			best = other
			best_size = size
	return best


func _place_doors() -> void:
	for id in _door.keys():
		var info: Dictionary = _door[id]
		var cell: Vector2i = info["cell"]
		var edge := str(info["edge"])
		if not _cells.has(cell):
			continue
		_overrides[_canon_key(cell, edge)] = "door"


func _repair_graph() -> void:
	for _try in 240:
		var seen := _reachable(Vector2i(16, 8))
		if seen.size() >= _cells.size():
			return
		var opened := false
		for key in _cells.keys():
			var cell: Vector2i = key
			if seen.has(cell):
				continue
			for edge in EDGES:
				var nxt: Vector2i = cell + _delta(edge)
				if not seen.has(nxt) or not _cells.has(nxt):
					continue
				if str(_cells[nxt]).ends_with("car") or str(_cells[cell]).ends_with("car"):
					continue
				_overrides[_canon_key(cell, edge)] = "door"
				opened = true
				break
			if opened:
				break
		if not opened:
			break
	var seen_final := _reachable(Vector2i(16, 8))
	var drop: Array[Vector2i] = []
	for key in _cells.keys():
		var cell: Vector2i = key
		if seen_final.has(cell):
			continue
		if str(_cells[cell]).ends_with("car"):
			continue
		drop.append(cell)
	for cell in drop:
		var id := str(_cells[cell])
		_cells.erase(cell)
		_size[id] = int(_size.get(id, 1)) - 1


func _reachable(start: Vector2i) -> Dictionary:
	var seen: Dictionary = {}
	if not _cells.has(start):
		return seen
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	var head := 0
	while head < queue.size():
		var here: Vector2i = queue[head]
		head += 1
		for edge in EDGES:
			var nxt: Vector2i = here + _delta(edge)
			if seen.has(nxt) or not _cells.has(nxt):
				continue
			if not _passable(here, edge):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return seen


func _passable(cell: Vector2i, edge: String) -> bool:
	var nxt: Vector2i = cell + _delta(edge)
	if str(_cells.get(cell, "")) == str(_cells.get(nxt, "")):
		return true
	var kind := str(_overrides.get(_canon_key(cell, edge), ""))
	return kind == "door" or kind == "elevator"


func _assign_remaining() -> void:
	var ids: Array[String] = []
	for key in _cells.keys():
		var id := str(_cells[key])
		if _kind.has(id) or ids.has(id):
			continue
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ds: int = int(_size.get(b, 1)) - int(_size.get(a, 1))
		if ds != 0:
			return ds > 0
		return a < b
	)
	var quotas := {
		"meeting": 10,
		"break": 5,
		"office": 35,
		"small": 15,
		"storage": 8,
		"utility": 3,
		"odd": 1,
	}
	var order: Array[String] = ["meeting", "break", "odd", "office", "small", "storage", "utility"]
	var prefer_big := {"meeting": true, "break": true, "office": true}
	for kind in order:
		var left: int = int(quotas[kind])
		var i := 0
		while left > 0 and i < ids.size():
			var id := ids[i]
			if _kind.has(id):
				i += 1
				continue
			var big: bool = int(_size.get(id, 1)) >= 2
			if prefer_big.has(kind) and not big and _has_untyped(ids, true):
				i += 1
				continue
			if (kind == "small" or kind == "storage" or kind == "utility" or kind == "odd") and big and _has_untyped(ids, false):
				i += 1
				continue
			_kind[id] = kind
			left -= 1
			i += 1
	for id in ids:
		if not _kind.has(id):
			_kind[id] = "office"


func _has_untyped(ids: Array[String], big: bool) -> bool:
	for id in ids:
		if _kind.has(id):
			continue
		var is_big: bool = int(_size.get(id, 1)) >= 2
		if is_big == big:
			return true
	return false


func _place_openings() -> void:
	var exits: Array[Vector2i] = [Vector2i(0, 7), Vector2i(23, 12), Vector2i(10, 0)]
	var edges: Array[String] = ["w", "e", "s"]
	var placed := 0
	for i in exits.size():
		var cell := _nearest_shell(exits[i], edges[i])
		if cell == Vector2i(-999, -999):
			continue
		_overrides[_canon_key(cell, edges[i])] = "exit"
		placed += 1
	if placed < 2:
		push_error("Floor 3 could not place the locked exits")
	for key in _cells.keys():
		var cell: Vector2i = key
		for edge in EDGES:
			var nxt: Vector2i = cell + _delta(edge)
			if _cells.has(nxt):
				continue
			var canon := _canon_key(cell, edge)
			if _overrides.has(canon):
				continue
			if _roll(cell.x * 13 + cell.y * 5 + edge.hash(), 9) % 5 != 0:
				continue
			if str(_cells[cell]) == "hall" and _roll(cell.x + cell.y, 1) % 2 == 0:
				continue
			_overrides[canon] = "window"


func _build_shell() -> void:
	for key in _cells.keys():
		var cell: Vector2i = key
		var id := str(_cells[cell])
		var tile: PackedScene = CARPET if _carpeted(id) else CONCRETE
		_module(tile, cell)
		_module(CEILING, cell).position.y += LIFT
		_lamp(cell, id)
	var seen: Dictionary = {}
	for key in _cells.keys():
		var cell: Vector2i = key
		for edge in EDGES:
			var canon := _canon_key(cell, edge)
			if seen.has(canon):
				continue
			seen[canon] = true
			var kind := _edge_kind(cell, edge)
			match kind:
				"wall":
					_lift(_place(WALL, cell, edge))
				"window":
					_lift(_place(WINDOW, cell, edge))
				"door":
					var door := _place(DOOR, cell, edge)
					_above_opening(door)
				"elevator":
					_shaft(cell, edge)
				"exit":
					_exit(cell, edge)
	_finish_car(Vector2i(8, 0), "n", "F03_DOWN", 2)
	_finish_car(Vector2i(20, 20), "s", "F03_UP", 4)


func _nearest_shell(want: Vector2i, edge: String) -> Vector2i:
	var best := Vector2i(-999, -999)
	var best_d := 9999
	var step := _delta(edge)
	for key in _cells.keys():
		var cell: Vector2i = key
		if _cells.has(cell + step):
			continue
		var d: int = absi(cell.x - want.x) + absi(cell.y - want.y)
		if d < best_d:
			best_d = d
			best = cell
	return best


func _carpeted(id: String) -> bool:
	var kind := str(_kind.get(id, ""))
	return kind == "office" or kind == "small" or kind == "meeting" or kind == "break" or kind == "open" or kind == "odd"


func _edge_kind(cell: Vector2i, edge: String) -> String:
	var canon := _canon_key(cell, edge)
	if _overrides.has(canon):
		return str(_overrides[canon])
	var nxt: Vector2i = cell + _delta(edge)
	if not _cells.has(nxt):
		return "wall"
	if str(_cells[cell]) != str(_cells[nxt]):
		return "wall"
	return "none"


func _furnish() -> void:
	_assign_ranks()
	var done: Dictionary = {}
	for key in _cells.keys():
		var id := str(_cells[key])
		if done.has(id):
			continue
		done[id] = true
		var kind := str(_kind.get(id, ""))
		if _rank.has(id):
			_density_counts[int(_rank[id])] += 1
		match kind:
			"office", "small":
				_furnish_office(id, kind == "small")
			"meeting":
				_furnish_meeting(id)
			"break":
				_furnish_break(id)
			"storage":
				_furnish_storage(id)
			"utility":
				if id.begins_with("panel"):
					_furnish_panel(id)
				else:
					_furnish_utility(id)
			"open":
				_furnish_open(id)
			"server":
				_furnish_server(id)
			"restroom":
				_furnish_restroom(id)
			"odd":
				_furnish_odd(id)
			"hall":
				_furnish_hall()
	_exit_count_note()
	_report_assets()


func _furnish_office(id: String, _small: bool) -> void:
	var info := _door_info(id)
	var door_edge := str(info["edge"])
	var door_cell: Vector2i = info["cell"]
	var far := _opposite(door_edge)
	var back: Vector2i = _far_cell(id, far)
	var computer_cell := _other_cell(id, back)
	var shared := computer_cell == back
	var side := _side_edge(far)
	if not _is_wall_edge(back, side):
		side = _opposite(side)
	var blockers: Array[Node3D] = []
	var manager_node: Node3D = null
	var desk_node: Node3D = null
	# Manager desk on the far wall, native size, monitor facing into the room.
	if _is_wall_edge(back, far):
		manager_node = _raw(WORK, _face_into(far))
		manager_node.name = "ManagerDesk"
		var manager_along := 2.0
		if shared:
			manager_along = 2.75 if (side == "w" or side == "s") else 1.25
		_settle_against(manager_node, back, far, manager_along, 0.16)
		_nudge_off_door(manager_node, far, door_cell, door_edge)
		blockers.append(manager_node)
	# The floating computer gets its own full-size desk, off the doorway.
	var desk_edge := side if shared else _desk_wall(computer_cell, door_edge, far)
	if _is_wall_edge(computer_cell, desk_edge):
		desk_node = _raw(TABLE, _face_into(desk_edge))
		desk_node.name = "ComputerDesk"
		var along := 2.0 if desk_edge == far else _deep_along(far)
		_settle_against(desk_node, computer_cell, desk_edge, along, 0.14)
		if manager_node != null:
			_separate(desk_node, manager_node, desk_edge)
		_nudge_off_door(desk_node, desk_edge, door_cell, door_edge)
		blockers.append(desk_node)
	if blockers.is_empty():
		return
	if manager_node != null:
		_seat(manager_node, _into(far), SWIVEL, id, door_cell, door_edge, blockers, true)
	var sitter: Node3D = null
	if desk_node != null:
		sitter = _seat(desk_node, _into(desk_edge), SWIVEL if shared else CHAIR, id, door_cell, door_edge, blockers, true)
		var aim := _into(desk_edge)
		if sitter != null:
			aim = sitter.global_position - desk_node.global_position
			aim.y = 0.0
		var local_aim := desk_node.global_transform.basis.inverse() * aim
		local_aim.y = 0.0
		if local_aim.length() > 0.001:
			local_aim = local_aim.normalized()
		var face := _yaw_facing(aim)
		_on_desk(KEYBOARD, desk_node, local_aim * 0.2, face)
		var screen := _on_desk(CRT, desk_node, -local_aim * 0.06, face)
		screen.name = "DeskScreen"
	if manager_node != null and desk_node != null:
		_multi_work += 1
	_dress_work(id, blockers)


func _furnish_meeting(id: String) -> void:
	var info := _door_info(id)
	var door_edge := str(info["edge"])
	var door_cell: Vector2i = info["cell"]
	var far := _opposite(door_edge)
	var table := _raw(TABLE, _face_into(far))
	table.name = "MeetingTable"
	_settle_against(table, _far_cell(id, far), far, 2.0, 0.2)
	_nudge_off_door(table, far, door_cell, door_edge)
	var blockers: Array[Node3D] = [table]
	_seat(table, _into(far), SWIVEL, id, door_cell, door_edge, blockers, true)
	_seat(table, _side(far), WOOD, id, door_cell, door_edge, blockers, false)
	_seat(table, -_side(far), WOOD, id, door_cell, door_edge, blockers, false)
	var screen := _on_desk(CRT, table, Vector3(0.05, 0.0, -0.04), _face_into(far))
	screen.name = "DeskScreen"
	var hung: PackedScene = BOARD if _roll(_id_num(id), 5) % 2 == 0 else TV
	if _hang_on_real_wall(id, hung, far, 1.78):
		_tag_last(hung)
	_dress_meeting(id, blockers, far)


func _furnish_break(id: String) -> void:
	var info := _door_info(id)
	var door_edge := str(info["edge"])
	var door_cell: Vector2i = info["cell"]
	var far := _opposite(door_edge)
	var cell: Vector2i = _far_cell(id, far)
	var wall := far
	if not _is_wall_edge(cell, wall):
		var found := false
		for candidate in _room_cells(id):
			if found:
				break
			for edge in EDGES:
				if edge != door_edge and _is_wall_edge(candidate, edge):
					cell = candidate
					wall = edge
					found = true
					break
	var appliances: Array[Node3D] = []
	if _is_wall_edge(cell, wall):
		var fridge := _raw(FRIDGE, _face_into(wall))
		fridge.name = "BreakFridge"
		_settle_against(fridge, cell, wall, 0.85, 0.1)
		appliances.append(fridge)
		var cooler := _raw(COOLER, _face_into(wall))
		cooler.name = "BreakCooler"
		_settle_against(cooler, cell, wall, 2.15, 0.1)
		_separate(cooler, fridge, wall)
		appliances.append(cooler)
	var table := _raw(TABLE, _face_into(far))
	table.name = "BreakTable"
	_center_mesh(table, _centroid(id))
	# Walk the table off the appliances, away from their wall.
	var toward_door := -_into(wall)
	for _step in 8:
		if not _hits_nodes(table, appliances):
			break
		table.position += toward_door * 0.3
	for _step in 6:
		if not _hits_door(table, door_cell, door_edge):
			break
		table.position -= toward_door * 0.22
	var blockers: Array[Node3D] = []
	for item in appliances:
		blockers.append(item)
	blockers.append(table)
	_seat(table, _into(far), WOOD, id, door_cell, door_edge, blockers, false)
	_seat(table, -_into(far), FOLD, id, door_cell, door_edge, blockers, false)
	var bin_edge := _side_edge(far)
	var bin_cell := door_cell
	if not _is_wall_edge(bin_cell, bin_edge):
		bin_edge = _opposite(bin_edge)
	if not _is_wall_edge(bin_cell, bin_edge):
		bin_cell = cell
		bin_edge = _side_edge(far)
	var bin := _raw(BIN, _face_into(bin_edge))
	bin.name = "BreakBin"
	_settle_against(bin, bin_cell, bin_edge, 0.55, 0.08)
	if _hits_nodes(bin, blockers) or _hits_door(bin, door_cell, door_edge):
		bin.position += _side(bin_edge) * 2.5
	blockers.append(bin)
	_dress_break(id, blockers)


func _furnish_storage(id: String) -> void:
	var info := _door_info(id)
	var far := _opposite(str(info["edge"]))
	var cell: Vector2i = _far_cell(id, far)
	var blockers: Array[Node3D] = []
	if _is_wall_edge(cell, far):
		blockers.append(_prop(SHELF, _inner(cell, far, 1.2, 0.4), _face_into(far), 2.0, 1.1))
		blockers.append(_prop(SHELF, _inner(cell, far, 2.8, 0.4), _face_into(far), 2.0, 1.1))
	var side := _side_edge(far)
	if _is_wall_edge(cell, side) and not _is_door_edge(cell, side):
		blockers.append(_prop(CABINET, _inner(cell, side, 2.2, 0.45), _face_into(side), 1.3, 0.65))
	var extra := _prop(COPIER, _centroid(id) + _into(far) * 0.4, _face_into(far), 1.15, 0.85) if _roll(_id_num(id), 2) % 2 == 0 else _prop(LADDER, _centroid(id), 0.4, 2.1, 0.65)
	if _off_doors(extra, id, blockers):
		blockers.append(extra)
	else:
		_forget(extra)
	_dress_storage(id, blockers)


func _furnish_utility(id: String) -> void:
	var info := _door_info(id)
	var far := _opposite(str(info["edge"]))
	var cell: Vector2i = _far_cell(id, far)
	var blockers: Array[Node3D] = []
	blockers.append(_prop(SHELF, _inner(cell, far, 2.0, 0.4), _face_into(far), 2.0, 1.1))
	blockers.append(_prop(LADDER, _inner(cell, _side_edge(far), 2.4, 0.45), 0.6, 2.1, 0.65))
	blockers.append(_prop(EXTINGUISHER, _inner(cell, _opposite(_side_edge(far)), 1.5, 0.3), 0.2, 0.7, 0.35))
	var cabinet := _try_wall(CABINET, id, blockers)
	if cabinet == null:
		cabinet = _prop(CABINET, _inner(cell, far, 0.7, 0.45), _face_into(far), 1.3, 0.65)
		if _off_doors(cabinet, id, blockers):
			blockers.append(cabinet)
		else:
			_forget(cabinet)
	_dress_utility(id, blockers)


func _furnish_panel(id: String) -> void:
	var info := _door_info(id)
	var far := _opposite(str(info["edge"]))
	var cell: Vector2i = info["cell"]
	var face := _inner(cell, far, 2.0, 0.0)
	# Cabinet origin sits on the wall. Its pitched face is local +Z, into the room.
	_control_cabinet(Vector3(face.x, 0.0, face.z), _face_into(far))
	var panel := ElectricalPanel.new()
	panel.panel_id = "F03_DOWN_PANEL" if id == "panel_down" else "F03_UP_PANEL"
	panel.show_plate = false
	panel.position = face + Vector3(0.0, 2.22, 0.0) + _into(far) * 0.08
	panel.rotation.y = _face_into(far) + PI
	add_child(panel)
	var side := _side_edge(far)
	for i in 3:
		var along := 0.9 + float(i) * 1.1
		var at := _inner(cell, side, along, 0.0)
		_wall_box(Vector3(at.x, 1.42, at.z), _face_into(side))


func _furnish_open(id: String) -> void:
	var info := _door_info(id)
	var door_cell: Vector2i = info["cell"]
	var door_edge := str(info["edge"])
	var n := 0
	var blockers: Array[Node3D] = []
	for cell in _room_cells(id):
		if cell == door_cell:
			continue
		var edge := _outer_edge(cell)
		var desk := _raw(TABLE, _face_into(edge))
		desk.name = "ComputerDesk"
		_settle_against(desk, cell, edge, 2.0, 0.16)
		blockers.append(desk)
		var sitter := _seat(desk, _into(edge), CHAIR if n % 2 == 0 else SWIVEL, id, door_cell, door_edge, blockers, true)
		var aim := _into(edge)
		if sitter != null:
			aim = sitter.global_position - desk.global_position
			aim.y = 0.0
		var screen := _on_desk(CRT, desk, Vector3.ZERO, _yaw_facing(aim))
		screen.name = "DeskScreen"
		n += 1
	if n >= 2:
		_multi_work += 1
	_dress_work(id, blockers)


func _furnish_server(id: String) -> void:
	var info := _door_info(id)
	var door_cell: Vector2i = info["cell"]
	var door_edge := str(info["edge"])
	var blockers: Array[Node3D] = []
	var min_x := 999
	var max_x := -999
	var min_z := 999
	var max_z := -999
	for cell in _room_cells(id):
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_z = mini(min_z, cell.y)
		max_z = maxi(max_z, cell.y)
	var origin := Vector3(float(min_x) * CELL, 0.0, float(min_z) * CELL)
	var span_x := float(max_x - min_x + 1) * CELL
	var span_z := float(max_z - min_z + 1) * CELL
	var row := 0
	var x := 1.7
	while x < span_x - 0.7:
		var z := 1.35
		var yaw := PI * 0.5 if row % 2 == 0 else -PI * 0.5
		while z < span_z - 0.9:
			var rack := _raw(RACK, yaw)
			_center_mesh(rack, origin + Vector3(x, 0.0, z))
			if not _foot_in_room(rack, id) or _hits_door(rack, door_cell, door_edge) or _hits_nodes(rack, blockers):
				_forget(rack)
			else:
				blockers.append(rack)
			z += 2.45
		x += 1.5
		row += 1
	var cool := OmniLight3D.new()
	cool.position = _centroid(id) + Vector3(0, 2.3, 0)
	cool.light_color = Color(0.45, 0.62, 0.95)
	cool.light_energy = 0.8
	cool.omni_range = 7.0
	cool.shadow_enabled = false
	add_child(cool)


func _furnish_odd(id: String) -> void:
	var info := _door_info(id)
	var door_edge := str(info["edge"])
	var door_cell: Vector2i = info["cell"]
	var blockers: Array[Node3D] = []
	var placed := 0
	var walls: Array[String] = [_opposite(door_edge), _side_edge(door_edge), _opposite(_side_edge(door_edge))]
	for edge in walls:
		if placed >= 3:
			break
		for cell in _room_cells(id):
			if placed >= 3:
				break
			if not _is_wall_edge(cell, edge) or _is_door_edge(cell, edge):
				continue
			var desk := _raw(TABLE, _face_into(edge))
			desk.name = "ComputerDesk"
			_settle_against(desk, cell, edge, 2.0, 0.12)
			_nudge_off_door(desk, edge, door_cell, door_edge)
			if not _foot_in_room(desk, id) or _hits_door(desk, door_cell, door_edge) or _tight_hit(desk, blockers):
				_forget(desk)
				continue
			blockers.append(desk)
			var sitter := _seat(desk, _into(edge), SWIVEL, id, door_cell, door_edge, blockers, false)
			var aim := _into(edge)
			if sitter != null:
				aim = sitter.global_position - desk.global_position
				aim.y = 0.0
			var screen := _on_desk(CRT, desk, Vector3.ZERO, _yaw_facing(aim))
			screen.name = "DeskScreen"
			_on_desk(KEYBOARD, desk, Vector3(0.16, 0.0, 0.1), _yaw_facing(aim))
			placed += 1
	if placed >= 2:
		_multi_work += 1
	if OS.get_environment("F03_AUDIT") == "1":
		print("odd desks ", placed, " at ", _centroid(id))
	_try_wall(PLANT, id, blockers)


func _furnish_restroom(id: String) -> void:
	_tile_restroom(id)
	var toilets_run := _longest_run(id, "")
	var toilet_edge := str(toilets_run["edge"])
	if toilet_edge == "":
		return
	var toilet_cells: Array[Vector2i] = []
	toilet_cells.assign(toilets_run["cells"])
	var spots := _fixture_row(toilet_cells, 1.38, 0.32)
	var occupied := _place_toilets(id, toilet_edge, spots)
	var toilet_count := occupied.size()
	var bowls: Array[Vector3] = []
	for node in occupied:
		bowls.append(node.global_position)
	var sink_count := 0
	for edge in EDGES:
		if edge == toilet_edge:
			continue
		for run in _wall_runs(id, edge):
			var sink_cells: Array[Vector2i] = []
			sink_cells.assign(run)
			if edge != _opposite(toilet_edge) and _run_on_cells(sink_cells, toilet_cells):
				continue
			var sink_spots := _fixture_row(sink_cells, 1.6, 0.34)
			sink_count += _place_sinks(id, edge, sink_spots, occupied, bowls)
	if OS.get_environment("F03_AUDIT") == "1":
		print("restroom toilets ", toilet_count, " sinks ", sink_count, " edge ", toilet_edge, " run ", toilet_cells.size())
	for door in _room_doors(id):
		_wc_signs(door["cell"], str(door["edge"]))


func _longest_run(id: String, skip: String) -> Dictionary:
	var best_edge := ""
	var best: Array[Vector2i] = []
	for edge in EDGES:
		if edge == skip:
			continue
		for run in _wall_runs(id, edge):
			if run.size() > best.size():
				best = run
				best_edge = edge
	return {"edge": best_edge, "cells": best}


func _clear_of_doors(id: String, at: Vector3, radius: float) -> bool:
	for door in _room_doors(id):
		var door_at := _inner(door["cell"], str(door["edge"]), 2.0, 0.0)
		if Vector2(at.x, at.z).distance_to(Vector2(door_at.x, door_at.z)) < radius:
			return false
	return true


func _wall_cells(id: String, edge: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _room_cells(id):
		if _is_wall_edge(cell, edge) and not _is_door_edge(cell, edge):
			cells.append(cell)
	var side := _side(edge)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var pa := Vector3(float(a.x) * CELL, 0.0, float(a.y) * CELL)
		var pb := Vector3(float(b.x) * CELL, 0.0, float(b.y) * CELL)
		return pa.dot(side) < pb.dot(side)
	)
	return cells


func _wall_runs(id: String, edge: String) -> Array:
	var cells := _wall_cells(id, edge)
	var runs: Array = []
	var current: Array[Vector2i] = []
	for cell in cells:
		if current.is_empty() or _run_continues(current[current.size() - 1], cell, edge):
			current.append(cell)
		else:
			runs.append(current.duplicate())
			current = [cell]
	if not current.is_empty():
		runs.append(current)
	return runs


func _run_on_cells(run: Array[Vector2i], cells: Array[Vector2i]) -> bool:
	for cell in run:
		if cells.has(cell):
			return true
	return false


func _run_continues(a: Vector2i, b: Vector2i, edge: String) -> bool:
	if edge == "n" or edge == "s":
		return a.y == b.y and absi(a.x - b.x) == 1
	return a.x == b.x and absi(a.y - b.y) == 1


func _fixture_row(cells: Array[Vector2i], pitch: float, margin: float) -> Array[Dictionary]:
	var spots: Array[Dictionary] = []
	if cells.is_empty():
		return spots
	var length := float(cells.size()) * CELL
	var usable := length - margin * 2.0
	if usable < pitch * 0.8:
		return spots
	var count := maxi(int(usable / pitch), 1)
	var step := usable / float(count)
	for i in count:
		var dist := margin + (float(i) + 0.5) * step
		var index := mini(int(dist / CELL), cells.size() - 1)
		spots.append({"cell": cells[index], "along": dist - float(index) * CELL})
	return spots


func _place_toilets(id: String, edge: String, spots: Array[Dictionary]) -> Array[Node3D]:
	var scale := 1.48
	var gap := 0.250 * scale + 0.06
	var door_cell: Vector2i = _door_info(id)["cell"]
	var door_edge := str(_door_info(id)["edge"])
	var kept: Array[Node3D] = []
	for spot in spots:
		var cell: Vector2i = spot["cell"]
		var toilet := TOILET_MODEL.instantiate() as Node3D
		toilet.position = _against(cell, edge, float(spot["along"]), gap)
		toilet.rotation.y = _face_into(edge)
		toilet.scale = Vector3(scale, scale, scale)
		add_child(toilet)
		_tag(toilet, TOILET_MODEL)
		_box_around(toilet)
		if not _foot_in_room(toilet, id) or _hits_door(toilet, door_cell, door_edge) or not _clear_of_doors(id, toilet.global_position, 1.45):
			_forget(toilet)
			continue
		kept.append(toilet)
	if kept.size() >= 2:
		_stalls(edge, kept, gap)
	return kept


func _stalls(edge: String, toilets: Array[Node3D], gap: float) -> void:
	_ensure_stall_material()
	var into := _into(edge)
	var side := _side(edge).normalized()
	var ordered: Array[Node3D] = []
	ordered.assign(toilets)
	ordered.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.dot(side) < b.global_position.dot(side)
	)
	var pitch := 1.3
	if ordered.size() >= 2:
		pitch = absf((ordered[1].global_position - ordered[0].global_position).dot(side))
	var front := 0.369 * 1.48
	var door_from_origin := front + 0.42
	var stall_depth := gap + door_from_origin + 0.08
	var opening := pitch - 0.04
	var door_width := minf(0.78, opening - 0.16)
	var flank := (opening - door_width) * 0.5
	var yaw := _face_into(edge)
	var leaf := Basis(Vector3.UP, yaw).x
	for i in ordered.size() + 1:
		var base: Node3D = ordered[mini(i, ordered.size() - 1)]
		var coord := _stall_cut(ordered, side, i, pitch)
		var at := base.global_position + side * (coord - base.global_position.dot(side))
		at = at - into * gap + into * (stall_depth * 0.5)
		at.y = 1.06
		var size := Vector3(0.04, 1.92, stall_depth)
		if absf(into.x) > 0.5:
			size = Vector3(stall_depth, 1.92, 0.04)
		_world_box(at, size, _stall_white)
	for toilet in ordered:
		var center := toilet.global_position + into * door_from_origin
		center.y = 0.0
		var hinge := center - leaf * (door_width * 0.5)
		hinge.y = 0.0
		_stall_door(hinge, yaw, door_width)
		if flank > 0.04:
			_stall_fill(center - leaf * (door_width * 0.5 + flank * 0.5), leaf, flank)
			_stall_fill(center + leaf * (door_width * 0.5 + flank * 0.5), leaf, flank)


func _stall_cut(ordered: Array[Node3D], side: Vector3, index: int, pitch: float) -> float:
	if ordered.size() < 2:
		var sign := -1.0 if index == 0 else 1.0
		return ordered[0].global_position.dot(side) + sign * pitch * 0.5
	if index == 0:
		return ordered[0].global_position.dot(side) - (ordered[1].global_position - ordered[0].global_position).dot(side) * 0.5
	if index == ordered.size():
		var last := ordered.size() - 1
		return ordered[last].global_position.dot(side) + (ordered[last].global_position - ordered[last - 1].global_position).dot(side) * 0.5
	return (ordered[index - 1].global_position.dot(side) + ordered[index].global_position.dot(side)) * 0.5


func _stall_fill(center: Vector3, along: Vector3, width: float) -> void:
	center.y = 1.02
	var size := Vector3(width, 1.80, 0.04)
	if absf(along.z) > absf(along.x):
		size = Vector3(0.04, 1.80, width)
	_world_box(center, size, _stall_white)


func _stall_door(at: Vector3, yaw: float, width: float) -> void:
	_ensure_stall_material()
	var body := AnimatableBody3D.new()
	body.name = "StallDoor"
	body.position = at
	body.rotation.y = yaw
	body.sync_to_physics = true
	body.set_script(DOOR_SCRIPT)
	body.set("open_angle_degrees", -85.0)
	body.set("duration", 0.4)
	add_child(body)
	var height := 1.80
	var thick := 0.04
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, height, thick)
	mesh_node.mesh = box
	mesh_node.position = Vector3(width * 0.5, 0.12 + height * 0.5, 0.0)
	mesh_node.material_override = _stall_white
	body.add_child(mesh_node)
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = box.size
	shape.shape = collision
	shape.position = mesh_node.position
	body.add_child(shape)
	var handle := MeshInstance3D.new()
	var handle_box := BoxMesh.new()
	handle_box.size = Vector3(0.11, 0.028, 0.018)
	handle.mesh = handle_box
	handle.position = Vector3(width - 0.09, 0.98, thick * 0.5 + 0.012)
	handle.material_override = _stall_handle
	body.add_child(handle)


func _place_sinks(id: String, edge: String, spots: Array[Dictionary], occupied: Array[Node3D], bowls: Array[Vector3]) -> int:
	var door_cell: Vector2i = _door_info(id)["cell"]
	var door_edge := str(_door_info(id)["edge"])
	var added := 0
	for spot in spots:
		var cell: Vector2i = spot["cell"]
		var along := float(spot["along"])
		var sink := SINK.instantiate() as Node3D
		sink.position = _against(cell, edge, along, 0.30)
		sink.rotation.y = _face_into(edge)
		add_child(sink)
		_tag(sink, SINK)
		_box_around(sink)
		var beside_bowl := false
		for bowl in bowls:
			var flat := Vector2(sink.global_position.x, sink.global_position.z) - Vector2(bowl.x, bowl.z)
			if flat.length() < 2.15:
				beside_bowl = true
				break
		if beside_bowl or not _foot_in_room(sink, id) or _hits_door(sink, door_cell, door_edge) or _hits_nodes(sink, occupied) or not _clear_of_doors(id, sink.global_position, 1.35):
			_forget(sink)
			continue
		occupied.append(sink)
		added += 1
		var mirror := _wall_hang(MIRROR, _against(cell, edge, along, 0.0), _face_into(edge), 1.62, 1.6)
		_tag_last(MIRROR)
		_paint_black(mirror)
	return added


func _tile_restroom(id: String) -> void:
	_ensure_tile_materials()
	for cell in _room_cells(id):
		var floor_tile := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(4.0, 4.0)
		floor_tile.mesh = plane
		floor_tile.position = Vector3(cell.x * CELL + 2.0, 0.02, cell.y * CELL + 2.0)
		floor_tile.material_override = _tile_floor
		add_child(floor_tile)
		for edge in EDGES:
			if not _is_wall_edge(cell, edge) or _is_door_edge(cell, edge):
				continue
			var face := _inner(cell, edge, 2.0, 0.02)
			var sheet := MeshInstance3D.new()
			var wall_plane := PlaneMesh.new()
			if edge == "e" or edge == "w":
				wall_plane.size = Vector2(3.2, CELL)
				sheet.rotation.z = PI * 0.5
			else:
				wall_plane.size = Vector2(CELL, 3.2)
				sheet.rotation.x = -PI * 0.5
			sheet.mesh = wall_plane
			sheet.position = Vector3(face.x, 1.6, face.z)
			sheet.material_override = _tile_ew if edge == "e" or edge == "w" else _tile_ns
			add_child(sheet)


func _wc_signs(cell: Vector2i, edge: String) -> void:
	# Corridor side of the door. Local +Z of each plate points into the corridor.
	var corridor := -_into(edge)
	var yaw := _yaw_facing(corridor)
	# Low along sits on the viewer's right when facing the corridor side of an east door.
	var tokens: Array[String] = ["DEFICIENTE", "MULHER", "HOMEM"]
	var alongs: Array[float] = [0.28, 0.72, 1.16]
	for i in tokens.size():
		var at := _inner(cell, edge, alongs[i], 0.0) + corridor * 0.24
		at.y = 1.55
		_wc_plate(at, yaw, tokens[i])


func _wc_plate(at: Vector3, yaw: float, token: String) -> void:
	var mount := Node3D.new()
	mount.name = "WcSymbol"
	mount.position = at
	mount.rotation.y = yaw
	add_child(mount)
	var sign := BATHROOM_SIGN.instantiate() as Node3D
	mount.add_child(sign)
	var plate := _find_plate(sign, token)
	if plate == null:
		mount.queue_free()
		return
	_keep_plate(sign, plate)
	_cull_sign_back(plate)
	sign.rotation.x = PI * 0.5
	sign.scale = Vector3(1.35, 1.35, 1.35)
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


func _ensure_stall_material() -> void:
	if _stall_white != null:
		return
	_stall_white = StandardMaterial3D.new()
	_stall_white.albedo_color = Color(0.95, 0.95, 0.94)
	_stall_white.roughness = 0.4
	_stall_handle = StandardMaterial3D.new()
	_stall_handle.albedo_color = Color(0.74, 0.75, 0.78)
	_stall_handle.roughness = 0.28
	_stall_handle.metallic = 0.88


func _ensure_tile_materials() -> void:
	if _tile_floor != null:
		return
	_tile_floor = _tile_material(0.40, 4.0, 4.0)
	_tile_ns = _tile_material(0.20, CELL, 3.2)
	_tile_ew = _tile_material(0.20, 3.2, CELL)


func _tile_material(tile: float, span_u: float, span_v: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TILE_TEX
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.roughness = 0.34
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(span_u / tile / 10.0, span_v / tile / 10.0, 1.0)
	return mat


func _world_box(at: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = at
	add_child(body)
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = material
	body.add_child(mesh_node)
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = size
	shape.shape = collision
	body.add_child(shape)


func _assign_ranks() -> void:
	var ids: Array[String] = []
	var seen: Dictionary = {}
	for key in _cells.keys():
		var id := str(_cells[key])
		if seen.has(id):
			continue
		seen[id] = true
		var kind := str(_kind.get(id, ""))
		if kind == "hall" or kind.ends_with("car"):
			continue
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra := _roll(_id_num(a), 17)
		var rb := _roll(_id_num(b), 17)
		if ra == rb:
			return a < b
		return ra < rb
	)
	var n := ids.size()
	var cuts: Array[int] = [
		int(round(n * 0.10)),
		int(round(n * 0.25)),
		int(round(n * 0.60)),
		int(round(n * 0.90)),
	]
	for i in ids.size():
		var rank := 4
		if i < cuts[0]:
			rank = 0
		elif i < cuts[1]:
			rank = 1
		elif i < cuts[2]:
			rank = 2
		elif i < cuts[3]:
			rank = 3
		_rank[ids[i]] = rank


func _prop_budget(id: String) -> int:
	var rank := int(_rank.get(id, 2))
	var cells := _room_cells(id).size()
	var table: Array[int] = [0, 1, 2, 3, 4]
	var per := table[rank]
	var extra := 0 if rank == 0 or cells < 2 else cells - 1
	return mini(per + extra, 7)


func _dress_work(id: String, blockers: Array[Node3D]) -> void:
	var budget := _prop_budget(id)
	if budget <= 0:
		return
	var info := _door_info(id)
	var door_edge := str(info["edge"])
	var door_cell: Vector2i = info["cell"]
	var n := _id_num(id)
	var first: PackedScene = PLANT
	match _roll(n, 23) % 3:
		1:
			first = CABINET
		2:
			first = SHELF
	_try_wall(first, id, blockers)
	if budget >= 2:
		_try_wall(BIN if first == PLANT else PLANT, id, blockers)
	if budget >= 3:
		_try_wall(SHELF, id, blockers)
	if budget >= 4:
		_try_wall(CABINET, id, blockers)
	for item in blockers:
		if budget < 2:
			break
		if str(item.name).begins_with("ComputerDesk"):
			_beside(TOWER, item, id, blockers)
			var paper: PackedScene = FOLDER if _roll(n, 31) % 2 == 0 else PENCIL
			_on_desk(paper, item, Vector3(0.32, 0.0, 0.1), 0.4, 0.16, 0.22)
			break
	if budget >= 1:
		for item in blockers:
			if str(item.name).begins_with("ManagerDesk"):
				_seat(item, item.global_transform.basis.x, WOOD, id, door_cell, door_edge, blockers, false)
				break
	if budget >= 4 and _roll(n, 37) % 3 == 0:
		_mount_camera(id)
	if budget >= 3 and _roll(n, 41) % 2 == 0:
		_mount_note(id)


func _dress_meeting(id: String, blockers: Array[Node3D], far: String) -> void:
	var budget := _prop_budget(id)
	if budget <= 0:
		return
	_try_wall(PLANT if _roll(_id_num(id), 19) % 2 == 0 else CABINET, id, blockers)
	if budget >= 2:
		_try_wall(SHELF, id, blockers)
	if budget >= 3:
		var side := _side_edge(far)
		var cell := _far_cell(id, far)
		if not _is_wall_edge(cell, side) or _is_door_edge(cell, side):
			side = _opposite(side)
		if _is_wall_edge(cell, side) and not _is_door_edge(cell, side):
			var board: PackedScene = GLASS if _roll(_id_num(id), 43) % 2 == 0 else NOTES
			_mount_on_wall(board, _inner(cell, side, 1.3, 0.0), _face_into(side), 1.55)
			_tag_last(board)


func _dress_break(id: String, blockers: Array[Node3D]) -> void:
	var budget := _prop_budget(id)
	if budget <= 0:
		return
	_try_wall(PLANT, id, blockers)
	if budget >= 2:
		_try_wall(PAPER, id, blockers)
	if budget >= 3:
		_try_wall(CABINET, id, blockers)


func _dress_storage(id: String, blockers: Array[Node3D]) -> void:
	var budget := _prop_budget(id)
	for _i in budget:
		_try_wall(SHELF if _i % 2 == 0 else CABINET, id, blockers)


func _dress_utility(id: String, blockers: Array[Node3D]) -> void:
	var budget := _prop_budget(id)
	if budget >= 2:
		_try_wall(BIN, id, blockers)
	if budget >= 3:
		_try_wall(SHELF, id, blockers)


func _try_wall(packed: PackedScene, id: String, blockers: Array[Node3D]) -> Node3D:
	var alongs: Array[float] = [0.7, 2.05, 3.3]
	var shift := _roll(_id_num(id), 11) % 3
	var doors := _room_doors(id)
	var tried := 0
	for cell in _room_cells(id):
		for edge in EDGES:
			if not _is_wall_edge(cell, edge) or _is_door_edge(cell, edge):
				continue
			var along: float = alongs[(tried + shift) % alongs.size()]
			tried += 1
			if tried > 8:
				return null
			var node := _raw(packed, _face_into(edge))
			_settle_against(node, cell, edge, along, 0.12)
			if _blocked(node, id, blockers, doors):
				_forget(node)
				continue
			blockers.append(node)
			_kept_prop(node, packed)
			return node
	return null


func _beside(packed: PackedScene, desk: Node3D, id: String, blockers: Array[Node3D]) -> void:
	var box := _world_bounds(desk)
	var doors := _room_doors(id)
	var dirs: Array[Vector3] = [desk.global_transform.basis.x, -desk.global_transform.basis.x]
	for dir in dirs:
		var flat := Vector3(dir.x, 0.0, dir.z)
		if flat.length() < 0.01:
			continue
		flat = flat.normalized()
		var reach := absf(flat.x) * box.size.x * 0.5 + absf(flat.z) * box.size.z * 0.5
		var at := Vector3(box.get_center().x, 0.0, box.get_center().z) + flat * (reach + 0.32)
		var node := _prop(packed, at, _yaw_facing(flat), 0.62, 0.42)
		if _blocked(node, id, blockers, doors):
			_forget(node)
			continue
		blockers.append(node)
		return


func _mount_camera(id: String) -> void:
	for cell in _room_cells(id):
		for edge in EDGES:
			if not _is_wall_edge(cell, edge) or _is_door_edge(cell, edge):
				continue
			var at := _inner(cell, edge, 0.75, 0.0)
			var root := Node3D.new()
			root.position = Vector3(at.x, 2.35, at.z)
			root.rotation.y = _face_into(edge)
			add_child(root)
			var node := CAM_MODEL.instantiate() as Node3D
			node.rotation.x = PI * 0.5
			root.add_child(node)
			_tag(node, CAM_MODEL)
			return


func _mount_note(id: String) -> void:
	for cell in _room_cells(id):
		for edge in EDGES:
			if not _is_wall_edge(cell, edge) or _is_door_edge(cell, edge):
				continue
			_mount_on_wall(NOTES, _inner(cell, edge, 3.1, 0.0), _face_into(edge), 1.35)
			_tag_last(NOTES)
			return


func _off_doors(node: Node3D, id: String, blockers: Array[Node3D]) -> bool:
	var doors := _room_doors(id)
	if not _blocked(node, id, blockers, doors):
		return true
	var origin := node.position
	var shifts: Array[Vector3] = [
		Vector3(0.0, 0.0, 1.6), Vector3(0.0, 0.0, -1.6),
		Vector3(1.6, 0.0, 0.0), Vector3(-1.6, 0.0, 0.0),
		Vector3(0.0, 0.0, 2.4), Vector3(0.0, 0.0, -2.4),
	]
	for shift in shifts:
		node.position = origin + shift
		if not _blocked(node, id, blockers, doors):
			return true
	node.position = origin
	return false


func _blocked(node: Node3D, id: String, blockers: Array[Node3D], doors: Array[Dictionary]) -> bool:
	if not _foot_in_room(node, id) or _hits_nodes(node, blockers) or _on_route(node, doors):
		return true
	for door in doors:
		if _hits_door(node, door["cell"], str(door["edge"])):
			return true
	return false


func _on_route(node: Node3D, doors: Array[Dictionary]) -> bool:
	if doors.size() < 2:
		return false
	var center := _world_bounds(node).get_center()
	var point := Vector2(center.x, center.z)
	for i in doors.size():
		for j in range(i + 1, doors.size()):
			var a := _door_center(doors[i])
			var b := _door_center(doors[j])
			if _segment_distance(point, a, b) < 0.85:
				return true
	return false


func _door_center(door: Dictionary) -> Vector2:
	var cell: Vector2i = door["cell"]
	var edge := str(door["edge"])
	var at := _inner(cell, edge, 2.0, 0.0) + _into(edge) * 0.4
	return Vector2(at.x, at.z)


func _segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom < 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _room_doors(id: String) -> Array[Dictionary]:
	var doors: Array[Dictionary] = []
	for cell in _room_cells(id):
		for edge in EDGES:
			if _is_door_edge(cell, edge):
				doors.append({"cell": cell, "edge": edge})
	return doors


func _is_door_edge(cell: Vector2i, edge: String) -> bool:
	return str(_overrides.get(_canon_key(cell, edge), "")) == "door"


func _tag(node: Node3D, packed: PackedScene) -> void:
	var key := packed.resource_path.get_file()
	node.set_meta("asset", key)
	_asset_counts[key] = int(_asset_counts.get(key, 0)) + 1


func _tag_last(packed: PackedScene) -> void:
	_asset_counts[packed.resource_path.get_file()] = int(_asset_counts.get(packed.resource_path.get_file(), 0)) + 1


func _forget(node: Node3D) -> void:
	_untag_tree(node)
	node.name = "Rejected"
	node.queue_free()


func _untag_tree(node: Node) -> void:
	if node is Node3D and (node as Node3D).has_meta("asset"):
		var key := str((node as Node3D).get_meta("asset"))
		_asset_counts[key] = int(_asset_counts.get(key, 0)) - 1
		(node as Node3D).remove_meta("asset")
	for child in node.get_children():
		_untag_tree(child)


func _report_assets() -> void:
	if OS.get_environment("F03_AUDIT") != "1":
		return
	var keys: Array = _asset_counts.keys()
	keys.sort()
	for key in keys:
		print("asset ", key, " ", _asset_counts[key])
	print("density ", _density_counts, " multi_work ", _multi_work, " door_hits ", _door_hits())
	_print_samples()


func _print_samples() -> void:
	var wanted: Dictionary = {"office": true, "meeting": true, "break": true}
	var shown: Dictionary = {}
	for id in _rank.keys():
		var kind := str(_kind.get(id, ""))
		if not wanted.has(kind):
			continue
		var rank := int(_rank[id])
		if kind == "office" and rank != 0 and rank != 4:
			continue
		var key := kind + str(rank)
		if shown.has(key):
			continue
		shown[key] = true
		var info := _door_info(id)
		print("sample ", kind, " ", id, " rank ", rank, " at ", _centroid(id), " door ", info["cell"], " ", info["edge"])


func _door_hits() -> int:
	var doors := _room_doors_all()
	var hits := 0
	for child in get_children():
		var node := child as Node3D
		if node == null or str(node.name) == "Rejected" or not node.has_meta("asset"):
			continue
		var box := _world_bounds(node)
		if box.size.length() < 0.001:
			continue
		var foot := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
		for door in doors:
			var zone := _door_zone(door["cell"], str(door["edge"]))
			var overlap := foot.intersection(zone)
			if overlap.size.x > 0.2 and overlap.size.y > 0.2:
				hits += 1
				print("door_hit ", node.get_meta("asset"), " node ", node.position, " box ", box, " door ", door["cell"], " ", door["edge"], " zone ", zone)
				break
	return hits


func _room_doors_all() -> Array[Dictionary]:
	var doors: Array[Dictionary] = []
	var seen: Dictionary = {}
	for key in _cells.keys():
		var cell: Vector2i = key
		for edge in EDGES:
			var canon := _canon_key(cell, edge)
			if seen.has(canon) or not _is_door_edge(cell, edge):
				continue
			seen[canon] = true
			doors.append({"cell": cell, "edge": edge})
	return doors


func _furnish_hall() -> void:
	var skips := {
		Vector2i(16, 8): true,
		Vector2i(8, 1): true,
		Vector2i(20, 19): true,
		Vector2i(8, 0): true,
		Vector2i(20, 20): true,
	}
	for key in _cells.keys():
		if str(_cells[key]) != "hall":
			continue
		var cell: Vector2i = key
		if skips.has(cell):
			continue
		if _roll(cell.x * 7 + cell.y, 4) % 7 != 0:
			continue
		var edge := _any_wall(cell)
		if edge == "":
			continue
		var packed: PackedScene = PLANT
		var roll := _roll(cell.x, cell.y) % 5
		if roll == 0:
			packed = EXTINGUISHER
		elif roll == 1:
			packed = BIN
		_prop(packed, _inner(cell, edge, 0.7, 0.35), 0.2, 1.3, 0.55)


func _desk_spots(id: String, count: int) -> Array[Dictionary]:
	var spots: Array[Dictionary] = []
	var info := _door_info(id)
	var far := _opposite(str(info.get("edge", "s")))
	var cells := _room_cells(id)
	var used: Dictionary = {}
	for cell in cells:
		if spots.size() >= count:
			break
		if cell == info.get("cell", Vector2i.ZERO) and cells.size() > 1:
			continue
		var edge := far if _is_wall_edge(cell, far) else _outer_edge(cell)
		var at := _inner(cell, edge, 2.0, 0.65)
		spots.append({"at": at, "edge": edge})
		used[cell] = true
	if spots.is_empty() and not cells.is_empty():
		var cell: Vector2i = cells[0]
		var edge := _outer_edge(cell)
		spots.append({"at": _inner(cell, edge, 2.0, 0.65), "edge": edge})
	return spots


func _room_cells(id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for key in _cells.keys():
		if str(_cells[key]) == id:
			cells.append(key)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return cells


func _door_info(id: String) -> Dictionary:
	if _door.has(id):
		return _door[id]
	for cell in _room_cells(id):
		for edge in EDGES:
			if str(_overrides.get(_canon_key(cell, edge), "")) == "door":
				return {"cell": cell, "edge": edge}
	var cells := _room_cells(id)
	if cells.is_empty():
		return {"cell": Vector2i.ZERO, "edge": "s"}
	return {"cell": cells[0], "edge": "s"}


func _far_cell(id: String, edge: String) -> Vector2i:
	var best: Vector2i = _door_info(id)["cell"]
	var best_d := -1
	var step := _delta(edge)
	for cell in _room_cells(id):
		var d: int = cell.x * step.x + cell.y * step.y
		if d > best_d:
			best_d = d
			best = cell
	return best


func _centroid(id: String) -> Vector3:
	var cells := _room_cells(id)
	if cells.is_empty():
		return Vector3.ZERO
	var acc := Vector3.ZERO
	for cell in cells:
		acc += Vector3(cell.x * CELL + 2.0, 0.0, cell.y * CELL + 2.0)
	return acc / float(cells.size())


func _corner(id: String) -> Vector3:
	var cells := _room_cells(id)
	var cell: Vector2i = cells[cells.size() - 1]
	return _inner(cell, _outer_edge(cell), 0.8, 0.4)


func _outer_edge(cell: Vector2i) -> String:
	for edge in EDGES:
		if not _cells.has(cell + _delta(edge)):
			return edge
		if str(_cells[cell + _delta(edge)]) != str(_cells[cell]):
			return edge
	return "n"


func _any_wall(cell: Vector2i) -> String:
	for edge in EDGES:
		if _edge_kind(cell, edge) == "wall" or _edge_kind(cell, edge) == "window":
			return edge
	return ""


func _is_wall_edge(cell: Vector2i, edge: String) -> bool:
	var kind := _edge_kind(cell, edge)
	return kind == "wall" or kind == "window"


func _lamp(cell: Vector2i, id: String) -> void:
	if id.ends_with("car"):
		return
	var panel := LIGHT.instantiate() as Node3D
	panel.position = Vector3(cell.x * CELL + 2.0, 2.9 + LIFT, cell.y * CELL + 2.0)
	add_child(panel)
	var glow := panel.get_node_or_null(^"Glow") as OmniLight3D
	if glow == null:
		return
	var kind := str(_kind.get(id, ""))
	var enable := true
	if id == "hall":
		enable = posmod(cell.x + cell.y, 3) == 0
	glow.visible = enable
	glow.shadow_enabled = false
	if not enable:
		return
	glow.light_color = Color(0.78, 0.84, 0.9) if id == "hall" else Color(0.93, 0.9, 0.84)
	glow.omni_range = 8.0
	glow.light_energy = 1.15
	glow.distance_fade_enabled = true
	glow.distance_fade_begin = 14.0
	glow.distance_fade_length = 8.0
	if kind == "utility" or kind == "storage" or _roll(cell.x, cell.y) % 9 == 0:
		glow.light_energy = 0.45
		_flicker_lights.append(glow)
		_flicker_energy.append(glow.light_energy)
	elif kind == "break":
		glow.light_color = Color(1.0, 0.94, 0.84)
		glow.light_energy = 1.6


func _shaft(cell: Vector2i, edge: String) -> void:
	var doors := ElevatorDoors.new()
	doors.build("03", _outside_z(cell, edge))
	_place_node(doors, cell, edge)
	doors.set_car_here(true)
	var car := cell if str(_cells.get(cell, "")).ends_with("car") else cell + _delta(edge)
	doors.set_meta("car", car)


func _finish_car(cell: Vector2i, edge: String, elevator_id: String, lit_floor: int) -> void:
	var center := Vector3(float(cell.x) * CELL + 2.0, 0.0, float(cell.y) * CELL + 2.0)
	var door_dir := Vector3(_delta(edge).x, 0.0, _delta(edge).y)
	var doors: ElevatorDoors = null
	for child in get_children():
		if child is ElevatorDoors and child.has_meta("car") and child.get_meta("car") == cell:
			doors = child
			break
	if doors != null:
		doors.set_car_bounds(center)
	var panel: ElevatorPanel = CABIN.install(self, center, door_dir, lit_floor, elevator_id)
	panel.home_doors = doors


func _outside_z(cell: Vector2i, edge: String) -> float:
	var owner := cell
	var side := edge
	var other := cell + _delta(edge)
	if _cells.has(other) and (other.x < cell.x or (other.x == cell.x and other.y < cell.y)):
		owner = other
		side = _opposite(edge)
	var ahead := owner + _delta(side)
	var into_car := str(_cells.get(ahead, "")).ends_with("car")
	return -0.12 if into_car else 0.12


func _extra_doors() -> void:
	var rooms: Dictionary = {}
	for key in _cells.keys():
		var id := str(_cells[key])
		if id == "hall" or id.ends_with("car") or id.begins_with("panel"):
			continue
		var room_kind := str(_kind.get(id, ""))
		if room_kind == "odd" or room_kind == "restroom":
			continue
		rooms[id] = true
	for id in rooms.keys():
		if _room_doors(id).size() != 1:
			continue
		var door_edge := str(_room_doors(id)[0]["edge"])
		var far := _opposite(door_edge)
		var picked := ""
		var best := -1
		for cell in _room_cells(id):
			for edge in EDGES:
				if _is_door_edge(cell, edge):
					continue
				var nxt: Vector2i = cell + _delta(edge)
				if not _cells.has(nxt):
					continue
				var neighbor := str(_cells[nxt])
				if neighbor == id or neighbor.ends_with("car") or neighbor.begins_with("panel"):
					continue
				var canon := _canon_key(cell, edge)
				var current := str(_overrides.get(canon, ""))
				if current == "elevator" or current == "exit" or current == "door":
					continue
				var score := 30 if neighbor == "hall" else 10
				if edge != far and edge != door_edge:
					score += 20
				elif edge != door_edge:
					score += 5
				score += _roll(cell.x * 3 + cell.y, edge.hash()) % 7
				if score > best:
					best = score
					picked = canon
		if picked != "":
			_overrides[picked] = "door"


func _exit(cell: Vector2i, edge: String) -> void:
	_lift(_place(WALL, cell, edge))
	var body := LockedExit.new()
	body.built_in_leaf = false
	# Local +Z points into the room, the same way Floor 4's red door faces the player.
	body.position = _inner(cell, edge, 2.0, 0.0)
	body.rotation.y = _face_into(edge)
	add_child(body)
	if OS.get_environment("F03_AUDIT") == "1":
		print("exit ", body.global_position, " yaw ", body.rotation.y)
	_red_exit_leaf(body)
	_exit_label(body)


func _red_exit_leaf(body: Node3D) -> void:
	_ensure_exit_materials()
	# Same proportions as Floor 4: brown frame, red leaf, metal handle. Bottom sits on the floor.
	_local_box(body, Vector3(0.0, 1.14, 0.02), Vector3(1.5, 2.28, 0.04), _exit_frame)
	_local_box(body, Vector3(0.0, 1.02, 0.05), Vector3(1.2, 2.04, 0.05), _exit_red)
	_local_box(body, Vector3(0.46, 0.98, 0.09), Vector3(0.14, 0.035, 0.035), _exit_metal)


func _exit_label(body: Node3D) -> void:
	var sign := Label3D.new()
	sign.name = "ExitSign"
	sign.text = "EXIT"
	# Above the leaf, matching Floor 4. +Z is the readable face and already points into the room.
	sign.position = Vector3(0.0, 2.62, 0.06)
	sign.pixel_size = 0.004
	sign.font_size = 96
	sign.modulate = Color(1.0, 0.18, 0.12)
	sign.outline_modulate = Color(0.2, 0.0, 0.0)
	sign.outline_size = 12
	body.add_child(sign)


func _hang_on_real_wall(id: String, packed: PackedScene, prefer: String, lift: float) -> bool:
	var order: Array[String] = [prefer, _side_edge(prefer), _opposite(_side_edge(prefer)), _opposite(prefer)]
	for edge in order:
		for cell in _room_cells(id):
			if not _is_wall_edge(cell, edge) or _is_door_edge(cell, edge):
				continue
			_mount_on_wall(packed, _inner(cell, edge, 2.0, 0.0), _face_into(edge), lift)
			return true
	return false


func _kept_prop(node: Node3D, packed: PackedScene) -> void:
	if packed == SHELF:
		_stock_shelf(node)
	elif packed == CABINET:
		_finish_cabinet(node)


func _stock_shelf(shelf: Node3D) -> void:
	# Board tops on the Blendkit shelf, the same heights Floor 4 uses.
	var stacks: Array[Vector3] = [Vector3(-0.28, 0.612, 0.0), Vector3(0.02, 0.956, 0.0), Vector3(-0.08, 1.301, 0.0)]
	var yaws: Array[float] = [0.2, -0.3, 0.15]
	for i in stacks.size():
		var book := BOOKS.instantiate() as Node3D
		book.position = stacks[i]
		book.rotation.y = yaws[i]
		shelf.add_child(book)
		_tag(book, BOOKS)
	var folder := FOLDER.instantiate() as Node3D
	folder.position = Vector3(0.22, 0.612, 0.0)
	folder.rotation.z = PI * 0.5
	shelf.add_child(folder)
	_tag(folder, FOLDER)


func _finish_cabinet(cabinet: Node3D) -> void:
	_ensure_cabinet_materials()
	var pending: Array[Node] = [cabinet]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			mesh_node.material_override = _cab_drawer if _is_drawer_face(cabinet, mesh_node) else _cab_body
		for child in node.get_children():
			if child is StaticBody3D:
				continue
			pending.append(child)
	var face_h := 0.385
	var gap := 0.015
	for i in 3:
		var bottom := 0.09 + float(i) * (face_h + gap)
		var y := bottom + face_h * 0.5
		_local_box(cabinet, Vector3(0.0, y, 0.382), Vector3(0.40, face_h - 0.008, 0.016), _cab_drawer)
		_local_box(cabinet, Vector3(0.0, bottom + face_h - 0.045, 0.394), Vector3(0.16, 0.016, 0.008), _cab_pull)


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
	return max_z - min_z < 0.05 and max_z > 0.25


func _ensure_cabinet_materials() -> void:
	if _cab_body != null:
		return
	_cab_body = StandardMaterial3D.new()
	_cab_body.albedo_color = Color(0.94, 0.94, 0.95)
	_cab_body.metallic = 0.06
	_cab_body.roughness = 0.48
	_cab_drawer = StandardMaterial3D.new()
	_cab_drawer.albedo_color = Color(0.78, 0.79, 0.8)
	_cab_drawer.metallic = 0.02
	_cab_drawer.roughness = 0.52
	_cab_pull = StandardMaterial3D.new()
	_cab_pull.albedo_color = Color(0.38, 0.39, 0.41)
	_cab_pull.metallic = 0.55
	_cab_pull.roughness = 0.35


func _ensure_exit_materials() -> void:
	if _exit_red != null:
		return
	_exit_red = StandardMaterial3D.new()
	_exit_red.albedo_color = Color(0.45, 0.08, 0.07)
	_exit_red.roughness = 0.55
	_exit_frame = StandardMaterial3D.new()
	_exit_frame.albedo_color = Color(0.32, 0.28, 0.25)
	_exit_frame.roughness = 0.55
	_exit_frame.metallic = 0.12
	_exit_metal = StandardMaterial3D.new()
	_exit_metal.albedo_color = Color(0.62, 0.64, 0.66)
	_exit_metal.metallic = 0.72
	_exit_metal.roughness = 0.28


func _local_box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.position = at
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _spawn_player() -> void:
	# Hall cell (16, 8), clear of the jog. Facing east along the corridor.
	_marker("ContinueSpawn", Vector3(66.0, 0.05, 34.0), -PI * 0.5)
	_marker("FromF04", Vector3(82.0, 0.05, 78.0), 0.0)
	_marker("FromF02", Vector3(34.0, 0.05, 6.0), PI)
	var player := PLAYER.instantiate() as Node3D
	player.position = Vector3(66.0, 0.05, 34.0)
	player.rotation.y = -PI * 0.5
	add_child(player)


func _marker(marker_name: String, at: Vector3, yaw: float) -> void:
	var marker := Node3D.new()
	marker.name = marker_name
	marker.position = at
	marker.rotation.y = yaw
	add_child(marker)


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.42)
	env.ambient_light_energy = 0.12
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.fog_enabled = true
	env.fog_light_color = Color(0.028, 0.032, 0.038)
	env.fog_density = 0.008
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


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
	if _wall_paint == null:
		var sample := WALL.instantiate()
		_wall_paint = _find_paint(sample)
		sample.free()
	if _wall_paint == null:
		var flat := StandardMaterial3D.new()
		flat.albedo_color = Color(0.73, 0.69, 0.6)
		flat.roughness = 0.82
		return flat
	var paint := _wall_paint.duplicate() as StandardMaterial3D
	paint.uv1_scale = Vector3(1.0, LIFT / 3.0, 1.0)
	return paint


func _find_paint(node: Node) -> StandardMaterial3D:
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var material := (node as MeshInstance3D).get_active_material(surface)
				if material is StandardMaterial3D and (material as StandardMaterial3D).albedo_texture != null:
					return material as StandardMaterial3D
	for child in node.get_children():
		var found := _find_paint(child)
		if found != null:
			return found
	return null


func _raw(packed: PackedScene, yaw: float) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.rotation.y = yaw
	add_child(node)
	_tag(node, packed)
	return node


func _settle_against(node: Node3D, cell: Vector2i, edge: String, along: float, gap: float) -> void:
	var box := _local_aabb(node)
	var center := box.get_center()
	var into := _into(edge)
	var half := _half_along(node, into)
	var desired := _inner(cell, edge, along, 0.0) + into * (gap + half)
	var shift := node.global_transform.basis * Vector3(center.x, 0.0, center.z)
	node.position = desired - shift
	_sit(node)
	_box_around(node)


func _center_mesh(node: Node3D, at: Vector3) -> void:
	var center := _local_aabb(node).get_center()
	var shift := node.global_transform.basis * Vector3(center.x, 0.0, center.z)
	node.position = Vector3(at.x, 0.0, at.z) - shift
	_sit(node)
	_box_around(node)


func _half_along(node: Node3D, dir: Vector3) -> float:
	var half := _local_aabb(node).size * 0.5
	var local_dir := node.global_transform.basis.inverse() * dir
	return absf(local_dir.x) * half.x + absf(local_dir.y) * half.y + absf(local_dir.z) * half.z


func _nudge_off_door(node: Node3D, edge: String, door_cell: Vector2i, door_edge: String) -> void:
	var along := _side(edge)
	var into := _into(edge)
	var id := str(_cells.get(door_cell, ""))
	for _step in 14:
		if not _hits_door(node, door_cell, door_edge):
			return
		var away := _push_from_doors(node, id, along)
		var next := node.position + away
		node.position = next
		if id != "" and id != "hall" and not _foot_in_room(node, id):
			node.position = next - away
			break
	for _step in 6:
		if not _hits_door(node, door_cell, door_edge):
			return
		var next := node.position + into * 0.22
		node.position = next
		if id != "" and id != "hall" and not _foot_in_room(node, id):
			node.position = next - into * 0.22
			return


func _push_from_doors(node: Node3D, id: String, along: Vector3) -> Vector3:
	var center := _world_bounds(node).get_center()
	var foot := Rect2(_world_bounds(node).position.x, _world_bounds(node).position.z, _world_bounds(node).size.x, _world_bounds(node).size.z)
	var best := 999.0
	var slide := along
	var doors := _room_doors(id) if id != "" and id != "hall" else []
	for door in doors:
		var zone := _door_zone(door["cell"], str(door["edge"]))
		if not foot.intersects(zone):
			continue
		var at := _inner(door["cell"], str(door["edge"]), 2.0, 0.0)
		var delta := center - Vector3(at.x, center.y, at.z)
		var dist := delta.length()
		if dist < best:
			best = dist
			slide = along if delta.dot(along) >= 0.0 else -along
	return slide * 0.3


func _separate(node: Node3D, other: Node3D, edge: String) -> void:
	var slide := _side(edge)
	for _step in 6:
		if not _world_bounds(node).grow(-0.02).intersects(_world_bounds(other)):
			return
		var mine := _world_bounds(node).get_center()
		var theirs := _world_bounds(other).get_center()
		var dir := slide if mine.dot(slide) >= theirs.dot(slide) else -slide
		node.position += dir * 0.16


func _other_cell(id: String, back: Vector2i) -> Vector2i:
	var door_cell: Vector2i = _door_info(id)["cell"]
	var fallback := back
	for cell in _room_cells(id):
		if cell == back:
			continue
		if cell != door_cell:
			return cell
		fallback = cell
	return fallback


func _desk_wall(cell: Vector2i, avoid: String, prefer: String) -> String:
	if prefer != avoid and _is_wall_edge(cell, prefer):
		return prefer
	for edge in EDGES:
		if edge != avoid and _is_wall_edge(cell, edge):
			return edge
	return prefer


func _deep_along(far: String) -> float:
	# Distance along a side wall, toward the far wall and away from the door.
	if far == "n" or far == "e":
		return 2.55
	return 1.45


func _hits_door(node: Node3D, cell: Vector2i, edge: String) -> bool:
	var box := _world_bounds(node)
	var foot := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	var id := str(_cells.get(cell, ""))
	if id == "" or id == "hall":
		return foot.intersects(_door_zone(cell, edge))
	for door in _room_doors(id):
		if foot.intersects(_door_zone(door["cell"], str(door["edge"]))):
			return true
	return false


func _door_zone(cell: Vector2i, edge: String) -> Rect2:
	var into := _into(edge)
	var side := _side(edge)
	var center := _inner(cell, edge, 2.0, 0.0) + into * 0.7
	var hx := absf(side.x) * 0.85 + absf(into.x) * 0.7
	var hz := absf(side.z) * 0.85 + absf(into.z) * 0.7
	return Rect2(center.x - hx, center.z - hz, hx * 2.0, hz * 2.0)


func _on_desk(packed: PackedScene, desk: Node3D, local_offset: Vector3, yaw: float, max_height: float = 0.52, max_span: float = 0.62) -> Node3D:
	var top := _local_aabb(desk)
	var local := Vector3(top.get_center().x, top.position.y + top.size.y, top.get_center().z) + local_offset
	var at := desk.global_transform * local
	var node := packed.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	_tag(node, packed)
	var box := _local_aabb(node)
	var factor := 1.0
	if max_height > 0.0 and box.size.y > max_height:
		factor = minf(factor, max_height / box.size.y)
	if max_span > 0.0 and maxf(box.size.x, box.size.z) > max_span:
		factor = minf(factor, max_span / maxf(box.size.x, box.size.z))
	if factor < 0.999:
		node.scale = Vector3.ONE * factor
	var world := _world_bounds(node)
	if world.size.y > 0.001:
		node.position.y += at.y - world.position.y
	_box_around(node)
	return node


func _seat(desk: Node3D, preferred: Vector3, packed: PackedScene, id: String, door_cell: Vector2i, door_edge: String, blockers: Array[Node3D], required: bool) -> Node3D:
	var dir := preferred.normalized()
	var tangent := Vector3(-dir.z, 0.0, dir.x)
	var shifts: Array[float] = [0.0, -0.7, 0.7]
	var placed: Node3D = null
	for shift in shifts:
		placed = _place_chair(desk, dir, shift, packed, id, door_cell, door_edge, blockers)
		if placed != null:
			return placed
	var ends: Array[Vector3] = [tangent, -tangent]
	for approach in ends:
		placed = _place_chair(desk, approach, 0.0, packed, id, door_cell, door_edge, blockers)
		if placed != null:
			return placed
	if not required:
		return null
	var fallback := _spawn_chair(desk, dir, 0.0, packed)
	blockers.append(fallback)
	return fallback


func _place_chair(desk: Node3D, approach: Vector3, along: float, packed: PackedScene, id: String, door_cell: Vector2i, door_edge: String, blockers: Array[Node3D]) -> Node3D:
	var chair := _spawn_chair(desk, approach, along, packed)
	if not _foot_in_room(chair, id) or _hits_door(chair, door_cell, door_edge) or _hits_nodes(chair, blockers):
		_forget(chair)
		return null
	blockers.append(chair)
	return chair


func _spawn_chair(desk: Node3D, approach: Vector3, along: float, packed: PackedScene) -> Node3D:
	var box := _world_bounds(desk)
	var dir := approach.normalized()
	var tangent := Vector3(-dir.z, 0.0, dir.x)
	var reach := absf(dir.x) * box.size.x * 0.5 + absf(dir.z) * box.size.z * 0.5
	var at := Vector3(box.get_center().x, 0.0, box.get_center().z) + dir * (reach + 0.36) + tangent * along
	# Chair front is local +Z. Point it at the desk so the seat stays outside the top.
	var chair := _prop(packed, at, _yaw_facing(-dir), 0.0, 0.0)
	chair.name = "DeskChair"
	return chair


func _foot_in_room(node: Node3D, id: String) -> bool:
	var box := _world_bounds(node)
	var center := box.get_center()
	var points: Array[Vector2] = [
		Vector2(center.x, center.z),
		Vector2(box.position.x + 0.04, box.position.z + 0.04),
		Vector2(box.end.x - 0.04, box.position.z + 0.04),
		Vector2(box.position.x + 0.04, box.end.z - 0.04),
		Vector2(box.end.x - 0.04, box.end.z - 0.04),
	]
	for point in points:
		var cell := Vector2i(int(floor(point.x / CELL)), int(floor(point.y / CELL)))
		if str(_cells.get(cell, "")) != id:
			return false
	return true


func _tight_hit(node: Node3D, others: Array[Node3D]) -> bool:
	var box := _world_bounds(node).grow(-0.18)
	for other in others:
		if other == null or not is_instance_valid(other):
			continue
		if box.intersects(_world_bounds(other).grow(-0.18)):
			return true
	return false


func _hits_nodes(node: Node3D, others: Array[Node3D]) -> bool:
	var box := _world_bounds(node).grow(-0.03)
	for other in others:
		if other == null or not is_instance_valid(other):
			continue
		if box.intersects(_world_bounds(other)):
			return true
	return false


func _yaw_facing(dir: Vector3) -> float:
	return atan2(dir.x, dir.z)


func _prop_inside(id: String, packed: PackedScene, at: Vector3, yaw: float, max_height: float, max_span: float) -> void:
	var cell := Vector2i(int(floor(at.x / CELL)), int(floor(at.z / CELL)))
	if str(_cells.get(cell, "")) != id:
		return
	_prop(packed, at, yaw, max_height, max_span)


func _prop(packed: PackedScene, at: Vector3, yaw: float, max_height: float, max_span: float) -> Node3D:
	var node := packed.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	_tag(node, packed)
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
	_kept_prop(node, packed)
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


func _control_cabinet(at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "PanelCabinet"
	root.set_script(CABINET_LINK)
	root.position = at
	root.rotation.y = yaw
	add_child(root)
	var node := CONTROL_PANEL.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	root.add_child(node)
	var box := _world_bounds(node)
	if box.size.y > 0.001:
		node.position.y -= box.position.y
	_box_around(root)


func _wall_box(at: Vector3, yaw: float) -> void:
	var node := WALL_PANEL.instantiate() as Node3D
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	_box_around(node)


func _mount_on_wall(packed: PackedScene, at: Vector3, yaw: float, lift: float) -> Node3D:
	var root := Node3D.new()
	root.name = "WallScreen"
	root.rotation.y = yaw
	root.position = Vector3(at.x, 0.0, at.z)
	add_child(root)
	var node := packed.instantiate() as Node3D
	root.add_child(node)
	var box := _local_aabb(root)
	# Boards that are already upright stay upright. Flat screens get stood up.
	if box.size.y < 0.25 and box.size.z > box.size.y:
		node.rotation.x = PI * 0.5
		box = _local_aabb(root)
	var center := box.get_center()
	# Local +Z faces the room, so the back is the minimum Z. Vertical center sits at lift.
	node.position += Vector3(-center.x, lift - center.y, -box.position.z)
	return root


func _wall_hang(packed: PackedScene, at: Vector3, yaw: float, lift: float, scale: float) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(at.x, lift, at.z)
	root.rotation.y = yaw
	add_child(root)
	var node := packed.instantiate() as Node3D
	node.rotation.x = PI * 0.5
	node.scale = Vector3(scale, scale, scale)
	root.add_child(node)
	return root


func _paint_black(root: Node) -> void:
	if _mirror_glass == null:
		_mirror_glass = StandardMaterial3D.new()
		_mirror_glass.albedo_color = Color(0.012, 0.012, 0.014)
		_mirror_glass.roughness = 0.07
		_mirror_glass.metallic = 0.62
		_mirror_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			mesh_node.material_override = _mirror_glass
			if mesh_node.mesh != null:
				for surface in mesh_node.mesh.get_surface_count():
					mesh_node.set_surface_override_material(surface, _mirror_glass)
		for child in node.get_children():
			pending.append(child)


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
			if child is StaticBody3D:
				continue
			pending.append(child)
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh_node := node as MeshInstance3D
			var ab := mesh_node.get_aabb()
			var to_root := root.global_transform.affine_inverse() * mesh_node.global_transform
			for i in 8:
				var corner := Vector3(
					ab.position.x if (i & 1) == 0 else ab.end.x,
					ab.position.y if (i & 2) == 0 else ab.end.y,
					ab.position.z if (i & 4) == 0 else ab.end.z
				)
				var point: Vector3 = to_root * corner
				if not has:
					merged = AABB(point, Vector3.ZERO)
					has = true
				else:
					merged = merged.expand(point)
	return merged


func _world_bounds(node: Node3D) -> AABB:
	var merged := AABB()
	var has := false
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var item: Node = pending.pop_back()
		for child in item.get_children():
			pending.append(child)
		if item is MeshInstance3D and (item as MeshInstance3D).mesh != null:
			var ab := (item as MeshInstance3D).get_aabb()
			for i in 8:
				var corner := Vector3(
					ab.position.x if (i & 1) == 0 else ab.end.x,
					ab.position.y if (i & 2) == 0 else ab.end.y,
					ab.position.z if (i & 4) == 0 else ab.end.z
				)
				var point: Vector3 = (item as MeshInstance3D).global_transform * corner
				if not has:
					merged = AABB(point, Vector3.ZERO)
					has = true
				else:
					merged = merged.expand(point)
	return merged


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


func _against(cell: Vector2i, edge: String, along: float, gap: float) -> Vector3:
	return _inner(cell, edge, along, gap)


func _into(edge: String) -> Vector3:
	match edge:
		"n":
			return Vector3(0, 0, -1)
		"s":
			return Vector3(0, 0, 1)
		"e":
			return Vector3(-1, 0, 0)
		_:
			return Vector3(1, 0, 0)


func _side(edge: String) -> Vector3:
	var into := _into(edge)
	return Vector3(-into.z, 0, into.x)


func _side_edge(edge: String) -> String:
	match edge:
		"n", "s":
			return "e"
		_:
			return "n"


func _face_into(edge: String) -> float:
	# Local +Z turns into the room, away from this wall.
	match edge:
		"n":
			return PI
		"s":
			return 0.0
		"e":
			return -PI * 0.5
		_:
			return PI * 0.5


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


func _mark(key: String, kind: String) -> void:
	_overrides[key] = kind


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


func _roll(a: int, b: int) -> int:
	var n := (a * 1103515245 + b * 12345 + 40403) & 2147483647
	return n if n >= 0 else -n


func _id_num(id: String) -> int:
	var digits := ""
	for i in id.length():
		var ch := id.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if digits != "" else 0


func _counted_rooms() -> int:
	var ids: Dictionary = {}
	for key in _cells.keys():
		var id := str(_cells[key])
		if id == "hall" or id.ends_with("car"):
			continue
		ids[id] = true
	return ids.size()


func _exit_count_note() -> void:
	pass


func _write_report() -> void:
	var counts: Dictionary = {}
	var ids: Dictionary = {}
	var hall_cells := 0
	for key in _cells.keys():
		var id := str(_cells[key])
		if id == "hall":
			hall_cells += 1
			continue
		ids[id] = str(_kind.get(id, "?"))
	for id in ids.keys():
		var kind := str(ids[id])
		counts[kind] = int(counts.get(kind, 0)) + 1
	var rooms := 0
	for kind in counts.keys():
		if str(kind).ends_with("car"):
			continue
		rooms += int(counts[kind])
	var seen := _reachable(Vector2i(16, 8))
	var dead := 0
	var tee := 0
	var cross := 0
	var corner := 0
	var straight := 0
	for key in _cells.keys():
		if str(_cells[key]) != "hall":
			continue
		var cell: Vector2i = key
		var open := 0
		var ns := 0
		var ew := 0
		for edge in EDGES:
			var nxt: Vector2i = cell + _delta(edge)
			if str(_cells.get(nxt, "")) != "hall":
				continue
			open += 1
			if edge == "n" or edge == "s":
				ns += 1
			else:
				ew += 1
		if open <= 1:
			dead += 1
		elif open == 3:
			tee += 1
		elif open >= 4:
			cross += 1
		elif open == 2 and ns == 1 and ew == 1:
			corner += 1
		elif open == 2:
			straight += 1
	_report.append("rooms %d" % rooms)
	_report.append("hall_cells %d" % hall_cells)
	_report.append("reachable %d / %d" % [seen.size(), _cells.size()])
	var one_door := 0
	for id in ids.keys():
		if str(ids[id]).ends_with("car") or str(id).begins_with("panel"):
			continue
		if _room_doors(str(id)).size() <= 1:
			one_door += 1
	_report.append("one_door %d" % one_door)
	_report.append("dead %d tee %d cross %d corner %d straight %d" % [dead, tee, cross, corner, straight])
	for kind in counts.keys():
		_report.append("%s %d" % [str(kind), int(counts[kind])])
	var lines := PackedStringArray()
	for z in range(21, -1, -1):
		var line := ""
		for x in 24:
			var id := str(_cells.get(Vector2i(x, z), ""))
			if id == "":
				line += "."
			elif id == "hall":
				line += "#"
			elif id.ends_with("car"):
				line += "E"
			elif id.begins_with("panel"):
				line += "P"
			else:
				var kind := str(_kind.get(id, "?"))
				match kind:
					"office":
						line += "o"
					"small":
						line += "s"
					"meeting":
						line += "M"
					"storage":
						line += "A"
					"break":
						line += "b"
					"utility":
						line += "u"
					"open":
						line += "O"
					"server":
						line += "S"
					"restroom":
						line += "R"
					"odd":
						line += "?"
					_:
						line += "?"
		lines.append(line)
	var text := "\n".join(_report) + "\n" + "\n".join(lines) + "\n"
	print(text)
	var file := FileAccess.open("C:/Users/peter/AppData/Local/Temp/f03/layout.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
