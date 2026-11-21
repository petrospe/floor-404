class_name StoryCatalog
extends RefCounted
## Floor entries for the reader and a future journal.
## Ids are stable save keys. Text here is not a puzzle solution.

const ENTRIES: Dictionary = {
	"f04_ellis_terminal": {
		"floor": "F04",
		"medium": "terminal",
		"title": "Workstation",
		"body": "BUILD 2003.04 — FAILED\n\nThe compile stopped.\nNothing after this line was written.",
	},
	"f04_ellis_note": {
		"floor": "F04",
		"medium": "paper",
		"title": "Desk note",
		"body": "Back by 18:10.\nDon't wait on the review.\n\n— A. Ellis",
	},
	"f04_break_coffee": {
		"floor": "F04",
		"medium": "paper",
		"title": "Coffee list",
		"body": "Thursday\nEllis — in\nOkonkwo —\nPatel —",
	},
	"f04_security_badges": {
		"floor": "F04",
		"medium": "terminal",
		"title": "Badge log",
		"body": "BADGE LOG — FLOOR 4\n\n18:02  ELLIS, A.      OUT\n18:02  OKONKWO, R.    OUT\n18:02  PATEL, S.      OUT\n18:02  (remaining)    OUT\n\nNo further reads.",
	},
	"f04_down_panel_tag": {
		"floor": "F04",
		"medium": "paper",
		"title": "Service tag",
		"body": "Cabinet tagged for service.\nLeave the conductors as found.\n\n— Facilities",
	},
	"f04_stair_wall": {
		"floor": "F04",
		"medium": "wall",
		"title": "Stairwell",
		"body": "The stairs only go back.",
	},
	"f04_up_panel_sticky": {
		"floor": "F04",
		"medium": "paper",
		"title": "Cabinet note",
		"body": "Do not block the cabinet.",
	},
	"f04_server_log": {
		"floor": "F04",
		"medium": "terminal",
		"title": "Service log",
		"body": "SERVICE LOG\n\nFloor 4 sessions closed.\n18:02:01\nOpen consoles: 0",
	},
	"f04_meeting_agenda": {
		"floor": "F04",
		"medium": "wall",
		"title": "Agenda",
		"body": "status\nstaffing\n—",
	},
	"f04_north_watchers": {
		"floor": "F04",
		"medium": "wall",
		"title": "Corridor",
		"body": "They are watching us.",
	},
}


static func has_entry(entry_id: String) -> bool:
	return ENTRIES.has(entry_id)


static func entry(entry_id: String) -> Dictionary:
	return ENTRIES.get(entry_id, {})


static func ids() -> Array[String]:
	var found: Array[String] = []
	for key in ENTRIES.keys():
		found.append(str(key))
	return found
