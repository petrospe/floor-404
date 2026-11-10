extends Node
## In-memory progression. Scene nodes ask this object; they do not edit the save.

signal panel_completed(panel_id: String)
signal elevator_activated(elevator_id: String)

var completed_panels: Array[String] = []
var activated_elevators: Array[String] = []
var last_activation_floor := "F04"
var last_activation_panel := ""
var game_completed := false


func is_panel_complete(panel_id: String) -> bool:
	return completed_panels.has(panel_id)


func is_elevator_active(elevator_id: String) -> bool:
	return activated_elevators.has(elevator_id)


func reset() -> void:
	completed_panels.clear()
	activated_elevators.clear()
	last_activation_floor = "F04"
	last_activation_panel = ""
	game_completed = false


func complete_panel(panel_id: String) -> bool:
	if is_panel_complete(panel_id):
		return true
	var elevator_id := FloorRegistry.elevator_id_for_panel(panel_id)
	if elevator_id == "":
		push_error("Floor 404 unknown panel %s" % panel_id)
		return false
	completed_panels.append(panel_id)
	if not activated_elevators.has(elevator_id):
		activated_elevators.append(elevator_id)
	last_activation_floor = FloorRegistry.floor_of_panel(panel_id)
	last_activation_panel = panel_id
	panel_completed.emit(panel_id)
	elevator_activated.emit(elevator_id)
	if not SaveManager.write_save():
		push_error("Floor 404 could not save panel %s" % panel_id)
		return false
	return true


func to_dictionary() -> Dictionary:
	return {
		"save_version": 1,
		"completed_panels": completed_panels.duplicate(),
		"activated_elevators": activated_elevators.duplicate(),
		"last_activation_floor": last_activation_floor,
		"last_activation_panel": last_activation_panel,
		"game_completed": game_completed,
	}


func apply_dictionary(data: Dictionary) -> void:
	reset()
	var panels: Variant = data.get("completed_panels", [])
	if panels is Array:
		for item in panels:
			var panel_id := str(item)
			if FloorRegistry.has_panel(panel_id):
				completed_panels.append(panel_id)
			else:
				push_warning("Floor 404 ignored unknown panel %s" % panel_id)
	var elevators: Variant = data.get("activated_elevators", [])
	if elevators is Array:
		for item in elevators:
			var elevator_id := str(item)
			if FloorRegistry.has_elevator(elevator_id):
				activated_elevators.append(elevator_id)
			else:
				push_warning("Floor 404 ignored unknown elevator %s" % elevator_id)
	var floor_id := str(data.get("last_activation_floor", "F04"))
	if FloorRegistry.has_floor(floor_id) and FloorRegistry.scene_path(floor_id) != "":
		last_activation_floor = floor_id
	else:
		push_warning("Floor 404 continue floor fell back to F04")
		last_activation_floor = "F04"
	last_activation_panel = str(data.get("last_activation_panel", ""))
	game_completed = bool(data.get("game_completed", false))
