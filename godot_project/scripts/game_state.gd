extends Node
## In-memory progression. Scene nodes ask this object; they do not edit the save.

signal panel_completed(panel_id: String)
signal elevator_activated(elevator_id: String)
signal discovery_recorded(entry_id: String)

var completed_panels: Array[String] = []
var activated_elevators: Array[String] = []
var discovered_entries: Array[String] = []
var last_activation_floor := "F04"
var last_activation_panel := ""
## Floor the player was on when the session last saved. Continue uses this.
var current_floor := "F04"
var game_completed := false
var session_started := false


func is_panel_complete(panel_id: String) -> bool:
	return completed_panels.has(panel_id)


func is_elevator_active(elevator_id: String) -> bool:
	return activated_elevators.has(elevator_id)


func reset() -> void:
	completed_panels.clear()
	activated_elevators.clear()
	discovered_entries.clear()
	last_activation_floor = "F04"
	last_activation_panel = ""
	current_floor = "F04"
	game_completed = false


func begin_session() -> void:
	session_started = true


## Remember which built floor is loaded. Panel progress stays where it was.
func note_floor(floor_id: String) -> void:
	if not session_started or floor_id == current_floor:
		return
	if FloorRegistry.scene_path(floor_id) == "":
		return
	current_floor = floor_id
	if not SaveManager.write_save():
		push_error("Floor 404 could not save floor %s" % floor_id)


func continue_floor() -> String:
	if FloorRegistry.scene_path(current_floor) != "":
		return current_floor
	return "F04"


## Remember a catalog id. Does not move the Continue floor or touch panel progress.
func note_discovery(entry_id: String) -> bool:
	if entry_id == "" or discovered_entries.has(entry_id):
		return discovered_entries.has(entry_id)
	if not StoryCatalog.has_entry(entry_id):
		push_warning("Floor 404 ignored unknown story entry %s" % entry_id)
		return false
	discovered_entries.append(entry_id)
	if not SaveManager.write_save():
		discovered_entries.erase(entry_id)
		push_error("Floor 404 could not save story entry %s" % entry_id)
		return false
	discovery_recorded.emit(entry_id)
	return true


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
		"current_floor": current_floor,
		"game_completed": game_completed,
		"discovered_entries": discovered_entries.duplicate(),
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
		push_warning("Floor 404 activation floor fell back to F04")
		last_activation_floor = "F04"
	last_activation_panel = str(data.get("last_activation_panel", ""))
	var riding := str(data.get("current_floor", ""))
	if FloorRegistry.scene_path(riding) == "":
		riding = last_activation_floor
	if FloorRegistry.scene_path(riding) == "":
		riding = "F04"
	current_floor = riding
	game_completed = bool(data.get("game_completed", false))
	var found: Variant = data.get("discovered_entries", [])
	if found is Array:
		for item in found:
			var entry_id := str(item)
			if not StoryCatalog.has_entry(entry_id):
				push_warning("Floor 404 ignored unknown story entry %s" % entry_id)
				continue
			if discovered_entries.has(entry_id):
				continue
			discovered_entries.append(entry_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and session_started:
		if not SaveManager.write_save():
			push_error("Floor 404 could not save on exit")
