extends Node
## Authoritative floor graph. IDs are stable save keys, not scene node names.
## Floors 2–14 each have an up and a down elevator. Special floors are explicit.

var _floors: Dictionary = {}
var _elevators: Dictionary = {}
var _panel_floor: Dictionary = {}
var _panel_elevator: Dictionary = {}


func _ready() -> void:
	_build()
	_validate()


func scene_path(floor_id: String) -> String:
	var floor: Dictionary = _floors.get(floor_id, {})
	return str(floor.get("scene", ""))


func continue_marker(floor_id: String) -> String:
	var floor: Dictionary = _floors.get(floor_id, {})
	return str(floor.get("continue_marker", "ContinueSpawn"))


func elevator(elevator_id: String) -> Dictionary:
	return _elevators.get(elevator_id, {})


func elevator_id_for_panel(panel_id: String) -> String:
	return str(_panel_elevator.get(panel_id, ""))


func floor_of_panel(panel_id: String) -> String:
	return str(_panel_floor.get(panel_id, ""))


func has_floor(floor_id: String) -> bool:
	return _floors.has(floor_id)


func has_elevator(elevator_id: String) -> bool:
	return _elevators.has(elevator_id)


func has_panel(panel_id: String) -> bool:
	return _panel_elevator.has(panel_id)


func _build() -> void:
	_add_floor("G", "")
	_add_floor("B2", "")
	_add_floor("B1", "")
	for number in range(1, 16):
		var floor_id := "F%02d" % number
		var scene := ""
		if floor_id == "F03":
			scene = "res://scenes/floors/floor_03.tscn"
		elif floor_id == "F04":
			scene = "res://scenes/office_level.tscn"
		elif floor_id == "F05":
			scene = "res://scenes/floors/floor_05.tscn"
		_add_floor(floor_id, scene)
	for number in range(2, 15):
		var here := "F%02d" % number
		var above := "F%02d" % (number + 1)
		var below := "F%02d" % (number - 1)
		_add_elevator("%s_UP" % here, here, above, "%s_UP_PANEL" % here, "From%s" % here)
		_add_elevator("%s_DOWN" % here, here, below, "%s_DOWN_PANEL" % here, "From%s" % here)
	_add_elevator("F01_UP", "F01", "F02", "F01_UP_PANEL", "FromF01")
	_add_elevator("F01_GROUND", "F01", "G", "B2_MASTER_PANEL", "FromF01")
	_add_elevator("F15_DOWN", "F15", "F14", "F15_DOWN_PANEL", "FromF15")
	_add_elevator("F15_B1", "F15", "B1", "F15_B1_PANEL", "FromF15")
	_add_elevator("B1_UP", "B1", "F15", "B1_UP_PANEL", "FromB1")
	_add_elevator("B1_DOWN", "B1", "B2", "B1_DOWN_PANEL", "FromB1")
	_add_elevator("B2_UP", "B2", "B1", "B2_UP_PANEL", "FromB2")
	_panel_floor["B2_MASTER_PANEL"] = "B2"


func _add_floor(floor_id: String, scene: String) -> void:
	_floors[floor_id] = {"scene": scene, "continue_marker": "ContinueSpawn"}


func _add_elevator(elevator_id: String, source: String, destination: String, panel_id: String, arrival: String) -> void:
	_elevators[elevator_id] = {
		"source": source,
		"destination": destination,
		"panel": panel_id,
		"arrival": arrival,
	}
	_panel_elevator[panel_id] = elevator_id
	if panel_id != "B2_MASTER_PANEL":
		_panel_floor[panel_id] = source


func _validate() -> void:
	var counts: Dictionary = {}
	for elevator_id in _elevators.keys():
		var info: Dictionary = _elevators[elevator_id]
		var source := str(info["source"])
		var destination := str(info["destination"])
		if not _floors.has(source) or not _floors.has(destination):
			push_error("Floor 404 elevator %s points at an unknown floor" % elevator_id)
		counts[source] = int(counts.get(source, 0)) + 1
		var panel_id := str(info["panel"])
		if str(_panel_elevator.get(panel_id, "")) != elevator_id:
			push_error("Floor 404 panel %s is not unique" % panel_id)
	if int(counts.get("G", 0)) != 0:
		push_error("Floor 404 ground floor must not have an elevator")
	if int(counts.get("B2", 0)) != 1:
		push_error("Floor 404 basement 2 must have exactly one elevator")
	if int(counts.get("F01", 0)) != 2 or int(counts.get("F15", 0)) != 2 or int(counts.get("B1", 0)) != 2:
		push_error("Floor 404 special floors must have two elevators")
	for number in range(2, 15):
		if int(counts.get("F%02d" % number, 0)) != 2:
			push_error("Floor 404 floor %d must have two elevators" % number)
	if str(_panel_elevator.get("B2_MASTER_PANEL", "")) != "F01_GROUND":
		push_error("Floor 404 master panel must unlock the ground floor elevator")
	if str(_panel_floor.get("B2_MASTER_PANEL", "")) != "B2":
		push_error("Floor 404 master panel must live in basement 2")
