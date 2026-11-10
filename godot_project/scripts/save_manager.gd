extends Node
## Atomic JSON save. Partial wire puzzles and hazard checkpoints are never written.

const SAVE_PATH := "user://savegame.json"
const TMP_PATH := "user://savegame.tmp"
const BAK_PATH := "user://savegame.bak"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Floor 404 could not open the save")
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is not Dictionary:
		push_error("Floor 404 save is not valid JSON")
		return false
	var data: Dictionary = parsed
	if int(data.get("save_version", 0)) != 1:
		push_error("Floor 404 save version is not supported")
		return false
	GameState.apply_dictionary(data)
	return true


func write_save() -> bool:
	var file := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(GameState.to_dictionary(), "\t"))
	file.flush()
	file.close()
	var folder := DirAccess.open("user://")
	if folder == null:
		return false
	if folder.file_exists("savegame.json"):
		if folder.file_exists("savegame.bak"):
			folder.remove("savegame.bak")
		if folder.rename("savegame.json", "savegame.bak") != OK:
			return false
	if folder.rename("savegame.tmp", "savegame.json") != OK:
		folder.rename("savegame.bak", "savegame.json")
		return false
	if folder.file_exists("savegame.bak"):
		folder.remove("savegame.bak")
	return true


func erase() -> void:
	var folder := DirAccess.open("user://")
	if folder == null:
		return
	if folder.file_exists("savegame.json"):
		folder.remove("savegame.json")
	if folder.file_exists("savegame.tmp"):
		folder.remove("savegame.tmp")
	if folder.file_exists("savegame.bak"):
		folder.remove("savegame.bak")
