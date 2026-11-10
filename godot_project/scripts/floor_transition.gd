extends Node
## One travel at a time. A missing destination scene stays on the current floor.

var pending_marker := ""
var arriving := false
var _busy := false


func go_to(floor_id: String, marker: String) -> void:
	if _busy:
		return
	var path := FloorRegistry.scene_path(floor_id)
	if path == "":
		push_error("Floor 404 has no scene for %s" % floor_id)
		return
	_busy = true
	arriving = true
	pending_marker = marker
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", true)
	var overlay := FadeOverlay.find_or_create(get_tree())
	if overlay != null:
		await overlay.fade_to(1.0, 0.45)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Floor 404 could not load %s" % floor_id)
		arriving = false
		pending_marker = ""
		_busy = false
		if player != null and is_instance_valid(player) and player.has_method(&"set_input_suspended"):
			player.call(&"set_input_suspended", false)
		if overlay != null:
			await overlay.fade_to(0.0, 0.3)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var arrived := get_tree().get_first_node_in_group(&"player")
	if overlay != null:
		await overlay.fade_to(0.0, 0.45)
	if arrived != null and arrived.has_method(&"set_input_suspended"):
		arrived.call(&"set_input_suspended", false)
	arriving = false
	_busy = false


func apply_pending_spawn(level: Node) -> void:
	var player := level.get_tree().get_first_node_in_group(&"player") as Node3D
	if pending_marker != "" and player != null:
		var marker := level.find_child(pending_marker, true, false) as Node3D
		if marker == null:
			push_error("Floor 404 missing spawn marker %s" % pending_marker)
		elif player.has_method(&"travel_to"):
			player.call(&"travel_to", marker.global_transform)
		pending_marker = ""
	if arriving and player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", true)
